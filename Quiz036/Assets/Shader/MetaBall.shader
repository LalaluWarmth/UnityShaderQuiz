Shader "Custom/RayMarchingBall"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            //Setup
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform int _MaxIterations;
            uniform float _Accuracy;
            uniform float _maxDistance;
            //sphere
            uniform float4 _sphereRigi[100];
            uniform int _sphereRigiNum;
            uniform float _sphereSmooth;
            uniform float3 _sphereColor;
            //Light
            uniform float3 _LightDir, _LightCol;
            uniform float _LightIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray :TEXCOORD1;
            };

            struct Ray
            {
                float3 origin;
                float3 direction;
            };

            struct RayHit
            {
                float4 position;
                float3 normal;
                float3 color;
            };

            Ray createRay(float3 origin, float3 direction)
            {
                Ray ray;
                ray.origin = origin;
                ray.direction = direction;
                return ray;
            }

            RayHit CreateRayHit()
            {
                RayHit hit;
                hit.position = float4(0.0f, 0.0f, 0.0f, 0.0f);
                hit.normal = float3(0.0f, 0.0f, 0.0f);
                hit.color = float3(1.0f, 1.0f, 1.0f);
                return hit;
            }

            RayHit raymarching(Ray ray, float depth, int MaxIterations, int maxDistance, int atten);

            float sdSphere(float3 p, float s)
            {
                return length(p) - s;
            }

            float4 opUS(float4 d1, float4 d2, float k)
            {
                float h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0.0, 1.0);
                float3 color = lerp(d2.rgb, d1.rgb, h);
                float dist = lerp(d2.w, d1.w, h) - k * h * (1.0 - h);
                return float4(color, dist);
            }

            float4 distenceField(float3 p)
            {
                float4 combines;

                combines = float4(_sphereColor.rgb, sdSphere(p - _sphereRigi[0].xyz, _sphereRigi[0].w));
                for (int i = 1; i < _sphereRigiNum; i++)
                {
                    float4 sphereAdd = float4(_sphereColor.rgb, sdSphere(p - _sphereRigi[i].xyz, _sphereRigi[i].w));
                    combines = opUS(combines, sphereAdd, _sphereSmooth); //opUS
                }
                return combines;
            }

            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001f, 0.0f);
                float3 n = float3(
                    distenceField(p + offset.xyy).w - distenceField(p - offset.xyy).w,
                    distenceField(p + offset.yxy).w - distenceField(p - offset.yxy).w,
                    distenceField(p + offset.yyx).w - distenceField(p - offset.yyx).w
                );
                return normalize(n);
            }

            float3 Shading(inout Ray ray,RayHit hit,float3 col)
            {
                float3 light = (_LightCol * dot(-_LightDir, hit.normal));
                return float3(hit.color * light);
            }

            RayHit raymarching(Ray ray, float depth, int MaxIterations, int maxDistance, int atten)
            {
                RayHit bestHit = CreateRayHit();
                float t = 0;
                for (int i = 0; i < MaxIterations; i++)
                {
                    if (t > maxDistance || t >= depth)
                    {
                        bestHit.position = float4(0, 0, 0, 0);
                        break;
                    }

                    float3 p = ray.origin + ray.direction * t;
                    float4 d = distenceField(p);

                    if (d.w < _Accuracy)
                    {
                        bestHit.position = float4(p, 1);
                        bestHit.normal = getNormal(p);
                        break;
                    }
                    t += d.w;
                }
                return bestHit;
            }

            v2f vert(appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;
                o.ray /= abs(o.ray.z); //z=-1
                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }


            fixed4 frag(v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray.xyz);
                fixed3 col = tex2D(_MainTex, i.uv);
                Ray ray = createRay(_WorldSpaceCameraPos, normalize(i.ray.xyz));
                RayHit hit;
                fixed4 result;
                hit = raymarching(ray, depth, _MaxIterations, _maxDistance, 1);
                if (hit.position.w == 1)
                {
                    float3 s = Shading(ray, hit, col); //setcolor
                    result = fixed4(s, 1);
                    
                }
                else
                {
                    result = fixed4(0, 0, 0, 0);
                }
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}