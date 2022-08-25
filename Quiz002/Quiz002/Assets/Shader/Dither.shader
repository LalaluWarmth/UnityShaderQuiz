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
            //输入屏幕齐次坐标
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
            //x 是摄像机目标纹理的宽度（以像素为单位），y 是摄像机目标纹理的高度（以像素为单位），z 是 1.0 + 1.0 / 宽度，w 为 1.0 + 1.0 / 高度。
            //IN.screenPos传入的float4类型的pos值是模型顶点的齐次裁剪空间的坐标值
            //将齐次裁剪空间的坐标映射到屏幕空间screenPosX = ((x / w) * 0.5 + 0.5) * width  screenPosY = ((y / w) * 0.5 + 0.5) * height
            float2 pos = ((IN.screenPos.xy / IN.screenPos.w) * 0.5 + 0.5) * _ScreenParams.xy;

            //clip函数会将参数小于0的像素点直接丢弃掉
            //fmod 计算除法余数
            const float2 xy = 0.5 - floor(fmod(pos.xy, t));
            clip(xy);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
