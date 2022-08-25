Shader "Custom/Dither"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Transparency ("Transparency", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            //������Ļ�������
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Transparency;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            

            const float t = 1 / (1.00001 - _Transparency);

            //float4 _ScreenParams(Built-in shader variables):
            //x �������Ŀ������Ŀ�ȣ�������Ϊ��λ����y �������Ŀ������ĸ߶ȣ�������Ϊ��λ����z �� 1.0 + 1.0 / ��ȣ�w Ϊ 1.0 + 1.0 / �߶ȡ�
            //IN.screenPos�����float4���͵�posֵ��ģ�Ͷ������βü��ռ������ֵ
            //����βü��ռ������ӳ�䵽��Ļ�ռ�screenPosX = ((x / w) * 0.5 + 0.5) * width  screenPosY = ((y / w) * 0.5 + 0.5) * height
            float2 pos = ((IN.screenPos.xy / IN.screenPos.w) * 0.5 + 0.5) * _ScreenParams.xy;

            //clip�����Ὣ����С��0�����ص�ֱ�Ӷ�����
            //fmod �����������
            const float2 xy = 0.5 - floor(fmod(pos.xy, t));
            clip(xy);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
