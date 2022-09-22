using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrassRenderFeature : ScriptableRendererFeature
{
    private HizRenderPass _hizPass = null;
    private GrassComputePass _computePass = null;
    private GrassRenderPass _grassPass = null;
    private List<ScriptableRenderPass> _scriptableRenderPasses = new List<ScriptableRenderPass>();

    //在 Renderer 中插入一个或多个 ScriptableRenderPass
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.renderType == CameraRenderType.Base)
        {
            foreach (var pass in _scriptableRenderPasses)
            {
                renderer.EnqueuePass(pass);
            }
        }
    }

    //初始化这个 Feature 的资源
    public override void Create()
    {
        _scriptableRenderPasses.Clear();
        _hizPass = new HizRenderPass();
        _scriptableRenderPasses.Add(_hizPass);
        // foreach (var grassTerrain in GrassTerrain.actives)
        // {
        //     _computePass = new GrassComputePass(grassTerrain);
        //     _scriptableRenderPasses.Add(_computePass);
        // }

        _grassPass = new GrassRenderPass();
        _scriptableRenderPasses.Add(_grassPass);
    }
}

public class HizRenderPass : ScriptableRenderPass
{
    public HizRenderPass()
    {
        //Pass 执行的时间点，用来控制每个 Pass 的执行顺序
        this.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
    }

    //在执行渲染过程之前，Renderer 将调用此方法。如果需要配置渲染目标及其清除状态，并创建临时渲染目标纹理，那就要重写这个方法。如果渲染过程未重写这个方法，则该渲染过程将渲染到激活状态下 Camera 的渲染目标
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        int temp = Shader.PropertyToID("_Temp");
        int w = DepthTextureGenerator.depthTexture.width;
        RenderTextureDescriptor desc = new RenderTextureDescriptor(w, w);
        cmd.GetTemporaryRT(temp, desc);
        //将这个RT设置为Render Target
        ConfigureTarget(temp);
        //将RT清空为黑
        ConfigureClear(ClearFlag.All, Color.black);
    }

    //用于释放通过此过程创建的分配资源。完成渲染相机后调用。就可以使用此回调释放此渲染过程创建的所有资源。
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    //标记，后续需要在 CommandBufferPool 中去获取到它，在 FrameDebugger 中也可以找到它
    private const string NameOfCalDepthCommandBuffer = "Calculate Depth";

    //核心方法，定义执行规则；包含渲染逻辑，设置渲染状态，绘制渲染器或绘制程序网格，调度计算等等
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //从命令缓存池中获取一个gl命令缓存，CommandBuffer主要用于收集一系列gl指令，然后之后执行
        var cmdDepth = CommandBufferPool.Get(NameOfCalDepthCommandBuffer);
        try
        {
            cmdDepth.Clear();
            int w = DepthTextureGenerator.depthTexture.width;
            int mipmapLevel = 0;

            RenderTexture currRenderTexture = null; //当前mipmapLevel对应的mipmap
            RenderTexture preRenderTexture = null; //mipmapLevel-1对应的mipmap

            //最小mipmap尺寸为16*16
            while (w > 8)
            {
                currRenderTexture = RenderTexture.GetTemporary(w, w, 0, RenderTextureFormat.RHalf);
                currRenderTexture.filterMode = FilterMode.Point;
                if (preRenderTexture == null)
                {
                    //Mipmap[0]即copy原始的深度图
                    cmdDepth.Blit(null, currRenderTexture, DepthTextureGenerator.depthMaterial, 1);
                }
                else
                {
                    cmdDepth.Blit(preRenderTexture, currRenderTexture, DepthTextureGenerator.depthMaterial, 0);
                    RenderTexture.ReleaseTemporary(preRenderTexture);
                }

                cmdDepth.CopyTexture(currRenderTexture, 0, 0, DepthTextureGenerator.depthTexture, 0, mipmapLevel);
                preRenderTexture = currRenderTexture;

                w /= 2;
                mipmapLevel++;
            }

            RenderTexture.ReleaseTemporary(currRenderTexture);
            RenderTexture.ReleaseTemporary(preRenderTexture);

            //执行
            context.ExecuteCommandBuffer(cmdDepth);
        }
        finally
        {
            //回收
            cmdDepth.Release();
        }
    }
}

//RenderPass是实际的渲染工作
public class GrassComputePass : ScriptableRenderPass
{
    private GrassTerrain grassTerrain;

