using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DistortionMerge : ScriptableRendererFeature
{
    [System.Serializable]
    public class mysetting
    {
        public Material DistortionMat;
    }

    class CustomRenderPass : ScriptableRenderPass
    {
        private Material DistortionMat;
        private RenderTargetIdentifier destination{get;set;}
        private RenderTargetHandle temp{get;set;}


        public CustomRenderPass(Material DistortionMat){
            this.DistortionMat = DistortionMat;
        }

        public void setup(RenderTargetIdentifier source)
        {
            this.destination = source;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("扭曲效果附加");
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();


            cmd.GetTemporaryRT(temp.id,renderingData.cameraData.cameraTargetDescriptor,FilterMode.Bilinear);
            Blit(cmd,destination,temp.Identifier(),DistortionMat,-1);
            Blit(cmd,temp.Identifier(),destination);
        
            context.ExecuteCommandBuffer(cmd);
            cmd.ReleaseTemporaryRT(temp.id);
            CommandBufferPool.Release(cmd);
        }

    

    }

    public mysetting setting = new mysetting();
    CustomRenderPass m_ScriptablePass;


    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(setting.DistortionMat);
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {   
        m_ScriptablePass.setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


