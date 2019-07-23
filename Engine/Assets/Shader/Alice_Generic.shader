Shader "Alice/Alice_Generic"
{
    Properties
    {
        [Header(Shadow)]
        _ShadowmapBlurring ("Shadowmap Blur <-> Sharp", Range(0.1, 2)) = 1.0
        _ShadowDepthFalloff ("Shadow Depth Falloff", Range(0.0, 1.0)) = 0.5
        _AddShadowDistanceBias ("Shadow Distance Bias", Range(0.0, 1.0)) = 0.5
        
        _AlbedoTex ("Albedo, AO", 2D) = "white" {}
        _AlbedoColor ("Albedo Color", Color) = (1, 1, 1, 1)

        [Header(Alpha)]
        _AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.1
        _AlphaDither("Alpha Dither", Range(0, 1)) = 0.0
        _AlphaDitherSize ("Alpha Dither Size", Range(1, 5)) = 3 

        [Header(Physic)]
        [NoScaleOffset]
        _NormalTex ("Normal", 2D) = "black"{}
        _NormalIntensity ("Normal Intensity", Range(0, 5.0))= 1

        _ReflectProbeTex ("ReflectProbeTex", CUBE) = "white"{}

        _MultiScatteringLUTTex ("MultiscatteringLUT", 2D) = "white" {}

        _MaskTex ("Metal, Gloss, Curvature", 2D) = "black"{}



        _Glossiness ("Glossiness", Range(0.0,1.0)) = 1
        _Metalness ("Metalness", Range(0.0,1.0)) = 1
        _Retro ("Retro", Range(0.0, 1.0)) = 0.0
        _RetroTint ("Retro Tint", Range(0.0, 1.0)) = 0.0
        _Thickness ("Thickness", Range(0.0, 1.0)) = 0.5
        _MultiScatteringInt ("MultiScatteringInt", Range(0.0, 1.0)) = 0

        [KeywordEnum(Everything, AlbedoColor, Diffuse, Specular, AmbientDiffuse, AmbientReflectance, Lightmap)] _Debug("Debug", Float) = 0
        


        // _EnvRotation ("Envrionment Rotation", range(0, 1.0)) = 0

    }
    SubShader
    {
        Tags {"RenderType"="Opaque" "ObjectType"="Default" "LIGHTMODE"="ForwardBase"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #define GENERIC_PBR_SHADING

            #include "UnityCG.cginc"
            #include "Alpha.cginc"
            #include "Alice_Lighting_Utility.cginc"

            sampler2D _AlbedoTex;
            half4 _AlbedoTex_ST;
            sampler2D _MultiScatteringLUTTex;
            sampler2D _NormalTex;
            sampler2D _MaskTex;

            half4 _AlbedoColor;
            half _NormalIntensity;
            half _Glossiness;
            half _Metalness;
            half _MultiScatteringInt;

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

                o.UVs = half4(v.uv, 1.0, 1.0);

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
                fixed4  albedoTex = tex2D(_AlbedoTex, i.UVs.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw);
                fixed3  albedo = _AlbedoColor.rgb * albedoTex;
                fixed   alpha = albedoTex.a;

                fixed4  normalAOTex = tex2D(_NormalTex, i.UVs.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw);
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


                half3 lightingResult = GenericLighting(albedo, normal, glossiness, metalness, microVis, 0.0, AO, thickness, multiScatteringInt,
                                                          wN, wT, wB, i.wPos,
                                                          i.shadowUV0, i.shadowUV1,
                                                          i.UVs.xy, 
                                                          0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0);

                clip(alpha - _AlphaThreshold);

                lightingResult = albedo;
                return fixed4(lightingResult, 1.0);
            }
            ENDCG
        }
    }
}
