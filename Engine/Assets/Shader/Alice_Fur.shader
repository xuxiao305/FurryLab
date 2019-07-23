
Shader "Alice/Alice_Fur"
{
	Properties
	{	
        [Header(Shadow)]
        _ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0
        _ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5
        _AddShadowDistanceBias ("Shadow Distance Bias", Range(0.0, 1.0)) = 0.5
        
		[Header(Textures)]
		_AlbedoTex ("Albedo Map", 2D) = "white" {}
		
		[NoScaleOffset]
		_DirectionTex ("Fur Direction Map", 2D) = "white" {}
		_DirectionInt ("Fur Direction Intensity", Range(0, 3.0)) = 1.0
		_OffsetNoise ("Offset Noise", Range(0, 2.0)) = 1.0

		[NoScaleOffset]
		_FurTex ("Fur Map", 2D) = "white" {}
		_BaseMeshVertCount ("Base Mesh Vert Count", Float) = 100


		[Header(Fur Properties)]
		_FurReduction ("Fur Reduction", Range(0.2,0.3))= 1
		_FurClumping ("Fur FurClumping", Range(0.0, 1.0)) = 0.5
		_FurLength("Fur Length", Range(0.01, 0.1)) = 0.25
		
		_FurTiling("Fur Tiling", Range(1.0,10.0)) = 1.0

		_TranslucentColor ("Translucent Color", Color) = (1, 1, 1, 1)

		[Header(Materials Properties)]
		_RootColor ("Root Color", Color) = (1, 1, 1, 1)
		_TipColor ("Tip Color", Color) = (1, 1, 1, 1)
		_RootShadowing ("Root Shadowing", Range(0, 1.0)) = 0.5
		
		_Gloss("Gloss", Range(0.0,1.0)) = 0.5
		_SpecularScale("Specular Scale", Range(0.0, 2.0)) = 1.0
		
		_SpecularShifting("Specular Spacing", Range(0.0, 1.0)) = 0.5

		_ShadingWarp("Shading Warp", Range(0.0,1.0)) = 0.5
		_EdgeFalloff("Edge Falloff", Range(0.0,5.0)) = 1.0

		_PushShellToTip("Push Fur Shell to Tip", Range(0.0,0.75)) = 0.5

		_ReflectProbeTex ("ReflectProbeTex", CUBE) = "white"{}


		[Header(Side Fur)]
		_Size("Size", Range(0, 0.2)) = 0.05
		_ForceX("ForceX", Range(-1, 1)) = 0.5
		_ForceY("ForceY", Range(-1, 1)) = -10
		_ForceZ("ForceZ", Range(-1, 1)) = 0.5
		_Stiffness("Stiffness", Range(1,10)) = 2.0
		_Turbluance("Turbluance", Range(0,10)) = 2.0


		[Header(Dynamic)]
		_FurStiff("Fur Stiffness", Range(0, 1.0)) = 0.1
		_WindDirection("Wind Direction", Color) = (1, 1, 1, 1)

		[KeywordEnum(Everything, AlbedoColor, Diffuse, Specular, AmbientDiffuse, AmbientReflectance, Lightmap)] _Debug("Debug", Float) = 0


	}
	SubShader
	{
		Tags {"RenderType"="Opaque" "LIGHTMODE"="ForwardBase" "ObjectType"="Fur"}
		Pass
		{
			////Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			CULL Off
			//AlphaTest Greater 0.1
			CGPROGRAM
						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma fragmentoption ARB_precision_hint_fastest		
			#include "UnityCG.cginc"
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 0

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}

		Pass
		{
			////Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM
						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 1

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}
		Pass
		{
			////Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM
						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING
			#define FUR_SHADING
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 2

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM


			#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 3

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}

		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

			#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 4

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 5

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}

		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 6

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}
		
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 7

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);
				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 8

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 9

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		/*
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 10

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 11

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 12

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 13

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 14

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		Pass
		{
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM

						#define EXP_FALLOFF_SHADOW
			#define FUR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "Alice_Fur_Utility.cginc"
			
			IMPORT_FUR_UNIFORM
			
			#define INDEX 15

			v2f_generic vert (appdata_generic v)
			{
				v2f_generic o;
				o = FurPass_VS(v, INDEX, _WorldSpaceLightPos0, colorLerpFactorList[INDEX]);
				return o;
			}

			fixed4 frag (v2f_generic i) : SV_Target
			{
				fixed4 output = FurPass_PS(i, INDEX, colorLerpFactorList[INDEX]);

				return output;
			}
			ENDCG	
		}
		*/
	}

	Fallback "Diffuse"
}
