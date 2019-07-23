using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

// See _ReadMe.txt for an overview
[ExecuteInEditMode]
public class CommandBufferDyanmicShadow : MonoBehaviour
{
    static CameraEvent kCameraEvent = CameraEvent.BeforeForwardOpaque;
    Camera m_ShadowmapCamera;
    public Camera ShadowComputingCamera;
    Transform m_ShadowmapCameraTransform;
    public Shader m_ShadowmapShader;
    public Shader m_ShadowingComputeShader;
    public Shader m_BlurShadowmapShader;
    Material m_BlurShadowmapMaterial;
    public RenderTexture m_Shadowmap = null;
    public RenderTexture m_BlurredShadowmap = null;
    public RenderTexture m_ShadowingResultMap = null;
    Texture2D m_ShadowmapDummy = null;
    int m_ShadowmapRenderTime = -1;
    int m_BlurredShadowmapRenderTime = -1;
    public enum TextureSize
    {
        x512 = 512,
        x1024 = 1024,
        x2048 = 2048,
        x4096 = 4096,
    }

    // shadow parameters
    public Vector3 m_Size = new Vector3(1, 1, 2);
    public float m_Intensity = 0.8f;
    [Header("Shadows")]
    public bool m_Shadows = true;
    public LayerMask m_ShadowCullingMask = ~0;
    public TextureSize m_ShadowmapRes = TextureSize.x2048;
    public float m_ReceiverSearchDistance = 24.0f;
    public float m_ReceiverDistanceScale = 5.0f;
    public float m_LightNearSize = 4.0f;
    public float m_LightFarSize = 22.0f;
    [Range(0, 0.1f)]
    public float m_DistanceBias = 0.001f;
    [Range(0, 0.1f)]
    public float m_NormalBias = 0.001f;
    

    [Range(0, 3.0f)]
    public float m_BlurSize = 1.0f;
    [Range(0, 3)]
    public float m_BlurIterations = 2;

    public float m_ESMExponent = 40.0f;
    // old
    public float GassianScale = 1.0f;
    public Shader shader;
    private Material _material;

    private Camera _cam;

    public Light dirLight;

    private CommandBuffer _commandBuffer;
    private CommandBuffer _cascadeShadowCommandBuffer;

    private CommandBuffer _buf;

    private float m_Angle = 0.0f;



    RenderTexture[] temp;

    void SetUpShadowmapForSampling(CommandBuffer buf)
    {
        UpdateShadowmap((int)m_ShadowmapRes);

        float texelsInMap = (int)m_ShadowmapRes;
        float relativeTexelSize = texelsInMap / (float)m_ShadowmapRes;

        buf.SetGlobalFloat("_ShadowReceiverWidth", relativeTexelSize * m_ReceiverSearchDistance / texelsInMap);
        buf.SetGlobalFloat("_ShadowReceiverDistanceScale", m_ReceiverDistanceScale * 0.5f / 10.0f); // 10 samples in shader
        buf.SetGlobalTexture("_Shadowmap", m_Shadowmap);
        buf.SetGlobalMatrix("_ShadowProjectionMatrix", GetProjectionMatrix());
        buf.SetGlobalFloat("_ShadowNormalBias", m_NormalBias);
        buf.SetGlobalFloat("_ShadowDistanceBias", m_DistanceBias);

        Vector2 shadowLightWidth = new Vector2(m_LightNearSize, m_LightFarSize) * relativeTexelSize / texelsInMap;
        buf.SetGlobalVector("_ShadowLightWidth", shadowLightWidth);
    }
    void UpdateShadowmap(int res)
    {
        if (m_Shadowmap != null && m_ShadowmapRenderTime == Time.renderedFrameCount)
            return;

        GameObject go1 = GameObject.Find("Shadowmap Camera");
        if (go1 != null)
        {
            m_ShadowmapCamera = go1.GetComponent<Camera>();
        }

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

            m_ShadowmapCameraTransform = go.transform;
            //            m_ShadowmapCameraTransform.parent = transform;
            m_ShadowmapCameraTransform.parent = dirLight.transform;

            m_ShadowmapCameraTransform.localRotation = Quaternion.identity;

            m_ShadowmapCameraTransform.localPosition = Vector3.zero;

        }
        //go.hideFlags = HideFlags.HideAndDontSave;
        m_ShadowmapCamera.enabled = false;
        m_ShadowmapCamera.clearFlags = CameraClearFlags.SolidColor;
        m_ShadowmapCamera.renderingPath = RenderingPath.Forward;
        // exp(EXPONENT) for ESM, white for VSM
        // m_ShadowmapCamera.backgroundColor = new Color(Mathf.Exp(EXPONENT), 0, 0, 0);
        //m_ShadowmapCamera.backgroundColor = Color.white;
        m_ShadowmapCamera.backgroundColor = Color.black;

        

