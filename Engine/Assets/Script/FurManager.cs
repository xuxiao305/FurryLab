using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ExecuteInEditMode]
public class FurManager : MonoBehaviour
{
    // Start is called before the first frame update

    public ComputeShaderFur[] furGeneratorList;

    [Header("Visual Params")]
    [Range(0.0f, 1.0f)]
    public float tearIntensity;
    public Material fabricMat;
    void Start()
    {
        furGeneratorList = GetComponentsInChildren<ComputeShaderFur>();


    }

    public void GenerateAllFur()
    {
        if (fabricMat != null)
        {
            fabricMat.SetFloat("_TearingInt", tearIntensity);

        }

        furGeneratorList = GetComponentsInChildren<ComputeShaderFur>();

        for (int i = 0; i < furGeneratorList.Length; i++)
        {
            furGeneratorList[i].TearInt = tearIntensity;
            furGeneratorList[i].GenerateFur();
        }
    }
}
