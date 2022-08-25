Shader "Unlit/Wave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Amount("Wave Amount", Range(0,1)) = 0.5
        _Height("Wave Height", Range(0,1)) = 0.5
        _Speed("Wave Speed", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

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
                float4 screenPos : TEXCOORD1;
                float4 changed:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Height, _Amount, _Speed;
            sampler2D _ReflectionTex;
            float4 _ReflectionTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                //营造水面的波浪浮动
                o.changed.y=sin(_Time.z*_Speed+(v.vertex.x*v.vertex.z*_Amount))*_Height;
                v.vertex.y+=sin(_Time.z*_Speed+(v.vertex.x*v.vertex.z*_Amount))*_Height;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv=TRANSFORM_TEX(v.uv,_ReflectionTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed4 col = tex2D(_ReflectionTex, i.screenPos.xy / i.screenPos.w);
                fixed4 col = tex2D(_ReflectionTex, (i.screenPos.xy-i.changed) / i.screenPos.w);
               //fixed4 col = tex2D(_ReflectionTex, i.uv);
                //fixed4 col = tex2D(_ReflectionTex, i.vertex.xy);
                return col;
            }
            ENDCG
        }
    }
}
