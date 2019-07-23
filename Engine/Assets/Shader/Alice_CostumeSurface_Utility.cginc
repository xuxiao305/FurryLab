#ifndef COSTUME_SURFACE
#define COSTUME_SURFACE

#define one2 1.0
#define one3 1.0
#define one4 1.0
#define zero2 0.0
#define zero3 0.0
#define zero4 0.0

float4 DecompressNormal(float4 normalFromTexture)
{
    float4 tempNormal = normalFromTexture;
    tempNormal.y = 1.0 - tempNormal.y;
    tempNormal.xy = tempNormal.xy * 2.0 - 1.0;
    tempNormal.z = sqrt(saturate(1.0f - (tempNormal.x*tempNormal.x + tempNormal.y*tempNormal.y)));
    return tempNormal;
}


float4 BumpToNormal(float3 bumpMap, float intensity )
{
	float3 bumpness = bumpMap * intensity;	
	float3 gradient = float3((bumpness.rr - bumpness.gb)*0.5+0.5, 1.0);

	float4 normalFromGrad = DecompressNormal(float4(gradient, 1.0));
	normalFromGrad.y *= -1;
	normalFromGrad.xyz = normalize(float3(normalFromGrad.xy, normalFromGrad.z));

	return normalFromGrad;
}


void SubstanceSample_FourHeights(sampler2D smp, float4 uv, 
								out float3 heightOut1, out float3 heightOut2, 
								out float3 heightOut3, out float3 heightOut4)
{	

	float2	size 	= float2(1024, 1024);

	float2 	offset 	= float2(float(size.x), float(size.y));

	float4 	su = float4(1.0/offset.x,   0.0, 		0.0, 0.0); // 1 / width
	float4 	sv = float4(0.0, 	  	1.0/offset.y, 	0.0, 0.0); // 1 / height  

    float4  smpResult1 = tex2D(smp, uv.xy);
    float4  smpResult2 = tex2D(smp, uv.xy + su.xy );
    float4  smpResult3 = tex2D(smp, uv.xy + sv.xy );


    		heightOut1 = float3(smpResult1.x, smpResult2.x, smpResult3.x);
 	  		heightOut2 = float3(smpResult1.y, smpResult2.y, smpResult3.y);
      		heightOut3 = float3(smpResult1.z, smpResult2.z, smpResult3.z);
    	  	heightOut4 = float3(smpResult1.w, smpResult2.w, smpResult3.w);
       
}


void ProcessWeatheringMap(float4 uv, 
								float bleachInt,
								float tearingInt, 
								float patinaInt,
								out float bleachOut, 
								out float patinaOut, 
								out float tearingOcclusionOut, 
								out float3 tearingHeightOut, 
								out float tearingMaskOut,
								out float tearingBleachOut,
								out float tearAlphaOut,
								out float permenantAlphaOut,
								out float3 permenantAlphaHeightOut,
								out float permenantAlphaOcclusionOut)
{
	// offset by 1 pixel 
	// I am using size from _PatinaMaskTex, which is the same size as the rest weatheringmap, as they will be packed when export
	float2 onePixelSize = 1.0 / 1024.0;// _PatinaMaskTex.size.zw;

	float4 	su = float4(onePixelSize.x, 0.0, 			0.0, 0.0); // 1 / width
	float4 	sv = float4(0.0, 			onePixelSize.y, 0.0, 0.0); // 1 / height

    float4  tearingMap0 			= tex2D(_TearingMaskTex, uv.xy);
    float4  tearingMap1 			= tex2D(_TearingMaskTex, uv.xy + su.xy);
    float4  tearingMap2 			= tex2D(_TearingMaskTex, uv.xy + sv.xy);

    float4  wearyingMap = tex2D(_WearyingMaskTex, uv.xy);
     		bleachOut 				= lerp(1.0, wearyingMap.r, bleachInt);
    		patinaOut 				= lerp(1.0, wearyingMap.g, patinaInt); 

			tearingHeightOut 	= float3(tearingMap0.a, tearingMap1.a, tearingMap2.a);
			
            // tearingMaskOut 		= lerp(1.0, tearingMap0.a, tearingInt);
            tearingMaskOut      = smoothstep(tearingInt - 0.5, tearingInt, tearingMap0.a);

			tearingOcclusionOut = lerp(1.0, tearingMap0.b, tearingInt);
	 		tearingBleachOut 	= lerp(1.0,  saturate(tearingMap0.a  * 2.0), tearingInt);

            tearAlphaOut   		= saturate(tearingMaskOut * 2.0);

       		permenantAlphaOut 	= saturate(tearingMap0.r * 7.0);
     		permenantAlphaHeightOut = float3(tearingMap0.r, tearingMap1.r, tearingMap2.r);

            permenantAlphaOcclusionOut = tearingMap0.r;
}



