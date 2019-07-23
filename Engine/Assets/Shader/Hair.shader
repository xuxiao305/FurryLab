// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "JokerProject/KKHair" {
    Properties {
        _MainTex("Diffuse Texture", 2D) = "white" {}
		_AlbedoColor ("Albedo Color", Color) = (1,1,1,1)
		_TranslucentColor ("Translucent Color", Color) = (1,1,1,1)

	    _NormalTex("Normal Texture", 2D) = "black"{}  
		_NormalIntensity ("Normal Intensity", Range(-3,3)) = 1

        _SurfaceDefinitionTex("Roughness(R), Metalness(G), EnvReflectionStrengh(B), Occulusion(A)", 2D) = "white" {}

		_Thickness ("Thickness", Range(0,2)) = 1
		_AnisoDir ("Aniso Direction", Range(0,1)) = 0
		_AnisoDir3 ("Aniso Direction 3", Vector) = (1,0,0,0)

		_TangentShift1("Tangent Shift 1", Range(-1,1)) = 0.1
		_TangentShift2("Tangent Shift 2", Range(-1,1)) = 0.1

		_SpecularDye("SpecularDye", Range(0,1)) = 0.5

		_Roughness1("Roughness1", Range(0,2)) = 1
			
		_Roughness2("Roughness2", Range(0,2)) = 1

		_Cutoff("Cutout", Range(0,1)) = 0.5
		_Color("Color", Color) = (1,1,1,1)
        [KeywordEnum(Everything, AlbedoColorOnly, DiffuseOnly, SpecularOnly, AmbientDiffuseOnly, AmbientReflectanceOnly, LightmapOnly)] _Debug("Debug", Float) = 0
		
        }        		
    SubShader {
		Tags {
			"LightMode" = "ForwardBase"
			"Queue"="AlphaTest"
			"IgnoreProjector"="True"
			// "RenderType"="Transparent"
		}

        
        Pass {

        	// blend SrcAlpha OneMinusSrcAlpha
    		// ZWrite off
    		// ZTest Less
    		Cull off

            CGPROGRAM	
	
            #pragma vertex VsMain	
            #pragma fragment PsMain

			#pragma multi_compile _DEBUG_EVERYTHING _DEBUG_ALBEDOCOLORONLY _DEBUG_DIFFUSEONLY _DEBUG_SPECULARONLY _DEBUG_AMBIENTDIFFUSEONLY _DEBUG_AMBIENTREFLECTANCEONLY _DEBUG_LIGHTMAPONLY 

			#pragma multi_compile_fwdbase
							
			sampler2D _MainTex;
			float4 _MainTex_ST;
            #include "UnityCG.cginc"	
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "PBRLib.cginc"
			#include "HairLighting.cginc"
		
			fixed _Cutoff;

            VsOutput VsMain(appdata v)	
            {
                VsOutput o = InitVS(v);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex).xy;

				return o;	
            }
            	
			half4 PsMain(VsOutput i) : COLOR	
            {
				float shadow = LIGHT_ATTENUATION(i);
				fixed4 mainTex = tex2D(_MainTex, i.uv0);
				fixed3 albedoColor = _AlbedoColor.rgb * mainTex.rgb;

				half3 N = normalize(i.wNormal);
				half3 diffuseLighting = DiffuseLighting(N,_DirectionalLight0,_DirectionalLightColor0, 1) * shadow;
				// diffuseLighting += DiffuseLighting(N,_DirectionalLight1,_DirectionalLightColor1, 1);

				half3 ambientLighting = AmbientLighting(N);
				diffuseLighting = diffuseLighting + ambientLighting * 2.0; 

				fixed4 output = 1;
				output.rgb = albedoColor * diffuseLighting;

				output.a = smoothstep(0.3,1, mainTex.a);

				output.rgb = diffuseLighting;
				output.a = mainTex.r;
				clip(mainTex.r - 0.1);
				// return 1;
				return output;	
					
            }	
            ENDCG

        }	
    }
    FallBack "Transparent/Cutout/VertexLit"
}