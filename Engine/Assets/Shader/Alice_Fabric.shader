
Shader "Alice/Alice_Fabric"
{
 	Properties
    {
        [Header(Shadow)]
        _ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0
        _ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5
        _AddShadowDistanceBias ("Shadow Distance Bias", Range(0.0, 1.0)) = 0.5

    	[Header(Common)]
        _TearingInt ("Tear Int", Range(0.0,1.0)) = 1.0
        _BleachInt ("Bleach Int", Range(0.0,1.0)) = 1.0
        _PatinaInt ("Patina Int", Range(0.0,1.0)) = 1.0
        _PatternInt ("Pattern Int", Range(0.0,1.0)) = 1.0

        [Header(TextureSettings)]
        _C_DetailMapCompositionTex ("Detail Map Composition", 2D) = "white" {}
        _C_DetailDamageTex ("Detail Map Damage ", 2D) = "white" {}
        _C_PatternMaskTex ("Pattern Mask", 2D) = "white" {}
        _TearingMaskTex ("Tearing Mask", 2D) = "white" {}
        _WearyingMaskTex ("Wearying Mask", 2D) = "white" {}
        _TintingDetailMaskTex ("Tinting Mask", 2D) = "white" {}
        _BaseColorTex ("Base Color Mask", 2D) = "white" {}
        _NormalGlossTex ("Normal Gloss Map", 2D) = "white" {}


        [Header(Basic)]
        _C_ColorTinting1H ("Tinting Color 1 H", Color) = (1, 1, 1, 1)
        _C_ColorTinting1V ("Tinting Color1 V", Color) = (1, 1, 1, 1)
        _C_ColorTinting2H ("Tinting Color2 H", Color) = (1, 1, 1, 1)
        _C_ColorTinting2V ("Tinting Color2 V", Color) = (1, 1, 1, 1)
        _C_PatinaColor1 ("Patina Color 1", Color) = (1, 1, 1, 1)
        _C_PatinaColor2 ("Patina Color 2", Color) = (1, 1, 1, 1)
        _C_BleachColor1 ("Bleach Color 1", Color) = (1, 1, 1, 1)
        _C_BleachColor2 ("Bleach Color 2", Color) = (1, 1, 1, 1)

        _C_DetailIndex1 ("Detail Index 1", Range(0.0,16.0)) = 0.0
        _C_DetailIndex2 ("Detail Index 2", Range(0.0,16.0)) = 0.0

        _C_DetailTiling1 ("Detail Tiling 1", Range(10.0,100.0)) = 50.0  
        _C_DetailTiling2 ("Detail Tiling 2", Range(10.0,100.0)) = 50.0  
        
        [Header(Alpha)]
        _Thickness ("Thickness", Range(0.0,1.0)) = 0.5
        _AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.1
        _AlphaDither("Alpha Dither", Range(0, 1)) = 0.0
        _AlphaDitherSize ("Alpha Dither Size", Range(1, 5)) = 3 


        [Header(Physic)]
        _DetailShadowing ("Detail Shadow", Range(0.0,1.0)) = 0.5

        _C_DamageDetailTiling ("Detail Damage Tiling", Range(1.0,5.0)) = 2.0  

        _BumpSharpness("Bump Sharpness", Range(0.5, 2.0)) = 1.0
        _C_Gloss  ("Gloss", Range(0.0,1.0)) = 1.0  
        _C_Retro  ("Retro", Range(0.0,1.0)) = 1.0  
        _C_DetailHeight1  ("Detail Height 1", Range(0.0,2.0)) = 1.0  
        _C_DetailHeight2  ("Detail Height 2", Range(0.0,2.0)) = 1.0  


        [Header(Weathering)]
        _C_WearyDistortion ("Weary Distortion", Range(0.0,1.0)) = 1.0  
        _C_TearHeight  ("Tear Height", Range(0.0,1.0)) = 1.0  


        [Header(Pattern)]
        _C_PatternHeight  ("Pattern Tiling X", Range(0.0,1.0)) = 1.0  
        _C_PatternColor1  ("Patina Color 1", Color) = (1, 1, 1, 1)
        _C_PatternColor2  ("Patina Color 2", Color) = (1, 1, 1, 1)
        _C_PatternColor3  ("Patina Color 3", Color) = (1, 1, 1, 1)
        _C_PatternDirection  ("Pattern Tiling X", Range(-1.0,1.0)) = 1.0  
        _C_PatternMetalness  ("Pattern Tiling X", Range(0.0,1.0)) = 1.0  
	}

	SubShader
	{
		Tags {"RenderType"="Opaque" "LIGHTMODE"="ForwardBase" "ObjectType"="Default"}
		Pass
		{
			////Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			//AlphaTest Greater 0.1
			CGPROGRAM
			#define GENERIC_PBR_SHADING

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma fragmentoption ARB_precision_hint_fastest		

			// [Header(TextureSettings)]
			sampler2D _C_DetailMapCompositionTex;
			sampler2D _C_DetailDamageTex;
			sampler2D _C_PatternMaskTex;
			half4 _C_PatternMaskTex_ST;
			sampler2D _TearingMaskTex;
			sampler2D _WearyingMaskTex;
			sampler2D _TintingDetailMaskTex;
			sampler2D _BaseColorTex ;
			sampler2D _NormalGlossTex;

			// [Header(Common)]
			fixed _TearingInt;
			fixed _BleachInt;
			fixed _PatinaInt;
			fixed _PatternInt;

			// [Header(Basic)]
			fixed4 _C_ColorTinting1H ;
			fixed4 _C_ColorTinting1V;
			fixed4 _C_ColorTinting2H ;
			fixed4 _C_ColorTinting2V ;
			fixed4 _C_PatinaColor1 ;
			fixed4 _C_PatinaColor2 ;
			fixed4 _C_BleachColor1 ;
			fixed4 _C_BleachColor2;
			fixed _DetailShadowing ;



			// [Header(Physic)]
			fixed _C_DetailIndex1;
			fixed _C_DetailIndex2 ;
			fixed _C_DetailTiling1 ;
			fixed _C_DetailTiling2;
			fixed _C_DamageDetailTiling ;
			fixed _C_WearyDistortion ;
			fixed _C_TearHeight;

			half _BumpSharpness;
			half _C_Gloss ;
			half _C_Retro ;
			half _C_DetailHeight1 ;
			half _C_DetailHeight2 ;


			// [Header(Pattern)]
			fixed _C_PatternHeight  ;
			fixed4 _C_PatternColor1 ;
			fixed4 _C_PatternColor2  ;
			fixed4 _C_PatternColor3 ;
			fixed _C_PatternDirection ;
			fixed _C_PatternMetalness;


			#include "UnityCG.cginc"
			#include "Alpha.cginc"
			#include "Alice_CostumeSurface_Utility.cginc"
			#include "Alice_Lighting_Utility.cginc"
			

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half2 uv1 : TEXCOORD1;
                half3 normal : NORMAL;
                half3 tangent : TANGENT;
                half4 color : TEXCOORD4;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half4  UVs : TEXCOORD0;
                half3  vPos : TEXCOORD1;
                half3  wPos : TEXCOORD2;
                half3  wNormal : TEXCOORD3;
                half3  wTangent : TEXCOORD4;
                half3  shadowUV0 : TEXCOORD6;
                half3  shadowUV1 : TEXCOORD7;
                half4  color : COLOR;
                
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.vPos = UnityObjectToViewPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.UVs = half4(v.uv, v.uv1);

                // TODO - unity_ObjectToWorld should be replaced by the inverse transpose matrix!!!!
                o.wNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));                
                o.wTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent));

                o.shadowUV0 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix0, _ShadowNormalBias0, _ShadowDistanceBias0);
                o.shadowUV1 = shadowingUV(v.vertex.xyz, v.normal, _ShadowProjectionMatrix1, _ShadowNormalBias1, _ShadowDistanceBias1);
                o.color = v.color;
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4  output = 1;

				float _GlossOut = 0.0;
			    float _TransOut = 0.0;
			    float _RetroOut = 0.0;
			    float _MetalnessOut = 0.0;
			    float _SpecOccOut = 1.0;
			    float _AmbOccOut = 1.0;
			    float4 _NormalOut = float4(0,0,1,1);
			    float4 _HeightOut = zero4;
			    float4 _AlbedoOut = one4;
			    float _AlphaOut = 1.0;

			    half4 _UV0 = half4(i.UVs.xy, 0.0, 0.0);
			    half4 _UV1 = half4(i.UVs.zw, 0.0, 0.0);

			    fixed4 tintingDetailMask = tex2D(_TintingDetailMaskTex, _UV0.xy);

				float4 	_FabricColorH 			= tintingDetailMask.x * _C_ColorTinting1H + tintingDetailMask.y *	_C_ColorTinting2H;
			    float4 	_FabricColorV 			= tintingDetailMask.x * _C_ColorTinting1V + tintingDetailMask.y * _C_ColorTinting2V;
			    float4 	_FabricColorPatina 		= tintingDetailMask.x * _C_PatinaColor1 + tintingDetailMask.y * _C_PatinaColor2;
			    float4 	_BleachColor 			= tintingDetailMask.x * _C_BleachColor1 + tintingDetailMask.y * _C_BleachColor2;

			    float 	_WeaveHeight 			= tintingDetailMask.z * _C_DetailHeight1 + tintingDetailMask.w * _C_DetailHeight2;
			    float 	_WeaveIndex 			= tintingDetailMask.z * _C_DetailIndex1 + tintingDetailMask.w * _C_DetailIndex2;
			    float 	_WeaveTiling 			= tintingDetailMask.z * _C_DetailTiling1 + tintingDetailMask.w * _C_DetailTiling2;

				CHR_BlendFabricUpdate
				(
				    _UV0,                         
				    _UV1,                 			
				    _WeaveIndex,                   
				    _WeaveTiling,
				    _WeaveHeight,
				    _C_Gloss,
				    _FabricColorH,
				    _FabricColorV,
				    _FabricColorPatina,
				    _BleachColor,

			  		_PatternInt,                   //< display_name: Pattern Intensity>
					_C_PatternColor1,                //< display_name: Pattern Color 1>
					_C_PatternColor2,                //< display_name: Pattern Color 2> 
					_C_PatternColor3,                //< display_name: Pattern Color 3> 
					_C_PatternMaskTex_ST,          
					_C_PatternMetalness,
					_C_PatternDirection,
					_C_PatternHeight,	

					_BumpSharpness,				     //< display_name: Bump Sharpness>
					_C_WearyDistortion,			 //< display_name: Weary Distortion X>	

					_C_Retro, 

				    _GlossOut,               //< display_name: Gloss>
				    _TransOut,               //< display_name: Translucency Out> 
				    _RetroOut,               //< display_name: Retro>
				    _MetalnessOut,           //< display_name: Metalness>
				    _AmbOccOut,	
				    _SpecOccOut,   			 //< display_name: SpecularOcclusion>
				    _NormalOut,              //< display_name: Normal>
				    _HeightOut,
				    _AlbedoOut,              //< display_name: Albedo>
				    _AlphaOut                //< display_name: Alpha>  
				);

				
				half3 viewPos = normalize(_WorldSpaceCameraPos - i.wPos) * _AlphaDitherSize * 1000.0;
				half frame = 100.0;
				if (_AlphaDither > 0.5)
				{
					AlphaToDitheringHiRes(viewPos, _AlphaOut, frame,   _AlphaOut);
				}


				clip(_AlphaOut - _AlphaThreshold);

			    float4 	normalFromHeight = BumpToNormal(_HeightOut.rgb, 1.0);

				float4  finalNormal = CombineDetailNormal(_NormalOut.xyz, normalFromHeight.xyz);

                half3   wB = normalize(cross( i.wTangent, i.wNormal));
                half3   wT = normalize(i.wTangent);
                half3   wN = normalize(i.wNormal);

                half3 lightingResult = GenericLighting(_AlbedoOut.xyz, finalNormal.xyz, _GlossOut, _MetalnessOut, _SpecOccOut, _RetroOut, _AmbOccOut, 
                                                       _Thickness, 1.0,
                                                          wN, wT, wB, i.wPos,
                                                          i.shadowUV0, i.shadowUV1,
                                                          i.UVs.xy, 
                                                          0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0);



                output.rgb = lightingResult;
                // output = _AlbedoOut;



                return output;
            }
            ENDCG
		}
	}

	Fallback "Diffuse"
}

