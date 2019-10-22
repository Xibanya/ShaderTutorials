//by Xibanya
//https://www.patreon.com/teamdogpit 
//https://twitter.com/ManuelaXibanya
//Shared under a CC 4.0 license https://creativecommons.org/licenses/by/4.0/
Shader "Xibanya/Standard/XibHDRP"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
		_NormalStrength("Normal Strength", float) = 1
		[NoScaleOffset] _MetallicGlossMap("Mask Map", 2D) = "white" {}
		[NoScaleOffset] _CubeMask("Cube Mask Map", Cube) = "grey" {}
		[Toggle] _CUBEMASK("Mask is cube?", float) = 0
		[KeywordEnum(Spec, Rough)] _SHINY("Shiny type?", float) = 0
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_OcclusionStrength("Occlusion", Range(0, 1)) = 1
		[NoScaleOffset] _DetailAlbedo("Detail Tex", 2D) = "transparent" {}
		_DetailStrength("Detail Strength", Range(0, 1)) = 1
		_DetailNormalStrength("Detail Normal Strength", float) = 0
		[KeywordEnum(None, HDRP, Mask, Mix)] _DETAIL("Detail blend?", float) = 0
		[Space]
		[Header(Emission)]
		//setting to be off by default even though that's annoying in ordinary circumstances because 
		//all the materials in the SNAPs packs have emission color set to white which is very annoying
		//when converting to this shader
		[KeywordEnum(None, Map, Cube)] _EMISSION("Emission?", float) = 0
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)
		[NoScaleOffset]_EmissionMap("Emission Tex", 2D) = "white" {}
		[NoScaleOffset] _EmissionCube("Emission Cube", Cube) = "white" {}
		[Gamma] _EmissionExposure("Emission Cube Exposure", Range(0, 8)) = 1.0
		[Space]
		[Header(Height)]
		[Toggle] _PARALLAXMAP("Parallax Map?", float) = 0
		_ParallaxMap("Parallax Map", 2D) = "white" {}
		_ParallaxStrength("Parallax Strength", float) = 0.02
		_ParallaxBias("Parallax Bias", float) = 0.42
		[Enum(Red,0,Green,1,Blue,2,Alpha,3)] _ParallaxChannel("Parallax Channel", float) = 0
		[Space]
		[Header(Options)]
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
		[Toggle] _CUTOUT("Cutout?", float) = 0
		_Cutout("Cutout", Range(0, 1)) = 0.5
		[Space]
		[Header(Cubes)]
		[Toggle] _CUBE("Use cubemaps instead?", float) = 0
		[Gamma] _Exposure("Exposure", Range(0, 8)) = 0.2
		[NoScaleOffset] _MainCube("Albedo Cube", Cube) = "grey" {}
		[NoScaleOffset] _BumpCube("Bump Cube", Cube) = "bump" {}
		[NoScaleOffset] _DetailCube("Detail Cube", Cube) = "transparent" {}
		[NoScaleOffset] _ParallaxCube("Parallax Cube", Cube) = "grey" {}
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 200
			Cull [_Cull]

			CGPROGRAM
			#pragma surface surf Standard addshadow novertexlights exclude_path:prepass
			#pragma exclude_renderers nomrt
			#pragma target 3.0
			#pragma shader_feature_local _CUTOUT_ON
			#pragma multi_compile_local __ _CUBEMASK_ON
			#pragma multi_compile_local _SHINY_SPEC _SHINY_ROUGH
			#pragma multi_compile_local _DETAIL_NONE _DETAIL_HDRP _DETAIL_MASK _DETAIL_MIX
			#pragma multi_compile_local _EMISSION_NONE _EMISSION_MAP _EMISSION_CUBE
			#pragma multi_compile_local __ _PARALLAXMAP_ON
			#pragma multi_compile_local __ _CUBE_ON 

#ifdef _SHINY_ROUGH
			#define UNITY_SETUP_BRDF_INPUT RoughnessSetup
#endif

		half4		_Color;
		half		_NormalStrength, _Glossiness, _Metallic, _OcclusionStrength;
		
#ifndef _EMISSION_NONE
		sampler2D	_EmissionMap;
		samplerCUBE _EmissionCube;
		half4		_EmissionCube_HDR;
		half3		_EmissionColor;
		half		_EmissionExposure;
#endif
#ifdef _CUBEMASK_ON
		samplerCUBE _CubeMask;
#else
		sampler2D	_MetallicGlossMap;
#endif
#ifndef _CUBE_ON
		sampler2D	_MainTex, _BumpMap;
#else
		samplerCUBE _MainCube, _BumpCube;
		half4		_MainCube_HDR;
		half		_Exposure;
	
	#ifndef _DETAIL_NONE
		samplerCUBE _DetailCube;
		half4		_DetailCube_HDR;
	#endif
#endif
#ifdef _CUTOUT_ON
		half		_Cutout;
#endif
#ifndef _DETAIL_NONE
		sampler2D	_DetailAlbedo;
		half		_DetailStrength, _DetailNormalStrength;
#endif
        struct Input
        {
            float2 uv_MainTex;
			float3 viewDir;
			float2 uv_MainCube;
        };

#ifdef _PARALLAXMAP_ON
		sampler2D	_ParallaxMap;
		samplerCUBE _ParallaxCube;
		float		_ParallaxStrength;
		float		_ParallaxBias = 0.42;
		half		_ParallaxChannel;
