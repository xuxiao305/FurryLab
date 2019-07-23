using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

// See _ReadMe.txt for an overview
[ExecuteInEditMode]
public class LightEX : MonoBehaviour
{
    public bool m_RenderSource = true;
    public Vector3 m_Size = new Vector3(1, 1, 2);
    [Range(0, 50)]
    public float m_Intensity = 0.8f;
    [Range(0, 5)]
    public float m_ConeFalloffStart;
    [Range(0, 5)]
    public float m_ConeFalloffEnd;

    [Range(0, 3)]
    public float m_distanceFalloff;
    [Range(0,1)]
    public int m_LightType;

    public GameObject m_LineLightVolume;
    public Color m_LightColor = Color.white;
    [Range(0, 10)]
    public float m_LineLightLength;
    
    public float m_Radius = 1.0f;

    [Header("Shadows")]
    public bool m_Shadows = false;
    public LayerMask m_ShadowCullingMask = ~0;
    public TextureSize m_ShadowmapRes = TextureSize.x2048;
    
    static CameraEvent kCameraEvent = CameraEvent.BeforeForwardOpaque;



    public enum TextureSize
    {
        x512 = 512,
        x1024 = 1024,
        x2048 = 2048,
        x4096 = 4096,
    }
    [Range(0, 0.01f)]
    public float m_DistanceBias = 0.001f;
    [Range(0, 0.01f)]
    public float m_NormalBias = 0.001f;
    
    // Debugging Infomation
    [Header("DEBUGGING INFO")]
    public Shader m_ShadowmapShader;
    public Camera m_ShadowmapCamera;
    public RenderTexture m_Shadowmap = null;
    public int lightIndex;

    // Private 
    float m_Angle = 0.0f;
    int m_ShadowmapRenderTime = -1;
  

    // We'll want to add a command buffer on any camera that renders us,
    // so have a dictionary of them.
    private Dictionary<Camera, CommandBuffer> _cameras = new Dictionary<Camera, CommandBuffer>();

    void Awake()
    {
        m_ShadowmapShader = Shader.Find("Alice/Hidden/Shadowmap");

        // Create the camera
        if (m_ShadowmapCamera == null)
        {
            if (m_ShadowmapShader == null)
            {
                Debug.LogError("AreaLight's shadowmap shader not assigned.", this);
                return;
            }

            GameObject go = new GameObject("Shadowmap Camera");

            go.AddComponent(typeof(Camera));
            m_ShadowmapCamera = go.GetComponent<Camera>();
        }

        m_ShadowmapCamera.enabled = false;
        m_ShadowmapCamera.clearFlags = CameraClearFlags.SolidColor;
        m_ShadowmapCamera.renderingPath = RenderingPath.Forward;
        m_ShadowmapCamera.backgroundColor = Color.black;
        m_ShadowmapCamera.fieldOfView = 0;
        m_ShadowmapCamera.orthographic = true;

        //m_ShadowmapCamera.gameObject.hideFlags = HideFlags.HideAndDontSave;

    }


    void Update()
    {
        m_LineLightVolume.transform.localScale = new Vector3(m_LineLightLength, 0.1f, 0.1f);

    }


    public void UpdateShadowmapCamera()
    {
        if (m_Shadowmap != null && m_ShadowmapRenderTime == Time.renderedFrameCount)
            return;

        int res = (int)m_ShadowmapRes;
        m_ShadowmapCamera.orthographic = true;
        m_ShadowmapCamera.nearClipPlane = 0;
        m_ShadowmapCamera.farClipPlane = m_Size.z;
        m_ShadowmapCamera.orthographicSize = 0.5f * m_Size.y;
        m_ShadowmapCamera.aspect = m_Size.x / m_Size.y;

        m_ShadowmapCamera.gameObject.transform.localRotation = Quaternion.identity;
        m_ShadowmapCamera.gameObject.transform.localPosition = Vector3.zero;

        ReleaseTemporary(ref m_Shadowmap);
        //m_Shadowmap = RenderTexture.GetTemporary(res, res, 24, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        m_Shadowmap = RenderTexture.GetTemporary(res, res, 24, RenderTextureFormat.RG32, RenderTextureReadWrite.Linear);

        m_Shadowmap.name = "Shadowmap" + lightIndex.ToString();
        m_Shadowmap.filterMode = FilterMode.Point;
        m_Shadowmap.wrapMode = TextureWrapMode.Clamp;
        m_ShadowmapCamera.targetTexture = m_Shadowmap;

    }

    public void RenderShadowmap()
    {
        // Clear. RenderWithShader() should clear too, but it doesn't.
        // TODO: Check if it's a bug.
        m_ShadowmapCamera.cullingMask = 0;
        m_ShadowmapCamera.Render();
        m_ShadowmapCamera.cullingMask = m_ShadowCullingMask;

        // We might be rendering inside PlaneReflections, which invert culling. Disable temporarily.
        var oldCulling = GL.invertCulling;
        GL.invertCulling = false;

        m_ShadowmapCamera.RenderWithShader(m_ShadowmapShader, "ObjectType");
        // Back to whatever was the culling mode.
        GL.invertCulling = oldCulling;

        m_ShadowmapRenderTime = Time.renderedFrameCount;


    }


