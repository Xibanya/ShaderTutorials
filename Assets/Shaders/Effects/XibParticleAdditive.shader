// This is a minor improvement on the built-in shader 
//"Legacy Shaders/Particles/Additive" 

//you may wonder why I often put "Xib" in front of the names of stuff
//even though it's already in the path. It's vanity! It makes
//it way easier for me to find my stuff cuz I can just start typing 
//"Xib" and my shaders pull up right away (turns out not many other 
//shader folk are naming their shaders anything starting with an X)
Shader "Xibanya/Particles/XibParticle Additive"
{
	Properties 
	{
		//I would normally call this property _Color but I believe it
		//needs to stay _TintColor to play nice with particle systems.
		//Could be wrong tho, I'll investigate further.
		[HDR]_TintColor ("Tint Color", Color) = (1, 1, 1, 1)
		_MainTex ("Particle Texture", 2D) = "white" {}
		//this allows using soft particles on an individual shader
		//basis even if soft particles are otherwise turned off in
		//project settings
		[Toggle(_SOFT)] _Soft("Soft particles?", float) = 1
		_InvFade ("Soft Particles Factor", Range(0.01, 6)) = 1
		[Header(Options)]
		[Toggle(_ALPHATEST_ON)] _ALPHATEST("Cutout?", float) = 1
		_Cutoff("Cutoff", Range(0, 1)) = 0.5
		[Enum(Off,0,Front,1,Back,2)] _Cull("Cull", int) = 0
		[Enum(One,1,SrcAlpha,5)] _Src("Source Blend", int) = 5
		[Enum(Alpha,1,Blue,2,Green,4,Red,8,RGB,14,All,15)]_ColorMask("Color Mask", float) = 14
		[Enum(Add,0,Max,4,Lighten,25)] _Op("Blend Op", float) = 4
	}
    SubShader 
    {
		Tags 
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane" 
		}
		BlendOp [_Op]
		Blend [_Src] One
		ColorMask [_ColorMask]
		Cull [_Cull] 
		Lighting Off 
		ZWrite Off
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile ___ UNITY_HDR_ON
            #pragma multi_compile_particles
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma shader_feature_local _SOFT
            #pragma shader_feature_local _ALPHATEST_ON

            #include "UnityCG.cginc"

            sampler2D   _MainTex;
            half4       _TintColor;
            half        _Cutoff;

            struct appdata_t 
            {
                float4 vertex : POSITION;
                half4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f 
            {
                float4 pos  : SV_POSITION;
                half4 color : COLOR;
                float2 uv   : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            #if defined(SOFTPARTICLES_ON) || defined(_SOFT)
                float4 projPos : TEXCOORD2;
            #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 _MainTex_ST;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
            #if defined(SOFTPARTICLES_ON) || defined(_SOFT)
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
            #endif
                o.color = v.color * _TintColor * 2;
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float _InvFade;

            half4 frag (v2f i) : SV_Target
            {
                //We'll sample the texture earlier than in the original
				//so that we can do the alpha clip before applying the 
				//fade, that way it'll be based directly on the texture
				//itself. This will allow greater control over the 
				//alpha value of the color for fading while avoiding
				//getting grody edges
				half4 col = tex2D(_MainTex, i.uv);
            #ifdef _ALPHATEST_ON
                clip(col.a - _Cutoff);
            #endif
				col *= i.color;
				//remember that saturate is basically clamp betwen 0-1
				col.a = saturate(col.a);
            #if defined(SOFTPARTICLES_ON) || defined(_SOFT)
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				half fadeFactor = sceneZ - i.projPos.z;
                float fade = saturate(_InvFade * fadeFactor);
                i.color.a *= fade;
            #endif
           
            #ifndef UNITY_HDR_ON
					col.rgb = exp2(-col.rgb);
			#endif
                //Original comment by Unity: 
                //fog towards black due to our blend mode
                UNITY_APPLY_FOG_COLOR(i.fogCoord, col, half4(0,0,0,0));
                return col;
            }
            ENDCG
        }
    }
}