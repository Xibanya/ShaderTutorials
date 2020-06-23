Shader "Hidden/Xibanya/Effects/DepthToon"
{
	HLSLINCLUDE
	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
	#define tex2D(idx, uv) SAMPLE_TEXTURE2D(idx, sampler##idx, uv)
	#define sampler2D(idx) TEXTURE2D_SAMPLER2D(idx, sampler##idx)
	#define v2f VaryingsDefault

	sampler2D(_MainTex);
	sampler2D(_CameraDepthTexture);
	sampler2D(_CameraGBufferTexture0);
	sampler2D(_CameraGBufferTexture2);

	half4	_Color;
	half4	_ShadowColor;

	half	_Range;
	half	_Falloff;

	half	_Softness;
	half	_Coverage;
	float3	_LightDir;

	float4x4 _Inverse;
	float2	_Size;

	sampler2D(_GlobalScreenSpaceShadows);
	int		_CastShadows;

	half4 frag(v2f i) : SV_Target
	{
		half4 col = tex2D(_MainTex, i.texcoord);
		half4 albedo = tex2D(_CameraGBufferTexture0, i.texcoord);
		float3 normal = tex2D(_CameraGBufferTexture2, i.texcoord).xyz;

		half selfShadow = 1 - (dot(normal, _LightDir) * 0.5 + 0.5);
		selfShadow = pow(selfShadow, lerp(1, 4, _Coverage));
		selfShadow = smoothstep(0.5, lerp(0.5, 1, _Softness), selfShadow);
		selfShadow *= tex2D(_GlobalScreenSpaceShadows, i.texcoord).r * _CastShadows + (1 - _CastShadows);
		half4 diffuse = lerp(_ShadowColor, _Color, selfShadow) * albedo;

		float depth = SAMPLE_DEPTH_TEXTURE(
			_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord);
		depth = Linear01Depth(depth);
		float4 p = float4((i.texcoord.x * 2 - 1) * _Size.x, i.texcoord.y * _Size.y, depth, 1);
		float3 worldPos = mul(_Inverse, p);
		float dist = 1 - distance(_WorldSpaceCameraPos, worldPos);

		float range = ((depth * _ProjectionParams.z) - _ProjectionParams.y) * (1 - _Range);
		range = saturate(exp2(-range * range));
		range = smoothstep(0.25, lerp(0.25, 1, _Falloff), range * dist);
		return lerp(col, diffuse, range * step(depth, 0.999));
	}
	ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment frag
            ENDHLSL
        }
    }
}