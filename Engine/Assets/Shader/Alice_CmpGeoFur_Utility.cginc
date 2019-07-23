// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef COMPUTER_GEO_FUR
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#define COMPUTER_GEO_FUR
#define BONE_NUM_PER_VERT 4
#define BONE_NUM_PER_LAYER 9

	sampler2D _FurIDMap;
	sampler2D _FurClumpingMap;



	half4 _FurClumpingMap_ST;
	sampler2D _FurFuzzyMap;
	half4 _FurFuzzyMap_ST;

	
	half4 _FurIDMap_ST;
	sampler2D _FurPosTex;
	half4 _FurPosTex_ST;

	sampler2D _FurStrandTex;
	half4 _FurStrandTex_ST;
	fixed4 _ScatteringColor;
	fixed4 _MutantColor;
	fixed _MutantRange;

	fixed4 _TipColor;	
	fixed4 _TipColor1;
	fixed4 _TipColor2;
	fixed4 _TipColor3;


	fixed4 _RootColor1;
	fixed4 _RootColor2;
	fixed4 _RootColor3;

	fixed _TipColorBlendWidth;
	fixed _TipColorBlendOffset;

	fixed _DetailNormalIntensity;
	fixed _TubeNormalIntensity;
	fixed _Gloss;
	fixed _SpecularScale; 
	fixed _SpecularShifting;

	fixed _FuzzyInt;
	fixed _FuzzyNoise;

	fixed _FurClumpingInt;
	fixed _FurTwistInt;
	fixed _FurWidth;

	fixed _FurLength;
	float _FurCut;

	fixed _FurTipTape;

	float4x4 BoneMatrics0[BONE_NUM_PER_LAYER];
	float4x4 BoneMatrics1[BONE_NUM_PER_LAYER];


