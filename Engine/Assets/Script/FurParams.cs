using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class FurParams : MonoBehaviour {

    public Material furMat;
    public AnimationCurve curve;
    public float[] occ;


    // Use this for initialization

    void Start () {
    }
	
	// Update is called once per frame
	void Update () {
        occ = new float[16];

        for (int i = 0; i < occ.Length; i++)
        {
            float occlusionValue = curve.Evaluate((float)i / (float)occ.Length);
            occ[i] = occlusionValue;
        }
		furMat.SetFloatArray("colorLerpFactorList", occ);
    }
}
