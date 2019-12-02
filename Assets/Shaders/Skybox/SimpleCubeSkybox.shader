//an improvement on
//https://assetstore.unity.com/packages/vfx/shaders/free-skybox-cubemap-extended-shader-standard-edition-107400
//(which is itself an improvement on the Unity builtin Skybox/Cubemap shader)
//kept all properties named the same so that if you were using the previous version you can easily just switch to this one
//My Fixes:
//Removed a lot of useless cruft left by Amplify Shader Editor and translated the shader into something more human readable
//"Fog Fill" now controls the opacity of the fog, which I think may be the original intention implemented poorly?
//Added _SeaLevel property for up/down offset of the horizon so the fog can actually seem to come from somewhere logical in relation to your cube texture
//this is now a vert/frag shader rather than a surface shader, making it more efficient
//Unity's built-in fog is now also applied, since if you're gonna have fog on your skybox might as well go all the way
//removed the keywords to prevent further polluting global shader keywords (the calculations are cheap enough to not warrant them anyway)
//added back the stereo view and instancing support that existed in the original
//
//if you have any questions hmu https://twitter.com/ManuelaXibanya
//Shared under a CreativeCommonsAttribution 4.0 International License

Shader "Xibanya/Skybox/SimpleCubemap"
{
	Properties
	{
		[Gamma][Header(Cubemap)]_Tint("Tint Color", Color) = (0.5,0.5,0.5,1)
		_Exposure("Exposure", Range(0 , 8)) = 1
		[NoScaleOffset]_Tex("Cubemap (HDR)", CUBE) = "black" {}
		[IntRange]_Rotation("Rotation", Range(0 , 360)) = 0
		_RotationSpeed("Rotation Speed", Float) = 1
		_FogHeight("Fog Height", Range(0 , 1)) = 1
		_FogSmoothness("Fog Smoothness", Range(0.01 , 1)) = 0.01
		_FogFill("Fog Fill", Range(0 , 1)) = 0.5
		_SeaLevel("Horizon Offset", float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"RenderType" = "Background"
			"Queue" = "Background"
			"IgnoreProjector" = "True"
			"PreviewType" = "Skybox"
		}
		ZWrite Off
		Cull Off

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct appdata_t {
			float4 vertex : POSITION;
			UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 eyeVec	: TEXCOORD0;
				float3 worldPos	: TEXCOORD1;
				UNITY_FOG_COORDS(2)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			samplerCUBE _Tex;
			half4		_Tex_HDR;
			half		_Rotation; 
			half		_RotationSpeed;
			half4		_Tint;
			half		_Exposure;
			half		_FogHeight;
			half		_FogSmoothness;
			half		_FogFill;
			half		_SeaLevel;

			float3 RotateAroundYInDegrees(float3 worldPos)
			{
				float aspect = lerp(1, (unity_OrthoParams.y / unity_OrthoParams.x), unity_OrthoParams.w);
				half rotation = _Rotation + (_Time.y * _RotationSpeed);
				float radians = rotation * UNITY_PI / 180;
				float sina, cosa;
				sincos(radians, sina, cosa);
				float3 xRot = float3(cosa, 0, -sina);
				float3 yRot = float3(0, aspect, 0);
				float3 zRot = float3(sina, 0, cosa);
				float3x3 rotationMatrix = float3x3(xRot, yRot, zRot);
				return mul(rotationMatrix, normalize(worldPos));
			}

			v2f vert(appdata_t v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.eyeVec = RotateAroundYInDegrees(o.worldPos);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			half4 frag(v2f i) : SV_TARGET
			{
				half4 cubeMap = texCUBE(_Tex, i.eyeVec);
				half4 col = half4(DecodeHDR(cubeMap, _Tex_HDR), 0) * unity_ColorSpaceDouble * _Tint * _Exposure;
				half fogValue = saturate(abs(normalize(i.worldPos).y / _FogHeight - _SeaLevel));
				fogValue = 1 - smoothstep(min(0.99, _FogSmoothness), 1, fogValue);
				col.rgb = lerp(col.rgb, unity_FogColor, _FogFill * fogValue);
				UNITY_APPLY_FOG(i.fogCoord, col.rgb);
				return col;
			}

			ENDCG
		}
	}
}
