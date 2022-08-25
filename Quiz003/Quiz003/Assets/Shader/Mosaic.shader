Shader "Unlit/Mosaic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Strength("Strength",Range(0.000001,1))=0.05
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
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
            fixed _Strength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv.x=round(i.uv.x/_Strength)*_Strength;
                i.uv.y=round(i.uv.y/_Strength)*_Strength;
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a-0.1);
                return col;
            }
            ENDCG
        }
    }
}
