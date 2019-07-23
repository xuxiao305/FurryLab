using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(ComputeShaderFur))]
public class FurGeneratorUI : Editor
{
    //public bool autoRefresh = false;
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        ComputeShaderFur furGenerator = (ComputeShaderFur)target;

        if (GUILayout.Button("Generate Fur"))
        {
            furGenerator.GenerateFur();

        }


    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
