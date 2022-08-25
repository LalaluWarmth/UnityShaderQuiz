Shader "CustomCartoon/SimpleCartoon_old"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1)
		_ShadowColor("Shadow Color", Color) = (0.7, 0.7, 0.8)
		_ShadowRange("Shadow Range", Range(0, 1)) = 0.5
		_RampTex("Ramp Tex", 2D) = "white" {}

		[Space(10)]
		_OutlineWidth("Outline Width", Range(0.01, 2)) = 0.24
		_OutLineColor("OutLine Color", Color) = (0.5,0.5,0.5,1)

		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimMin("Rim Min", Range(0,2)) = 0
		_RimMax("Rim Max", Range(0,2)) = 0.5
		_RimSmooth("Rim Smooth", Range(0,2)) = 0.5
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }

			pass
			{
				Tags {"LightMode" = "ForwardBase"}

				Cull Back

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "AutoLight.cginc"
				sampler2D _MainTex,_RampTex,_ShadowRamp;
				float4 _MainTex_ST;
				float4 _Forward, _Left;
				half3 _MainColor;
				half3 _ShadowColor;
				half _ShadowRange, _RimMin, _RimMax, _RimSmooth;
				half4 _RimColor;

				struct a2v
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					float3 worldNormal : TEXCOORD1;
					float3 worldPos : TEXCOORD2;
				};


				v2f vert(a2v v)
				{
					v2f o;
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.pos = UnityObjectToClipPos(v.vertex);
					return o;
				}

				float4 frag(v2f i) : SV_TARGET
				{
					float4 col = 1;
				float4 mainTex = tex2D(_MainTex, i.uv);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 worldNormal = normalize(i.worldNormal);
				float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				float halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5; //半兰伯特光照强度
				//float3 diffuse = halfLambert > _ShadowRange ? _MainColor : _ShadowColor; //双色阶
				half ramp = tex2D(_RampTex, float2(saturate(halfLambert - _ShadowRange), 0.5)).r;
				half3 diffuse = lerp(_ShadowColor, _MainColor, ramp);
				diffuse *= mainTex;

				half f = 1.0 - saturate(dot(viewDir, worldNormal));
				half rim = smoothstep(_RimMin, _RimMax, f);
				rim = smoothstep(0, _RimSmooth, rim);
				half3 rimColor = rim * _RimColor.rgb * _RimColor.a;

				col.rgb = _LightColor0 * (diffuse + rimColor);
				return col;
				}
				ENDCG
			}

			Pass
			{
				Tags {"LightMode" = "ForwardBase"}

				Cull Front

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"

				half _OutlineWidth;
				half4 _OutLineColor;

				struct a2v
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
					float4 vertColor : COLOR;
					float4 tangent : TANGENT;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
				};


				v2f vert(a2v v)
				{
					v2f o;
					float4 pos = UnityObjectToClipPos(v.vertex);
					float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
					//float3 viewNormal = mul( v.normal.xyz,(float3x3)UNITY_MATRIX_T_MV);
					//顶点着色器的这行坐标变换得到的x，y的范围是(-w, w)。
					//当在屏幕上做栅格化的时候，管线会将x，y的坐标值除以w就能得到（-1, 1）范围的坐标（ndc）。
					//我们希望得到的是显示在屏幕上的固定宽度的轮廓线，那么顶点向外延伸的距离应该是ndc空间下的固定距离，而不是投影空间下的固定距离。
					//于是我在投影空间下做计算的时候只要将轮廓线宽度乘上w值，再后续的计算中，管线会将坐标值除以w，得到的仍然是人为设定的轮廓线宽度。
					//float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//将法线变换到NDC空间
					float3 ndcNormal = normalize(mul((float3x3)UNITY_MATRIX_P,viewNormal.xyz)) * pos.w;//将法线变换到NDC空间

					float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
					float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
					ndcNormal.x *= aspect;

					pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
					o.pos = pos;
					return o;
				}

				float4 frag(v2f i) : SV_TARGET
				{
					return _OutLineColor;
				}
				ENDCG
			}
		}
}