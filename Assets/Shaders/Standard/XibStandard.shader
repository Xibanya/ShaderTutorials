Shader "Xibanya/Standard/XibStandard"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionMap("Emission Tex", 2D) = "white" {}
		[HDR]_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimPower("Rim Fill", Range(0, 2)) = 0.1
		_RimSmooth("Rim Smoothness", Range(0.5, 1)) = 1
		_MetallicGlossMap("Shiny Map", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_OcclusionMap("AO", 2D) = "white" {}
		_OcclusionStrength("Occlusion Power", Range(0, 1)) = 1
		_SpecGlossMap("Second Shiny Map", 2D) = "white" {}
		[KeywordEnum(None, FirstA, AlbedoA, FirstR, SecondR)] _SMOOTH("Smoothness source?", float) = 0
		[Toggle] _ROUGHNESS("Smoothness is roughness?", float) = 0
		[KeywordEnum(None, FirstR, FirstG)] _METAL("Metallic source?", float) = 0
		[KeywordEnum(None, AO, FirstB, FirstG, AlbedoA)] _AO("Occlusion source?", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard addshadow
        #pragma target 3.0
		#pragma multi_compile_local __ _SMOOTH_FIRSTA _SMOOTH_ALBEDOA _SMOOTH_FIRSTR _SMOOTH_SECONDR
		#pragma multi_compile_local __ _ROUGHNESS_ON
		#pragma multi_compile_local _METAL_NONE _METAL_FIRSTR _METAL_FIRSTG
		#pragma multi_compile_local _AO_NONE _AO_AO _AO_FIRSTB _AO_FIRSTG _AO_ALBEDOA

        sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _EmissionMap;

        struct Input
        {
            float2 uv_MainTex;
			float3 viewDir;
        };

        half4 _Color;
		float _NormalStrength;
		half4 _EmissionColor;
		half4 _RimColor;
		half _RimPower;
		half _RimSmooth;
		sampler2D _MetallicGlossMap;
		half _Glossiness;
		half _Metallic;
		sampler2D _OcclusionMap;
		half _OcclusionStrength;
		sampler2D _SpecGlossMap;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			half4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = mainTex.rgb * _Color;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			o.Normal.z *= _NormalStrength;
			o.Emission = _EmissionColor * tex2D(_EmissionMap, IN.uv_MainTex) * o.Albedo;
			half d = 1 - pow(dot(o.Normal, IN.viewDir), _RimPower);
			o.Emission += _RimColor * smoothstep(0.5, max(0.5, _RimSmooth), d);
#if defined(_SMOOTH_FIRSTA) || defined(_SMOOTH_FIRSTR) || !defined(_METAL_NONE) || \
			defined(_AO_FIRSTB) || defined(_AO_FIRSTG)
			half4 shiny = tex2D(_MetallicGlossMap, IN.uv_MainTex);
#endif
			
			half smooth = 1;
#if defined(_SMOOTH_FIRSTA)
			smooth = shiny.a;
#elif defined(_SMOOTH_ALBEDOA)
			smooth = mainTex.a;
#elif defined(_SMOOTH_FIRSTR)
			smooth = shiny.r;
#elif defined(_SMOOTH_SECONDR)
			smooth = tex2D(_SpecGlossMap, IN.uv_MainTex).r;
#endif
#ifdef _ROUGHNESS_ON
			smooth = (1 - smooth) * (1 - smooth);
#endif
			o.Smoothness = smooth * _Glossiness;

#if defined(_METAL_FIRSTR)
			o.Metallic = shiny.r * _Metallic;
#elif defined(_METAL_FIRSTG)
			o.Metallic = shiny.g * _Metallic;
#else
			o.Metallic = _Metallic;
#endif

			half occlusion = 1;
#if defined(_AO_AO)
			occlusion = tex2D(_OcclusionMap, IN.uv_MainTex).g;
#elif defined(_AO_FIRSTB)
			occlusion = shiny.b;
#elif defined(_AO_FIRSTG)
			occlusion = shiny.g ;
#elif defined(_AO_ALBEDOA)
			occlusion = mainTex.a;
#endif
#if (SHADER_TARGET < 30) || defined(_AO_NONE)
			o.Occlusion = occlusion * _OcclusionStrength;
#else
			o.Occlusion = (1 - _OcclusionStrength) + occlusion * _OcclusionStrength;
#endif

        }
        ENDCG
    }
    FallBack "Diffuse"
}
