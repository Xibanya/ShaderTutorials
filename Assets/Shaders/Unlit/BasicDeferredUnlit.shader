Shader "Xibanya/Unit/BasicUnlit"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	}
		SubShader
		{
			Pass
			{
				Name "ShadowCaster"
				Tags { "LightMode" = "ShadowCaster" }

				ZWrite On ZTest LEqual

				CGPROGRAM
				#pragma target 3.0
				#pragma exclude_renderers nomrt gles
				#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
				#pragma multi_compile_shadowcaster
				#pragma vertex vertShadowCaster
				#pragma fragment fragShadowCaster
				#include "UnityStandardShadow.cginc"
				ENDCG
			}
			//yes this is intended to be used only in deferred
			//but the editor preview ONLY renders the forward base pass
			//and not having an editor preview annoys the hell out of me
			Pass 
			{
				Name "FORWARDBASE"
				Tags 
				{ 
					"LightMode" = "ForwardBase" 
					"IsEmissive" = "True"
				}
				Lighting Off
				LOD 100
				Cull[_Cull]
				CGPROGRAM
				#pragma vertex vert
				#pragma target 2.0
				#pragma fragment frag
				#pragma multi_compile_instancing
				#pragma multi_compile ___ UNITY_HDR_ON
				#include "UnityCG.cginc"
				sampler2D	_MainTex;
				float4		_MainTex_ST;
				half4		_Color;
				half		_Cutoff;
				struct v2f
				{
					float4 pos		: SV_POSITION;
					float2 uv		: TEXCOORD0;
				};
				v2f vert(appdata_base v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}
				half4 frag(v2f i) : SV_TARGET
				{
					half4 c = tex2D(_MainTex, i.uv) * _Color;
					clip(c.a - _Cutoff);
					#ifndef UNITY_HDR_ON
					c.rgb = exp2(-c.rgb);
					#endif
					return c;
				}
				ENDCG
			}
			Pass
			{
				Name "DEFERRED"
				Tags
				{
					"IsEmissive" = "True"
					"LightMode" = "Deferred"
					"RenderType" = "TransparentCutout"
				}
				Cull[_Cull]
				ZWrite On
				Lighting Off
				LOD 100
			
				CGPROGRAM
				#pragma target 2.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma exclude_renderers nomrt
				#pragma multi_compile_instancing
				#pragma multi_compile ___ UNITY_HDR_ON
				#include "UnityCG.cginc"

				sampler2D	_MainTex;
				float4		_MainTex_ST;
				half4		_Color;
				half		_Cutoff;

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

				struct FragmentOutput 
				{
					float4 gBuffer0 : SV_Target0;
					float4 gBuffer1 : SV_Target1;
					float4 gBuffer2 : SV_Target2;
					float4 gBuffer3 : SV_Target3;
				};

				FragmentOutput frag(v2f i)
				{
					half4 c = tex2D(_MainTex, i.uv) * _Color;
					clip(c.a - _Cutoff);
					#ifndef UNITY_HDR_ON
					c.rgb = exp2(-c.rgb);
					#endif
					FragmentOutput output;
					output.gBuffer0.rgb = c.rgb;
					output.gBuffer0.a = 0;
					output.gBuffer1.rgb = c.rgb;
					output.gBuffer1.a = 0;
					output.gBuffer2 = float4(i.normal * 0.5 + 0.5, 1);
					output.gBuffer3 = c;
					return output;
				}
				ENDCG
			}
	}
}
