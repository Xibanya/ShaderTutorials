Shader "Xibanya/Basic Snow"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_SnowColor("Snow Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_OtherTex("Other Tex", 2D) = "white" {}
		_Mix("Mix", Range(0, 1)) = 1
		_BumpMap("Normal", 2D) = "bump" {}
		_BumpMap2("Normal2", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
		_SnowDirection("Snow Direction", Vector) = (0, 1, 0, 0)
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
			float3 worldNormal; INTERNAL_DATA
        };

        fixed4 _Color;
		float _Mix;
		half _NormalStrength;
		float3 _SnowDirection;
		half4 _SnowColor;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			half d = dot(WorldNormalVector(IN, o.Normal), _SnowDirection);
			float3 mainTex = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color;
			float3 otherTex = tex2D(_OtherTex, IN.uv_OtherTex).rgb * _SnowColor;
			o.Albedo = lerp(mainTex, otherTex, d * _Mix);
			float3 mainNormal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			float3 otherNormal = UnpackNormal(tex2D(_BumpMap2, IN.uv_OtherTex));
			o.Normal = lerp(mainNormal, otherNormal, d * _Mix);
			o.Normal.z *= _NormalStrength;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
