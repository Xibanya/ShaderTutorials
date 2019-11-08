---
layout: post
title: Toon Lighting
date: 2019-07-09 14:38:10
categories: [tutorial]
tags: [lighting]
part: 10
after: 11
summary: Use a custom lighting function to apply cel shading.
---
# Part 10: Toon Lighting, Shaders For People Who Don't Know How To Shader

[Last time](https://www.patreon.com/posts/shaders-for-who-28231962) we learned how to use a dot product to add a fresnel rim to our shader. Now we're going to learn how to use a dot product to do cel shading! If you don't remember what a dot product is, reread [Part 8](https://www.patreon.com/posts/shaders-for-who-28227883) so you're all set for this lesson!

Cel shading, also called toon shading, is a kind of technique that makes it so that there are hard cutoffs between light and dark on an object, like how shading is done in a cartoon. We can do this by writing a custom lighting function.

In forward rendering (which we are using right now) a lighting function is a calculation that is run for every light that hits the 3d object in question. Once we've applied our textures and normal maps and all that other good stuff, this is what's used to apply darkness or brightness from the light to determine the final color of our 3d object.

### Setup

If you've been following along, you should have the XibStandard shader, but if you don't, [download it now](https://www.patreon.com/file?h=28235014&i=4115062). (It's also attached to this post as XibStandard.shader.) Copy XibStandard by clicking it in your project files and pressing ctrl + D. Name the new shader XibToon. Copy Claire's current material the same way, and name it ClaireToon. Drag the ClaireToon material into the material slot on Girl_Body_Geo. Open XibToon in Visual Studio. Change the first line to

> **Shader "Xibanya/XibToon"**

Save and go back to Unity. In the ClaireToon material, select XibToon from the dropdown. You should end up with something like this:

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/2b95b6515b6a48caae90cf870cea8bf7/1.png?token-time=1574380800&token-hash=kGkxag6yf4I23TUfpbfM3lOyCwqwtMjSzkDNcUVHTfw%3D)

### Custom Lighting

This entire time we've had a line in our shaders near the top that says this:

` **#pragma surface surf Standard fullforwardshadows**

this actually means something, let's break it down!

**#pragma** is a pre-compiler directive, putting it at the start of the line signals to Unity that we're about to tell it how it should treat this shader

**surface** means it's a surface shader (there are other kinds of shader we haven't looked at yet!)

**surf** is the name of the surface function (so you could rename it here if you wanted to as long as you made sure to change the name of the surface function down below too!)

**Standard** is the name of the lighting function that should be used

anything after that is options, so **fullforwardshadows** is just one of many options you could put there. You can see a full list of options in the [Unity docs here](https://docs.unity3d.com/Manual/SL-SurfaceShaders.html). You can throw on as many as you want, or have none.

This entire time we have been using the Standard lighting model. This is the built-in default lighting model, and because it's built-in, we can tell the shader to use it without having it in the file itself. If we want to use our own lighting function, we'll have to add it to our shader code.

In this line in our XibToon shader, let's replace Standard with Toon so the line looks like this.

#pragma surface surf Toon fullforwardshadows

By doing that, we've told Unity to look for a lighting function called LightingToon so now we need to add that or this shader will return errors and not work.

Let's stub this out first. Add this LightingToon function below your #pragmas

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/3f57b04dab094bc1963fb06b5818d069/1.png?token-time=1574380800&token-hash=BUEbakMygEo5MDLLw9tZ5JMBA6xiQdE2RGcDlI0uLNY%3D)

I really wish Patreon let me have codeblocks! Since it doesn't, if you're lazy, copy and paste this, then add line breaks to taste.

` **half4 LightingToon(SurfaceOutput s, half3 lightDir, half atten) { return half4(s.Albedo, 1); }**

down in your surface function, replace SurfaceOutputStandard with SurfaceOutput

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/99f7c48b653445a4bad3eea311a332a1/1.png?token-time=1574380800&token-hash=yxSgbaLcemdJAAan15_69sjRDhgiJz4TAmrbu2qcYUY%3D)

Save and go back to Unity to make sure you don't get any errors. You should have this.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/9e5d204104d0410fa4316745aec8d1ec/1.png?token-time=1574380800&token-hash=X-OjWSPDbSYGRyXjo8oFC4lfYJOiBpkV3PuBWrUGg10%3D)

If you got errors look over your code carefully and make sure the parts you've altered so far look just like mine. (It can be easy to mess up here by forgetting to change something.)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/051b453344904a8287d77a9c081d7526/1.png?token-time=1574380800&token-hash=rloUyYIN2e2nHxwMYSjgiTI9WN5ZiZ-ktmSu7GTgqOw%3D)

