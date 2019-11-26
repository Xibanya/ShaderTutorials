Shader "Xibanya/Unit/BasicDeferredUnlit"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
	}

		SubShader
		{
			Tags 
			{ 
				"IsEmissive" = "True"
				"LightMode" = "Deferred"
			}

			LOD 100
			Cull[_Cull]

			Pass
			{
				ZWrite On
				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag
				#pragma exclude_renderers nomrt
				#pragma multi_compile_instancing
				#pragma multi_compile ___ UNITY_HDR_ON
				#define DEFERRED_PASS
				#include "UnityCG.cginc"

				sampler2D	_MainTex;
				float4		_MainTex_ST;
				half4		_Color;

				struct v2f
				{
					float4 pos		: SV_POSITION;
					float2 uv		: TEXCOORD0;
					float3 normal		: NORMAL;
				};

				v2f vert(appdata_base v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.normal = v.normal;
					return o;
				}
//implemented as described on https://catlikecoding.com/unity/tutorials/rendering/part-13/
				struct FragmentOutput {
#if defined(DEFERRED_PASS)
					float4 gBuffer0 : SV_Target0;
					float4 gBuffer1 : SV_Target1;
					float4 gBuffer2 : SV_Target2;
					float4 gBuffer3 : SV_Target3;
#else
					float4 color : SV_Target;
#endif
				};

				FragmentOutput frag(v2f i)
				{
					half4 c = tex2D(_MainTex, i.uv) * _Color;
					#ifndef UNITY_HDR_ON
					c = exp2(-c);
					#endif
					FragmentOutput output;
#if defined(DEFERRED_PASS)
					output.gBuffer0.rgb = c.rgb;
					output.gBuffer0.a = 0;
					output.gBuffer1.rgb = c.rgb;
					output.gBuffer1.a = 0;
					output.gBuffer2 = float4(i.normal * 0.5 + 0.5, 1);
					output.gBuffer3 = c;
#else
					output.color = c;
#endif
					return output;
				}
				ENDCG
			}
	}
}
