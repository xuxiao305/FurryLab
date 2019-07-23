
//********************* Lighting *************************//
half3 GenericLighting (	half3 	albedo, 
                          	half3 	tNormal, //tangent space pixel normal 
                          	half 	gloss, 
                          	half 	metallness,
                          	half 	microVisibility, 
                          	half 	ao,
                          	half 	thicknessMask,
                          	half 	multiScatteringInt,
						  	half3 	wVertexN, 	// world space vertex normal
                          	half3 	wVertexT,	// world space vertex tangent
                          	half3 	wVertexB,	// world space vertex binormal
                          	half3 	wPos,
                          	half3 	shadowUV0,
                          	half3	shadowUV1,
                          	half2 	uv,
                          	half2   tangentShift
                          	half2 	hairGloss,
                          	half2 	hairSpec)
{
	// suggested by Advance Material in WWII, I use the following function to convert gloss into roughness,
	// but somehow it will make the object looks extremetly glossy, and it only has the normal look when combine with the ACU one, 
	// which is powered by 0.25
	// half roughness = sqrt(2.0 / (1.0 + exp(gloss * 18)));

	float alphaSqr  = 2.0/(1.0 + exp(18.0 * gloss));
	half roughness = pow(alphaSqr, 0.25);	
	half3 wV = normalize(_WorldSpaceCameraPos - wPos);
	half flipped    = step(0.0, ddx(uv.x));
	half3 wB = wVertexB* lerp(1.0, -1.0, flipped);
	half3 wT = wVertexT ;

	half3x3 tangentMatrix = half3x3(wT.x, wB.x, wVertexN.x,
	                                wT.y, wB.y, wVertexN.y,
	                                wT.z, wB.z, wVertexN.z);

	half3 wN = mul(tangentMatrix, tNormal);
	half3 wVr = normalize(reflect(wV, wN));

	#ifdef HAIR_SHDING
		half3 wT1 = normalize(wVertexB + tangentShift.x * wN);	
		half3 wT2 = normalize(wVertexB + tangentShift.y * wN); 
	#endif

	half  NdotV = saturate(dot(wN, wV));
	half3 wReflectDir = -reflect(wV, wN);

	fixed3 F0 = lerp(0.04, albedo, metallness);

	
	///////////////////////// IBL ////////////////////////////////////
	half3 ambientDiffuseLighting = ShadeSH9(float4(rotate(wN, _EnvRotation), 1)).xyz;
	half3 ambientTranslucentLighting = ShadeSH9(float4(-rotate(wN, _EnvRotation), 1)).xyz * (1.0 - thicknessMask); 
	half3 ambientSpecularLighting = computeIBL(_ReflectProbeTex, 
	                                           _EnvRotation, 
	                                           wN, 
	                                           wV, 
	                                           F0, 
	                                           roughness) * microVisibility;

	//////////////// Lighting and Shadows ////////////////////////////


    half3   	startPos[2]    			= {_TubeLightPosStart0, _TubeLightPosStart1};
    half3   	endPos[2] 				= {_TubeLightPosEnd0,_TubeLightPosEnd1};
	half3 		shadowUVs[2] 			= {shadowUV0, shadowUV1};
	float4x4 	shadowMatrix[2] 		= {_ShadowProjectionMatrix0, _ShadowProjectionMatrix1};
	sampler2D 	shadowmapSampler[2] 	= {_Shadowmap0, _Shadowmap1};
	half3 		lightDirection[2] 		= {_DirLightFwd0, _DirLightFwd1};
	half3 		lightPos[2]				= {_DirLightPos0, _DirLightPos1};
	half4 		dirLightColorIntensity[2] 	= {_DirLightColorIntensity0, _DirLightColorIntensity1};
	fixed 		shadowMapSize[2] 			= {_ShadowmapSize0, _ShadowmapSize1};
	half 		distanceFalloffs[2] 		= {_DistanceFalloff0, _DistanceFalloff1};
	half 		coneFalloffStart[2] 		= {_ConeFalloffStart0, _ConeFalloffStart1};
	half 		coneFalloffEnd[2] 			= {_ConeFalloffEnd0, _ConeFalloffEnd1};
	 
	int 		lightTypes[2] 			= {_LightType0, _LightType1};

	half3 		directionalDiffuseLighting 	= 0;
	half3 		translucencyLighting 		= 0;
	half3 		specularLighting 			= zero3;
	half 		shadow 					= 1.0;

	half 		finalAO = ao;

	half 		thickness = 0.0;


	for (int i = 0; i < 1; i++)	
	{
		half3 wDiffuseLightDir;
		half3 wSpecLightDir;
		half diffuseIrradiance = 1.0;
		half irradiance = 1.0;

		if (lightTypes[i] == 0)
		{
			wDiffuseLightDir = lightDirection[i];
			wSpecLightDir = lightDirection[i];
			DirectionalLightIrradiance(wPos, lightDirection[i], lightPos[i], coneFalloffStart[i], coneFalloffEnd[i], distanceFalloffs[i],
			                                        irradiance);
			diffuseIrradiance = irradiance;
		}
		else if (lightTypes[i] == 1)
		{
	    	
			LineLight(wPos, wN, wN, startPos[i], endPos[i],  distanceFalloffs[i], wDiffuseLightDir, diffuseIrradiance);
			LineLight(wPos, wVr, wN, startPos[i], endPos[i],  distanceFalloffs[i], wSpecLightDir, irradiance);
		}



		half3 	wH = normalize(wSpecLightDir + wV);
		half 	NdotL = saturate(dot(wN, wDiffuseLightDir));
		
		half 	NdotH = dot(wN, wH);
		half 	VdotH = saturate(dot(wV, wH));

		half3 	lightColor =  dirLightColorIntensity[i].xyz * dirLightColorIntensity[i].w;




		#ifdef GENERIC_PBR_SHADING

				half3 	specGGX = GGXSpecularLighting(F0, NdotL, NdotV, saturate(NdotH), VdotH, roughness) * lightColor;// * microVisibility * shadow;  
				half3 	specRetro = RetroSpecLighting(NdotH, VdotH, NdotL, NdotV, gloss) * lightColor * lerp(1.0, albedo, _RetroTint);
						specularLighting += lerp(specGGX, specRetro, _Retro) * irradiance;
						directionalDiffuseLighting += LambertDiffuseLighting(wN, wDiffuseLightDir) * lightColor * diffuseIrradiance;

				#define MAT_ID 0.0

		#endif 

		#ifdef HAIR_SHDING
				half  	HdotT1 = dot(wH, wT1);
				half  	HdotT2 = dot(wH, wT2);
				half3 	kkLobe1 = KajiyaKayShading(HdotT1, hairGloss.x, hairSpec.x);
				half3 	kkLobe2 = KajiyaKayShading(HdotT2, hairGloss.y, hairSpec.y) * albedo;

						specularLighting += (kkLobe1 + kkLobe2) * lightColor;
						directionalDiffuseLighting = 0.0;

						#define MAT_ID 0.0
		#endif

		#ifdef FUR_SHADING
					  	specularLighting += KajiyaKayShading(HdotT, hairGloss.x, _SpecularScale.x) * lightColor;
					  	directionalDiffuseLighting = 0.0;
						
						#define MAT_ID 0.3
		#endif

		#ifdef GEO_FUR_SHADING
					  	specularLighting += KajiyaKayShading(HdotT, hairGloss.x, _SpecularScale.x) * lightColor;
					  	directionalDiffuseLighting = 0.0;
						#define MAT_ID 0.1  

		#endif 

		half2 	shadowAndThickness = PCF(shadowmapSampler[i], shadowUVs[i], 3, shadowMapSize[i], _ShadowDepthFalloff, MAT_ID);

				shadow = min(shadow, shadowAndThickness.x);

				thickness = max(thickness, shadowAndThickness.y);

	// a terrible hack to generate the sky visibility...
	half skyVis = pow(lerp(0.1, 1.0, saturate(dot(wN, half3(0,1,0)))), 0.45); 
	return (ambientDiffuseLighting + ambientSpecularLighting) * skyVis + specularLighting * shadow * ao;
		translucencyLighting += _Translucency * TranslucencyLighting(wDiffuseLightDir, wV, wN, thickness, dirLightColorIntensity[i]) * lightColor * albedo;

	}

	// a terrible hack to generate the sky visibility...
	half 	skyVis = smoothstep(0.0, 1.0, dot(wN, half3(0,1,0))*0.5+0.5); 
			finalAO = min(finalAO, skyVis);

	half3 	output = (directionalDiffuseLighting * finalAO * shadow + 
	              	0 * finalAO) *  albedo + 
					specularLighting * shadow * finalAO + 0 * finalAO;
	

	return output;
}










