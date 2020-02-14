using UnityEngine;
using System;
using UnityEngine.Rendering.PostProcessing;

namespace Xibanya
{
    [Serializable, PostProcess(typeof(ShadowGradientRenderer), 
        PostProcessEvent.BeforeTransparent, "Xibanya/Shadow Gradient", allowInSceneView: true)]
    public class ShadowGradient : PostProcessEffectSettings
    {
        [Range(0, 1)] public FloatParameter mix = new FloatParameter { value = 0.5f };
        public GradientParameter gradient = new GradientParameter
        {
            value = new Gradient()
            {
                colorKeys = new[] {
                    new GradientColorKey(new Color(0.1657656f, 0.1768017f, 0.5367647f), 0f),
                    new GradientColorKey(new Color(0f, 1, 0.9897847f), 0.5f),
                    new GradientColorKey(new Color(0.8398438f, 0.9062501f, 0.9335938f), 1f)
                },
                alphaKeys = new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0.5f, 1f) }
            }
        };
    }
    public class ShadowGradientRenderer : PostProcessEffectRenderer<ShadowGradient>
    {
        private const string SHADER = "Hidden/Xibanya/Effects/ShadowGradient";
        public override void Render(PostProcessRenderContext context)
        {
            PropertySheet sheet = context.propertySheets.Get(Shader.Find(SHADER));
            sheet.properties.SetFloat("_Mix", settings.mix);
            sheet.properties.SetTexture("_Gradient", settings.gradient);
            context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
        }
    }
}
