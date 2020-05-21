Shader "Xibanya/Unlit/TexGen"
{
    Properties
    {
        _Tex("Texture", 2D) = "white" {}
		_BlendTex("Blend Texture", 2D) = "white" {}
		_Mask("Blend Mask", 2D) = "white" {}
		_BlendPower("Blend Power", Range(0, 2)) = 1
    }
    SubShader
    {
        Tags 
		{ 
			"Queue" = "Transparent" 
			"RenderType" = "Transparent" 
			"PreviewType" = "Plane" 
		}
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 pos		: SV_POSITION;
                float4 packedUV	: TEXCOORD0;
				float2 maskUV	: TEXCOORD1;
            };

            sampler2D	_Tex;
			sampler2D	_BlendTex;
			sampler2D	_Mask;

            float4		_Tex_ST;
			float4		_BlendTex_ST;
			float4		_Mask_ST;
			half		_BlendPower;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.packedUV.xy = TRANSFORM_TEX(v.uv, _Tex);
				o.packedUV.zw = TRANSFORM_TEX(v.uv, _BlendTex);
                o.maskUV = TRANSFORM_TEX(v.uv, _Mask);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 tex1 = tex2D(_Tex, i.packedUV.xy);
				half4 tex2 = tex2D(_BlendTex, i.packedUV.zw);
				half mask = saturate(pow(tex2D(_Mask, i.maskUV).r, _BlendPower));
				return lerp(tex1, tex2, mask);
            }
            ENDCG
        }
    }
}