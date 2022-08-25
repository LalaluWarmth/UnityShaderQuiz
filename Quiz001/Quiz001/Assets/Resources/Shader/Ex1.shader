Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _Transparency("Transparency", Range(0,1)) = 0
        _Speed("Speed", Range(0,500)) = 200
        _GlitchSustain("GlitchSustain", Range(0.001,0.01)) = 0.002
        _LineSpacing("LineSpacing", Range(20,200)) = 100
        _GlitchHeight("GlitchHeight", Range(0,20)) = 10
        _GlitchWidth("GlitchWidth", Range(0.1, 1)) = 0.3
        _GlitchRate("GlitchRate", Range(0, 10)) = 5
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Transparency;
        float _Speed;
        float _GlitchSustain;
        float _LineSpacing;
        float _GlitchHeight;
        float _GlitchWidth;
        float _GlitchRate;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            const float t = 2 / (2 - _Transparency);
            float2 pos = IN.screenPos.xy / IN.screenPos.w * _ScreenParams.xy;
            const float x = 0.5 - floor(fmod(pos.x, t));
            const float y = 0.5 - floor(fmod(pos.y, t));
            const float yLow = floor(fmod(pos.y + _Time.y * _Speed, _LineSpacing));
            const float yHigh = floor(fmod(pos.y - _GlitchHeight + _Time.y * _Speed, _LineSpacing));
            const float yTest = ceil((_GlitchHeight - yLow) / _LineSpacing);

            // Albedo comes from a texture tinted by color
            const float sinT = sin(_Time.y * _GlitchRate);
            const float sin = (ceil((sinT + 1) / 2 + _GlitchSustain * _GlitchRate) - 1) * _GlitchWidth + 1;
            const float2 uv = float2((IN.uv_MainTex.x - 0.5) / ((sin - 1) * yTest + 1) + 0.5, IN.uv_MainTex.y);
            fixed4 c = tex2D(_MainTex, uv) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            clip(c.a - 0.01);
            clip(x * y);
            clip(yLow - 2);
            clip(yHigh - 1);
            //clip(1.5 - floor(fmod(pos.y, t)));
        }
        ENDCG
    }
    FallBack "Diffuse"
}