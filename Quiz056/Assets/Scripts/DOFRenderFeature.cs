using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DOFRenderFeature : ScriptableRendererFeature
{
    DOFRenderPass dofRenderPass;

    public override void Create()
    {
        dofRenderPass = new DOFRenderPass(RenderPassEvent.BeforeRenderingPostProcessing);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        dofRenderPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(dofRenderPass);
    }
}