Shader "Blur/MyRBlur"

{

    Properties

    {
        _MainTex("MainTex",2D)="white"{}
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

        float _BlurRadius;
        float _Iteration;
        float4 _RadialCenter;
        float4 _MainTex_TexelSize;
        float _Intensity;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_SourceTex);
        SAMPLER(sampler_SourceTex);

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


        half4 RadialBlur(v2f i){

                float2 blurVector = (_RadialCenter.xy - i.texcoord.xy) * _BlurRadius;
                
                half4 acumulateColor = half4(0, 0, 0, 0);
                
                [unroll(30)]
                for (int j = 0; j < _Iteration; j ++)
                {
                    acumulateColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                    i.texcoord.xy += blurVector;
                }
                
                return acumulateColor / _Iteration;
        }

         v2f VERT(a2v i)

            {

                v2f o;

                o.positionCS=TransformObjectToHClip(i.positionOS.xyz);

                o.texcoord=i.texcoord;

                return o;

            }

         half4 FRAG(v2f i):SV_TARGET

            {         
                float4 blur = RadialBlur(i);


                return blur; 
                
            }

            half4 FRAG2(v2f i):SV_TARGET

            {         
                
                float4 Blur = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);
                float4 Source = SAMPLE_TEXTURE2D(_SourceTex,sampler_SourceTex,i.texcoord);

                return lerp(Source,Blur,_Intensity); 
                
            }

        ENDHLSL


        pass

        {

            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG

            ENDHLSL

        }


        pass

        {

            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG2

            ENDHLSL

        }
    }

}
