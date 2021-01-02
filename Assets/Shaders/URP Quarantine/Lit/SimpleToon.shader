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
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
        }
        LOD 300
        Pass
        {
            Name "ForwardLit"
            Tags{ "LightMode" = "UniversalForward" }
            Cull Back

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
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
            #ifdef _NORMALMAP
                half3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.zw), _BumpScale);
                float3 worldNormal = TransformTangentToWorld(normal,
                    half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz));
            #else
                float3 worldNormal = i.normalWS;
            #endif
                worldNormal = NormalizeNormalPerPixel(worldNormal);
                #ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord = i.shadowCoord;
                #else
                float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                Light mainLight = GetMainLight(shadowCoord);
                half3 diffuseColor = LightingToon(mainLight, worldNormal);

                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    diffuseColor += LightingToon(light, worldNormal);
                }
                #endif

                half3 finalColor = diffuseColor * col.rgb;
                return half4(finalColor, 1);
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