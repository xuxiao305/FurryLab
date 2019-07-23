// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

half4 _AnisoDir3;

half3 DiffuseLighting(half3 N, half3 L, half3 LColor, half thickness)
{
	float3 diffuseLighting = 1;
	float NdotL = dot(N,L)*0.75+0.25;	
	diffuseLighting = saturate(NdotL) * LColor;


	return diffuseLighting;
}

half3 HairStrandSpecular(half3 planeVec, half3 N, half3 V, half3 L, half3 LColor, half roughness)
{
	half3 H = normalize(V + L);
	float HdotT = dot(H, planeVec);
	float sinHT = 1 - sqrt(HdotT * HdotT);
	float dirAtten = smoothstep(-1, 0, HdotT);

	half NdotL = saturate(dot(N, L));
	half NdotV = saturate(dot(N, V));

	half NdotH = saturate(dot(N, H));
	half VdotH = saturate(dot(V, H));

	half specV = SmithGGXVisibilityTerm2 (NdotL, NdotV, roughness);
	half specD = GGXTerm2 (sinHT, roughness);

	half specF = Fresnel(0.04, VdotH);
	
	half specularLighting = max(0, specV * specF * specD * NdotL);

	return specularLighting * LColor;

}

inline float3 KajiyaKay (float3 N, float3 T, float3 V, float3 L, float specNoise) 
{
	half3 H = normalize(V + L);
	float3 B = normalize(T + N * specNoise);
	float dotBH = dot(B,H);
	return sqrt(1-dotBH*dotBH);
}

half3 ShiftPlaneVec(half tangentShift, half3 T, half3 N)
{
	half3 outputVec = normalize(T + N * tangentShift);
	return outputVec;
}
	


sampler2D _SurfaceDefinitionTex;

sampler2D _NormalTex;
float _NormalIntensity;

float _Metalness;
float _Roughness1;
float _Roughness2;
float4 _AlbedoColor;
float _Thickness;
half _TangentShift1;
half _TangentShift2;	
half _AnisoDir;
half _SpecularDye;

uniform float4 _DirectionalLight0;
uniform float4 _DirectionalLight1;
uniform float4 _DirectionalLightColor0;
uniform float4 _DirectionalLightColor1;

half4 HairPixel(VsOutput i){
	fixed4 output = 1;

	/************* DYNAMIC SHADOWING ****************/
	float shadow = LIGHT_ATTENUATION(i);

	fixed4 mainTex = tex2D(_MainTex, i.uv0);
	fixed3 albedoColor = _AlbedoColor.rgb * mainTex.rgb;

	fixed4 surfaceDefinition = tex2D(_SurfaceDefinitionTex, i.uv0);
	fixed shift = surfaceDefinition.r - 0.5;
	fixed roughness1 = saturate((1-surfaceDefinition.g) * _Roughness1);
	fixed roughness2 = saturate((1-surfaceDefinition.g) * _Roughness2);
	roughness1 = _Roughness1;
	roughness2 = _Roughness2;

	roughness1 = roughness1 * roughness1;
	roughness2 = roughness2 * roughness2;

	fixed noise = surfaceDefinition.b;

	fixed thickness = saturate(surfaceDefinition.b * surfaceDefinition.b * _Thickness);

	fixed AO = surfaceDefinition.a;

	half3 N = normalize(i.wNormal);

	half3 V = normalize(_WorldSpaceCameraPos - i.wPos);

	half3 wB = normalize(i.wBinormal);
	half3 wT = normalize(i.wTangent);

	fixed4 normalTex = tex2D(_NormalTex, i.uv0);

	normalTex.xyz = (UnpackNormal(normalTex)).xyz;

	normalTex.xyz = normalize(fixed3(normalTex.x * _NormalIntensity, normalTex.y * _NormalIntensity, normalTex.z));

	float3x3 tangentMatrix = float3x3(wT.x, wB.x, N.x, 
										wT.y, wB.y, N.y,
										wT.z, wB.z, N.z);

	N = mul(tangentMatrix, normalTex.xyz);
	wT =  mul(tangentMatrix, half3(1,0,0));

	half3 diffuseLighting = DiffuseLighting(N,_DirectionalLight0,_DirectionalLightColor0, 1);
	diffuseLighting *= shadow;
	diffuseLighting = DiffuseLighting(N,_DirectionalLight1,_DirectionalLightColor1, 1);
		
	half3 ambientLighting = AmbientLighting(N);

	diffuseLighting = diffuseLighting + ambientLighting; 
	float3 anisoDirWorld = normalize(mul(unity_ObjectToWorld, float4(normalize(_AnisoDir3.xyz), 0.0)).xyz);

	half3 planeVec = lerp(wT, wB, _AnisoDir);
	planeVec = normalize(mul(tangentMatrix, float4(normalize(_AnisoDir3.xyz), 0.0)).xyz);

	half3 shiftedPlaneVec1 = ShiftPlaneVec(_TangentShift1 + shift, planeVec, N);
	half3 shiftedPlaneVec2 = ShiftPlaneVec(_TangentShift2 + shift, planeVec, N);

	half3 hairSpec1 = HairStrandSpecular(shiftedPlaneVec1, N, V, _DirectionalLight0, _DirectionalLightColor0, roughness1) * 1;
	half3 hairSpec2 = HairStrandSpecular(shiftedPlaneVec2, N, V, _DirectionalLight0, _DirectionalLightColor0, roughness2) * lerp(1.0, mainTex,_SpecularDye) * 4 * noise;

	half3 specularLighting = (hairSpec1 + hairSpec2);// * shadow;

//	hairSpec1 = HairStrandSpecular(shiftedPlaneVec1, N, V, _DirectionalLight1, _DirectionalLightColor1, roughness1);
//	hairSpec2 = HairStrandSpecular(shiftedPlaneVec2, N, V, _DirectionalLight1, _DirectionalLightColor1, roughness2) * lerp(1.0, mainTex,_SpecularDye) * 4 * noise;
//	specularLighting += hairSpec1 + hairSpec2;

	output.rgb = diffuseLighting * mainTex.rgb + specularLighting;
	output.rgb = specularLighting;// * dot(N,_DirectionalLight0) ;

//	output.rgb = dot(N, V);
//	output.a = mainTex.a;
//output.rgb = wT;
	return output;
}			    