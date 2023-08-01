using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;



public class GSVO : VolumeComponent

{              
        public BoolParameter initiate = new BoolParameter(false);       
        
        [Tooltip("扫描线的宽度")]
        public FloatParameter ScanRange = new ClampedFloatParameter(0f,0f,10f);

        [Tooltip("扫描速度")]
        public FloatParameter ScanSpeed = new ClampedFloatParameter(1.0f,0f,10f);

        [Tooltip("扫描线颜色")]
        public ColorParameter ScanColor = new ColorParameter(Color.white);

        [Tooltip("是否起用边缘检测")]
        public BoolParameter EdgeDetection = new BoolParameter(false); 

} 