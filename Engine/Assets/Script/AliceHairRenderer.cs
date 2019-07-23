using UnityEngine;
using System.Collections.Generic;

// Based on the script of Unity Demo Blacksmooth Hair Renderer 
//[ExecuteInEditMode]
public class AliceHairRenderer : MonoBehaviour {
	public enum DebugMode { DBG_HAIR_NONE, DBG_HAIR_OCCLUSION, DBG_HAIR_GRAYMASK, DBG_HAIR_MASKEDALBEDO, DBG_HAIR_SPECULAR, DBG_HAIR_LIGHTING, DBG_HAIR_FLOW }

	public enum Mode { Original, StaticHeightBased, DynamicRadialDistance };
	
	public Renderer		sourceRenderer;
	public Mode			mode = Mode.StaticHeightBased;
	public float		opaqueAlphaRef = 0.80f;
	public float		frontAlphaRef = 0f;
	public Transform[]	headSpheres;
	public Transform	headShell;
	public float		sortDistanceScale = 1f;
	public DebugMode	debugMode = DebugMode.DBG_HAIR_NONE;


    public Mesh m_sourceMesh;
    public Mesh m_sortedMesh;
	int[]		m_sortedIndices;
	MeshFilter	m_meshFilter;
	MeshSorter	m_meshSorter;
	Material	m_materialOpaque;
	Material	m_materialBack;
	Material	m_materialFront;

	void Awake () {
		debugMode = DebugMode.DBG_HAIR_NONE;
        sourceRenderer = gameObject.GetComponentInParent<Renderer>();

        gameObject.layer = sourceRenderer.gameObject.layer;
		if(sourceRenderer is MeshRenderer)
			m_sourceMesh = ((MeshRenderer)sourceRenderer).GetComponent<MeshFilter>().sharedMesh;
		else if(sourceRenderer is SkinnedMeshRenderer)
			m_sourceMesh = ((SkinnedMeshRenderer)sourceRenderer).sharedMesh;
		else
			Debug.LogError("Invalid source renderer type");

		CreateMeshData();
        SelectMesh();
    }

	void CreateMeshData() {
		var vertices = m_sourceMesh.vertices;
		var uvs = m_sourceMesh.uv;
		var colors = m_sourceMesh.colors;
		var indices = m_sourceMesh.triangles;
		m_sortedIndices = new int[indices.Length];

		m_meshSorter = new MeshSorter(vertices, uvs, colors, indices, sourceRenderer.transform, headSpheres);
		m_meshSorter.BuildNormalizedPatches();
		m_meshSorter.SortIndices(Vector3.zero, m_sortedIndices, 0f);

		m_sortedMesh = new Mesh();
        m_sortedMesh.name = "Sorted_" + m_sourceMesh.name;
        m_sortedMesh.vertices = vertices;
		m_sortedMesh.uv = uvs;
		m_sortedMesh.normals = m_sourceMesh.normals;
		m_sortedMesh.tangents = m_sourceMesh.tangents;
		m_sortedMesh.colors = m_meshSorter.staticPatchColors;
		m_sortedMesh.triangles = m_sortedIndices;
		m_sortedMesh.bindposes = m_sourceMesh.bindposes;
		m_sortedMesh.boneWeights = m_sourceMesh.boneWeights;
		m_sourceMesh.RecalculateBounds();
	}

    void AddChild(Material material)
    {
        var go = new GameObject(material.name);
        go.name = "Sorted Fur";
        go.layer = gameObject.layer;
        go.transform.parent = transform;
        go.transform.localPosition = Vector3.zero;
        go.transform.localRotation = Quaternion.identity;
        go.transform.localScale = Vector3.one;

        if (sourceRenderer is MeshRenderer)
        {
            go.AddComponent<MeshFilter>().sharedMesh = m_sortedMesh;
            var mr = go.AddComponent<MeshRenderer>();
            mr.sharedMaterial = material;
            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            mr.receiveShadows = true;
        }
        else
        {
            var smr = go.AddComponent<SkinnedMeshRenderer>();
            smr.rootBone = (sourceRenderer as SkinnedMeshRenderer).rootBone;
            smr.bones = (sourceRenderer as SkinnedMeshRenderer).bones;
            smr.sharedMaterial = material;
            smr.sharedMesh = m_sortedMesh;
        }
    }

    void SelectMesh()
    {
        foreach (var c in transform)
            Destroy((c as Transform).gameObject);

        sourceRenderer.enabled = false;

        AddChild(sourceRenderer.sharedMaterial);
    }

