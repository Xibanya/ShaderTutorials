#ifndef XIBANYA_COMMON_LIBRARY_INCLUDED
#define XIBANYA_COMMON_LIBRARY_INCLUDED

#include "UnityCG.cginc"

#define White half3(1,1,1)
#define Black half3(0,0,0)

half _ToonThreshold;
half _ToonSmoothness;
half3 _ToonShadowColor;
half _ToonGloss;
half _ToonGlossSmoothness;
half3 _ToonGlossColor;

void InitLightingToon(half threshold, half smoothness, half3 shadowColor, 
	half highlightSize, half highlightSmoothness, half3 highlightColor)
{
	_ToonThreshold = threshold;
	_ToonSmoothness = smoothness;
	_ToonShadowColor = shadowColor;
	_ToonGloss = highlightSize;
	_ToonGlossSmoothness = highlightSmoothness;
	_ToonGlossColor = highlightColor;
}

half4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
{
	half d = pow(dot(s.Normal, lightDir) * 0.5 + 0.5, _ToonThreshold);
	half shadow = smoothstep(0.5, _ToonSmoothness, d);
	half3 shadowColor = lerp(_ToonShadowColor, half3(1, 1, 1), shadow);
	half4 c;
	c.rgb = s.Albedo * _LightColor0.rgb * atten * shadowColor;
	c.a = s.Alpha;

	half3 halfDir = normalize(lightDir + viewDir);
	half halfDot = pow(dot(s.Normal, halfDir), _ToonGloss);
	half gloss = smoothstep(0.5, max(0.5, _ToonGlossSmoothness), halfDot) * s.Specular;
	c.rgb = lerp(c.rgb, _ToonGlossColor * _LightColor0.rgb, gloss);
	return c;
}
#endif