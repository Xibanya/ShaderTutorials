Shader "Xibanya/HDRP/XibProcEye"
{
	Properties
	{
		_Color("Eye White Color", Color) = (1,1,1,1)
		_IrisColor("Iris Color", Color) = (0.854902,0.9841103,1,1)
		_Radius("Iris Radius", Range(0, 0.05)) = 0.025
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineThickness("Outline Thickness", Range(0, 0.5)) = 0.068
		[Toggle(_NORMALMAP)] _NORMAPMAP("Normal map?", int) = 1
		_NormalMap("Normal", 2D) = "bump" {}
		_NormalScale("Normal Strength", float) = 1
		_Smoothness("Smoothness", Range(0,1)) = 0.5
		_SpecularColor("Specular Tint", Color) = (0.055653821, 0.03528, 0.084, 1)
		[Toggle(_NORMALMAP_TANGENT_SPACE)] _NORMALMAP_TANGENT_SPACE("Tangent Space Normal?", int) = 1
		[HideInInspector]_SpecularColorMap("SpecularColorMap", 2D) = "white" {}
		[HideInInspector]_InvTilingScale("Inverse tiling scale = 2 / (abs(_BaseColorMap_ST.x) + abs(_BaseColorMap_ST.y))", Float) = 1
		[HideInInspector]_UVMappingMask("_UVMappingMask", Color) = (1, 0, 0, 0)
	}
	HLSLINCLUDE
#pragma target 4.5
#pragma shader_feature_local _NORMALMAP_TANGENT_SPACE
#pragma shader_feature_local _NORMALMAP
#pragma shader_feature_local _MATERIAL_FEATURE_SPECULAR_COLOR
#define _MaterialID 4
#ifndef _MATERIAL_FEATURE_SPECULAR_COLOR
#define _MATERIAL_FEATURE_SPECULAR_COLOR
#endif
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitProperties.hlsl"

	ENDHLSL
	SubShader
	{
		Tags{ "RenderPipeline" = "HDRenderPipeline" "RenderType" = "HDLitShader" }
		Pass
		{
			Name "GBuffer"
			Tags { "LightMode" = "GBuffer" }

			Cull Back
			ZTest LEqual

			Stencil
			{
				WriteMask 3
				Ref 2
				Comp Always
				Pass Replace
			}
			HLSLPROGRAM

			#pragma only_renderers d3d11 playstation xboxone vulkan metal switch
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define DECALS_OFF
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ LIGHT_LAYERS
			#define SHADERPASS_GBUFFER_BYPASS_ALPHA_TEST
			#define SHADERPASS SHADERPASS_GBUFFER
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassGBuffer.hlsl"

			#pragma vertex Vert
			#pragma fragment EyeFrag

			half	_Radius;
			half3	_OutlineColor;
			half	_OutlineThickness;
			half3	_Color;
			half3	_IrisColor;
			float4 _NormalMap_ST;

			float circle(float2 uv, float radius)
			{
				float2 dist = uv - real2(0.5, 0.5);
				return 1 - smoothstep(radius - (radius * 0.01),
					radius + (radius * 0.01),
					dot(dist, dist)*4.0);
			}
			half3 EyeColor(float2 uv)
			{
				float2 outlineUV = float2(uv.x, uv.y);
				float outline = circle(outlineUV, _Radius + _OutlineThickness * _Radius);
				real3 albedo = lerp(_Color, _OutlineColor, outline);
				float iris = circle(uv, _Radius);
				return lerp(albedo, _IrisColor, iris);
			}

			void EyeFrag(PackedVaryingsToPS packedInput,
				OUTPUT_GBUFFER(outGBuffer)
#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
#endif
			)
		{
			UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
			FragInputs input = UnpackVaryingsMeshToFragInputs(packedInput.vmesh);

			PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, 
				input.positionSS.z, input.positionSS.w, input.positionRWS);

			float2 uv = input.texCoord0.xy;
			float2 outlineUV = float2(uv.x, uv.y);
			float outline = circle(outlineUV, _Radius + _OutlineThickness * _Radius);
			half3 albedo = lerp(_Color, _OutlineColor, outline);
			float iris = circle(uv, _Radius);
			half3 color = lerp(albedo, _IrisColor, iris);
			float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
			SurfaceData surfaceData;
			surfaceData.materialFeatures = _MaterialID;
			BuiltinData builtinData;
			GetSurfaceAndBuiltinData(input, V, posInput, surfaceData, builtinData);
			surfaceData.ambientOcclusion = 1 - (outline - iris);
			surfaceData.baseColor = color;
			ENCODE_INTO_GBUFFER(surfaceData, builtinData, posInput.positionSS, outGBuffer);

#ifdef _DEPTHOFFSET_ON
			outputDepth = posInput.deviceDepth;
#endif
		}

			ENDHLSL
		}
		 Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			Cull[_CullMode]

			ZClip[_ZClip]
			ZWrite On
			ZTest LEqual

			ColorMask 0

			HLSLPROGRAM

			#pragma only_renderers d3d11 playstation xboxone vulkan metal switch
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer

			#define SHADERPASS SHADERPASS_SHADOWS
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

			#pragma vertex Vert
			#pragma fragment Frag

			ENDHLSL
		}
		 Pass
		 {
			 Name "DepthOnly"
			 Tags{ "LightMode" = "DepthOnly" }

			 Cull[_CullMode]

			 // To be able to tag stencil with disableSSR information for forward
			 Stencil
			 {
				 WriteMask[_StencilWriteMaskDepth]
				 Ref[_StencilRefDepth]
				 Comp Always
				 Pass Replace
			 }

			 ZWrite On

			 HLSLPROGRAM

			 #pragma only_renderers d3d11 playstation xboxone vulkan metal switch

			 //enable GPU instancing support
			 #pragma multi_compile_instancing
			 #pragma instancing_options renderinglayer

			 // In deferred, depth only pass don't output anything.
			 // In forward it output the normal buffer
			 #pragma multi_compile _ WRITE_NORMAL_BUFFER
			 #pragma multi_compile _ WRITE_MSAA_DEPTH

			 #define SHADERPASS SHADERPASS_DEPTH_ONLY
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

			 #ifdef WRITE_NORMAL_BUFFER // If enabled we need all regular interpolator
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
			 #else
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
			 #endif

			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

			 #pragma vertex Vert
			 #pragma fragment Frag

			 ENDHLSL
		 }
		 Pass
		 {
			 Name "MotionVectors"
			 Tags{ "LightMode" = "MotionVectors" } // Caution, this need to be call like this to setup the correct parameters by C++ (legacy Unity)

			 // If velocity pass (motion vectors) is enabled we tag the stencil so it don't perform CameraMotionVelocity
			 Stencil
			 {
				 WriteMask[_StencilWriteMaskMV]
				 Ref[_StencilRefMV]
				 Comp Always
				 Pass Replace
			 }

			 Cull[_CullMode]

			 ZWrite On

			 HLSLPROGRAM

			 #pragma only_renderers d3d11 playstation xboxone vulkan metal switch

			 //enable GPU instancing support
			 #pragma multi_compile_instancing
			 #pragma instancing_options renderinglayer

			 #pragma multi_compile _ WRITE_NORMAL_BUFFER
			 #pragma multi_compile _ WRITE_MSAA_DEPTH

			 #define SHADERPASS SHADERPASS_MOTION_VECTORS
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
			 #ifdef WRITE_NORMAL_BUFFER // If enabled we need all regular interpolator
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
			 #else
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitMotionVectorPass.hlsl"
			 #endif
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
			 #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassMotionVectors.hlsl"

			 #pragma vertex Vert
			 #pragma fragment Frag

			 ENDHLSL
		 }
	}
	Fallback Off
}