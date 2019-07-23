using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class LightManager : MonoBehaviour {
    public List<LightEX> lightsList = new List<LightEX>();
    static CameraEvent kCameraEvent = CameraEvent.BeforeForwardOpaque;
   
    CommandBuffer buffer;

    // Use this for initialization
    void Start () {
        lightsList.Clear();
        lightsList.AddRange(GetComponentsInChildren<LightEX>());
		for (int i = 0; i < lightsList.Count; i++)
        {
            lightsList[i].lightIndex = i;
        }
	}

    public void OnWillRenderObject()
    {
        GetOrCreateCommandBuffer();

        for (int i = 0; i < lightsList.Count; i++)
        {
            lightsList[i].UpdateShadowmapCamera();
            lightsList[i].RenderShadowmap();
            lightsList[i].SetBufferParameter(buffer);
        }
    }

    void GetOrCreateCommandBuffer()
    {
        if (buffer == null)
        {
            buffer = new CommandBuffer();
            buffer.name = gameObject.name;
            Camera.main.AddCommandBuffer(kCameraEvent, buffer);
            
        }
        else
        {
            buffer.Clear();
        }
        
    }


}
