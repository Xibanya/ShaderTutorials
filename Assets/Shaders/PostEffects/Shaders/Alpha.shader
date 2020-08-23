Shader "Hidden/Xibanya/Alpha"
{
	HLSLINCLUDE
	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	#define tex2D(tex, uv) SAMPLE_TEXTURE2D(tex, sampler##tex, \
			UnityStereoTransformScreenSpaceTex(uv))
	
	half _Alpha;

	half4 Frag(VaryingsDefault i) : SV_Target
	{
		half4 color = tex2D(_MainTex, i.texcoord.xy);
		color.a *= _Alpha;
		return color;
	}
	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			HLSLPROGRAM
			#pragma vertex VertDefault
			#pragma fragment Frag
			ENDHLSL
		}
	}
}