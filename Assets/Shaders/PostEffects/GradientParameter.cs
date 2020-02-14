using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace Xibanya
{
    [Serializable]
    public class GradientParameter : ParameterOverride<Gradient>
    {
        public const int WIDTH = 256;
        public static implicit operator Texture2D(GradientParameter gradient)
        {
            Texture2D ramp = new Texture2D(WIDTH, 1)
            {
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Point
            };
            for (int i = 0; i < WIDTH; i++)
            {
                ramp.SetPixel(i, 0, gradient.value.Evaluate((float)i / (float)WIDTH));
            }
            ramp.Apply(false);
            return ramp;
        }
    }
}
