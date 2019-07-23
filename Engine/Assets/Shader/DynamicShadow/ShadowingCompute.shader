// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Similar to regular FX/Glass/Stained BumpDistort shader
// from standard Effects package, just without grab pass,
// and samples a texture with a different name.

Shader "Alice/Hidden/ShadowingCompute" {
	Properties{
		_NormalBias("Normal Bias", Range(0,0.01)) = 0.001
		_DistanceBias("Distance Bias", Range(0,0.2)) = 0.001
	}

		Category{

		// We must be transparent, so other objects are drawn before this one.
		Tags{ "Queue" = "Transparent" "RenderType" = "Opaque" }

		SubShader{

		Pass{
		Name "BASE"
		Tags{ "LightMode" = "Always" }

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
		float4 lPos : TEXCOORD4;
		UNITY_FOG_COORDS(3)
	};

	float4x4 _ShadowProjectionMatrix;
	half _NormalBias;
	half _DistanceBias;

	v2f vert(appdata_t v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		half4 wPos = mul(unity_ObjectToWorld, half4(v.vertex.xyz + _NormalBias * v.normal, 1.0));
		o.lPos = mul(_ShadowProjectionMatrix, wPos);
		o.lPos.z -= _DistanceBias;
		return o;
	}

	sampler2D _Shadowmap;

	half4 frag(v2f i) : SV_Target
	{
		// calculate perturbed coordinates
		// we could optimize this by just reading the x & y without reconstructing the Z
		// i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
		half2 offset = half2(0.001, 0.001);

		half3 shadowUV = half3(i.lPos.xy * 0.5 + 0.5, 1.0 - (i.lPos.z * 0.5 + 0.5));

		half shadowMap = tex2D(_Shadowmap, shadowUV.xy).r;

		fixed shadowing = step(shadowMap,  shadowUV.z);
		
		return shadowMap;
	}
	
	ENDCG
	}
	}

	}

}
