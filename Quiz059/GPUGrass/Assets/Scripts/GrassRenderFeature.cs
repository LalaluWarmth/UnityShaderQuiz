using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrassRenderFeature : ScriptableRendererFeature
{
    private GrassRenderPass _pass = null;

    //在 Renderer 中插入一个或多个 ScriptableRenderPass
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.renderType == CameraRenderType.Base)
        {
            renderer.EnqueuePass(_pass);
        }
    }

    //初始化这个 Feature 的资源
    public override void Create()
    {
        _pass = new GrassRenderPass();
    }

    //RenderPass是实际的渲染工作
    public class GrassRenderPass : ScriptableRenderPass
    {
        public GrassRenderPass()
        {
            //Pass 执行的时间点，用来控制每个 Pass 的执行顺序,此处选择在不透明物体之前画
            this.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
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
        private const string NameOfCommandBuffer = "Grass";

        //核心方法，定义执行规则；包含渲染逻辑，设置渲染状态，绘制渲染器或绘制程序网格，调度计算等等
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //从命令缓存池中获取一个gl命令缓存，CommandBuffer主要用于收集一系列gl指令，然后之后执行
            var cmd = CommandBufferPool.Get(NameOfCommandBuffer);
            try
            {
                cmd.Clear();
                var index = 0;
                foreach (var grassTerrain in GrassTerrain.actives)
                {
                    if (!grassTerrain)
                    {
                        continue;
                    }

                    if (!grassTerrain.material)
                    {
                        continue;
                    }

                    if (grassTerrain.updatedGrassCnt <= 0)
                    {
                        continue;
                    }

                    grassTerrain.UpdateMaterialProperties();
                    cmd.DrawMeshInstancedProcedural(GrassUtil.unitMesh, 0, grassTerrain.material, 0,
                        grassTerrain.updatedGrassCnt, grassTerrain.materialPropertyBlock);
                    index++;
                }

                //执行
                context.ExecuteCommandBuffer(cmd);
            }
            finally
            {
                //回收
                cmd.Release();
            }
        }
    }
}