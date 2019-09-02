Shader "Xibanya/ColorAdd"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AddColor("Add Color", Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        fixed4 _Color;
		fixed4 _AddColor;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color;
			o.Albedo += _AddColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
