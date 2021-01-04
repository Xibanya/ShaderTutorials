Shader "Xibanya/URP/XibParallax"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _BumpScale("Scale", Float) = 1.0
        [Normal]_BumpMap("Normal Map", 2D) = "bump" {}
        _Threshold("Shadow Threshold", Range(0,2)) = 1
	_ShadowSoftness("Shadow Smoothness", Range(0.5, 1)) = 0.6
	_ShadowColor("Shadow Color", Color) = (0.1657655, 0.1768016, 0.5367647,1)
        [Header(Shiny)]
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}
        [KeywordEnum(Metallic, Roughness, Spec)] _Shiny("Shiny Map Type", float) = 0
        _SpecColor("Spec Color", Color) = (1, 1, 1, 1)
        [Header(AO)]
        _OcclusionStrength("AO Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("AO Map", 2D) = "white" {}
        _EmissionMap("EmissionMap", 2D) = "white" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0, 0, 0, 1)
        [Header(Parallax)]
	_ParallaxMap("Parallax map", 2D) = "black" {}
        [IntRange]_Steps("Steps", Range(4, 32)) = 5
	_Parallax("Parallax Strength", Range(-0.5, 0.5)) = 0.1
        _Amplitude("Prallax Amplitude", Range(-1, 1)) = 0.2
	[HDR]_ParallaxColor("Parallax Color", Color) = (1,1,1,1)
        [Header(Options)]
	[Toggle] _ALPHATEST("Cutout?", float) = 0
	_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
        [Toggle(_RECEIVE_SHADOWS_OFF)] _NoReceiveShadows("Don't receive shadows?", float) = 0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
            "PerformanceChecks" = "False"
        }
        LOD 300
        Pass
        {
            Name "ForwardLit"
            Tags{ "LightMode" = "UniversalForward" }
            
            Cull [_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 4.5
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _SHINY_METALLIC _SHINY_ROUGHNESS _SHINY_SPEC
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_instancing

            #pragma vertex VertParallax
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define UnpackScaleNormal UnpackNormalScale
            #define tex2D(idx, uv) SAMPLE_TEXTURE2D(idx, sampler##idx, uv)
            
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
            TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
            TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
            TEXTURE2D(_EmissionMap);        SAMPLER(sampler_EmissionMap);

            CBUFFER_START(UnityPerMaterial)
            float4  _BaseMap_ST;
            float4  _ParallaxMap_ST;
            half4   _BaseColor;
            half    _Cutoff;
            half    _BumpScale;
            half    _Threshold;
            half    _ShadowSoftness;
            half3   _ShadowColor;
            half    _Steps;
            half    _Parallax;
            half4   _ParallaxColor;
            half    _Smoothness;
            half    _Metallic;
            half    _Amplitude;
            half    _OcclusionStrength;
            half3   _SpecColor;
            half3   _EmissionColor;
            CBUFFER_END

            struct appdata
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f_TS
            {
                float4 uv                       : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
                float3 normalWS                 : TEXCOORD3;  
                float4 tangentWS                : TEXCOORD4;  
                float3 worldViewDir                : TEXCOORD5;
                half3 vertexLighting            : TEXCOORD6;
                float4 shadowCoord              : TEXCOORD7;
                float3 viewDirTS                : TEXCOORD8;
            #ifdef _ADDITIONAL_LIGHTS
                float3 positionWS               : TEXCOORD9;
            #endif
              
                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f_TS VertParallax(appdata v)
            {
                v2f_TS o = (v2f_TS)0;
            
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
            
                half3 worldViewDir = GetWorldSpaceViewDir(vertexInput.positionWS);
            
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _ParallaxMap);
                o.normalWS = normalInput.normalWS;
                o.worldViewDir = worldViewDir;
                real sign = v.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                o.tangentWS = tangentWS;
                half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, o.normalWS, worldViewDir);
                o.viewDirTS = viewDirTS;
            
                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
            
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                o.vertexLighting = vertexLight;
                o.shadowCoord = GetShadowCoord(vertexInput);
                o.positionCS = vertexInput.positionCS;

            #ifdef _ADDITIONAL_LIGHTS
                o.positionWS = vertexInput.positionWS;
            #endif
            
                return o;
            }

            half3 LightingToon(Light light, float3 normal, float2 uv, 
                float3 viewDir, half3 albedo, half4 shiny)
            {
                half shadowDot = pow(dot(normal, light.direction) * 0.5 + 0.5, _Threshold);
                float threshold = smoothstep(0.5, _ShadowSoftness, shadowDot);
            	half3 diffuseTerm = saturate(
                    threshold * light.distanceAttenuation * light.shadowAttenuation);
            	half3 diffuse = lerp(_ShadowColor, light.color, diffuseTerm);
                
            #ifdef _SHINY_METALLIC
                half metallic = shiny.r * _Metallic;
                half smoothness = shiny.a * _Smoothness;
                half oneMinusReflectivity = kDieletricSpec.a - metallic * kDieletricSpec.a;
                half reflectivity = 1 - oneMinusReflectivity;
                half3 spec = lerp(kDielectricSpec.rgb, albedo, metallic) * _SpecColor;
                albedo *= oneMinusReflectivity;
            #else
                #ifdef _SHINY_ROUGHNESS
                    half3 spec = _SpecColor;
                    half smoothness = (1 - shiny.r) * _Smoothness;
                #else
                    half3 spec = shiny.rgb * _SpecColor;
                    half smoothness = sqrt(shiny.a) * _Smoothness;
                #endif

                half reflectivity = ReflectivitySpecular(spec);
                half oneMinusReflectivity = 1 - reflectivity;
                albedo = lerp(albedo, albedo * (half3(1.0h, 1.0h, 1.0h) - spec), _Metallic);
            #endif
             
                half grazingTerm = saturate(smoothness + reflectivity);
                half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
                half roughness = max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN);
                half normalizationTerm = roughness * 4 + 2;
                half roughness2MinusOne = (roughness * roughness) - 1;

                float3 halfDir = SafeNormalize(float3(light.direction) + float3(viewDir));
                float NoH = saturate(dot(normal, halfDir));
                half LoH = saturate(dot(light.direction, halfDir));
                float d = NoH * NoH * roughness2MinusOne + 1.00001f;
                half LoH2 = LoH * LoH;
                half specularTerm = (roughness * roughness) / 
                    ((d * d) * max(0.1h, LoH2) * (roughness * 4 + 2));

                half occlusion = tex2D(_OcclusionMap, uv).g;
                occlusion = (1 - min(1, _OcclusionStrength)) + occlusion * min(1, _OcclusionStrength);
                return (diffuse * albedo + spec * specularTerm) * occlusion;
            }

            float GetParallax(float2 uv, float3 viewDir)
            {
                float parallax = 0;
                int steps = max(1, min(_Steps, 64));
                for (int i = 0; i < steps; i++)
                {
                        float fade = 1 - (float)i / steps;
                        parallax += tex2D(_ParallaxMap, uv + fade * _Parallax *
                            normalize(viewDir)).g * fade;
                }
                parallax /= steps;
                return parallax;
            }
            
            half4 frag(v2f_TS i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float parallax = GetParallax(i.uv.zw, i.viewDirTS);
                float2 offset = ParallaxOffset1Step(parallax, _Amplitude, i.viewDirTS);
                float3 n1 = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
                float3 n2 = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy + offset), _BumpScale);
                ///we don't want to just lerp the normals because they'll cancel each
                ///other out. instead we want an effect like two things engraved
                ///on top of each other
                float3 normal = normalize(half3(n1.xy + n2.xy, n1.z * n2.z));
                half4 shiny = tex2D(_MetallicGlossMap, i.uv.xy);
                half3 emission = tex2D(_EmissionMap, i.uv.xy + offset) * _EmissionColor;

                half4 col = tex2D(_BaseMap, i.uv.xy + offset);
            #ifdef _ALPHATEST_ON
                clip(col.a - _Cutoff);
            #endif
                col *= lerp(_BaseColor, _ParallaxColor, parallax);
                half3 worldViewDir = SafeNormalize(i.worldViewDir);
                float sgn = i.tangentWS.w; 
                float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3 worldNormal = TransformTangentToWorld(normal, 
                    half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));
                worldNormal = NormalizeNormalPerPixel(worldNormal);

            #ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord = i.shadowCoord;
            #else
                float4 shadowCoord = float4(0, 0, 0, 0);
            #endif

                Light l1 = GetMainLight(shadowCoord);
                Light l2 = GetMainLight(shadowCoord + float4(offset, offset));
                half3 d1 = LightingToon(l1, worldNormal, 
                    i.uv.xy + offset, worldViewDir, col.rgb, shiny);
                half3 d2 = LightingToon(l2, worldNormal, 
                    i.uv.xy + offset, worldViewDir, col.rgb, shiny);

                half3 diffuse = lerp(d1, d2, parallax);

                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light1 = GetAdditionalLight(lightIndex, i.positionWS);
                    Light light2 = GetAdditionalLight(lightIndex, i.positionWS + float4(offset, offset));
                     half3 a1 = LightingToon(light1, worldNormal, 
                        i.uv.xy + offset, worldViewDir, col.rgb, shiny);
                    half3 a2 = LightingToon(light2, worldNormal, 
                        i.uv.xy + offset, worldViewDir, col.rgb, shiny);
                    diffuse += lerp(a1, a2, parallax);
                }
                #endif
                ////////////////////////////////////

                return half4(diffuse + emission, col.a);
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
