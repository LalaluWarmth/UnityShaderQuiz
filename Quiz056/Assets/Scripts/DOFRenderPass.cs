using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DOFRenderPass : ScriptableRenderPass
{
    private static readonly string k_RenderTag = "Render DOF Effects";
    private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
    private static readonly int TempTargetId = Shader.PropertyToID("_TempTarget");
    private static readonly int FocusPowerId = Shader.PropertyToID("_FocusPower");
    private static readonly int focalDistanceId = Shader.PropertyToID("_focalDistance");
    private static readonly int farBlurScaleId = Shader.PropertyToID("_farBlurScale");
    private static readonly int farBlurScalePowerId = Shader.PropertyToID("_farBlurScalePower");
    private static readonly int nearBlurScaleId = Shader.PropertyToID("_nearBlurScale");
    private static readonly int nearBlurScalePowerId = Shader.PropertyToID("_nearBlurScalePower");

    private DOF dof;
    private Material dofMaterial;
    private RenderTargetIdentifier currentTarget;

    public DOFRenderPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
        var shader = Shader.Find("PostEffect/DOFBlur");
        if (shader == null)
        {
            Debug.LogError("Shader not Found");
            return;
        }

        dofMaterial = CoreUtils.CreateEngineMaterial(shader);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (dofMaterial == null)
        {
            Debug.LogError("Material not created");
            return;
        }

        if (!renderingData.cameraData.postProcessEnabled) return;

        var stack = VolumeManager.instance.stack;
        dof = stack.GetComponent<DOF>();
        if (dof == null) return;
        if (!dof.IsActive()) return;

        var cmd = CommandBufferPool.Get(k_RenderTag);

        Render(cmd, ref renderingData);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public void Setup(in RenderTargetIdentifier currentTarget)
    {
        this.currentTarget = currentTarget;
    }

    void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ref var cameraData = ref renderingData.cameraData;
        var source = currentTarget;
        int destination = TempTargetId;

        var w = (int) (cameraData.camera.scaledPixelWidth / dof.downSample.value);
        var h = (int) (cameraData.camera.scaledPixelHeight / dof.downSample.value);
        dofMaterial.SetFloat(FocusPowerId, dof.BlurRadius.value);
        dofMaterial.SetFloat(focalDistanceId, dof.focalDistanceSetting.value / 100f);
        dofMaterial.SetFloat(farBlurScaleId, dof.farBlurScaleSetting.value);
        dofMaterial.SetFloat(farBlurScalePowerId, dof.farBlurScalePowerSetting.value / 100 + 1);
        dofMaterial.SetFloat(nearBlurScaleId, dof.nearBlurScaleSetting.value);
        dofMaterial.SetFloat(nearBlurScalePowerId, dof.nearBlurScalePowerSetting.value / 100 + 1);

        int shaderPass = 0;
        cmd.SetGlobalTexture(MainTexId, source);
        cmd.GetTemporaryRT(destination, w, h, 16, FilterMode.Point, RenderTextureFormat.Default);

        cmd.Blit(source, destination);
        for (int i = 0; i < dof.Iteration.value; i++)
        {
            cmd.GetTemporaryRT(destination, w / 2, h / 2, 16, FilterMode.Point, RenderTextureFormat.Default);
            cmd.Blit(destination, source, dofMaterial, shaderPass);
            cmd.Blit(source, destination);
            cmd.Blit(destination, source, dofMaterial, shaderPass + 1);
            cmd.Blit(source, destination);
        }

        for (int i = 0; i < dof.Iteration.value; i++)
        {
            cmd.GetTemporaryRT(destination, w * 2, h * 2, 16, FilterMode.Point, RenderTextureFormat.Default);
            cmd.Blit(destination, source, dofMaterial, shaderPass);
            cmd.Blit(source, destination);
            cmd.Blit(destination, source, dofMaterial, shaderPass + 1);
            cmd.Blit(source, destination);
        }

        cmd.Blit(destination, destination, dofMaterial, 0);
    }
}