/////////////////////// the old one!

//********************* Lighting *************************//
half3 GenericPBRLighting (	half3 	albedo, 
                          	half3 	tNormal, //tangent space pixel normal 
                          	half3 	gloss, 
                          	half 	metallness,
                          	half 	microVisibility, 
                          	half 	ao,
                          	half 	thicknessMask,
                          	half 	multiScatteringInt,
						  	half3 	wVertexN, 	// world space vertex normal
                          	half3 	wVertexT,	// world space vertex tangent
                          	half3 	wVertexB,	// world space vertex binormal
                          	half3 	wPos,
                          	half3 	shadowUV0,
                          	half3	shadowUV1,
                          	half2 	uv)
{
	// suggested by Advance Material in WWII, I use the following function to convert gloss into roughness,
	// but somehow it will make the object looks extremetly glossy, and it only has the normal look when combine with the ACU one, 
	// which is powered by 0.25
	// half roughness = sqrt(2.0 / (1.0 + exp(gloss * 18)));

	float alphaSqr  = 2.0/(1.0 + exp(18.0 * gloss));
	half roughness = pow(alphaSqr, 0.25);	
	half3 wV = normalize(_WorldSpaceCameraPos - wPos);
	half flipped    = step(0.0, ddx(uv.x));
	half3 wB = wVertexB* lerp(1.0, -1.0, flipped);
	half3 wT = wVertexT ;

	half3x3 tangentMatrix = half3x3(wT.x, wB.x, wVertexN.x,
	                                wT.y, wB.y, wVertexN.y,
	                                wT.z, wB.z, wVertexN.z);

	half3 wN = mul(tangentMatrix, tNormal);


	half  NdotV = saturate(dot(wN, wV));
	half3 wReflectDir = -reflect(wV, wN);

	fixed3 F0 = lerp(0.04, albedo, metallness);

	
	///////////////////////// IBL ////////////////////////////////////
	half3 ambientDiffuseLighting = ShadeSH9(float4(rotate(wN, _EnvRotation), 1)).xyz;
	half3 ambientTranslucentLighting = ShadeSH9(float4(-rotate(wN, _EnvRotation), 1)).xyz * (1.0 - thicknessMask); 
	half3 ambientSpecularLighting = computeIBL(_ReflectProbeTex, 
	                                           _EnvRotation, 
	                                           wN, 
	                                           wV, 
	                                           F0, 
	                                           roughness) * microVisibility;

	//////////////// Lighting and Shadows ////////////////////////////


    half3   startPos[2]    = {_TubeLightPosStart0, _TubeLightPosStart1};
    half3   endPos[2] 		= {_TubeLightPosEnd0,_TubeLightPosEnd1};
	half3 	shadowUVs[2] 			= {shadowUV0, shadowUV1};
	float4x4 shadowMatrix[2] 	= {_ShadowProjectionMatrix0, _ShadowProjectionMatrix1};
	sampler2D shadowmapSampler[2] 	= {_Shadowmap0, _Shadowmap1};
	half3 lightDirection[2] 		= {_DirLightFwd0, _DirLightFwd1};
	half3 lightPos[2]				= {_DirLightPos0, _DirLightPos1};
	half4 dirLightColorIntensity[2] = {_DirLightColorIntensity0, _DirLightColorIntensity1};
	fixed shadowMapSize[2] 			= {_ShadowmapSize0, _ShadowmapSize1};
	half distanceFalloffs[2] = {_DistanceFalloff0, _DistanceFalloff1};
	half coneFalloffStart[2] = {_ConeFalloffStart0, _ConeFalloffStart1};
	half coneFalloffEnd[2] = {_ConeFalloffEnd0, _ConeFalloffEnd1};
	 
	int lightTypes[2] = {_LightType0, _LightType1};

	half3 directionalDiffuseLighting = 0;
	half3 translucencyLighting = 0;
	half3 specularLighting = zero3;
	half shadow = 1;

	half finalAO = pow(ao, 1.0);

	half thickness = 0.0;

	half3 wVr = normalize(reflect(wV, wN));

	for (int i = 0; i < 1; i++)	
	{
		half3 wDiffuseLightDir;
		half3 wSpecLightDir;
		half diffuseIrradiance = 1.0;
		half irradiance = 1.0;

		if (lightTypes[i] == 0)
		{
			wDiffuseLightDir = lightDirection[i];
			wSpecLightDir = lightDirection[i];
			DirectionalLightIrradiance(wPos, lightDirection[i], lightPos[i], coneFalloffStart[i], coneFalloffEnd[i], distanceFalloffs[i],
			                                        irradiance);
			diffuseIrradiance = irradiance;
		}
		else if (lightTypes[i] == 1)
		{
	    	
			LineLight(wPos, wN, wN, startPos[i], endPos[i],  distanceFalloffs[i], wDiffuseLightDir, diffuseIrradiance);
			LineLight(wPos, wVr, wN, startPos[i], endPos[i],  distanceFalloffs[i], wSpecLightDir, irradiance);
		}



		half3 wH = normalize(wSpecLightDir + wV);
		half NdotL = saturate(dot(wN, wDiffuseLightDir));
		
		half NdotH = dot(wN, wH);
		half VdotH = saturate(dot(wV, wH));

		half3 lightColor =  dirLightColorIntensity[i].xyz * dirLightColorIntensity[i].w;

		fixed2 shadowAndThickness = PCF(shadowmapSampler[i], shadowUVs[i], 3, shadowMapSize[i], _ShadowDepthFalloff, 0.0);

		shadow = min(shadow, shadowAndThickness.x);

		thickness = max(thickness, shadowAndThickness.y);

		half3 specGGX = GGXSpecularLighting(F0, NdotL, NdotV, saturate(NdotH), VdotH, roughness) * lightColor;// * microVisibility * shadow;  
		half3 specRetro = RetroSpecLighting(NdotH, VdotH, NdotL, NdotV, gloss) * lightColor * lerp(1.0, albedo, _RetroTint);

		specularLighting += lerp(specGGX, specRetro, _Retro) * irradiance;
		directionalDiffuseLighting += LambertDiffuseLighting(wN, wDiffuseLightDir) * lightColor * diffuseIrradiance;
		translucencyLighting += _Translucency * TranslucencyLighting(wDiffuseLightDir, wV, wN, thickness, dirLightColorIntensity[i]) * lightColor * albedo;

	}

	// a terrible hack to generate the sky visibility...
	half 	skyVis = smoothstep(0.0, 1.0, dot(wN, half3(0,1,0))*0.5+0.5); 
			finalAO = min(finalAO, skyVis);

	half3 	output = (directionalDiffuseLighting * finalAO * shadow + 
	              	0 * finalAO) *  albedo + 
					specularLighting * shadow * finalAO + 0 * finalAO;
	

	return output;
}


