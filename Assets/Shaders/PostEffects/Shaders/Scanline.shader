Shader "Hidden/Xibanya/Effects/Scanline"
{
	HLSLINCLUDE
	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
	#define tex2D(idx, uv) SAMPLE_TEXTURE2D(idx, sampler##idx, uv)
	#define sampler2D(idx) TEXTURE2D_SAMPLER2D(idx, sampler##idx)
	#define v2f VaryingsDefault

	sampler2D(_MainTex);
	int		_Height;
	half4	_Color;
	half	_Speed;

	half4 frag(v2f i) : SV_Target
	{
		half3 mainTex = tex2D(_MainTex, i.texcoord);
		half scroll = sin(_Time.y * _Speed);
		float scanline = sin((i.texcoord.y - scroll) * _Height) * 0.5 + 0.5;
		mainTex = lerp(mainTex, mainTex * _Color.rgb, _Color.a * scanline);
		return half4(mainTex, 1);
	}
	ENDHLSL

    SubShader
    {
		ZTest Always Cull Off ZWrite On
		Pass
		{
			HLSLPROGRAM
			#pragma vertex VertDefault
			#pragma fragment frag
			ENDHLSL
		}
    }
}