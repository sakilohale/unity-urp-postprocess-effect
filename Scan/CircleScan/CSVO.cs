using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;



public class CSVO : VolumeComponent

{              
        public BoolParameter initiate = new BoolParameter(false);       
        
        [Tooltip("扫描线的宽度")]
        public FloatParameter ScanRange = new ClampedFloatParameter(0f,0f,10f);

        [Tooltip("扫描圆形范围")]
        public FloatParameter MaxScanDistance = new ClampedFloatParameter(5.0f,0f,20f);

        [Tooltip("扫描速度")]
        public FloatParameter ScanSpeed = new ClampedFloatParameter(1.0f,0f,10f);

        [Tooltip("扫描线颜色")]
        public ColorParameter ScanColor = new ColorParameter(Color.white);

        [Tooltip("扫描圆形中心")]
        public Vector3Parameter ScanCenter = new Vector3Parameter(new Vector3(0,0,0));

        [Tooltip("是否起用内圆")]
        public BoolParameter CircleEdgeInitiate = new BoolParameter(false); 

        [Tooltip("内圆频率")]
        public FloatParameter CircleEdgeFrequency = new ClampedFloatParameter(0.0f,0f,4f);

        [Tooltip("内圆扫描线宽度")]
        public FloatParameter CircleEdgeWidth = new ClampedFloatParameter(0.0f,-0.5f,1.3f);

        [Tooltip("是否起用边缘检测")]
        public BoolParameter EdgeDetection = new BoolParameter(false); 

} 