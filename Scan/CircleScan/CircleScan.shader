Shader "scan/CircleScan"

{

    Properties

    {
      [HideInInspector]_MainTex("MainTex",2D)="white"{}
    }

    SubShader
    {

        Tags{
        "RenderPipeline"="UniversalRenderPipeline"
        }

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float _ScanDistance;
        float _ScanRange;
        half4 _ScanColor;
        float3 _ScanCenter;
        float4x4 _InverseVPMatrix; 
        half4 _MainTex_ST;
        half4 _MainTex_TexelSize;
        Matrix _ViewPortRay;
        int _CircleEdgeInitiate;
        float _EdgeSinOmega;
        float _EdgeSinVerticalMove;
        int _EdgeDetection;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        SAMPLER(_CameraDepthTexture);
        SAMPLER(_CameraDepthNormalsTexture);


         struct a2v
         {
             float4 positionOS:POSITION;
             float2 texcoord:TEXCOORD;
         };

         struct v2f
         {
             float4 positionCS:SV_POSITION;
             float3 CameraRayDirection : TEXCOORD0; 
             float2 texcoord : TEXCOORD1;
         };



        ENDHLSL


        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG


            half luminance(half4 color){
                return 0.2125 * color.r + 0.7154 * color.g +0.0721 * color.b;
            }

            half Sobel(v2f i){

                const half Gx[9] = {-1,-2,-1,
                0,0,0,
                1,2,1
                };
                const half Gy[9] = {-1,0,1,
                -2,0,2,
                -1,0,1
                };
                
                half4 DepthNormaltex;
                half2 normaledgey=0;
                half2 normaledgex=0; 
                half depthedgey=0;
                half depthedgex=0; 
                half depth;
                half2 uv[9];
            
                uv[0] = i.texcoord + _MainTex_TexelSize.xy * half2(-1,-1);
                uv[1] = i.texcoord + _MainTex_TexelSize.xy * half2(0,-1);
                uv[2] = i.texcoord + _MainTex_TexelSize.xy * half2(1,-1);
                uv[3] = i.texcoord + _MainTex_TexelSize.xy * half2(-1,0);
                uv[4] = i.texcoord + _MainTex_TexelSize.xy * half2(0,0);
                uv[5] = i.texcoord + _MainTex_TexelSize.xy * half2(1,0);
                uv[6] = i.texcoord + _MainTex_TexelSize.xy * half2(-1,1);
                uv[7] = i.texcoord + _MainTex_TexelSize.xy * half2(0,1);
                uv[8] = i.texcoord + _MainTex_TexelSize.xy * half2(1,1);


                for(int it = 0; it < 9; it++){
                    //texColor = luminance(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv[it]));
                    DepthNormaltex = tex2D(_CameraDepthNormalsTexture,uv[it]);
                    
                    // 解码，得到线性深度
                    depth = DepthNormaltex.z + DepthNormaltex.w / 255.0;

                    // xy存储的是法线信息
                    normaledgex += DepthNormaltex.xy * Gx[it]; 
                    normaledgey += DepthNormaltex.xy * Gy[it];

                    
                    depthedgex += depth * Gx[it]; 
                    depthedgey += depth * Gy[it];

                }


                half normaledge = 1 - abs(sqrt(mul(normaledgex,normaledgex))) -abs(sqrt(mul(normaledgey,normaledgey)));
                half depthedge = 1 - abs(depthedgex) -abs(depthedgey);
                return saturate(normaledge+depthedge);

            }



            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);

                // 相机角判断
                int index = 0 ;
                if(i.texcoord.x < 0.5 && i.texcoord.y > 0.5)
                {
                    index = 0;
                }
                if(i.texcoord.x > 0.5 && i.texcoord.y > 0.5)
                {
                    index = 1;
                }
                if(i.texcoord.x > 0.5 && i.texcoord.y < 0.5)
                {
                    index = 2;
                }
                if(i.texcoord.x < 0.5 && i.texcoord.y < 0.5)
                {
                    index = 3;
                }

                o.texcoord = i.texcoord;

                o.CameraRayDirection = _ViewPortRay[index].xyz;

                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                float3 finalColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord).rgb;

                // 深度图逆推导重建世界坐标
                float depth = tex2D(_CameraDepthTexture, i.texcoord).r;
                // float3 worldPos = ComputeWorldSpacePosition(i.uv, depth*2-1, UNITY_MATRIX_I_VP);
                float4 NDCPos = float4(i.texcoord * 2 - 1,depth * 2 - 1,1);
                float4 WorldPos = mul(_InverseVPMatrix,NDCPos);
                WorldPos /= WorldPos.w;

                // 基于相机坐标重建世界坐标
                // 这玩意在runtime下貌似有点问题
                float LEyeDepth = LinearEyeDepth(depth,_ZBufferParams);
                float3 WorldPos2 = _WorldSpaceCameraPos + LEyeDepth * i.CameraRayDirection;
                

                float distanceFromCenter = distance(WorldPos.xyz, _ScanCenter);
                float L01Depth = Linear01Depth(depth,_ZBufferParams);

                // _ProjectionParams.z 远平面距离
                // L01Depth < 1 ,背景深度为1，这样可以规避扫描背景
                // _ScanDistance - distanceFromCenter < _ScanRange，保证宽度，且保证scanPercent范围01
                // 由于_ScanDistance需要比最小的distanceFromCenter要大才能有扫描效果，实际运用的时候还需要根据场景位置，摄像机位置来调整cs中的MaxScanDistance
                if (distanceFromCenter < _ScanDistance && L01Depth < 1 && _ScanDistance - distanceFromCenter < _ScanRange)
                {
                     float EdgeCircleMask = 0;
                     half edge = 0;
                    // _ScanRange 调整了扫描线的宽度，当_ScanRange比较小时，视觉上扫描过的区域会马上恢复原样（因为扫描宽度小），大时则会滞留一段时间。
                    float scanPercent = 1 - (_ScanDistance - distanceFromCenter) / _ScanRange;
                    
                    // 一个基于正弦函数的Edgemask，从圆心扩散往外
                    if(_CircleEdgeInitiate == 1)
                    {
                        EdgeCircleMask = saturate(round(sin(distanceFromCenter * _EdgeSinOmega) + _EdgeSinVerticalMove));
                    }

                    // sobel
                    if(_EdgeDetection)
                    {
                        edge = 1 - Sobel(i);
                    }

                    // pow一下能让扫描不那么拖沓
                    finalColor +=  _ScanColor.rgb * pow(scanPercent,5) + _ScanColor.rgb * scanPercent * EdgeCircleMask + _ScanColor.rgb * scanPercent * pow(edge,4) *10;

                }


            
    
                return float4(finalColor.rgb,1);
            }

            ENDHLSL
      


    }

} 
}