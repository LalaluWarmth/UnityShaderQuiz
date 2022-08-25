using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DOF : VolumeComponent, IPostProcessComponent
{
    [Range(0f, 100f), Tooltip("模糊强度")] public FloatParameter BlurRadius = new FloatParameter(0f);
    [Range(0f, 10f), Tooltip("模糊质量")] public IntParameter Iteration = new IntParameter(5);
    [Range(0f, 100f), Tooltip("模糊深度")] public FloatParameter downSample = new FloatParameter(0f);
    [Range(-1f, 1f), Tooltip("聚焦点设置")] public FloatParameter focalDistanceSetting = new FloatParameter(0f);
    [Range(-1f, 1f), Tooltip("远模糊设置")] public FloatParameter farBlurScaleSetting = new FloatParameter(0f);
    [Range(0f, 100f), Tooltip("远深度强度设置")] public FloatParameter farBlurScalePowerSetting = new FloatParameter(0f);
    [Range(-1f, 1f), Tooltip("近模糊设置")] public FloatParameter nearBlurScaleSetting = new FloatParameter(0f);
    [Range(0f, 100f), Tooltip("近深度强度设置")] public FloatParameter nearBlurScalePowerSetting = new FloatParameter(0f);
    public bool IsActive() => downSample.value > 0f;
    public bool IsTileCompatible() => false;
}