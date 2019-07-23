#ifndef GEOFUR
#define GEOFUR


#define IMPORT_GEOFUR_UNIFORM 	
	float _Segment;
	fixed _ShapeCurve;
	fixed _TipScale;
	fixed _TipScaleThinToThick;
	float _Length;
	float4x4 _VP;
	
	sampler2D _DirectionTex;
	fixed _DirectionTexIntensity;
	fixed _BaseMeshVertCount;
	float _Stiffness;
	float _Turbluance;
	half _Clustering;

	sampler2D _HairMaskTex;
	half4 _HairMaskTex_ST;
	sampler2D _FurTex; 
	sampler2D _HairColorTex;
	half4 _HairColorTex_ST;
	fixed _NormalIntensity; 
	float _FurReduction; 
	float _FurLength;
	fixed _ShadingWarp;
	fixed _Sheen;
	fixed _Gloss;
	fixed _SpecularScale; 
	fixed _SpecularShifting;
		
	fixed4 _ScatteringColor;
	fixed3 _TipColor1;
	fixed3 _TipColor2;
	fixed _TipColor12Blend;
	fixed _RootTipColorBlendWidth;
	fixed _RootTipColorBlendOffset;
	fixed3 _RootColor;
	fixed _FurStiff;
	half4 _WindDirection;
	fixed _HairNormalSmooth;
	fixed _percentage;
	fixed _PushShellToTip;
	fixed _MaxWidth;
	fixed _MinWidth;
	fixed _LocalRandomization;
	fixed _LengthNoiseFrequency;
	fixed _LengthNoiseAmplitude;


	half toneMappingFactor;
	fixed toneMappingLerp;

struct appdata_generic
{
	float4 vertex		: POSITION;
	fixed2 uv			: TEXCOORD0;
	fixed2 uv2			: TEXCOORD1;
	half3 normal		: NORMAL;
	half3 tangent  		: TANGENT;
	fixed4 color 		: COLOR;

};

struct GS_INPUT
{
	float4 pos    : POSITION;

	float3 wNormal : NORMAL;
	float3 wTangent : TEXCOORD3;
	float3 wBinormal : TEXCOORD2;
	float2 uv    : TEXCOORD0;
	float4 wPos : TEXCOORD1;
	float4 color : COLOR;
};

struct FS_INPUT1
{
	float4 pos        		: POSITION;
	float2 uv 				: TEXCOORD2;

#ifdef GEO_FUR_SHADING
	half3 color				: TEXCOORD1;
#endif
};

struct FS_INPUT
{
	float4 pos        		: POSITION;
	float2 uv 				: TEXCOORD1;

#ifdef GEO_FUR_SHADING
	half3 wHairDir			: TEXCOORD2;
	half3 wPos 				: TEXCOORD3;
#endif
};

GS_INPUT VS_Main_GeoFur(appdata_generic v)
{
	GS_INPUT output = (GS_INPUT)0;

	output.wPos = mul(unity_ObjectToWorld, v.vertex);
	output.pos = v.vertex;
	output.wNormal = normalize(mul(unity_ObjectToWorld, v.normal));
	output.wTangent = normalize(mul(unity_ObjectToWorld, v.tangent));
	output.wBinormal = normalize(cross(output.wNormal, output.wTangent)) ;
	output.uv = v.uv;
	output.color = v.color;

	return output;
}


