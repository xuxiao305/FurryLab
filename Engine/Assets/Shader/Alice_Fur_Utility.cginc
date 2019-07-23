#ifndef FUR_UTILITIES
#define FUR_UTILITIES


#define IMPORT_FUR_UNIFORM 	
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"	
			// #include "Alice_Shadow_Utility.cginc"

			#include "Alice_Lighting_Utility.cginc"

			sampler2D _AlbedoTex;
			half4 _AlbedoTex_ST;
			sampler2D _FurTex; 
			sampler2D _DirectionTex;
			half _DirectionInt;
			half _OffsetNoise;
			fixed _NormalIntensity; 
			float _FurReduction; 
			float _FurClumping; 
			float _FurLength;
			fixed _Gloss;			
			fixed _SpecularScale;
			
			fixed _SpecularShifting;

			fixed colorLerpFactorList[16];
			fixed _FurTiling;
			fixed _ShadingWarp;
			fixed3 _TipColor;
			fixed3 _RootColor;
			fixed _FurStiff;
			half4 _WindDirection;
			fixed _BaseMeshVertCount;
			fixed _RootShadowing;
			fixed _PushShellToTip;

			fixed _EdgeFalloff;


struct appdata_generic
{
	float4 vertex		: POSITION;
	fixed2 uv			: TEXCOORD0;
	fixed2 uv2			: TEXCOORD1;
	
	float3 normal		: NORMAL;
	float3 tangent		: TANGENT;
	fixed3 color 		: COLOR;

};

struct v2f_generic
{
	float4 pos : SV_POSITION;

	// UNITY_FOG_COORDS(0)
	half4 wHairDir : TEXCOORD0;
	half2 uv : TEXCOORD1;
	half2 uv2 : TEXCOORD2;
	half4 wPos : TEXCOORD3;
	half3 wNormal : TEXCOORD4;
	half3 wL : TEXCOORD5;
	half3 hairColor : TEXCOORD6;
	half3 debugColor : TEXCOORD7;
	half3 shadowUV0 : TEXCOORD8;
	half3 shadowUV1 : TEXCOORD9;

};

half preventBleeding (half i )
{
	return clamp(0.0001, 0.9999, i);
}


v2f_generic FurPassShadow_VS (appdata_generic v, fixed index, half4 wL, half colorLerpFactor)
{
	v2f_generic o = (v2f_generic)0;
	o.pos = UnityObjectToClipPos(v.vertex);

	return o;
}



v2f_generic FurPass_VS (appdata_generic v, fixed index, half4 wL, half colorLerpFactor)
{
	v2f_generic o = (v2f_generic)0;

	o.wNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));				

	fixed3 	offsetFromMap = tex2Dlod(_DirectionTex, half4(v.uv.xy, 0, 0)).xyz * 2.0 - 1.0;
			offsetFromMap.z = -offsetFromMap.z;

	half3	offsetFromTangent = v.tangent;
	half3 	offsetFromBinormal = cross(v.tangent, v.normal);

	half3 	gravityVec = half3(0.0, -1.0, .0);
	half3 	horiVec = normalize(cross(gravityVec, v.normal));
	half3 	biHoriVec = normalize(cross(v.normal, horiVec));

	half  	cosTheta 	= dot(v.normal, gravityVec);
	half 	cosTheta2 	= cosTheta * cosTheta;
	half 	sinTheta2 	= (1.0 - cosTheta2) * (1.0 - cosTheta2);
	half3 	offsetFramGravity = sinTheta2 * gravityVec;
			o.debugColor = biHoriVec;// * 0.5 + 0.5;

			offsetFramGravity = biHoriVec ;//* sinTheta2;

	fixed 	offsetFromMapNoise = tex2Dlod(_FurTex, half4(v.uv.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw, 0, 0)).r;
			offsetFromMapNoise = lerp(0.5, 1.0, offsetFromMapNoise);

	fixed3 	offsetFromVertex = v.normal * colorLerpFactor;
	half3 	offset = offsetFromVertex + offsetFramGravity.xyz * offsetFromMapNoise * colorLerpFactor * _DirectionInt;
			offset *= step(0.0, sin(length(v.vertex - half3(0, 2.0, 0.0)) * _OffsetNoise * 500.0));
	
	float4 offsetLocalPos = half4(v.vertex.xyz + offset * _FurLength, v.vertex.w);
	
	half3 vHairDir = normalize(offsetLocalPos.xyz - v.vertex.xyz);

	o.wHairDir = mul(unity_ObjectToWorld, float4(vHairDir, 0.0));
	// o.wHairDir.xyz = v.normal.xyz;

	o.wPos = mul(unity_ObjectToWorld, offsetLocalPos);

	o.pos = mul(UNITY_MATRIX_VP, o.wPos);
	o.uv = v.uv;
	o.uv2 = v.uv2;
	// TODO - unity_ObjectToWorld should be replaced by the inverse transpose matrix!!!!
	o.wL = wL;

	// lerp the hair color based on the normalized real distance instead of percentage, to get a softer / unified color
	half normalizedOffsetDistance = length(offset) / 0.15;
	o.hairColor = lerp(_RootColor, _TipColor, colorLerpFactor);
	o.wHairDir.w = normalizedOffsetDistance;

	o.shadowUV0 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix0, _ShadowNormalBias0, _ShadowDistanceBias0);
	o.shadowUV1 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix1, _ShadowNormalBias1, _ShadowDistanceBias1);

	return o;
}



