using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace Xibanya.TCO.Effects
{
    [Serializable, PostProcess(typeof(AlphaRenderer), PostProcessEvent.AfterStack,
        "TCO/Alpha", allowInSceneView: false)]
    public sealed class Alpha : PostProcessEffectSettings
    {
        [Range(0, 1)]
        public FloatParameter alpha = new FloatParameter { value = 1 };
    }

    public sealed class AlphaRenderer : PostProcessEffectRenderer<Alpha>
    {
        private const string SHADER = "Hidden/Xibanya/Alpha";
        private static Shader shader;

        public override void Render(PostProcessRenderContext context)
        {
            if (shader == null) shader = Shader.Find(SHADER);
            if (shader != null && settings.IsEnabledAndSupported(context))
            {
                PropertySheet sheet = context.propertySheets.Get(shader);
                sheet.properties.SetFloat("_Alpha", settings.alpha);
                context.command.BlitFullscreenTriangle(
                    context.source, context.destination, sheet, 0);
            }
            else
            {
                context.command.BuiltinBlit(context.source, context.destination);
            }
        }
    }
}