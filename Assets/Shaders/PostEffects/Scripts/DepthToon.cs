using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable, PostProcess(typeof(DepthToonRenderer), PostProcessEvent.AfterStack,
    "Xibanya/DepthToon", allowInSceneView: true)]
public sealed class DepthToon : PostProcessEffectSettings
{
    public BoolParameter CastShadows = new BoolParameter() { };
    [Range(0, 1)]
    public FloatParameter Range = new FloatParameter() { value = 0.2f };
    [Range(0, 1)]
    public FloatParameter Falloff = new FloatParameter() { value = 0.2f };
    [Range(0, 1)]
    public FloatParameter Coverage = new FloatParameter() { value = 1 };
    [Range(0, 1)]
    public FloatParameter Softness = new FloatParameter() { value = 0.2f };
    [Range(0, 2)]
    public FloatParameter Height = new FloatParameter() { value = 1 };
    [Range(0, 2)]
    public FloatParameter Width = new FloatParameter() { value = 1 };
    [ColorUsage(false, false)]
    public ColorParameter MainColor = new ColorParameter() { value = Color.white };
    [ColorUsage(false, false)]
    public ColorParameter ShadowColor = new ColorParameter() {
        value = new Color(0.17f, 0.18f, 0.54f, 1) };
}

public sealed class DepthToonRenderer : PostProcessEffectRenderer<DepthToon>
{
    private const string SHADER = "Hidden/Xibanya/Effects/DepthToon";

    public override DepthTextureMode GetCameraFlags() => DepthTextureMode.Depth;

    public override void Render(PostProcessRenderContext context)
    {
        PropertySheet sheet = context.propertySheets.Get(Shader.Find(SHADER));
        sheet.properties.SetFloat("_CastShadows", settings.CastShadows ? 1 : 0);
        sheet.properties.SetFloat("_Range", settings.Range);
        sheet.properties.SetFloat("_Falloff", settings.Falloff);
        sheet.properties.SetFloat("_Coverage", settings.Coverage);
        sheet.properties.SetFloat("_Softness", settings.Softness);
        sheet.properties.SetColor("_Color", settings.MainColor);
        sheet.properties.SetColor("_ShadowColor", settings.ShadowColor);
        sheet.properties.SetMatrix("_Inverse", context.camera.cameraToWorldMatrix);
        sheet.properties.SetVector("_Size", new Vector2(settings.Width, settings.Height));
        if (RenderSettings.sun)
        {
            sheet.properties.SetVector("_LightDir", RenderSettings.sun.transform.forward);
        }
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}