// Include this file to have simple access to every noise function available in this repository.
// Once you're done mucking about, it's recommended that you specifically #include
// only whichever noise functions your shader is actually using

#include "ashima/cellular2D.hlsl"
#include "ashima/cellular2x2.hlsl"
#include "ashima/cellular2x2x2.hlsl"
#include "ashima/cellular3D.hlsl"
#include "ashima/classicnoise2D.hlsl"
#include "ashima/classicnoise3D.hlsl"
#include "ashima/classicnoise4D.hlsl"
#include "ashima/noise2D.hlsl"
#include "ashima/noise3D.hlsl"
#include "ashima/noise3Dgrad.hlsl"
#include "ashima/noise4D.hlsl"
#include "ashima/psrdnoise2D.hlsl"

#include "stegu-psrdnoise/mpsrdnoise2.hlsl"
#include "stegu-psrdnoise/psrdnoise2.hlsl"
#include "stegu-psrdnoise/psrdnoise3.hlsl"
#include "stegu-psrdnoise/psrddnoise2.hlsl"
#include "stegu-psrdnoise/psrddnoise3.hlsl"