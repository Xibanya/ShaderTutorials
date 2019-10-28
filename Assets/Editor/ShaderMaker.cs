//By Xibanya
//https://twitter.com/ManuelaXibanya
//https://www.patreon.com/teamdogpit
//Shared under a CreativeCommonsAttribution 4.0 International License
/*
HOW TO INSTALL:
In any folder in your project called Editor (or any folder which has 
"Editor" somewhere in its directory path within your assets folder) create 
a new C# script called ShaderMaker and paste this code inside OR download 
this file directly into a location in your project files which has "Editor"
somewhere in its path.

HOW TO USE:
Go to Tools > Xibanya > ShaderMaker to open the window
*/
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System;

public class ShaderMaker : EditorWindow
{
    private const string ASSETS = "Assets";
    private const string SHADER_EXT = "shader";
    private const string MATERIAL_EXT = "mat";
    private const string SHADER_FOLDER = "Custom";
    private const string PLACEHOLDER_NAME = "MyNewShader";
    private const string WINDOW_TITLE = "Shader Maker";
    private const int MARGIN = 10;
    private const int MIN_FIELD_WIDTH = 350;

    public string shaderName = PLACEHOLDER_NAME;
    public string shaderFolder = SHADER_FOLDER;
    public Shader toCopy;
    public string materialName;
    public Material material;
    public Material propCopy;
    public Renderer toSet;

    private bool showTooltips;
    private bool copyProps;
    private Shader shader;
    private string shaderPath;
    private Color mainColor = new Color(0.9948735f, 0.3066038f, 1f, 1f); //pink
    private Color backgroundColor = new Color(0.2108968f, 0.03065528f, 0.4632353f, 1f); //purple
    private Color infoColor = new Color(0, 0.8612394f, 1f, 1f); //cyan
    private Color transparent = new Color(0, 0, 0, 0);
    private GUIStyle titleStyle;
    private GUIStyle backgroundStyle;
    private GUIStyle mainStyle;
    private GUIStyle tipStyle;
    private GUIStyle labelStyle;
    private GUIStyle textStyle;

    [MenuItem("Tools/Xibanya/Shader Maker", false, 1)]
    public static void ShowWindow()
    {
        ShaderMaker window = GetWindow(typeof(ShaderMaker)) as ShaderMaker;
        window.UpdateHeight();
    }
    private void OnInspectorUpdate() { Repaint(); }
    private void OnGUI()
    {
        GenerateStyles();
        EditorGUILayout.BeginVertical(backgroundStyle);
        EditorGUILayout.BeginVertical();
        GUILayout.Label(WINDOW_TITLE, titleStyle);
        EditorGUILayout.EndVertical();
        EditorGUI.BeginChangeCheck();
        showTooltips = EditorGUILayout.Toggle("Tooltips?", showTooltips);
        if (EditorGUI.EndChangeCheck()) UpdateHeight();
        DoWindow();
    }

