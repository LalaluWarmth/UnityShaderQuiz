Shader "Unlit/Dissolve"
{
    Properties {
        // 环境光照强度
        _AmbientStrength ("Ambient Strength", Range(1.0, 10.0)) = 1.0

        // 消融程度
        _BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0

        // 烧焦程度的线宽
        _LineWidth ("Burn Line Width", Range(0.0, 0.2)) = 0.1

        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BumpMap ("Normap Map", 2D) = "bump" {}

        // 火焰边缘的两种颜色值
        _BurnFirstColor ("Burn First Color", Color) = (1, 0, 0, 1)
        _BurnSecondColor ("Burn Second Color", Color) = (1, 0, 0, 1)

        // 噪声纹理
        _BurnMap ("Burn Map", 2D) = "white" {}
    }

    SubShader {
        Tags {"RenderType"="Opaque" "Queue"="Geometry"}

        Pass {
            Tags {"LigthMode" = "ForwardBase"}

            // 关闭了面片剔除，模型的正面和背面都会被渲染，因为消融会导致裸露，模型内部的构造
            Cull Off

            CGPROGRAM

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            fixed _AmbientStrength;
            fixed _BurnAmount;
            fixed _LineWidth;
            sampler2D _MainTex;
            sampler2D _BumpMap;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _BurnMap;

            float4 _MainTex_ST;
            float4 _BumpMap_ST;
            float4 _BurnMap_ST;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 使用TRANSFORM_TEX() 计算了三张纹理对应的纹理坐标
                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                // 把光源方向从模型空间变换为切线空间
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                // 计算了世界空间下的顶点位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 计算阴影纹理的采样坐标
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                // 对噪声纹理进行采样
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap);
                // 当结果小于0 时，该像素会被剔除，从而不会显示到屏幕上；否则进行正常的光照计算
                clip(burn.r - _BurnAmount);


                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

                // 反射率albedo
                fixed3 albedo = tex2D(_MainTex, i.uvMainTex);
                // 环境光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo * _AmbientStrength;
                // 漫反射光照
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // 计算烧焦颜色burnColor。想要得在宽度为_LineWidth 的范围内模拟烧焦的颜色变化
                // 使用smoothstep() 函数来计算混合系数 t
                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
                // 当t 为1 时，表明该像素位于消融的边界处；当t 为0 时，表明该像素为正常的模型颜色
                // 用t 混合两种火焰颜色_BurnFirstColor, _BurnSecondColor
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
                // 为了让效果更接近烧焦的痕迹，还是用pow() 对结果进行处理
                burnColor = pow(burnColor, 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // 用t 来混合正常的光照颜色（环境光+漫反射）和烧焦颜色
                // 使用step() 保证当_BurnAmount 为0 时不显示任何消融效果
                fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));

                return fixed4(finalColor, 1);
            }

            ENDCG
        }


        // 定义用于投射阴影的Pass，实现当物体消融时，阴影对应发生变化
        // 阴影投射的重点在于需要按正常Pass 的处理来剔除片元或进行顶点动画，以便阴影可以和物体正常渲染的结果相匹配
        // 使用Unity 内置的V2F_SHADOW_CASTER、TRANSFER_SHADOW_CASTER_NORMALOFFSET、SHADOW_CASTER_FRAGMENT 帮助计算阴影投射时需要的各种变量
        Pass {
            // 用于投射阴影的Pass 的LightMode 必须设置为LightMode
            Tags {"LightMode" = "ShadowCaster"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // 还需要#pragma multi_compile_shadowcaster 指明它需要的编译指令
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            fixed _BurnAmount;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct v2f {
                // 使用V2F_SHADOW_CASTER 定义阴影投射需要定义的变量
                V2F_SHADOW_CASTER;
                float2 uvBurnMap : TEXCOORD1;
            };

            v2f vert(appdata_base v) {
                v2f o;

                // 填充V2F_SHADOW_CASTER 背后声明的一些变量
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                // 自定义计算部分，计算噪声纹理的采样坐标uvBurnMap
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                return o;
            }

            fixed4 frag(v2f i): SV_Target {
                // 和上一个片元着色器一样，使用噪声纹理的采样来剔除片元
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
                clip(burn.r - _BurnAmount);

                // 再利用SHADOW_CASTER_FRAGMENT 来让Unity 完成阴影投射的部分
                // 把结果输出到深度图和阴影映射纹理中
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}