    void LateUpdate() {
		if(Camera.main == null || mode != Mode.DynamicRadialDistance)
			return;

		var eyePos = Camera.main.transform.position;
		var eyeHeadVec = headShell.transform.position - eyePos;
		var eyeRay = new Ray(eyePos, eyeHeadVec);
		RaycastHit rhi;
		if(headShell.GetComponent<SphereCollider>().Raycast(eyeRay, out rhi, eyeHeadVec.magnitude)) {
			m_meshSorter.SortIndices(transform.InverseTransformPoint(rhi.point), m_sortedIndices, sortDistanceScale);
			Debug.DrawLine(eyePos, rhi.point, Color.red, 3f);
			m_sortedMesh.triangles = m_sortedIndices;
                
			m_sortedMesh.colors = m_meshSorter.staticPatchColors;
            //for (int i = 0; i < m_sortedMesh.colors.Length; i++)
            //{
            //    print(m_sortedMesh.colors[i].r.ToString());
            //}
        } else {
			Debug.LogWarning("Failed to find head ray.. inside shell?");
		}

	}

	#region MeshSorter
	class MeshSorter {
		Vector3[]		vertices;
		Vector2[]		uvs;
		Color[]			colors;
		SortablePatch[]	sortablePatches;
		uint[]			sortingList;
		
		public Color[]		staticPatchColors;
		public int[]		staticPatchIndices;
		
		class Triangle {
			public int i0, i1, i2;
			
			public Triangle(int i0, int i1, int i2) {
				this.i0 = i0;
				this.i1 = i1;
				this.i2 = i2;
			}
		}
		
		class Patch {
			public MeshSorter			owner;
			public HashSet<int>			indices;
			public HashSet<Triangle>	triangles;
			
			public Patch(MeshSorter owner, Triangle t) {
				this.owner = owner;
				indices = new HashSet<int>();
				triangles = new HashSet<Triangle>();
				
				if(t != null)
					AddTriangle(t);
			}
			
			public bool AddTriangle(Triangle t) {
				if(triangles.Contains(t))
					return false;
				
				triangles.Add(t);
				indices.Add(t.i0);
				indices.Add(t.i1);
				indices.Add(t.i2);
				return true;
			}
			
			public bool Merge(Patch p) {
				int commonCount = 0;
				foreach(var pi in p.indices) {
					if(indices.Contains(pi)) {
						if(++commonCount >= 1) 
							goto outside;
					} else {
						// This is dog slow, but good enough for now (and can also be baked if we're too lazy to opt it).
						const float threshold = 0.001f * 0.001f;
						var piv = owner.vertices[pi];
						foreach(var si in indices) {
							var siv = owner.vertices[si];
							if(Vector3.SqrMagnitude(piv - siv) <= threshold)
								if(++commonCount >= 1)
									goto outside;
						}
					}
				}
			outside:
					
				if(commonCount >= 1) {
					foreach(var t in p.triangles)
						AddTriangle(t);
					
					return true;
				}
				
				return false;
			}
		}
		
		struct SortablePatch {
			public Vector3	centroid;
			public float	layer;
			public int[]	indices;
			
			public SortablePatch(int[] i, Vector3 c, float l) {
				indices = i;
				centroid = c;
				layer = l;
			}
		}
		
		public MeshSorter(Vector3[] vertices, Vector2[] uvs, Color[] colors, int[] indices, Transform space, Transform[] spheres) {
			this.vertices = vertices;
			this.uvs = uvs;
			this.colors = colors;
			
			var patches = new List<Patch>();
			patches.Add(new Patch(this, new Triangle(indices[0], indices[1], indices[2])));
			Patch activePatch = patches[0];
			for(int i = 3, n = indices.Length; i < n; i += 3) {
				var newPatch = new Patch(this, new Triangle(indices[i], indices[i+1], indices[i+2]));
				if(!activePatch.Merge(newPatch)) {
					patches.Add(newPatch);
					activePatch = newPatch;
				}
			}
			
			staticPatchColors = new Color[vertices.Length];
			var staticIndices = new List<int>();
			int patchIdx = 0;
			foreach(var p in patches) {
				foreach(var t in p.triangles) {
					staticIndices.Add(t.i0);
					staticIndices.Add(t.i1);
					staticIndices.Add(t.i2);
					
					//SetDebugColor(patches.Count, patchIdx, t.i0, null);
					//SetDebugColor(patches.Count, patchIdx, t.i1, null);
					//SetDebugColor(patches.Count, patchIdx, t.i2, null);
				}
				//Debug.Log(string.Format("Indices in patch {0}: {1}", patchIdx, p.triangles.Count * 3));
				++patchIdx;
			}
			staticPatchIndices = staticIndices.ToArray();
			
			//Debug.Log(string.Format("Merged {2} triangles to {0} patches in {1} iterations (tried {3} - out {4} indices).", patches.Count, mergeIterations, indices.Length/3, mergeTests, staticIndices.Count));
			
			
			sortingList = new uint[patches.Count];
			sortablePatches = new SortablePatch[patches.Count];
			for(int i = 0, n = patches.Count; i < n; ++i) {
				var p = patches[i];
				
				var c = Vector3.zero;
				var l = float.MaxValue;
				foreach(var idx in p.indices) {
					var v = vertices[idx];
					c += v;
     
					#if _DISABLED
					foreach(var s in spheres) {
						l = Mathf.Min(l, Vector3.Distance(space.TransformPoint(v), s.position) - s.localScale.x);
					}
					#else
					l = Mathf.Min(l, space.TransformPoint(v).y - space.position.y);
					#endif
				}
				c /= (float)p.indices.Count;
                
				var patchIndices = new int[p.triangles.Count * 3];
				var pIdx = 0;
				foreach(var t in p.triangles) {
					patchIndices[pIdx++] = t.i0;
					patchIndices[pIdx++] = t.i1;
					patchIndices[pIdx++] = t.i2;
				}
				
				//Debug.Log(string.Format("Patch {0}:  Layer: {1}  Centroid: {2}", patchIdx, l, c));
				sortablePatches[i] = new SortablePatch(patchIndices, c, l);
			}
		}
		