    #region Core Functionality
    private void DoWindow()
    {
        DoTextField(ref shaderName, "Shader Name", "The name of the new shader");
        DoTextField(ref shaderFolder, "Shader Path", "Shader path as used in the first line of the shader. " +
            "NOT the same as the file path. Example: \"Custom/Effects\" (no quotes)");
        DoTextField(ref materialName, "New Material Name", "Name of the generated material. Leave blank to use shader name + \"Material\"");
        EditorGUI.BeginChangeCheck();
        DoObjectField(ref toCopy, "Template Shader", "Optional. If left blank, new shader will be generated from the default template. " +
            "Otherwise, apart from the path and name, the new shader's code will be copied from this one.");
        DoObjectField(ref propCopy, "Property Source", "Optional. This material's properties will be copied to the new material's.");
        if (EditorGUI.EndChangeCheck()) UpdateHeight();
        if (toCopy != null)
        {
            DoTooltip("Generate a new material with the template shader assigned to it. If there is a template material, its properties will be copied.");
            if (GUILayout.Button("Generate new material from template shader"))
            {
                string savePath = EditorUtility.SaveFilePanel("Save new material", GetFolderPath(), 
                    UniqueMatName(toCopy.name + "Material", GetFolderPath()), MATERIAL_EXT);
                if (!string.IsNullOrEmpty(savePath)) GenerateMaterial(toCopy, savePath);
            }
        }

        GUILayout.Label(string.Format("Full shader name: {0}\nMaterial Name: {1}\nTemplate: {2}", 
            FullShaderPath, UniqueMatName(MaterialName, GetFolderPath()), TemplateName), textStyle);

        EditorGUILayout.BeginVertical(mainStyle);
        EditorGUI.BeginChangeCheck();
        DoObjectField(ref shader, "New Shader", backgroundColor, "Most recently generated shader");
        if (EditorGUI.EndChangeCheck()) UpdateHeight();
        DoObjectField(ref material, "Material", backgroundColor, "Most recently generated material. This " +
            "material will have the most recently generated shader assigned to it.");
        DoObjectField(ref toSet, "Renderer", backgroundColor, "Optional: if there is a renderer in this field, its " +
            "material will be set to the new material.");
        DoTooltip("Generate a new shader and a new material. The new material will have the new " +
            "shader assigned to it.", backgroundColor);
        EditorGUILayout.Space();
        if (GUILayout.Button("Generate")) GenerateShader();
        if (shader != null)
        {
            DoTooltip("Create another material with most recently generated shader assigned to it.", backgroundColor);
            if (GUILayout.Button("Generate additional material")) GenerateMaterial(shader, shaderPath);
        }
        EditorGUILayout.EndVertical();
    }
    string GetFolderPath(string assetPath = null)
    {
        if (string.IsNullOrEmpty(assetPath) && Selection.activeObject == null) return ASSETS;
        else
        {
            string path = assetPath;
            if (string.IsNullOrEmpty(path)) path = AssetDatabase.GetAssetPath(Selection.activeObject.GetInstanceID());
            if (Directory.Exists(path) || !path.Contains("/"))
            {
                if (string.IsNullOrEmpty(path)) return ASSETS;
                else return path;
            }
            else
            {
                string folderPath = "";
                string[] pathTokens = path.Split('/');
                for (int i = 0; i < pathTokens.Length - 1; i++)
                {
                    folderPath += pathTokens[i];
                    if (i < pathTokens.Length - 2) folderPath += "/";
                }
                if (string.IsNullOrEmpty(folderPath)) return ASSETS;
                else return folderPath;
            }
        }
    }

