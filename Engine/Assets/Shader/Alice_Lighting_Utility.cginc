#ifndef ALICELIGHTING
#define ALICELIGHTING

#define M_PI 3.1415926535897932384626433832795
#define M_INV_PI 0.31830988618379067153776752674503
#define M_INV_LOG2 1.4426950408889634073599246810019
#define M_GOLDEN_RATIO 0.618034	
#define one2 1.0
#define one3 1.0
#define one4 1.0
#define zero2 0.0
#define zero3 0.0
#define zero4 0.0
/****************************** DYNAMIC SHADOW ******************************/
fixed _AddShadowDistanceBias;

float4x4 _ShadowProjectionMatrix0;
sampler2D _Shadowmap0;
half _ShadowNormalBias0;
half _ShadowDistanceBias0;
fixed _ShadowmapSize0;

float4x4 _ShadowProjectionMatrix1;
sampler2D _Shadowmap1;
half _ShadowNormalBias1;
half _ShadowDistanceBias1;


fixed _ShadowmapSize1;
fixed _ShadowmapBlurring;
half _ShadowDepthFalloff;

int _LightType0;
int _LightType1;
float3 _DirLightFwd0;
float3 _DirLightFwd1;
float3 _DirLightPos0;
float3 _DirLightPos1;
half _ConeFalloffStart0;
half _ConeFalloffEnd0;
half _ConeFalloffStart1;
half _ConeFalloffEnd1;
fixed4 _DirLightColorIntensity0;
fixed4 _DirLightColorIntensity1;
half3 _TubeLightPosStart0;
half3 _TubeLightPosStart1;
half3 _TubeLightPosEnd0;
half3 _TubeLightPosEnd1;
half _SphereLightRadius;
half _DistanceFalloff0;
half _DistanceFalloff1;

int _IBLImportanceSampling;
int _IBLSampleCount;


half _EnvRotation;


half _SSSMaskingFactor;
half _Translucency;
half _RetroTint;
fixed _UseBentNormal;



sampler2D _TranslucentTex;
samplerCUBE _ReflectProbeTex;

#ifdef SKIN_SHADING
	half _Curvature;
	sampler2D _ScatteringTex;
#endif

half3 rotate(half3 v, float a)
{
	float angle = a * 2.0 * M_PI;
	float ca = cos(angle);
	float sa = sin(angle);
	return half3(v.x*ca+v.z*sa, v.y, v.z*ca-v.x*sa);
}

fixed2 ParralaxUV(half2 uv, half height, half3 wV, half3 wN, half refractionIndex)
{
	half2 outUV = uv - 0.5;
	half3 wGazeDir = half3(0,0,1);
	half3 wRefraction = refract(-wV, wN, refractionIndex);
	float cosAlpha = dot(wGazeDir, -wRefraction);
	float dist = (height - 1.0) / cosAlpha;
	float3 offsetW = dist * wRefraction;
	
	//return offsetW.xy;

	float2 offsetL = half2(dot(unity_WorldToObject[0].xyz, offsetW.x), dot(unity_WorldToObject[2].xyz, offsetW.y));
	half mask = 0.1;

	outUV = (outUV + float2(mask, -mask) * offsetL);
	outUV += 0.5;
	return outUV;
}


half3 CombineNormal(half3 baseNormal, half3 topNormal)
{
    half3 t     = baseNormal;
           t.z   = t.z + 1.0f;
    half3 u     = topNormal;
           u.xy *= -1.0f;
    return half3(t * dot(t, u) / t.z - u);
}		


half Normal2Gloss(half3 normal, fixed s)
{
	half normLen = length(normal);
	half variance = (1.0 - normLen) / normLen;
	half p = s / (1.0 + variance * s);
	return p;
}

half ComputeCurvature(half3 N, float3 wPos, float curvatureScale)
{
	float curvature = length(fwidth(N)) * curvatureScale / length(fwidth(wPos));
	return curvature;
}

