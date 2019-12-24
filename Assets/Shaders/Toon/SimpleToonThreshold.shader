Shader "Xibanya/SimpleToonThreshold"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("Normal Strength", Float) = 1
		_Threshold("Shadow Threshold", Range(0,2)) = 1
		_ShadowSoftness("Shadow Smoothness", Range(0.5, 1)) = 0.6
		_ShadowColor("Shadow Color", Color) = (0,0,0,1)
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Toon
		
		half		_Threshold;
		half		_ShadowSoftness;
		half3		_ShadowColor;
		sampler2D	_MainTex;
		sampler2D	_BumpMap;
		
		struct Input
		{
			float2 uv_MainTex;
		};
		half4		_Color;
		float		_BumpScale;

            	inline half4 LightingToon(SurfaceOutput s, half3 lightDir, half atten)
            	{
            	#ifndef USING_DIRECTIONAL_LIGHT
            	    	lightDir = normalize(lightDir);
            	#endif
			half shadowDot = pow(dot(s.Normal, lightDir) * 0.5 + 0.5, _Threshold);
			float threshold = smoothstep(0.5, _ShadowSoftness, shadowDot);
            	    	half3 diffuseTerm = saturate(threshold * atten);
            	    	half3 diffuse = lerp(_ShadowColor, _LightColor0.rgb, diffuseTerm);
            	    	return half4(s.Albedo * diffuse, 1);
            	}

		void surf(Input IN, inout SurfaceOutput o)
		{
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color;
			o.Normal = UnpackScaleNormal(tex2D(_BumpMap, IN.uv_MainTex), _BumpScale);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
