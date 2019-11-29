Shader "Xibanya/Effects/XibGlass"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "bump" {}
		_DistortionPower("Distortion Power", range(0, 1)) = 0.5
		[Header]
		[Header(Shadow)]
		_Thresh("Shadow Threshold", Range(0,2)) = 1
		_ShadowSmooth("Shadow Smoothness", Range(0.5, 1)) = 0.6
		_ShadowColor("Shadow Color", Color) = (0,0,0,1)
		[Space]
		[Header(Rim)]
		[HDR]_RimColor("Rim Color", Color) = (0.5556639, 0.3725525, 0.8679245,1)
		_RimPower("Rim Fill", Range(0, 2)) = 0.1
		_RimSmooth("Rim Smoothness", Range(0.5, 1)) = 1
		_SideRimSize("Side Rim Size", Range(0, 1)) = 0.5
		[Space]
		[Header(Gloss)]
		_Glossiness("Glossiness", Range(0, 1)) = 0.75
		_Metallic("Metallic", Range(0, 1)) = 0.5
		_Occlusion("Occlusion", Range(0, 1)) = 1
		[Space]
		[HDR]_GlossColor("Gloss Color", Color) = (1,1,1,1)
		_GlossSize("Gloss Size", Range(0, 1)) = 0.5
		_GlossSmoothness("Gloss Smoothness", Range(0, 1)) = 0
	}
		SubShader
		{
			Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }

			Blend SrcAlpha OneMinusSrcAlpha
			Pass
			{
				ZWrite On
				ColorMask A
			}
			GrabPass{ }

			ColorMask RGB
			CGPROGRAM
			#pragma surface surf Glass addshadow

			sampler2D	_MainTex;
			sampler2D	_GrabTexture;
			sampler2D	_BumpMap;

			struct Input
			{
				float2 uv_MainTex;
				float3 viewDir;
				float3 worldPos;
				float4 screenPos;
			};

			half		_Thresh;
			half		_ShadowSmooth;
			half3		_ShadowColor;
			half		_GlossSize;
			half3		_GlossColor;
			half		_GlossSmoothness;
			half		_SideRimSize;
			half		_Metallic, _Glossiness, _Occlusion;
			half3		_RimColor;

			struct SurfaceOutputGlass
			{
				half3 Albedo;
				half3 GrabColor;
				half3 Normal;
				half3 Emission;
				half Alpha;
				float3 worldPos;
			};

			half4 LightingGlass(SurfaceOutputGlass s, half3 lightDir, half3 viewDir, half atten)
			{
				half3 c = s.Albedo * (1 - _Metallic);

				half shadowDot = pow(dot(s.Normal, lightDir) * 0.5 + 0.5, _Thresh);
				shadowDot = smoothstep(0.5, _ShadowSmooth, shadowDot);
				half3 halfDir = normalize(lightDir + viewDir);
				float viewDot = dot(s.Normal, viewDir);

				half glossSize = lerp(20, 0.001, _GlossSize);
				half halfDot = pow(dot(normalize(s.Normal), halfDir), glossSize);
				half glossDot = smoothstep(0.5, max(0.5, halfDot + _GlossSmoothness / 50), halfDot);

				half roughness = SmoothnessToPerceptualRoughness(_Glossiness);

				half glossPower = max(0, SmithJointGGXVisibilityTerm(shadowDot, viewDot, roughness) * GGXTerm(glossDot, roughness) * UNITY_PI);
				half3 glossColor = lerp(_GlossColor, s.Albedo * _GlossColor, _Metallic);
				half3 gloss = glossPower * glossColor;
				c += gloss;
				c *= lerp(_ShadowColor, _LightColor0.rgb, shadowDot * atten);

				half lightDot = exp2(saturate(dot(lightDir, halfDir))) * _SideRimSize * 5;
				half sideRim = saturate(pow((1 - shadowDot), 5) * pow((1 - viewDot), 5) * lightDot);
				c += sideRim * _RimColor;

				float3 reflUVW = reflect(-viewDir, s.Normal);
				half mip = roughness * UNITY_SPECCUBE_LOD_STEPS;
				half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflUVW, mip);
				c.rgb += DecodeHDR(rgbm, unity_SpecCube0_HDR).rgb * _Occlusion;

				half alpha = saturate(s.Alpha + sideRim + glossPower);
				c = lerp(s.GrabColor, c, alpha);
				return half4(c, 1);

			}

			half4		_Color;
			half		_DistortionPower;
			half		_RimPower;
			half		_RimSmooth;

			void surf(Input IN, inout SurfaceOutputGlass o)
			{
				half4 tex = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = tex.rgb * _Color;
				o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));

				half2 distortion = lerp(float2(1, 1), exp2(o.Normal).xy, _DistortionPower);
				float2 grabUV = (IN.screenPos.xy / max(0.0001, IN.screenPos.w)) * distortion;
				half3 grabColor = tex2D(_GrabTexture, grabUV);
				o.GrabColor = grabColor;

				half rimDot = 1 - pow(dot(o.Normal, IN.viewDir), _RimPower);
				half rim = smoothstep(0.5, max(0.5, _RimSmooth), rimDot);
				o.Emission = _RimColor * rim;

				o.Alpha = saturate(_Color.a * tex.a + rim);
				o.worldPos = IN.worldPos;
			}
			ENDCG
		}
			FallBack "Diffuse"
}
