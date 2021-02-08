Shader "Xibanya/Lit/RimLight"
{
    Properties
    {
        _Color					("Color", Color) = (1,1,1,1)
        _MainTex				("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_BumpMap	("Normal Map", 2D) = "bump" {}
		_BumpScale				("Normal Map Strength", float) = 1
		[NoScaleOffset]_MetallicGlossMap("Gloss map", 2D) = "white" {}
		[KeywordEnum(Metallic, Roughness, Specular)] _Map("Gloss map type", int) = 0
        _Glossiness				("Smoothness", Range(0,1)) = 0.5
        [Gamma]_Metallic		("Metallic", Range(0,1)) = 0.0
		_RimSmooth				("Rim Smoothness", Range(0.5, 2)) = 1
		_RimPower				("Rim Size", Range(0.001, 2)) = 1
		[HDR]_RimColor			("Rim Color", Color) = (1, 1, 1, 1)
		_EnergyConservation		("Energy Conservation", Range(0, 1)) = 1
		_LightPower				("Light Power", float) = 1
    }
    SubShader
    {
        Tags 
		{ 
			"RenderType" = "Opaque" 
			"Queue" = "Geometry"
		}
        LOD 200

        CGPROGRAM
        #pragma surface surf RimLight
        #pragma target 3.0
		#pragma multi_compile_local _MAP_METALLIC _MAP_ROUGHNESS _MAP_SPECULAR
		#include "UnityPBSLighting.cginc"

        sampler2D	_MainTex, _BumpMap;
		sampler2D	_MetallicGlossMap;

        struct Input
        {
            float2 uv_MainTex;
        };

        half		_Glossiness;
        half		_Metallic;
        half4		_Color;
		half		_RimSmooth;
		half		_RimPower;
		half3		_RimColor;
		half		_EnergyConservation;
		half		_BumpScale;
		half		_LightPower;

		inline half4 LightingRimLight(SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
		{
			s.Normal = normalize(s.Normal);
			half rimDot = 1 - (dot(s.Normal, viewDir) * 0.5 + 0.5);
			rimDot = pow(rimDot, _RimPower);
			rimDot = smoothstep(0.5, max(0.5, _RimSmooth), rimDot);
			half oneMinusReflectivity;
			half3 specColor;
			half3 conserved = DiffuseAndSpecularFromMetallic(
				s.Albedo, s.Metallic, specColor, oneMinusReflectivity);
			s.Albedo = lerp(s.Albedo, conserved, _EnergyConservation);
			s.Albedo = lerp(s.Albedo, s.Albedo * _RimColor, rimDot * s.Smoothness);
		
			half outputAlpha;
			s.Albedo = PreMultiplyAlpha(s.Albedo, s.Alpha, oneMinusReflectivity, outputAlpha);

			half4 c = UNITY_BRDF_PBS(s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, 
				s.Normal, viewDir, gi.light, gi.indirect);
			c.a = outputAlpha;
			return c;
		}
		void LightingRimLight_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			half3 lightColor = gi.light.color;
			
			LightingStandard_GI(s, data, gi);
			half3 viewDir = data.worldViewDir;
			half nDotL = dot(s.Normal, gi.light.dir) * 0.5 + 0.5;
			half nDotV = dot(s.Normal, viewDir) * 0.5 + 0.5;
			gi.light.color = lightColor * nDotL * pow(nDotL * nDotV, 1 - data.atten * _LightPower);
		}
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
			o.Normal = UnpackScaleNormal(tex2D(_BumpMap, IN.uv_MainTex), _BumpScale);
			half4 shiny = tex2D(_MetallicGlossMap, IN.uv_MainTex);
		#ifdef _MAP_ROUGHNESS
			o.Smoothness = _Glossiness * (1 - shiny.r);
		#elif defined(_MAP_SPECULAR)
			o.Smoothness = _Glossiness * sqrt(shiny.r);
		#else
			o.Smoothness = _Glossiness * sqrt(shiny.a);
		#endif
		#ifdef _MAP_METALLIC
			o.Metallic = _Metallic * shiny.r;
		#else
			o.Metallic = _Metallic;
		#endif
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
