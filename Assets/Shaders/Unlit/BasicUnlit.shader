Shader "Xibanya/Unit/BasicUnlit"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
	}

		SubShader
		{
			Tags { "RenderType" = "Opaque" }

			LOD 100
			Cull[_Cull]

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers nomrt
			#pragma multi_compile_instancing
			#pragma multi_compile ___ UNITY_HDR_ON
			#include "UnityCG.cginc"

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			half4		_Color;

			struct v2f
			{
				float4 pos	: SV_POSITION;
				float2 uv	: TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 c = tex2D(_MainTex, i.uv) * _Color;
				#ifdef UNITY_HDR_ON
				return c;
				#else
				return exp2(-c);
				#endif
			}
			ENDCG
		}
	}
}