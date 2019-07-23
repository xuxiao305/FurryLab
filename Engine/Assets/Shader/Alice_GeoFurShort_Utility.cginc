#ifndef GEOFUR
#define GEOFUR


#define IMPORT_GEOFUR_UNIFORM 	
	float _Segment;
	fixed _TipScale;
	float _Length;
	
	sampler2D _DirectionTex;
	fixed _DirectionTexIntensity;
	fixed _BaseMeshVertCount;
	float _Stiffness;
	float _Turbluance;
	half _Clustering;

	sampler2D _FurIDTex; 
	fixed4 _FurIDTex_ST;
	sampler2D _FurNormalTex;
	half4 _FurNormalTex_ST;
	fixed _NormalIntensity; 
	float _FurLength;
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
	half2 spawnUV  			: TEXCOORD4;
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

[maxvertexcount(70)]
void GS_Main_GeoFur(triangle GS_INPUT p[3], inout TriangleStream<FS_INPUT> triStream)
{
	float4 vert[2];
	FS_INPUT pIn;

	half3 wMacroHairDir = 0;

	float randVal = sin(p[0].uv.y * 100 + p[0].wPos.x * 100) ;

	half3 wLookAt = normalize(_WorldSpaceCameraPos - p[0].wPos);

	half3 worldUp = half3(0.0, 1.0, 0.0);

	// Local Randomization
	fixed3x3 tangentMatrix = float3x3(p[0].wTangent.x, p[0].wBinormal.x, p[0].wNormal.x,
									  p[0].wTangent.y, p[0].wBinormal.y, p[0].wNormal.y,
									  p[0].wTangent.z, p[0].wBinormal.z, p[0].wNormal.z);

	//////////////// Create Points Along Spline ////////////////////////////


	half3 furPosWeight[20] = {half3(0.169156,0.651753,0.179092),
								half3(0.195445,0.212877,0.591677),
								half3(0.685643,0.251817,0.0625392),
								half3(0.752251,0.0410823,0.206667),
								half3(0.564867,0.234396,0.200738),
								half3(0.0410823,0.752251,0.206667),
								half3(0.331064,0.561021,0.107915),
								half3(0.0743828,0.388033,0.537584),
								half3(0.168589,0.475497,0.355914),
								half3(0.378539,0.240109,0.381353),
								half3(0.323333,0.419629,0.257038),
								half3(0.206667,0.0410823,0.752251),
								half3(0.0410823,0.206667,0.752251),
								half3(0.908843,0.0469941,0.0441634),
								half3(0.547511,0.091602,0.360887),
								half3(0.056974,0.877211,0.0658146),
								half3(0.0261094,0.636441,0.33745),
								half3(0.478274,0.432869,0.0888569),
								half3(0.0426395,0.0498169,0.907544),
								half3(0.381855,0.0797,0.538445)};

	int segments[4] = {2,5,2,4};
	// int segments[10] = {2,2,2,3,2,2,2,2,2,2};

	for (int f = 0; f < 20; f++)
	{
		furPosWeight[f] += float3(sin(p[0].wPos.x * 10.0), sin(p[2].wPos.z * 103400.0), sin(p[1].wPos.y * 52185.0)) * 0.01;

		half3 furSpawnPos = p[0].wPos.xyz * furPosWeight[f].x + p[1].wPos.xyz * furPosWeight[f].y + p[2].wPos.xyz * furPosWeight[f].z;
		half2 furSpawnUV = p[0].uv * furPosWeight[f].x + p[1].uv * furPosWeight[f].y + p[2].uv * furPosWeight[f].z;
		half3 furSpawnNormal = p[0].wNormal * furPosWeight[f].x + p[1].wNormal * furPosWeight[f].y + p[2].wNormal * furPosWeight[f].z;
		half3 furSpawnBiNormal = p[0].wBinormal * furPosWeight[f].x + p[1].wBinormal * furPosWeight[f].y + p[2].wBinormal * furPosWeight[f].z;

		half3 furDir = tex2Dlod(_DirectionTex, float4(furSpawnUV, 0.0, 0.0)) * 2.0 - 1.0;

		if (length(furDir) < 0.01 || length(furDir) > 1.0)
		{
			return;
		}

		int seg = segments[f%4];

		for(int i = 0; i < seg; i++)
		{
			
			//////////////// Create Points Along Spline ////////////////////////////
			half percentage = i / ((float)seg - 1.0);
					
			half3 lFurOffsetFromMap = furDir * percentage * _Length * 0.15 * randVal;
			half3 wFurOffsetFromMap = mul(unity_ObjectToWorld, float4(lFurOffsetFromMap, 1.0)).xyz;
			half3 wFurOffsetFromNormal = furSpawnBiNormal * length(lFurOffsetFromMap);

			half3 wFurOffset = lerp(wFurOffsetFromNormal, wFurOffsetFromMap, _DirectionTexIntensity * pow(percentage, 0.5));		

			half3 wHairDir = normalize(mul(unity_ObjectToWorld, normalize(furDir)));
			wHairDir += furSpawnNormal * (1.0 - _DirectionTexIntensity);

			half3 wSideVec = normalize(cross(wHairDir, furSpawnNormal));

			fixed curvedWidth = lerp(1.0, _TipScale, percentage * percentage) * _MaxWidth  * 0.01;
			

			//////////////// Lighting and Shadows ////////////////////////////
			for (int u = 0; u < 2; u++)
			{
				float4 wPos = float4(furSpawnPos + wFurOffset, 1.0f);

				wPos.xyz += wSideVec * u * curvedWidth;

				float4 projPos = mul(UNITY_MATRIX_VP, wPos);

				pIn.pos = projPos;
				pIn.uv = half2(u, 1.0 - percentage);

				#ifdef GEO_FUR_SHADING
					pIn.wPos = wPos.xyz;
					pIn.wHairDir = wHairDir.xyz + 0.0;
					pIn.spawnUV = furSpawnUV + 0.0;
				#endif
				triStream.Append(pIn);	
			}	
		}
		triStream.RestartStrip();
	}
}




