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
            CGPROGRAM
            #pragma vertex vert
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST, _MainTex_TexelSize;

            inline float CalculateMipmapDepth(float2 uv)
            {
                float4 depth;
                float offset = _MainTex_TexelSize.x / 2;
                depth.x = tex2D(_MainTex, uv);
                depth.y = tex2D(_MainTex, uv + float2(0, offset));
                depth.z = tex2D(_MainTex, uv + float2(offset, 0));
                depth.w = tex2D(_MainTex, uv + float2(offset, offset));
                #if defined(UNITY_REVERSED_Z)
                return min(min(depth.x, depth.y), min(depth.z, depth.w));
                #else
                return max(max(depth.x, depth.y), max(depth.z, depth.w));
                #endif
            }


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag(v2f i) : Color
            {
                float depth = CalculateMipmapDepth(i.uv);
                return float4(depth, 0, 0, 1.0f);
            }
            ENDCG
        }
    }
}