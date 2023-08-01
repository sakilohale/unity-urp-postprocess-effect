Shader "Distortion/DistrotionMask_shader"

{

    Properties

    {
      [HideInInspector]_MainTex("MainTex",2D)="white"{}
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

        TEXTURE2D( _MainTex);
        SAMPLER(sampler_MainTex);

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
            Tags
            {
                "LightMode"="MaskOnly"
            }
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
                return float4(1,1,1,1);
            }

            ENDHLSL
        }

    }

} 