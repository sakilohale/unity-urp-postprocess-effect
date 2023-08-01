using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DistortionMask : ScriptableRendererFeature
{   
    [System.Serializable]
    public class mysetting
    {
        public Material DistortionMaskMaterial;
    }

    class DistortionMaskRenderPass : ScriptableRenderPass
    {   

        private RenderTargetHandle destination{set;get;}
        private Material DistortionMaskMaterial;
        private FilteringSettings m_FilteringSettings;
        ShaderTagId m_ShaderTagId = new ShaderTagId("UniversalForward");


        public DistortionMaskRenderPass(RenderQueueRange renderQueueRange, LayerMask layerMask, Material material)
        {
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
            this.DistortionMaskMaterial = material;
        }
        

        public void SetUp(RenderTargetHandle destination)
        {
            this.destination = destination;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // 自定义渲染目标纹理格式
            RenderTextureDescriptor descriptor = new RenderTextureDescriptor(128,128);
            cmd.GetTemporaryRT(destination.id,descriptor,FilterMode.Point);
            ConfigureTarget(destination.id);
            ConfigureClear(ClearFlag.All,Color.black);
            
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            CommandBuffer cmd = CommandBufferPool.Get("扭曲遮罩get");

            cmd.BeginSample("GetMask");
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortFlags);
            drawSettings.overrideMaterial = DistortionMaskMaterial;
            drawSettings.overrideMaterialPassIndex = 0;
            context.DrawRenderers(renderingData.cullResults,ref drawSettings,ref m_FilteringSettings);

            cmd.SetGlobalTexture(destination.id, destination.Identifier());  
            cmd.EndSample("GetMask");
    
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }


    
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if (destination != RenderTargetHandle.CameraTarget)
            {
                cmd.ReleaseTemporaryRT(destination.id);
                destination = RenderTargetHandle.CameraTarget;
            }
        }

    }

    public mysetting setting = new mysetting();
    DistortionMaskRenderPass distortionMaskRenderPass;
    RenderTargetHandle MaskRenderTexture;
    


    /// <inheritdoc/>
    public override void Create()
    {
        distortionMaskRenderPass = new DistortionMaskRenderPass(RenderQueueRange.all,LayerMask.GetMask("DistortionMask") , setting.DistortionMaskMaterial);
        distortionMaskRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;

        MaskRenderTexture.Init("_DistortionMaskTexture");
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {   
        distortionMaskRenderPass.SetUp(MaskRenderTexture);
        renderer.EnqueuePass(distortionMaskRenderPass);
    }
}


