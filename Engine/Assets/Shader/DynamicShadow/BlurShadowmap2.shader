
Shader "Alice/Hidden/BlurShadowmap2" {
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
	}
	
	CGINCLUDE
	#include "UnityCG.cginc"

	half4 _TexelSize;

	struct v2f_tap
	{
		float4 pos : SV_POSITION;
		half2 uv20 : TEXCOORD0;
		half2 uv21 : TEXCOORD1;
		half2 uv22 : TEXCOORD2;
		half2 uv23 : TEXCOORD3;
	};			

	v2f_tap vert4Tap ( appdata_img v )
	{
		v2f_tap o;
		o.pos = v.vertex;

		o.uv20 = v.texcoord + _TexelSize.xy;				
		o.uv21 = v.texcoord + _TexelSize.xy * half2(-0.5, -0.5);	
		o.uv22 = v.texcoord + _TexelSize.xy * half2( 0.5, -0.5);		
		o.uv23 = v.texcoord + _TexelSize.xy * half2(-0.5,  0.5);		

		return o; 
	}

	// TODO: consolidate with the above, but make sure both area and dir shadows work
	v2f_tap vert4TapDir ( appdata_img v )
	{
		v2f_tap o;
		o.pos = UnityObjectToClipPos(v.vertex);

		o.uv20 = v.texcoord + _TexelSize.xy;				
		o.uv21 = v.texcoord + _TexelSize.xy * half2(-0.5, -0.5);	
		o.uv22 = v.texcoord + _TexelSize.xy * half2( 0.5, -0.5);		
		o.uv23 = v.texcoord + _TexelSize.xy * half2(-0.5,  0.5);		

		return o; 
	}

	sampler2D _Shadowmap;

	sampler2D _MainTex;

	float4 fragDownsample ( v2f_tap i ) : SV_Target
	{		
		float4 color = tex2D (_MainTex, i.uv20);
		color += tex2D (_MainTex, i.uv21);
		color += tex2D (_MainTex, i.uv22);
		color += tex2D (_MainTex, i.uv23);
		return float4(1,0,0,1);
		return color * 0.25;
	}

	
	ENDCG
	
	SubShader {
	  ZTest Off Cull Off ZWrite Off Blend Off

	// 0
	Pass 
	{ 
		CGPROGRAM
		#pragma vertex vert4Tap
		#pragma fragment fragDownsample
		ENDCG	 
	}
	}
	FallBack Off
}
