using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System.Xml;


public class FurBone
{
    public Transform bone;
    public List<Transform> baseBone = new List<Transform>();
    public List<int> baseBoneID = new List<int>();
    public List<float> boneWeight = new List<float>();

    public Matrix4x4 initXF;
    public Matrix4x4 initInvXF;

    public FurBone()
    {

    }
}
//[ExecuteInEditMode]
public class FurSkinning : MonoBehaviour
{
    public List<Material> furMaterials;

    List<Transform> baseBoneList = new List<Transform>();
    public List<Transform> baseBoneListByID = new List<Transform>();
    public List<Matrix4x4> baseBnInitInvXF = new List<Matrix4x4>();
    public Transform baseRigRoot;
    public Transform furRigRoot;
    public FurMeshBuilder furBuider;

    public List<FurBone> furBoneList0 = new List<FurBone>();
    public List<FurBone> furBoneList1 = new List<FurBone>();

    public string constraintPath = "D:\\FurBonesConstraint.xml";

    // Start is called before the first frame update
    void Start()
    {
        List<Transform> furBoneTransform0 = new List<Transform>();

        for (int i = 0; i < furRigRoot.childCount; i++)
        {
            furBoneTransform0.Add(furRigRoot.GetChild(i).GetComponent<Transform>());
        }

        for (int i = 0; i < furBoneTransform0.Count; i++)
        {
            FurBone newBone = new FurBone();
            newBone.bone = furBoneTransform0[i];
            newBone.initXF = newBone.bone.localToWorldMatrix;
            newBone.initInvXF = newBone.bone.worldToLocalMatrix;
            furBoneList0.Add(newBone);

            Transform childXf = furBoneTransform0[i].GetChild(0);
            FurBone newBone2 = new FurBone();
            newBone2.bone = childXf;
            newBone2.initInvXF = newBone2.bone.worldToLocalMatrix;
            furBoneList1.Add(newBone2);
        }

        furBuider = GetComponentInChildren<FurMeshBuilder>();
        furMaterials.Clear();
        foreach (MeshRenderer rend in furBuider.GetComponentsInChildren<MeshRenderer>())
        {
            furMaterials.Add(rend.sharedMaterial);
        }


        GetAllChildren(baseRigRoot, ref baseBoneList);

        ReadFurRigConstraint(constraintPath);
    }

    
    void ReadFurRigConstraint(string path)
    {
        XmlTextReader reader = new XmlTextReader(path);

        reader.WhitespaceHandling = WhitespaceHandling.None;

        reader.Read();

        while (!reader.EOF)
        {
            reader.Read();
            if (reader.Name == "BaseBone")
            {
                string boneName = reader.GetAttribute("Name");
                for (int i = 0; i < baseBoneList.Count; i++)
                {
                    if (baseBoneList[i].name == boneName)
                    {
                        baseBoneListByID.Add(baseBoneList[i]);
                        baseBnInitInvXF.Add(baseBoneList[i].worldToLocalMatrix);
                    }
                }
                print(reader.Name);
            }

            if (reader.Name == "FurBone")
            {
                string boneName = reader.GetAttribute("Name");
                for (int i = 0; i < furBoneList0.Count; i++)
                {
                    if (furBoneList0[i].bone.name == boneName)
                    {
                        string boneIDString = reader.GetAttribute("BoneID");
                        string[] boneIDList = boneIDString.Split(',');
                        foreach (string s in boneIDList)
                        {
                            int id = int.Parse(s);
                            Transform baseBone = baseBoneListByID[id];
                            furBoneList0[i].baseBone.Add(baseBone);
                            furBoneList0[i].baseBoneID.Add(id);
                        }

                        string boneWeightString = reader.GetAttribute("BoneWeight");
                        string[] boneWeightList = boneWeightString.Split(',');
                        foreach (string s in boneWeightList)
                        {
                            furBoneList0[i].boneWeight.Add(float.Parse(s));
                        }
                    }
                }
            }
        }
    }

    // Update is called once per frame
    private void Update()
    {
        Matrix4x4[] matArr0 = new Matrix4x4[furBoneList0.Count];
        Matrix4x4[] matArr1 = new Matrix4x4[furBoneList1.Count];

        for (int i = 0; i < furBoneList0.Count; i++)
        {
            FurBone furBone = furBoneList0[i];
            Matrix4x4 animatedFurBoneMat ;
            Vector3 finalFramePos = new Vector3();
            Quaternion finalFrameRot = new Quaternion();

            for (int k = 0; k < furBone.baseBoneID.Count; k++)
            {
                Transform baseBone = furBone.baseBone[k];
                float weight = furBone.boneWeight[k];
                int baseBoneID = furBone.baseBoneID[k];

                animatedFurBoneMat = baseBone.localToWorldMatrix * baseBnInitInvXF[baseBoneID] * furBone.initXF;

                finalFramePos += (Vector3)animatedFurBoneMat.GetColumn(3) * weight;

                finalFrameRot = Quaternion.Slerp(finalFrameRot, animatedFurBoneMat.rotation, weight);
            }

            furBone.bone.position = finalFramePos;
            furBone.bone.rotation = finalFrameRot;

            matArr0[i] = furBoneList0[i].bone.localToWorldMatrix * furBoneList0[i].initInvXF;
            matArr1[i] = furBoneList1[i].bone.localToWorldMatrix * furBoneList1[i].initInvXF;


        }

        foreach (Material mat in furMaterials)
        {
            mat.SetMatrixArray("BoneMatrics0", matArr0);
            mat.SetMatrixArray("BoneMatrics1", matArr1);

        }
        
    }


    void GetAllChildren(Transform parent, ref List<Transform> allChidren)
    {
        for (int i = 0; i < parent.childCount; i++)
        {
            Transform childTransform = parent.GetChild(i).GetComponent<Transform>();

            allChidren.Add(childTransform);

            GetAllChildren(childTransform, ref allChidren);
        }
    }

}