// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/Bubble"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPow ("Rim Pow", float) = 2.0
        _Alpha ("Alpha", Range(0,1)) = 0.5
        //_NormalMap ("Normal Map", 2D) = "bump" {}
        //_NormalScale ("NormalScale", float) = 1
        //_Distortion ("Distortion",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        GrabPass {
          "_GrabTexture"
        }
        
        Pass
        {
            ZWrite Off
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
                float3 normal : NORMAL;
                float4 posWorld : TEXCOORD1;
                float4 grabtex : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _GrabTexture;
            //float4 _GrabTexture_TexelSize;
            //sampler2D _NormalMap;
            //float _NormalScale,_Distortion;
            float4 _MainTex_ST;
            float _RimPow;
            float4 _RimColor;
            float _Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                float3 value=(cos(5.0*v.vertex.y+_Time.y)*0.015+sin(5.0*v.vertex.y+_Time.y)*0.005).xxx;
                v.vertex.xyz+=value;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal=mul(float4(v.normal,0),unity_WorldToObject).xyz;
                o.posWorld=mul(unity_ObjectToWorld,v.vertex);
                o.grabtex=ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldViewDirNor=normalize(UnityWorldSpaceViewDir(i.posWorld));
                float3 worldViewDir=UnityWorldSpaceViewDir(i.posWorld);
                float3 worldNormal=UnityObjectToWorldNormal(i.normal);
                float rimValue=pow((1-dot(worldViewDirNor,i.normal)),_RimPow);
                float4 Emissive=float4(_RimColor.rgb*rimValue*_Alpha,1.0);

                
                float3 refractDir_r=refract(-worldViewDirNor,normalize(worldNormal), 1/(1.05-0.02));
                float3 newPosWorld_r= -refractDir_r+_WorldSpaceCameraPos;
                float4 refract_r = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(ComputeGrabScreenPos(mul(UNITY_MATRIX_VP,float4(newPosWorld_r, 1.0)))));
                float3 refractDir_g=refract(-worldViewDirNor,normalize(worldNormal), 1/(1.05));
                float3 newPosWorld_g= -refractDir_g+_WorldSpaceCameraPos;
                float4 refract_g = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(ComputeGrabScreenPos(mul(UNITY_MATRIX_VP,float4(newPosWorld_g, 1.0)))));
                float3 refractDir_b=refract(-worldViewDirNor,normalize(worldNormal), 1/(1.05+0.02));
                float3 newPosWorld_b= -refractDir_b+_WorldSpaceCameraPos;
                float4 refract_b = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(ComputeGrabScreenPos(mul(UNITY_MATRIX_VP,float4(newPosWorld_b, 1.0)))));
                float4 refractCol=float4(refract_r.r,refract_g.g,refract_b.b,1.0);

                //float3 bump=UnpackNormal(tex2D(_NormalMap,i.uv)).rgb;
                //bump.xy*=_NormalScale;
                //bump=normalize(bump);
                //float2 offset = bump.xy*_Distortion*_GrabTexture_TexelSize.xy;
                //i.grabtex.xyz/=i.grabtex.w;
                //float4 refractCol=tex2D(_GrabTexture,UNITY_PROJ_COORD(i.grabtex.xy+offset));

                float4 col;
                col=refractCol+Emissive;
                return col;
            }
            ENDCG
        }
    }
}
