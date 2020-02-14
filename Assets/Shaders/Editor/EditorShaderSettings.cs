using UnityEditor;

namespace Xibanya
{
    [InitializeOnLoad]
    public static class EditorShaderSettings
    {
        static EditorShaderSettings()
        {
            ShaderGlobals.SetDefaults();
        }
    }
}