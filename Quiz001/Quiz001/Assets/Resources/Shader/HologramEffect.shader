Shader "rBit/HologramEffect"
{
    Properties
    {
        [HDR]_HologramColor("Hologram Color",Color)=(1,1,1,0)
        _HologramAlpha("Hologram Alpha",Range(0.0,1.0))=1.0

        //原先模型的UV纹理
        _HologramMaskMap("Hologram Mask",2D)="white"{}
        //通道蒙版的强度，控制遮罩效果
        _HologramMaskAffect("Hologram Mask Affect",Range(0.0,1.0))=0.5

        //Glitch的数值，x速度，y抖动范围，z抖动偏移量，w频率(0~0.99)
        _HologramGliterData1("Hologram Gliter Data1",Vector)=(0,1,0,0)
        _HologramGliterData2("Hologram Gliter Data2",Vector)=(0,1,0,0)

        // 扫描线
        _HologramLine("HologramLine",2D)="white"{}
        _HologramLineSpeed("Hologram Line Speed",Range(-10.0,10.0))=1.0
        _HologramLineFrequency("Hologram Line Frequency",Range(0.0,100.0))=20.0
        _HologramLineAlpha("Hologram Line  Alpha",Range(0.0,1.0))=0.15
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "RenderType"="Transparent"
        }
        CGINCLUDE
        struct a2v_hg
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f_hg
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 posWorld : TEXCOORD1;
        };

        float4 _HologramColor;
        fixed _HologramAlpha;
        sampler2D _HologramMaskMap;
        float4 _HologramMaskMap_ST;
        half _HologramMaskAffect;
        half4 _HologramGliterData1, _HologramGliterData2;

        sampler2D _HologramLine;
        half _HologramLineSpeed, _HologramLineFrequency, _HologramLineAlpha;

        half3 VertexHologramOffset(float3 vertex, half4 offsetData)
        {
            half speed = offsetData.x;
            half range = offsetData.y;
            half offset = offsetData.z;
            half frequency = offsetData.w;

            half offset_time = sin(_Time.y * speed);
            half timeToGliter = step(frequency, offset_time);
            half gliterPosY = sin(vertex.y + _Time.z);
            half gliterPosYRange = step(0, gliterPosY) * step(gliterPosY, range);
            half res = gliterPosYRange * offset * timeToGliter * gliterPosY;

            // 将偏移量定义为视角坐标的偏移量，转到模型坐标
            float3 view_offset = float3(res, 0, 0);
            // 将法线（向量）从模型空间变换到观察空间
            return mul((float3x3)UNITY_MATRIX_T_MV, view_offset);
        }

        v2f_hg HologramVertex(a2v_hg v)
        {
            v2f_hg o;
            // Glitch作用在模型顶点上
            v.vertex.xyz += VertexHologramOffset(v.vertex.xyz, _HologramGliterData1);
            v.vertex.xyz += VertexHologramOffset(v.vertex.xyz, _HologramGliterData2);
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            o.posWorld = mul(unity_ObjectToWorld, v.vertex);
            // 将顶点、方向矢量从世界空间转换到裁剪空间
            o.pos = mul(UNITY_MATRIX_VP, o.posWorld);
            return o;
        }
        ENDCG
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha // 启用默认渲染目标的混合 Blend <source factor> <destination factor>
            ZWrite off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex HologramVertex
            #pragma fragment HologramFragment

            float4 HologramFragment(v2f_hg i):SV_Target
            {
                // 颜色蒙版，使用r通道作为蒙版
                float4 main_color = _HologramColor;
                float2 mask_uv = i.uv.xy * _HologramMaskMap_ST.xy + _HologramMaskMap_ST.zw;
                float4 mask = tex2D(_HologramMaskMap, mask_uv);
                float mask_alpha = lerp(1, mask.r, _HologramMaskAffect);

                // 扫描线
                float2 line_uv = (i.posWorld.y * _HologramLineFrequency + _Time.y * _HologramLineSpeed).xx;
                float lline = clamp(tex2D(_HologramLine, line_uv).r, 0.0, 1.0);
                float4 line_color = float4((main_color * lline).rgb, lline) * _HologramLineAlpha;
                float line_alpha = clamp(((main_color).a + (line_color).w), 0.0, 1.0);

                float4 resultColor = float4(main_color.rgb + line_color.rgb * line_alpha,
                                            _HologramAlpha * mask_alpha);
                return resultColor;
            }
            ENDCG
        }
    }
}