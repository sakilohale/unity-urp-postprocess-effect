Shader "Distortion/mask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
    }
    SubShader
    {
        Tags 
        { 
        "RenderPipeline"="UniversalRenderPipeline" 
        "RenderType"="Transparent" 
        "Queue"="Transparent" 
        "LightMode" = "UniversalForward"
        }


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        CBUFFER_END

        // --------------------------------------------------------------------------------------

         struct Attributes
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };


        // --------------------------------------------------------------------------------------

        Varyings vert (Attributes IN)
        {
            Varyings OUT;
            OUT.positionCS = TransformObjectToHClip(IN.positionOS);
            OUT.uv = TRANSFORM_TEX(IN.texcoord, _MainTex);
            return OUT;
        }

        float4 frag (Varyings IN) : SV_Target
        {
            float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.uv);
            return float4(1,1,1,0);
        }


        ENDHLSL



        Pass
        {
            Blend Zero One

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL
        }
    }
}
