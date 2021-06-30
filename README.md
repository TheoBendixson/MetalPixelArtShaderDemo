# 2D Scaling Pixel Art Shader Demo App 
# (Mac OS / Metal Shading Language)

## What is it?
This is a demo project for a scaling 2D pixel art shader, currently written in the Metal shading language and available on the Mac OS platform.

It accompanies an article I wrote on Medium, in which I discuss the math behind the shader, why it works, and what the different parameters mean:
[How To Render Perfect Pixel Art With Apple's Metal Shading Language](https://theobendixson.medium.com/how-to-render-perfect-pixel-art-with-apples-metal-shading-language-3200bc6b7de8)

## How to build and run it
This demo project is somewhat unorthodox. It follows the handmade philosophy, meaning most of the project is built from scratch so you can get a deeper understanding how it works. I also want you to have more control when you incorporate it into your games.

That means this project doesn't use Xcode's build system. It has its own build script that lays out exactly what it does, line by line so you can follow along better.

The build script is located at the following path: 
code/mac_platform_layer/build.sh

To build the project, open terminal, cd into the aforementioned directory, and then run the script. The built application will appear in the build/mac_os directory.

## Why is there an Xcode project?
Like Casey Muratori, I only use Xcode as a debugger. The Xcode project is a bare bones project template that simply lets you add various code files so you can step through them visually with the debugger. It serves no other purpose.

In order to debug this project, you may need to change the app target for the default build scheme to your built application in the build/mac_os directory. Aside from that, you just press the play button and the app will launch inside of the debugger. You ought to be good to go!

## What's the deal with the lack of objects?
Unlike Apple's typical sample projects, this demo project doesn't use much object oriented code. I don't find object oriented programming all that helpful and therefore don't use it.

I want to show people an alternative to the mainstream, a way to build games and game engines that is less abstract, more simple, and more direct. I use a minimal form of C++, so it's more like straight C programming for most of the logic that runs on the CPU.

If you've never seen something like this before and find yourself somewhat put off by it, I encourage you to be patient with it and give it a try. You might find that you enjoy having such direct control over the way your software works. I certainly do and will never go back to my old object oriented ways!


