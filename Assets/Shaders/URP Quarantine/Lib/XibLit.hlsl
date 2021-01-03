#ifndef XIBANYA_URP_LIT_CRAP_INCLUDED
#define XIBANYA_URP_LIT_CRAP_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

///This is mostly just like LitForwardPass 
///except it excludes the frag function so 
///we won't be forced to define some stupid 
///crap we don't need

////////////// STRUCTS ////////////////////////
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

#if defined(_ADDITIONAL_LIGHTS) || defined(NEED_WORLDPOS)
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

////////////////////// MACROS ////////////////////////////////
// the point of these is just to make it easy to spin out a 
// different vert function from the one below if needed
// without having to copy over a bunch of crap again
// they all work under the assumption that the above appdata
// and v2f structs have been defined
//
// The reason why these are split out like this is that if
// some effect requires messing with some part of the vert shader
// that can be isolated without having to totally rewrite
// the entire vert shader
// 
// As always, using the "Xib" prefix is not done out
// of vanity but to make it very clear that my stuff
// isn't official unity stuff and to prevent any collisions
//////////////////////////////////////////////////////////////

#define XIB_INIT_V2F v2f o = (v2f)0; \
    UNITY_SETUP_INSTANCE_ID(v); \
    UNITY_TRANSFER_INSTANCE_ID(v, o); \
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

#ifdef _NORMALMAP
#define XIB_PACK_UV_AND_NORMAL  o.uv.xy = TRANSFORM_TEX(v.texcoord, _BaseMap); \
        half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS; \
        o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap); \
        o.normalWS = half4(normalInput.normalWS, viewDirWS.x); \
        o.tangentWS = half4(normalInput.tangentWS, viewDirWS.y); \
        o.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
#define XIB_PACK_UV_AND_NORMAL o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap); \
        o.normalWS = NormalizeNormalPerVertex(normalInput.normalWS); \
        o.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
#endif

#define XIB_FOGFACTOR  half3 vertexLight = \
        VertexLighting(vertexInput.positionWS, normalInput.normalWS); \
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z); \
        o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#define XIB_GET_VERT_INPUTS  VertexPositionInputs vertexInput = \
        GetVertexPositionInputs(v.positionOS.xyz); \
        VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS); \
        o.positionCS = vertexInput.positionCS;

#if defined(_ADDITIONAL_LIGHTS) || defined(NEED_WORLDPOS)
    #define XIB_PACK_WORLDPOS o.positionWS = vertexInput.positionWS;
#else
    #define XIB_PACK_WORLDPOS
#endif

#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
    #define XIB_PACK_SHADOWCOORD o.shadowCoord = GetShadowCoord(vertexInput);
#else 
    #define XIB_PACK_SHADOWCOORD
#endif

#define XIB_PACK_LIGHTMAPS   OUTPUT_LIGHTMAP_UV(\
        v.lightmapUV, unity_LightmapST, o.lightmapUV); \
        OUTPUT_SH(o.normalWS.xyz, o.vertexSH); \
        XIB_PACK_WORLDPOS  XIB_PACK_SHADOWCOORD

////////////////////////////////////////////////////////
///////////////// VERT FUNCTION ////////////////////////
v2f vert(appdata v)
{
    XIB_INIT_V2F
    XIB_GET_VERT_INPUTS
    XIB_FOGFACTOR
    XIB_PACK_UV_AND_NORMAL
    XIB_PACK_LIGHTMAPS
    return o;
}
////////////////////////////////////////////////////////
#endif