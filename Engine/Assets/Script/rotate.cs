using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ExecuteInEditMode]
public class rotate : MonoBehaviour {
    public float angles = 0;
    public float speed = 1.0f;

	// Use this for initialization
	void Start () {
        angles = 0.0f;
	}
	
	// Update is called once per frame
	void Update () {
        angles += speed * Time.deltaTime;
       // angles = Mathf.LerpAngle(200, 230, Mathf.Sin(Time.time) * 0.5f + 0.5f);
        float rad = angles / 360.0f;
        gameObject.transform.localRotation = Quaternion.AngleAxis(angles, Vector3.up);
        Shader.SetGlobalFloat("_EnvRotation", rad - Mathf.Floor(rad));
	}
}
