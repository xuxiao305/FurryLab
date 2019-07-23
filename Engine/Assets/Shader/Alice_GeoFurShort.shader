Shader "Alice/Alice_GeometryFurShort"
{
    Properties
    {
        [Header(Shadow)]
        _ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0
        _ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5
        _AddShadowDistanceBias ("Shadow Distance Bias", Range(0.0, 1.0)) = 0.5
        
        [Header(Shape)]
        _DirectionTexIntensity ("Direction Tex Intensity", Range(0, 1.0)) = 1.0
        _BaseMeshVertCount ("Base Mesh Vert Count", Float) = 100
        

        _TipScale("Tip Scale", Range(0, 1.0)) = 0.5
        _Length("Length", Range(0, 1)) = 0.1
        _MaxWidth("Max Width", Range(0, 1)) = 0.2

        [Header(TextureSetting)]
        _DirectionTex ("Fur Direction Map", 2D) = "white" {}
        _FurIDTex("Fur ID Map", 2D) = "white" {}
        _FurNormalTex ("Fur Normal Map", 2D) = "white" {}

        [Header(Color)]
        _AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.1
        _RootColor ("Root Color", Color) = (1, 1, 1, 1)
        _TipColor1 ("Tip Color 1", Color) = (1, 1, 1, 1)
        _TipColor2 ("Tip Color 2", Color) = (1, 1, 1, 1)
        _TipColor12Blend ("Tip Color 12 Blend", Range(0.0,1.0)) = 0.5
        _RootTipColorBlendWidth ("Root Tip Color Blend Width", Range(0.0, 0.3)) = 0.25
        _RootTipColorBlendOffset ("Root Tip Color Blend Offset", Range(-0.2, 0.2)) = 0.

        [Header(Shading)]
        
        _NormalIntensity("Normal Intensity", Range(0.0, 3.0)) = 1.0
        _Gloss("Gloss", Range(0.0,1.0)) = 0.5
        _SpecularScale("Specular Scale", Range(0.0, 1.0)) = 1.0
        _SpecularShifting("Specular Shift", Range(-1.0, 1.0)) = 0.5

        _ReflectProbeTex ("ReflectProbeTex", CUBE) = "white"{}

        _Thickness ("Thickness",  Range(0,2)) = 1
        _TranslucentTex ("Translucent Texture", 2D) = "black"{}
        _Translucency ("Translucency", Range(0.0, 0.5)) = 0.25

        [Header(Dynamic)]
        _Stiffness("Stiffness", Range(1,20)) = 2.0
        _Turbluance("Turbluance", Range(0,10)) = 2.0

        [Header(TempParams_Tonemapping)]
        toneMappingFactor  ("ToneMapping Factor", Range(0.1, 5.0)) = 1.0
        toneMappingLerp ("ToneMapping Lerp", Range(0.0, 1.0)) = 1.0 
    }

    SubShader
    {
        Tags {"RenderType"="Opaque" "ObjectType"="GeometryFur" "LIGHTMODE"="ForwardBase"}
        

    

        Pass
        {
            LOD 200
            // Blend SrcAlpha OneMinusSrcAlpha
            // ZWrite Off
            CULL Off
            // AlphaToMask on
            CGPROGRAM
            #pragma target 5.0

            #define EXP_FALLOFF_SHADOW
            #define GEO_FUR_SHADING

            #include "UnityCG.cginc" 
            #include "Random.cginc"
            #include "Alpha.cginc"
            #include "Alice_Lighting_Utility.cginc"
            #include "Alice_GeoFurShort_Utility.cginc"

            #pragma vertex VS_Main_GeoFur
            #pragma fragment FS_Main_GeoFur
            #pragma geometry GS_Main_GeoFur

            #pragma multi_compile_fwdbase

            #pragma fragmentoption ARB_precision_hint_fastest

            // RGB

            ENDCG
        }
    }
}