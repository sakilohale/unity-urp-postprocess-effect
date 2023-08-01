using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class scan : ScriptableRendererFeature
{

    // 序列化
    [System.Serializable]
    public class mysetting
    {   
        public RenderPassEvent passEvent=RenderPassEvent.AfterRenderingTransparents;
        public Material mymat;
        public int matpassindex=-1;
        public string passTag="scanTag";
        [Range(0,1)]
        public float ScanRange;
        public Color ScanColor;
        public int EdgeDetection = 0;

    }

    public mysetting setting=new mysetting();


    //自定义pass类
    class CustomRenderPass : ScriptableRenderPass
    {
        public Material passMat=null;
        public int passMatInt=0; 
        public string passTag; 
        public float ScanRange;
        public float ScanSpeed = 1f;
        public Color ScanColor;
        public int EdgeDetection = 0;
        
        float scanDistance = 0;

        private RenderTargetIdentifier passSource{get;set;}//源图像,目标图像，这个会自动传给shader中的_MainTex里面
        
        // GetTemporaryRT需要的参数
        public FilterMode passfiltermode;// 图像过滤模式
        public RenderTargetHandle tempory;// 临时计算图像


        //构造函数
        public CustomRenderPass(RenderPassEvent passEvent,Material material,int passint,float ScanRange, Color ScanColor, int EdgeDetection)
        {
            renderPassEvent=passEvent;
            this.passMat=material;
            this.passMatInt=passint;
            this.ScanRange = ScanRange;
            this.ScanColor = ScanColor;
            this.EdgeDetection = EdgeDetection;
        }

        //接收render feature传的图
        public void setup(RenderTargetIdentifier sour)
        {
            this.passSource=sour;  
        }

        // Exectue函数，定义了该pass里要做的操作，即逻辑实现
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            
            // -----------------------------------------------------------------
            // 判断材质是否存在
            if (passMat == null)
            {
                Debug.LogError("材质初始化失败");
                return;
            }
            // 摄像机是否开启后处理
            if (!renderingData.cameraData.postProcessEnabled)
            {
                return;
            }
            // // 渲染设置
            var stack = VolumeManager.instance.stack;          // 传入volume
            var GSVO = stack.GetComponent<GSVO>();       // 拿到我们的volume
            if (GSVO == null)
            {
                Debug.LogError(" Volume组件获取失败 ");
                return;
            } 
            if(!GSVO.initiate.value)
            {
                return;
            }
            // 将volume组件里设置的参数传给脚本

            ScanRange = GSVO.ScanRange.value;
            ScanSpeed = GSVO.ScanSpeed.value;
            ScanColor = GSVO.ScanColor.value;
            EdgeDetection = GSVO.EdgeDetection.value?1:0;

            // ------------------------------------------------------------------
            
            scanDistance = Mathf.Lerp(scanDistance, 1, Time.deltaTime * ScanSpeed);
            if(scanDistance > 0.9f){
                scanDistance = 0;
            }

            passMat.SetFloat("_ScanDistance",scanDistance);
            passMat.SetFloat("_ScanRange",ScanRange);
            passMat.SetColor("_ScanColor",ScanColor);
            passMat.SetInt("_EdgeDetection",EdgeDetection);
            

            CommandBuffer cmd=CommandBufferPool.Get(passTag);  
            
            ref var cameraData = ref renderingData.cameraData;
            RenderTextureDescriptor opaquedesc=cameraData.cameraTargetDescriptor;

            cmd.GetTemporaryRT(tempory.id,opaquedesc,FilterMode.Bilinear);

            Blit(cmd,passSource,tempory.Identifier(),passMat,-1);
            Blit(cmd,tempory.Identifier(),passSource);

            cmd.ReleaseTemporaryRT(tempory.id);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
            
        } 

    }

    CustomRenderPass mypass;
    
    // Feature被创建时即调用，用于初始化参数以及Pass
    public override void Create()

    {   
        // 计算材质球里总的pass数，如果没有则为1，不然返回总数-1（pass索引从0开始）
        int passint=setting.mymat==null?1:setting.mymat.passCount-1;
        
        // 把设置里的pass的id限制在-1到材质的最大pass数 
        // -1表示不用，0表示第一个pass，以此类推
        setting.matpassindex=Mathf.Clamp(setting.matpassindex,-1,passint);

        //实例化一下并传参数,name就是tag
        mypass = new CustomRenderPass(setting.passEvent,setting.mymat,setting.matpassindex,setting.ScanRange,setting.ScanColor,setting.EdgeDetection);
    }

    // 每帧调用，摄像机渲染
    // 等同于 将pass给塞进了队列里进行渲染
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        mypass.setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(mypass);
    }

}
