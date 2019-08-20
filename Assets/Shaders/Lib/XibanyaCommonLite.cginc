#ifndef XIBANYA_COMMON_LITE_INCLUDED
#define XIBANYA_COMMON_LITE_INCLUDED
#include "UnityCG.cginc"
#include "XibanyaVariables.cginc"

//Gloss Map Type
#define isMetallic step(_ShinyType, 0.5)
#define isRMA step(_ShinyType - 1, 0.1) * step(0.5, _ShinyType)
#define isSpec step(1.5, _ShinyType) * step(_ShinyType, 2.5)
#define isRoughness step(2.5, _ShinyType) * step(_ShinyType, 3.5)

//Smoothness Source
#define metallicAlpha step(_SmoothnessSource, 0.5)
#define albedoAlpha step(0.5, _SmoothnessSource) * step(_SmoothnessSource, 1.5)
#define roughness step(1.5, _SmoothnessSource) * step(_SmoothnessSource, 2.5)
#define secondSpecMap step(2.5, _SmoothnessSource) * step(_SmoothnessSource, 3.5)

half3 emissionMap;
half4 metal = half4(1, 1, 1, 1);
half rough = 0;
half alpha = 1; //cached in case we need to get smoothness from albedo alpha

void ApplyAlbedo(float2 uv, inout SurfaceOutputStandard o)
{
	half4 tex = UNITY_SAMPLE_TEX2D_SAMPLER(_MainTex, _MainTex, uv);
	alpha = tex.a;
	o.Albedo = tex.rgb * _Color.rgb;
	o.Alpha = tex.a * _Color.a;
}
void ApplyAlbedo(float2 uv, half4 blockColor, inout SurfaceOutputStandard o)
{
	half4 tex = UNITY_SAMPLE_TEX2D_SAMPLER(_MainTex, _MainTex, uv);
	alpha = tex.a;
	o.Albedo = tex.rgb * _Color.rgb * blockColor.rgb;
	o.Alpha = tex.a * _Color.a * blockColor.a;
}
void ApplyNormal(float2 uv, inout SurfaceOutputStandard o)
{
	o.Normal = UnpackNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv));
	o.Normal.z *= _NormalStrength;
}

half Metallic()
{
	return	metal.r * isMetallic +
			metal.g * isRMA +
			min(1, isSpec + isRoughness);
}
half Smoothness()
{
	half fromMetallic = isMetallic * ((metal.a * metallicAlpha) + (alpha * albedoAlpha) + (rough * roughness) + ((1 - rough) * secondSpecMap));
	half fromRoughness = min(1, isRMA + isRoughness) * (1 - metal.r);
	half fromSpecmap = metal.r * isSpec;
	return fromMetallic + fromRoughness + fromSpecmap;
}

half3 Shiny(float2 uv)
{
	metal = UNITY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, _MainTex, uv);
#ifdef _SECONDGLOSSMAP_ON
	rough = 1 - UNITY_SAMPLE_TEX2D_SAMPLER(_RoughnessMap, _MainTex, 
		uv * _RoughnessMap_ST.xy + _RoughnessMap_ST.zw).r;
#endif

	half occlusion =	metal.b * isRMA + 
						UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, 
						uv * _OcclusionMap_ST.xy + _OcclusionMap_ST.zw).r * (1 - isRMA);
	return half3(Metallic(), Smoothness(), occlusion);
}
void ApplyShiny(float2 uv, inout SurfaceOutputStandard o)
{
	half3 shiny = Shiny(uv);
	o.Metallic += shiny.x * _Metallic;
	o.Smoothness += shiny.y * _Glossiness;
	o.Occlusion += shiny.z * _OcclusionStrength;
}
void ApplyEmission(float2 uv, inout SurfaceOutputStandard o)
{
	emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv);
	o.Emission += emissionMap * _EmissionColor;
}
void ApplyEmission(float2 uv, half3 flashColor, inout SurfaceOutputStandard o)
{
	emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv);
	o.Emission += emissionMap * _EmissionColor;
	o.Emission += emissionMap * flashColor;
}
#endif