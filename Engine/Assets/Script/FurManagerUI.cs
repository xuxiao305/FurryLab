using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(FurManager))]
public class FurManagerUI : Editor
{
    //public bool autoRefresh = false;

    private float val;
    
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        FurManager furManager = (FurManager)target;

        if (GUILayout.Button("Generate All Fur"))
        {
            furManager.GenerateAllFur();

        }

        
        GUILayout.HorizontalSlider(furManager.tearIntensity, 0.0f, 1.0f);

        //if (val != furManager.tearIntensity)
        //{
        //    furManager.GenerateAllFur();
        //}


        val = furManager.tearIntensity;

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