half3 DisneyDiffuse(half NdotV, half NdotL, half LdotH, half roughness)
{
 	// Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    half FL = pow(1.0 - NdotL, 5.0); 
    half FV = pow(1.0 - NdotV, 5.0);
    half Fd90MinusOne = 0.5 + 2 * LdotH * LdotH * roughness - 1.0;
    half Fd = (1.0 + Fd90MinusOne * FL) * (1.0 + Fd90MinusOne * FV);
    return Fd;
}

half SmithVisibilityTerm2(half NdotL, half NdotV, half k)
{
	half gL = NdotL * (1-k) + k;
	half gV = NdotV * (1-k) + k;

	return 1.0 / (gL*gV) + 1e-5f;
}

// This one should be the same as SmithVisibilityTerm2, but I will just keep it here for now
float G1(
	float ndw, // w is either Ln or Vn
	float k)
{
// One generic factor of the geometry function divided by ndw
// NB : We should have k > 0
	return 1.0 / ( ndw*(1.0-k) + k );
}

float visibility(
	float ndl,
	float ndv,
	float Roughness)
{
// Schlick with Smith-like choice of k
// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
// visibility is a Cook-Torrance geometry function divided by (n.l)*(n.v)
	float k = Roughness * Roughness * 0.5;
	return G1(ndl,k)*G1(ndv,k);
}


half SmithGGXVisibilityTerm2 (half NdotL, half NdotV, half roughness)
{
	half k = (roughness * roughness) / 2.0;

	return SmithVisibilityTerm2 (NdotL, NdotV, k);
}

half SmithJointGGXVisibilityTerm (half NdotL, half NdotV, half roughness)
{

    // Original formulation:
    //  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
    //  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
    //  G           = 1 / (1 + lambda_v + lambda_l);

    // Reorder code to be more optimal
    half a          = roughness;
    half a2         = a * a;

    half lambdaV    = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
    half lambdaL    = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

    // Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
    return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
}

half GGXTerm2 (half NdotH, half roughness)
{
	half a = roughness * roughness;
	half a2 = a * a;
	half d = NdotH * NdotH * (a2 - 1.0f) + 1.0f;

	return a2 / (3.14 * d * d );
}


half3 Fresnel(half3 F0, half VdotH)
{
// Schlick with Spherical Gaussian approximation
// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
	float sphg = pow(2.0, (-5.55473 * VdotH - 6.98316) * VdotH);
	return F0 + (1.0 - F0) * sphg;
}


half3 GGXSpecularLighting(fixed3 F0, fixed NdotL, fixed NdotV, fixed NdotH, fixed VdotH, fixed roughness)
{
	// half specV = SmithGGXVisibilityTerm2(NdotL, NdotV, roughness);
	half specV = SmithJointGGXVisibilityTerm(NdotL, NdotV, roughness);
	half specD = GGXTerm2(NdotH, roughness);
	half3 specF = Fresnel(F0, VdotH);
	half3 outSpec = max(0.0, specV * specF * specD * NdotL);
	return outSpec;
}

half KajiyaKayShading(half HdotT, half gloss, half specScale)
{
	half  shading = pow(sqrt(1.0 - HdotT * HdotT), exp(lerp(1.0, 11.0, gloss))) * specScale;
	half  dirAtten = smoothstep(-1.0, 0.0, HdotT); // i don't see the effect from this...

	return shading;
}


#ifdef SKIN_SHADING
half3 SkinDiffuseLighting(fixed sss, half3 wNBlurR, half3 wNBlurG, half3 wNBlurB, half3 wL, 
                          fixed curvature, fixed thickness)
{

	half3 diffuseLighting = 1;
	
	half scattering = (1 - thickness * _SSSMaskingFactor);
	
	half3 NrgbDotL = half3(dot(wNBlurR, wL), dot(wNBlurG, wL), dot(wNBlurB, wL));

	float3 lookup = half3(NrgbDotL * 0.5 + 0.5);

	diffuseLighting.r = tex2D(_ScatteringTex, float2(lookup.r, curvature)).r;
	diffuseLighting.g = tex2D(_ScatteringTex, float2(lookup.g, curvature)).g;
	diffuseLighting.b = tex2D(_ScatteringTex, float2(lookup.b, curvature)).b;

	return diffuseLighting;
}
#endif

