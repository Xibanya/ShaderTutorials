// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_UIE_INCLUDED
#define UNITY_UIE_INCLUDED

#ifndef UIE_SKIN_USING_CONSTANTS
    #if SHADER_TARGET < 45
        #define UIE_SKIN_USING_CONSTANTS
    #endif // SHADER_TARGET < 30
#endif // UIE_SKIN_USING_CONSTANTS

#ifndef UIE_RECTCLIP_USING_BUFFER
    #if SHADER_TARGET >= 45
        #define UIE_RECTCLIP_USING_BUFFER
    #endif // SHADER_TARGET
#endif // UIE_RECTCLIP_USING_BUFFER

// The value below is only used on older shader targets, and should be configurable for the app at hand to be the smallest possible
#ifndef UIE_SKIN_ELEMS_COUNT_MAX_CONSTANTS
#define UIE_SKIN_ELEMS_COUNT_MAX_CONSTANTS 20
#endif // UIE_SKIN_ELEMS_COUNT_MAX_CONSTANTS

#include "UnityCG.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _MainTex_TexelSize;

sampler2D _FontTex;
float4 _FontTex_ST;

sampler2D _CustomTex;
float4 _CustomTex_ST;

fixed4 _Color;
float4 _1PixelClipInvView; // xy in clip space, zw inverse in view space
float4 _Viewport;
float2 _RenderTargetSize;

struct appdata_t
{
    float4 vertex   : POSITION;
    float4 color    : COLOR;
    float2 uv       : TEXCOORD0;
    float3 idsAndFlags : TEXCOORD1; // x=transform id, y=clipping rect id, z=flags
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 vertex   : SV_POSITION;
    fixed4 color    : COLOR;
    float2 uv       : TEXCOORD0;
    nointerpolation fixed4 flags : TEXCOORD1;
#ifdef UIE_RECTCLIP_USING_BUFFER
    float4 clipping : TEXCOORD2;
#endif
    UNITY_VERTEX_OUTPUT_STEREO
};

static const float kUIEVertexLastFlagValue = 6.0f;

struct ClippingData { float4 worldRect, viewRect, skinningRect; };  // x=left, y=bottom, z=right, w=top
struct SkinningData { float4 row0, row1, row2; };

float4 skinningToView(float4 pt, SkinningData skinningData)
{
    pt.x = dot(pt, skinningData.row0);
    pt.y = dot(pt, skinningData.row1);
    pt.z = dot(pt, skinningData.row2);
    return pt;
}

// Returns the view-space offset that must be applied to the vertex to satisfy a minimum displacement constraint.
// embeddedDisplacement Displacement vector that is embedded in vertex, in vertex-space.
// minDisplacement      Minimum length of the displacement that must be observed, in pixels.
float2 uie_get_border_offset(float2 displacementVector, float minDisplacement, SkinningData skinningData)
{
    // Compute the displacement length in framebuffer space (unit = 1 pixel).
    float2 viewDisplacement = skinningToView(float4(displacementVector, 0, 0), skinningData).xy;
    float frameDisplacementLength = length(viewDisplacement * _1PixelClipInvView.zw);

    // We need to meet the minimum displacement requirement before rounding so that we can simply add 1 after rounding
    // if we don't meet it anymore.
    float newFrameDisplacementLength = max(minDisplacement, frameDisplacementLength);
    newFrameDisplacementLength = round(newFrameDisplacementLength);
    newFrameDisplacementLength += step(newFrameDisplacementLength, minDisplacement - 0.001);

    // Convert the resulting displacement into an offset.
    float changeRatio = newFrameDisplacementLength / (frameDisplacementLength + 0.000001);
    float2 viewOffset = (changeRatio - 1) * viewDisplacement;

    return viewOffset;
}

float4 viewToWorld(float4 pt)
{
    return mul(UNITY_MATRIX_MV, pt);
}

float4 worldToClip(float4 pt)
{
    return mul(UNITY_MATRIX_P, pt);
}

float4 skinningToClip(float4 pt, SkinningData skinningData)
{
    pt = skinningToView(pt, skinningData);
    return mul(UNITY_MATRIX_MVP, pt);
}

#ifdef UIE_RECTCLIP_USING_BUFFER

