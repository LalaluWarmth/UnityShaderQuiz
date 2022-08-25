Shader "Unlit/Wave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Tint ("Tint", Color) = (1,1,1,0.5)
        _Amount("Wave Amount", Range(0,1)) = 0.5
        _Height("Wave Height", Range(0,1)) = 0.5
        _Speed("Wave Speed", Range(0,1)) = 0.5
        _FoamThickness("Foam Thickness", Range(0,50)) = 0.5
		_EdgeColor("Edge Color", Color) = (1,1,1,0.5)
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
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
            float4 _Tint,_EdgeColor;
            float _Height, _Amount, _Speed,_FoamThickness;
            float _MirrorRange, _MirrorAlpha, _MirrorFadeAlpha;

            v2f vert (appdata v)
            {
                v2f o;
                //营造水面的波浪浮动
                v.vertex.y+=sin(_Time.z*_Speed+(v.vertex.x*v.vertex.z*_Amount))*_Height;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //在纹理采样之前，会将UV坐标的xy值除以w，实现的效果是将UV坐标从正交投影变为透视投影
                float4 depthSample=SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,(i.screenPos));
                //然后用LinearEyeDepth进行还原，返回一个处于观察空间的z值
                float depth = LinearEyeDepth(depthSample);
                //(depth-i.screenPos.w)  经过MVP变换后的齐次裁剪空间坐标,w值代替了z值的作用，用来判断与摄像机的相对位置
                float foamLine=1-saturate(_FoamThickness*(depth-i.screenPos.w));
                half4 col=_Tint+foamLine*_EdgeColor*0.5;

                return col;
            }
            ENDCG
        }
    }
}
