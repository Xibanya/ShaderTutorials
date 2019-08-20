//Adapted from https://www.patreon.com/posts/25418236
Shader "Xibanya/MinionsBlocks" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		[Toggle] _NORMALMAP("Use normal map?", float) = 1
		_BumpMap("Normal", 2D) = "bump" {}
		_NormalStrength("Normal Strength", float) = 1
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_OcclusionStrength("Occlusion Power", Range(0, 10)) = 2
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		[Enum(Metallic,0,RMA,1,Specular,2,Roughness,3)] _ShinyType("Gloss Map Type", float) = 0
		[Enum(Metallic Alpha,0,Albedo Alpha,1,Second Roughness Map,2,Second Spec Map,3)] _SmoothnessSource("Metallic Map Smoothness Source", float) = 0
		[Toggle] _SECONDGLOSSMAP("2nd gloss map? (only applied if 1st is metallic map)", float) = 1
		_RoughnessMap("Roughness", 2D) = "black" {}
		_OcclusionMap("AO", 2D) = "white" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionMap("Emission Map", 2D) = "white" {}
		[Space]
		[Toggle] _EFFECT("Enable Effect", Int) = 1
		_Speed("MoveSpeed", Range(1,50)) = 10
		_Moved("Moved", Range(0, 1)) = 1
		_RotationMod("Inactive Local Rotation", Vector) = (0, 0, 0, 0)
		_ScaleMod("Inactive Local Scale", Vector) = (0, 0, 0, 0)
		_MoveMod("Inactive Local Translation", Vector) = (0, 0, 0, 0)
		_MoveAxes("Movement Axes", Vector) = (0, 1, 0, 0)
		[Toggle] _DOWN("Move Down?", Int) = 0
		[Toggle] _SHRINK("Shrink?", Int) = 0
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
		[PerRendererData][HDR]_FlashColor("Flash Color", Color) = (0,0,0,1)
		[PerRendererData][HDR]_BlockColor("Block Color", Color) = (1,1,1,1)
	}

		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200
			Cull[_Cull]

		CGPROGRAM
		#pragma surface surf Standard vertex:vert addshadow
		#pragma multi_compile_local		__ _EFFECT_ON
		#pragma multi_compile_local		__ _NORMALMAP_ON
		#pragma multi_compile_local		__ _SECONDGLOSSMAP_ON
		#pragma shader_feature_local	_DOWN_ON
		#pragma shader_feature_local	_SHRINK_ON
		#pragma target 3.0
		#include "../Lib/MatrixTransform.cginc"
		#include "../Lib/XibanyaVariables.cginc"
		#include "../Lib/XibanyaCommonLite.cginc"

		struct Input
		{
			float2 uv_MainTex;
		};

		UNITY_INSTANCING_BUFFER_START(Props)
		FLASH_COLOR
		BLOCK_COLOR
		UNITY_DEFINE_INSTANCED_PROP(float, _Moved)
		UNITY_DEFINE_INSTANCED_PROP(float3, _RotationMod)
		UNITY_DEFINE_INSTANCED_PROP(float3, _ScaleMod)
		UNITY_DEFINE_INSTANCED_PROP(float3, _MoveMod)
		UNITY_INSTANCING_BUFFER_END(Props)

		#define TranslateAmount lerp(UNITY_ACCESS_INSTANCED_PROP(Props, _MoveMod), float3(0, 0, 0), clamp(UNITY_ACCESS_INSTANCED_PROP(Props, _Moved), 0, 1))
		#define RotateAmount lerp(UNITY_ACCESS_INSTANCED_PROP(Props, _RotationMod), float3(0, 0, 0), clamp(UNITY_ACCESS_INSTANCED_PROP(Props, _Moved), 0, 1))
		#define ScaleAmount lerp(UNITY_ACCESS_INSTANCED_PROP(Props, _ScaleMod), float3(1, 1, 1), clamp(UNITY_ACCESS_INSTANCED_PROP(Props, _Moved), 0, 1))

		half3		_MoveAxes;
		half		_Speed;

		void vert(inout appdata_full v)
		{
#ifdef _EFFECT_ON
			float4 pos = v.vertex;
			DoTransform(pos, TranslateAmount, ScaleAmount, RotateAmount);
			v.vertex = pos;
#ifdef _SHRINK_ON
			v.vertex.xyz *= clamp(UNITY_ACCESS_INSTANCED_PROP(Props, _Moved), 0, 1);
#endif
			float m = _Speed - (UNITY_ACCESS_INSTANCED_PROP(Props, _Moved) * _Speed);
			float3 movement = float3(m, m, m) * _MoveAxes;
			#if DOWN_ON
			v.vertex.xyz += movement;
			#else
			v.vertex.xyz -= movement;
			#endif
#endif
		}

		void surf(Input IN, inout SurfaceOutputStandard o) {
			ApplyAlbedo(IN.uv_MainTex, GET_BLOCK_COLOR, o);
#ifdef _NORMALMAP_ON
			ApplyNormal(IN.uv_MainTex * _BumpMap_ST.xy + _BumpMap_ST.zw, o);
#endif
			ApplyShiny(IN.uv_MainTex * _MetallicGlossMap_ST.xy + _MetallicGlossMap_ST.zw, o);
			ApplyEmission(IN.uv_MainTex * _EmissionMap_ST.xy + _EmissionMap_ST.zw, GET_FLASH_COLOR, o);
		}
		ENDCG
		}
			Fallback "Diffuse"
}