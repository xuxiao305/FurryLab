
Shader "Alice/Alice_Hair"
{
	Properties
	{	

        [Header(Basic)]
        [NoScaleOffset]
        _AlbedoTex 		("Albedo, Alpha", 2D) = "white" {}
        _AlbedoColor 	("Albedo Color", Color) = (1, 1, 1, 1)
		_RootColor 		("Root Color", Color) = (1, 1, 1, 1)
		_TipColor 		("Tip Color", Color) = (1, 1, 1, 1)
		_RootShadowing 	("Root Shadowing", Range(0, 1.0)) = 0.5
		_AlphaThreshold ("Alpha Threshold", Range(0.0, 1.0)) = 0.1
		

        [Header(Physic)]
        [NoScaleOffset]
        _HairStrandNormalTex ("Strand Normal", 2D) = "black"{}
        [NoScaleOffset]
        _HairBentNormalTex ("Mesh Normal", 2D) = "black"{}
        _UseBentNormal ("Use Bent Normal", Range(0.0,1.0)) = 1

		_TranslucentColor ("Translucent Color", Color) = (1, 1, 1, 1)
        _Thickness ("Thickness", Range(0.0, 1.0)) = 0.5

		_Gloss1("Gloss 1", Range(0.0,1.0)) = 0.5
		_Gloss2("Gloss 2", Range(0.0,1.0)) = 0.5

		_SpecularScale1("Specular Scale 1", Range(0.0, 2.0)) = 1.0		
		_SpecularScale2("Specular Scale 2", Range(0.0, 2.0)) = 1.0		
		
		_SpecularShifting1("Specular Shift 1", Range(-1.0, 1.0)) = 0.5
		_SpecularShifting2("Specular Shift 2", Range(-1.0, 1.0)) = 0.5

		_ShadingWarp("Shading Warp", Range(0.0,1.0)) = 0.5
		_EdgeFalloff("Edge Falloff", Range(0.0,5.0)) = 1.0

		_ReflectProbeTex ("ReflectProbeTex", CUBE) = "white"{}

		[Header(Shadowmap)]
		_ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 5)) = 1.0
		_ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5

        [Header(TempParams_IBL)]
        _EnvRotation ("Env Rotation", range(0, 1)) = 0.0
        _HorizonFade ("Horizon Fade", range(0, 2.0)) = 1.3


		[KeywordEnum(Everything, AlbedoColor, Diffuse, Specular, AmbientDiffuse, AmbientReflectance, Lightmap)] _Debug("Debug", Float) = 0


	}
	SubShader
	{
		Tags {"RenderType"="Opaque" "LIGHTMODE"="ForwardBase" "ObjectType"="Hair"}
        CULL Off
		Pass
		{
            CGPROGRAM
            #define EXP_FALLOFF_SHADOW
            #define HAIR_SHDING
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma fragmentoption ARB_precision_hint_fastest		

            #include "UnityCG.cginc"
            #include "Alice_Lighting_Utility.cginc"
            
            sampler2D _AlbedoTex;
            sampler2D _HairStrandNormalTex;
            sampler2D _HairBentNormalTex;

            half4 _AlbedoColor;
            half _Glossiness;
            half _Thickness;

            half _Gloss1;
            half _Gloss2;
            half _SpecularScale1;
            half _SpecularScale2;
            half _SpecularShifting1;
            half _SpecularShifting2;
            fixed _AlphaThreshold;

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
                fixed4  albedoTex = tex2D(_AlbedoTex, i.UVs.xy);
                fixed3  albedo = _AlbedoColor.rgb * albedoTex;
                fixed 	alpha = albedoTex.a;

                fixed4  normalTanShiftTex = tex2D(_HairStrandNormalTex, i.UVs.xy);
                half3   normal     = normalTanShiftTex.xyz * 2.0 - 1.0;
                fixed   tanShift = normalTanShiftTex.a;

                fixed4  bentNormalOcc = tex2D(_HairBentNormalTex, i.UVs.zw);
                half3   bentNormal = bentNormalOcc.xyz * 2.0 - 1.0;
                fixed   AO = bentNormalOcc.a;
                fixed   thickness = _Thickness;

                half3   wB = normalize(cross( i.wTangent, i.wNormal));
                half3   wT = normalize(i.wTangent);
                half3   wN = normalize(i.wNormal);

                half 	shift1 = _SpecularShifting1 * tanShift;
                half 	shift2 = _SpecularShifting2 * tanShift;

                half3   lightingResult = GenericLighting(albedo, 
                                                          normal, 
                                                          0.0,
                                                          0.0,
                                                          AO,
                                                          AO,
                                                          thickness,
                                                          0.0,
                                                          wN,
                                                          wT,
                                                          wB,
                                                          i.wPos,
                                                          i.shadowUV0,
                                                          i.shadowUV1,
                                                          i.UVs.xy,
                                                          half2(shift1, shift2),
                                                          half2(_Gloss1, _Gloss2),
                                                          half2(_SpecularScale1, _SpecularScale2),
                                                          1.0, 1.0, 1.0, 1.0);
                if (alpha < _AlphaThreshold)  
                {
                	discard;
                }
                return fixed4(lightingResult, 1.0);
            }
			ENDCG	
		}

	}

	Fallback "Diffuse"
}
