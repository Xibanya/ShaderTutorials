#ifndef XIBANYA_URP_FRAG_FUNCTIONS_INCLUDED
#define XIBANYA_URP_FRAG_FUNCTIONS_INCLUDED
// The assumption here is that the frag input struct is 
// the same as that used by the default URP Lit shader
// if that's not true then these probably won't work

/////////////////// MACROS ////////////////////////
#ifdef _NORMALMAP
    #define GET_WORLD_NORMAL half3 normal = \
        UnpackScaleNormal(tex2D(_BumpMap, i.uv.zw), _BumpScale); \
        float3 worldNormal = TransformTangentToWorld(normal, \
        half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz)); \
        worldNormal = NormalizeNormalPerPixel(worldNormal)
#else
        #define GET_WORLD_NORMAL float3 worldNormal = \
            NormalizeNormalPerPixel(i.normalWS);
#endif

#ifdef _MAIN_LIGHT_SHADOWS
    #define SHADOWCOORD i.shadowCoord
#else
    #define SHADOWCOORD float4(0, 0, 0, 0)
#endif
//////////////////////////////////////////////////////////

/// Get diffuse term for simple single-cut toon lighting
/// intended use: elsewhere, lerp(shadow Color, light color, this)
half ToonAtten(Light light, float3 worldNormal, half threshold, 
    half shadowSoftness)
{
    half shadowDot = pow(dot(worldNormal, light.direction) * 0.5 + 0.5, threshold);
    shadowDot = smoothstep(0.5, shadowSoftness, shadowDot);
	return saturate(
        shadowDot * light.distanceAttenuation * light.shadowAttenuation);
}

////////////////////////////////////////////////////////////////////////////////////
#endif