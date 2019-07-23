using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TextureCreator : MonoBehaviour
{
    Texture2D texture2D;
	public int size = 1024;
	public int iteration = 100;
	public float rangeCenterMin = 1.0f;
	public float rangeCenterMax = 10.0f;
	public float rangeStepMin = 0.1f;
	public float rangeStepMax = 1.0f;

    void Start ()
    {
		texture2D = CreateTexture2D (size);
        byte[] bytes;
        bytes = texture2D.EncodeToPNG();
        System.IO.File.WriteAllBytes(OurTempSquareImageLocation(), bytes);
    }

    private string OurTempSquareImageLocation()
    {
        string r = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Generic\\p.png";
        return r;
    }
    Texture2D CreateTexture2D (int size)
    {
        Color[] colorArray = new Color[size * size];
        texture2D = new Texture2D (size, size, TextureFormat.RGBA32, true);

		for (int i = 0; i < iteration; i++) {
			float centerX = Random.Range (rangeCenterMin, rangeCenterMax);
			float centerY = Random.Range (rangeCenterMin, rangeCenterMax);
			float sinStep = Random.Range (rangeStepMin, rangeStepMax);
	        for (int x = 0; x < size; x++) {
	            for (int y = 0; y < size; y++) {
					float valX = (x - centerX) * (x - centerX);
					float valY = (y - centerY) * (y - centerY);
					float val = Mathf.Sin(Mathf.Sqrt (valX + valY) * sinStep);
					val = val * 0.5f + 0.5f;
					val = val / (float)iteration;
					Color c = new Color (val, val, val);
					colorArray[x + (y * size)] += c;
				}
            }
        }
        texture2D.SetPixels (colorArray);
        texture2D.Apply ();
        
        return texture2D;
    }
        
}
