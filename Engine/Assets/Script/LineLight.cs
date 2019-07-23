using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

// See _ReadMe.txt for an overview
[ExecuteInEditMode]
public class LineLight : MonoBehaviour
{
    [Range(0, 5)]
    public float m_Radius = 1.0f;
    [Range(0, 10)]
    public float m_Intensity = 0.8f;
    public Color m_LightColor = Color.white;
    public Transform startNode;
    public Transform endNode;
    
    // Debugging Infomation
    [Header("DEBUGGING INFO")]
    public int lightIndex;

    // Private 
    private float m_Angle = 0.0f;
    int m_ShadowmapRenderTime = -1;
  

    // We'll want to add a command buffer on any camera that renders us,
    // so have a dictionary of them.
    private Dictionary<Camera, CommandBuffer> _cameras = new Dictionary<Camera, CommandBuffer>();

    void Update()
    {
        Shader.SetGlobalFloat("_TubeLightPos1X", startNode.transform.position[0]);
        Shader.SetGlobalFloat("_TubeLightPos1Y", startNode.transform.position[1]);
        Shader.SetGlobalFloat("_TubeLightPos1Z", startNode.transform.position[2]);

        Shader.SetGlobalFloat("_TubeLightPos2X", endNode.transform.position[0]);
        Shader.SetGlobalFloat("_TubeLightPos2Y", endNode.transform.position[1]);
        Shader.SetGlobalFloat("_TubeLightPos2Z", endNode.transform.position[2]);

        Shader.SetGlobalFloat("_SphereLightRadius1", m_Radius);
        Shader.SetGlobalFloat("_TubeLightInt", m_Intensity);

    }

    // Start and End
    void OnDisable()
    {
    }

    void OnDestroy()
    {
        //Cleanup();
    }

    void Cleanup()
    {
    }



    float GetNearToCenter()
    {
        return 0;
    }


}
