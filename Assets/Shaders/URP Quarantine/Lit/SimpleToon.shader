Shader "Xibanya/URP/SimpleToon"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [Toggle(_NORMALMAP)] _Normalmap("Normal map?", float) = 0
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        _Threshold("Shadow Threshold", Range(0,2)) = 1
	_ShadowSoftness("Shadow Smoothness", Range(0.5, 1)) = 0.6
	_ShadowColor("Shadow Color", Color) = (0,0,0,1)
        [Toggle(_RECEIVE_SHADOWS_OFF)] _NoReceiveShadows("Don't receive shadows?", float) = 0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            ///Have to have this tag for it to work in URP
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
        }
        LOD 300
        Pass
        {
            Name "ForwardLit"
            ///Has to have this tag or lighting won't work right
            ///Just like writing frag shaders that use ForwardBase
            /// in the good (Standard) render pipeline
            Tags{ "LightMode" = "UniversalForward" }

            ///Here you can put culling modes, ZWrite, 
            ///Blend, ZTest, etc just like normal, they just
            ///aren't here due to being irrelevant to this shader
            Cull Back

            HLSLPROGRAM
            ///You have to have these two pragmas for shit to work
            ///right due to stupid reasons, just leave 'em
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma target 2.0

            ///Note: you can add your own keywords like usual, 
            ///but every single keyword included here affects something
            ///in the lighting done in the builtin includes. I got
            ///rid of all the ones that are mostly pointless, don't get rid
            ///of these unless you know why you're getting rid
            ///of them
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "../Lib/XibSpite.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4  _BaseMap_ST;
            float4  _BumpMap_ST;
            half4   _BaseColor;
            half    _BumpScale;
            half    _Threshold;
            half    _ShadowSoftness;
            half3   _ShadowColor;
            CBUFFER_END
            ///Note: this HAS to come after _BaseMap_ST is defined
            #include "../Lib/XibLit.hlsl"

            half3 LightingToon(Light light, float3 normal)
            {
                ///PUT WHATEVER CUSTOM LIGHTING YOU WANT HERE
                half shadowDot = pow(dot(normal, light.direction) * 0.5 + 0.5, _Threshold);
                float threshold = smoothstep(0.5, _ShadowSoftness, shadowDot);
            	half3 diffuseTerm = saturate(
                    threshold * light.distanceAttenuation * light.shadowAttenuation);
            	return lerp(_ShadowColor, light.color, diffuseTerm);
            }

            half4 frag(v2f i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 col = tex2D(_BaseMap, i.uv.xy) * _BaseColor;

                //Get world normal
            #ifdef _NORMALMAP
                half3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.zw), _BumpScale);
                float3 worldNormal = TransformTangentToWorld(normal,
                    half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz));
            #else
                float3 worldNormal = i.normalWS;
            #endif
                worldNormal = NormalizeNormalPerPixel(worldNormal);
                ////////////////////////////////////

                // Apply lighting
                #ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord = i.shadowCoord;
                #else
                float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                Light mainLight = GetMainLight(shadowCoord);
                half3 diffuse = LightingToon(mainLight, worldNormal);

                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    diffuse += LightingToon(light, worldNormal);
                }
                #endif
                ////////////////////////////////////
                half3 finalDiffuse = col.rgb * diffuse;

                ///////////////////////////////////////////////////////
                // BASICALLY IF YOU WANT TO PRETEND URP HAS A SURFACE SHADER
                // USE THIS AND PUT ALL YOUR CUSTOM CRAP HERE
                ////////////////////////////////////////////////////////

                return half4(finalDiffuse, 1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/Meta"
        UsePass "Universal Render Pipeline/Lit/Universal2D"
    }
    FallBack "Universal Render Pipeline/Lit"
}
