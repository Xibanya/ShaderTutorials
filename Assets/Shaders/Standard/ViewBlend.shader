Shader "Xibanya/ViewBlend"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionMap("Emission Tex", 2D) = "white" {}
		[HDR]_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimPower("Rim Fill", Range(0, 2)) = 0.1
		_RimSmooth("Rim Smoothness", Range(0.5, 1)) = 1
		[Space]
		[HDR]_CenterCol("Center Color", Color) = (1,1,1,1)
		[HDR]_LeftCol("Left Color", Color) = (1,1,1,1)
		[HDR]_RightCol("Right Color", Color) = (1,1,1,1)
		_LeftTex("Blend Tex Left", 2D) = "white" {}
		_CenterTex("Blend Tex Center", 2D) = "white" {}
		_RightTex("Blend Tex Right", 2D) = "white" {}
		_TexSmooth("Tex Blend Smooth", Range(0, 1)) = 0.5
		_ColorSmooth("Color Blend Smooth", Range(0, 1)) = 0.5
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			#pragma surface surf Standard fullforwardshadows
			#pragma target 3.0

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _EmissionMap;

			struct Input
			{
				float2 uv_MainTex;
				float3 viewDir;
			};

			half4 _Color;
			float _NormalStrength;
			half4 _EmissionColor;
			half4 _RimColor;
			half _RimPower;
			half _RimSmooth;
			sampler2D	_LeftTex, _CenterTex, _RightTex;
			half3		_LeftCol, _CenterCol, _RightCol;
			half		_TexSmooth;
			half		_ColorSmooth;

			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb * _Color;
				o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
				o.Normal.z *= _NormalStrength;
				o.Emission = _EmissionColor * tex2D(_EmissionMap, IN.uv_MainTex) * o.Albedo;
				half d = 1 - pow(dot(o.Normal, IN.viewDir), _RimPower);
				o.Emission += _RimColor * smoothstep(0.5, max(0.5, _RimSmooth), d);

				half dotLeft = dot(IN.viewDir, float3(1, 0, 0));
				half dotRight = dot(IN.viewDir, float3(-1, 0, 0));

				half colDotLeft = smoothstep(0, _ColorSmooth, smoothstep(0.5, 1, dotLeft));
				half colDotRight = smoothstep(0, _ColorSmooth, smoothstep(0.5, 1, dotRight));
				half colDotCenter = min((1 - colDotLeft), (1 - colDotRight));
				colDotLeft = max(0, colDotLeft - colDotCenter);
				colDotRight = max(0, colDotRight - colDotCenter);
				half3 colorMix = lerp(lerp(
					lerp(half3(1, 1, 1), _CenterCol, colDotCenter), 
								_LeftCol, colDotLeft),
								_RightCol, colDotRight);
				o.Albedo *= colorMix;

				half4 texCenter = tex2D(_CenterTex, IN.uv_MainTex);
				half4 texLeft = tex2D(_LeftTex, IN.uv_MainTex);
				half4 texRight = tex2D(_RightTex, IN.uv_MainTex);
				half texDotLeft = smoothstep(0, _TexSmooth, smoothstep(0.5, 1, dotLeft));
				half texDotRight = smoothstep(0, _TexSmooth, smoothstep(0.5, 1, dotRight));
				half texDotCenter = min((1 - texDotLeft), (1 - texDotRight));
				texDotLeft = max(0, texDotLeft - texDotCenter);
				texDotRight = max(0, texDotRight - texDotCenter);
				half3 texMix = lerp(lerp(
					lerp(half3(0, 0, 0), texCenter.rgb, texDotCenter * texCenter.a),
					texLeft.rgb, texDotLeft * texLeft.a),
					texRight, texDotRight * texRight.a);
				o.Emission += texMix;

			}
			ENDCG
		}
			FallBack "Diffuse"
}
