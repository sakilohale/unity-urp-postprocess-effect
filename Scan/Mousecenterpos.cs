using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Mousecenterpos : MonoBehaviour
{

    public Material mat = null;

    Vector3 mousePosInWorld;


    void Update()
    {
　　    mousePosInWorld = Input.mousePosition;
　　    mousePosInWorld.z = Mathf.Abs(Camera.main.transform.position.z);
        mousePosInWorld = Camera.main.ScreenToWorldPoint(mousePosInWorld);

        if(Input.GetMouseButtonDown(0))
        {
            if(mat != null)
            {
                mat.SetVector("_ScanCenter",mousePosInWorld);
            }
            
        }        
        
    }
}
