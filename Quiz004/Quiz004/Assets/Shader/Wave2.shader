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
                //Ӫ��ˮ��Ĳ��˸���
                v.vertex.y+=sin(_Time.z*_Speed+(v.vertex.x*v.vertex.z*_Amount))*_Height;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //���������֮ǰ���ὫUV�����xyֵ����w��ʵ�ֵ�Ч���ǽ�UV���������ͶӰ��Ϊ͸��ͶӰ
                float4 depthSample=SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,(i.screenPos));
                //Ȼ����LinearEyeDepth���л�ԭ������һ�����ڹ۲�ռ��zֵ
                float depth = LinearEyeDepth(depthSample);
                //(depth-i.screenPos.w)  ����MVP�任�����βü��ռ�����,wֵ������zֵ�����ã������ж�������������λ��
                float foamLine=1-saturate(_FoamThickness*(depth-i.screenPos.w));
                half4 col=_Tint+foamLine*_EdgeColor*0.5;

                return col;
            }
            ENDCG
        }
    }
}
