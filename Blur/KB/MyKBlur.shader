Shader "Blur/MyKBlur"

{

    Properties

    {

      _MainTex("MainTex",2D)="white"{}

      _BlurSize("Blur",float)=2

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

        float _BlurSize;

        float4 _MainTex_TexelSize;

        CBUFFER_END

        TEXTURE2D(_MainTex);

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

         v2f VERT(a2v i)

            {

                v2f o;

                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord=i.texcoord;

                return o;

            }

         half4 FRAG(v2f i):SV_TARGET

            {         
                
                half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);

                tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(-1,-1)*_MainTex_TexelSize.xy*_BlurSize);
                tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(1,-1)*_MainTex_TexelSize.xy*_BlurSize);
                tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(-1,1)*_MainTex_TexelSize.xy*_BlurSize);
                tex+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord+float2(1,1)*_MainTex_TexelSize.xy*_BlurSize);

                return tex/5.0;

            }

        ENDHLSL


        pass

        {

            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG

            ENDHLSL

        }

    }

}
