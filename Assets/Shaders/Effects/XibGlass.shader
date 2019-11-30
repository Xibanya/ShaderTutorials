Shader "Xibanya/Special/XibGlass"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
	_BumpMap("Normal", 2D) = "bump" {}
	_Distortion("Distortion Power", range(0, 1)) = 0.5
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
	_Occlusion("Occlusion", Range(0, 1)) = 1
	[Header]
	[Header(Shadow)]
	_Threshold("Shadow Threshold", Range(0,2)) = 1
	_ShadowSmooth("Shadow Smoothness", Range(0.5, 1)) = 0.6
	_ShadowColor("Shadow Color", Color) = (0,0,0,1)
	[Space]
	[Header(Rim)]
	[HDR]_RimColor("Rim Color", Color) = (0.5556639, 0.3725525, 0.8679245, 1)
	_RimPower("Rim Fill", Range(0, 2)) = 0.1
	_RimSmooth("Rim Smoothness", Range(0.5, 1)) = 1
	_SideRimSize("Side Rim Size", Range(0, 1)) = 0.5
	[Space]
	[HDR]_GlossColor("Gloss Color", Color) = (0, 1, 0.9897847, 1)
	_GlossSize("Gloss Size", Range(0, 1)) = 0.5
	_GlossSmoothness("Gloss Smoothness", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
       
	GrabPass{ }

        CGPROGRAM
        #pragma surface surf StandardGlass
        #pragma target 3.0
	#define EPSILON     1.192092896e-07
	#include "UnityPBSLighting.cginc"
      
	half		_Threshold;
	half		_ShadowSmooth;
	half3		_ShadowColor;
	half		_GlossSize;
	half3		_GlossColor;
	half		_GlossSmoothness;
	half		_SideRimSize;
	half3		_RimColor;
	half3		grabColor;

	inline half4 LightingStandardGlass(SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
	{
		half3 color = max(_ShadowColor * s.Albedo, s.Albedo * (1 - s.Metallic));
		color *= gi.indirect.diffuse;
		color = lerp(grabColor, color, s.Alpha);
		half3 final = color + gi.indirect.specular;
		return half4(final, 1);
	}

	inline void LightingStandardGlass_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
	{
		half shadowDot = pow(dot(s.Normal, data.light.dir) * 0.5 + 0.5, _Threshold);
		shadowDot = smoothstep(0.5, _ShadowSmooth, shadowDot);

		gi = UnityGI_Base(data, s.Occlusion, s.Normal);
		gi.light.color = lerp(_ShadowColor, gi.light.color, shadowDot * data.atten);
		gi.indirect.diffuse += gi.light.color;

		float3 reflectionDir = reflect(-data.worldViewDir, s.Normal);
		half mip = (1 - s.Smoothness) * UNITY_SPECCUBE_LOD_STEPS;
		half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, mip);
		gi.indirect.specular = DecodeHDR(rgbm, unity_SpecCube0_HDR).rgb * s.Occlusion;
		gi.indirect.specular *= max(0.25, gi.indirect.diffuse);

		half3 halfDir = normalize(gi.light.dir + data.worldViewDir);
		float viewDot = dot(s.Normal, data.worldViewDir);
		half glossSize = lerp(20, EPSILON, _GlossSize);
		half halfDot = pow(dot(normalize(s.Normal), halfDir), glossSize);
		half glossDot = smoothstep(0.5, max(0.5, halfDot + _GlossSmoothness / glossSize * 2), halfDot);
		half3 glossColor = lerp(_GlossColor, s.Albedo, s.Metallic);
		gi.indirect.specular += glossDot * glossColor * s.Smoothness * unity_ColorSpaceDouble;

		half glossPower = max(0, GGXTerm(pow(dot(normalize(s.Normal), halfDir), 5), 0.2));
		gi.indirect.specular += glossPower * s.Smoothness;

		half lightDot = exp2(saturate(dot(gi.light.dir, halfDir))) * _SideRimSize * 20;
		half sideRim = saturate(pow((1 - shadowDot), 5) * pow((1 - viewDot), 5) * lightDot);
		gi.indirect.specular += sideRim * _RimColor;
	}

	sampler2D	_MainTex;
	sampler2D	_BumpMap;
	sampler2D	_GrabTexture;

	struct Input
	{
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float3 viewDir;
		float4 screenPos;
	};

        half		_Glossiness;
        half		_Metallic;
	half		_Occlusion;
        half4		_Color;
	half		_RimPower;
	half		_RimSmooth;
	half		_Distortion;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            	half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));

		half2 distortion = lerp(float2(1, 1), exp2(o.Normal).xy, _Distortion);
		float2 grabUV = IN.screenPos.xy / max(EPSILON, IN.screenPos.w) * distortion;
		grabColor = tex2D(_GrabTexture, grabUV);

		o.Albedo = c.rgb;
            	o.Metallic = _Metallic;
            	o.Smoothness = _Glossiness;
		o.Occlusion = _Occlusion;
            	o.Alpha = c.a;

		half rimDot = 1 - pow(dot(o.Normal, IN.viewDir), _RimPower);
		half rim = smoothstep(0.5, max(0.5, _RimSmooth), rimDot);
		o.Emission = _RimColor * rim;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
