Shader "Unlit/DepthTextureMipmapCalculator"
{
    Properties
    {
        _MainTex ("Previous Mipmap", 2D) = "black" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {


            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            #pragma vertex PassVertex
            #pragma fragment PassFragment


            sampler2D _MainTex;
            float4 _MainTex_ST, _MainTex_TexelSize;

            inline float CalculateMipmapDepth(float2 uv)
            {
                float4 depth;
                float offset = _MainTex_TexelSize.x / 2;
                depth.x = tex2D(_MainTex, uv);
                depth.y = tex2D(_MainTex, uv - float2(0, offset));
                depth.z = tex2D(_MainTex, uv - float2(offset, 0));
                depth.w = tex2D(_MainTex, uv - float2(offset, offset));
                #if defined(UNITY_REVERSED_Z)
                return min(min(depth.x, depth.y), min(depth.z, depth.w));
                #else
                return max(max(depth.x, depth.y), max(depth.z, depth.w));
                #endif
            }


            Varyings PassVertex(Attribute v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                // o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                return o;
            }

            half4 PassFragment(Varyings i) : SV_TARGET
            {
                float depth = CalculateMipmapDepth(i.uv);
                return float4(depth.x, 0, 0, 1.0f);
            }
            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex PassVertex
            #pragma fragment PassFragment


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 scrPos : TEXCOORD1;
            };

            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            Varyings PassVertex(Attribute v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.scrPos = ComputeScreenPos(vertexInput.positionCS);
                return o;
            }

            half4 PassFragment(Varyings i) : SV_TARGET
            {
                half2 screenPos = i.scrPos.xy / i.scrPos.w;
                float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
                return float4(depth.x, 0, 0, 1.0f);
            }
            ENDHLSL
        }
    }
}