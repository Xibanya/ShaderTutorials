//This shader is tutorialized in Part 29: Colormasked UI Graphics
//https://www.patreon.com/posts/3-techniques-for-36122576
Shader "Xibanya/Unlit/MaskedVertexColor"
{
    Properties
    {
        [PerRendererData]_MainTex ("Texture", 2D) = "white" {}
		[NoScaleOffset]_Mask("Mask", 2D) = "white" {}
    }
    SubShader
    {
	   Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}
		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityUI.cginc"

            struct appdata
            {
                float4 vertex	: POSITION;
				half4 color		: COLOR;
                float2 uv		: TEXCOORD0;
            };

            struct v2f
            {
				float4 pos	: SV_POSITION;
				half4 color	: COLOR;
                float2 uv	: TEXCOORD0;
            };

			sampler2D _MainTex;
			sampler2D _Mask;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
				half mask = tex2D(_Mask, i.uv).a;
				col.rgb = lerp(col.rgb, col.rgb * i.color.rgb, mask);
				col.a *= i.color.a;
                return col;
            }
            ENDCG
        }
    }
}