Shader "Xibanya/Standard/SimpleStandard"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("Normal Strength", Float) = 1
		_MetallicGlossMap("Gloss Map", 2D) = "white" {}
		_Metallic("Metallic", Range(0, 1)) = 0.5
		_Glossiness("Smoothness", Range(0 ,1)) = 0.5
		_OcclusionMap("AO", 2D) = "white" {}
		_OcclusionStrength("Occlusion", Range(0, 1)) = 1
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionMap("Emission Tex", 2D) = "white" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200
		CGPROGRAM
		#pragma surface surf Standard
		#pragma target 3.0

		sampler2D   _MainTex;
		sampler2D   _BumpMap;
		sampler2D   _MetallicGlossMap;
		sampler2D   _EmissionMap;
		sampler2D   _OcclusionMap;

		struct Input
		{
			float2 uv_MainTex;
		};

		half4       _Color;
		float       _BumpScale;
		half3       _EmissionColor;
		half        _Glossiness;
		half        _Metallic;
		half        _OcclusionStrength;

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color.rgb;
			o.Normal = UnpackScaleNormal(tex2D(_BumpMap, IN.uv_MainTex), _BumpScale);
			half4 glossmap = tex2D(_MetallicGlossMap, IN.uv_MainTex);
			o.Metallic = glossmap.r * _Metallic;
			o.Smoothness = glossmap.a * _Glossiness;
			o.Emission = _EmissionColor * tex2D(_EmissionMap, IN.uv_MainTex);
			o.Occlusion = (1 - _OcclusionStrength) +
				tex2D(_OcclusionMap, IN.uv_MainTex).g *
				_OcclusionStrength;
			o.Alpha = 1;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