half3 LambertDiffuseLighting (half3 wN, half3 wL)
{
	return saturate(dot(wN, wL));
}
half3 TranslucencyLighting(half3 wL, half3 wV, half3 wN, half thickness, fixed4 dirLightColorIntensity)
{
	half LdotV = saturate(dot(-wL, wV));
	half backNdotL = dot(-wN, wL) * 0.5 + 0.5;

	half translucency = pow((1 - thickness), 0.25) * backNdotL;

	half3 ambinetTransluceny = ShadeSH9(float4(-wV, 1)) * translucency;

	half3 translucentColor = tex2D(_TranslucentTex, float2(translucency, 0.5)).rgb;

	half3 translucentColor2 = tex2D(_TranslucentTex, float2(ambinetTransluceny.r * 0.25 + ambinetTransluceny.g * 0.65 + ambinetTransluceny.b * 0.1, 0.5)).rgb;
	translucentColor2 *= lerp(1.0, ambinetTransluceny, 0.75);

	half3 translucencyLighting = translucentColor;// + translucentColor2;
	translucencyLighting *= dirLightColorIntensity.rgb * dirLightColorIntensity.w;
	return translucencyLighting;
}



half3 FastSSSWrap(half NdotL, fixed wrapScale, fixed3 scatterColor)
{
	fixed diffuseShading = saturate(NdotL + wrapScale) / (1 + wrapScale); 
	fixed3 scatterLight = saturate(scatterColor + saturate(NdotL)) * diffuseShading;
	fixed3 diffuseLighting = scatterLight; 
	return diffuseLighting;
}

half3 ClothDiffuseLighting(fixed3 wN, half3 wL, fixed wrapScale, fixed4 scatterColor)
{
	fixed NdotL = dot(wN, wL);

	half3 diffuseLighting = FastSSSWrap(NdotL, wrapScale, scatterColor);
	/*
	fixed diffuseShading = saturate(NdotL + wrapScale) / (1 + wrapScale); 
	fixed3 scatterLight = saturate(scatterColor.rgb + saturate(NdotL)) * diffuseShading;
	fixed3 diffuseLighting = scatterLight;
	*/
	return diffuseLighting;
}


//http://www.cs.utah.edu/~premoze/dbrdf/dBRDF.pdf
half3 DistributionBasedBRDFSpecular(half3 tN, half3 tL, half3 tH, half3 tV, fixed specScale, fixed gloss, half3 anisoDir, fixed anisoOffset, fixed anisoBlend)
{
	fixed HdotA = dot(normalize(tN + anisoDir.xyz), tH);
	float aniso = saturate(sin(radians((HdotA + anisoOffset) * 180)));

	float NdotH = saturate(dot(tN, tH));
	half VdotH = dot(tV, tH);
	half VdotN = dot(tV, tN);
	half LdotN = dot(tL, tN);

	half3 specF = Fresnel(0.04, VdotH);


	half anisoPhong = sqrt(gloss) * pow(lerp(NdotH, aniso, anisoBlend), gloss);

	half specEnergyConservation = VdotN + LdotN - VdotN * LdotN;

	half3 spec = specScale * anisoPhong * specF * saturate(LdotN)/ specEnergyConservation;

	return spec;
}



float AshikhminD(float ndh, float roughness)
{
	float 	a2 = roughness * roughness;
    float 	ct2  = ndh*ndh;
    float 	st2  = 1.0001 - ct2;
    float 	st4  = st2*st2;
    float 	cot2 = ct2/st2;
    float 	A = 4.0;
    float 	d = (1 + A*exp(-cot2/a2)/st4);
    	  	d = d / (M_PI * (A*a2 + 1));
    return 	d;
}

 