        if (m_Angle == 0.0f)
        {
            m_ShadowmapCamera.orthographic = true;
            m_ShadowmapCamera.nearClipPlane = 0;
            m_ShadowmapCamera.farClipPlane = m_Size.z;
            m_ShadowmapCamera.orthographicSize = 0.5f * m_Size.y;
            m_ShadowmapCamera.aspect = m_Size.x / m_Size.y;
        }
        else
        {
            m_ShadowmapCamera.orthographic = false;
            float near = GetNearToCenter();
            m_ShadowmapCameraTransform.localPosition = -near * Vector3.forward;
            m_ShadowmapCamera.nearClipPlane = near;
            m_ShadowmapCamera.farClipPlane = near + m_Size.z;
            m_ShadowmapCamera.fieldOfView = m_Angle;
            m_ShadowmapCamera.aspect = m_Size.x / m_Size.y;
        }
        ReleaseTemporary(ref m_Shadowmap);
        m_Shadowmap = RenderTexture.GetTemporary(res, res, 24, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        //m_Shadowmap.antiAliasing = 2;
        m_Shadowmap.name = "Shadowmap";
        m_Shadowmap.filterMode = FilterMode.Point;
        //m_Shadowmap.useMipMap = true;
        //m_Shadowmap.autoGenerateMips = false;
        //m_Shadowmap.anisoLevel = 6;


        m_Shadowmap.wrapMode = TextureWrapMode.Clamp;



        m_ShadowmapCamera.targetTexture = m_Shadowmap;

        // Clear. RenderWithShader() should clear too, but it doesn't.
        // TODO: Check if it's a bug.
        m_ShadowmapCamera.cullingMask = 0;
        m_ShadowmapCamera.Render();
        m_ShadowmapCamera.cullingMask = m_ShadowCullingMask;

        // We might be rendering inside PlaneReflections, which invert culling. Disable temporarily.
        var oldCulling = GL.invertCulling;
        GL.invertCulling = false;

        m_ShadowmapCamera.RenderWithShader(m_ShadowmapShader, "RenderType");

        // Back to whatever was the culling mode.
        GL.invertCulling = oldCulling;

        m_ShadowmapRenderTime = Time.renderedFrameCount;
    }

    void UpdateBlurredShadowmap()
    {
        if (m_BlurredShadowmap != null && m_BlurredShadowmapRenderTime == Time.renderedFrameCount)
            return;
        int startRes = (int)m_ShadowmapRes;
        int targetRes = startRes / 2;

        RenderTexture originalRT = RenderTexture.active;

        // Downsample
        ReleaseTemporary(ref m_BlurredShadowmap);

        InitMaterial(ref m_BlurShadowmapMaterial, m_BlurShadowmapShader);

        int downsampleSteps = (int)Mathf.Log(startRes / targetRes, 2);
        downsampleSteps = 1;

        // RFloat for ESM, RGHalf for VSM
        RenderTextureFormat format = RenderTextureFormat.RGHalf;

        m_BlurredShadowmap = RenderTexture.GetTemporary(targetRes, targetRes, 0, format, RenderTextureReadWrite.Linear);
        m_BlurredShadowmap.name = "AreaLight Shadow Downsample";
        m_BlurredShadowmap.filterMode = FilterMode.Bilinear;
        m_BlurredShadowmap.wrapMode = TextureWrapMode.Clamp;

        if (temp == null || temp.Length != downsampleSteps)
            temp = new RenderTexture[downsampleSteps];

        for (int i = 0, currentRes = startRes / 2; i < downsampleSteps; i++)
        {
            temp[i] = RenderTexture.GetTemporary(currentRes, currentRes, 0, format, RenderTextureReadWrite.Linear);
            temp[i].name = "AreaLight Shadow Downsample";
            temp[i].filterMode = FilterMode.Bilinear;
            temp[i].wrapMode = TextureWrapMode.Clamp;
            m_BlurShadowmapMaterial.SetVector("_TexelSize", new Vector4(0.5f / currentRes, 0.5f / currentRes, 0, 0));
            m_BlurShadowmapMaterial.SetTexture("_Shadowmap", m_Shadowmap);
            currentRes /= 2;
            Graphics.Blit(temp[0], m_BlurredShadowmap);
        }


        RenderTexture.active = m_BlurredShadowmap;

        m_BlurredShadowmapRenderTime = Time.renderedFrameCount;
    }

