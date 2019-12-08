Shader "Xibanya/Deferred/LitDeferredOutline" {
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		[Toggle(_NORMALMAP)] _Normalmap("Use normal map?", float) = 0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Strength", float) = 1
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		[Gamma]_Metallic("Metallic", Range(0,1)) = 0.0
		_OcclusionStrength("Occlusion", Range(0, 1)) = 1
		[Space]
		[Header(Outline)]
		_Outline("Outline Width", Range(0, 0.01)) = 0.005
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 0)
		[Space]
		[Header(Options)]
		[Toggle] _ALPHATEST("Cutout?", float) = 0
		_Cutoff("Cutoff", Range(0, 1)) = 0.5
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
	}
		SubShader
		{
			CGINCLUDE
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local _NORMALMAP
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			half		_Cutoff;

#ifndef _NORMALMAP
			struct v2f
			{
				float4 pos			: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float3 normal		: NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
		#define FINAL_NORMAL i.normal
		#define V2F_NORMAL	o.normal = UnityObjectToWorldNormal(v.normal);
#else
// --------- [ ALL THE CRAP YOU NEED TO UNPACK A NORMAL MAP ] ------------------ //
			sampler2D	_BumpMap;
			half		_BumpScale;
			struct v2f
			{
				float4 pos			: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float4 tangent[3]	: TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			float3 GetNormal(v2f i)
			{
				half3 normalMap = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
				float3 normal = float3(
					dot(i.tangent[0].xyz, normalMap),
					dot(i.tangent[1].xyz, normalMap),
					dot(i.tangent[2].xyz, normalMap));
				return normalize(normal);
			}
#define FINAL_NORMAL GetNormal(i)
#define V2F_NORMAL float3 worldNormal = UnityObjectToWorldNormal(v.normal);\
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;\
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);\
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;\
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;\
				o.tangent[0] = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);\
				o.tangent[1] = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);\
				o.tangent[2] = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
//-------------------------------------------------------------------------- //
#endif
		ENDCG
		Pass
		{
			Name "Deferred Outline"
			Tags { "LightMode" = "Deferred" }
			Cull Front
			Offset 8, 8
			ZWrite On
			CGPROGRAM
			#pragma multi_compile_prepassfinal
			float	_Outline;
			half4	_OutlineColor;

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_OUTPUT(v2f, o); //lets me be lazy and use the same struct and not bother to initialize everything
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
#ifdef _ALPHATEST_ON
				half alpha = tex2D(_MainTex, i.uv).a;
				clip(alpha - _Cutoff);
#endif
				outGBuffer0 = 0;
				outGBuffer1 = 0;
				outGBuffer2 = 0;
				outEmission = _OutlineColor;
			}
			ENDCG
		}
		Pass
		{
			Name "Deferred"
			Tags { "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma multi_compile_prepassfinal

			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				V2F_NORMAL
				return o;
			}

			half4		_Color;
			half		_Glossiness;
			half		_Metallic;
			half		_OcclusionStrength;
			half4		unity_Ambient;

			void frag(v2f i,
				out half4 outGBuffer0 : SV_Target0, out half4 outGBuffer1 : SV_Target1,
				out half4 outGBuffer2 : SV_Target2, out half4 outGBuffer3 : SV_Target3)
			{
				half4 tex = tex2D(_MainTex, i.uv);
#if defined(_ALPHATEST_ON)
				clip(tex.a - _Cutoff);
#endif
				half3 specColor;
				half oneMinusReflectivity;
				half3 albedo = DiffuseAndSpecularFromMetallic(tex.rgb * _Color.rgb, _Metallic, specColor, oneMinusReflectivity);

				outGBuffer0 = half4(albedo, _OcclusionStrength);
				outGBuffer1 = half4(specColor, _Glossiness);
				outGBuffer2 = half4(FINAL_NORMAL, 1);

				outGBuffer3 = tex * unity_Ambient * _OcclusionStrength;
			}
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_shadowcaster

			struct v2f_shadow
			{
				V2F_SHADOW_CASTER;
	#ifdef _ALPHATEST_ON
				float2  uv		: TEXCOORD1;
	#endif
			};

			v2f_shadow vert(appdata_base v)
			{
				v2f_shadow o;
				UNITY_SETUP_INSTANCE_ID(v);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

			#ifdef _ALPHATEST_ON
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			#endif
				return o;
			}

			float4 frag(v2f_shadow i) : SV_Target
			{
			#ifdef _ALPHATEST_ON
				half alpha = tex2D(_MainTex, i.uv).a;
				clip(alpha - _Cutoff);
			#endif
				SHADOW_CASTER_FRAGMENT(i)
			}
		ENDCG
		}
	}
	Fallback "Diffuse"
}