float FurPassShadow_PS(v2f_generic i)
{
	half normalizedOffsetDistance = i.wHairDir.w;

	fixed furTex = tex2D(_FurTex, i.uv * _FurTiling).x;
	fixed alphaThreshold = lerp(_FurReduction * 0.5, _FurReduction, normalizedOffsetDistance);
	fixed alpha = step(alphaThreshold, furTex);
	clip(alpha - 0.5);
	return i.pos.z;
}

fixed4 FurPass_PS1(v2f_generic i, half index, half colorLerpFactor)
{
	// clip (-1);
	//////////////// Sample Textures ////////////////////////////
	half normalizedOffsetDistance = i.wHairDir.w;

	fixed furTex = tex2D(_FurTex, i.uv * _FurTiling).x;
	fixed alphaThreshold = lerp(_FurReduction * 0.5, _FurReduction, normalizedOffsetDistance);
	fixed alpha = step(alphaThreshold, furTex);

	if(index>0)
	{
		clip(alpha - 0.1);
	}
	

	fixed4 output = 1;
	fixed4 albedoTex = tex2D(_AlbedoTex, i.uv * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw);

	fixed3 albedo = i.hairColor.xyz;

	//////////////// Prepare Normal and Tangent Space ////////////////////////////
	half3 wL = normalize(_DirLightFwd0);
	half3 wHairDir = normalize(i.wHairDir);
	half3 wV = normalize(_WorldSpaceCameraPos - i.wPos);
	half3 wH = normalize(wL + wV);
	half  HdotT = dot(wHairDir, wH);
	half  shading = KajiyaKayShading(HdotT, _Gloss, _SpecularScale);
	

	output.xyz = albedo * shading; 

	return output;
}



fixed4 FurPass_PS(v2f_generic i, half index, half colorLerpFactor)
{
	// clip (-1);
	//////////////// Sample Textures ////////////////////////////
	half clumpingMap = tex2D(_AlbedoTex, i.uv.xy * _AlbedoTex_ST.x).r;
	half clumpingMap1 = tex2D(_AlbedoTex, (i.uv.xy + half2(0.001, 0.0)) * _AlbedoTex_ST.x).r;
	half clumpingMap2 = tex2D(_AlbedoTex, (i.uv.xy + half2(0.0, 0.001)) * _AlbedoTex_ST.x).r;

	half2 clumpping = half2(-clumpingMap1 + clumpingMap, -clumpingMap2 + clumpingMap) * _FurClumping * colorLerpFactor;

	// return half4(clumpping, 0, 1.0);
	half normalizedOffsetDistance = i.wHairDir.w;

	fixed furTex = tex2D(_FurTex, (i.uv + clumpping.xy) * _FurTiling).x;
	fixed alphaThreshold = lerp(_FurReduction * 0.5, _FurReduction, normalizedOffsetDistance);
	fixed alpha = step(alphaThreshold, furTex);
	alpha *= step(abs(clumpping.x) * abs(clumpping.y) * 1000.0, 0.001);

	if(index>0)
	{
		clip(alpha - 0.1);
	}
	
	fixed4 output = 1;
	fixed4 albedoTex = tex2D(_AlbedoTex, i.uv * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw);

	fixed3 albedo = i.hairColor.xyz;
	half3 wHairDir = normalize(i.wHairDir);

	half  specShift = 0.0;

    half3   lightingResult = GenericLighting(albedo, 
                                              half3(0.0, 0.0, 1.0), 
                                              0.0,
                                              0.0,
                                              1.0,
											  0.0,
                                              1.0,
                                              1.0,
                                              0.0,
                                              i.wNormal,
                                              wHairDir,
                                              0.0,
                                              i.wPos,
                                              i.shadowUV0,
                                              i.shadowUV1,
                                              i.uv,
                                              specShift,
                                              _Gloss,
                                              _SpecularScale,
                                              1.0, 1.0, 1.0, 1.0);

    output.rgb = lightingResult;


	// return float4(0.0, 100.0 * x * x, 0.0, 1.0);

	return output;
}




#endif