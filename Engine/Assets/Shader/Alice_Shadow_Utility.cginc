#ifndef ALICE_SHADOWING
#define ALICE_SHADOWING

/****************************** DYNAMIC SHADOW ******************************/
float4x4 _ShadowProjectionMatrix0;
sampler2D _Shadowmap0;
half _ShadowNormalBias0;
half _ShadowDistanceBias0;

float4x4 _ShadowProjectionMatrix1;
sampler2D _Shadowmap1;
half _ShadowNormalBias1;
half _ShadowDistanceBias1;
fixed _ShadowmapSize0;
fixed _ShadowmapSize1;

fixed _ShadowmapBlurring;

float3 shadowingUV(float3 vertexPos, half3 normal, float4x4 shadowProjectionMatrix, half normalBias, half distBias)
{
	float4 biasedWPos = mul(unity_ObjectToWorld, half4(vertexPos + normalBias * normal, 1.0));
	float3 shadowUV = mul(shadowProjectionMatrix, biasedWPos);
	shadowUV.z -= distBias;
	shadowUV = half3(shadowUV.xy * 0.5 + 0.5, 1.0 - (shadowUV.z * 0.5 + 0.5));
	return shadowUV;
}

fixed2 shadowing(sampler2D shadowMap, half2 uv, float compare)
{
#ifdef USE_FUR_LIGHTING
	// float depths = tex2D(shadowMap, uv).r;

	// fixed shadowMask = step(compare, depths);
	// fixed thickness = saturate((compare - depths));
	
	// return half2(shadowMask, thickness);

	float depths = tex2Dlod(shadowMap, half4(uv,0,0)).r;

	fixed shadowMask = step(compare, depths);
	shadowMask = 1.0-exp(-200 * abs(depths-compare));
	fixed thickness = saturate((compare - depths));
	return half2(shadowMask, thickness);
#else
	float depths = tex2D(shadowMap, uv).r;
	fixed shadowMask = step(compare, depths);
	fixed thickness = saturate((compare - depths));
	return half2(shadowMask, thickness);

#endif
}


float2 texture2DShadowLerp(sampler2D shadowMap, half2 uv, float compare, half shadowmapSize)
{
	half remappedShadowMapSize = _ShadowmapBlurring * shadowmapSize;
    half2 texelSize = 1.0 / remappedShadowMapSize;
    half2 f = frac(uv * remappedShadowMapSize + 0.5);
    half2 centroidUV = floor(uv * remappedShadowMapSize + 0.5) / remappedShadowMapSize;


    float2 lb = shadowing(shadowMap, centroidUV + texelSize * half2(0.0, 0.0), compare);
    float2 lt = shadowing(shadowMap, centroidUV + texelSize * half2(0.0, 1.0), compare);
    float2 rb = shadowing(shadowMap, centroidUV + texelSize * half2(1.0, 0.0), compare);
    float2 rt = shadowing(shadowMap, centroidUV + texelSize * half2(1.0, 1.0), compare);
    
    float2 a = lerp(lb, lt, f.y);
    float2 b = lerp(rb, rt, f.y);
    float2 c = lerp(a, b, f.x);



    return c;
}

fixed2 PCF(sampler2D shadowMapSampler, half3 shadowUV, int iteration, half shadowmapSize)
{
    fixed2 result = 0.0;
    
    half2 uv = shadowUV.xy;
    half compare = shadowUV.z;
    for(int x = -iteration; x <= iteration; x++)
    {
        for(int y = -iteration; y <= iteration; y++)
        {
            half2 offset = half2(x, y) / (_ShadowmapBlurring * shadowmapSize);
            result += texture2DShadowLerp(shadowMapSampler, uv + offset, compare, shadowmapSize);
        }
    }

    fixed normFactor = (2 * iteration + 1 );
    normFactor *= normFactor;
    result =  1.0 - result / normFactor;


	half xx = texture2DShadowLerp(shadowMapSampler, uv, compare, shadowmapSize);

    return result;
}