    public GrassComputePass(GrassTerrain gT)
    {
        grassTerrain = gT;

        //Pass 执行的时间点，用来控制每个 Pass 的执行顺序
        this.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    //在执行渲染过程之前，Renderer 将调用此方法。如果需要配置渲染目标及其清除状态，并创建临时渲染目标纹理，那就要重写这个方法。如果渲染过程未重写这个方法，则该渲染过程将渲染到激活状态下 Camera 的渲染目标
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    //用于释放通过此过程创建的分配资源。完成渲染相机后调用。就可以使用此回调释放此渲染过程创建的所有资源。
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    //标记，后续需要在 CommandBufferPool 中去获取到它，在 FrameDebugger 中也可以找到它
    private const string NameOfDrawGrassCommandBuffer = "Compute Grass";

    //核心方法，定义执行规则；包含渲染逻辑，设置渲染状态，绘制渲染器或绘制程序网格，调度计算等等
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //从命令缓存池中获取一个gl命令缓存，CommandBuffer主要用于收集一系列gl指令，然后之后执行
        var cmdComputeGrass = CommandBufferPool.Get(NameOfDrawGrassCommandBuffer);

        try
        {
            cmdComputeGrass.Clear();

            // 执行Compute Shader
            cmdComputeGrass.SetComputeBufferParam(grassTerrain.compute, grassTerrain.kernel, "grassInfoBuffer",
                grassTerrain.grassBuffer);
            cmdComputeGrass.SetComputeBufferCounterValue(grassTerrain.cullResult, 0);
            cmdComputeGrass.SetComputeBufferParam(grassTerrain.compute, grassTerrain.kernel, "cullResult",
                grassTerrain.cullResult);
            cmdComputeGrass.SetComputeTextureParam(grassTerrain.compute, grassTerrain.kernel,
                grassTerrain.hizTextureId,
                DepthTextureGenerator.depthTexture);
            cmdComputeGrass.SetComputeMatrixParam(grassTerrain.compute, grassTerrain.vpMatrixId,
                GL.GetGPUProjectionMatrix(grassTerrain.mainCamera.projectionMatrix, false) *
                grassTerrain.mainCamera.worldToCameraMatrix);
            cmdComputeGrass.SetComputeMatrixParam(grassTerrain.compute, grassTerrain.mTerrainMatrixId,
                grassTerrain.transform.localToWorldMatrix);
            cmdComputeGrass.DispatchCompute(grassTerrain.compute, grassTerrain.kernel,
                1 + grassTerrain.grassCnt / 640, 1, 1);
            cmdComputeGrass.CopyCounterValue(grassTerrain.cullResult, grassTerrain.argResult, sizeof(uint));

            //执行
            context.ExecuteCommandBuffer(cmdComputeGrass);

            int[] counter = new int[5] {0, 0, 0, 0, 0};
            grassTerrain.argResult.GetData(counter);
            grassTerrain.updatedGrassCnt = counter[1];
            // Debug.Log("grassCnt count: " + counter[0] + " " + counter[1] + " " + counter[2] + " " + counter[3] + " " +
            //           counter[4]);
        }
        finally
        {
            //回收
            cmdComputeGrass.Release();
        }
    }
}

//RenderPass是实际的渲染工作
public class GrassRenderPass : ScriptableRenderPass
{
    public GrassRenderPass()
    {
        //Pass 执行的时间点，用来控制每个 Pass 的执行顺序
        this.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    //在执行渲染过程之前，Renderer 将调用此方法。如果需要配置渲染目标及其清除状态，并创建临时渲染目标纹理，那就要重写这个方法。如果渲染过程未重写这个方法，则该渲染过程将渲染到激活状态下 Camera 的渲染目标
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    //用于释放通过此过程创建的分配资源。完成渲染相机后调用。就可以使用此回调释放此渲染过程创建的所有资源。
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    //标记，后续需要在 CommandBufferPool 中去获取到它，在 FrameDebugger 中也可以找到它
    private const string NameOfDrawGrassCommandBuffer = "Draw Grass";

    //核心方法，定义执行规则；包含渲染逻辑，设置渲染状态，绘制渲染器或绘制程序网格，调度计算等等
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //从命令缓存池中获取一个gl命令缓存，CommandBuffer主要用于收集一系列gl指令，然后之后执行
        var cmdDrawGrass = CommandBufferPool.Get(NameOfDrawGrassCommandBuffer);
        try
        {
            cmdDrawGrass.Clear();
            var index = 0;
            foreach (var grassTerrain in GrassTerrain.actives)
            {
                if (!grassTerrain) continue;
                if (!grassTerrain.material) continue;
                if (grassTerrain.updatedGrassCnt <= 0) continue;

                grassTerrain.UpdateMaterialProperties();
                cmdDrawGrass.DrawMeshInstancedProcedural(GrassUtil.unitMesh, 0, grassTerrain.material, 0,
                    grassTerrain.updatedGrassCnt, grassTerrain.materialPropertyBlock);
                index++;
            }

            //执行
            context.ExecuteCommandBuffer(cmdDrawGrass);
        }
        finally
        {
            //回收
            cmdDrawGrass.Release();
        }
    }
}