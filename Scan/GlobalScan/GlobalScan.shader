Shader "scan/GlobalScan"

{

    Properties

    {
      [HideInInspector]_MainTex("MainTex",2D)="white"{}
      _ScanDistance("scanDistance",Range(0,1)) = 0
      _ScanRange("ScanRange",Range(0,1)) = 0
      [HDR]_ScanColor("ScanColor",Color) = (0,0,0,1)
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
        half4 _MainTex_ST;
        half4 _MainTex_TexelSize;
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

             float2 texcoord:TEXCOORD;

         };



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




        ENDHLSL


        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG
            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);
                // o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.texcoord = i.texcoord;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                float3 finalColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);

                float depth = tex2D(_CameraDepthTexture, i.texcoord).r;

                float L01Depth = Linear01Depth(depth,_ZBufferParams);

                if(L01Depth < _ScanDistance && L01Depth <1 && _ScanDistance - L01Depth < _ScanRange)
                {   
                    half edge = 0;

                    float scanPercent = saturate((1 - (_ScanDistance - L01Depth)*7) / (_ScanRange * 2));
                    finalColor = lerp(finalColor.rgb,_ScanColor.rgb,scanPercent);

                    // sobel
                    if(_EdgeDetection == 1)
                    {
                        edge = 1 - Sobel(i);
                    }

                    finalColor += _ScanColor.rgb * scanPercent * pow(edge,4) *10;
                }


                return float4(finalColor.rgb,1);
            }

            ENDHLSL
        }

    }

} 