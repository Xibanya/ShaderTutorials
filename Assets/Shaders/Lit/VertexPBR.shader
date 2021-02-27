Shader "Xibanya/Lit/VertexPBR"
{
    Properties
    {
        _Color				("Color", Color) = (1,1,1,1)
        _MainTex			("Albedo (RGB)", 2D) = "white" {}
	[NoScaleOffset]_BumpMap	("Normal Map", 2D) = "bump" {}
	_BumpScale			("Normal Strength", float) = 1
	[Toggle(_METALLICGLOSSMAP)]
	_IsMetallic			("Metallic Map?", float) = 0
	[NoScaleOffset]
	_MetallicGlossMap		("Gloss Map", 2D) = "white" {}
        _Glossiness			("Smoothness", Range(0,1)) = 0.5
        [Gamma]_Metallic		("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert
        #pragma target 2.0
	#pragma shader_feature_local _METALLICGLOSSMAP

        sampler2D	_MainTex;
	sampler2D	_BumpMap;
	sampler2D	_MetallicGlossMap;
	float4		_MainTex_ST;
	half4		_Color;
	half		_Glossiness;
	half		_Metallic;
	half		_BumpScale;
		
        struct Input
        {
            	float2 uv_MainTex;
		half4 Color;
		half4 NormalTS;
        };

	void vert(inout appdata_full v, out Input o)
	{
		UNITY_INITIALIZE_OUTPUT(Input, o);
		float2 uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
		o.Color.rgb = tex2Dlod(_MainTex, float4(uv, 0, 0)).rgb * _Color.rgb;
		o.NormalTS.xyz = UnpackScaleNormal(tex2Dlod(_BumpMap, float4(uv, 0, 0)), _BumpScale);
		half4 shiny = tex2Dlod(_MetallicGlossMap, float4(uv, 0, 0));
#ifdef _METALLICGLOSSMAP
		o.NormalTS.w = shiny.r * _Metallic;
		o.Color.a = shiny.a * _Glossiness;
#else
		o.NormalTS.w = _Metallic;
		o.Color.a = shiny.r * _Glossiness;
#endif
	}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
		o.Albedo = IN.Color.rgb;
		o.Normal = IN.NormalTS.xyz;
            	o.Metallic = IN.NormalTS.w;
            	o.Smoothness = IN.Color.a;
		o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
