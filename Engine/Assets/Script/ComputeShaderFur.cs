using System.Collections.Generic;
using UnityEngine;

public enum FurType
{
    Fur,
    FabricFraying,
    FabricTear,
}
[ExecuteInEditMode]
public class ComputeShaderFur : MonoBehaviour
{   
    [Header("Common Setting")]
    public Shader shader;
    //[HideInInspector]
    public Material furMaterial;
    public string kernalName;
    public ComputeShader computeShader;

    //private Material material;
    public Texture2D furPosMap;
    public Texture2D furNormalMap;
    public Texture2D furClumpingMap;

    public Texture2D furVolMap01;
    public Texture2D furVolMap02;
    public Texture2D furVolMap03;
    public Texture2D furPhxBoneIDMap;
    public Texture2D furPhxBoneSkinningMap;

    public Texture2D furmaskMap;


    [Header("Fur Basic")]
    public FurType furType;
    [Range(0.0f, 1.0f)]
    public float TearInt;
    [Range(1.0f, 10.0f)]
    public int furAmountMultiplier = 2;
    public int furTexResolutionX = 1024;
    public int furTexResolutionY = 64;

    [Range(0.0f, 1.0f)]
    public float furLength = 0.5f;
    [Range(0.0f, 1.0f)]
    public float furCut = 1.0f;
    [Range(0.0f, 1.0f)]
    public float furSpawnNoise = 0.5f;
    [Range(0.0f, 1.0f)]
    public float furWidth = 0.01f;
    [Range(0.0f, 1.0f)]
    public float furTipTape = 0.5f;



    [Header("Fur Clumping")]
    [Range(0.0f, 1.0f)]
    public float furClumpingInt;
    [Range(0.0f, 1.0f)]
    public float furClumpingNoise;
    [Range(0.0f, 60.0f)]
    public float furClumpingClusterAmountX = 1.0f;
    [Range(0.0f, 60.0f)]
    public float furClumpingClusterAmountY = 1.0f;

    [Range(0.0f, 1.0f)]
    public float furTwistInt = 0.0f;

    [Header("Fur Fuzzy")]
    [Range(0.0f, 1.0f)]
    public float furFuzzyInt = 0.5f;
    [Range(0.0f, 1.0f)]
    public float furFuzzyNoise = 1.0f;

    [Header("Fur Wave")]
    public float furwaveIntensity;
    [Range(0.0f, 360.0f)]
    public float furWaveDirection;
    [Range(0.0f, 1.0f)]
    public float furWaveDirectionNoise;
    [Range(0.0f, 1.0f)]
    public float furWavePhaseNoise;
    [Range(0.0f, 1.0f)]
    public float furWaveIntensityNoise;

    [Header("Alpha")]
    public bool alphaDither;
    [Range(1.0f, 5.0f)]
    public float alphaDitherSize;
    [Range(1.0f, 3.0f)]
    public float alphaEnhancement;
    [Range(0.0f, 1.0f)]
    public float alphaThreshold;


    [HideInInspector]
    [Range(0.0f, 1.0f)]
    public float flowIntensity;
    [Range(0.0f, 1.0f)]
    public float gravityIntensity;



    [HideInInspector]
    public ComputeShaderFur cmpShaderFur;
    [HideInInspector]
    public int VertCount = 10000000; //2*2*1*15 (Groups*ThreadsPerGroup)
    const int furInputAttributeCount = 2;
    const int furInputAttributeCountVec4 = 4;
    const int furSegCount = 3;

    private ComputeBuffer outputBuffer;
    private ComputeBuffer constantBuffer;
    private int _kernel;



    struct FurVertexFormat
    {
        public Vector4 pos0;
        public Vector3 clumpPos0;
        public Vector3 twistPos0;
        public Vector4 dataPack;
        public Vector4 dataPack2;
        public Vector4 dataPack3;


    };

    class FurDataList
    {
        public List<Vector4> pos0List = new List<Vector4>();
        public List<Vector3> clumpPos0List = new List<Vector3>();
        public List<Vector3> twistPos0List = new List<Vector3>();

        public List<Vector4> dataPackList = new List<Vector4>();
        public List<Vector4> dataPack2List = new List<Vector4>();
        public List<Vector4> dataPack3List = new List<Vector4>();
    }

    void Start()
    {
        //GenerateFur();
    }

