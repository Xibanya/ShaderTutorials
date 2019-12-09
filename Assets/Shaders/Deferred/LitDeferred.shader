Shader "Xibanya/Deferred/LitDeferred"
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
			CGINCLUDE
			#pragma target 3.0
			#pragma fragment frag
			#pragma multi_compile_instancing
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local _NORMALMAP

		#if (_NORMALMAP || DIRLIGHTMAP_COMBINED || _PARALLAXMAP)
			#define _TANGENT_TO_WORLD 1
		#endif

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardUtils.cginc"
			#include "Assets/Scripts/Shaders/Lib/XibanyaSafeVariables.cginc"

#if !defined(UNITY_PASS_DEFERRED) && !defined(UNITY_PASS_PREPASSBASE) && !defined(UNITY_PASS_SHADOWCASTER) && !defined(UNITY_PASS_META)
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
#endif

			#ifndef MAINTEX_DEFINED
				XIBANYA_DECLARE_SCALED_MAINTEX(_MainTex)
				#define MAINTEX_DEFINED
			#endif
			#ifndef CUTOFF_DEFINED
				XIBANYA_DECLARE_CUTOFF(_Cutoff)
				#define CUTOFF_DEFINED
			#endif
			#if !defined(BUMPMAP_DEFINED) && defined(_NORMALMAP)
				#define BUMPMAP_DEFINED
				XIBANYA_DECLARE_SCALED_BUMPMAP(_BumpMap, _BumpScale)
			#endif
			#ifndef SHINYMAP_DEFINED
				#define SHINYMAP_DEFINED
				XIBANYA_DECLARE_SHINYMAP(_MetallicGlossMap)
			#endif
			#if !defined(AOMAP_DEFINED) && defined(_AO_MAP_ON)
				#define AOMAP_DEFINED
				XIBANYA_DECLARE_AOMAP(_OcclusionMap)
			#endif
				
				struct lit_v2f
				{
					UNITY_POSITION(pos);
					float2 pack0 : TEXCOORD0;
					float4 tSpace0 : TEXCOORD1;
					float4 tSpace1 : TEXCOORD2;
					float4 tSpace2 : TEXCOORD3;
#ifndef DIRLIGHTMAP_OFF
					half3 viewDir : TEXCOORD4;
#endif
					float4 lmap : TEXCOORD5;
#ifndef LIGHTMAP_ON
#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					half3 sh : TEXCOORD6;
#endif
#else
#ifdef DIRLIGHTMAP_OFF
					float4 lmapFadePos : TEXCOORD6;
#endif
#endif
#if !defined(UNITY_PASS_DEFERRED) && !defined(UNITY_PASS_PREPASSBASE) && !defined(UNITY_PASS_SHADOWCASTER) && !defined(UNITY_PASS_META)
					UNITY_SHADOW_COORDS(7)
#endif
#ifdef UNITY_PASS_FORWARDADD
						float3 _LightCoord	: TEXCOORD8;
#endif
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				lit_v2f lit_vert(appdata_full v)
				{
					UNITY_SETUP_INSTANCE_ID(v);
					lit_v2f o;
					UNITY_INITIALIZE_OUTPUT(lit_v2f, o);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.pos = UnityObjectToClipPos(v.vertex);
					o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					float3 worldNormal = UnityObjectToWorldNormal(v.normal);

#ifdef _TANGENT_TO_WORLD
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
					fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
					o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
					o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
					o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
#else
					o.tSpace0.xyz = 0;
					o.tSpace1.xyz = 0;
					o.tSpace2.xyz = worldNormal;
#endif
					float3 viewDirForLight = UnityWorldSpaceViewDir(worldPos);
#ifndef DIRLIGHTMAP_OFF
					o.viewDir.x = dot(viewDirForLight, worldTangent);
					o.viewDir.y = dot(viewDirForLight, worldBinormal);
					o.viewDir.z = dot(viewDirForLight, worldNormal);
#endif
#ifdef DYNAMICLIGHTMAP_ON
					o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#else
					o.lmap.zw = 0;
#endif
#ifdef LIGHTMAP_ON
					o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#ifdef DIRLIGHTMAP_OFF
					o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
					o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
#endif
#else
					o.lmap.xy = 0;
#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					o.sh = 0;
					#ifdef VERTEXLIGHT_ON
					o.sh += Shade4PointLights(
						unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
						unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
						unity_4LightAtten0, worldPos, worldNormal);
					#endif
					o.sh = ShadeSHPerVertex(worldNormal, o.sh);
#endif
#endif
#if !defined(UNITY_PASS_DEFERRED) && !defined(UNITY_PASS_PREPASSBASE) && !defined(UNITY_PASS_SHADOWCASTER) && !defined(UNITY_PASS_META)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
#endif
					return o;
				}

			float3 FinalNormal(float2 uv, half3 _unity_tbn_0, half3 _unity_tbn_1, half3 _unity_tbn_2)
			{
#ifdef _NORMALMAP
				half3 normal = XIBANYA_SAMPLE_SCALED_BUMPMAP(_BumpMap, uv, _BumpScale);
				float3 worldNormal;
				worldNormal.x = dot(_unity_tbn_0, normal);
				worldNormal.y = dot(_unity_tbn_1, normal);
				worldNormal.z = dot(_unity_tbn_2, normal);
				worldNormal = normalize(worldNormal);
				return worldNormal;		
#else
				return normalize(_unity_tbn_2);
#endif
			}
			UnityGI DefaultDeferredGI()
			{
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = 0;
				gi.light.dir = half3(0, 1, 0);
				return gi;
			}
			UnityGIInput DefaultGIInput()
			{
				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.atten = 1;
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
				giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#endif
#ifdef UNITY_SPECCUBE_BOX_PROJECTION
				giInput.boxMax[0] = unity_SpecCube0_BoxMax;
				giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
				giInput.boxMax[1] = unity_SpecCube1_BoxMax;
				giInput.boxMin[1] = unity_SpecCube1_BoxMin;
				giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif
				return giInput;
			}
			ENDCG
			Pass
			{
				Name "Forward"
				Tags { "LightMode" = "ForwardBase" }
				CGPROGRAM
				#pragma vertex lit_vert
				#pragma multi_compile_local _PBR_NONE _PBR_METALLIC _PBR_PM _PBR_RMA
				#pragma shader_feature_local _AO_MAP_ON
				
				#define UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_LIGHTMAPSTS
				
				#ifndef _PBR_NONE
				#include "UnityStandardBRDF.cginc"
					#ifdef _PBR_METALLIC
						#define _METALLICGLOSSMAP
					#elif defined(_PBR_PM)
						#define PM
					#elif defined(_PBR_RMA)
						#define RMA
					#endif
				#endif
				

				half4		_Color;
				half3		_SpecTint;
				half		_Thresh;
				half		_ShadowSmooth;
				half3		_ShadowColor;
				half		_Glossiness;
				half		_Metallic;
				half		_OcclusionStrength;

				half4 frag(lit_v2f i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i);
					float2 uv = i.pack0.xy;
					float3 worldPos = float3(i.tSpace0.w, i.tSpace1.w, i.tSpace2.w);
					float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
#ifndef USING_DIRECTIONAL_LIGHT
					half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
					half3 lightDir = _WorldSpaceLightPos0.xyz;
#endif
					UNITY_LIGHT_ATTENUATION(atten, i, worldPos)

					float3 normal = FinalNormal(uv, i.tSpace0.xyz, i.tSpace1.xyz, i.tSpace2.xyz);
					half4 tex = XIBANYA_SAMPLE_MAINTEX(_MainTex, uv);
					XIBANYA_CLIP(_Cutoff, tex.a);
					half alpha = tex.a * _Color.a;
					half3 albedo = tex.rgb * _Color.rgb;
					half occlusion = _OcclusionStrength;
#ifdef _AO_MAP_ON
					occlusion = XIBANYA_SAMPLE_AOMAP(_OcclusionMap, uv, _OcclusionStrength);
#endif

#ifndef _PBR_NONE
					half smoothness = _Glossiness;
					half metallic = _Metallic;
					UnpackShiny(_MetallicGlossMap, uv, smoothness, metallic);

#if !defined(_AO_MAP_ON) && defined(PM)
					occlusion = XIBANYA_SAMPLE_AOMAP(_MetallicGlossMap, uv, _OcclusionStrength);
#endif
					UnityGI gi;
					UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
					gi.indirect.diffuse = 0;
					gi.indirect.specular = 0;
					gi.light.color = _LightColor0.rgb;
					gi.light.dir = lightDir;
					UnityGIInput giInput = DefaultGIInput();
					giInput.light = gi.light;
					giInput.worldPos = worldPos;
					giInput.worldViewDir = worldViewDir;
					giInput.atten = atten;
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
#else
					giInput.lightmapUV = 0.0;
#endif
#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
#else
					giInput.ambient.rgb = 0.0;
#endif
					Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(smoothness, worldViewDir, normal, lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic));
					gi = UnityGlobalIllumination(giInput, occlusion, normal, g);

					half3 specColor;
					half oneMinusReflectivity;
					albedo = DiffuseAndSpecularFromMetallic(tex.rgb * _Color.rgb, metallic, specColor, oneMinusReflectivity);
					specColor *= _SpecTint;
					float3 halfDir = normalize(gi.light.dir + worldViewDir);
					half shiftAmount = dot(normal, worldViewDir);
					normal = shiftAmount < 0.0f ? normal + worldViewDir * (-shiftAmount + 1e-5f) : normal;
					float nv = saturate(dot(normal, worldViewDir));
					float nl = saturate(dot(normal, gi.light.dir));
					float nh = saturate(dot(normal, halfDir));

					half lv = saturate(dot(gi.light.dir, worldViewDir));
					half lh = saturate(dot(gi.light.dir, halfDir));
					half diffuseTerm = pow(dot(normal, lightDir) * 0.5 + 0.5, _Thresh);
					diffuseTerm = smoothstep(0.5, _ShadowSmooth, diffuseTerm);
					diffuseTerm *= occlusion;

					float roughness = max(exp2(1 - smoothness), 0.002);
					float V = SmithJointGGXVisibilityTerm(nl, nv, roughness);
					float D = GGXTerm(nh, roughness);
					float specularTerm = V * D * UNITY_PI;
					specularTerm = max(0, specularTerm * nl);
					half surfaceReduction = 1.0 / (roughness*roughness + 1.0);
					half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

					half3 finalSpec = specularTerm * gi.light.color * FresnelTerm(specColor, lh);
					half3 finalSurfaceReduction = surfaceReduction * gi.indirect.specular * FresnelLerp(specColor, grazingTerm, nv);
					half3 diffuse = lerp(_ShadowColor, gi.light.color, diffuseTerm);
					
					half3 c = albedo * diffuse + gi.indirect.diffuse * gi.light.color + finalSpec + finalSurfaceReduction;
#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					c += (i.sh * tex.rgb * _Ambient);
#endif
					return half4(c, alpha);
#else
					half shadowDot = pow(dot(normal, lightDir) * 0.5 + 0.5, _Thresh);
					shadowDot = smoothstep(0.5, _ShadowSmooth, shadowDot);
					
					half3 diffuse = lerp(_ShadowColor, _LightColor0.rgb, shadowDot * atten * occlusion);
					albedo *= diffuse;
#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					albedo += (i.sh * tex.rgb * occlusion * _Ambient);
#endif
					return half4(albedo, alpha);
#endif
				}
				ENDCG
			}
			Pass
			{
				Name "Forward Add"
				Tags { "LightMode" = "ForwardAdd" }
				ZWrite Off Blend One One
				CGPROGRAM
				#pragma multi_compile_fwdadd
				#pragma vertex lit_vert
				#pragma multi_compile_local _PBR_NONE _PBR_METALLIC _PBR_PM _PBR_RMA
				#pragma shader_feature_local _AO_MAP_ON

				half4		_Color;
				half		_Thresh;
				half		_ShadowSmooth;
				half3		_ShadowColor;
				half		_Glossiness;
				half		_Metallic;
				half		_OcclusionStrength;
				half3		_SpecTint;

				half4 frag(lit_v2f i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i);
					float2 uv = i.pack0.xy;
					float3 worldPos = float3(i.tSpace0.w, i.tSpace1.w, i.tSpace2.w);
					float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					half4 tex = XIBANYA_SAMPLE_MAINTEX(_MainTex, uv);
					XIBANYA_CLIP(_Cutoff, tex.a);
					half3 albedo = tex.rgb * _Color.rgb;
					half smoothness = _Glossiness;
					half metallic = _Metallic;
					half occlusion = _OcclusionStrength;
					
#ifdef _AO_MAP_ON
					occlusion = XIBANYA_SAMPLE_AOMAP(_OcclusionMap, uv, _OcclusionStrength);
#endif
#ifndef _PBR_NONE
					UnpackShiny(_MetallicGlossMap, uv, smoothness, metallic);
#if !defined(_AO_MAP_ON) && defined(PM)
					occlusion = XIBANYA_SAMPLE_AOMAP(_MetallicGlossMap, uv, _OcclusionStrength);
#endif
					half3 specColor;
					half oneMinusReflectivity;
					albedo = DiffuseAndSpecularFromMetallic(albedo, metallic, specColor, oneMinusReflectivity);
#else
					half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, 0, metallic);
