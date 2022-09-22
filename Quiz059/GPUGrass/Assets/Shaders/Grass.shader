Shader "Unlit/Grass"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white"{}
        [MainColor] _BaseColor("Color",Color)=(1,1,1,1)
        _Cutoff("Alpha Cutoff",Range(0.0,1.0))=0.5

        //风
        _NoiseMap("WaveNoiseMap",2D)="white"{}
        _Wind("Wind(x,y,z,strength)",Vector)=(1,0,0,0)
        _WindNoiseStrength("WindNoiseStrength",Range(0,20))=10
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True"
        }
        LOD 100

        Pass
        {
            ZWrite On
            ZTest On
            Cull off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            struct Attribute
            {
                float4 positionOS:POSITION;
                float2 uv:TEXCOORD0;
                float3 normalOS:NORMAL;
                //GPU Instance实例索引
                uint instanceID:SV_INSTANCEID;
            };

            struct Varyings
            {
                float2 uv:TEXCOORD0;
                float4 positionCS:SV_POSITION;
                float3 normalWS:TEXCOORD1;
                float4 positionWS:TEXCOORD2;
            };

            #pragma vertex PassVertex
            #pragma fragment PassFragment

            //透明度裁剪
            float _Cutoff;
            half4 _BaseColor;

            TEXTURE2D_X(_BaseMap);
            SAMPLER(sampler_BaseMap);

            //Terrain本地转换至世界坐标的矩阵，由脚本传入
            float4x4 _TerrainLocalToWorld;
            //草的大小，由脚本传入
            float2 _GrassQuadSize;

            #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                struct GrassInfo{
                    //Terrain的本地空间下的位置旋转缩放转换矩阵
                    float4x4 localToTerrain;
                    //id
                    int id;
                };
                //声明结构化缓冲区
                StructuredBuffer<GrassInfo> _GrassInfos;
            #endif

            //风
            sampler2D _NoiseMap;
            float4 _Wind;
            float _WindNoiseStrength;

            //添加风的作用
            //positonWS 草的顶点的世界坐标
            //grassUpWS 草的朝上方向的世界坐标
            //windDir 风的方向。单位向量
            //windStrength 风的强度，Range(0,1)
            //vertexLocalHeight 草的高度
            float3 applyWind(float3 positionWS, float3 grassUpWS, float3 windDir, float windStrength,
                             float vertexLocalHeight)
            {
                //根据风的强度，计算草的弯曲程度，Range(0,90)
                float rad = windStrength * PI * 0.9 / 2;
                //windDir和grassUpWS的正交向量
                windDir = normalize(windDir - dot(windDir, grassUpWS) * grassUpWS);

                //弯曲后，x为单位球在wind方向上的计量，y为单位球在grassUp上的计量
                float x, y;
                sincos(rad, x, y);

                //grassUpWs的顶点在风力作用下会偏移到的位置
                float3 windedPos = x * windDir + y * grassUpWS;

                return positionWS + (windedPos - grassUpWS) * vertexLocalHeight;
            }

            Varyings PassVertex(Attribute input)
            {
                Varyings output;
                float2 uv = input.uv;
                float3 positionOS = input.positionOS;
                float3 normalOS = input.normalOS;
                uint instanceID = input.instanceID;
                //通过_GrassQuadSize来控制面片大小
                positionOS.xy = positionOS.xy * _GrassQuadSize;

                #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                    //通过每个实例索引，去访问这个数组,获取本株草的生成信息
                    GrassInfo grassInfo=_GrassInfos[instanceID];

                    //将Quad的本地空间的顶点和法线转换到Terrain的本地空间
                    positionOS=mul(grassInfo.localToTerrain,float4(positionOS,1)).xyz;
                    normalOS=mul(grassInfo.localToTerrain,float4(normalOS,0)).xyz;
                #endif

                //从Terrain本地坐标转换到世界坐标
                float4 positionWS = mul(_TerrainLocalToWorld, float4(positionOS, 1));
                positionWS /= positionWS.w;


                //-----------------------------Wind Start----------------------------
                //草的朝上的方向
                float3 grassUpDir = float3(0, 1, 0);
                grassUpDir = normalize(mul(_TerrainLocalToWorld, float4(grassUpDir, 0)));
                //风的方向
                float3 windDir = normalize(_Wind.xyz);

                //风随时间扰动
                float time = _Time.y;
                //生成一个扰动
                float2 noiseUV = (positionWS.xz - time) / 30;
                //tex2d 采样纹理，在vs中不可用
                //tex2dlod 根据采样点坐标和mip级别，计算偏移值，然后采样，在vs/fs中均可用 （lod -- Level-of-detail）
                float noiseValue = tex2Dlod(_NoiseMap, float4(noiseUV, 0, 0)).r;

                //风的强度
                float windStrength = _Wind.w + noiseValue;

                positionWS.xyz = applyWind(positionWS.xyz, grassUpDir, windDir, windStrength, positionOS.y);
                //-----------------------------Wind End----------------------------


                output.uv = uv;
                output.positionWS = positionWS;
                output.positionCS = mul(UNITY_MATRIX_VP, positionWS);
                output.normalWS = mul(unity_ObjectToWorld, float4(normalOS, 0.0)).xyz;
                return output;
            }

            half4 PassFragment(Varyings input):SV_TARGET
            {
                half4 diffuseColor = SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, input.uv);
                //透明度裁剪
                if (diffuseColor.a < _Cutoff)
                {
                    discard;
                    return 0;
                }

                //计算光照和阴影，光照使用兰伯特
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = mainLight.direction;
                float3 lightColor = mainLight.color;
                float3 normalWS = input.normalWS;
                float4 color = float4(1, 1, 1, 1);
                //为避免光向和normal的点积因为光照接近90度而太暗，设置最小值
                float minDotLightAndNormal = 0.2;

                color.rgb = max(minDotLightAndNormal, abs(dot(lightDir, normalWS))) * lightColor * diffuseColor.rgb *
                    _BaseColor.rgb * mainLight.shadowAttenuation;

                return color;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}