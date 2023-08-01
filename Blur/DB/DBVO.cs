using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;



public class DBVO : VolumeComponent
{              
        public BoolParameter initiate = new BoolParameter(false);       

        // Blur iterations - larger number means more blur.
        public IntParameter iterations = new IntParameter(3);
        
        // Blur spread for each iteration - larger value means more blur
        public FloatParameter blurSpread = new FloatParameter(.6f);


} 