    // Normally would've used Graphics.Blit(), but it breaks picking in the scene view.
    // TODO: bug report
    void Blur(RenderTexture src, RenderTexture dst, int pass)
    {
        RenderTexture.active = dst;
        m_BlurShadowmapMaterial.SetTexture("_MainTex", src);
        m_BlurShadowmapMaterial.SetPass(pass);
        RenderQuad();
    }

    void RenderQuad()
    {
        GL.PushMatrix();
        GL.LoadOrtho();

        GL.Begin(GL.QUADS);
        GL.TexCoord2(0, 0);
        GL.Vertex3(-1, 1, 0);
        GL.TexCoord2(0, 1);
        GL.Vertex3(-1, -1, 0);
        GL.TexCoord2(1, 1);
        GL.Vertex3(1, -1, 0);
        GL.TexCoord2(1, 0);
        GL.Vertex3(1, 1, 0);
        GL.End();

        GL.PopMatrix();
    }

    void InitMaterial(ref Material material, Shader shader)
    {
        if (material)
            return;

        if (!shader)
        {
            Debug.LogError("Missing shader");
            return;
        }

        material = new Material(shader);
        material.hideFlags = HideFlags.HideAndDontSave;
    }

    // We'll want to add a command buffer on any camera that renders us,
    // so have a dictionary of them.
    private Dictionary<Camera, CommandBuffer> _cameras = new Dictionary<Camera, CommandBuffer>();

    void OnEnable()
    {
    }

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
        Cleanup();
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

    // Whenever any camera will render us, add a command buffer to do the work on it
    public void OnWillRenderObject()
    {
        Shader.SetGlobalMatrix("_LightMatrix", dirLight.transform.worldToLocalMatrix);
        SetUpCommandBuffer();

    }

    public void SetUpCommandBuffer()
    {
        Camera cam = Camera.current;
        CommandBuffer buf = GetOrCreateCommandBuffer(cam);

        SetUpShadowmapForSampling(buf);

        //ComputeShadow(buf);

        //UpdateBlurredShadowmap();
    }


    CommandBuffer GetOrCreateCommandBuffer(Camera cam)
    {
        if (cam == null)
            return null;

        CommandBuffer buf = null;
        if (!_cameras.ContainsKey(cam))
        {
            buf = new CommandBuffer();
            buf.name = gameObject.name;
            _cameras[cam] = buf;
            cam.AddCommandBuffer(kCameraEvent, buf);
            //cam.depthTextureMode |= DepthTextureMode.Depth;
            cam.depthTextureMode = DepthTextureMode.None;
        }
        else
        {
            buf = _cameras[cam];
            buf.Clear();
        }

        return buf;
    }


    void InitShadowmapDummy()
    {
        if (m_ShadowmapDummy != null)
            return;
        m_ShadowmapDummy = new Texture2D(1, 1, TextureFormat.Alpha8, false, true);
        m_ShadowmapDummy.filterMode = FilterMode.Point;
        m_ShadowmapDummy.SetPixel(0, 0, new Color(0f, 0f, 0f, 0f));
        m_ShadowmapDummy.Apply(false, true);
    }
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
        return m * dirLight.transform.worldToLocalMatrix;
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
    Vector4 GetZParams()
    {
        float n = GetNearToCenter();
        float f = n + m_Size.z;
        // linear z, 0 near, 1 far
        // linearz = A * (z + 1.0) / (z + B);
        // A = n/(n - f)
        // B = (n + f)/(n - f)

        return new Vector4(n / (n - f), (n + f) / (n - f), 0, 0);
    }
}
