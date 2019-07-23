// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Similar to regular FX/Glass/Stained BumpDistort shader
// from standard Effects package, just without grab pass,
// and samples a texture with a different name.

Shader "TEST/DynamicShadowOnObject" {
Properties {
	_BumpAmt  ("Distortion", range (0,64)) = 10
	_TintAmt ("Tint Amount", Range(0,1)) = 0.1
	_MainTex ("Tint Color (RGB)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	
	_NormalBias ("Normal Bias", Range(0,0.01)) = 0.001	
	_DistanceBias ("Distance Bias", Range(0,0.2)) = 0.001	

	_ShadowmapSize ("_ShadowmapSize", Range(256, 4096)) = 2048
}

Category {

	// We must be transparent, so other objects are drawn before this one.
	Tags { "Queue"="Transparent" "RenderType"="Opaque" }

	SubShader {

		Pass {
			Name "BASE"
			Tags { "LightMode" = "Always" }
			
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fog
#include "UnityCG.cginc"

struct appdata_t {
	float4 vertex : POSITION;
	float2 texcoord: TEXCOORD0;
	float3 normal : NORMAL;
};

struct v2f {
	float4 vertex : POSITION;
	float4 uvgrab : TEXCOORD0;
	float2 uvbump : TEXCOORD1;
	float2 uvmain : TEXCOORD2;
	float4 wPos : TEXCOORD3;
	float4 lPos : TEXCOORD4;
	UNITY_FOG_COORDS(3)
};

float _BumpAmt;
half _TintAmt;
float4 _BumpMap_ST;
float4 _MainTex_ST;
float4x4 _ShadowProjectionMatrix;
half _NormalBias;
half _DistanceBias;
half _ShadowmapSize;


v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
	#else
	float scale = 1.0;
	#endif
	o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y * scale) + o.vertex.w) * 0.5;
	o.uvgrab.zw = o.vertex.zw;
	o.uvbump = TRANSFORM_TEX( v.texcoord, _BumpMap );
	o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
	o.wPos = mul(unity_ObjectToWorld, half4(v.vertex.xyz + 0* _NormalBias * v.normal,1));
	o.lPos = mul(_ShadowProjectionMatrix, o.wPos);
	o.lPos.z -= 2*_DistanceBias;
	UNITY_TRANSFER_FOG(o,o.vertex);
	return o;
}

sampler2D _GrabBlurTexture;
float4 _GrabBlurTexture_TexelSize;
sampler2D _BumpMap;
sampler2D _MainTex;
sampler2D _Shadowmap;

float shadowing(sampler2D shadowMap, half2 uv, float compare)
{
	float depths = tex2D(shadowMap, uv).r;
    return step(compare, depths);
}

float texture2DShadowLerp(sampler2D shadowMap, half2 uv, float compare)
{
    half2 texelSize = 1.0 / _ShadowmapSize;
    half2 f = frac(uv * _ShadowmapSize + 0.5);
    half2 centroidUV = floor(uv * _ShadowmapSize + 0.5) / _ShadowmapSize;

    float lb = shadowing(shadowMap, centroidUV + texelSize * half2(0.0, 0.0), compare);
    float lt = shadowing(shadowMap, centroidUV + texelSize * half2(0.0, 1.0), compare);
    float rb = shadowing(shadowMap, centroidUV + texelSize * half2(1.0, 0.0), compare);
    float rt = shadowing(shadowMap, centroidUV + texelSize * half2(1.0, 1.0), compare);
    
    float a = lerp(lb, lt, f.y);
    float b = lerp(rb, rt, f.y);
    float c = lerp(a, b, f.x);
    
    return c;
}

float PCF(sampler2D shadowMap, half2 uv, float compare, int iteration)
{
    float result = 0.0;
    
    for(int x = -iteration; x <= iteration; x++)
    {
        for(int y = -iteration; y <= iteration; y++)
        {
            half2 offset = half2(x, y) / _ShadowmapSize;
            result += texture2DShadowLerp(shadowMap, uv + offset, compare);
        }
    }
    fixed normFactor = (2 * iteration + 1 );
    normFactor *= normFactor;

    return result / normFactor;
}

half4 frag (v2f i) : SV_Target
{
	// calculate perturbed coordinates
	// we could optimize this by just reading the x & y without reconstructing the Z
	// i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
	half4 col = tex2Dproj (_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));
	half4 tint = tex2D(_MainTex, i.uvmain);
	
	half3 shadowUV = half3(i.lPos.xy * 0.5 + 0.5, 1.0 - (i.lPos.z * 0.5 + 0.5));

	int iteration = 0;
	 return half4(shadowUV, 1);
	fixed shadowing = PCF(_Shadowmap, shadowUV.xy, shadowUV.z, iteration);
	return shadowing;
}

ENDCG

		}
	}
}
}