Once you're situated have a look at Claire. If you have the rim on, make the rim color black. You'll find she has no shadowiness on her at all -- she has the same brightness all over. In our lighting function we just said to keep the model the same color that it was before we tried to put lighting on it, which is like not bothering with lighting or shadow at all. Whoever made the texture was a skilled artist, as they made her neck darker than her face on purpose to make it look like there was shading even if the model was in a situation like this, so if you want to really see how there's not any lighting being applied, click the texture slot in the material properties and hit backspace to remove it.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/4a052f4bd8e34aef8ee0c88d7ac37c00/1.png?token-time=1574380800&token-hash=xqxSpVq7CdQKxSgbco30LsTSkPX_LWAVebwjwh2BuU8%3D)

Interestingly this is often what it looks like when our shader has an error. That's because an error often stops the lighting function from being run! (Then hit ctrl + z to put it the texture back!)

OK so what do we even _want_ out of a lighting function? Well we want the parts being hit by light to be brighter and we want the parts not being hit by light to be darker. How can we do that? Well hm, last time when we were making the rim, the first thing we did was make the parts facing us directly lighter with the view direction, so if we had the light direction, we could do basically the same thing!

In our custom lighting function, we have our light direction given to us in the parameters, so we have that to start with. We also have SurfaceOutput being given to us, which will have all the same info stored in it as it does down in the surface function, which means we can get the direction any given pixel we're coloring is facing in. So let's add this to the top of our lighting function:

` **half d = dot(s.Normal, lightDir);**

Remember, our dot product will be bigger the more overlap there is between the directions and smaller the less overlap there is. So we could just multiply s.Albedo (our main color) by that and call it a day!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/d9fc1f3e0c96450abd9ef59e98ef63bb/1.png?token-time=1574380800&token-hash=gzAd2gJs3PXHHpFtrak2cyuF9Ev0nPKm9mfYyiBZnUo%3D)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/a4090dca05f14f429ad03a4470c84035/1.png?token-time=1574380800&token-hash=Vdm_SlJXQAsq4vZb_WjYfv_wD2dancHqZXiLlao_OAE%3D)

Well, not really. There's some weird stuff happening here. I don't know that this is totally accurate.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/bc5f0e48463947d09da8b9f29211f485/1.png?token-time=1574380800&token-hash=p4Ye4IfpxwFhxX271NxwyOTYLnkLIl1j1nyxPTyssBk%3D)

Like look under her chin, I think the shadowy areas kinda should be pushed back a bit. Let's tweak our dot product a little bit. Change the first line to

` **half d = dot(s.Normal, lightDir) * 0.5 + 0.5;**

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/bb8809e7c4a54e1b82d5489f31bb1043/1.png?token-time=1574380800&token-hash=yqfWWk_sURSlkqmC_UNSeHKfEjr7y3LqRJpFQSzVMqk%3D)

by making the dot product half value then adding 0.5, we're basically squishing the possible ranges to be between 0.5 and 1\. (because what would have been 0 normally is now 0.5, and what would have been 1 is still 1.)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/e21aaf8033e84edabc89e96ee25df498/1.png?token-time=1574380800&token-hash=Jtk67-XTuz4PtRpi7ZPGSKJhesrARZj7wELmns6vY8w%3D)

OK, looks more reasonable.

But wait, there's a problem. Look at her eyes! They're purple! Why? Because my directional light is purple!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/67c9e2a8e6c647e194fa906b28f08dfe/1.png?token-time=1574380800&token-hash=OYXcGCVUj31ZIvsXETJ__tTQcaAKKVMMIC_SRDBB6Bc%3D)

Remember, the eyes are on a different mesh that's still using the standard shader! So we need to make sure our custom lighting function uses light color too!

Unity surface shaders basically invisibly add a lot of other code, which is extremely convenient because it lets us use a lot of cool built in functions without having to have them inside our shader files. (This is one of the reasons I've started us out with surface shaders instead of other kinds of shaders!) In the invisible code is a variable **_LightColor0** that holds the light color, so we can use that right now!

Update your lighting function to look like this!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/56e028f17d1a4ddab704ee4c3cf0b518/1.png?token-time=1574380800&token-hash=aoeoQ0njDGda4ZwqLgtOLbDnF19ND3YiU47GYRG-hlA%3D)

We're declaring a half4 c so that our return line doesn't get super long and hard to read. Since this function is a half4 instead of void, we have to return a half4 or the shader will throw errors. The half4 returned is the final color that will be applied to our 3d object!

**_LightColor0**, unlike the other variables we use in our shader, isn't defined outside of a function -- not by us anyway. It actually is defined, but in the invisible code we don't see. We'll return to this idea later when we start looking at vertex shaders. Anyway, save and head back to Unity.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/4c72644b2a104a75aa93a136dec4d883/1.png?token-time=1574380800&token-hash=z4A-iK-W1vjb_68QxrL8cNBI8nxDz_MPpjKajAPJwaM%3D)

Yay we have light color now!

Ahaa but we actually have another problem, although it's not immediately obvious. You can see it if you create a point light with a short range near Claire.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/e01b519feef544e1b23acc3af2bffa7b/1.png?token-time=1574380800&token-hash=yEFpQKaMERGdn8G90MujOHSJQEhZqUCDNrb-oyuZXyg%3D)

