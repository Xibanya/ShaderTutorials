#ifndef XIBANYA_URP_LIT_CRAP_INCLUDED
#define XIBANYA_URP_LIT_CRAP_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

///This is mostly just like LitForwardPass 
///except it excludes the frag function so 
///we won't be forced to define some stupid 
///crap we don't need

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
    float4 uv                       : TEXCOORD0;
#else
    float2 uv                       : TEXCOORD0;
#endif
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#ifdef _ADDITIONAL_LIGHTS
    float3 positionWS               : TEXCOORD2;
#endif

#ifdef _NORMALMAP
    float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    float3 normalWS                 : TEXCOORD3;
    float3 viewDirWS                : TEXCOORD4;
#endif

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord              : TEXCOORD7;
#endif

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

v2f vert(appdata v)
{
    v2f o = (v2f)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
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

    o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#ifdef _ADDITIONAL_LIGHTS
    o.positionWS = vertexInput.positionWS;
#endif

#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
    o.shadowCoord = GetShadowCoord(vertexInput);
#endif

    o.positionCS = vertexInput.positionCS;

    return o;
}
#endif