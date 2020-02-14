using UnityEngine;

namespace Xibanya
{
    [ExecuteAlways]
    public class ShaderGlobals : MonoBehaviour
    {
        public const string SHADOW_COLOR = "_GlobalShadowColor";
        public const string SHADOW_THRESHOLD = "_GlobalShadowThreshold";
        public const string SHADOW_SMOOTHNESS = "_GlobalShadowSmoothness";
        public const float DEFAULT_SHADOW_THRESHOLD = 1.5f;
        public const float DEFAULT_SHADOW_SMOOTHNESS = 0.6f;
        public const float DEFAULT_SHADOW_R = 0.17f;
        public const float DEFAULT_SHADOW_G = 0.18f;
        public const float DEFAULT_SHADOW_B = 0.5f;

        [ColorUsage(showAlpha: false, hdr: false)]
        public Color shadowColor = new Color(
            DEFAULT_SHADOW_R, DEFAULT_SHADOW_G, DEFAULT_SHADOW_B);
        [Range(0.1f, 2)]
        public float shadowThreshold = DEFAULT_SHADOW_THRESHOLD;
        [Range(0.5f, 1)]
        public float shadowSmoothness = DEFAULT_SHADOW_SMOOTHNESS;
        [Space]
        public bool onUpdate;

        private void OnEnable()
        {
            SetGlobals();
        }
        private void Update()
        {
            if (onUpdate) SetGlobals();
        }
        private void SetGlobals()
        {
            SetGlobals(shadowColor, shadowThreshold, shadowSmoothness);
        }
        public static void SetGlobals(
            Color shadowColor, float shadowThreshold, float shadowSmoothness)
        {
            Shader.SetGlobalColor(SHADOW_COLOR, shadowColor);
            Shader.SetGlobalFloat(SHADOW_THRESHOLD, shadowThreshold);
            Shader.SetGlobalFloat(SHADOW_SMOOTHNESS, shadowSmoothness);
        }
        public static void SetDefaults()
        {
            SetGlobals(DefaultShadowColor, DEFAULT_SHADOW_THRESHOLD, DEFAULT_SHADOW_SMOOTHNESS);
        }
        public static Color DefaultShadowColor => new Color(
            DEFAULT_SHADOW_R, DEFAULT_SHADOW_G, DEFAULT_SHADOW_B);
    }
}