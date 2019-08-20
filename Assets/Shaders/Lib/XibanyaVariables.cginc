#ifndef XIBANYA_COMMON_VARIABLES_INCLUDED
#define XIBANYA_COMMON_VARIABLES_INCLUDED
#include "UnityCG.cginc"

#define Lilac half4(0.5556639, 0.3725525, 0.8679245, 1)
#define Black half3(0, 0, 0)
#define White half3(1, 1, 1)
uniform float3 GlobalFakeLightDir;

//------ Material Property Bock & Instanced Stuff-----//
#ifndef INSTANCED_PROPS
#define INSTANCED_PROPS
#define FLASH_COLOR UNITY_DEFINE_INSTANCED_PROP(half3, _FlashColor)
#define FAKE_LIGHT_DIR UNITY_DEFINE_INSTANCED_PROP(float3, _FakeLightDir)
#define BLOCK_COLOR UNITY_DEFINE_INSTANCED_PROP(half4, _BlockColor)

#define GET_FLASH_COLOR UNITY_ACCESS_INSTANCED_PROP(Props, _FlashColor)
#define GET_FAKE_LIGHT_DIR UNITY_ACCESS_INSTANCED_PROP(Props, _FakeLightDir)
#define GET_BLOCK_COLOR UNITY_ACCESS_INSTANCED_PROP(Props, _BlockColor)
#endif
/////////////////////////////////////////

//---------------------------------------
// MAIN

UNITY_DECLARE_TEX2D(_MainTex);
half4       	_Color;
half4			_ColorOffset;
half			_Cutout;

// NORMAL
UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
float4			_BumpMap_ST;
half			_NormalStrength;

// SHINY
UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_RoughnessMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
float4			_MetallicGlossMap_ST;
float4			_RoughnessMap_ST;
float4			_OcclusionMap_ST;
half			_Metallic;
half			_Glossiness;
half			_ShinyType;
half			_SmoothnessSource;
half			_OcclusionStrength;

// HIGHLIGHT
half4			_GlossColor;
half			_GlossIntensity; 
half			_GlossSoftness;
half			_GlossSize;
half			_MetallicAffectGloss;
half			_SmoothAffectGloss;
half4			_GlossOffset;
samplerCUBE		_Cube;
half			_CubePower;
half			_MetalCube;

// EMISSION
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
float4			_EmissionMap_ST;
half4			_EmissionColor;
half4			_MaxDarkness;
half			_DarkMix;
half			_TexAdd;

// RIM
half			_RimSoftness;
half			_RimLightMix; 
half			_RimPower;
half4			_RimColor;
half			_RimIntensity;
half			_RimMix;

// DETAIL
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailAlbedo);
UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap2);
half 			_NormalStrength2;
half 			_DetailScale;
half 			_DetailStrength;
half 			_NormalBlend;
half 			_DetailBlend;
half4 			_DetailColorOffset;

#endif