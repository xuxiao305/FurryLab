Shader "Alice/Alice_Skin"
{
	Properties
	{
        [Header(Shadow)]
        _ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0
        _ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5
        _AddShadowDistanceBias ("Shadow Distance Bias", Range(0.0, 1.0)) = 0.5
        
		_AlbedoTex ("Albedo, Roughness", 2D) = "white" {}
		_AlbedoColor ("Albedo Color", Color) = (1, 1, 1, 1)

		_NormalTex ("Normal Texture", 2D) = "black"{}
		_NormalIntensity ("Normal Intensity", Range(0,1.0))= 1

		_BentNormalTex ("Bent Normal Texture", 2D) = "black"{}
		_BentNormalIntensity ("Bent Normal Intensity", Range(0,1.0))= 1

		// Detail Normal Map
		_DetailNormalTex ("Detail Normal Texture", 2D) = "black"{}
		_DetailNormalIntensity ("Detail Normal Intensity", Range(0, 1.0))= 1

		_ScatteringTex ("Scattering Texture", 2D) = "black"{}
		_MaskTex ("DetailMask, Thickness, AO, SSS", 2D) = "white"{}


		_DetailMasking ("Detail Masking", Range(0.0,1)) = 1

		
		_ReflectProbeTex ("ReflectProbeTex", CUBE) = "white"{}


		[Header(Translucency)]
		_Thickness ("Thickness",  Range(0,2)) = 1
		_TranslucentTex ("Translucent Texture", 2D) = "black"{}
		_Translucency ("Translucency", Range(0.0, 10.0)) = 0.5


		[Header(Occlusion)]
		_AO2SpecOccPower ("AO to SpecOcc Power", Range(1,10)) = 5 
		_AOColorBleeding ("AO Color Bleeding", Color) = (0.4, 0.15, 0.13, 1)
		_PoreOccScale ("Pore Occ Scale", Range(0,1)) = 0.5 
		

		[Header(Specular)]
		_Roughness ("Roughness", Range(0.0,3.0)) = 1
		_Normal2GlossFactor ("Normal to Gloss Factor", Range(0,1)) = 0.5

		[KeywordEnum(Everything, AlbedoColor, Diffuse, Specular, AmbientDiffuse, AmbientReflectance, Lightmap)] _Debug("Debug", Float) = 0

		[Header(TempParams_Shadow)]
		_ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0

		[Header(TempParams_Tonemapping)]
		toneMappingFactor  ("ToneMapping Factor", Range(0.1, 5.0)) = 1.0
		toneMappingLerp ("ToneMapping Lerp", Range(0.0, 1.0)) = 1.0

		[Header(TempParams_IBL)]
		_IBLSampleCount ("IBL Sampling Count", range(1, 64)) = 1
		_HorizonFade ("Horizon Fade", range(0, 2.0)) = 1.3
		// _EnvRotation ("Envrionment Rotation", range(0, 1.0)) = 0

		[Header(SSS)]
		_SSSStrength ("SSS Strength", Range(0, 8)) = 1
		_NormalBlurTuner ("Normal Blur Tuner", Color) = (1.0, 0.5, 0.0)
		_SSSMaskingFactor ("SSS Masking Factor", Range(0,1)) = 0.5
		_Curvature("Curvature", Range(0.000,0.025)) = 0.015
		_AmbientSSS ("Ambient SSS", Range(0, 1)) = 1.0


	}
	SubShader
	{
		Tags {"RenderType"="Opaque" "ObjectType"="Default" "LIGHTMODE"="ForwardBase"}
		Pass
		{
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#define GENERIC_SKIN_SHADING

			#pragma fragmentoption ARB_precision_hint_fastest
						
			#include "UnityCG.cginc"
			#include "Alice_Lighting_Utility.cginc"
			
			sampler2D _AlbedoTex;
			sampler2D _SSSMask;
			sampler2D _VeinTex;
			sampler2D _NormalTex;
			sampler2D _BentNormalTex;
			sampler2D _DetailNormalTex;	
			half4 _DetailNormalTex_ST;
			sampler2D _MaskTex;
			
			half4 _AlbedoColor;
			half4 _VeinColor1;
			half4 _VeinColor2;
			half4 _VeinColor3;
			half4 _FreckleColor;
			half _VeinLUTOffset;
			fixed _NormalIntensity;
			fixed _BentNormalIntensity;
			fixed _DetailNormalIntensity;
			fixed _SSSStrength;
			half4 _NormalBlurTuner;
			fixed _Roughness;
			fixed _DetailMasking;
			float _Curvature;
			fixed _AO2SpecOccPower;
			fixed _PoreOccScale;
			half _Normal2GlossFactor;
			half4 _AOColorBleeding;



			half toneMappingFactor;
			fixed toneMappingLerp;

			fixed _AmbientSSS;

			
			half _Thickness;	

			struct appdata
			{
				float4 vertex		: POSITION;
				fixed2 uv			: TEXCOORD0;
				float2 uv1			: TEXCOORD1;
				float3 normal		: NORMAL;
				float3 tangent		: TANGENT;
				float4 color 		: COLOR;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;				
				fixed4 UVs : TEXCOORD0;
				half3 vPos : TEXCOORD1;
				half3 wPos : TEXCOORD2;
				half3 wNormal : TEXCOORD3;
				half3 wTangent : TEXCOORD4;
				half3 wBinormal : TEXCOORD5;
				half3 shadowUV0 : TEXCOORD6;
				half3 shadowUV1 : TEXCOORD7;
				half4 color : COLOR;

			};


			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.vPos = UnityObjectToViewPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.UVs = half4(v.uv, 1.0, 1.0);

				// TODO - unity_ObjectToWorld should be replaced by the inverse transpose matrix!!!!
				o.wNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));				
				o.wTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent));
				o.wBinormal = -cross(o.wNormal, o.wTangent);

				o.shadowUV0 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix0, _ShadowNormalBias0, _ShadowDistanceBias0);
				o.shadowUV1 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix1, _ShadowNormalBias1, _ShadowDistanceBias1);
				o.color = v.color;
				return o;
			}

			fixed frag (v2f i) : SV_Target
			{
                fixed4  output = 1;
                fixed4  albedoTex = tex2D(_AlbedoTex, i.UVs.xy);
                fixed3  albedo = _AlbedoColor.rgb * albedoTex;
                

                fixed4  normalAOTex = tex2D(_NormalTex, i.UVs.xy);
                fixed4  maskTex = tex2D(_MaskTex, i.UVs.xy);


                half3   normal     = normalAOTex.xyz * 2.0 - 1.0;
                        normal     = normalize(half3(normal.xy * _NormalIntensity, normal.z));

                fixed   AO = min(normalAOTex.a, i.color.a);   
                fixed   metalness  = maskTex.r * _Metalness;
                fixed   glossiness = maskTex.g * _Glossiness;

                fixed   microVis = 1.0;
                fixed   thickness = _Thickness;
                fixed   multiScatteringInt = _MultiScatteringInt;

                half3   wB = normalize(cross( i.wTangent, i.wNormal));
                half3   wT = normalize(i.wTangent);
                half3   wN = normalize(i.wNormal);


                half3 lightingResult = GenericLighting(albedo, normal, glossiness, metalness, microVis, AO, thickness, multiScatteringInt,
                                                          wN, wT, wB, i.wPos,
                                                          i.shadowUV0, i.shadowUV1,
                                                          i.UVs.xy, 
                                                          0.0, 0.0, 0.0);

                return fixed4(lightingResult, 1.0);



			}
			fixed4 frag1 (v2f i) : SV_Target
			{
				//////////////// Sample Textures ////////////////////////////
				fixed4 output = 1;
				fixed4 albedoTex = tex2D(_AlbedoTex, i.UVs.xy);
				fixed3 albedo = _AlbedoColor.rgb * albedoTex;
				fixed AO = min(albedoTex.a, i.color.a);

				fixed4 maskTex = tex2D(_MaskTex, i.UVs.xy);
				
				fixed detailMask = lerp(1.0, maskTex.r, _DetailMasking);

				fixed thicknessMask = pow(maskTex.g, _Thickness);

				fixed SSSMask = maskTex.a;
				
				// Sample and unpack normal 
				fixed4 normalRoughnessTex = tex2D(_NormalTex, i.UVs.xy);
				fixed3 normalMapColor = normalRoughnessTex.xyz;
				// normalMapColor.g = 1 - normalMapColor.g;
				fixed roughness = normalRoughnessTex.a * _Roughness;

				fixed3 bentNormalMapColor = tex2D(_BentNormalTex, i.UVs.xy).xyz;
				bentNormalMapColor.y = 1.0 - bentNormalMapColor.y;
				normalMapColor = lerp(normalMapColor, bentNormalMapColor, _BentNormalIntensity);

				fixed3 detailNormalMapColor = tex2D(_DetailNormalTex, i.UVs.xy * _DetailNormalTex_ST.x).xyz;
				detailNormalMapColor.g = 1 - detailNormalMapColor.g;
				detailNormalMapColor = lerp(half3(0.5,0.5,1), detailNormalMapColor, _DetailNormalIntensity * detailMask);

				fixed3 blurredNormalMapColor = tex2Dbias(_NormalTex, half4(i.UVs.xy, 0, _SSSStrength)).xyz;
				// blurredNormalMapColor.y = 1 - blurredNormalMapColor.y;

				fixed3 blurredBentNormalMapColor = tex2Dbias(_BentNormalTex, half4(i.UVs.xy, 0, _SSSStrength)).xyz;
				blurredBentNormalMapColor.g = 1 - normalMapColor.g;

				blurredBentNormalMapColor = lerp(blurredNormalMapColor, blurredBentNormalMapColor, _BentNormalIntensity);

				fixed3 blurredDetailNormalTexBlur = tex2Dbias(_DetailNormalTex, half4(i.UVs.xy, 0, _SSSStrength)).xyz;
				blurredDetailNormalTexBlur = lerp(half3(0.5,0.5,1), blurredDetailNormalTexBlur,  _DetailNormalIntensity * detailMask);

				half3 combinedNomal = CombineNormal(normalMapColor, detailNormalMapColor);

				half3 blurredCombinedNormal = CombineNormal(blurredNormalMapColor, blurredDetailNormalTexBlur);	

				half roughnessFromNormal = Normal2Gloss(CombineNormal(normalMapColor, detailNormalMapColor) * 0.5 + 0.5, _Normal2GlossFactor);
				roughness = (roughness * roughnessFromNormal);

				combinedNomal = normalize(combinedNomal);
				blurredCombinedNormal = normalize(blurredCombinedNormal);


				//////////////// Prepare Normal and Tangent Space ////////////////////////////
				half3 wN = normalize(i.wNormal);
				half3 wB = normalize(i.wBinormal);
				half3 wT = normalize(i.wTangent);
				half3 wV = normalize(_WorldSpaceCameraPos - i.wPos);
				

				float curvature = ComputeCurvature(wN, i.wPos, _Curvature);	
				fixed3x3 tangentMatrix = float3x3(wT.x, wB.x, wN.x,
												  wT.y, wB.y, wN.y,
												  wT.z, wB.z, wN.z);

				
				wN = mul(tangentMatrix, combinedNomal.xyz);
				half3 wNBlur = mul(tangentMatrix, blurredCombinedNormal.xyz);

				half NdotV = saturate(dot(wN, wV));
				half3 wReflectDir = -reflect(wV, wN);

				//////////////// Ambient Lighting ////////////////////////////
				half poreSpecularOcc = saturate(lerp(1.0, pow(detailNormalMapColor.b, 15), _PoreOccScale * 10));
				half specularOcc = lerp(pow(AO, _AO2SpecOccPower), poreSpecularOcc, saturate(NdotV * NdotV)) ;

				// half3 ambientSpecularLighting = texCUBElod(_ReflectProbeTex, half4(wReflectDir, roughness * 5.0)) * lerp(0.04, 1.0, (pow(1.0 - NdotV, 5))) * specularOcc;
				half3 ambientSpecularLighting = computeIBL(_ReflectProbeTex, _EnvRotation, 7.0, _IBLSampleCount, wN, wN, wT, wB, wV, 0.04, roughness * 1.5 / 2.0) * specularOcc;

				half3 wNBlurR = lerp(wN, wNBlur, (_NormalBlurTuner.r));
				half3 wNBlurG = lerp(wN, wNBlur, (_NormalBlurTuner.g));
				half3 wNBlurB = lerp(wN, wNBlur, (_NormalBlurTuner.b));

				half ambientDiffuseLightingR = ShadeSH9(float4(rotate(wNBlurR, _EnvRotation), 1));
				half ambientDiffuseLightingG = ShadeSH9(float4(rotate(wNBlurG, _EnvRotation), 1));
				half ambientDiffuseLightingB = ShadeSH9(float4(rotate(wNBlurB, _EnvRotation), 1));

				half3 ambientDiffuseLighting = half3(ambientDiffuseLightingR, ambientDiffuseLightingG, ambientDiffuseLightingB);

				ambientDiffuseLighting = lerp(ambientDiffuseLightingB, ambientDiffuseLighting, _AmbientSSS);
				
				half ambientTranslucency = ShadeSH9(float4(-rotate(wNBlurR, _EnvRotation), 1)) * (1.0 - thicknessMask); 
				half3 ambientTranslucentLighting = tex2D(_TranslucentTex, half2(ambientTranslucency, 0.5));

				half3 colorBleedingAO = pow(AO, 1.0 - _AOColorBleeding.rgb);
				half3 finalAO = lerp(AO, colorBleedingAO, _AOColorBleeding.a);
				finalAO = pow(finalAO, 1.5);

				//////////////// Lighting and Shadows ////////////////////////////
				
				half3 shadowUVs[2] = {i.shadowUV0, i.shadowUV1};
				float4x4 shadowMatrix[2] = {_ShadowProjectionMatrix0, _ShadowProjectionMatrix1};
				sampler2D shadowmapSampler[2] = {_Shadowmap0, _Shadowmap1};
				half3 lightDirection[2] = {_DirLightFwd0, _DirLightFwd1};
				half4 dirLightColorIntensity[2] = {_DirLightColorIntensity0, _DirLightColorIntensity1};
				fixed shadowMapSize[2] = {_ShadowmapSize0, _ShadowmapSize1};

				half3 directionalDiffuseLighting = 0;
				half3 TranslucencyColor = 0;
				half3 specularLighting = 0;
				half shadowTest = 1;

				for (int i = 0; i < 1; i++)	
				{
					half3 wL = lightDirection[i];
					half3 wH = normalize(wL + wV);
					half NdotL = saturate(dot(wN, wL));
					
					half NdotH = saturate(dot(wN, wH));
					half VdotH = saturate(dot(wV, wH));

					fixed2 shadowAndThickness = PCF(shadowmapSampler[i], shadowUVs[i], 3, shadowMapSize[i]);

					fixed shadow = shadowAndThickness.x;
					shadowTest *= shadow;

					half thickness = max(thicknessMask, shadowAndThickness.y);
					
					specularLighting += 0.8 * GGXSpecularLighting(0.04, NdotL, NdotV, NdotH, VdotH, roughness, dirLightColorIntensity[i]) * specularOcc * shadow;  
					specularLighting += 0.2 * GGXSpecularLighting(0.04, NdotL, NdotV, NdotH, VdotH, pow(roughness,1.5), dirLightColorIntensity[i]) * specularOcc * shadow;  

					directionalDiffuseLighting += SkinDiffuseLighting(SSSMask, wNBlurR, wNBlurG, wNBlurB, wL, wV, shadow, curvature, thickness, _NormalBlurTuner, dirLightColorIntensity[i]);
					TranslucencyColor += _Translucency * TranslucencyLighting(wL, wV, wN, thickness, dirLightColorIntensity[i]);
				}
				// albedo = 0.25;
				albedo = lerp(albedo, dot(albedo, 0.5), 0.5);
				output.rgb = (directionalDiffuseLighting * finalAO + ambientDiffuseLighting * finalAO + 
				              TranslucencyColor + ambientTranslucentLighting) * 
								albedo + specularLighting + ambientSpecularLighting;

				output.rgb = lerp(output.rgb, ACESToneMapping(output.rgb, toneMappingFactor), toneMappingLerp);
				

				//output.rgb = ambientDiffuseLighting * 0.5 * lerp(0.5, 1, shadowTest);
				return output;
			}
			ENDCG
		}		
	}
}
