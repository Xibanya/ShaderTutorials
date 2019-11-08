---
layout: default
title: Cutouts
date: 2019-07-11 13:45:00
categories: [tutorial]
tags: [clip]
---
Last time [we learned how to do toon shading](https://www.patreon.com/posts/part-10-toon-for-28235014)!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/62d44117eb1e46c9810145fe9387b48e/1.png){width="300px"}

Claire in her full toony glory -- btw this is a variant of the toon shader we did last time that has the rim strongest on one side. I challenge you to figure that out for yourself. Or, if you're a $5 patron, [you can just download it straight up here](https://www.patreon.com/posts/toon-side-rim-28290325).

And yet, something is amiss -- her eyes and mouth are just kinda _dull_. That's because they're still using the standard shader! Let's put them on the toon shader too! Make a new material called ClaireFeatures and drag Girl01_FacialAnimMap into the Albedo texture slot. Put the shader XibToon on it. If you don't already have XibToon, [you can download it here](https://www.patreon.com/file?h=28304378&i=4125859). (It is also attached to this post.)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/615663c77d2f4cb5998e450290798ab6/1.png)

Now let's drag the material ClaireFeatures into the material slots on Girl_Brows_Geo, Girl_Eyes_Geo, and Girl_Mouth_Geo in the hierarchy.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/2a479678981045bc9f6b2fd4797503a9/1.png)

Oh no! It's like she's got clown makeup on. This happened because the eyes, brows, and mouth, are on a texture in which the background is transparent and our shader is not designed to handle transparency. 

Well first, let's examine our texture import settings to make sure we're importing it with its alpha transparency handled correctly. Hm, "Alpha Is Transparency" isn't checked, Let's try that.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/ff242bfe9cef466fab4335f0f611bbde/1.png)

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/7ab4a94d7ec94a44bf356d5e22273bfd/1.png)

aaaaAAAAAAAAAA! Nope, that's not the solution! We need to make a shader that only shows the 3d object if the pixel currently being colored isn't transparent.

Go to XibToon in the project files and duplicate it. Name the duplicate XibToon Cutout. Open XibToon Cutout in Visual Studio and change the name at the top to  XibToon Cutout. 

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/8eecd26770be48a3bd39c9c8c9cf35e6/1.png)

Let's also add this property

> **_Cutout("Cutout", Range(0,1)) = 0.5**

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/7f162a60ea914882803d06ddc9272b75/1.png)

 Back in Unity, change the shader used by the ClaireFeatures material to XibToon Cutout. You can see the new cutout slider we just added at the bottom of the material properties there.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/5891aed13e9e4b51866baa1d1c72f8df/1.png)

Back in our code, update the Tags near the top to this:

> **Tags { "RenderType" = "TransparentCutout" "Queue" = "Transparent" }**

Render Type, as you imagine, is the type of object being rendered. Queue tells Unity what order to draw the object in. In Forward rendering (which we're using) objects get drawn back to front, going forward (get it?) so transparent objects should be drawn last so that the stuff behind them that we should see has already been drawn. So we're telling Unity to draw the things with this shader after the other stuff.

Above your surface function, be sure to declare our _Cutout variable with **half _Cutout;**

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/70b6348be6a9473a8fc890ef02fa6683/1.png?token-time=1574380800&token-hash=PFdC_dGyPEdZGfywtTS9vVgvnBWpbeW6Im9Xxqn6WzA%3D)

The transparency info has been in the texture all along, we just weren't using it. tex2D gets us a variable that holds 4 numbers at once, red, green, blue, and alpha (transparency) so let's get this info from our texture and put it into our Albedo and Alpha values.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/1823c8bbc09f4983b31c2e900ceaf679/1.png?token-time=1574380800&token-hash=i5STtAuiLlRpYp9lpbw--Qc769vouqi8SLWqwK5sZqM%3D)

If you were to save and head back to Unity now though, you'd find that nothing's changed. We need to do one more thing. Under those three lines (or anywhere in your surface function after them) put this:

> **clip(tex.a - _Cutout);**

This clip function takes a number. If the number given to it is less than zero, then the pixel being shaded won't even be drawn at all. So we are saying, if the alpha value of the texture at the pixel we're coloring is less than the number we put into _Cutout, make that pixel invisible. 

We should now have this.

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/44f4e188fead465880b99ea3817b520d/1.png?token-time=1574380800&token-hash=bkFYvE4KRs6cNzz1h2TJEslgY7F9MUv1B82FxnbUC7E%3D)

Save and head back to Unity. 

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/4af2c0772cfc4e638c1996dc7659586e/1.png?token-time=1574380800&token-hash=_3Sgw2MfNQagNQI7L1vjOAt0Yf0uubmSiwuOR27pns4%3D)

Yay!

btw if you get something like this

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/d05316960c774271aa3a06261ed0a434/1.png?token-time=1574380800&token-hash=3nbLf_k75UhZMu02KwbMKt8V_Hz1iMXEN3CWejnO7qo%3D)

make sure the Render Queue in the material properties is set to Transparent

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/0e7b3ba4cb8b4b799066a62bed1507f0/1.png?token-time=1574380800&token-hash=8PNTww0ezJZNpyY7pd4L9cStDpu9727WX8mcUl7HWZ0%3D)

Hooray! Now everything is in balance and all is right with the world!

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/5bc8b89e10ff4844b9152801d37d7215/1.png?token-time=1574380800&token-hash=yFP67WS7J7NRgalGDaFMZDwuSFxyAYAfUd3eJtDyr18%3D)

Now that you have your cutout shader, try sliding the cutout value around to see the effect that has.

This is at 0.05

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/2916615d636f441a9bdaae6314522ad0/1.png?token-time=1574380800&token-hash=9zT5-NsjBht7NcmyhsXct92mdk37zNZjXCPdKHabhZA%3D)

This is at 1

![](https://c10.patreonusercontent.com/3/eyJwIjoxfQ%3D%3D/patreon-media/p/post/28304378/74f74314b8b445a7abf8c946f62e0199/1.png?token-time=1574380800&token-hash=_yEeuRkWuaJx2q3xEgLYmL4JC8URP7cAA1jFJbpRlkI%3D)

Cutouts are a really handy trick for a lot of things. They get used a lot for making plants 'cause then you don't have to model a whole branch with leaves, you just stick a cutout shader on a plane! In fact they're pretty much perfect for things that have complicated shapes but are mostly flat. If you're feeling creative, try making some transparent textures on your own and putting them into cutout materials on planes.

{% include TutorialFooter.md %}
