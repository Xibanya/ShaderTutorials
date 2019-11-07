---
layout: post
title: Dissolve
date: 2019-07-11 17:13:00
categories: [tutorial]
tags: [dissolve, clip, step, tex2d]
---

# Part 12: Dissolve

[Last time](https://www.patreon.com/posts/part-11-cutouts-28304378) we learned how to make a cutout shader. Today we're going to apply what we learned to make a neat dissolve effect!

![](https://raw.githubusercontent.com/Xibanya/ShaderTutorials/master/Img/12%20Dissolve/00.png)

## Lesson in brief
### Code created
* [XibDissolve.shader](https://github.com/Xibanya/ShaderTutorials/blob/master/Assets/Shaders/Toon/XibDissolve.shader)

### Functions Used
* clip
* step
* tex2D

### Concepts & Techniques
* Material editor formatting
* Unity CG surface shaders
* Noise masking
* Render queue

## Setup
* In your project files, duplicate XibToon. If you don't already have it, download it here.
Name the new file **XibDissolve**. 
* Open it in Visual Studio and rename the shader XibDissolve by replacing the entire first line with `Shader "Xibanya/XibDissolve"`
* In Unity, select **Girl_Body_Geo** in the Hierarchy so you can view Claire's details in the Inspector. 
* In the Skinned Mesh Renderer component, click the material so that you can see it in the Project files. 
* Click the material in the Project tab and press `Ctrl + D` to duplicate it. 
* Name the duplicate **Claire Dissolve**. 
* Drag the Claire Dissolve material into the material slot in the Skinned Mesh Renderer component. 

You should end up with this.

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/01.png]]
 
Whew, OK, now we are ready to make this shader.

So here's what we want to do: we want to have a way to do a sort of fancy fadeout, like Claire is teleporting away with some sort of magic or something. That means we don't want her to disappear all at once, we want some parts to disappear faster than others. We can use a texture to keep info about how fast we want her to dissolve. We could take the value of the color in that texture and make a cutoff, just like last time, but instead of making the cutoff based on the alpha transparency value, we can make it just based on where on a scale of black to white the texture is.
So first things first, we will need to add an additional texture slot and a cutout slider.

```
_DissolveTex("Dissolve Tex", 2D) = "white" {}
_DissolveAmount("Dissolve Amount", Range(0, 1)) = 0.5
```
 
be sure to declare these new properties down in the SubShader too.
```
half        _DissolveAmount;
sampler2D   _DissolveTex;
```
Save and head back to Unity.

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/02.png]]
 
So far so good. Let's go ahead and put a texture in the new slot now. Snow01_disp in the Snow textures we downloaded in Part 8 would work pretty well, so drag that in.

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/03.png]]
 
Yanno these properties are getting kinda long. Let's make this a little easier to read. In Visual Studio, add these above our new dissolve-related properties.

```
[Space]
[Header(Dissolve)]
```

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/04.png]]

That looks nicer
 
Back in our shader code, let's add a line at the bottom of our surface function to get the color info from the noise texture.

```
half4 noise = tex2D(_DissolveTex, IN.uv_MainTex);
```

then we'll use the clip function like last time to make pixels below our _DissolveAmount threshold not get drawn at all. This time, instead of using the alpha value, we'll use the red value of the texture. We can just use red because if we're going from black to white, red, green, and blue are all going to be the same anyway.

```
half4 noise = tex2D(_DissolveTex, IN.uv_MainTex);
clip(noise.r - _DissolveAmount);
```
 
Save and go back to Unity.

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/05.png]]
 
She's dissolving!  Kinda. I think it would look better if the cutout zones were smaller and if there were more of them. We should scale the texture. Add a _DissolveScale property, then multiply the coordinates we're using to get the texture by it.
 
```
_DissolveScale("Dissolve Scale", float) = 1
```

```
half    _DissolveScale;
```

```
half4 noise = tex2D(_DissolveTex, IN.uv_MainTex * _DissolveScale);
clip(noise.r - _DissolveAmount);
```

After you've saved, set the dissolve scale in the material properties in Unity to 5.

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/06.png]]
 
Sweet. Play with the dissolve amount slider a bit to see this dissolve in action. 

Of course we can make this look fancier and more magical/science-fictiony by making the border around the dissolve area glow. Add these to your properties

```
_DissolveLine("Dissolve Line", Range(0,0.2)) = 0.1
[HDR]_DissolveLineColor("Dissolve Line Color", Color) = (1,1,1,1)
```

and SubShader

```
half _DissolveLine;
half3 _DissolveLineColor;
```

and at the bottom of your surface shader, add `o.Emission += step(noise.r, _DissolveAmount + _DissolveLine) * _DissolveLineColor;`

```
half4 noise = tex2D(_DissolveTex, IN.uv_MainTex * _DissolveScale);
clip(noise.r - _DissolveAmount);
o.Emission += step(noise.r, _DissolveAmount + _DissolveLine) * _DissolveLineColor;
```
 
We are basically putting the emissive color in all the areas that are being dissolved, but we're expanding the area by the  **_DissolveLine** value. Since the dissolve area pixels aren't even being drawn, it makes it look like there's a border around the hole. Save and check it out!

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/07.png]]
 
Hm, you can still see some shadows on her even though she's supposed to be going invisible. As a final touch, change the render queue in that dropdown over there to Transparent!

[[https://github.com/Xibanya/ShaderTutorials/blob/master/Img/12 Dissolve/08.png]]
 
Pretty darn cool if you ask me.

The final code for this shader can be found here: [XibDissolve.shader](https://github.com/Xibanya/ShaderTutorials/blob/master/Assets/Shaders/Toon/XibDissolve.shader)

Next, [Part 13: Highlights](https://www.patreon.com/posts/28571898) 

{% include TutorialFooter.md %}
