Shader "Unlit/ScreenBroken"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BrokenNormalMap("Broken Normal Map", 2D) = "bump"{}
        _BrokenScale("Broken Scale", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
            float4 _MainTex_ST;

            sampler2D _BrokenNormalMap;
            float4 _BrokenNormalMap_ST;

            float _BrokenScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 packedNormal=tex2D(_BrokenNormalMap,i.uv);
                fixed3 tangentNormal=UnpackNormal(packedNormal)*_BrokenScale;
                fixed4 col = tex2D(_MainTex, i.uv+tangentNormal.xy);
                return col;
            }
            ENDCG
        }
    }
}
