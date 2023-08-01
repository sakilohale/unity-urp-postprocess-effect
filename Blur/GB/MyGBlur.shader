Shader "Blur/GaussianBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("BlurSize",Range(1,10)) = 1
    }
    SubShader
    {
        Tags 
        { 
        "RenderPipeline"="UniversalRenderPipeline" 
        }


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;
        float _BlurSize;
        CBUFFER_END

        // --------------------------------------------------------------------------------------

         struct Attributes
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv[5] : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };


        // --------------------------------------------------------------------------------------

        Varyings vertVertical (Attributes IN)
        {
            Varyings OUT;
            OUT.positionCS = TransformObjectToHClip(IN.positionOS);
            float2 uv = TRANSFORM_TEX(IN.texcoord, _MainTex);

            OUT.uv[0] = uv;
            OUT.uv[1] = uv + float2(0, _MainTex_TexelSize.y) * _BlurSize;
            OUT.uv[2] = uv - float2(0, _MainTex_TexelSize.y) * _BlurSize; 
            OUT.uv[3] = uv + float2(0, _MainTex_TexelSize.y * 2) * _BlurSize;
            OUT.uv[4] = uv - float2(0, _MainTex_TexelSize.y * 2) * _BlurSize;

            return OUT;
        }

        Varyings vertHorizontal (Attributes IN)
        {
            Varyings OUT;
            OUT.positionCS = TransformObjectToHClip(IN.positionOS);
            float2 uv = TRANSFORM_TEX(IN.texcoord, _MainTex);

            OUT.uv[0] = uv;
            OUT.uv[1] = uv + float2(_MainTex_TexelSize.x, 0) * _BlurSize;
            OUT.uv[2] = uv - float2(_MainTex_TexelSize.x, 0) * _BlurSize; 
            OUT.uv[3] = uv + float2(_MainTex_TexelSize.x * 2, 0) * _BlurSize;
            OUT.uv[4] = uv - float2(_MainTex_TexelSize.x * 2, 0) * _BlurSize;

            return OUT;
        }

        float4 frag (Varyings IN) : SV_Target
        {

            float weight[3] = {0.4026, 0.2442, 0.0545};

            float3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv[0]).rgb * weight[0];

            for(int it = 1; it < 3; it++)
            {
              sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv[2*it - 1]).rgb * weight[it];
              sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv[2*it]).rgb * weight[it];
            }
            
            return float4(sum, 1.0);
        }


        ENDHLSL


        ZTest Always Cull Off ZWrite Off

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward" 
            }

            HLSLPROGRAM
            #pragma vertex vertVertical
            #pragma fragment frag

            ENDHLSL
        }


            
        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward" 
            }

            HLSLPROGRAM
            #pragma vertex vertHorizontal
            #pragma fragment frag

            ENDHLSL
        }

    }
}
