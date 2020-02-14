using System;
using System.Linq;
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;
//All editor code in scripts that are not in the path of a folder called Editor
//must be enclosed in preprocessor blocks like this or there will be build errors
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Xibanya
{
    [Serializable]
    public struct LightBuffer
    {
        private const string NAME_TIP = "The name of the command buffer is what " +
            "shows up on the light or camera component it's attached to, so " +
            "the main important thing is to give it a name that actually means " +
            "something to you so that you know what is is when you see it.";

        //note that because this is a struct, we can't assign default values here
        //that's because default values are initialized in a class when 
        //the class itself is initialized but structs are never initialzed,
        public LightEvent lightEvent;
        [Tooltip(NAME_TIP)]
        public string name;
        public string texProperty;

        private CommandBuffer buffer;

        /// <summary>Only add command buffer if there isn't 
        /// already one of the same name added.</summary>
        public CommandBuffer Add(Light light, BuiltinRenderTextureType builtinRenderTexture = BuiltinRenderTextureType.CurrentActive)
        {
            if (light != null && !string.IsNullOrEmpty(name))
            {
                //we must assign name to a local string here in order to use it 
                //in the Linq query, as struct fields aren't allowed
                string buffName = name;
                buffer = light.GetCommandBuffers(lightEvent).ToList().Find(b => b.name == buffName);
                if (buffer == null)
                {
                    buffer = new CommandBuffer() { name = buffName };
                    if (builtinRenderTexture != BuiltinRenderTextureType.None && !string.IsNullOrEmpty(texProperty))
                    {
                        buffer.SetGlobalTexture(texProperty, builtinRenderTexture);
                    }
                    light.AddCommandBuffer(lightEvent, buffer);
                }
                return buffer;
            }
            else return null;
        }

        /// <summary> Removes the command buffer from the 
        /// light if it is assigned to that light. </summary>
        public void Remove(Light light, bool release = false)
        {
            if (light != null && buffer != null)
            {
                //we must assign name to a local string here in order to use it 
                //in the Linq query, as struct fields aren't allowed
                string buffName = name;
                List<CommandBuffer> buffers = light.GetCommandBuffers(lightEvent).Where(b => b.name == buffName).ToList();
                foreach (CommandBuffer match in buffers)
                {
                    light.RemoveCommandBuffer(lightEvent, match);
                    if (release || !IsPlaying) match.Release();
                }
                Release(); //likely not needed, but just to be safe
            }
        }
        public void Release()
        {
            if (buffer != null)
            {
                buffer.Release();
                buffer = null;
            }
        }
#if UNITY_EDITOR
        private bool IsPlaying => EditorApplication.isPlaying;
#else
        private bool IsPlaying => Application.isPlaying;
#endif
    }
}
