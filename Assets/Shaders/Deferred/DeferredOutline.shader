Shader "Xibanya/Deferred/LitDeferredOutline"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		[Toggle(_NORMALMAP)] _Normalmap("Use normal map?", float) = 0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Strength", float) = 1
		[Header(PBR)]
		_MetallicGlossMap("Gloss Map", 2D) = "white" {}
		[KeywordEnum(None,Metallic,PM,RMA)] _PBR("PBR Map", float) = 1
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		[Gamma]_Metallic("Metallic", Range(0,1)) = 0.0
		[HDR]_SpecTint("Spec Tint", Color) = (1, 1, 1, 1)
		[Space]
		[Toggle]_AO_MAP("Use AO Map?", float) = 0
		_OcclusionMap("Occlusion Map", 2D) = "white" {}
		_OcclusionStrength("Occlusion", Range(0, 1)) = 1
		[Space]
		[Header(Emission)]
		_Ambient("Ambient Light Strength", float) = 1
		_MaxDark("Max Dark", Color) = (0.1057118, 0.01566101, 0.2309999, 1)
		[Space]
		[Header(Forward Tooniness)]
		_Thresh("Shadow Threshold", Range(0,2)) = 1
		_ShadowSmooth("Shadow Smoothness", Range(0.5, 1)) = 0.6
		_ShadowColor("Shadow Color", Color) = (0,0,0,1)
		[Space]
		[Header(Options)]
		[Toggle] _ALPHATEST("Cutout?", float) = 0
		_Cutoff("Cutoff", Range(0, 1)) = 0.5
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
	}
		SubShader
		{
			Pass
			{
				Name "OUTLINE"
				Tags { "LightMode" = "Always" }
				Cull Front
				Offset 8, 8
				ZWrite On
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#pragma shader_feature_local _ALPHATEST_ON
				#include "UnityCG.cginc"
				#include "Assets/Scripts/Shaders/Lib/XibanyaSafeVariables.cginc"

				#ifndef MAINTEX_DEFINED
					XIBANYA_DECLARE_SCALED_MAINTEX(_MainTex)
					#define MAINTEX_DEFINED
				#endif
				#ifndef CUTOFF_DEFINED
					XIBANYA_DECLARE_CUTOFF(_Cutoff)
					#define CUTOFF_DEFINED
				#endif

				float	_Outline;
				half4	_OutlineColor;

				struct v2f
				{
					float4 pos	: SV_POSITION;
					float2 uv	: TEXCOORD0;
				};
				v2f vert(appdata_base v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.pos = UnityObjectToClipPos(v.vertex);
					float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
					norm.x *= UNITY_MATRIX_P[0][0];
					norm.y *= UNITY_MATRIX_P[1][1];
					o.pos.xy += norm.xy * _Outline;
		#ifdef _ALPHATEST_ON
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		#endif
					return o;
				}
				half4 frag(v2f i) : COLOR
				{
					UNITY_SETUP_INSTANCE_ID(i);
					XIBANYA_CLIP_MAINTEX(_Cutoff, _MainTex, i.uv);
					return _OutlineColor;
				}
				ENDCG
			}
			Pass
			{
				Name "Deferred Outline"
				Tags { "LightMode" = "Deferred" }
				Cull Front
				Offset 8, 8
				ZWrite On
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#pragma multi_compile_prepassfinal
				#pragma shader_feature_local _ALPHATEST_ON
				#include "UnityCG.cginc"
				#include "Assets/Scripts/Shaders/Lib/XibanyaSafeVariables.cginc"

				#ifndef MAINTEX_DEFINED
					XIBANYA_DECLARE_SCALED_MAINTEX(_MainTex)
					#define MAINTEX_DEFINED
				#endif
				#ifndef CUTOFF_DEFINED
					XIBANYA_DECLARE_CUTOFF(_Cutoff)
					#define CUTOFF_DEFINED
				#endif

				float	_Outline;
				half4	_OutlineColor;

				struct v2f
				{
					float4 pos	: SV_POSITION;
					float2 uv	: TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				v2f vert(appdata_base v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					UNITY_INITIALIZE_OUTPUT(v2f, o);
					o.pos = UnityObjectToClipPos(v.vertex);
					float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
					norm.x *= UNITY_MATRIX_P[0][0];
					norm.y *= UNITY_MATRIX_P[1][1];
					o.pos.xy += norm.xy * _Outline;
					#ifdef _ALPHATEST_ON
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					#endif
					return o;
				}
				void frag(v2f i, out half4 outGBuffer0 : SV_Target0, out half4 outGBuffer1 : SV_Target1,
					out half4 outGBuffer2 : SV_Target2, out half4 outEmission : SV_Target3)
				{
					UNITY_SETUP_INSTANCE_ID(i);
					XIBANYA_CLIP_MAINTEX(_Cutoff, _MainTex, i.uv);
					outGBuffer0 = 0;
					outGBuffer1 = 0;
					outGBuffer2 = 0;
					outEmission = _OutlineColor;
				}
				ENDCG
			}
			UsePass "Xibanya/Deferred/LitDeferred/Forward"
			UsePass "Xibanya/Deferred/LitDeferred/Forward Add"
			UsePass "Xibanya/Deferred/LitDeferred/Deferred"
			UsePass "Xibanya/Deferred/LitDeferred/ShadowCaster"
		}
		FallBack "Diffuse"
}
