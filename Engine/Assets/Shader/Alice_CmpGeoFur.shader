Shader "Alice/Alice_ComputerGeoFur"
{
	Properties
	{
        [Header(Shadow)]
        _ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0
        _ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5
        _AddShadowDistanceBias ("Shadow Distance Bias", Range(0.0, 1.0)) = 0.5

		[Header(TextureSetting)]
		_FurIDMap("Fur ID Map", 2D) = "white" {}
		_FurClumpingMap("Fur Clumping Map", 2D) = "white" {}
		// _FurIDMap("Fur ID Map", 2D) = "white" {}
		_FurFuzzyMap("Fur Fuzzy Map", 2D) = "white" {}

		_FurPosTex("Fur Position Map", 2D) = "white" {}
		_FurStrandTex ("Fur Strand Map", 2D) = "white" {}


		[Header(Color)]
		_TipColor1 ("Tip1 Color", Color) = (1, 1, 1, 1)
		_RootColor1 ("Root1 Color", Color) = (1, 1, 1, 1)
		_TipColorBlendWidth ("Tip Color Blend Width", Range(0.0, 0.3)) = 0.25
		_TipColorBlendOffset ("Tip Color Blend Offset", Range(0.0, 0.2)) = 0.0

		_MutantColor ("Mutant Color", Color) = (1, 1, 1, 1)
		_MutantRange ("Mutant Range", Range(0.0, 1.0)) = 0.5




		[Header(Common)]
		_AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.1


		[Header(Shading)]
		_DetailNormalIntensity("Detail Normal Intensity", Range(0.0, 0.5)) = 1.0
		_TubeNormalIntensity("Tube Normal Intensity", Range(0.0, 0.5)) = 1.0
		_Gloss("Gloss", Range(0.0,1.0)) = 0.5
		_SpecularScale("Specular Scale", Range(0.0, 1.0)) = 1.0
		_SpecularShifting("Specular Shift", Range(-1.0, 1.0)) = 0.5

	}
	SubShader
	{
		CULL Off
		AlphaToMask On
		Tags {"RenderType"="Opaque" "ObjectType"="CmpGeometryFur" "LIGHTMODE"="ForwardBase"}

		Pass
		{  
			CGPROGRAM
			#define EXP_FALLOFF_SHADOW
			#define GEO_FUR_SHADING
			#pragma target 5.0
			#include "UnityCG.cginc"
			#include "Alpha.cginc"
			#include "Alice_Lighting_Utility.cginc"
			#include "Alice_CmpGeoFur_Utility.cginc"
			#include "Random.cginc"

			#pragma vertex VS_Main_CmpGeoFur
			#pragma geometry GS_Main_CmpGeoFur
			#pragma fragment FS_Main_CmpGeoFur




			ENDCG

		}
	}

	Fallback Off
}