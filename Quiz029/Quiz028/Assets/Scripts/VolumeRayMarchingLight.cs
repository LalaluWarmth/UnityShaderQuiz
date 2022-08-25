/********************************************************************
 FileName: VolumeRayMarchingLight.cs
 Description:
 Created: 2018/04/28
 history: 28:4:2018 20:33 by puppet_master
*********************************************************************/

using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class VolumeRayMarchingLight : MonoBehaviour
{
    private Material lightMaterial = null;
    private Light lightComponent = null;

    private Texture2D ditherMap = null;
    private Renderer lightRenderer = null;

    //Mie-Scattering g 参数
    [Range(0.0f, 0.99f)] public float MieScatteringG = 0.5f;

    void OnEnable()
    {
        if (Camera.main != null)
            Camera.main.depthTextureMode = DepthTextureMode.Depth;
        Init();
    }

    void OnDisable()
    {
        if (Camera.main != null)
            Camera.main.depthTextureMode = DepthTextureMode.None;
    }

    private void Init()
    {
        InitVolumeLight();
    }

    private void InitVolumeLight()
    {
        lightRenderer = GetComponent<Renderer>();
        //sharedMaterial方便一点...
        lightMaterial = lightRenderer.sharedMaterial;
        lightComponent = GetComponent<Light>();
        if (lightComponent == null)
        {
            lightComponent = gameObject.AddComponent<Light>();
        }
        if (ditherMap == null)
            ditherMap = GenerateDitherMap();
    }

    void Update()
    {
        if (lightMaterial == null || lightComponent == null)
            return;
        transform.localScale = new Vector3(lightComponent.range * 2.0f, lightComponent.range * 2.0f,
            lightComponent.range * 2.0f);

        float g2 = MieScatteringG * MieScatteringG;
        float lightRange = lightComponent.range;
        lightMaterial.SetVector("_VolumeLightPos", transform.position);
        lightMaterial.SetVector("_MieScatteringFactor",
            new Vector4((1 - g2) * 0.25f / Mathf.PI, 1 + g2, 2 * MieScatteringG, 1.0f / (lightRange * lightRange)));

        lightMaterial.SetTexture("_DitherMap", ditherMap);
    }

    private Texture2D GenerateDitherMap()
    {
        int texSize = 4;
        var ditherMap = new Texture2D(texSize, texSize, TextureFormat.Alpha8, false, true);
        ditherMap.filterMode = FilterMode.Point;
        Color32[] colors = new Color32[texSize * texSize];

        colors[0] = GetDitherColor(0.0f);
        colors[1] = GetDitherColor(8.0f);
        colors[2] = GetDitherColor(2.0f);
        colors[3] = GetDitherColor(10.0f);

        colors[4] = GetDitherColor(12.0f);
        colors[5] = GetDitherColor(4.0f);
        colors[6] = GetDitherColor(14.0f);
        colors[7] = GetDitherColor(6.0f);

        colors[8] = GetDitherColor(3.0f);
        colors[9] = GetDitherColor(11.0f);
        colors[10] = GetDitherColor(1.0f);
        colors[11] = GetDitherColor(9.0f);

        colors[12] = GetDitherColor(15.0f);
        colors[13] = GetDitherColor(7.0f);
        colors[14] = GetDitherColor(13.0f);
        colors[15] = GetDitherColor(5.0f);

        ditherMap.SetPixels32(colors);
        ditherMap.Apply();
        return ditherMap;
    }

    private Color32 GetDitherColor(float value)
    {
        byte byteValue = (byte) (value / 16.0f * 255);
        return new Color32(byteValue, byteValue, byteValue, byteValue);
    }
}