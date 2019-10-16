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
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard addshadow
        #pragma target 3.0

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

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
		o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color;
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
		o.Normal.z *= _NormalStrength;
		o.Emission = _EmissionColor * tex2D(_EmissionMap, IN.uv_MainTex) * o.Albedo;
		half d = 1 - pow(dot(o.Normal, IN.viewDir), _RimPower);
		o.Emission += _RimColor * smoothstep(0.5, max(0.5, _RimSmooth), d);
        }
        ENDCG
    }
    FallBack "Standard"
}