float3 Ashikhmin_contrib(
	float vdh,
	float ndh,
	float ndl,
	float ndv)
{
	float3  f = Fresnel(vdh, one3 * 0.04);

	float  denomiator = 1.0 / 4.0 * (ndl + ndv - ndl * ndv);
	return denomiator;
	return denomiator * vdh * ndl / ndh; 
	// return denomiator;
	return f * (denomiator * vdh * ndl / ndh );
}

float3 RetroSpecLighting(float NdotH, float VdotH, float NdotL, float NdotV, float roughness)
{
	float D = AshikhminD(NdotH, roughness);
	float V = Ashikhmin_contrib(VdotH, NdotH, NdotL, NdotV);

	return D* V;// * NdotL;
}

float2 fippedBookUV(float row, float column, float2 uv, float offset)
{
    float2 newUV = uv;
    newUV.x = newUV.x / column;
    newUV.y = newUV.y / row;
    float xStep = (int)(offset);
    float yStep = (int)(offset / column);

    newUV.x += xStep / column;
    newUV.y += yStep / row;

    return newUV;
}

/****************************** IBL *****************************************/
// From Substance Painter 

half2 fibonacci2D(int i, int nbSamples)
{
	half x = (float)(i+1) * M_GOLDEN_RATIO;
	half y = (float)((i)+0.5) / (float)(nbSamples);
  	return half2(x, y);
}

half3 importanceSampleGGX(half2 Xi, half3 A, half3 B, half3 C, float roughness)
{
	float a = roughness*roughness;
	float cosT = sqrt((1.0-Xi.y)/(1.0+(a*a-1.0)*Xi.y));
	float sinT = sqrt(1.0-cosT*cosT);
	float phi = 2.0*M_PI*Xi.x;
	return (sinT*cos(phi)) * A + (sinT*sin(phi)) * B + cosT * C;
}



half3 importanceSampleRetro(half2 Xi, half3 A, half3 B, half3 C, float roughness)
{
	float a = roughness*roughness;
	float cosT = sqrt((1.0-Xi.y)/(1.0+(a*a-1.0)*Xi.y));
	float sinT = sqrt(1.0-cosT*cosT);
	float phi = 2.0*M_PI*Xi.x;
	return (sinT*cos(phi)) * A + (sinT*sin(phi)) * B + cosT * C;
}

float normal_distrib(
	float ndh,
	float Roughness)
{
	// use GGX / Trowbridge-Reitz, same as Disney and Unreal 4
	// cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
	float alpha = Roughness * Roughness;
	float tmp = alpha / max(1e-8,(ndh*ndh*(alpha*alpha-1.0)+1.0));
	return tmp * tmp * M_INV_PI;
}

float distortion(half3 Wn)
{
	// Computes the inverse of the solid angle of the (differential) pixel in
	// the environment map pointed at by Wn
	float sinT = sqrt(1.0 - Wn.y * Wn.y);
	return sinT;
}

float probabilityGGX(float ndh, float vdh, float Roughness)
{
	return normal_distrib(ndh, Roughness) * ndh / (4.0*vdh);
}


half3 microfacets_contrib(
	float vdh,
	float ndh,
	float ndl,
	float ndv,
	half3 Ks,
	float Roughness,
	float multiScattering)
{
	// This is the contribution when using importance sampling with the GGX based
	// sample distribution. This means ct_contrib = ct_brdf / ggx_probability
	return Fresnel(Ks, vdh) * (multiScattering + visibility(ndl,ndv,Roughness) * vdh * ndl / ndh );
}

float computeLOD(half3 Ln, float p, int nbSamples, float maxLod)
{
	return max(0.0, (maxLod-1.5) - 0.5*(log(float(nbSamples)) + log( p * distortion(Ln) ))
		* M_INV_LOG2);
}