#define GUIDELINE_NORMALIZE_FACTOR 10
#define POS_NORMALIZE_FACTOR 30.0
#define UNIT_FACTOR 0.01

	struct appdata_generic
	{
		float4 pos0 		: TEXCOORD0;
		float4 dataPack 	: TEXCOORD1;
		float4 dataPack2 	: TEXCOORD2;
		float4 dataPack3 	: TEXCOORD3;
		// float4 clumpBindMatCompressed : TEXCOORD3;
		float3 clumpPos0 : POSITION;
		float3 twistPos0 : NORMAL;

	};


	struct GS_INPUT {
		float3 pos0 : TEXCOORD0;
		float4 dataPack : TEXCOORD1;
		float4 dataPack2 : TEXCOORD2;
		float4 dataPack3 : TEXCOORD3;
		// float4 clumpBindMatCompressed : TEXCOORD3;
		float4 clumpPos0 : POSITION;
		float3 twistPos0 : NORMAL;
	};

	struct FS_INPUT
	{
		float4 pos        		: POSITION;
		half  u 				: TEXCOORD1;

	#ifdef GEO_FUR_SHADING
		half3 wHairDir			: TEXCOORD2;
		half3 wPos 				: TEXCOORD3;
		half  percent 			: TEXCOORD4;
		half  furID				: TEXCOORD5;
		half2 meshUV 			: TEXCOORD6;
		half3 meshNormal  		: NORMAL;
	#endif
	};	


	GS_INPUT VS_Main_CmpGeoFur(appdata_generic v)
	{
		GS_INPUT o = (GS_INPUT)0;
		o.pos0 = v.pos0;
		o.dataPack = v.dataPack;
		o.dataPack2 = v.dataPack2;
		o.dataPack3 = v.dataPack3;
		o.twistPos0 = v.twistPos0;
		// o.clumpBindMatCompressed = v.clumpBindMatCompressed;
		o.clumpPos0 = float4(v.clumpPos0, 1.0);

		return o;
	}

	float3 GetCatmullRomPosition(float t, float3 p0, float3 p1, float3 p2, float3 p3)
	{
		//The coefficients of the cubic polynomial (except the 0.5f * which I added later for performance)
		float3 a = 2 * p1;
		float3 b = p2 - p0;
		float3 c = 2 * p0 - 5 * p1 + 4 * p2 - p3;
		float3 d = -p0 + 3 * p1 - 3 * p2 + p3;

		//The cubic polynomial: a + b * t + c * t^2 + d * t^3
		float3 pos = 0.5 * (a + (b * t) + (c * t * t) + (d * t * t * t));

		return pos;
	}



	[maxvertexcount(50)]
	void GS_Main_CmpGeoFur(triangle GS_INPUT p[3], inout TriangleStream<FS_INPUT> triStream)
	{
		float4 vert[64];

		FS_INPUT pIn;
		
		float2 	meshUV 		= p[0].dataPack.xy;
		float 	randomID 	= p[0].dataPack.z;
		float3  meshNormal 	= p[1].dataPack.xyz;
		float3  pos1 		= p[2].dataPack.xyz;
		float3  clumpPos1 	= p[2].dataPack2.xyz;

		float4	skinningWeight 	= p[0].dataPack2;
		float4 	boneIDs = p[1].dataPack2;

		float4  clumpSkinningWeight = p[0].dataPack3;
		float4  clumpBoneIDs = p[1].dataPack3;
		float3  twistPos1 	= p[2].dataPack3.xyz;

		
		float4x3 strandPointPos = {float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0)};
		float4x3 strandClumpPos = {float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0)};
		// float4x3 strandTwistPos = {float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0), float3(0.0, 0.0, 0.0)};

		float3 	vv0 = lerp(p[0].pos0, p[0].twistPos0, _FurTwistInt);
		float3 	vv1 = lerp(p[1].pos0, p[1].twistPos0, _FurTwistInt);
		float3 	vv2 = lerp(p[2].pos0, p[2].twistPos0, _FurTwistInt);
		float3 	vv3 = lerp(pos1, twistPos1, _FurTwistInt);

		float4x3 vvList = {vv0, vv1, vv2, vv3};

		[unroll(3)]
		for (int v = 0; v < 3; v++)
		{
			float percent = float(v) / 3.0;

			[unroll(BONE_NUM_PER_VERT)]
			for (int i = 0; i < BONE_NUM_PER_VERT; i++)
			{
				float w = skinningWeight[i];
				int boneID = int(boneIDs[i]);
				strandPointPos[v]  += mul(BoneMatrics0[boneID], float4(vvList[v], 1.0)).xyz * w * (1.0 - percent);
				strandPointPos[v]  += mul(BoneMatrics1[boneID], float4(vvList[v], 1.0)).xyz * w * percent ;

				w = clumpSkinningWeight[i];
				boneID = int(clumpBoneIDs[i]);
				strandClumpPos[v]  += mul(BoneMatrics0[boneID], float4(p[v].clumpPos0.xyz, 1.0)).xyz * w * (1.0 - percent);
				strandClumpPos[v]  += mul(BoneMatrics1[boneID], float4(p[v].clumpPos0.xyz, 1.0)).xyz * w * percent ;

				if (v == 2)
				{
					strandPointPos[3] += mul(BoneMatrics1[boneID], float4(vvList[3], 1.0)).xyz * w;
					strandClumpPos[3] += mul(BoneMatrics1[boneID], float4(clumpPos1.xyz, 1.0)).xyz * w;
				}
			}		


		}



		fixed4 clumpingMap = tex2Dlod(_FurClumpingMap, float4(meshUV.xy * _FurClumpingMap_ST.xy + _FurClumpingMap_ST.zw, 0.0, 0.0));
		clumpingMap = 1.0;
		fixed  clumpingIntMask = _FurClumpingInt;
		fixed  clumpingShapeMask = lerp(0.75, 2, clumpingMap.g);
		fixed  twistIntMask = clumpingMap.b;
		fixed  furTwistness = _FurTwistInt * clumpingMap.b * 0.99;
		

		fixed4 fuzzyMap = tex2Dlod(_FurFuzzyMap, float4(meshUV.xy * _FurFuzzyMap_ST.xy + _FurFuzzyMap_ST.zw, 0.0, 0.0));

		fixed  fuzzyIntMask =  fuzzyMap.r * _FuzzyInt;
		fixed  fuzzyNoiseMask = _FuzzyNoise * fuzzyMap.g;

		float3 v0 = strandPointPos[0];
		float3 v1 = (strandPointPos[0] - v0) * _FurCut + v0;
		float3 v2 = (strandPointPos[1] - v0) * _FurCut + v0;
		float3 v3 = (strandPointPos[2] - v0) * _FurCut + v0;
		float3 v4 = (strandPointPos[3] - v0) * _FurCut + v0;

		float3 v5 = v4 + (v4 - v3) * 0.1;
		v0 += v2 - v1; // shift the v0 along the opposite direction of v1 and v2

		float3 cv0 = strandClumpPos[0];
		float3 cv1 = (strandClumpPos[0] - cv0) * _FurCut + cv0;
		float3 cv2 = (strandClumpPos[1] - cv0) * _FurCut + cv0;
		float3 cv3 = (strandClumpPos[2] - cv0) * _FurCut + cv0;
		float3 cv4 = (strandClumpPos[3] - cv0) * _FurCut + cv0;

		float3 cv5 = cv4 + (cv4 - cv3) * 0.1;
		cv0 += cv2 - cv1; // shift the v0 along the opposite direction of v1 and v2

		float4x3 pointGrp0 = {v0, v1, v2, v3};
		float4x3 pointGrp1 = {v1, v2, v3, v4};
		float4x3 pointGrp2 = {v2, v3, v4, v5};

		float4x3 cPointGrp0 = {cv0, cv1, cv2, cv3};
		float4x3 cPointGrp1 = {cv1, cv2, cv3, cv4};
		float4x3 cPointGrp2 = {cv2, cv3, cv4, cv5};

		float4x3 pointGrp[3] = {pointGrp0,pointGrp1,pointGrp2};
		float4x3 cPointGrp[3] = {cPointGrp0,cPointGrp1,cPointGrp2};

		int segments = 3;

		float3x2 percentGrp = {float2(0.0,0.33333), float2(0.33333,0.6666667), float2(0.6666667,1.0)};

		float3  tangent = normalize(v3 - v1);
		float3 	sideVec		= normalize(cross(tangent, meshNormal));

		[unroll(3)]
		for (int i = 0; i < 3; i++)
		{
			float3 p0 = pointGrp[i][0];
			float3 p1 = pointGrp[i][1];
			float3 p2 = pointGrp[i][2];
			float3 p3 = pointGrp[i][3];

			float3 cp0 = cPointGrp[i][0];
			float3 cp1 = cPointGrp[i][1];
			float3 cp2 = cPointGrp[i][2];
			float3 cp3 = cPointGrp[i][3];
			
			float2 percent0 = percentGrp[i][0];
			float2 percent1 = percentGrp[i][1];

			[unroll(segments)]
			for(int s = 0; s < segments; s++)
			{
				float t = (float(s) / (segments - 1.0));
				float percent = lerp(percent0, percent1, t);

				float3 pos = GetCatmullRomPosition(t, p0, p1, p2, p3); 
				float3 posNext = GetCatmullRomPosition(t + 0.1, p0, p1, p2, p3); 
				float3 clumpPos = GetCatmullRomPosition(t, cp0, cp1, cp2, cp3); 

				pos = lerp(pos, clumpPos, _FurClumpingInt * percent);

				float3 wHairDir = normalize(posNext - pos);

				for (int u = 0; u < 2; u++)
				{
					// float4 pos1 = float4(pos.xyz + (float(u) - 0.5)  * 0.01 * _FurWidth, 1.0f);
					float tipTape = 1.0 - percent * percent * _FurTipTape;
					float4 pos1 = float4(pos.xyz + (float(u) - 0.5) * sideVec * _FurWidth * 0.02 * tipTape, 1.0f);

					pIn.pos = UnityObjectToClipPos(pos1);

					pIn.u = u;

					#ifdef GEO_FUR_SHADING
						// need to perform some operate on the each output value to avoid the l-value casting issue 
						pIn.furID = randomID + 0.0;
						pIn.percent = percent + 0.0;
						pIn.wHairDir = wHairDir + 0.0;
						pIn.wPos = mul(unity_ObjectToWorld, pos1);
						pIn.meshUV = meshUV + (u * 0.03);
						pIn.meshNormal = meshNormal + 0.0;
					#endif

					triStream.Append(pIn);	
				}	
			}
		}
	}

