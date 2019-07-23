#ifndef ALPHA
#define ALPHA

fixed _AlphaDither = 0.0;
fixed _AlphaDitherSize = 1.0;
fixed _AlphaEnhancement = 1.0;
fixed _AlphaThreshold = 0.1;
fixed _Thickness = 1.0;

float AlphaToDither(in float2 screenPos, in float alpha, float frame )
{
		uint2 spos = ((uint2)( screenPos.xy + float2(frame,frame) ) ) & 0x7;
		
		const float alphaThreshold[64] =
		{
		   1,  49, 13, 61, 4,  52, 16, 64,
		   33, 17, 45, 29, 36, 20, 48, 32,
		   9, 57, 5,  53, 12, 60, 8,  56,
		   41, 25, 37, 21, 44, 28, 40, 24,
		   3,  51, 15, 63, 2,  50, 14, 62,
		   35, 19, 47, 31, 34, 18, 46, 30,
		   11, 59, 7,  55, 10, 58, 6,  54,
		   43, 27, 39, 23, 42, 26, 38, 22
		};

		float threshold = alphaThreshold[spos.x + spos.y * 8 ] / 65.0;
		return step(threshold, alpha);
}


void AlphaToDitheringHiRes(
         in  float3 screenPos,  //<display_name: ScreenPos; default: In.m_ScreenPosition; hidden: true>
		 in  float  alpha,     	//<display_name: Alpha>
		 in  float  frame,     	//<display_name: Frame>
		 out float paramOut 	//<display_name: Ouput>
         )
{
	paramOut = AlphaToDither(screenPos.xy, alpha, frame*160.0f );
}



#endif