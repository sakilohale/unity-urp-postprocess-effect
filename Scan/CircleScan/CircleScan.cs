using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class CircleScan : ScriptableRendererFeature
{

    // 序列化
    [System.Serializable]
    public class mysetting
    {   
        public RenderPassEvent passEvent=RenderPassEvent.AfterRenderingTransparents;
        public Material mymat;
        public int matpassindex=-1;
        public string passTag="scanTag";
        [Range(0,5)]
        public float ScanRange = 0;         // 扫描线的宽度
        public Color ScanColor;             // 扫描线颜色
        public Vector3 ScanCenter;          // 扫描圆心
        public float MaxScanDistance = 0;   // 扫描圆半径
        public float ScanSpeed = 0;         // 扫描扩散速度
        public int CircleEdgeInitiate = 0;
        [Range(1,4)]
        public float CircleEdgeFrequency = 1f; // 圆形边缘频率，EdgeSinOmega

        [Range(-0.5f,1f)]
        public float CircleEdgeWidth = -0.49f; // 圆形边缘宽度，EdgeSinVerticalMove

        public int EdgeDetection = 0;
    }

    public mysetting setting=new mysetting();


    //自定义pass类
    class CustomRenderPass : ScriptableRenderPass
    {
        public Material passMat=null;
        public int passMatInt=0; 
        public string passTag; 
        public float ScanRange = 0;
        public Color ScanColor = Color.white;
        public Vector3 ScanCenter = Vector3.zero;
        public float ScanSpeed;
        private float ScanDistance = 0;
        public float MaxScanDistance;

        public int CircleEdgeInitiate;
        public float CircleEdgeFrequency;
        public float CircleEdgeWidth;

        public int EdgeDetection;

        public Camera currentCamera = null;


        private RenderTargetIdentifier passSource{get;set;}//源图像,目标图像，这个会自动传给shader中的_MainTex里面
        
        // GetTemporaryRT需要的参数
        public FilterMode passfiltermode;// 图像过滤模式
        public RenderTargetHandle tempory;// 临时计算图像


        //构造函数
        public CustomRenderPass(RenderPassEvent passEvent,Material material,int passint,float ScanRange, 
            Color ScanColor,Vector3 ScanCenter,float MaxScanDistance,float ScanSpeed, int CircleEdgeInitiate, float CircleEdgeFrequency, float CircleEdgeWidth, int EdgeDetection)
        {
            renderPassEvent=passEvent;
            this.passMat=material;
            this.passMatInt=passint;
            this.ScanRange = ScanRange;
            this.ScanColor = ScanColor;
            this.ScanCenter = ScanCenter;
            this.MaxScanDistance = MaxScanDistance;
            this.ScanSpeed = ScanSpeed;
            this.CircleEdgeInitiate = CircleEdgeInitiate;
            this.CircleEdgeFrequency = CircleEdgeFrequency;
            this.CircleEdgeWidth = CircleEdgeWidth;
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
            var CSVO = stack.GetComponent<CSVO>();       // 拿到我们的volume
            if (CSVO == null)
            {
                Debug.LogError(" Volume组件获取失败 ");
                return;
            } 

            if (!CSVO.initiate.value)
            {
                return;
            }

            // 将volume组件里设置的参数传给脚本

            ScanRange = CSVO.ScanRange.value;
            MaxScanDistance = CSVO.MaxScanDistance.value;
            ScanSpeed = CSVO.ScanSpeed.value;
            ScanColor = CSVO.ScanColor.value;
            ScanCenter = CSVO.ScanCenter.value;
            CircleEdgeInitiate = CSVO.CircleEdgeInitiate.value?1:0;
            CircleEdgeFrequency = CSVO.CircleEdgeFrequency.value;
            CircleEdgeWidth = CSVO.CircleEdgeWidth.value;
            EdgeDetection = CSVO.EdgeDetection.value?1:0;

            // ------------------------------------------------------------------
            
    
            ScanDistance = Mathf.Lerp(ScanDistance, MaxScanDistance, Time.deltaTime * ScanSpeed);
            if(ScanDistance > MaxScanDistance - 0.1){
                ScanDistance = 0;
            }
            
            passMat.SetFloat("_ScanDistance",ScanDistance);

            passMat.SetFloat("_ScanRange",ScanRange);
            passMat.SetColor("_ScanColor",ScanColor);
            // 这里可以通过其他方式，例如鼠标点击方式来传递ScanCenter
            passMat.SetVector("_ScanCenter",ScanCenter);
            passMat.SetInt("_CircleEdgeInitiate",CircleEdgeInitiate);

            if(CircleEdgeInitiate == 1)
            { 
                passMat.SetFloat("_EdgeSinOmega",CircleEdgeFrequency * 100);
                passMat.SetFloat("_EdgeSinVerticalMove",CircleEdgeWidth);
            }

            passMat.SetInt("_EdgeDetection",EdgeDetection);
            

            
            // vp逆矩阵
            currentCamera = renderingData.cameraData.camera;
            var vpMatrix = currentCamera.projectionMatrix * currentCamera.worldToCameraMatrix;
            passMat.SetMatrix("_InverseVPMatrix",vpMatrix.inverse);

//-------------------------------------------------------------------------------------------------------------------------------------------------//

            // 相机参数
            Camera cam= renderingData.cameraData.camera;

            float halfheight=cam.nearClipPlane*Mathf.Tan(Mathf.Deg2Rad*cam.fieldOfView*0.5f);  //Mathf.Deg2Rad表示角度转弧度
            Vector3 up=cam.transform.up*halfheight;
            Vector3 right=cam.transform.right*halfheight*cam.aspect;
            Vector3 forward=cam.transform.forward*cam.nearClipPlane;
            Vector3 ButtomLeft=forward-right-up;

            float scale=ButtomLeft.magnitude/cam.nearClipPlane;  // vector.magnitude返回向量长度
            ButtomLeft.Normalize();
            ButtomLeft*=scale;

            Vector3 ButtomRight=forward+right-up;
            ButtomRight.Normalize();
            ButtomRight*=scale;

            Vector3 TopRight=forward+right+up;
            TopRight.Normalize();
            TopRight*=scale;

            Vector3 TopLeft=forward-right+up;
            TopLeft.Normalize();
            TopLeft*=scale;

            Matrix4x4 MATRIX=new Matrix4x4();
            MATRIX.SetRow(0,ButtomLeft);
            MATRIX.SetRow(1,ButtomRight);
            MATRIX.SetRow(2,TopRight);
            MATRIX.SetRow(3,TopLeft);

            passMat.SetMatrix("_ViewPortRay",MATRIX); 

//-------------------------------------------------------------------------------------------------------------------------------------------------//
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
        mypass = new CustomRenderPass(setting.passEvent,setting.mymat,setting.matpassindex,setting.ScanRange,setting.ScanColor,setting.ScanCenter,setting.MaxScanDistance,setting.ScanSpeed,setting.CircleEdgeInitiate,setting.CircleEdgeFrequency,setting.CircleEdgeWidth,setting.EdgeDetection);
    }

    // 每帧调用，摄像机渲染
    // 等同于 将pass给塞进了队列里进行渲染
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        mypass.setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(mypass);
    }

}