The point light is being treated like a square, where the pixel is either inside the range or outside the range, and if it's inside it has the light applied in full, and outside the light isn't applied at all. That hard cutoff. That's NOT the kind of hard cutoff we want for toon lighting because it doesn't even follow the shape of the 3d object!

This is what the parameter atten is for! It stands for **attenuation**, and it means how close we are to the light. If this lighting function is being run on a directional light, attenuation is always 1, because directional lights in Unity have the same intensity no matter where they are, but if the lighting function is being run on a point or spot light, then the attenuation will be something between 0 and 1! Let's update our lighting function to use it!

> **c.rgb = s.Albedo * d * _LightColor0.rgb * atten;**

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/2c4d2800830f4edfbd5f1e42cfe57fbc/1.png?token-time=1574380800&token-hash=OSr6h28TwwSvYTiUMsmiMEH3fdr__sklY-Oho6aIxO4%3D)

Ay there we go!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/58e582c32f3140c482a517f02774a29d/1.png?token-time=1574380800&token-hash=_FkqR-cHZn4jO9oAv55w3j8VahjT-9j9Rd20lBA9AtE%3D)

Well that's great and all, but that is not toon lighting. So let's get to work on that!

### Toon Lighting

To review, a dot product is gonna be a value between 0 and 1 that shows how much overlap between directions there is. We need to establish a cutoff point - if the value is higher than this, there's no shadowiness, and if it's lower, there's maximum shadowiness. Well, we do have the step function. Remember, with the step function, we put in two numbers - if the first is bigger, the result is 0\. If the second is bigger, the result is 1.

If I do this

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/db1fcbe3277a4b3c868967dc9b96e0ed/1.png?token-time=1574380800&token-hash=XqzGLJWFyVEFP6p3wVceSsNEKJpUiG4usiidHn1Yxa8%3D)

we get this

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/8c89404a593948838ba4da83168cfaa0/1.png?token-time=1574380800&token-hash=AjQAB82pfMxwnb-K6NtGH9i4XIbj8oqaStZJryOWAiA%3D)

it's very uh, Sin City or something. I'll be honest I'm not crazy 'bout it. Kinda harsh, don't you think? Let's add some sliders to adjust the shadow size and shadow smoothness like we did with the rim!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/a689114334b4479386812428adec8b73/1.png?token-time=1574380800&token-hash=1kxfonJqP4ux1pHQw34I0MNOe_C7l5MxX0JBVGK-fsg%3D)

Since we'll use these in the lighting function, we will have to declare them above the lighting function, since unlike in C#, the order in which things are defined matters in CG shader code (which is what we are using.)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/d44ed0b7475d462f88d17020e4f8b0dc/1.png?token-time=1574380800&token-hash=_PZP2MjA63mpX-xL5HLMPS0IUoy3t7JeQN8RqXOBtm4%3D)

Then we can modify our lighting function to let us adjust the shadow coverage (like we use _RimPower down in the surface function!) and the smoothness (like how we use _RimSmooth!)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/589013cc6b41409db0259a91d4f96ea3/1.png?token-time=1574380800&token-hash=JhqILslFKwUJnyir5VKx97nRCk-lAXU-RfwbPnbn_GI%3D)

Yeah there we go!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/66a0760c4c4049e89b2348e41c2ae45d/1.png?token-time=1574380800&token-hash=6hlHVFFEORzLMS4iHO1iTqoTq1Ak8WgnRZLwg4Q_Y7E%3D)

That's all well and good, but the shadow being totally black is a bit harsh. Let's have a shadow color to use as our maximum shadowiness. Add _ShadowColor to our properties like so:

> **_ShadowColor("Shadow Color", Color) = (0,0,0,1)**

and declare it above the lighting function

> **half3 _ShadowColor;**

Since multiplying anything by zero makes it zero, we don't want to multiply our shadow color by the "shadow" variable we made from the dot product, because if the shadow variable is 0, it'll just make the color black. Instead, we can use a lerp function with _ShadowColor as the lowest value in the gradient.

> **half3 shadowColor = lerp(_ShadowColor, half3(1, 1, 1), shadow);**

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/3a47565ef3c5441ebe3a32fbd04a40b7/1.png?token-time=1574380800&token-hash=_yoGAZqlwhVeDtxCQQRu1pDmxGq6fAR8x74Nxmijvjw%3D)

Remember, half3(1,1,1) means white!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/0905819a65c041bfb7295933c7ee4de3/1.png?token-time=1574380800&token-hash=bYDBmCOFJ7SZfRl4PqzyMO3eAhiVqXEx0Ah5emG1tfI%3D)

Yay! Now we have ourselves some basic toon lighting! There are a lot of really neat variations we can do on this, but for now, throw some lights into the scene and have some fun looking at how cool this stylized lighting looks!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28235014/8e07f9201b254634b69e6afaf418b238/1.png?token-time=1574380800&token-hash=YTv7o49z984pWWJxauRhiAiU56LQMMtO_Jbf74xFxkA%3D)

The [final shader code](https://www.patreon.com/file?h=28235014&i=4115543) is attached to this post as XibToon.shader.
