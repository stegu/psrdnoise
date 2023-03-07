# psrdnoise
Tiling simplex flow noise in 2-D and 3-D compatible with GLSL 1.20 (WebGL 1.0) and above.

A WGSL port is in the "src" directory with the GLSL versions, and it seems
to be working (yields the same results as the corresponding GLSL functions),
but I have only done a minimal amount of testing. If you find bugs, please
report them in the "Issues" section.

A variant of 2-D noise which is compatible with "mediump" 16-bit float precision
has been added to the repository. (A 3-D version is more tricky. No promises yet.)
As with the WGSL port, bug reports and general feedback on the code is appreciated.

A scientific article on this is published in Journal of Computer Graphics
Techniques, [JCGT](http://jcgt.org/published/0011/01/02/).
Code is in the src/ folder, and there are some live WebGL examples and
a tutorial on how to use these functions on
[the accompanying Github Pages site](https://stegu.github.io/psrdnoise).

Ports to HLSL are in the src/hlsl directory. These were made by @domportera,
I am not fluent in HLSL myself.

A Unity shader project using another HLSL port of these functions is available
from @chmodseven: https://github.com/chmodseven/psrdnoise

The infamous troll-owned patent on Simplex Noise finally expired in January 2022,
but none of these functions implement any of the patented methods. That patent
was arguably never valid in the first place, because I would argue that its
primary claim is demonstrably false. In any case, it's a moot point now.

## LICENSE

The entire content of the docs/ folder is in the public domain, with the
exception of GLSL shader code that comes with an MIT license as specified
in the code comments.

All GLSL code in this repository is published under the permissive
[MIT license](https://opensource.org/licenses/MIT):

Copyright 2021 Stefan Gustavson and Ian McEwan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
