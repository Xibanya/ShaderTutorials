#ifndef XIBANYA_SAFE_VARIABLES_INCLUDED
#define XIBANYA_SAFE_VARIABLES_INCLUDED
#include "UnityCG.cginc"

//use MAINTEX_DEFINED
#define XIBANYA_DECLARE_MAINTEX(tex) sampler2D tex;
#define XIBANYA_DECLARE_SCALED_MAINTEX(tex) sampler2D tex; float4 tex##_ST;
#define XIBANYA_SAMPLE_MAINTEX(tex, uv) tex2D(tex, uv)
#define XIBANYA_MAINTEX_ALPHA(tex, uv) tex2D(tex, uv).a

half3 XibUnpackScaleNormalRGorAG(half4 packednormal, half scale)
{
	#if defined(UNITY_NO_DXT5nm)
		half3 normal = packednormal.xyz * 2 - 1;
	#if (SHADER_TARGET >= 30)
		normal.xy *= scale;
	#endif
		return normal;
	#else
	packednormal.x *= packednormal.w;

	half3 normal;
	normal.xy = (packednormal.xy * 2 - 1);
	#if (SHADER_TARGET >= 30)
		normal.xy *= scale;
	#endif
	normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	return normal;
	#endif
}

//use BUMPMAP_DEFINED
#define XIBANYA_DECLARE_BUMPMAP(tex, scale) sampler2D tex;
#define XIBANYA_DECLARE_SCALED_BUMPMAP(tex, scale) sampler2D tex; half scale;
#define XIBANYA_SAMPLE_SCALED_BUMPMAP(tex, uv, scale) XibUnpackScaleNormalRGorAG(tex2D(tex, uv), scale)
#define XIBANYA_SAMPLE_BUMPMAP UnpackNormal(tex2D(tex, uv))

//use CUTOFF_DEFINED
#define XIBANYA_DECLARE_CUTOFF(cutoff) half cutoff;
	#ifdef _ALPHATEST_ON
		#define XIBANYA_CLIP(cutoff, alpha) clip(alpha - cutoff)
		#define XIBANYA_CLIP_MAINTEX(cutoff, tex, uv) clip(tex2D(tex, uv).a - cutoff)
	#else
		#define XIBANYA_CLIP(cutoff, alpha) 
		#define XIBANYA_CLIP_MAINTEX(cutoff, tex, uv)
	#endif


half XibLerpOneTo(half b, half t)
{
	half oneMinusT = 1 - t;
	return oneMinusT + b * t;
}

//use SHINYMAP_DEFINED
#define XIBANYA_DECLARE_SHINYMAP(tex) sampler2D tex;
#define XIBANYA_SAMPLE_SHINYMAP(tex, uv) tex2D(tex, uv)

void UnpackShiny(sampler2D tex, float2 uv, inout half smoothness, inout half metallic)
{
	half4 shinyMap = XIBANYA_SAMPLE_SHINYMAP(tex, uv);
	#ifndef RMA
		smoothness *= shinyMap.a;
		metallic *= shinyMap.r;
	#else
		smoothness = (1 - shinyMap.r) * smoothness;
		metallic *= shinyMap.g;
	#endif
}
//use AOMAP_DEFINED
#define XIBANYA_DECLARE_AOMAP(tex) sampler2D tex;
#define XIBANYA_SAMPLE_AOMAP(tex, uv, power)  (((1 - min(1, power)) + tex2D(tex, uv).g * min(1, power)))
////////////////////////////////////////////
#endif 