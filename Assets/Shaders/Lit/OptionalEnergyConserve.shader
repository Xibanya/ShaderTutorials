Shader "Xibanya/Lit/OptionalEnergyConservation"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpStrength("Normal Strength", float) = 1
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
		_SpecTint("Spec Tint", Color) = (0.5, 0.5, 0.5, 1)
		_SpecGlossMap("Spec Map", 2D) = "white" {}
		[Toggle(_FINAL_SPEC)] _FinalSpec("Write specular data last?", int) = 0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
		#pragma shader_feature_local _FINAL_SPEC
        #pragma surface surf StandardSpecular finalgbuffer:ColorFunction
        #pragma target 3.0

        sampler2D	_MainTex;
		sampler2D	_SpecGlossMap;
		sampler2D	_BumpMap;

        struct Input
        {
            float2 uv_MainTex;
        };

		half	_BumpStrength;
        half	_Glossiness;
        half4	_Color;
		half4	_SpecTint;

		void ColorFunction(Input IN, SurfaceOutputStandardSpecular o,
			inout half4 gb0 : SV_Target0,
			inout half4 gb1 : SV_Target1,
			inout half4 gb2 : SV_Target2,
			inout half4 gb3 : SV_Target3)
		{
			#ifdef _FINAL_SPEC
			half4 shinyMap = tex2D(_SpecGlossMap, IN.uv_MainTex);
			gb1.rgb = shinyMap.rgb * _SpecTint;
			gb1.a = shinyMap.a * _Glossiness;
			#endif
		}

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
			o.Normal = UnpackScaleNormal(tex2D(_BumpMap, IN.uv_MainTex), _BumpStrength);
		#ifdef _FINAL_SPEC
			o.Smoothness = 0;
			o.Specular = 0;
		#else
			half4 shinyMap = tex2D(_SpecGlossMap, IN.uv_MainTex);
            o.Smoothness = shinyMap.a * _Glossiness;
			o.Specular = shinyMap.rgb * _SpecTint;
		#endif
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
