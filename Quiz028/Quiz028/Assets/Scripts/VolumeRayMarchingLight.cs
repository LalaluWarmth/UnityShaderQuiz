/********************************************************************
 FileName: VolumeRayMarchingLight.cs
 Description:
 Created: 2018/04/28
 history: 28:4:2018 20:33 by puppet_master
*********************************************************************/

using UnityEngine;

[ExecuteInEditMode]
public class VolumeRayMarchingLight : MonoBehaviour
{
    private Material lightMaterial = null;

    private Light lightComponent = null;

    //Mie-Scattering g 参数
    [Range(0.0f, 0.99f)] public float MieScatteringG = 0.5f;

    void OnEnable()
    {
        if (Camera.main != null)
            Camera.main.depthTextureMode = DepthTextureMode.Depth;
        InitVolumeLight();
    }

    void OnDisable()
    {
        if (Camera.main != null)
            Camera.main.depthTextureMode = DepthTextureMode.None;
    }

    private void InitVolumeLight()
    {
        var render = GetComponent<Renderer>();
        //sharedMaterial方便一点...
        lightMaterial = render.sharedMaterial;
        lightComponent = GetComponent<Light>();
        if (lightComponent == null)
        {
            lightComponent = gameObject.AddComponent<Light>();
        }
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
    }
}