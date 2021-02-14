Shader "Xibanya/Lit/TestLightModels"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_SpecColor("Spec Color", Color) = (0.3, 0.3, 0.3, 1)
		_Specular("Specular", Range(0, 1)) = 0.3
		[KeywordEnum(Lambert,BlinnPhong,None)] _Lighting("Lighting Model", float) = 0
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			#pragma surface surf Demo
			#pragma multi_compile_local _LIGHTING_LAMBERT _LIGHTING_BLINNPHONG _LIGHTING_NONE
			sampler2D _MainTex;

			struct Input
			{
				float2 uv_MainTex;
			};

			sampler2D	_BumpMap;
			sampler2D	_SpecGlossMap;
			half		_Glossiness;
			half		_Specular;
			half4		_Color;

			inline half4 LightingDemo(SurfaceOutput s, half3 viewDir, UnityGI gi)
			{
		#ifdef _LIGHTING_LAMBERT
				half4 c = UnityLambertLight(s, gi.light);
		#elif defined(_LIGHTING_BLINNPHONG)
				half4 c = UnityBlinnPhongLight(s, viewDir, gi.light);
		#else
				half4 c = half4(s.Albedo, s.Alpha);
		#endif
				return c;
			}
			inline void LightingDemo_GI(
				SurfaceOutput s,
				UnityGIInput data,
				inout UnityGI gi)
			{
				gi = UnityGlobalIllumination(data, 1.0, s.Normal);
			}

			void surf(Input IN, inout SurfaceOutput o)
			{
				half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = c.rgb;
				o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
				half4 shiny = tex2D(_SpecGlossMap, IN.uv_MainTex);
				o.Gloss = _Glossiness * shiny.r;
				o.Specular = _Specular;
				o.Alpha = c.a;
			}
			ENDCG
		}
		FallBack "Diffuse"
}