float4 FS_Main_GeoFur(FS_INPUT i) : COLOR
{
#ifdef GEO_FUR_SHADING 
	fixed4  furColor = tex2D(_FurIDTex, i.spawnUV * _FurIDTex_ST.xy + _FurIDTex_ST.zw);
	fixed4  furNormal = tex2D(_FurNormalTex, i.uv * fixed2(_FurNormalTex_ST.x, 1.0) + fixed2(i.wPos.x, 0.0));
	half3   tNormal = furNormal.rgb * 2.0 - 1.0;
	tNormal = normalize(half3(tNormal.xy * _NormalIntensity, tNormal.z));
	fixed  specShift = (furColor.a - 0.5) * _SpecularShifting + sin(i.wPos.z * 100.0) * 0.1;

	///////////////// Albedo /////////////////
	// fixed3 tipColor = lerp(_TipColor1, _TipColor2, smoothstep(_TipColor12Blend - 0.1, _TipColor12Blend + 0.1, (hairStrandTipMask + hairStrandCurvyMask) * 0.5));
	half percentage = 1.0 - i.uv.y;
	fixed3 tipColor = lerp(_TipColor1, _TipColor2, _TipColor12Blend * 0.5 + 0.5);

	fixed3 albedo = furColor.rgb * lerp(_RootColor, tipColor, smoothstep(0.0 + _RootTipColorBlendWidth + _RootTipColorBlendOffset, 
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
                                              i.uv,
                                              specShift,
                                              _Gloss,
                                              _SpecularScale,
                                              1.0, 1.0, 1.0, 1.0);
 
	fixed4 output =  float4(lightingResult, furNormal.a);

	float alphaV = pow(output.a, 2.0);
	alphaV *= 2.0;
	
	half3 viewPos = normalize(_WorldSpaceCameraPos - i.wPos) * 2000.0;
	half frame = 100.0;
	if (_AlphaDither > 0.5)
	{
		AlphaToDitheringHiRes(viewPos, alphaV, frame,   alphaV);
	}


	clip (alphaV - _AlphaThreshold);
	// output = percentage;
	return output;
#else
	return 1;
#endif

}





#endif