float _HorizonFade;



                        
half3 IBLSpecularContribution(
	samplerCUBE environmentMap,
	float envRotation,
	float maxLod,
	int nbSamples,
	half3 normalWS,
	half3 fixedNormalWS,
	half3 Tp,
	half3 Bp,
	half3 pointToCameraDirWS,
	half3 specColor,
	float roughness,
	float multiScattering)
{
	half3 sum = 0.0;

	float ndv = max( 1e-8, abs(dot( pointToCameraDirWS, fixedNormalWS )) );

	for(int i=0; i<nbSamples; ++i)
	{
		half2 Xi = fibonacci2D(i, nbSamples);


		half3 Hn = importanceSampleGGX(Xi,Tp,Bp,fixedNormalWS,roughness);

		half3 Ln = -reflect(pointToCameraDirWS, Hn);

		half ndl = dot(fixedNormalWS, Ln);

		// Horizon fading trick from http://marmosetco.tumblr.com/post/81245981087
		half horiz = saturate(1.0 + _HorizonFade * dot(normalWS, Ln));
		horiz *= horiz;
		ndl = max( 1e-8, ndl);

		half vdh = max( 1e-8, abs(dot(pointToCameraDirWS, Hn)));
		half ndh = max( 1e-8, abs(dot(fixedNormalWS, Hn)));


		half lodSGGX = computeLOD(Ln, probabilityGGX(ndh, vdh, roughness),nbSamples,maxLod);


		half lodS = lodSGGX;
		lodS = roughness < 0.01 ? 0.0 : lodS;

		half3 contribGGX = microfacets_contrib(vdh, ndh, ndl, ndv, specColor, roughness, multiScattering);

		half3 contrib = contribGGX;

		sum += texCUBElod(environmentMap, half4(rotate(Ln,envRotation), lodS)) * contrib;

		// sum += texCUBElod(environmentMap, half4(rotate(Ln,envRotation), lodS))* (microfacets_contrib(vdh, ndh, ndl, ndv,specColor, roughness, multiScattering));// * horiz;
		// half lodS = roughness < 0.01 ? 0.0 : computeLOD(Ln, AshikhminD(ndh, roughness),nbSamples,maxLod);
		// sum += texCUBElod(environmentMap, half4(rotate(Ln,envRotation), lodS))* (Ashikhmin_contrib(vdh, ndh, ndl, ndv));// * horiz;

	}


	return sum / nbSamples;
}



void computeSamplingFrame(half3 iFS_Tangent, half3 iFS_Binormal, half3 fixedNormalWS, out half3 Tp, out half3 Bp)
{
	Tp = normalize(iFS_Tangent - fixedNormalWS * dot(iFS_Tangent, fixedNormalWS));
	Bp = normalize(iFS_Binormal - fixedNormalWS * dot(iFS_Binormal, fixedNormalWS) - Tp * dot(iFS_Binormal, Tp));
}



half3 computeIBL(
	samplerCUBE environmentMap,
	float envRotation, 
	half3 wN,
	half3 wV,
	half3 specColor,
	float roughness)
{


	half3 wReflectDir = -reflect(wV, wN);
	float NdotV = saturate(dot(wN, wV));
	half3 result = texCUBElod(environmentMap, half4(rotate(wReflectDir, envRotation), roughness * 7.0)) 	
					* (Fresnel(specColor, NdotV));

	return result;

}



float3 shadowingUV(float3 vertexPos, half3 normal, float4x4 shadowProjectionMatrix, half normalBias, half distBias)
{
	float4 biasedWPos = mul(unity_ObjectToWorld, half4(vertexPos + normalBias * normal, 1.0));
	float3 shadowUV = mul(shadowProjectionMatrix, biasedWPos);
	shadowUV.z -= distBias;
	shadowUV = half3(shadowUV.xy * 0.5 + 0.5, 1.0 - (shadowUV.z * 0.5 + 0.5));
	return shadowUV;
}