    //Adapted from ShaderForge source
    //https://github.com/FreyaHolmer/ShaderForge/blob/master/Shader%20Forge/Assets/ShaderForge/Editor/Code/SF_Editor.cs
    private void GenerateShader()
    {
        string savePath = EditorUtility.SaveFilePanel("Save new shader", GetFolderPath(), shaderName, SHADER_EXT);
        if (string.IsNullOrEmpty(savePath)) return;
        StreamWriter sw;
        if (!File.Exists(savePath)) sw = File.CreateText(savePath);
        else sw = new StreamWriter(savePath);
        sw.WriteLine(FirstLine);
        string[] template = GetTemplate();
        for (int i = 0; i < template.Length; i++) sw.WriteLine(template[i]);
        sw.Flush();
        sw.Close();
        AssetDatabase.Refresh();
        shaderPath = string.Format("{0}/{1}", ASSETS, savePath.Substring(Application.dataPath.Length + 1));
        Shader newShader = (Shader)AssetDatabase.LoadAssetAtPath(shaderPath, typeof(Shader));
        if (newShader != null)
        {
            bool wasNull = shader == null;
            shader = newShader;
            if (wasNull) UpdateHeight();
            GenerateMaterial(shader, shaderPath);
        }
    }
    private void GenerateMaterial(Shader matShader, string folderPath)
    {
        if (matShader != null)
        {
            material = new Material(matShader);
            if (propCopy != null) material.CopyPropertiesFromMaterial(propCopy);
            string path = string.Format("{0}/{1}.{2}", GetFolderPath(folderPath), UniqueMatName(MaterialName, folderPath), MATERIAL_EXT);
            AssetDatabase.CreateAsset(material, path);
            AssetDatabase.Refresh();
            material = (Material)AssetDatabase.LoadAssetAtPath(path, typeof(Material));
            if (toSet != null && material != null) toSet.material = material;
        }
    }
    private string UniqueMatName(string desiredName, string checkPath)
    {
        string folderPath = Application.dataPath + GetFolderPath(checkPath).Substring(ASSETS.Length) + "/";
        string finalName = desiredName;
        string fullpath = folderPath + finalName + "." + MATERIAL_EXT;
        int increment = 1;
        bool exists = File.Exists(fullpath);
        while (exists)
        {
            finalName = desiredName + increment.ToString();
            increment++;
            fullpath = folderPath + finalName + "." + MATERIAL_EXT;
            exists = File.Exists(fullpath);
        }
        return finalName;
    }
    private string[] GetTemplate()
    {
        if (toCopy == null) return surfaceTemplate;
        else
        {
            string copyPath = AssetDatabase.GetAssetPath(toCopy.GetInstanceID());
            List<string> lines = new List<string>();
            using (StreamReader reader = new StreamReader(Application.dataPath + copyPath.Substring(6)))
            {
                reader.ReadLine(); //discard the first line
                while(reader.Peek() >= 0)
                {
                    lines.Add(reader.ReadLine());
                }
            }
            return lines.ToArray();
        }
    }
    string MaterialName => string.IsNullOrEmpty(materialName)? shaderName + "Material" : materialName;
    string TemplateName => (toCopy == null) ? "Basic Surface" : toCopy.name;
    string FirstLine => string.Format("Shader\"{0}\"", FullShaderPath);
    string FullShaderPath => string.IsNullOrEmpty(shaderFolder) ? shaderName : string.Format("{0}/{1}", shaderFolder, shaderName);

    string[] surfaceTemplate = new string[] 
    {
        "{",
        "Properties",
        "{",
        "_Color (\"Color\", Color) = (1,1,1,1)",
        "_MainTex (\"Albedo (RGB)\", 2D) = \"white\" {}",
        "}",
        "SubShader",
        "{",
        "Tags { \"RenderType\" = \"Opaque\" }",
        "",
        "CGPROGRAM",
        "#pragma surface surf Standard addshadow",
        "#pragma target 3.0",
        "",
        "sampler2D _MainTex;",
        "",
        "struct Input",
        "{",
        "float2 uv_MainTex;",
        "};",
        "half4 _Color;",
        "void surf(Input IN, inout SurfaceOutputStandard o)",
        "{",
        "half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;",
        "o.Albedo = c.rgb;",
        "o.Alpha = c.a;",
        "}",
        "ENDCG",        
        "}",
        "FallBack \"Diffuse\"",
        "}"
    };
    #endregion

