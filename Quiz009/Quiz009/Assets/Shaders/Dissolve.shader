Shader "Unlit/Dissolve"
{
    Properties {
        // ��������ǿ��
        _AmbientStrength ("Ambient Strength", Range(1.0, 10.0)) = 1.0

        // ���ڳ̶�
        _BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0

        // �ս��̶ȵ��߿�
        _LineWidth ("Burn Line Width", Range(0.0, 0.2)) = 0.1

        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BumpMap ("Normap Map", 2D) = "bump" {}

        // �����Ե��������ɫֵ
        _BurnFirstColor ("Burn First Color", Color) = (1, 0, 0, 1)
        _BurnSecondColor ("Burn Second Color", Color) = (1, 0, 0, 1)

        // ��������
        _BurnMap ("Burn Map", 2D) = "white" {}
    }

    SubShader {
        Tags {"RenderType"="Opaque" "Queue"="Geometry"}

        Pass {
            Tags {"LigthMode" = "ForwardBase"}

            // �ر�����Ƭ�޳���ģ�͵�����ͱ��涼�ᱻ��Ⱦ����Ϊ���ڻᵼ����¶��ģ���ڲ��Ĺ���
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

                // ʹ��TRANSFORM_TEX() ���������������Ӧ����������
                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                // �ѹ�Դ�����ģ�Ϳռ�任Ϊ���߿ռ�
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                // ����������ռ��µĶ���λ��
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // ������Ӱ����Ĳ�������
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                // ������������в���
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap);
                // �����С��0 ʱ�������ػᱻ�޳����Ӷ�������ʾ����Ļ�ϣ�������������Ĺ��ռ���
                clip(burn.r - _BurnAmount);


                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

                // ������albedo
                fixed3 albedo = tex2D(_MainTex, i.uvMainTex);
                // ��������
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo * _AmbientStrength;
                // ���������
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // �����ս���ɫburnColor����Ҫ���ڿ��Ϊ_LineWidth �ķ�Χ��ģ���ս�����ɫ�仯
                // ʹ��smoothstep() ������������ϵ�� t
                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
                // ��t Ϊ1 ʱ������������λ�����ڵı߽紦����t Ϊ0 ʱ������������Ϊ������ģ����ɫ
                // ��t ������ֻ�����ɫ_BurnFirstColor, _BurnSecondColor
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
                // Ϊ����Ч�����ӽ��ս��ĺۼ���������pow() �Խ�����д���
                burnColor = pow(burnColor, 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // ��t ����������Ĺ�����ɫ��������+�����䣩���ս���ɫ
                // ʹ��step() ��֤��_BurnAmount Ϊ0 ʱ����ʾ�κ�����Ч��
                fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));

                return fixed4(finalColor, 1);
            }

            ENDCG
        }


        // ��������Ͷ����Ӱ��Pass��ʵ�ֵ���������ʱ����Ӱ��Ӧ�����仯
        // ��ӰͶ����ص�������Ҫ������Pass �Ĵ������޳�ƬԪ����ж��㶯�����Ա���Ӱ���Ժ�����������Ⱦ�Ľ����ƥ��
        // ʹ��Unity ���õ�V2F_SHADOW_CASTER��TRANSFER_SHADOW_CASTER_NORMALOFFSET��SHADOW_CASTER_FRAGMENT ����������ӰͶ��ʱ��Ҫ�ĸ��ֱ���
        Pass {
            // ����Ͷ����Ӱ��Pass ��LightMode ��������ΪLightMode
            Tags {"LightMode" = "ShadowCaster"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // ����Ҫ#pragma multi_compile_shadowcaster ָ������Ҫ�ı���ָ��
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            fixed _BurnAmount;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct v2f {
                // ʹ��V2F_SHADOW_CASTER ������ӰͶ����Ҫ����ı���
                V2F_SHADOW_CASTER;
                float2 uvBurnMap : TEXCOORD1;
            };

            v2f vert(appdata_base v) {
                v2f o;

                // ���V2F_SHADOW_CASTER ����������һЩ����
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                // �Զ�����㲿�֣�������������Ĳ�������uvBurnMap
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                return o;
            }

            fixed4 frag(v2f i): SV_Target {
                // ����һ��ƬԪ��ɫ��һ����ʹ����������Ĳ������޳�ƬԪ
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
                clip(burn.r - _BurnAmount);

                // ������SHADOW_CASTER_FRAGMENT ����Unity �����ӰͶ��Ĳ���
                // �ѽ����������ͼ����Ӱӳ��������
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}