[maxvertexcount(80)]
void GS_Main_GeoFur(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream)
{
	float4 vert[2];
	FS_INPUT pIn;

	half3 wMacroHairDir = 0;

	float randVal = sin(p[0].uv.y * 10 + p[0].wPos.x * 10) ;
	
	half3 wLookAt = normalize(_WorldSpaceCameraPos - p[0].wPos);

	half3 worldUp = half3(0.0, 1.0, 0.0);

	half curvedWidth = 0.01 * lerp(_MinWidth, _MaxWidth, randVal * 0.5 + 0.5);
	half tipScale = lerp(_TipScale, _TipScale + 0.5, 1.0 - pow(randVal * 0.5 + 0.5,  _TipScaleThinToThick)); 

	half3 wMacroNormal = p[0].wNormal;

	// Local Randomization
	fixed3x3 tangentMatrix = float3x3(p[0].wTangent.x, p[0].wBinormal.x, p[0].wNormal.x,
									  p[0].wTangent.y, p[0].wBinormal.y, p[0].wNormal.y,
									  p[0].wTangent.z, p[0].wBinormal.z, p[0].wNormal.z);

	half randomOffsetX = sin(randVal*  5) * _LocalRandomization;
	half randomOffsetY = sin(randVal * 3) * _LocalRandomization;
	half randomOffsetZ = sin(randVal * 10) * _LocalRandomization;

	half3 localRandomization = mul(tangentMatrix, half3(randomOffsetX, randomOffsetY, randomOffsetX));

	//////////////// Create Points Along Spline ////////////////////////////

	int segment = 3; // the hardcoded segment value for the shadow
	#ifdef GEO_FUR_SHADING
		segment = (int)_Segment;
	#else
		curvedWidth *= 3.0;
	#endif

	for(int i = 0; i < segment; i++)
	{
		//////////////// Create Points Along Spline ////////////////////////////
		half percentage = i / (float)segment;

		half uvX0 = lerp(0.1, 1.0, percentage); // the direction texture that i did have 0 0 0 value in the first colume of each row! 
		half uvY = (p[0].uv.y + 0.5) / _BaseMeshVertCount;

		half3 	lHairOffset = tex2Dlod(_DirectionTex, float4(uvX0, uvY, 0, 0)).xyz * 2.0 - 1.0 ;
		lHairOffset.yz = lHairOffset.zy;
		lHairOffset.z = -lHairOffset.z;
				
		half lHairOffsetLength = length(lHairOffset);
		
		half3 noiseXYZ = percentage * sin(percentage * _LengthNoiseFrequency * lHairOffsetLength + randVal * float3(2,4,0)) * _LengthNoiseAmplitude;
		noiseXYZ = mul(tangentMatrix, noiseXYZ);

		lHairOffset = lerp(p[0].wNormal * lHairOffsetLength, lHairOffset, _DirectionTexIntensity);

		half3 wHairDir = normalize(mul(unity_ObjectToWorld, normalize(lHairOffset)));
		half3 wRight = normalize(cross(wHairDir, wLookAt));

		float3x3 wLookAtMat = float3x3(wRight.x, wHairDir.x, wLookAt.x, 
		                               wRight.y, wHairDir.y, wLookAt.y, 
		                               wRight.z, wHairDir.z, wLookAt.z);

		curvedWidth *= lerp(1.0 + tipScale, 1.0, pow((1.0 - percentage), _ShapeCurve));
		



	//////////////// Lighting and Shadows ////////////////////////////


		for (int u = 0; u < 2; u++)
		{
			half offsetX = curvedWidth * (u - 0.5) * 2.0;
			// half3 offset = half3(offsetX, _Length * 0.02  * length(lHairOffset) , offsetX);
			// the offsetX shouldn't be in Z component???
			half3 offset = half3(offsetX, _Length * length(lHairOffset) , 0);

			offset = mul(wLookAtMat, offset);

			float4 wPos = float4(p[0].wPos.xyz + offset, 1.0f);
			wPos.xyz += localRandomization * percentage * percentage;
			wPos.xyz += noiseXYZ;

			half3 wTemp = normalize(mul(unity_ObjectToWorld, normalize(lHairOffset)));

			float4 projPos = mul(UNITY_MATRIX_VP, wPos);

			pIn.pos = projPos;
			pIn.uv = half2(u * curvedWidth * _HairColorTex_ST.x + p[0].wPos.x, 1.0 - percentage);

			#ifdef GEO_FUR_SHADING
				pIn.wPos = wPos.xyz;
				pIn.wHairDir = wTemp.xyz;
			#endif
			triStream.Append(pIn);	
		}	
	
	}
}

float4 FS_Main_GeoFur(FS_INPUT i) : COLOR
{
#ifdef GEO_FUR_SHADING 
	fixed4  furColor = tex2D(_HairColorTex, i.uv);
	half3   tNormal = furColor.rgb * 2.0 - 1.0;
	tNormal = normalize(half3(tNormal.xy * _NormalIntensity, tNormal.z));
	fixed  specShift = (furColor.a - 0.5) * _SpecularShifting * 1;
	fixed 	alpha = furColor.a;

	///////////////// Albedo /////////////////
	// fixed3 tipColor = lerp(_TipColor1, _TipColor2, smoothstep(_TipColor12Blend - 0.1, _TipColor12Blend + 0.1, (hairStrandTipMask + hairStrandCurvyMask) * 0.5));
	half percentage = 1.0 - i.uv.y;
	fixed3 tipColor = lerp(_TipColor1, _TipColor2, _TipColor12Blend * 0.5 + 0.5);

	fixed3 albedo = lerp(_RootColor, tipColor, smoothstep(0.0 + _RootTipColorBlendWidth + _RootTipColorBlendOffset, 
	                                                                       1.0 - _RootTipColorBlendWidth + _RootTipColorBlendOffset, 
	                                                                       percentage));


	fixed3 shadowUV0 = shadowingUV(i.wPos, 1, _ShadowProjectionMatrix0, _ShadowNormalBias0, _ShadowDistanceBias0);
	fixed3 shadowUV1 = shadowingUV(i.wPos, 1, _ShadowProjectionMatrix1, _ShadowNormalBias1, _ShadowDistanceBias1);
	half3 wHairDir = i.wHairDir;
	half3 wUp = half3(0,1,0);
	half3 wSide = normalize(cross(wHairDir, wUp));
	half3 wNormal = normalize(cross(wSide, wHairDir));


    half3   lightingResult = GenericLighting(albedo, 
                                              tNormal, 
                                              0.0,
                                              0.0,
                                              1.0,
                                              1.0,
                                              1.0,
                                              0.0,
                                              wNormal,
                                              wHairDir,
                                              wSide,
                                              i.wPos,
                                              shadowUV0,
                                              shadowUV1,
                                              i.uv,
                                              specShift,
                                              _Gloss,
                                              _SpecularScale,
                                              1.0, 1.0, 1.0, 1.0);

	fixed4 output =  float4(lightingResult, alpha);
// output.rgb = albedo.rgb;
	if (output.a < _AlphaThreshold * 0.5)
	{
		discard;
	}
	return output;
#else
	return 1;
#endif
}





#endif
