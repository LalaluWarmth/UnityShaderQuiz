Shader "CustomCartoon/SimpleCartoon"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1)
		_ShadowColor("Shadow Color", Color) = (0.7, 0.7, 0.8)
		_ShadowRange("Shadow Range", Range(0, 1)) = 0.5
		_RampTex("Ramp Tex", 2D) = "white" {}

		[Space(10)]
		_ShadowRamp("Shadow Ramp", 2D) = "white" {}
		_Forward("Forward", Vector) = (0,0,-1,0)
		_Left("Left", Vector) = (1,0,0,0)

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

					float3 lightDirH = normalize(float3(_WorldSpaceLightPos0.x, 0, _WorldSpaceLightPos0.z));
					float lightAtten = 1 - (dot(lightDirH, _Forward) * 0.5 + 0.5);
					float flipU = sign(dot(lightDirH, _Left));
					float4 shadowRampTex = tex2D(_ShadowRamp, i.uv * float2(flipU, 1));
					float faceShadow = step(lightAtten, shadowRampTex);
					//float3 diffuse = faceShadow > _ShadowRange ? _MainColor : _ShadowColor; //??????

					half ramp = tex2D(_RampTex, float2(saturate(faceShadow - _ShadowRange), 0.5)).r;
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
					//??????????????????????????????x??y????????(-w, w)??
					//??????????????????????????????????x??y????????????w??????????-1, 1??????????????ndc????
					//????????????????????????????????????????????????????????????????????????????ndc??????????????????????????????????????????????
					//??????????????????????????????????????????????????w??????????????????????????????????????w????????????????????????????????????
					//float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//????????????NDC????
					float3 ndcNormal = normalize(mul((float3x3)UNITY_MATRIX_P,viewNormal.xyz)) * pos.w;//????????????NDC????

					float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//????????????????????????????????????????
					float aspect = abs(nearUpperRight.y / nearUpperRight.x);//??????????????
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