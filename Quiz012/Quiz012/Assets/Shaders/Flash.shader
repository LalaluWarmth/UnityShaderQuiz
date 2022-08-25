Shader "Unlit/Flash"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RadiusTex ("RadiusTex", 2D) = "white" {}
        _Dist ("Dist", Range(0,1)) = 0.0
        _U("U", Float) = 1.0
        _V("V", Float) = 1.0
        _SmoothstepMax("SmoothStep Max", Float) = 0.51
        _Inverse("Inverse", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        LOD 100

        GrabPass
        {
            "_BackgroundTexture"
        }

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
                float4 grabPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _RadiusTex;
            sampler2D _BackgroundTexture;
            float4 _MainTex_ST;
            float _Dist,_U,_V,_SmoothstepMax,_Inverse;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            float2 PolarCoordinates (float2 uv, float2 center, float radialScale, float lengthScale)
            {
                float2 delta=uv-center;
                float radius=length(delta)*2*radialScale;
                float angle=atan2(delta.x,delta.y)*1.0/6.28*lengthScale;
                return float2(radius,angle);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 polar=PolarCoordinates(i.grabPos/i.grabPos.w,float2(0.5,0.5),0.1,5);


                _Dist = _Time.y;

                float2 newUV=polar+_Dist*float2(_U,_V);
                fixed4 radiusCol = tex2D(_RadiusTex, newUV);

                fixed4 screenCol = tex2Dproj(_BackgroundTexture, i.grabPos);

                fixed4 mixedCol=screenCol.r*radiusCol.r+screenCol.r;

                float s;

                if(_Inverse==1){
                    s=smoothstep(_SmoothstepMax-0.02,_SmoothstepMax,mixedCol);
                }else{
                    s=smoothstep(_SmoothstepMax,_SmoothstepMax-0.02,mixedCol);
                }
                


                return fixed4(s,s,s,1);
            }
            ENDCG
        }
    }
}
