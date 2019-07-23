			void weatheringEffect(half intensity, 
			                      half vcGradient, 
			                      half centerRange, 
			                      half borderPos, 
			                      half borderSmoothness, 
			                      half3 colorCenter, 
			                      half3 colorMid, 
			                      half3 colorBorder, 
			                      half3 colorSpread,   
			                      fixed3 IDsMap, 
			                      fixed depthMap, 
			                      half baseNoiseIntensity,
			                      half noiseMap, 
			                      fixed2 noiseFreq, 
			                      fixed2 noiseStrength,
			                      half3 detailWeatheringNormal, 
			                      half wetness, 
			                      half tearingIntensity, 
			                      half2 tearingFreq, 
			                      half2 tearingStrength, 
			                      out half3 effectColor, 
			                      out half3 effectNormal, 
			                      out half effectGloss, 
			                      out half effectCavity, 
			                      out half effectMask, 
			                      out half effectAlpha)
			{
				effectColor = 1;
				effectGloss = 0;
				effectCavity = 1;
				effectMask = 1;
				effectAlpha = 1;

			    half horiID = IDsMap.r;
			    half vertID = IDsMap.b;
			    half microFiberID = IDsMap.g;
			    float microFiberMask = microFiberID * noiseMap;

				effectMask = (vcGradient + (noiseMap - 0.5) * baseNoiseIntensity * 1.0 * vcGradient);

	            effectMask = saturate(effectMask + (
	                                   sin(horiID * noiseMap * noiseFreq.x) * noiseStrength.x - 
	                                   sin(vertID * noiseMap * noiseFreq.y) * noiseStrength.y
	                                   ) * vcGradient);

	    		effectMask *= lerp(1.0 - microFiberMask, 1.0, wetness);

	    		fixed effectMaskDeep = (1.0 - saturate(depthMap)) * effectMask;
	    		fixed effectMaskShallow = saturate(depthMap) * effectMask;
	    		fixed effectMaskbyDepth = lerp(effectMaskDeep, effectMaskShallow, 0); // probably needed for dirt

	    		fixed3 effectColorBasedOnDepth = lerp(1.0, colorMid * colorMid, effectMaskbyDepth);

	    		effectMask *= intensity;

	    		float effectBorderMask = smoothstep(borderPos - borderSmoothness, borderPos, effectMask) * 
	    							smoothstep(borderPos + borderSmoothness, borderPos, effectMask);
	    		float3 effectBorderColor = lerp(1.0, colorBorder, effectBorderMask);

	    		float effectCenterMask = smoothstep(centerRange, 1.0, effectMask);
	    		float3 effectCenterColor = lerp(1.0, colorCenter, effectCenterMask);

			    float  tearingMask        = saturate(vcGradient + (noiseMap - 0.5) * tearingIntensity * vcGradient);

			    float  tearingHori        = saturate(tearingMask * 
			                                    (
			                                    sin(horiID * noiseMap * tearingFreq.x) * tearingStrength.x
			                                    ) *
			                                    vcGradient) * tearingMask * tearingIntensity * 2.0;

			    float  tearingVert        = saturate(tearingMask * 
			                                    (
			                                    sin(vertID *  noiseMap * tearingFreq.y) * tearingStrength.y
			                                    ) *
			                                    vcGradient) * tearingMask * tearingIntensity * 2.0;




	    		effectColor = lerp(1.0, lerp(colorSpread, colorMid, effectMask) * effectBorderColor * effectCenterColor, effectMask);
	    		effectColor *= effectColorBasedOnDepth;

	    		effectGloss = wetness * effectMask;
	    		effectNormal = lerp(half3(0.0, 0.0, 1.0), detailWeatheringNormal, effectMask);
	    		effectCavity = depthMap;

	    		// effectColor =  ;
	    		effectAlpha = 1.0 - saturate(tearingVert - tearingHori);
			}