//Pixel function returns a solid color for each point.
	float4 FS_Main_CmpGeoFur(FS_INPUT i) : COLOR
	{
		fixed4 outputColor = 1.0;

		fixed4 albedo = 1.0;
		#ifdef GEO_FUR_SHADING
			float percent = i.percent;
			half rand = sin(i.meshUV.x + i.meshUV.y * 50);
			fixed2 uv = fixed2(i.u, 1.0 - i.percent);
		
			fixed4  furStrandMap = tex2D(_FurStrandTex, uv * _FurStrandTex_ST.x);

			half3   tNormal = furStrandMap.rgb * 2.0 - 1.0;

					tNormal = normalize(half3(tNormal.xy * _DetailNormalIntensity, tNormal.z));


			half3   tubeNormal = half3((i.u - 0.5) * 2.0, 0.0, 1.0);
					tubeNormal = normalize(half3(tubeNormal.xy * _TubeNormalIntensity, tubeNormal.z));

					tNormal.xy += tubeNormal.xy;

					tNormal = normalize(tNormal.xyz);


			float furID = i.furID ;
			fixed 	perFurIDShift = furID * (sin(furID * furID * furID * 10)) * 1;
			


			fixed3 	idMap = tex2D(_FurIDMap, i.meshUV * _FurIDMap_ST.xy + _FurIDMap_ST.zw);
					// idMap.x += furID * 5.25;
					// idMap.y += perFurIDShift * 1.5;
					// idMap.z += perFurIDShift * 3.5;
					// idMap = normalize(idMap);
					// idMap = pow(idMap, 2);

			// fixed4	tipColor = lerp(lerp(_TipColor1 * idMap.r, _TipColor2, idMap.g), _TipColor3, idMap.b);

			// fixed4	rootColor = lerp(lerp(_RootColor1 * idMap.r, _RootColor2, idMap.g), _RootColor3, idMap.b);


			


			fixed 	mutantMask = pow(saturate(perFurIDShift), 4.0 * (1.1 - _MutantRange)) * _MutantColor.a;
					albedo.xyz = idMap;
					albedo.xyz *= lerp(_RootColor1.xyz, _TipColor1.xyz, smoothstep(0.5 - _TipColorBlendWidth + _TipColorBlendOffset + perFurIDShift,
			                                                     	0.5 + _TipColorBlendWidth + _TipColorBlendOffset + perFurIDShift,
			                                                     	percent));

					albedo.xyz = lerp(albedo.xyz, _MutantColor.xyz, mutantMask);

					fixed3 shadowUV0 = shadowingUV(i.wPos, 1, _ShadowProjectionMatrix0, _ShadowNormalBias0, _ShadowDistanceBias0);
					fixed3 shadowUV1 = shadowingUV(i.wPos, 1, _ShadowProjectionMatrix1, _ShadowNormalBias1, _ShadowDistanceBias1);
			

			half3 	wHairDir = i.wHairDir;

			// bool 	useDirMap = false;
			// 		if (useDirMap)
			// 		{
			// 			wHairDir = tex2D(_FurPosTex, i.meshUV) * 2.0 - 1.0;
			// 			wHairDir = normalize(wHairDir);
			// 			wHairDir.yz = wHairDir.zy;
			// 			wHairDir.x = - wHairDir.x;						
			// 		}

			half3 	wUp = half3(0,1,0);
			half3 	wSide = normalize(cross(wHairDir, wUp));         
			half3 	wNormal = normalize(cross(wSide, wHairDir));
					wNormal = i.meshNormal;

			half 	specShift = (furID - 0.5) * _SpecularShifting;


			half3   lightingResult = GenericLighting(albedo, 
		                                              tNormal, 
		                                              0.0,
		                                              0.0,
		                                              1.0,
		                                              0.0,
		                                              1.0,
		                                              1.0,
		                                              0.0,
		                                              wNormal,
		                                              wHairDir,
		                                              wSide,
		                                              i.wPos,
		                                              shadowUV0,
		                                              shadowUV1,
		                                              uv,
		                                              specShift,
		                                              _Gloss,
		                                              _SpecularScale,
		                                              1.0, 1.0, 1.0, 1.0);

				    outputColor.xyz = lightingResult.rgb;// * percent ;//* percent;

			// float 	alphaV = pow(furStrandMap.a, 2.0);
			// alphaV *= _AlphaEnhancement;
			
			// half3 viewPos = normalize(_WorldSpaceCameraPos - i.wPos) * _AlphaDitherSize;
			// half frame = 100.0;
			// if (_AlphaDither > 0.5)
			// {
			// 	AlphaToDitheringHiRes(viewPos, alphaV, frame,   alphaV);
			// }


		    // clip(alphaV - 0.2);
		    outputColor.rgb = percent;

		#endif
		// return BoneMatrics[0][0];
		return outputColor * 1.0 ;
	}

#endif