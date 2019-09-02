Shader "Xibanya/Lerp"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_OtherTex("Other Tex", 2D) = "white" {}
		_Mix("Mix", Range(0,1)) = 0.5
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

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_OtherTex;
        };

        fixed4 _Color;
		float _Mix;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float3 mainTex = tex2D(_MainTex, IN.uv_MainTex).rgb;
			float3 otherTex = tex2D(_OtherTex, IN.uv_OtherTex).rgb;
			o.Albedo = lerp(mainTex, otherTex, _Mix);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