    #region Fields
    protected virtual void DoTooltip(string text) { if (showTooltips) GUILayout.Label(text, tipStyle); }
    protected virtual void DoTooltip(string text, Color textColor)
    {
        if (showTooltips)
        {
            Color oldColor = tipStyle.normal.textColor;
            tipStyle.normal.textColor = textColor;
            GUILayout.Label(text, tipStyle);
            tipStyle.normal.textColor = oldColor;
        }
    }
    protected virtual void DoObjectField<T>(ref T property, string label, string tooltip = null, GUIStyle style = null) where T : UnityEngine.Object
    {
        if (!string.IsNullOrEmpty(tooltip)) DoTooltip(tooltip);
        if (style == null) EditorGUILayout.BeginVertical();
        else EditorGUILayout.BeginVertical(style);
        T obj = null;
        EditorGUI.BeginChangeCheck();
        if (!string.IsNullOrEmpty(label))
        {
            obj = EditorGUILayout.ObjectField(Label(label, tooltip), property, typeof(T), true, GUILayout.MinWidth(MIN_FIELD_WIDTH)) as T;
        }
        else obj = EditorGUILayout.ObjectField(property, typeof(T), true, GUILayout.MinWidth(MIN_FIELD_WIDTH)) as T;
        if (EditorGUI.EndChangeCheck()) property = obj;
        EditorGUILayout.EndVertical();
    }
    protected virtual void DoObjectField<T>(ref T property, string label, Color labelColor, string tooltip = null, GUIStyle style = null) where T : UnityEngine.Object
    {
        if (!string.IsNullOrEmpty(tooltip))
        {
            Color oldTooltipColor = tipStyle.normal.textColor;
            tipStyle.normal.textColor = labelColor;
            DoTooltip(tooltip);
            tipStyle.normal.textColor = oldTooltipColor;
        }
        if (style == null) EditorGUILayout.BeginVertical();
        else EditorGUILayout.BeginVertical(style);
        Color oldLabelColor = labelStyle.normal.textColor;
        labelStyle.normal.textColor = labelColor;
        T obj = null;
        EditorGUI.BeginChangeCheck();
        if (!string.IsNullOrEmpty(label))
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(label, labelStyle);
            obj = EditorGUILayout.ObjectField(property, typeof(T), true, GUILayout.MinWidth(MIN_FIELD_WIDTH)) as T;
            EditorGUILayout.EndHorizontal();
        }
        else obj = EditorGUILayout.ObjectField(property, typeof(T), true, GUILayout.MinWidth(MIN_FIELD_WIDTH)) as T;
        if (EditorGUI.EndChangeCheck()) property = obj;
        EditorGUILayout.EndVertical();
        labelStyle.normal.textColor = oldLabelColor;
    }
    protected virtual void DoTextField(ref string str, string label = null, string tooltip = null)
    {
        if (!string.IsNullOrEmpty(tooltip)) DoTooltip(tooltip);
        string strLabel = label;
        if (string.IsNullOrEmpty(strLabel)) strLabel = nameof(str);
        GUIContent nameLabel = Label(strLabel, tooltip);
        EditorGUI.BeginChangeCheck();
        str = EditorGUILayout.TextField(nameLabel, str, GUILayout.MinWidth(MIN_FIELD_WIDTH));
        if (EditorGUI.EndChangeCheck()) str = CleanPath(str);
    }
    protected virtual string CleanPath(string toClean) => toClean.Trim(new char[] { ' ', '/', '"' });
    protected GUIContent Label(string label, string tooltip = null) => string.IsNullOrEmpty(tooltip) ? new GUIContent(label) : new GUIContent(label, tooltip);
    #endregion

    #region Styles
    private int HalfMargin => (int)Math.Round((float)MARGIN * 0.5f);
    private int TooltipHeight
    {
        get
        {
            if (toCopy == null && shader == null) return 630;
            else if (toCopy != null && shader != null) return 735;
            else return 675;
        }
    }
    private int Height
    {
        get
        {
            if (toCopy == null && shader == null) return 350;
            else if (toCopy != null && shader != null) return 400;
            else return 370;
        }
    }
    private void UpdateHeight()
    {
        if (showTooltips)
        {
            minSize = new Vector2(MIN_FIELD_WIDTH + 200, TooltipHeight);
            maxSize = new Vector2(MIN_FIELD_WIDTH * 2, TooltipHeight);
        }
        else
        {
            minSize = new Vector2(MIN_FIELD_WIDTH + 200, Height);
            maxSize = new Vector2(MIN_FIELD_WIDTH * 2, Height);
        }
        Repaint();
    }
    private void GenerateStyles(bool reload = false)
    {
        GenerateTitleStyle(reload);
        GenerateBackgroundStyle(reload);
        GenerateMainStyle(reload);
        GenerateTextStyle(reload);
        GenerateTipStyle(reload);
        GenerateLabelStyle(reload);
    }
    protected virtual void GenerateTitleStyle(bool reload = false)
    {
        if (titleStyle == null || reload)
        {
            titleStyle = new GUIStyle(EditorStyles.boldLabel);
            titleStyle.font = EditorStyles.boldFont;
            titleStyle.normal.textColor = Color.white;
            titleStyle.margin = new RectOffset(HalfMargin, HalfMargin * 3, MARGIN, HalfMargin);
            titleStyle.alignment = TextAnchor.MiddleCenter;
            titleStyle.stretchWidth = true;
            titleStyle.fontSize = (int)(EditorStyles.boldLabel.fontSize * 1.5f);
            titleStyle.normal.background = MakeBG(transparent);
        }
    }
    private void GenerateBackgroundStyle(bool reload = false)
    {
        if (backgroundStyle == null || reload)
        {
            backgroundStyle = new GUIStyle(GUI.skin.window);
            backgroundStyle.normal.background = MakeBG(backgroundColor);
            backgroundStyle.alignment = TextAnchor.MiddleRight;
            backgroundStyle.clipping = TextClipping.Clip;
            backgroundStyle.wordWrap = true;
            backgroundStyle.stretchWidth = true;
            backgroundStyle.stretchHeight = true;
            backgroundStyle.normal.textColor = Color.white;
            backgroundStyle.margin = new RectOffset(0, 0, 0, 0);
            backgroundStyle.padding = new RectOffset(MARGIN, MARGIN, MARGIN, MARGIN);
        }
    }
    protected virtual void GenerateMainStyle(bool reload = false)
    {
        if (mainStyle == null || reload)
        {
            mainStyle = new GUIStyle(EditorStyles.inspectorDefaultMargins);
            mainStyle.normal.background = MakeBG(mainColor);
            mainStyle.alignment = TextAnchor.UpperLeft;
            mainStyle.clipping = TextClipping.Overflow;
            mainStyle.richText = true;
            mainStyle.wordWrap = true;
            mainStyle.padding = new RectOffset(HalfMargin, HalfMargin, MARGIN, MARGIN);
            mainStyle.margin = new RectOffset(HalfMargin, HalfMargin, MARGIN, MARGIN);
            mainStyle.stretchWidth = false;
            mainStyle.stretchHeight = false;
            mainStyle.normal.textColor = backgroundColor;
            mainStyle.focused.textColor = backgroundColor;
        }
    }
    protected virtual void GenerateTextStyle(bool reload = false)
    {
        if (textStyle == null || reload)
        {
            textStyle = new GUIStyle(EditorStyles.helpBox);
            textStyle.normal.background = MakeBG(infoColor);
            textStyle.normal.textColor = backgroundColor;
            textStyle.richText = true;
            textStyle.fontSize = (int)(EditorStyles.helpBox.fontSize * 1.5f);
            textStyle.alignment = TextAnchor.UpperLeft;
            textStyle.clipping = TextClipping.Overflow;
            textStyle.padding = new RectOffset(MARGIN, MARGIN, HalfMargin, MARGIN);
            textStyle.margin = new RectOffset(MARGIN, MARGIN, MARGIN, MARGIN);
            textStyle.wordWrap = true;
            textStyle.stretchWidth = true;
        }
    }
    protected virtual void GenerateTipStyle(bool reload = false)
    {
        if (tipStyle == null || reload)
        {
            tipStyle = new GUIStyle(EditorStyles.helpBox);
            tipStyle.margin.top = MARGIN;
            tipStyle.stretchWidth = true;
            tipStyle.stretchHeight = true;
        }
    }
    protected virtual void GenerateLabelStyle(bool reload = false)
    {
        if (labelStyle == null || reload)
        {
            labelStyle = new GUIStyle(EditorStyles.objectField);
            labelStyle.normal.textColor = backgroundColor;
            labelStyle.normal.background = MakeBG(transparent);
            labelStyle.fontStyle = FontStyle.Bold;
            labelStyle.stretchWidth = false;
            labelStyle.fixedWidth = 150;
            labelStyle.padding.top = HalfMargin;
        }
    }
    private Texture2D MakeBG(Color col)
    {
        Color[] pix = new Color[4];
        for (int i = 0; i < pix.Length; ++i) pix[i] = col;
        Texture2D result = new Texture2D(2, 2);
        result.SetPixels(pix);
        result.Apply();
        return result;
    }
    #endregion
}