    public void SetBufferParameter(CommandBuffer buffer)
    {
        string strIndex = lightIndex.ToString();
        buffer.SetGlobalTexture("_Shadowmap" +              strIndex,   m_Shadowmap);
        buffer.SetGlobalMatrix("_ShadowProjectionMatrix" +  strIndex,   GetProjectionMatrix());
        buffer.SetGlobalFloat("_ShadowNormalBias" +         strIndex,   m_NormalBias);
        buffer.SetGlobalFloat("_ShadowDistanceBias" +       strIndex,   m_DistanceBias);
        buffer.SetGlobalVector("_DirLightFwd" +             strIndex,   -transform.forward);
        buffer.SetGlobalVector("_DirLightColorIntensity" +  strIndex,   new Vector4(m_LightColor.r, m_LightColor.g, m_LightColor.b, m_Intensity));
        buffer.SetGlobalVector("_DirLightPos" +             strIndex,   transform.position);
        buffer.SetGlobalFloat("_ConeFalloffStart" +    strIndex,   m_ConeFalloffStart);
        buffer.SetGlobalFloat("_ConeFalloffEnd" +      strIndex, m_ConeFalloffEnd);
        buffer.SetGlobalFloat("_DistanceFalloff" + strIndex, m_distanceFalloff);

        buffer.SetGlobalFloat("_ShadowmapSize" +            strIndex,   (float)m_ShadowmapRes);

        Vector3 localStart = new Vector3(m_LineLightLength * 0.5f, 0.0f, 0.0f);
        Vector3 localEnd = new Vector3(-m_LineLightLength * 0.5f, 0.0f, 0.0f);
        Vector3 globalStart = transform.localToWorldMatrix.MultiplyPoint(localStart);
        Vector3 globalEnd = transform.localToWorldMatrix.MultiplyPoint(localEnd);

        buffer.SetGlobalVector("_TubeLightPosStart" + strIndex, globalStart);
        buffer.SetGlobalVector("_TubeLightPosEnd" +   strIndex, globalEnd);
        buffer.SetGlobalFloat("_SphereLightRadius" +        strIndex,   m_Radius);
        buffer.SetGlobalInt("_LightType" + strIndex, m_LightType);

    }

    // Start and End
    void OnDisable()
    {
        if (!Application.isPlaying)
            Cleanup();
        else
            for (var e = _cameras.GetEnumerator(); e.MoveNext();)
                if (e.Current.Value != null)
                    e.Current.Value.Clear();

    }

    void OnDestroy()
    {
        //Cleanup();
    }

    void Cleanup()
    {
        for (var e = _cameras.GetEnumerator(); e.MoveNext();)
        {
            var cam = e.Current;
            if (cam.Key != null && cam.Value != null)
            {
                cam.Key.RemoveCommandBuffer(kCameraEvent, cam.Value);
            }
        }
        _cameras.Clear();
    }

    // Utilities functions
    void ReleaseTemporary(ref RenderTexture rt)
    {
        if (rt == null)
            return;

        RenderTexture.ReleaseTemporary(rt);
        rt = null;
    }

    public Matrix4x4 GetProjectionMatrix(bool linearZ = false)
    {
        Matrix4x4 m;

        if (m_Angle == 0.0f)
        {
            m = Matrix4x4.Ortho(-0.5f * m_Size.x, 0.5f * m_Size.x, -0.5f * m_Size.y, 0.5f * m_Size.y, 0, -m_Size.z);
        }
        else
        {
            float near = GetNearToCenter();
            if (linearZ)
            {
                m = PerspectiveLinearZ(m_Angle, m_Size.x / m_Size.y, near, near + m_Size.z);
            }
            else
            {
                m = Matrix4x4.Perspective(m_Angle, m_Size.x / m_Size.y, near, near + m_Size.z);
                m = m * Matrix4x4.Scale(new Vector3(1, 1, -1));
            }
            m = m * GetOffsetMatrix(near);
        }

        return m * gameObject.transform.worldToLocalMatrix;
    }

    Matrix4x4 PerspectiveLinearZ(float fov, float aspect, float near, float far)
    {
        // A vector transformed with this matrix should get perspective division on x and y only:
        // Vector4 vClip = MultiplyPoint(PerspectiveLinearZ(...), vEye);
        // Vector3 vNDC = Vector3(vClip.x / vClip.w, vClip.y / vClip.w, vClip.z);
        // vNDC is [-1, 1]^3 and z is linear, i.e. z = 0 is half way between near and far in world space.

        float rad = Mathf.Deg2Rad * fov * 0.5f;
        float cotan = Mathf.Cos(rad) / Mathf.Sin(rad);
        float deltainv = 1.0f / (far - near);
        Matrix4x4 m;

        m.m00 = cotan / aspect; m.m01 = 0.0f; m.m02 = 0.0f; m.m03 = 0.0f;
        m.m10 = 0.0f; m.m11 = cotan; m.m12 = 0.0f; m.m13 = 0.0f;
        m.m20 = 0.0f; m.m21 = 0.0f; m.m22 = 2.0f * deltainv; m.m23 = -(far + near) * deltainv;
        m.m30 = 0.0f; m.m31 = 0.0f; m.m32 = 1.0f; m.m33 = 0.0f;

        return m;
    }
    float GetNearToCenter()
    {
        if (m_Angle == 0.0f)
            return 0;

        return m_Size.y * 0.5f / Mathf.Tan(m_Angle * 0.5f * Mathf.Deg2Rad);
        
    }

    Matrix4x4 GetOffsetMatrix(float zOffset)
    {
        Matrix4x4 m = Matrix4x4.identity;
        m.SetColumn(3, new Vector4(0, 0, zOffset, 1));
        return m;
    }

    Bounds GetFrustumBounds()
    {
        return new Bounds(Vector3.zero, m_Size);
    }
    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.white;
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.DrawWireCube(new Vector3(0, 0, 0.5f * m_Size.z), m_Size);
    }



    
}
