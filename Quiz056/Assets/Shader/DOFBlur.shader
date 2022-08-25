Shader "PostEffect/DOFBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
    }

    SubShader
    {
        Cull Off ZWrite On ZTest Off
        Tags { "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            CGPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag
            #include"UnityCG.cginc"

            sampler2D _MainTex;
            float2 _FocusScreenPosition;
            float _FocusPower;

            //声明摄像机深度
            sampler2D _CameraDepthTexture;
            float4 _MainTex_TexelSize;

            float _focalDistance, _farBlurScale, _farBlurScalePower, _nearBlurScale, _nearBlurScalePower;

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f Vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                if (_MainTex_TexelSize.y < 0) 
                o.uv.y = 1 - o.uv.y;
                return o;
            }

            float4 Frag(v2f i): SV_Target
            {
                float2 uv = i.uv;

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);

                float final_res_depth = 0;
                float offset = 0;

                if (1-depth > _focalDistance)
                {
                    final_res_depth = saturate(_farBlurScale * (1 - depth - _focalDistance) * (1 - depth - _focalDistance));
                    offset = _FocusPower * pow(final_res_depth, _farBlurScalePower);
                }
                else
                {
                    final_res_depth = saturate(_nearBlurScale * (1 - depth - _focalDistance) * (1 - depth - _focalDistance));
                    offset = _FocusPower * pow(final_res_depth, _nearBlurScalePower);
                }

                half2 uv1 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(1, 0) * - 2.0;
                half2 uv2 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(1, 0) * - 1.0;
                half2 uv3 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(1, 0) * 0.0;
                half2 uv4 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(1, 0) * 1.0;
                half2 uv5 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(1, 0) * 2.0;
                half4 s = 0;

                s += tex2D(_MainTex, uv1) * 0.0545;
                s += tex2D(_MainTex, uv2) * 0.2442;
                s += tex2D(_MainTex, uv3) * 0.4026;
                s += tex2D(_MainTex, uv4) * 0.2442;
                s += tex2D(_MainTex, uv5) * 0.0545;

                return s;
            }
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            sampler2D _MainTex;
            float2 _FocusScreenPosition;
            float _FocusPower;

            //声明摄像机深度
            sampler2D _CameraDepthTexture;
            float4 _MainTex_TexelSize;

            float _focalDistance, _farBlurScale, _farBlurScalePower, _nearBlurScale, _nearBlurScalePower;

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f Vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                if (_MainTex_TexelSize.y < 0) 
                o.uv.y = 1 - o.uv.y;
                return o;
            }

            float4 Frag(v2f i): SV_Target
            {
                float2 uv = i.uv;

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);

                float final_res_depth = 0;
                float offset = 0;

                if (1-depth > _focalDistance)
                {
                    final_res_depth = saturate(_farBlurScale * (1 - depth - _focalDistance) * (1 - depth - _focalDistance));
                    offset = _FocusPower * pow(final_res_depth, _farBlurScalePower);
                }
                else
                {
                    final_res_depth = saturate(_nearBlurScale * (1 - depth - _focalDistance) * (1 - depth - _focalDistance));
                    offset = _FocusPower * pow(final_res_depth, _nearBlurScalePower);
                }

                half2 uv1 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(0, 1) * - 2.0;
                half2 uv2 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(0, 1) * - 1.0;
                half2 uv3 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(0, 1) * 0.0;
                half2 uv4 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(0, 1) * 1.0;
                half2 uv5 = uv + half2(offset / _ScreenParams.x, offset / _ScreenParams.y) * half2(0, 1) * 2.0;
                half4 s = 0;

                s += tex2D(_MainTex, uv1) * 0.0545;
                s += tex2D(_MainTex, uv2) * 0.2442;
                s += tex2D(_MainTex, uv3) * 0.4026;
                s += tex2D(_MainTex, uv4) * 0.2442;
                s += tex2D(_MainTex, uv5) * 0.0545;

                return s;
            }
            ENDCG

        }
    }
}