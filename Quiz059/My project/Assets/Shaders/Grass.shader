Shader "Grass/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindTex ("风贴图", 2D) = "white" {}
        [HDR]_Color ("颜色", Color) = (0,1,0,1)
        _Height("高度",Float)=1
        _WindSpeed("风速",Float)=2
        _WindSize("风尺寸",Float)=10

        _LowColor("草根部颜色",Color)= (1,1,1,1)
        _TopColor("草顶部颜色",Color) = (1,1,1,1)
        _MaxHight("草的最大高度",Float) = 3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WindTex;

            float _Height;
            float _WindSpeed;
            float _WindSize;
            float4 _Color;

            float4 _LowColor;
            float4 _TopColor;
            float _MaxHight;

            float GetWindWave(float2 position,float height){
                //以物体坐标点采样风的强度,
                //风按照时间*风速移动,以高度不同获得略微有差异的数据
                //移动值以高度不同进行减免,越低移动的越少.
                //根据y值获得不同的
                float4 p=tex2Dlod(_WindTex,float4(position/_WindSize+float2(_Time.x*_WindSpeed+height*.01,0),0.0,0.0)); 
                return height * saturate(p.r-.2);
            }

            v2f vert (appdata v , uint instanceID : SV_InstanceID)
            {
                v2f o;
                
                //GPU Instance 宏
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                //设置风的影响
                float4 worldPos = mul(unity_ObjectToWorld,v.vertex);
                float win = GetWindWave(worldPos.xz,v.vertex.y);
                v.vertex.x += win;
                v.vertex.y +=_Height+ win * 0.2;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.z = saturate( v.vertex.y / _MaxHight);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                
                fixed4 col = tex2D(_MainTex, i.uv.xy)*_Color;
                clip(col.a -0.6); //透明度剔除

                fixed hightColFac = i.uv.z;
                fixed3 higthCol = lerp(_LowColor,_TopColor,hightColFac);
                col = fixed4(col.rgb*higthCol , col.a); 

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}