#endif
					specColor *= _SpecTint;
#ifndef USING_DIRECTIONAL_LIGHT
					half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
					half3 lightDir = _WorldSpaceLightPos0.xyz;
#endif
					float3 normal = FinalNormal(uv, i.tSpace0.xyz, i.tSpace1.xyz, i.tSpace2.xyz);
					UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
					half shadowDot = pow(dot(normal, lightDir) * 0.5 + 0.5, _Thresh);
					atten = smoothstep(0.5, _ShadowSmooth, shadowDot) * atten;

					half3 diffuse = _LightColor0.rgb * atten;

					float3 halfDir = normalize(lightDir + worldViewDir);
					half nv = dot(normal, worldViewDir);
					float nl = dot(normal, lightDir);
					float nh = dot(normal, halfDir);

					half lv = dot(lightDir, worldViewDir);
					half lh = dot(lightDir, halfDir);

					half3 finalSpec = _LightColor0.rgb * FresnelTerm(specColor, lh) * diffuse;
					finalSpec += specColor * FresnelLerp(specColor, smoothness, nv);
					half3 c = albedo * diffuse + finalSpec * occlusion;
					return half4(c, 1);
				}
				ENDCG
			}
			Pass
			{
				Name "Deferred"
				Tags { "LightMode" = "Deferred" }
				CGPROGRAM
				#pragma vertex lit_vert
				#pragma multi_compile_prepassfinal
				#pragma multi_compile_local _PBR_NONE _PBR_METALLIC _PBR_PM _PBR_RMA
				#pragma shader_feature_local _AO_MAP_ON
				#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
				#define UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_LIGHTMAPSTS
				#include "UnityShaderVariables.cginc"
				#include "UnityStandardBRDF.cginc"
			#ifndef _PBR_NONE
				#ifdef _PBR_METALLIC
					#define _METALLICGLOSSMAP
				#elif defined(_PBR_PM)
					#define PM
				#elif defined(_PBR_RMA)
					#define RMA
				#endif
			#endif

#ifdef LIGHTMAP_ON
				float4 unity_LightmapFade;
#endif
				half4		_Color;
				half		_Glossiness;
				half		_Metallic;
				half		_OcclusionStrength;
				half		_Ambient;
				half3		_SpecTint;
				half3		_MaxDark;
				half4		unity_Ambient;
				half		_Thresh;
				half		_ShadowSmooth;
				half3		_ShadowColor;

#define XIB_NORMAL FinalNormal(uv, i.tSpace0.xyz, i.tSpace1.xyz, i.tSpace2.xyz)

				void frag(lit_v2f i,
					out half4 outGBuffer0 : SV_Target0, out half4 outGBuffer1 : SV_Target1,
					out half4 outGBuffer2 : SV_Target2, out half4 outGBuffer3 : SV_Target3)
				{
					UNITY_SETUP_INSTANCE_ID(i);
					
					float2 uv = i.pack0.xy;
					float3 worldPos = float3(i.tSpace0.w, i.tSpace1.w, i.tSpace2.w);
					float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					half4 tex = tex2D(_MainTex, uv);
					XIBANYA_CLIP(_Cutoff, tex.a);

					half smoothness = _Glossiness;
					half metallic = _Metallic;
					half occlusion = _OcclusionStrength;
					UnpackShiny(_MetallicGlossMap, uv, smoothness, metallic);
#ifdef _AO_MAP_ON
					occlusion = XIBANYA_SAMPLE_AOMAP(_OcclusionMap, uv, _OcclusionStrength);
#elif defined(PM)
					occlusion = XIBANYA_SAMPLE_AOMAP(_MetallicGlossMap, uv, _OcclusionStrength);
#endif
					half3 specColor;
					half oneMinusReflectivity;
					half3 albedo = DiffuseAndSpecularFromMetallic(tex.rgb * _Color.rgb, metallic, specColor, oneMinusReflectivity);
					specColor *= _SpecTint;
					outGBuffer0 = half4(albedo, occlusion);
					outGBuffer1 = half4(specColor, smoothness);
					
					float3 normal = XIB_NORMAL;
					outGBuffer2 = float4(normal, 1);

					UnityGI gi = DefaultDeferredGI();
					UnityGIInput giInput = DefaultGIInput();
					giInput.light = gi.light;
					giInput.worldPos = worldPos;
					giInput.worldViewDir = worldViewDir;
					
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = i.lmap;
#else
					giInput.lightmapUV = 0.0;
#endif
#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = i.sh;
#else
					giInput.ambient.rgb = 0.0;
#endif
					outGBuffer3.a = 1;
					float3 halfDir = normalize(gi.light.dir + worldViewDir);
					half shiftAmount = dot(normal, worldViewDir);
					normal = shiftAmount < 0.0f ? normal + worldViewDir * (-shiftAmount + 1e-5f) : normal;
					float nv = saturate(dot(normal, worldViewDir));
					float nl = saturate(dot(normal, gi.light.dir));
					float nh = saturate(dot(normal, halfDir));

					half lv = saturate(dot(gi.light.dir, worldViewDir));
					half lh = saturate(dot(gi.light.dir, halfDir));
					half diffuseTerm = dot(normal, gi.light.dir);

					float roughness = max(exp2(1 - smoothness), 0.002);
					float V = SmithJointGGXVisibilityTerm(nl, nv, roughness);
					float D = GGXTerm(nh, roughness);
					float specularTerm = V * D * UNITY_PI;
					specularTerm = max(0, specularTerm * nl);
					half surfaceReduction = 1.0 / (roughness*roughness + 1.0);
					half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

					half3 finalSpec = specularTerm * gi.light.color * FresnelTerm(specColor, lh);
					half3 finalSurfaceReduction = surfaceReduction * gi.indirect.specular * FresnelLerp(specColor, grazingTerm, nv);
					half3 diffuse = lerp(_ShadowColor, gi.light.color, diffuseTerm);

					outGBuffer3.rgb = albedo * (diffuse + gi.indirect.diffuse * gi.light.color) + finalSpec + finalSurfaceReduction;
					
					outGBuffer3.rgb += unity_Ambient.rgb * tex.rgb * _Ambient;
					outGBuffer3.rgb *= occlusion;
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
				#pragma vertex vert

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
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

				#ifdef _ALPHATEST_ON
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				#endif
					return o;
				}

				float4 frag(v2f_shadow i) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(i);
					
				#ifdef _ALPHATEST_ON
					half alpha = XIBANYA_MAINTEX_ALPHA(_MainTex, i.uv);
					XIBANYA_CLIP(_Cutoff, alpha);
				#endif
					SHADOW_CASTER_FRAGMENT(i)
				}
			ENDCG
			}

		}
			FallBack "Diffuse"
}
