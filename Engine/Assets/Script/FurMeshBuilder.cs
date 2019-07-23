using UnityEngine;
using System.Collections.Generic;

//[ExecuteInEditMode]
public class FurMeshBuilder : MonoBehaviour
{
    //public Vector4[] posList0;
    //public Vector3[] clumpPosList0;
    //public Vector3[] twistPos0List;

    //public Vector4[] dataPackList;
    //public Vector4[] dataPack2List;
    //public Vector4[] dataPack3List;


    //[HideInInspector]
    public int[] newTriangles;

    MeshFilter meshFilter;
    Mesh mesh;
    

    void Start()
    {
        //posList0 = new Vector4[0];
        //dataPackList = new Vector4[0];
        //dataPack2List = new Vector4[0];
        //dataPack3List = new Vector4[0];
        //twistPos0List = new Vector3[0];

        newTriangles = new int[0];
    }


    public void BuildMesh(List<Vector4> pos0,
                             List<Vector3> clumpPos0,
                             List<Vector3> twistPos0,
                             List<Vector4> dataPack,
                             List<Vector4> dataPack2,
                             List<Vector4> dataPack3,
                            int[] triangles)
    {

        mesh = GetComponent<MeshFilter>().sharedMesh;
        
        //if (mesh == null)
        //{
            mesh = new Mesh();
            mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
            meshFilter = GetComponent<MeshFilter>();
            meshFilter.sharedMesh = mesh;
        //}
        mesh.Clear();

        mesh.SetVertices(clumpPos0);
        mesh.SetUVs(0, pos0);
        mesh.SetNormals(twistPos0);
        mesh.SetUVs(1, dataPack);
        mesh.SetUVs(2, dataPack2);
        mesh.SetUVs(3, dataPack3);

        mesh.triangles = triangles;
        newTriangles = triangles;

        mesh.RecalculateBounds();

        //posList0 = pos0.ToArray();
        //dataPackList = dataPack.ToArray();
        //dataPack2List = dataPack2.ToArray();
        //dataPack3List = dataPack3.ToArray();
        //twistPos0List = twistPos0.ToArray();
        //clumpPosList0 = clumpPos0.ToArray();
        //mesh.triangles = triangles;
    }

}