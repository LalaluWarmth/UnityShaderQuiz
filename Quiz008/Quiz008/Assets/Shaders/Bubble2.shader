Shader "Unlit/Bubble2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _CubeMap ("Cube Map", Cube) = "" {}
        _Reflection ("Reflection", Range(0,1)) = 0
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor;
            samplerCUBE  _CubeMap;
            float _Reflection;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);

                o.worldNormal=mul(v.normal,(float3x3)unity_WorldToObject);
                o.worldNormal=normalize(o.worldNormal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv)*_MainColor;

                float3 viewDir=i.worldPos.xyz-_WorldSpaceCameraPos;
                viewDir=normalize(viewDir);

                float3 refDir=2*dot(-viewDir,i.worldNormal)*i.worldNormal+viewDir;
                refDir=normalize(refDir);

                float4 reflection=texCUBE(_CubeMap,refDir);

                fixed4 fCol=lerp(col,reflection,_Reflection);
                return fCol;
            }
            ENDCG
        }
    }
}
