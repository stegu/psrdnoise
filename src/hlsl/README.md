[Source repo where this HLSL port is maintained](https://github.com/domportera/hlsl-noise)

Ports of [this library](https://github.com/ashima/webgl-noise) to HLSL are also included. [This fork](https://github.com/stegu/webgl-noise) (also by the author of psrdnoise) is your best source of information about these functions.

These have been modified for compatibility with HLSL (of course), removing redundant code and renaming things where necessary so that you may #include to your heart's content without worrying about function redefinition errors. I've even included a "noise-include-all.hlsl" for your convenience if you'd like to play around.

When using this, ensure you are using a compiler that supports macros. If you're not, you may need to edit the `special-math.hlsl` file to convert the `mod` macro into several explicit overloaded functions.