float4 uie_compute_clipping(SkinningData skinningData, ClippingData clippingData)
{
    // The min/max corners are assuming a UI coordinate system whose origin is at the top-left corner of the screen.
    float4 minCorner = float4(clippingData.skinningRect.x, clippingData.skinningRect.y, 0, 1);
    float4 maxCorner = float4(clippingData.skinningRect.z, clippingData.skinningRect.w, 0, 1);

    // Apply the fast transform.
    minCorner = skinningToView(minCorner, skinningData);
    minCorner = minCorner / minCorner.w;

    maxCorner = skinningToView(maxCorner, skinningData);
    maxCorner = maxCorner / maxCorner.w;

    // Intersect with the view rect.
    minCorner.xy = max(minCorner.xy, clippingData.viewRect.xy);
    maxCorner.xy = min(maxCorner.xy, clippingData.viewRect.zw);
    maxCorner.xy = max(maxCorner.xy, minCorner.xy);

    // Apply the view transform.
    minCorner = viewToWorld(minCorner);
    minCorner = minCorner / minCorner.w;

    maxCorner = viewToWorld(maxCorner);
    maxCorner = maxCorner / maxCorner.w;

    // Intersect with the world rect.
    minCorner.xy = max(minCorner.xy, clippingData.worldRect.xy);
    maxCorner.xy = min(maxCorner.xy, clippingData.worldRect.zw);
    maxCorner.xy = max(maxCorner.xy, minCorner.xy);

    // Apply the projection. At this point, min/max isn't a representative naming anymore, because the UI projection
    // matrix flips the vertical axis upside down, hence the renaming where topLeft and bottomRight are relative to the
    // clip-space, where y increases vertically.
    float4 topLeft = worldToClip(minCorner);
    topLeft = topLeft / topLeft.w;

    float4 bottomRight = worldToClip(maxCorner);
    bottomRight = bottomRight / bottomRight.w;

    // We must provide the min/max corners to the fragment shader in the same space as that of the vertex position
    // input of the fragment shader.
#if UNITY_UV_STARTS_AT_TOP
    // With DirectX, the vertex position input of the fragment shader increases from top to bottom. This is a vertical
    // flip compared to the clip space, so we just multiply the y values by -1.
    return float4(topLeft.x, -topLeft.y, bottomRight.x, -bottomRight.y);
#else
    // With OpenGL, the vertex position input of the fragment shader increases from bottom to top. There is no vertical
    // flip involved, but min is bottom-left and max is top-right which we must deduce from our bottomRight and topLeft
    // coordinates.
    return float4(topLeft.x, bottomRight.y, bottomRight.x, topLeft.y);
#endif // UNITY_UV_STARTS_AT_TOP
}

void uie_apply_clipping(v2f IN)
{
#if UNITY_UV_STARTS_AT_TOP
    float2 v = IN.vertex.xy - float2(_Viewport.x, _RenderTargetSize.y - _Viewport.y - _Viewport.w);
#else
    float2 v = IN.vertex.xy - float2(_Viewport.x, _Viewport.y);
#endif
    float2 clipSpacePos = v * _1PixelClipInvView.xy - 1;
    float2 minCorner = IN.clipping.xy;
    float2 maxCorner = IN.clipping.zw;

    float4 clipValue;
    clipValue.xy = clipSpacePos - minCorner;
    clipValue.zw = maxCorner - clipSpacePos;
    clip(clipValue);
}

#endif // UIE_RECTCLIP_USING_BUFFER

float TestForValue(float value, inout float flags)
{
#if SHADER_API_GLES
    float result = saturate(flags - value + 1.0);
    flags -= result * value;
    return result;
#else
    return flags == value;
#endif
}

