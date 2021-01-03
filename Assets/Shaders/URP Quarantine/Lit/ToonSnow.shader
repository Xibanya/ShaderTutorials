Shader "Xibanya/URP/ToonSnow"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [Toggle(_NORMALMAP)] _Normalmap("Normal map?", float) = 0
        _BumpScale("Scale", Float) = 1.0
        [Normal]_BumpMap("Normal Map", 2D) = "bump" {}
        _Threshold("Shadow Threshold", Range(0,2)) = 1
	_ShadowSoftness("Shadow Smoothness", Range(0.5, 1)) = 0.6
	_ShadowColor("Shadow Color", Color) = (0.1657655, 0.1768016, 0.5367647,1)
        _SnowColor("Snow Color", Color) = (1,1,1,1)
        _SnowDirection("Snow Direction", Vector) = (0, 1, 0, 0)
        _SnowShape("Snow Buildup", Range(0, 0.1)) = 1
        _SnowSmooth("Snow Edge Smooth", Range(0, 1)) = 0.5
        _SnowSpec("Snow Spec Color", Color) = (0.1, 0.9, 1, 1)
        _SpecSmoothness("Spec edge smoothness", Range(0.5, 1)) = 0.75
        _SnowGlossiness("Snow Glossiness", Range(0, 1)) = 0.25
        [HDR]_RimColor("Rim Color", Color) = (0.1, 0.9, 1, 1)
        _RimSmooth("Rim Smoothness", Range(0, 1)) = 0.6
        _RimPower("Rim Size", Range(0, 1)) = 0.5
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
            "PerformanceChecks" = "False"
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

            #pragma vertex SnowVert
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
            half3   _SnowColor;
            float3  _SnowDirection;
            float   _SnowShape;
            half    _SnowSmooth;
            half3   _SnowSpec;
            half    _SnowGlossiness;
            half    _RimPower;
            half    _RimSmooth;
            half3   _RimColor;
            half    _SpecSmoothness;
            CBUFFER_END
            #define NEED_WORLDPOS
            ///Note: this HAS to come after _BaseMap_ST is defined
            #include "../Lib/XibLit.hlsl"
            #include "../Lib/XibFrag.hlsl"

            v2f SnowVert(appdata v)
            {
                XIB_INIT_V2F

                ///////// SNOW BUILDUP EFFECT HAPPENS HERE /////////
                float3 worldNormal = TransformObjectToWorldNormal(v.normalOS);
                float snowDot = saturate(dot(worldNormal, _SnowDirection));
                half smooth = lerp(0, 4, _SnowSmooth * 0.5);
                snowDot = smoothstep(0, smooth, snowDot);
                v.positionOS.xyz += min(_SnowShape, worldNormal * snowDot * _SnowShape);
                ///////////////////////////////////////////////////

                //The rest of this vert shader is just like the default
                //lit vert shader
                XIB_GET_VERT_INPUTS
                XIB_PACK_UV_AND_NORMAL
                XIB_FOGFACTOR
                XIB_PACK_LIGHTMAPS
                return o;
            }

            half3 ToonSpecular(Light light, float3 worldNormal, half3 viewDir, 
                half3 specular, half rough)
            {
                half shadowDot = pow(dot(worldNormal, light.direction) * 0.5 + 0.5, _Threshold);
                shadowDot = smoothstep(0.5, _ShadowSoftness, shadowDot);
            	half term =  saturate(shadowDot * 
                    light.distanceAttenuation * light.shadowAttenuation);
                float3 halfVec = SafeNormalize(float3(light.direction) + float3(viewDir));
                half NdotH = saturate(dot(worldNormal, halfVec));
                half modifier = smoothstep(0.5, _SpecSmoothness, pow(NdotH, rough));
                half3 specColor = specular * modifier * light.color * _SnowGlossiness;
                return lerp(_ShadowColor, light.color, term) + specColor;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half4 col = tex2D(_BaseMap, i.uv.xy) * _BaseColor;
                GET_WORLD_NORMAL;

                float snowDot = saturate(dot(worldNormal, _SnowDirection));
                snowDot = smoothstep(0, _SnowSmooth, snowDot);
                half3 snowSpec = lerp(0, _SnowSpec, snowDot);
                half snowGloss = sqrt(1 - lerp(0, _SnowGlossiness, snowDot));

                #ifdef _NORMALMAP
                    float3 viewDir = GetWorldSpaceNormalizeViewDir(i.positionWS);
                #else
                    float3 viewDir = i.viewDirWS;
                #endif

                Light mainLight = GetMainLight(SHADOWCOORD);
                half3 diffuse = ToonSpecular(mainLight, worldNormal, viewDir, snowSpec, snowGloss);

                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    diffuse += ToonSpecular(light, worldNormal, viewDir, snowSpec, snowGloss);
                }
                #endif

                half3 color = lerp(col.rgb, _SnowColor, snowDot) * diffuse;

                half rimSize = lerp(0, 9, _RimPower);
                float rimDot = 1 - pow(dot(worldNormal, viewDir), rimSize);
	            float rim = smoothstep(0, _RimSmooth, smoothstep(0.5, 1, rimDot));
                color += _RimColor * rim * snowDot;
                return half4(color, 1);
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
