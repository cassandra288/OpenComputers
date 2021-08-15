# OpenTGL
OpenTGL (Open Terminal Graphics Library) is a library written for OpenOS. It adds double buffered graphics including adding methods for rendering "SemiChars" (a half height character which is square, doubling the vertical resolution) and also supports alpha blending.

It implements multiple rasterizers both for SemiChars and full Chars. The rasterizers are as follows:
- Line Rasterizer
- Rectangle Rasterizer
- Box Rasterizer (just the frame of a rectangle)
- Ellipse Rasterizer

OpenTGL also has multiple functions for rendering text in different ways, including full support for newline characters.

Documentation is in the [github wiki](https://github.com/Thomas2889/OpenComputers/wiki/OpenTGL)