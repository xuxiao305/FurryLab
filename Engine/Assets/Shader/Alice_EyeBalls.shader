Shader "Alice/Alice_EyeBall"
{
	Properties
	{
		_AlbedoTex ("Albedo, AO", 2D) = "white" {}
		_AlbedoColor ("Albedo Color", Color) = (1, 1, 1, 1)

		_NormalRoughnessTex ("Normal, Roughness", 2D) = "black"{}
		_NormalIntensity ("Normal Intensity", Range(0,1.0))= 1

		_FluidNormalTex ("Fluid Normal", 2D) = "black" {}
		_FluidNormalIntensity ("Fluid Normal Intensity", Range(0,1.0)) = 1

		_MaskTex ("Mask", 2D) = "black" {}
		_ParralxHeight ("Parralax Height", 2D) = "white"{}
		
		_ScatteringTex ("Scattering Texture", 2D) = "black"{}
		
		_SSSStrength ("SSS Strength", Range(0, 8)) = 1
		_SSSMaskingFactor ("SSS Masking Factor", Range(0, 1)) = 0.5
		_NormalBlurTuner ("Normal Blur Tuner", Color) = (1.0, 0.5, 0.0)
		_Curvature("Curvature", Range(0.000,0.025)) = 0.015
		_Roughness ("Roughness", Range(0.1,2)) = 1
		
		_ReflectProbeTex ("ReflectProbeTex", CUBE) = "white"{}

		[Header(Eyes)]
		_PupilSize("PupilSize", Range(0.001, 0.5)) = 0.25
		_RefractionIndex("Refraction Index", Range(0.015, 0.75)) = 0.4

		[Header(Occlusion)]
		_AO2SpecOccPower ("AO to SpecOcc Power", Range(1,10)) = 5 
		_AOColorBleeding ("AO Color Bleeding", Color) = (0.4, 0.15, 0.13, 1)
		_PoreOccScale ("Pore Occ Scale", Range(0,1)) = 0.5 
		

		[Header(Specular)]
		_Normal2GlossFactor ("Normal to Gloss Factor", Range(0,1)) = 0.5

		[KeywordEnum(Everything, AlbedoColor, Diffuse, Specular, AmbientDiffuse, AmbientReflectance, Lightmap)] _Debug("Debug", Float) = 0

		[Header(TempParams_Shadow)]
		_ShadowmapSize ("ShadowmapSize", Range(256, 4096)) = 2048

		[Header(TempParams_Tonemapping)]
		toneMappingFactor  ("ToneMapping Factor", Range(0.1, 5.0)) = 1.0
		toneMappingLerp ("ToneMapping Lerp", Range(0.0, 1.0)) = 1.0

	}
	SubShader
	{
		Tags { "RenderType"="Opaque"  "LIGHTMODE" = "ForwardBase" }

		Pass
		{
			
			CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#pragma fragmentoption ARB_precision_hint_fastest
						
			#include "UnityCG.cginc"
			#include "Alice_Lighting_Utility.cginc"
			
			sampler2D _AlbedoTex;
			sampler2D _NormalRoughnessTex;

			sampler2D _FluidNormalTex;
			half4 _FluidNormalTex_ST;

			sampler2D _MaskTex;

			sampler2D _ParralxHeight;
			

			half _RefractionIndex;
			half _PupilSize;

			half4 _AlbedoColor;
			fixed _NormalIntensity;
			fixed _FluidNormalIntensity;
			fixed _SSSStrength;
			half4 _NormalBlurTuner;
			fixed _Roughness;
			float _Curvature;
			fixed _AO2SpecOccPower;
			fixed _PoreOccScale;
			half _Normal2GlossFactor;
			half4 _AOColorBleeding;

			half toneMappingFactor;
			fixed toneMappingLerp;

			struct appdata
			{
				float4 vertex		: POSITION;
				fixed2 uv			: TEXCOORD0;
				float2 uv1			: TEXCOORD1;
				fixed2 lightmapUV	: TEXCOORD2;
				float3 normal		: NORMAL;
				float3 tangent		: TANGENT;

			};

			struct v2f
			{
				float4 pos : SV_POSITION;				
				fixed4 UVs : TEXCOORD0;
				half3 vPos : TEXCOORD1;
				half3 viewDir : TEXCOORD8;
				half3 wPos : TEXCOORD2;
				half3 wNormal : TEXCOORD3;
				half3 wTangent : TEXCOORD4;
				half3 wBinormal : TEXCOORD5;
				half3 shadowUV0 : TEXCOORD6;
				half3 shadowUV1 : TEXCOORD7;

			};




			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				// o.wPos = mul(unity_ObjectToWorld, half4(v.vertex.xyz, 1)).xyz;
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				half2 uv2 = 0;

				o.UVs = half4(v.uv, uv2);

				// TODO - unity_ObjectToWorld should be replaced by the inverse transpose matrix!!!!
				o.wNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));				
				o.wTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent));
				o.wBinormal = -cross(o.wNormal, o.wTangent);
				o.shadowUV0 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix0, _ShadowNormalBias0, _ShadowDistanceBias0);
				o.shadowUV1 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix1, _ShadowNormalBias1, _ShadowDistanceBias1);

				return o;
			}



			fixed4 frag (v2f i) : SV_Target
			{
				/*
				half3 wV = normalize(_WorldSpaceCameraPos - i.wPos);
				// return half4(wV,1);

				//////////////// Sample Textures ////////////////////////////	
				fixed4 output = 1;
				fixed height = tex2D(_ParralxHeight, i.UVs.xy).r;
				
				half2 uv = ParralaxUV (i.UVs.xy, height, wV, i.wNormal, _RefractionIndex);

				// return half4(uv,0,1);
				float2 delta = float2(0.5, 0.5) - i.UVs.xy;
				// Calculate pow(distance,2) to center (pythagoras...)
				float factor = (delta.x*delta.x + delta.y*delta.y); 
				// Clamp it in order to mask our pixels, then bring it back into 0 - 1 range
				// Max distance = 0.15 --> pow(max,2) = 0.0225
				factor = saturate(0.02 - factor) * 44.444;
				uv += delta * factor * _PupilSize;

				fixed4 albedoTex = tex2D(_AlbedoTex, uv);
				// return albedoTex;
				fixed3 albedo = _AlbedoColor.rgb * albedoTex;
				fixed AO = albedoTex.a;

				fixed4 masks = tex2D(_MaskTex, uv);
				fixed irisMask = masks.r;

				// Sample and unpack normal 
				fixed4 normalRoughnessMap = tex2D(_NormalRoughnessTex, uv);
				fixed3 fluidNormalMap = tex2D(_FluidNormalTex, uv * _FluidNormalTex_ST.x).rgb;
				fluidNormalMap = lerp(half3(0.5,0.5,1.0), fluidNormalMap, _FluidNormalIntensity);

				fixed roughness = normalRoughnessMap.a * _Roughness;

				half3 normalMapColor = normalRoughnessMap.rgb;
				half3 blurredNormalMapColor = tex2Dbias(_NormalRoughnessTex, half4(uv, 0, _SSSStrength)).xyz;

				half3 combinedFluidNomralMapColor = lerp(fluidNormalMap.rgb, half3(0.5, 0.5, 1.0), irisMask) * 2.0 - 1.0;

				//////////////// Prepare Normal and Tangent Space ////////////////////////////
				half3 wN = normalize(i.wNormal);
				half3 wB = normalize(i.wBinormal);
				half3 wT = normalize(i.wTangent);
				
				float curvature = ComputeCurvature(wN, i.wPos, _Curvature);	
				fixed3x3 tangentMatrix = float3x3(wT.x, wB.x, wN.x,
												  wT.y, wB.y, wN.y,
												  wT.z, wB.z, wN.z);
				
				wN = mul(tangentMatrix, normalMapColor * 2.0 - 1.0);
				half3 wNBlur = mul(tangentMatrix, blurredNormalMapColor * 2.0 - 1.0);
				half3 wFluidN = mul(tangentMatrix, combinedFluidNomralMapColor);

				half NdotV = saturate(dot(wN, wV));
				half fluidNdotV = saturate(dot(wFluidN, wV));

				half3 wFluidReflectDir = -reflect(wV, fluidNdotV);

				half SpecOcc = pow(AO, _AO2SpecOccPower);

				//////////////// Ambient Lighting //////////////////////////// 
				half3 ambientSpecularLighting = texCUBElod(_ReflectProbeTex, half4(wFluidReflectDir, roughness * 5)) * (pow(1.0 - fluidNdotV, 5)) * SpecOcc;
				half3 ambientDiffuseLighting = ShadeSH9(float4(wNBlur, 1));

				//////////////// Lighting and Shadows ////////////////////////////
				half3 shadowUVs[2] = {i.shadowUV0, i.shadowUV1};
				float4x4 shadowMatrix[2] = {_ShadowProjectionMatrix0, _ShadowProjectionMatrix1};
				sampler2D shadowmapSampler[2] = {_Shadowmap0, _Shadowmap1};
				half3 lightDirection[2] = {_DirLightFwd0, _DirLightFwd1};
				half4 dirLightColorIntensity[2] = {_DirLightColorIntensity0, _DirLightColorIntensity1};

				half3 directionalDiffuseLighting = 0;
				half3 specularLighting = 0;

				half shadow = 1;
				
				for (int j = 0; j < 2; j++)
				{
					half3 wL = lightDirection[j];
					half3 wH = normalize(wL + wV);
					half NdotL = saturate(dot(wN, wL));
					half fluidNdotL = saturate(dot(wFluidN, wL));
					
					half NdotH = saturate(dot(wN, wH));
					half fluidNdotH = saturate(dot(wFluidN, wH));

					half VdotH = saturate(dot(wV, wH));

					fixed2 shadowAndThickness = PCF(shadowmapSampler[j], shadowUVs[j], 3);
					shadow = min(shadow, shadowAndThickness.x);
					
					specularLighting += GGXSpecularLighting(fluidNdotL, fluidNdotV, fluidNdotH, VdotH, roughness) * shadow * SpecOcc;  
					// specularLighting = 0;
					directionalDiffuseLighting += SkinDiffuseLighting(1.0, wN, wNBlur, wL, wV, shadow, curvature, irisMask, _NormalBlurTuner, dirLightColorIntensity[j]);
				}
				
				// shadow = lerp(0.0,1.0, shadow);
				output.rgb = (directionalDiffuseLighting + ambientDiffuseLighting * AO) * albedo + specularLighting + ambientSpecularLighting * lerp(0.5,1.0, shadow);
				output.rgb = lerp(output.rgb, ACESToneMapping(output.rgb, toneMappingFactor), toneMappingLerp);
				
				// output.rgb = (ambientSpecularLighting  * shadow * AO) * albedo;
				
				
				return output;	
				*/
				return 0;

			}
			ENDCG
		}	
	}

	Fallback "Diffuse"
}
