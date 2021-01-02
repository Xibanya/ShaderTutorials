Shader "Xibanya/URP/Lit/XibLitDissolve"
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
        [Header(Dissolve)]
        [KeywordEnum(Screen, Pos, UV)] _Coords("Dissolve coords", float) = 0
	[NoScaleOffset]_Noise("Dissolve Mask", 2D) = "white" {}
        _DissolveScale("Dissolve Scale", float) = 1
        [NoScaleOffset]_Edge("Edge Mask", 2D) = "white" {}
        _EdgeScale("Noise Scale", float) = 1
	_DissolveAmount("Dissolve Amount", Range(0, 1)) = 0.1
	_DissolveLine("Dissolve Line", Range(0, 0.2)) = 0.1
	[HDR]_DissolveLineColor("Dissolve Line Color", Color) = (1,1,1,1)
	_DissolveLineSmooth("Dissolve Line Smooth", Range(0, 1)) = 0
        _LineCutoff("Line cutoff", Range(0,1)) = 0.5
        _Scroll("Scroll: XY Noise, ZW Edge", Vector) = (0, 0, 0, 0)
        _RimPower("Rim Power", Range(0, 2)) = 1
        [Space]
        [Header(Options)]
	[Toggle] _ALPHATEST("Cutout?", float) = 0
	_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _Src("Source Blend", float) = 5
	[Enum(UnityEngine.Rendering.BlendMode)] _Dst("Destination Blend", float) = 10
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
        Cull [_Cull]
        HLSLINCLUDE
        #pragma multi_compile_instancing
        ///not entirely sure of this difference between 
        ///shader_feature_local_fragment and shader_feature_local
        ///probably has something to do with how batching/instancing
        ///works in URP. basically, when in Rome, do as the Romans 
        ///write their own shaders
        #pragma shader_feature_local_fragment _ALPHATEST_ON
        #pragma multi_compile _COORDS_SCREEN _COORDS_POS _COORDS_UV
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../Lib/XibSpite.hlsl"

        TEXTURE2D(_Noise);      SAMPLER(sampler_Noise);
        TEXTURE2D(_Edge);       SAMPLER(sampler_Edge);
           
        CBUFFER_START(UnityPerMaterial)
        float4  _BaseMap_ST;
        float4  _BumpMap_ST;
        float4  _Noise_ST;
        float4  _Edge_ST;
        half4   _BaseColor;
        half    _Cutoff;
        half	_DissolveScale;
        half	_DissolveAmount;
        half	_DissolveLine;
        half	_DissolveLineSmooth;
        half4	_DissolveLineColor;
        half4   _Scroll;
        half    _LineCutoff;
        half    _BumpScale;
        half    _Threshold;
        half    _ShadowSoftness;
        half3   _ShadowColor;
        half    _EdgeScale;
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

        struct v2f
        {
        #ifdef _NORMALMAP
            float4 uv           : TEXCOORD0;
        #else
            float2 uv           : TEXCOORD0;
        #endif
            DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
            float3 positionWS   : TEXCOORD2;

        #ifdef _NORMALMAP
            float4 normalWS     : TEXCOORD3;    // xyz: normal, w: viewDir.x
            float4 tangentWS    : TEXCOORD4;    // xyz: tangent, w: viewDir.y
            float4 bitangentWS  : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
        #else
            float3 normalWS     : TEXCOORD3;
            float3 viewDirWS    : TEXCOORD4;
        #endif
            float4 screenPos    : TEXCOORD6;

        #ifdef _MAIN_LIGHT_SHADOWS
            float4 shadowCoord  : TEXCOORD7;
        #endif

            float4 positionCS   : SV_POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f DissolveVert(appdata v)
        {
            v2f o = (v2f)0;

            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_TRANSFER_INSTANCE_ID(v, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
            o.screenPos = vertexInput.positionNDC;
            VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
            half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
            half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
            half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

        #ifdef _NORMALMAP
            o.uv.xy = TRANSFORM_TEX(v.texcoord, _BaseMap);
            o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
            o.normalWS = half4(normalInput.normalWS, viewDirWS.x);
            o.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
            o.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
        #else
            o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
            o.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
            o.viewDirWS = viewDirWS;
        #endif

            OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
            OUTPUT_SH(o.normalWS.xyz, o.vertexSH);

        //#ifdef _ADDITIONAL_LIGHTS
            o.positionWS = vertexInput.positionWS;
        //#endif

        #if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
            o.shadowCoord = GetShadowCoord(vertexInput);
        #endif

            o.positionCS = vertexInput.positionCS;
            return o;
        }

        ///Get uvs for unpacking noise texture if _COORDS_POS is enabled
        float2 DissolveCoords(float3 worldPos, float3 worldNormal)
        {
            float3 localPos = worldPos - TransformObjectToWorld(float3(0, 0, 0));
            half zMask = 1 - dot(worldNormal, float3(0, 0, 1) * 0.5 + 0.5);
			half xMask = 1 - dot(worldNormal, float3(1, 0, 0) * 0.5 + 0.5);
            float2 side1 = (1 - zMask) * xMask * localPos.xy;
            float2 side2 =  zMask * (1 - xMask) * localPos.zy;
            return side1 + side2;
        }
        ///Not only does this return the line color to be added
        ///to the final diffuse color, it also handles all the pixel
        ///discarding (clip) so should be called even when no color
        ///is needed (shadowcaster, depth pass) to make sure the cutouts 
        ///are applied
        half3 GetDissolveLine(float2 uvNoise, float rim)
        {
            half4 noise = tex2D(_Noise, 
                uvNoise * _DissolveScale + _Time.x * _Scroll.xy);
            clip(noise.r + rim - _DissolveAmount);
            ///offset edge UV from the noise offset so it appears to be 
            ///scrolling in relative relation
            float2 edgeNoiseOffset = _Time.x * (_Scroll.zw + _Scroll.xy);
            half edgeNoise = tex2D(_Edge, uvNoise * _EdgeScale + edgeNoiseOffset).r;
            half edge = (_DissolveAmount + _DissolveLine - noise.r) * 0.5 + 0.5;
			edge = smoothstep(0.5, max(0.5, _DissolveLineSmooth), edge);
            half3 lineColor = lerp(0, _DissolveLineColor, saturate(edgeNoise));
            half toClip = lerp(noise.r, edgeNoise, saturate(edge));
            clip(toClip + noise.r + rim - _LineCutoff);
            return edge * lineColor;
        }

        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags{ "LightMode" = "UniversalForward"  }
            Blend [_Src] [_Dst]

            HLSLPROGRAM
            ///You have to have these two pragmas for shit to work
            ///right due to stupid reasons, just leave 'em
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma target 4.5

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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

            #pragma vertex DissolveVert
            #pragma fragment frag

        #ifdef _COORDS_SCREEN
            #define DISS_UV (i.screenPos.xy / i.screenPos.w)
        #elif defined(_COORDS_POS)
            #define DISS_UV DissolveCoords(i.positionWS, worldNormal)
        #else
            #define DISS_UV i.uv.xy
        #endif

            half    _RimPower;

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

                half4 col = tex2D(_BaseMap, i.uv.xy);
                #ifdef _ALPHATEST_ON
					clip(col.a - _Cutoff);
                #endif
                col *= _BaseColor;

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
                ///viewDir has to be normalized to prevent the rim from
                ///sliding around as the viewer gets closer or farther
                float3 viewDir = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float dotProduct = 1 - pow(dot(worldNormal, viewDir), _RimPower);
	            float rim = smoothstep(0.5, 1.0, dotProduct);
	            rim = smoothstep(0, _DissolveLineSmooth, rim);
                finalDiffuse += rim * _DissolveLineColor;
                finalDiffuse += GetDissolveLine(DISS_UV, rim);
                return half4(finalDiffuse, 1);
                
            }
            ENDHLSL
        }
        ///This doesn't apply the cutouts, I still haven't figured out why
        ///ofc point lights can't even cast realtime shadows in URP so just lol
        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma _MAIN_LIGHT_SHADOWS
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        #ifdef _COORDS_SCREEN
            #define DISS_UV (i.screenPos.xy / i.screenPos.w)
        #elif defined(_COORDS_POS)
            #define DISS_UV DissolveCoords(i.positionWS, i.normalWS)
        #else
            #define DISS_UV i.uv.xy
        #endif
            v2f ShadowVert(appdata v)
            {
                v2f o = vert(v);
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.pos = TransformWorldToHClip(
                    ApplyShadowBias(worldPos, worldNormal, _LightDirection));

            #if UNITY_REVERSED_Z
                o.pos.z = min(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
            #else
                o.pos.z = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
            #endif
                return o;
            }
            half4 ShadowFrag(v2f i) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
               
            #ifdef _ALPHATEST_ON
                 half4 col = tex2D(_BaseMap, i.uv.xy);
				clip(col.a - _Cutoff);
            #endif
                half3 dissLine = GetDissolveLine(DISS_UV, 0);
                return 0;
			}
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags{ "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DissolveVert
            #pragma fragment frag
            #pragma multi_compile _ DOTS_INSTANCING_ON
        #ifdef _COORDS_SCREEN
             #define DISS_UV (i.screenPos.xy / i.screenPos.w)
        #elif defined(_COORDS_POS)
            #define DISS_UV DissolveCoords(i.positionWS, i.normalWS)
        #else
            #define DISS_UV i.uv.xy
        #endif
            ///it appears the only purpose of this frag function is 
            ///to discard pixels in the event of a cutout
            ///but since the point of this shader IS the cutout
            ///we have to go thru nearly the entire function as
            ///used in the ForwardBase (or whatever) pass
            half4 frag(v2f i) : SV_TARGET
			{
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
               
            #ifdef _ALPHATEST_ON
                half4 col = tex2D(_BaseMap, i.uv.xy);
				clip(col.a - _Cutoff);
            #endif
                half3 dissLine = GetDissolveLine(DISS_UV, 0);
                return 0;
			}
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/Meta"
        UsePass "Universal Render Pipeline/Lit/Universal2D"
    }
    FallBack "Universal Render Pipeline/Lit"
}
