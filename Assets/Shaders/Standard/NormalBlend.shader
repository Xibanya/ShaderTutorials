Shader "Xibanya/NormalBlend"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_OtherTex("Other Tex", 2D) = "white" {}
		_Mix("Mix", Range(0,1)) = 0.5
		_BumpMap("Normal", 2D) = "bump" {}
		_BumpMap2("Normal2", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _OtherTex;
		sampler2D _BumpMap;
		sampler2D _BumpMap2;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_OtherTex;
        };

        fixed4 _Color;
		float _Mix;
		float _NormalStrength;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float3 mainTex = tex2D(_MainTex, IN.uv_MainTex).rgb;
			float3 otherTex = tex2D(_OtherTex, IN.uv_OtherTex).rgb;
			o.Albedo = lerp(mainTex, otherTex, _Mix);
			float3 mainNormal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			float3 otherNormal = UnpackNormal(tex2D(_BumpMap2, IN.uv_OtherTex));
			o.Normal = lerp(mainNormal, otherNormal, _Mix);
			o.Normal.z *= _NormalStrength;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