float4 UVDistortion(float tearingMask, float distortionInt)
{
	float4 distortionOut = float4(0.0, 0.006 * (1.0 - tearingMask), 0.0, 0.0)  * distortionInt;

	return distortionOut;
}


float Height2Curvature(float height, float a, float b)
{
	return saturate(smoothstep(a, b, height));
}

half4 CombineDetailNormal(float3 baseNormal, float3 detailNormal)
{
    float3 t     = baseNormal;
           t.z   = t.z + 1.0f;
    float3 u     = detailNormal;
           u.xy *= -1.0f;
    return half4(t * dot(t, u) / t.z - u, 1);
}		

float4 CHR_FlipBook3(float4 AtlasDim, float Index, float4 UV)
{
    // AtlasDim.x and .y should be specified to give number of sub images U and V directions
    // Index 0 is at top left of image and can go up to (AtlasDim.x * AtlasDim.y - 1)

    float fIndex = floor(Index);
    float indexY = AtlasDim.y - floor(fIndex / AtlasDim.x) - 1;
    float indexX = fIndex - indexY * AtlasDim.x;
    float4 indices = {indexX, indexY, 0, 0};
        
    float4 paramOut = 0.0;
    paramOut.xy = (frac(UV.xy) + indices.xy) / AtlasDim.xy;

    return frac(paramOut);
}


float3 SelectVector3(float index,	float3 v0, float3 v1, float3 v2, float3 v3)
{
    float3 vectorList[4] = {v0, v1, v2, v3};

	float3 vectorOut = vectorList[int(index) % 4];

	return vectorOut;
}


void PatternIDs(float _int, 
                float3 _channels, 
                sampler2D _patternMaskTex, 
                float _weaveTiling, 
                float2 _baseUVOffset,
                float2 _patternUV, 
                float2 _uvRatio, 
                float _weatherUVDistortion,
                float4 _patternIDMask,
                float4 _pattern_ST,
                float _tearingMask,
                float4 _patternColor1,
                float4 _patternColor2,
                float4 _patternColor3,
                out float3 _patternTintingMask,
                out float4 _patternColor,
                out float3 _patternHeightR,
                out float3 _patternHeightG,
                out float3 _patternHeightB,
                out float _patternCurvature)
{
    _patternTintingMask = zero3;
    _patternColor = zero4;
    _patternHeightR = zero3;
    _patternHeightG = zero3;
    _patternHeightB = zero3;    

    float4  patternUV = float4(_patternUV.xy * _pattern_ST.xy * _uvRatio + 
                            float2(0.0, _weatherUVDistortion) / _weaveTiling + 
                            _pattern_ST.zw, 1.0, 1.0);

    float4  patternMap0 = tex2D(_patternMaskTex, patternUV.xy);
    float4  patternMap1 = tex2D(_patternMaskTex, patternUV.xy + float2(_baseUVOffset.x, 0.0));
    float4  patternMap2 = tex2D(_patternMaskTex, patternUV.xy + float2(0.0, _baseUVOffset.y));

    float   patternChannel = _patternIDMask.r * float(_channels.r) + 
                                _patternIDMask.g * float(_channels.g) +
                                _patternIDMask.b * float(_channels.b);

    float3  useAll   = patternMap0.rgb;
    float3  useROnly = float3(patternMap0.r, 0.0, 0.0);
    float3  useGOnly = float3(0.0, patternMap0.g, 0.0);
    float3  useBOnly = float3(0.0, 0.0, patternMap0.b);

    float   tearFallloff = saturate(_tearingMask - 0.3);
    float   patternIDlevel = dot(_patternIDMask.rgb, one3) * tearFallloff;

            _patternTintingMask = SelectVector3(patternChannel, useAll, useROnly, useGOnly, useBOnly) * patternIDlevel * _int;

            _patternHeightR = float3(patternMap0.r, patternMap1.r, patternMap2.r) * patternIDlevel;
            _patternHeightG = float3(patternMap0.g, patternMap1.g, patternMap2.g) * patternIDlevel;
            _patternHeightB = float3(patternMap0.b, patternMap1.b, patternMap2.b) * patternIDlevel;
    
            _patternColor = patternMap0;
            _patternCurvature = lerp(0.5, patternMap0.a, tearFallloff);
}


