using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Xibanya
{
    [ExecuteAlways, RequireComponent(typeof(Light))]
    public class Sun : MonoBehaviour
    {
        #region Declarations
        public const string SUN_DIRECTION = "_SunDirection";
        public const string LIGHT_COLOR = "_GlobalLightColor";
        public const string SCREEN_SPACE_SHADOWS = "_GlobalScreenSpaceShadows";
        
        private static Sun instance;
        private static List<Sun> suns = new List<Sun>();
        private static Color lightColor;

        public LightBuffer[] buffers = new LightBuffer[] {
            new LightBuffer() {
                lightEvent = LightEvent.AfterScreenspaceMask,
                name = "Screen Space Shadows",
                texProperty = SCREEN_SPACE_SHADOWS
            }
        };
        new private Light light;
        #endregion

        #region Methods
        private void OnEnable()
        {
            if (!Instance) Instance = this;
            if (!suns.Contains(this)) suns.Add(this);
        }
        private void SetActive()
        {
            if (!light) light = GetComponent<Light>();
            if (light)
            {
                LightColor = light.color;
                light.enabled = true;
                foreach (LightBuffer buffer in buffers) buffer.Add(light);
            }
            Direction = transform.forward;
        }
        private void SetInactive()
        {
            foreach (LightBuffer buffer in buffers) buffer.Remove(light);
            Direction = Vector3.zero;
            LightColor = Color.white;
        }
        private void OnDisable()
        {
            if (suns.Contains(this)) suns.Remove(this);
            if (Instance == this) Instance = suns.Find(s => s != this && s.isActiveAndEnabled);
        }
        private void OnDestroy()
        {
            foreach (LightBuffer buffer in buffers) buffer.Release();
        }
        private void LateUpdate()
        {
            if (Instance == this)
            {
                LightColor = light.color;
                if (transform.hasChanged)
                {
                    Direction = transform.forward;
                    transform.hasChanged = false;
                }
            }
        }
        #endregion

        #region Properties
        private static bool Ready => Instance && Instance.isActiveAndEnabled;
        public static Sun Instance
        {
            get => instance;
            set
            {
                if (instance != value)
                {
                    if (instance) instance.SetInactive();
                    instance = value;
                    if (instance) instance.SetActive();
                }
            }
        }
        public static Color LightColor
        {
            get => lightColor;
            set
            {
                if (Ready && instance.light != null && lightColor != value)
                {
                    lightColor = instance.light.color = value;
                    Shader.SetGlobalColor(LIGHT_COLOR, value);
                }
            }
        }
        public static Vector3 Direction
        {
            get => Ready ? Instance.transform.forward : RenderSettings.sun ? 
                RenderSettings.sun.transform.forward : Vector3.zero;
            private set => Shader.SetGlobalVector(SUN_DIRECTION, value);
        }
        #endregion

        public static implicit operator Vector3(Sun sun)
        {
            return sun.transform.forward;
        }
    }
}
