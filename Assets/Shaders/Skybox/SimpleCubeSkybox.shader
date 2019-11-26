//https://twitter.com/ManuelaXibanya
//https://www.patreon.com/teamdogpit
//Shared under a CreativeCommonsAttribution 4.0 International License

Shader "Xibanya/Skybox/SimpleCubeSkybox"
{
	Properties
	{
		[Gamma][Header(Cubemap)]_TintColor("Tint Color", Color) = (0.5,0.5,0.5,1)
		_Exposure("Exposure", Range(0 , 8)) = 1
		[NoScaleOffset]_SkyCube("Cubemap (HDR)", CUBE) = "black" {}
		[IntRange]_Rotation("Rotation", Range(0 , 360)) = 0
	}

	SubShader
	{
		Tags
		{ 
			"RenderType" = "Background"
			"Queue" = "Background+0"
			"IgnoreProjector" = "True"
			"IsEmissive" = "true"
			"PreviewType" = "Skybox"
		}
		Blend Off
		Lighting Off
		ZWrite Off
		Cull Off

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos		: SV_POSITION;
				float3 eyeVec	: TEXCOORD0;
			};

			samplerCUBE _SkyCube;
			half4		_SkyCube_HDR;
			half		_Rotation;
			half4		_TintColor;
			half		_Exposure;

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float aspect = lerp(1.0, (unity_OrthoParams.y / unity_OrthoParams.x), unity_OrthoParams.w);
				float3 xRot = float3(cos(radians((_Rotation))), 0.0, (sin(radians(_Rotation)) * -1.0));
				float3 yRot = float3(0.0, aspect, 0.0);
				float3 zRot = float3(sin(radians(_Rotation)), 0.0, cos(radians(_Rotation)));
				//this step is needed so the skybox doesn't rotate with the camera view  
				o.eyeVec = mul(float3x3(xRot, yRot, zRot), normalize(worldPos));
				return o;
			}

			half4 frag(v2f i) : SV_TARGET
			{
				half4 cubeMap = texCUBE(_SkyCube, i.eyeVec);
				half4 col = half4(DecodeHDR(cubeMap, _SkyCube_HDR), 0) * unity_ColorSpaceDouble * _TintColor * _Exposure;
				return col;
			}

			ENDCG
		}
	}
}