#define pR step(_ParallaxChannel, 0.5)
#define pG step(0.5, _ParallaxChannel) * step(_ParallaxChannel, 1.5)
#define pB step(1.5, _ParallaxChannel) * step(_ParallaxChannel, 2.5)
#define pA step(2.5, _ParallaxChannel)

		float2 ParallaxOffset(float2 uv, float3 viewDir, float bias) 
		{
			float2 vd = viewDir.xy / (viewDir.z + bias);
			float4 pMap = tex2D(_ParallaxMap, uv);
			float height = (pMap.r * pR + pMap.g * pG + pMap.b * pB + pMap.a * pA) - 0.5;
			return vd * height * _ParallaxStrength;
		}

		float3 ParallaxOffset(float3 uv, float3 viewDir, float bias)
		{
			viewDir.z += bias;
			float4 pMap = texCUBE(_ParallaxCube, uv);
			float height = (pMap.r * pR + pMap.g * pG + pMap.b * pB + pMap.a * pA) - 0.5;
			return viewDir * height * _ParallaxStrength;
		}
#endif

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float3 cubeUV = float3(frac(IN.uv_MainCube) * 2 - 1, 1);
#ifdef _PARALLAXMAP_ON
			cubeUV += ParallaxOffset(cubeUV, IN.viewDir, _ParallaxBias);
			IN.uv_MainTex += ParallaxOffset(IN.uv_MainTex, IN.viewDir, _ParallaxBias);
#endif
#ifdef _CUBE_ON

			half4 c = texCUBE(_MainCube, cubeUV);
			c.rgb = DecodeHDR(c, _MainCube_HDR) * _Color.rgb * unity_ColorSpaceDouble.rgb * _Exposure;
			o.Normal = UnpackNormal(texCUBE(_BumpCube, cubeUV));
			
#else
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
#endif
			o.Albedo = c.rgb;
			o.Alpha = c.a;

#if defined(_EMISSION_MAP)
			o.Emission = tex2D(_EmissionMap, IN.uv_MainTex).rgb * _EmissionColor;
#elif defined(_EMISSION_CUBE)
			o.Emission = DecodeHDR(texCUBE(_EmissionCube, cubeUV), _EmissionCube_HDR).rgb * _EmissionColor * unity_ColorSpaceDouble.rgb * _EmissionExposure;
#endif	
#ifdef _CUBEMASK_ON
			half4 mask = texCUBE(_CubeMask, cubeUV);
#else
			half4 mask = tex2D(_MetallicGlossMap, IN.uv_MainTex);
#endif
            o.Metallic = mask.r * _Metallic;
			o.Occlusion = (1 - _OcclusionStrength) + mask.g * _OcclusionStrength;
#if defined(_SHINY_ROUGH)
            o.Smoothness = _Glossiness * (1 - mask.a);
#elif defined(_SHINY_SPEC)
			o.Smoothness = _Glossiness * mask.a;
#endif
#ifndef _DETAIL_NONE
	#ifdef _CUBE_ON
				half4 detail = texCUBE(_DetailCube, cubeUV);
				detail.rgb = DecodeHDR(detail, _DetailCube_HDR) * _Color.rgb * unity_ColorSpaceDouble.rgb * _Exposure;
	#else
				half4 detail = tex2D(_DetailAlbedo, IN.uv_MainTex);
	#endif
			half detailStrength = mask.b * _DetailStrength;
	#if defined(_DETAIL_MULTIPLY)
				o.Albedo = lerp(c.rgb, c.rgb * detail.rgb, detail.a * detailStrength);
	#elif defined(_DETAIL_MIX)
				o.Albedo = lerp(c.rgb, detail.rgb, detail.a * detailStrength);
	#elif defined(_DETAIL_ADD)
				o.Albedo = lerp(c.rgb, c.rgb + detail.rgb, detail.a * detailStrength);
	#elif defined(_DETAIL_HDRP)
				//Interpreting this explanation to the best of my ability:
				//https://forum.unity.com/threads/hdrp-lit-shader-detail-map-issue.540514/#post-3567806
				o.Normal.y = lerp(o.Normal.y, detail.g * _DetailNormalStrength, detailStrength);
				o.Normal.x = lerp(o.Normal.x, detail.a * _DetailNormalStrength, detailStrength);
				#if defined(_SHINY_ROUGH)
								half maskSmooth = _Glossiness * (1 - detail.b);
				#elif defined(_SHINY_SPEC)
								half maskSmooth = _Glossiness * detail.b;
				#endif
				half overlaySmooth = o.Smoothness * maskSmooth * step(o.Smoothness, 0.5) +
					(1 - step(o.Smoothness, 0.5)) * (1 - (2 * (1 - o.Smoothness) * (1 - maskSmooth)));
				o.Smoothness = lerp(o.Smoothness, overlaySmooth, detailStrength);
				half3 overlayAlbedo = o.Albedo * detail.r * step(o.Albedo, 0.5) +
					(1 - step(o.Albedo, 0.5)) * (1 - (2 * (1 - o.Albedo) * (1 - detail.r)));
				o.Albedo = lerp(o.Albedo, overlayAlbedo, detailStrength);
	#elif defined(_DETAIL_MASK)
			o.Metallic = lerp(o.Metallic, _Metallic * detail.r, detailStrength);
			o.Occlusion = lerp(o.Occlusion, (1 - _OcclusionStrength) + detail.g * _OcclusionStrength, detailStrength);
		#if defined(_SHINY_ROUGH)
					half maskSmooth = _Glossiness * (1 - detail.a);
		#elif defined(_SHINY_SPEC)
					half maskSmooth = _Glossiness * detail.a;
		#endif
					o.Smoothness = lerp(o.Smoothness, maskSmooth, detailStrength);
	#endif
#endif
			o.Normal.xy *= _NormalStrength;
#ifdef _CUTOUT_ON
			clip(c.a - _Cutout);
#endif
        }
        ENDCG
    }
    FallBack "Standard"
}
