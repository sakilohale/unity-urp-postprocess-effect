Shader "Distortion/DistrotionMerge_shader"

{

    Properties

    {
      [HideInInspector]_MainTex("MainTex",2D)="white"{}
      _NoiseTex("NoiseTex",2D)="white"{}
      
    }

    SubShader
    {

        Tags{
        "RenderPipeline"="UniversalRenderPipeline"
        "RenderType" = "Opaque"
        }



        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
    
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NoiseTex);
        SAMPLER(sampler_NoiseTex);
        SAMPLER(_DistortionMaskTexture);

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
                o.texcoord=i.texcoord;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {   
                //获取扭曲遮罩
                half DistortionMask = tex2D(_DistortionMaskTexture,i.texcoord).r;
                
                //采样噪声
                float noise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.texcoord + _Time.y * 0.1).r;
            
                float offset = DistortionMask * noise * 0.01;
                float2 uv = i.texcoord + offset;

                half3 texCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv).rgb;

    

                return float4(texCol,1);
            }

            ENDHLSL
        }

    }

} 