v2f uie_std_vert_core(appdata_t v, SkinningData skinningData, ClippingData clippingData)
{
    v2f OUT;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

    float flags = v.idsAndFlags.z;
    // Keep the descending order for GLES2
    const float isSVGGradients = TestForValue(5.0, flags);
    const float isEdge = TestForValue(4.0, flags);
    const float isCustom = TestForValue(3.0, flags);
    const float isTextured = TestForValue(2.0, flags);
    const float isText = TestForValue(1.0, flags);

    float2 viewOffset = float2(0, 0);
    if (isEdge == 1)
        viewOffset = uie_get_border_offset(v.uv, 1, skinningData);

    v.vertex = skinningToView(v.vertex, skinningData);
    v.vertex.xy += viewOffset;

    OUT.vertex = mul(UNITY_MATRIX_MVP, float4(v.vertex.xyz, 1));
    OUT.uv = TRANSFORM_TEX(v.uv, _MainTex);
    if (isTextured == 1.0f && isCustom == 0.0f)
        OUT.uv *= _MainTex_TexelSize.xy;
    OUT.color = v.color * _Color;
    OUT.flags = fixed4(isText, isTextured, isCustom, 1 - saturate(isText + isTextured + isCustom));

#ifdef UIE_RECTCLIP_USING_BUFFER
    OUT.clipping = uie_compute_clipping(skinningData, clippingData);
#endif // UIE_RECTCLIP_USING_BUFFER

    return OUT;
}

fixed4 uie_std_frag(v2f IN)
{
#ifdef UIE_RECTCLIP_USING_BUFFER
    uie_apply_clipping(IN);
#endif // UIE_RECTCLIP_USING_BUFFER

    // Extract the flags.
    fixed isText     = IN.flags.x;
    fixed isTextured = IN.flags.y;
    fixed isCustom   = IN.flags.z;
    fixed isSolid    = IN.flags.w;

    half4 atlasColor = tex2D(_MainTex, IN.uv) * isTextured;
    half4 fontColor = half4(1, 1, 1, tex2D(_FontTex, IN.uv).a) * isText;
    half4 customColor = tex2D(_CustomTex, IN.uv) * isCustom;

    half4 texColor = (half4)isSolid + atlasColor + fontColor + customColor;
    half4 color = texColor * IN.color;
    return color;
}


#ifdef UIE_SKIN_USING_CONSTANTS

CBUFFER_START(UITransforms)
float4 _Transforms[UIE_SKIN_ELEMS_COUNT_MAX_CONSTANTS * 3]; // 3 float4s map to matrix 3 columns (the projection column is ignored)
CBUFFER_END

SkinningData uie_get_skinning_data(float id)
{
    SkinningData skinningData;
    skinningData.row0 = _Transforms[id * 3 + 0];
    skinningData.row1 = _Transforms[id * 3 + 1];
    skinningData.row2 = _Transforms[id * 3 + 2];
    return skinningData;
}

#else // !UIE_SKIN_USING_CONSTANTS

struct Transform3x4 { float4 v0, v1, v2; };
StructuredBuffer<Transform3x4> _TransformsBuffer; // 3 float4s map to matrix 3 columns (the projection column is ignored)

SkinningData uie_get_skinning_data(float id)
{
    Transform3x4 transform = _TransformsBuffer[id];
    SkinningData skinningData;
    skinningData.row0 = transform.v0;
    skinningData.row1 = transform.v1;
    skinningData.row2 = transform.v2;
    return skinningData;
}

#endif // UIE_SKIN_USING_CONSTANTS


#ifdef UIE_RECTCLIP_USING_BUFFER

StructuredBuffer<ClippingData> _ClippingBuffer;

ClippingData uie_get_clipping_rect(float id)
{
    return _ClippingBuffer[id];
}

#else // !UIE_RECTCLIP_USING_BUFFER

ClippingData uie_get_clipping_rect(float id)
{
    ClippingData data;
    data.worldRect = float4(-1000000, -1000000, 1000000, 1000000);
    data.viewRect = float4(-1000000, -1000000, 1000000, 1000000);
    data.skinningRect = float4(-1000000, -1000000, 1000000, 1000000);
    return data;
}

#endif


v2f uie_std_vert(appdata_t v)
{
    SkinningData skinningData = uie_get_skinning_data(v.idsAndFlags.x);
    ClippingData clippingData = uie_get_clipping_rect(v.idsAndFlags.y);
    return uie_std_vert_core(v, skinningData, clippingData);
}

#ifndef UIE_CUSTOM_SHADER

v2f vert(appdata_t v) { return uie_std_vert(v); }
fixed4 frag(v2f IN) : SV_Target { return uie_std_frag(IN); }

#endif // UIE_CUSTOM_SHADER

#endif // UNITY_UIE_INCLUDED