float2 shadowing(sampler2D shadowMapSampler, half2 uv, float compare, float shadowDepthFalloff, float objID)
{
#ifdef EXP_FALLOFF_SHADOW
	float2 shadowMap = tex2Dlod(shadowMapSampler, half4(uv,0,0)).rg; 
	float  depths = shadowMap.r + _AddShadowDistanceBias;
	float materialIndex = shadowMap.g;

	float thickness = saturate((compare - depths));
	float shadowMask = 0.0;

	// if the occluder is self, then use exp for shadowing, otherwise use the regular one
	if (abs(materialIndex - objID) < 0.01)
	{
		// shadowMask = 1.0-exp(- shadowDepthFalloff * 100 * max(0.0, depths-compare));
		shadowMask = 1.0 - exp(-shadowDepthFalloff * 100.0 * max(0.0, depths - compare));

	}
	else
	{
		shadowMask = step(compare, depths);

	}

	// shadowMask = abs(depths - compare);
	// shadowMask = depths;
	// shadowMask = compare;
	return float2(shadowMask, thickness);
#else
	float depths = tex2D(shadowMapSampler, uv).r + _AddShadowDistanceBias;
	fixed shadowMask = step(compare, depths);
	fixed thickness = saturate((compare - depths));
	return half2(shadowMask, thickness);

#endif
}


float2 texture2DShadowLerp(sampler2D shadowMap, half2 uv, float compare, half shadowmapSize, float shadowDepthFalloff, float objID)
{
	half remappedShadowMapSize = _ShadowmapBlurring * shadowmapSize;
    half2 texelSize = 1.0 / remappedShadowMapSize;
    half2 f = frac(uv * remappedShadowMapSize + 0.5);
    half2 centroidUV = floor(uv * remappedShadowMapSize + 0.5) / remappedShadowMapSize;


    float2 lb = shadowing(shadowMap, centroidUV + texelSize * half2(0.0, 0.0), compare, shadowDepthFalloff, objID);
    float2 lt = shadowing(shadowMap, centroidUV + texelSize * half2(0.0, 1.0), compare, shadowDepthFalloff, objID);
    float2 rb = shadowing(shadowMap, centroidUV + texelSize * half2(1.0, 0.0), compare, shadowDepthFalloff, objID);
    float2 rt = shadowing(shadowMap, centroidUV + texelSize * half2(1.0, 1.0), compare, shadowDepthFalloff, objID);
    
    float2 a = lerp(lb, lt, f.y);
    float2 b = lerp(rb, rt, f.y);
    float2 c = lerp(a, b, f.x);



    return c;
}

half2 PCF(sampler2D shadowMapSampler, half3 shadowUV, int iteration, half shadowmapSize, float shadowDepthFalloff, float objID)
{
    half2 result = 0.0;
    
    half2 uv = shadowUV.xy;
    half compare = shadowUV.z;
    for(int x = -iteration; x <= iteration; x++)
    {
        for(int y = -iteration; y <= iteration; y++)
        {
            half2 offset = half2(x, y) / (_ShadowmapBlurring * shadowmapSize);
            result += texture2DShadowLerp(shadowMapSampler, uv + offset, compare, shadowmapSize, shadowDepthFalloff, objID);
        }
    }

    half normFactor = (2 * iteration + 1 );
    normFactor *= normFactor;
    result =  1.0 - result / normFactor;

    return result;
}

void LineLight(half3 wPos, half3 wDir, half3 n, half3 startPos, half3 endPos, half falloff, 
                    out half3 wL, out float irradiance)
{
    irradiance = 1.0;
    half3 r = wDir;
    half3 L0 = startPos - wPos;
    half3 L1 = endPos - wPos;
    half3 Ld = endPos - startPos;


    float a = dot(r, L0) * dot(r, Ld) - dot(L0, Ld);
    float b = pow(length(Ld), 2.0) - pow(dot(r, Ld), 2.0);
    float t = a / b;

    wL = normalize(startPos + Ld * saturate(t) - wPos);

    float temp = 2 * saturate(dot(n, L0) / (2.0 * length(L0)) + dot(n, L1) / (2.0 * length(L1)));
    float denominator = length(L0) * length(L1) + dot(L0, L1) + 2.0;
	
	denominator = pow(denominator, falloff);

    irradiance = temp / denominator;
}

