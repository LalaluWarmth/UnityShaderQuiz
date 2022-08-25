Shader "Unlit/Eye"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Height ("Height", Float) = 0
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
            // Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Height;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewDir = normalize(_WorldSpaceCameraPos-worldPos);
                //矩阵构建
                v.normal = UnityObjectToWorldNormal(v.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 binormal = cross(v.normal,wTangent)* tangentSign;
                float3x3 world2tangent = float3x3(wTangent,binormal,v.normal);

                float2 viewL = mul(world2tangent,viewDir);

                float2 offset = _Height * viewL;
                offset.y = -offset.y;
                o.uv -= offset;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}