		void SetDebugColor(int patchCount, int patchIdx, int offset, int[] indices) {
			float r = Mathf.Ceil((float)patchCount / 3f);
			float r2 = 2f * r;
			float fpi = (float)patchIdx;
			
			Color c = new Color();
			if(fpi <= r) c.r = Mathf.Clamp01(fpi / r);
			else if((fpi - r) <= r) c.g = Mathf.Clamp01((fpi - r) / r);
			else c.b = Mathf.Clamp01((fpi - r2) / r);
			
			if(indices != null)
				for(int i = 0, n = indices.Length; i < n; ++i)
					staticPatchColors[indices[i]] = c;
			else
				staticPatchColors[offset] = c;
		}
		
		public void BuildNormalizedPatches() {
			for(int i = 0, n = sortablePatches.Length; i < n; ++i) {
				var patch = sortablePatches[i];
				var idc = patch.indices;
				float vMin = 1f, vMax = 0f;
				for(int j = 0, m = idc.Length; j < m; ++j) {
					var uv = uvs[idc[j]];
					vMin = Mathf.Min(vMin, uv.y);
					vMax = Mathf.Max(vMax, uv.y);
				}
				
				var vScale = 1f / (vMax - vMin);
				var vOffset = vMin;
				
				for(int j = 0, m = idc.Length; j < m; ++j) {
					var idx = idc[j];
					var uvn = Mathf.Clamp01((uvs[idx].y - vOffset) * vScale);
					var uvn2 = uvn * uvn;
					var uvn3 = uvn2 * uvn;
					var alpha = colors.Length > 0 ? colors[idx].a : 1f;
					staticPatchColors[idx] = new Color(1f - uvn, 1f - uvn2, 1f - uvn3, alpha);
				}
			}
		}
		
		public void SortIndices(Vector3 eye, int[] indices, float distScale) {
			UnityEngine.Profiling.Profiler.BeginSample("SortIndices");
			for(int i = 0, n = sortingList.Length; i < n; ++i) {
				var sp = sortablePatches[i];
				//Debug.Log(string.Format("SP: {0}  L: {1}  D2: {2}  D: {3}  C: {4}", i, sp.layer, Vector3.SqrMagnitude(eye - sp.centroid), Vector3.Distance(eye, sp.centroid), sp.centroid));
				var w = sp.layer + Vector3.SqrMagnitude(eye - sp.centroid) * distScale;
				var iw = Mathf.RoundToInt(Mathf.Clamp(w * 100f, 0f, 1048575f)); //TODO: use shell size as scale
				sortingList[i] = (uint)(((iw&0xFFFFF) << 20) | (i&0xFFF));
			}
			
			System.Array.Sort(sortingList);
			
			for(int i = 0, n = sortingList.Length, off = 0; i < n; ++i) {
				#if _DISABLED
				var si = sortingList[n - i - 1] & 0xFFF;
				#else
				var si = sortingList[i] & 0xFFF;
				#endif
				var spi = sortablePatches[si].indices;
				System.Array.Copy(spi, 0, indices, off, spi.Length);
				//SetDebugColor(n, i, 0, spi);
				off += spi.Length;
			}
			
			UnityEngine.Profiling.Profiler.EndSample();
		}
	}
	#endregion
}