void DirectionalLightIrradiance(half3 wPos, half3 wDir, half3 lightPos, half coneFalloffStart, half coneFalloffEnd, half distanceFalloff,
                      	out half irradiance)
{
	half3 L = lightPos - wPos;
	half  dist = length(L);
	half  cosine = dot(normalize(L), normalize(wDir));
	half  sine = sqrt(1.0 - cosine * cosine);
	half  coneRadius = length(L) * sine;

	half  coneFalloffRatio = smoothstep(coneFalloffEnd, coneFalloffStart, coneRadius);
	half  distanceFalloffRatio = saturate(1.0 / pow(dist * dist, distanceFalloff));

	irradiance = coneFalloffRatio * distanceFalloffRatio;
}

//********************* Lighting *************************//
half3 GenericLighting (	half3 	albedo, 
                          	half3 	tNormal, //tangent space pixel normal 
                          	half 	gloss, 
                          	half 	metallness,
                          	half 	microVisibility, 
                          	half 	retroReflectivity,
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
                          	half2   tangentShift,
                          	half2 	hairGloss,
                          	half2 	hairSpec,
                          	half 	sssMask,
                          	half3   wNBlurR,
                          	half3 	wNBlurG,
                          	half3 	wNBlurB)
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

	half3 	wN = mul(tangentMatrix, tNormal);
	half3 	wVr = normalize(reflect(wV, wN));

	#ifdef HAIR_SHDING
			half3 	wT1 = normalize(wVertexB + tangentShift.x * wN);	
			half3 	wT2 = normalize(wVertexB + tangentShift.y * wN); 
	#endif

	#ifdef GEO_FUR_SHADING
					wT = normalize(wT + tangentShift.x * wN);	
	#endif



	half  	NdotV = saturate(dot(wN, wV));
	half3 	wReflectDir = -reflect(wV, wN);

	fixed3 	F0 = lerp(0.04, albedo, metallness);

	
	///////////////////////// IBL ////////////////////////////////////
	half3 	ambientDiffuseLighting 		= ShadeSH9(float4(rotate(wN, _EnvRotation), 1)).xyz * albedo;
	half3 	ambientTranslucentLighting 	= ShadeSH9(float4(-rotate(wN, _EnvRotation), 1)).xyz * (1.0 - thicknessMask) * albedo; 
	half3 	ambientSpecularLighting 	= computeIBL(_ReflectProbeTex, 
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
		half3 wDiffuseLightDir = float3(0.0,1.0,0.0);
		half3 wSpecLightDir  = float3(0.0,1.0,0.0);
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


		half MAT_ID = 0.0;


		#ifdef GENERIC_PBR_SHADING

			half3 	specGGX = GGXSpecularLighting(F0, NdotL, NdotV, saturate(NdotH), VdotH, roughness) * lightColor;  
			half3 	specRetro = RetroSpecLighting(NdotH, VdotH, NdotL, NdotV, gloss) * lightColor * lerp(1.0, albedo, _RetroTint);
					// specularLighting += lerp(specGGX, specRetro, retroReflectivity) * irradiance;
					specularLighting += specGGX * irradiance;
					directionalDiffuseLighting += LambertDiffuseLighting(wN, wDiffuseLightDir) * lightColor * diffuseIrradiance * albedo;
		#endif 

		#ifdef HAIR_SHDING
			half  	HdotT1 = dot(wH, wT1);
			half  	HdotT2 = dot(wH, wT2);
			half3 	kkLobe1 = KajiyaKayShading(HdotT1, hairGloss.x, hairSpec.x);
			half3 	kkLobe2 = KajiyaKayShading(HdotT2, hairGloss.y, hairSpec.y) * albedo;

					specularLighting += (kkLobe1 + kkLobe2) * lightColor * irradiance;
				  	directionalDiffuseLighting = 0.0;

					MAT_ID = 0.3;
		#endif

		#ifdef FUR_SHADING
			half 	HdotT = dot(wH, wT);
				  	specularLighting += albedo * KajiyaKayShading(HdotT, hairGloss.x, hairSpec.x) * lightColor * irradiance;
					directionalDiffuseLighting = LambertDiffuseLighting(wN, wDiffuseLightDir) * lightColor * diffuseIrradiance * albedo * 0.5;
					MAT_ID = 0.5;

		#endif

		#ifdef GEO_FUR_SHADING
			half 	HdotT = dot(wH, wT);
				  	specularLighting += KajiyaKayShading(HdotT, hairGloss.x, hairSpec.x) * lightColor * irradiance * lerp(0.1, albedo * 1.0, saturate(dot(albedo, 5))); 
				  	directionalDiffuseLighting  = LambertDiffuseLighting(wDiffuseLightDir, wN) * lightColor * diffuseIrradiance * albedo * 0.5;
					MAT_ID = 0.1;


		#endif 

		int shadowPrecision = 3;
 
		#ifdef GEO_FUR_SHADING 
			shadowPrecision = 1;
		#endif

		half2 	shadowAndThickness = PCF(shadowmapSampler[i], shadowUVs[i], shadowPrecision, shadowMapSize[i], _ShadowDepthFalloff, MAT_ID);
				shadow = min(shadow, shadowAndThickness.x);

		// #ifdef FUR_SHADING
		// 		shadow = lerp(1.0, shadow, saturate(NdotV * 2.0));
		// #endif

		#ifdef SKIN_SHADING
			// float 	curvature = ComputeCurvature(wN, i.wPos, _Curvature);	
			// half    GGXLobe1 = GGXSpecularLighting(0.04, NdotL, NdotV, NdotH, VdotH, roughness);  
			// half  	GGXLobe2 = GGXSpecularLighting(0.04, NdotL, NdotV, NdotH, VdotH, roughness * 0.5);  
			// 		specularLighting = GGXLobe1 * 0.8 + GGXLobe2 * 0.2;
			// 		directionalDiffuseLighting += SkinDiffuseLighting(sssMask, wNBlurR, wNBlurG, wNBlurB, wDiffuseLightDir, curvature, thickness);


		#endif
		thickness = max(thickness, shadowAndThickness.y);

	}

	//a terrible hack to generate the sky visibility...
	half 	skyVis = smoothstep(0.0, 1.0, dot(wN, half3(0,1,0))*0.5+0.5); 
	half 	cameraVis = smoothstep(3.0, 1.0, length(wPos - half3(0.0,1.5, 0.0))); 
			finalAO = min(finalAO, skyVis * cameraVis);

#ifdef GEO_FUR_SHADING
	finalAO =1;// 1.0 - uv.y;
#endif

	half3 	output = (directionalDiffuseLighting * finalAO * shadow) + 
						specularLighting * shadow * finalAO +
						ambientDiffuseLighting * finalAO;// + ambientSpecularLighting * finalAO * 0.2;

	// output = step(tex2Dlod(shadowmapSampler[0], half4(shadowUVs[0].xy,0,0)).r, shadowUVs[0].z); 
	// output = directionalDiffuseLighting * finalAO * shadow * 0.15 + ambientDiffuseLighting * finalAO ;

	return output;
}




/****************************** TONE MAPPING ******************************/
float3 ACESToneMapping(float3 color, float adapted_lum)
{
	const float A = 2.51f;
	const float B = 0.03f;
	const float C = 2.43f;
	const float D = 0.59f;
	const float E = 0.14f;

	color *= adapted_lum;
	return (color * (A * color + B)) / (color * (C * color + D) + E);
}


	
#endif
