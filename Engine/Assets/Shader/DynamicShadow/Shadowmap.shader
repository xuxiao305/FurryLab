Shader "Alice/Hidden/Shadowmap" 
{

    SubShader 
    {
        Tags {"RenderType"="Opaque" "ObjectType"="Default"}
        Pass
        {
            // Fog { Mode Off }
            // Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex.xyz);
      
                return o;
            }

            float frag(v2f i) : COLOR
            {
                float depth = i.pos.z ;/// i.pos.w;

                // SSM
                return float2(depth, 0.0);

                // ESM
                // return (exp(80.0 * depth));
                
                // VSM
                
                // float moment1 = depth; // 一阶矩
                // float moment2 = depth * depth; // 二阶矩

                // float dx = ddx(depth);
                // float dy = ddy(depth);
                // moment2 += 0.25 * (dx * dx + dy * dy); // 解决acne问题
                // half2 outColor = half2(moment1, moment2);
                // return outColor;
            }
            ENDCG
        }
    }

    SubShader
    {
        Tags {"RenderType"="Opaque" "ObjectType"="CmpGeometryFur"}

        Pass
        {
            ZWrite On
            Cull Back
            CGPROGRAM

            #pragma target 5.0

            #pragma vertex VS_Main_CmpGeoFur
            #pragma geometry GS_Main_CmpGeoFur
            #pragma fragment FS_Shadow_CmpGeoFur

            #include "UnityCG.cginc"
            // #include "Alice_Lighting_Utility.cginc"
            #include "Assets\Shader\Alice_CmpGeoFur_Utility.cginc"


            float2 FS_Shadow_CmpGeoFur(FS_INPUT i) : COLOR
            {
                float depth = i.pos.z; /// i.pos.w;

                return float2(depth, 0.1);
            }

            ENDCG
        }
    }

    SubShader
    {
        Tags {"RenderType"="Opaque" "ObjectType"="GeometryFur"}

        Pass
        {
            ZWrite On
            Cull Back
            CGPROGRAM
            #pragma target 5.0
            #include "UnityCG.cginc" 
            // #include "Alice_Lighting_Utility.cginc"
            #include "Assets\Shader\Alice_GeoFur_Utility.cginc"
            #pragma vertex VS_Main_GeoFur
            #pragma fragment FS_Shadow_GeoFur
            #pragma geometry GS_Main_GeoFur

            #pragma multi_compile_fwdbase

            #pragma fragmentoption ARB_precision_hint_fastest

            float2 FS_Shadow_GeoFur(FS_INPUT i) : COLOR
            {
                float depth = i.pos.z; /// i.pos.w;

                return float2(depth, 0.1);
            }

            ENDCG
        }
    }

    SubShader
    {
        Tags {"RenderType"="Opaque" "ObjectType"="Hair"}

        Pass
        {
            ZWrite On
            Cull Back
            CGPROGRAM
            #pragma target 5.0
            #include "UnityCG.cginc" 
            #include "Assets\Shader\Alice_Lighting_Utility.cginc"
            #pragma vertex vert
            #pragma fragment FS_Shadow_Hair

            #pragma multi_compile_fwdbase

            #pragma fragmentoption ARB_precision_hint_fastest

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                // half2 uv1 : TEXCOORD1;
                // half3 normal : NORMAL;
                // half3 tangent : TANGENT;
                // half4 color : TEXCOORD4;

            };


            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex.xyz);
                o.uv = v.uv;
      
                return o;
            }

            sampler _AlbedoTex;
            fixed _AlphaThreshold;
            float2 FS_Shadow_Hair(v2f i) : COLOR
            {
                fixed4  albedoTex = tex2D(_AlbedoTex, i.uv.xy);
                fixed   alpha = albedoTex.a ;

                if (alpha < _AlphaThreshold)
                {
                    discard;
                }
                float depth = i.pos.z; /// i.pos.w;

                return float2(depth, 0.3);
                // SSM
                return depth;
            }


            ENDCG
        }
    }

    SubShader 
    {
        Tags { "RenderType"="Opaque" "ObjectType" = "Fur" }
        
        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            
            
            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o = (v2f_generic)0;             
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = mul(UNITY_MATRIX_VP, o.wPos);
                
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = i.pos.z;
                return float2(depth, 0.5);
                return i.pos.z;

            }
            ENDCG   
        }

        Pass
        {
            ZWrite On
            Cull Back
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            // #include "UnityCG.cginc"
            // #include "AutoLight.cginc"   
            // #include "Alice_Lighting_Utility.cginc"
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPassShadow_VS(v, 0, _WorldSpaceLightPos0, colorLerpFactorList[0]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }

        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            // #include "UnityCG.cginc"
            // #include "AutoLight.cginc"   
            // #include "Alice_Lighting_Utility.cginc"
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPass_VS(v, 4, _WorldSpaceLightPos0, colorLerpFactorList[4]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }

        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPass_VS(v, 6, _WorldSpaceLightPos0, colorLerpFactorList[5]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }

        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPass_VS(v, 8, _WorldSpaceLightPos0, colorLerpFactorList[6]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }

        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPass_VS(v, 10, _WorldSpaceLightPos0, colorLerpFactorList[7]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }
       
        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPass_VS(v, 12, _WorldSpaceLightPos0, colorLerpFactorList[8]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }

        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            //AlphaTest Greater 0.1
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "Assets\\Shader\\Alice_Fur_Utility.cginc"
            
            IMPORT_FUR_UNIFORM
            

            v2f_generic vert (appdata_generic v)
            {
                v2f_generic o;
                o = FurPass_VS(v, 14, _WorldSpaceLightPos0, colorLerpFactorList[9]);
                return o;
            }

            float2 frag (v2f_generic i) : SV_Target
            {
                float depth = FurPassShadow_PS(i);
                return float2(depth, 0.5);
                return depth;
            }
            ENDCG   
        }
        
    }
}