half3 KKBasedHairLighting(half3 albedo,
                   			half3 tNormal,
                   			half3 tBentNormal,
                   			half  gloss1,
                   			half  gloss2,
                   			half  specScale1,
                   			half  specScale2,
                   			half  tangentShift1,
                   			half  tangentShift2,
                   			half  ao, 
                   			half  thickness,
                   			half3 wVertexN,
                   			half3 wVertexT,
                   			half3 wVertexB,
                   			half  wPos,
                   			half3 shadowUV0,
                   			half3 shadowUV1 )
{


	half3x3 tangentMatrix = half3x3(wVertexT.x, wVertexB.x, wVertexN.x,
	                                wVertexT.y, wVertexB.y, wVertexN.y,
	                                wVertexT.z, wVertexB.z, wVertexN.z);

	half3 wN = mul(tangentMatrix, tNormal);
	half3 wBentN = mul(tangentMatrix, tBentNormal);


	// somehow, using the bent normal is not working as i wanted... should keep it zero for now
		  wN = lerp(wN,wBentN, _UseBentNormal * (1.0- ao));

	half3 wB = wVertexB;
	half3 wT = wVertexT;
	half3 F0 = 0.04;

	float alphaSqr  = 2.0/(1.0 + exp(18.0 * (gloss1 * 0.5 + gloss2 * 0.5)));
	half roughness = pow(alphaSqr, 0.25);	

	half multiScattering = 0.0;

	half3 wT1 = normalize(wVertexB + tangentShift1 * wN);	
	half3 wT2 = normalize(wVertexB + tangentShift2 * wN); 

	half3 wV = normalize(_WorldSpaceCameraPos - wPos);

	///////////////////////// IBL ////////////////////////////////////
	half3 ambientDiffuseLighting = ShadeSH9(float4(rotate(wN, _EnvRotation), 1)).xyz * albedo * ao;
	half3 ambientTranslucentLighting = ShadeSH9(float4(-rotate(wN, _EnvRotation), 1)).xyz * (1.0 - thickness); 
	half3 ambientSpecularLighting = computeIBL(_ReflectProbeTex, 
	                                           _EnvRotation, 
	                                           wN, 
	                                           wV, 
	                                           0.04, 
	                                           roughness) * ao * ao;


	//////////////// Lighting and Shadows ////////////////////////////
	half3 shadowUVs[2] 			= {shadowUV0, shadowUV1};
	float4x4 shadowMatrix[2] 	= {_ShadowProjectionMatrix0, _ShadowProjectionMatrix1};
	sampler2D shadowmapSampler[2] 	= {_Shadowmap0, _Shadowmap1};
	half3 lightDirection[2] 		= {_DirLightFwd0, _DirLightFwd1};
	half4 dirLightColorIntensity[2] = {_DirLightColorIntensity0, _DirLightColorIntensity1};
	fixed shadowMapSize[2] 			= {_ShadowmapSize0, _ShadowmapSize1};

	half3 directionalDiffuseLighting = 0;
	half3 translucencyLighting = 0;
	half3 specularLighting = zero3;
	half shadow = 1;

	half finalAO = 1.0;


	for (int i = 0; i < 1; i++)	
	{

		half3 	lightColor =  dirLightColorIntensity[i].xyz * dirLightColorIntensity[i].w;

		half3 	wL = lightDirection[i];
		half3 	wH = normalize(wL + wV);
		half 	NdotL = saturate(dot(wN, wL));
		
		half 	NdotH = dot(wN, wH);
		half 	VdotH = saturate(dot(wV, wH));

		half  	HdotT1 = dot(wH, wT1);
		half  	HdotT2 = dot(wH, wT2);
		half3 	kkLobe1 = KajiyaKayShading(HdotT1, gloss1, specScale1);
		half3 	kkLobe2 = KajiyaKayShading(HdotT2, gloss2, specScale2) * albedo;

				specularLighting += (kkLobe1 + kkLobe2) * lightColor;

		fixed2 	shadowAndThickness = PCF(shadowmapSampler[i], shadowUVs[i], 3, shadowMapSize[i], _ShadowDepthFalloff, 0.3);

				shadow = min(shadow, shadowAndThickness.x);

				thickness = max(thickness, shadowAndThickness.y);

				translucencyLighting += _Translucency * TranslucencyLighting(wL, wV, wN, thickness, dirLightColorIntensity[i]) * lightColor * albedo;
	}

	// a terrible hack to generate the sky visibility...
	half skyVis = pow(lerp(0.1, 1.0, saturate(dot(wN, half3(0,1,0)))), 0.45); 
	return (ambientDiffuseLighting + ambientSpecularLighting) * skyVis + specularLighting * shadow * ao;
	
}