void CHR_BlendFabricUpdate(
    float4 _UV0,                         //< display_name: UV0>
    float4 _UV1,						 //< display_name: UV1>
    float  _WeaveIndex,                  //< display_name: Weaves Index>
    float _WeaveTiling,				 	 //< display_name: Weaves Tiling>
    float _WeaveHeight,				 //< display_name: Weave Normal Int>
    float _C_Gloss,			     //< display_name: Weave Gloss Int>
	float4 _FabricColorH,				 //< display_name: Fabric Color H>
	float4 _FabricColorV,				 //< display_name: Fabric Color V>
	float4 _FabricColorPatina,			 //< display_name: Fabric Color Patina>
	float4 _BleachColor, 				 //< display_name: Bleach Color>
    
    float  _PatternInt,                   	//< display_name: Pattern Intensity>
    float4 _C_PatternColor1,                //< display_name: Pattern Color 1>
    float4 _C_PatternColor2,                //< display_name: Pattern Color 2> 
    float4 _C_PatternColor3,                //< display_name: Pattern Color 3> 
    float4 _C_Pattern_ST,          //< display_name: Pattern Translation X>
    float _C_PatternMetalness,            //< display_name: Pattern Metalness>
    float _C_PatternDirection,                  //< display_name: Pattern Direction>
    float _C_PatternHeight,          //< display_name: Pattern Height>


	float  _BumpSharpness,				 //< display_name: Bump Sharpness>
	float  _C_WearyDistortion,			 //< display_name: Weary Distortion X>
	float _C_Retro,

    out float _GlossOut,               //< display_name: Gloss>
    out float _TransOut,             //< display_name: Translucency Out> 
    out float _RetroOut,               //< display_name: Retro>
    out float _MetalnessOut,           //< display_name: Metalness>
    out float _AmbOccOut,
    out float _SpecOccOut,   //< display_name: SpecularOcclusion>
    out float4 _NormalOut,              //< display_name: Normal>
    out float4 _HeightOut,
    out float4 _AlbedoOut,              //< display_name: Albedo>
    out float _AlphaOut               //< display_name: Alpha>  

    )
{
	// ====================================================
    // Initialize Fabric Output =======================
    // ================================================
    _GlossOut = 0.0;
    _RetroOut = 1.0;
    _MetalnessOut = 0.0;
    _SpecOccOut = 1.0;
    _AmbOccOut = 1.0;
    _NormalOut = float4(0.0, 0.0, 1.0, 1.0);
    _HeightOut = one4;
    _AlbedoOut = float4(1.0, 1.0, 1.0, 1.0);
    _AlphaOut = 1.0;
    _TransOut = 0.0;

    float4 FlatNormal = float4(0.0, 0.0, 1.0, 0.0);
	float4  size = float4(4.0, 4.0, 0.0, 0.0); 
	float3 heightAll = zero3;
	half _UVRatio = 1.0;
	float2 uvRatio = float2(1.0/_UVRatio, _UVRatio);

    // ====================================================
    // Sample Fabric Textures =============================
    // ====================================================
    float4  baseColor = tex2D(_BaseColorTex, _UV0.xy);
            _AlbedoOut.rgb *= baseColor.rgb;
            _AmbOccOut *= baseColor.a;

    float4  normalGlossMap = tex2D(_NormalGlossTex, _UV0.xy);
            _GlossOut = normalGlossMap.a;
            _NormalOut = float4(normalGlossMap.rgb * 2.0 - 1.0, 1.0);

    float4  detailDamageMapUV = float4(_UV0.xy * _C_DamageDetailTiling * uvRatio, 1.0, 1.0);

    float   bleachMask 				= 1.0; 		float 	tearingOcclusionMask = 1.0; 		float patinaMask = 1.0; 
    float3 	tearingHeight 			= zero3; 	float 	tearingMask = 1.0;					float tearingBleachMask = 1.0;
    float3  detailPatinaHeight1 	= zero3; 	float3 	detailTearHeight = zero3;  	
    float3  weaveHeightComp 		= zero3; 	float3 	weaveHeightTear = zero3; 	
    float3 	weaveTintingMask 		= zero3; 	float3  weaveTintingMaskTear = zero3;
    float3 	weaveHeightPattern 		= zero3;	float3  weaveHeightPattern2 = zero3;
    float   permenantAlpha 			= 1.0;		float3  permenantAlphaHeight = zero3;     float   permenantAlphaOcclusion = 1.0; 
    float   tearAlpha 				= 1.0;

    		ProcessWeatheringMap(_UV0, _BleachInt, _TearingInt, _PatinaInt, 
    										bleachMask, patinaMask, tearingOcclusionMask, tearingHeight, tearingMask, tearingBleachMask,
    										tearAlpha, permenantAlpha, permenantAlphaHeight, permenantAlphaOcclusion);
  
    float4  weatherUVDistortion = UVDistortion(tearingMask, _C_WearyDistortion);
 			weatherUVDistortion.y = pow(abs(tearingHeight.x - 0.5) * 2.0, 2.0) * 0.1  * _TearingInt; 
            detailDamageMapUV.xy += weatherUVDistortion.xy * _C_WearyDistortion;

            SubstanceSample_FourHeights(_C_DetailDamageTex, detailDamageMapUV, 
            								detailPatinaHeight1, detailTearHeight, weaveHeightPattern, weaveHeightPattern2);

            

    float4  compMapUV = float4((_UV0.xy) * _WeaveTiling * uvRatio, 1.0, 1.0);
            compMapUV.xy += weatherUVDistortion.xy * detailTearHeight.x * _C_WearyDistortion * 4.0;
            compMapUV = CHR_FlipBook3(size, _WeaveIndex, compMapUV);


            SubstanceSample_FourHeights(_C_DetailMapCompositionTex, compMapUV,
            								weaveHeightComp, weaveHeightTear, weaveTintingMask, weaveTintingMaskTear);
    

    float 	weaveTintingMaskFinal = lerp(weaveTintingMaskTear.r, weaveTintingMask.r, tearingMask);
    float   weaveCompIDH = 1.0 - saturate(weaveTintingMaskFinal * 2.0);
    float   weaveCompIDV = saturate(weaveTintingMaskFinal - 0.5) * 2.0;  

    float   weavePatternID = saturate(weaveHeightPattern.r * weaveHeightPattern.r * 2.0);        

            _GlossOut *= _C_Gloss;

    float3  depthHeight = lerp(weaveHeightTear, weaveHeightComp, tearingMask);
    float 	detailDepth = depthHeight.r;
    float   detailAO = lerp(1.0, detailDepth, _DetailShadowing);


    // Fabric Pattern ====================================================
    float3  patternTintingMask = zero3;
    float4  patternColor = zero4;
    float3  patternHeightR = zero3;
    float3  patternHeightG = zero3;
    float3  patternHeightB = zero3;
    float3  patternHeightMask = zero3;
    float 	patternCurvature = 0.0;

    // PatternIDs(_PatternInt, _C_PatternChannel.xyz, _C_PatternMaskTex, _WeaveTiling, float2(1.0/1024, 1.0/1024), _UV1.xy, 
    //             uvRatio, _C_WearyDistortion, _IDPatternMaskRGB, 
    //             _C_Pattern_ST,
    //             tearingMask, _C_PatternColor1, _C_PatternColor2, _C_PatternColor3, patternTintingMask, 
    //             patternColor, patternHeightR, patternHeightG, patternHeightB, patternCurvature);

    // float3  patternDirH = (one3 - saturate(_C_PatternDirection.xyz)) * patternTintingMask.rgb;   // patternDirH = 1 when _C_PatternDirection = -1   
    // float3  patternDirV = (one3 - saturate(-_C_PatternDirection.xyz)) * patternTintingMask.rgb;     // patternDirV = 1 when _C_PatternDirection = 1

    // float3  patternHeightsInt = float3(_C_PatternHeight.x, _C_PatternHeight.y, _C_PatternHeight.z) * _PatternInt * max(patternDirH, patternDirV);

    //         patternHeightMask = saturate(patternHeightsInt * weaveHeightPattern * saturate(patternColor.rgb * 2.0));

    //         patternHeightR = (patternHeightR + lerp(weaveHeightPattern, weaveHeightPattern2, patternColor.a)) * 20.0;
    //         patternHeightB = (patternHeightB + lerp(weaveHeightPattern, weaveHeightPattern2, patternColor.a)) * 20.0;
    //         patternHeightG = (patternHeightG + lerp(weaveHeightPattern, weaveHeightPattern2, patternColor.a)) * 20.0;

    // float3  patternMapMetal = _C_PatternMetalness.xyz * patternTintingMask.xyz;

    // float3  patternMetalnessH = patternMapMetal * lerp(patternDirH.xyz * weaveCompIDH, weavePatternID * one3, patternHeightMask);
    // float3  patternMetalnessV = patternMapMetal * lerp(patternDirV.xyz * weaveCompIDV, weavePatternID * one3, patternHeightMask);

    // float   patternMetal = patternMetalnessH.x + patternMetalnessH.y + patternMetalnessH.z + 
    //                             patternMetalnessV.x + patternMetalnessV.y + patternMetalnessV.z;    

    //         _MetalnessOut = saturate(_MetalnessOut + patternMetal * _PatternInt);
    // float   patternMapGloss = _MetalnessOut * _MetalnessOut;

    //         _GlossOut = lerp(_GlossOut, 0.8, patternMapGloss * tearingMask);

    float3  fabricColorH = _FabricColorH.rgb;
    float3  fabricColorV = _FabricColorV.rgb;
            
    //         fabricColorH = lerp(fabricColorH.rgb, _C_PatternColor1.rgb, _C_PatternColor1.a * patternDirH.x);
    //         fabricColorH = lerp(fabricColorH.rgb, _C_PatternColor2.rgb, _C_PatternColor2.a * patternDirH.y);
    //         fabricColorH = lerp(fabricColorH.rgb, _C_PatternColor3.rgb, _C_PatternColor3.a * patternDirH.z);
    
    //         fabricColorV = lerp(fabricColorV.rgb, _C_PatternColor1.rgb, _C_PatternColor1.a * patternDirV.x);
    //         fabricColorV = lerp(fabricColorV.rgb, _C_PatternColor2.rgb, _C_PatternColor2.a * patternDirV.y);
    //         fabricColorV = lerp(fabricColorV.rgb, _C_PatternColor3.rgb, _C_PatternColor3.a * patternDirV.z);


    float3  fabricColorHV = weaveCompIDH * fabricColorH + weaveCompIDV * fabricColorV;
            _AlbedoOut.rgb *= fabricColorHV;
            
            _AlbedoOut.rgb = lerp(_AlbedoOut.rgb, _C_PatternColor1.rgb, _C_PatternColor1.a * patternHeightMask.x);
            _AlbedoOut.rgb = lerp(_AlbedoOut.rgb, _C_PatternColor2.rgb, _C_PatternColor2.a * patternHeightMask.y);
            _AlbedoOut.rgb = lerp(_AlbedoOut.rgb, _C_PatternColor3.rgb, _C_PatternColor3.a * patternHeightMask.z);

    // Fabric Patina =================================
     		_AlbedoOut.rgb = lerp(_AlbedoOut.rgb, _FabricColorPatina.rgb, _FabricColorPatina.a * (1.0 - patinaMask));
            detailDepth    = min(detailDepth, lerp(detailPatinaHeight1.x, 1.0, patinaMask));

    // Fabric Bleach =================================
    		bleachMask      = lerp(1.0, bleachMask, _BleachColor.a * Height2Curvature(detailDepth, 0.0, 0.6));
            _AlbedoOut.rgb 	= lerp(_BleachColor.rgb, _AlbedoOut.rgb, bleachMask);


	// Fabric Alpha Resolve ======================================================
	float 	alphaToDither = saturate(detailDepth * 2.0);
		
    		_AlphaOut *= min(tearAlpha, permenantAlpha);


    // Fabric Height Resolve =====================================================
            heightAll = depthHeight * _WeaveHeight;
            heightAll = lerp(heightAll, patternHeightR , patternHeightMask.x);
            heightAll = lerp(heightAll, patternHeightG , patternHeightMask.y);
            heightAll = lerp(heightAll, patternHeightB , patternHeightMask.z);
            heightAll += detailPatinaHeight1    * (1.0 - patinaMask)        * 5.0 * _WeaveHeight;
   
            heightAll += permenantAlphaHeight * 5;

            heightAll += tearingHeight.xyz * _TearingInt * 3.5;

    //====================================================================================================
    //====================================================================================================
            _GlossOut   *= tearingMask;

            _RetroOut = saturate((max(patinaMask, (1.0 - tearingMask))) * saturate(_C_Retro * 2.0) + saturate(_C_Retro - 0.5));

            _GlossOut *= detailAO;    
     
            _HeightOut.xyz = heightAll;
            _SpecOccOut *= detailAO * min(tearingOcclusionMask,  permenantAlphaOcclusion);


            // _AlphaOut = PhysicallyBased_GeometricOpacity(ndotv, _AlphaOut, _Thickness);
}





#endif