    void Update()
    {
        if (furMaterial == null)
        {
            return;
        }
        furMaterial.SetFloat("_FurCut", furCut);
        furMaterial.SetFloat("_FurWidth", furWidth);
        furMaterial.SetFloat("_FuzzyInt", furFuzzyInt);
        furMaterial.SetFloat("_FuzzyNoise", furFuzzyNoise);
        furMaterial.SetFloat("_FurClumpingInt", furClumpingInt);
        furMaterial.SetFloat("_FurTwistInt", furTwistInt);
        furMaterial.SetFloat("_FurTipTape", furTipTape);

        furMaterial.SetFloat("_FurLength", furLength);

        if (alphaDither)
            furMaterial.SetFloat("_AlphaDither", 1.0f);
        else
            furMaterial.SetFloat("_AlphaDither", 0.0f);

        furMaterial.SetFloat("_AlphaDitherSize", alphaDitherSize * 1000.0f);

        furMaterial.SetFloat("_AlphaEnhancement", alphaEnhancement);
        furMaterial.SetFloat("_AlphaThreshold", alphaThreshold);

     }

    FurVertexFormat GetFurVert(System.Array bufferContent, int furIndex, int vertIndex)
    {
        FurVertexFormat vert = new FurVertexFormat
        {
            pos0 = new Vector4((float)bufferContent.GetValue(furIndex, vertIndex),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 1),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 2),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 3)),

            clumpPos0 = new Vector4((float)bufferContent.GetValue(furIndex, vertIndex + 4),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 5),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 6)),

            twistPos0 = new Vector4((float)bufferContent.GetValue(furIndex, vertIndex + 7),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 8),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 9)),

            dataPack = new Vector4((float)bufferContent.GetValue(furIndex, vertIndex + 10),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 11),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 12),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 13)),

            dataPack2 = new Vector4((float)bufferContent.GetValue(furIndex, vertIndex + 14),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 15),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 16),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 17)),

            dataPack3 = new Vector4((float)bufferContent.GetValue(furIndex, vertIndex + 18),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 19),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 20),
                                            (float)bufferContent.GetValue(furIndex, vertIndex + 21)),

        };

        return vert;
    }

    public void GenerateFur()
    {
        int furAmount = furTexResolutionX * furTexResolutionY;
        //furMeshBuilder = GetComponentInChildren<FurMeshBuilder>();
        //furMaterial = furMeshBuilder.GetComponent<Renderer>().sharedMaterial;

        cmpShaderFur = GetComponent<ComputeShaderFur>();
        CreateBuffers();

        _kernel = cmpShaderFur.computeShader.FindKernel(kernalName);

        if (furType == FurType.Fur)
            cmpShaderFur.computeShader.SetInt("_FurType", 0);
        else if (furType == FurType.FabricFraying)
            cmpShaderFur.computeShader.SetInt("_FurType", 1);
        else if (furType == FurType.FabricTear)
            cmpShaderFur.computeShader.SetInt("_FurType", 2);

        cmpShaderFur.computeShader.SetInt("_FurTexResX", furTexResolutionX);
        cmpShaderFur.computeShader.SetInt("_FurTexResY", furTexResolutionY);

        cmpShaderFur.computeShader.SetFloat("_TearInt", TearInt);

        for (int i = gameObject.transform.childCount-1; i >= 0; i--)
        {
            GameObject child = gameObject.transform.GetChild(i).gameObject;
            GameObject.DestroyImmediate(child);

        }

        for (int k = 0; k < furAmountMultiplier; k++)
        {
            cmpShaderFur.computeShader.SetFloat("_FurIteration", k);

            int csOutputBufferSize = furInputAttributeCount * 3 + furInputAttributeCountVec4 * 4; // 8 vector 3, according to my current compute shader

            System.Array bufferContent = new float[furAmount, furSegCount * csOutputBufferSize];

            Dispatch(k);

            outputBuffer.GetData(bufferContent);

            FurDataList furDataList = new FurDataList();

            for (int f = 0; f < furAmount; f++)
            {
                for (int s = 0; s < furSegCount; s++)
                {
                    FurVertexFormat vert = GetFurVert(bufferContent, f, s * csOutputBufferSize);

                    float mask = vert.pos0[3];
                    if (mask > 0.0f)
                    {
                        furDataList.pos0List.Add(vert.pos0);
                        furDataList.clumpPos0List.Add(vert.clumpPos0);
                        furDataList.twistPos0List.Add(vert.twistPos0);
                        furDataList.dataPackList.Add(vert.dataPack);
                        furDataList.dataPack2List.Add(vert.dataPack2);
                        furDataList.dataPack3List.Add(vert.dataPack3);
                    }
                }
            }

            int[] triangle = new int[furDataList.pos0List.Count];
            for (int f = 0; f < triangle.Length; f++)
            {
                triangle[f] = f;
            }


            GameObject newMeshBuilder = new GameObject();
            newMeshBuilder.AddComponent<FurMeshBuilder>();
            newMeshBuilder.AddComponent<MeshFilter>();
            newMeshBuilder.AddComponent<MeshRenderer>();
            newMeshBuilder.GetComponent<MeshRenderer>().sharedMaterial = furMaterial;
            newMeshBuilder.transform.parent = transform;
            newMeshBuilder.name = "FurBuilder_" + k.ToString();

            newMeshBuilder.GetComponent<FurMeshBuilder>().BuildMesh(
                            furDataList.pos0List,
                            furDataList.clumpPos0List,
                            furDataList.twistPos0List,
                            furDataList.dataPackList,
                            furDataList.dataPack2List,
                            furDataList.dataPack3List,
                            triangle);
            
        }

        ReleaseBuffer();
    }





    void CreateBuffers()
    {
        constantBuffer = new ComputeBuffer(1, 15 * 4);
        outputBuffer = new ComputeBuffer(VertCount, furInputAttributeCount * 12 + furInputAttributeCountVec4 * 16);
    }

    //Remember to release buffers and destroy the material when play has been stopped.
    void ReleaseBuffer()
    {
        constantBuffer.Release();
        outputBuffer.Release();
    }

    //The meat of this script, it sets the constant buffer (current time) and then sets all of the buffers for the compute shader.
    //We then dispatch 32x32x1 groups of threads of our CSMain kernel.
    void Dispatch(int ieration)
    {
        constantBuffer.SetData(new[] { (float)ieration,
            cmpShaderFur.furLength,
            cmpShaderFur.furSpawnNoise,
            cmpShaderFur.furFuzzyInt,
            cmpShaderFur.furClumpingInt,
            cmpShaderFur.furClumpingNoise,
            cmpShaderFur.furClumpingClusterAmountX,
            cmpShaderFur.furClumpingClusterAmountY,

            cmpShaderFur.flowIntensity,
            cmpShaderFur.gravityIntensity,
            cmpShaderFur.furwaveIntensity,
            Mathf.Deg2Rad * cmpShaderFur.furWaveDirection,
            cmpShaderFur.furWaveDirectionNoise,
            cmpShaderFur.furWavePhaseNoise,
            cmpShaderFur.furWaveIntensityNoise});


        //computeShader.SetTexture(_kernel, "debugTex", myRt);        

        cmpShaderFur.computeShader.SetTexture(_kernel, "FurPosMap", cmpShaderFur.furPosMap);
        cmpShaderFur.computeShader.SetTexture(_kernel, "FurNormalMap", cmpShaderFur.furNormalMap);
        cmpShaderFur.computeShader.SetTexture(_kernel, "FurClumpingMap", cmpShaderFur.furClumpingMap);

        cmpShaderFur.computeShader.SetTexture(_kernel, "FurVolMap01", cmpShaderFur.furVolMap01);
        cmpShaderFur.computeShader.SetTexture(_kernel, "FurVolMap02", cmpShaderFur.furVolMap02);
        cmpShaderFur.computeShader.SetTexture(_kernel, "FurVolMap03", cmpShaderFur.furVolMap03);

        cmpShaderFur.computeShader.SetTexture(_kernel, "FurMaskMap", cmpShaderFur.furmaskMap);

        cmpShaderFur.computeShader.SetTexture(_kernel, "FurPhxBoneIDMap", cmpShaderFur.furPhxBoneIDMap);
        cmpShaderFur.computeShader.SetTexture(_kernel, "FurPhxBoneSkinningMap", cmpShaderFur.furPhxBoneSkinningMap);


        cmpShaderFur.computeShader.SetBuffer(_kernel, "cBuffer", constantBuffer);
        cmpShaderFur.computeShader.SetBuffer(_kernel, "lineOutput", outputBuffer);
        cmpShaderFur.computeShader.Dispatch(_kernel, furTexResolutionX, furTexResolutionY, 1);
    }

}
