// Shaders For People Who Don't Know How To Shader Part 44: 2D rotation
// https://www.patreon.com/posts/shader-tutorial-73605548
// this code is shared under Attribution 4.0 International (CC BY 4.0) license
// https://creativecommons.org/licenses/by/4.0/
Shader "Xibanya/Unlit/Rotation2D"
{
    Properties
    {
        _MainTex            ("Texture", 2D) = "white" {}
        _Rotation           ("Rotation", float) = 0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "PreviewType" = "Plane"
        }
        Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos  : SV_POSITION;
                float2 uv   : TEXCOORD0;
            };
            sampler2D   _MainTex;
            float4      _MainTex_ST;
            float       _Rotation;

            float2 Rotate2D(float2 uv, float angle)
            {
                float2x2 rotationMatrix = float2x2(
                    cos(angle), -sin(angle),
                    sin(angle), cos(angle)
                    );
                return mul(uv, rotationMatrix);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float2 uv = v.uv - 0.5;
                uv = Rotate2D(uv, radians(_Rotation));
                uv += 0.5;
                o.uv = TRANSFORM_TEX(uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}