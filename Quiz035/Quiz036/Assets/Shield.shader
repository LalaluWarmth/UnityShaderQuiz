Shader "Unlit/Shield"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_Color("颜色",Color)=(1,1,1,1)
        _Strength("波浪度",Range(0,1))=0
        _Distance("扩散距离",Range(0,0.05))=0.01
        _FresnelPower("菲涅尔power",Range(0,10))=5
        _FresnelScale("菲涅尔比例",Range(0,1))=1

        _MaskRadius("遮罩半径",Range(0,3))=0
        _MaskSmooth("羽化",Range(0,1))=0
        [HDR]_CollisionColor("碰撞颜色",Color)=(1,1,1,1)


    }
    SubShader
    {
        Tags
        {
            "RenderType"="transparent" "queue"="transparent"
        }
        LOD 100

        Pass
        {
            blend srccolor one
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            float _Strength;
            float _Distance;
            float _FresnelPower;
            float4 _Color;
            float _FresnelScale;
            float4 _InteractPoint;
            float _MaskSmooth;
            float4 _CollisionColor;
            float _Toggle;

            float _MaskRadius;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 objPos:TEXCOORD1;

                float3 worldNormal:TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;


                v.vertex += _Distance * float4((_Strength + _SinTime.w) * v.normal, 0);
                o.objPos = v.vertex;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 worldPos = mul(unity_ObjectToWorld, i.objPos);
                float dt = smoothstep(_MaskRadius + _MaskSmooth, _MaskRadius - _MaskSmooth,
                                      distance(worldPos, _InteractPoint));
                float3 viewDir = normalize(WorldSpaceViewDir(i.objPos));
                float fresnel = _FresnelScale * pow(1 - abs(dot(viewDir, i.worldNormal)), _FresnelPower);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * (fresnel * _Color + _CollisionColor * dt * _Toggle);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}