//This shader is tutorialized in Part 29: Smooth Blending with Sine
//https://www.patreon.com/posts/shaders-for-who-35129311
Shader "Xibanya/Unlit/ColorMaskBlend"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
		_Color1("Color 1", Color) = (1,1,1,1)
		_Color2("Color 2", Color) = (1,1,1,1)
		_Color3("Color 3", Color) = (1,1,1,1)
		_Blend1("Blend Color 1", Color) = (1,1,1,1)
		_Blend2("Blend Color 2", Color) = (1,1,1,1)
		_Blend3("Blend Color 3", Color) = (1,1,1,1)
		_Speed("Speed", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags 
		{ 
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
			"IgnoreProjector" = "True"
		}

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex	: POSITION;
                float2 uv		: TEXCOORD0;
				half4 color		: COLOR;
            };

            struct v2f
            {
				float4 pos	: SV_POSITION;
                float2 uv	: TEXCOORD0;
				half4 color	: COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			half4 _Color1, _Color2, _Color3;
			half4 _Blend1, _Blend2, _Blend3;
			float4 _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				v.uv.x = v.uv.x + frac(_Time.x * _Speed.w);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				half4 mask = tex2D(_MainTex, i.uv);
				half4 col = half4(0, 0, 0, 0);

				half4 r = lerp(_Color1, _Blend1, sin(_Time.y * _Speed.r) * 0.5 + 0.5);
				half4 g = lerp(_Color2, _Blend2, sin(_Time.y * _Speed.g) * 0.5 + 0.5);
				half4 b = lerp(_Color3, _Blend3, sin(_Time.y * _Speed.b) * 0.5 + 0.5);

				col += r * mask.r;
				col += g * mask.g;
				col += b * mask.b;
				col.a *= mask.a;
                return col * i.color;
            }
            ENDCG
        }
    }
}