// There is no law to be found here.
// Due to the nature of how generic and simple this is and how I found these solutions online from kind strangers,
// I hereby excempt this file from the MIT licenses that shackle the rest of this repository.
// The only license I claim is that you mustn't use this for evil,
// unless an original author of one of these methods reaches out and insists on evil being permitted.
// Copy and paste to your heart's content with no attribution required. 
// - dom

#ifndef __GLSLTRANSLATIONS_HLSL__
#define __GLSLTRANSLATIONS_HLSL__

// glsl style mod - thank you bgolus
// https://forum.unity.com/threads/translating-a-glsl-shader-noise-algorithm-to-hlsl-cg.485750/#post-3164874
#define mod(x, y) (x - y * floor(x / y))

// emulates glsl comparison functions
// found the following somewhere online from someone who found it somewhere online.
// they didn't remember who they found it from, i don't remember who i found it from.
// I expect you to steal this and do the same. if you remember where you found it, pretend you don't
float  lt(float a, float b){ return a < b ? 1.0 : 0.0;}
float  lessThan(float  a, float b){ return lt(a,b); }
float2 lessThan(float2 a, float2 b){ return float2(lt(a.x,b.x),lt(a.y,b.y) );}
float3 lessThan(float3 a, float3 b){ return float3(lt(a.x,b.x),lt(a.y,b.y),lt(a.z,b.z) );}
float4 lessThan(float4 a, float4 b){ return float4(lt(a.x,b.x),lt(a.y,b.y),lt(a.z,b.z),lt(a.w,b.w) );}

float  gt(float a, float b){ return a > b ? 1.0 : 0.0;}
float  greaterThan(float  a, float b){ return gt(a,b); }
float2 greaterThan(float2 a, float2 b){ return float2(gt(a.x,b.x),gt(a.y,b.y) );}
float3 greaterThan(float3 a, float3 b){ return float3(gt(a.x,b.x),gt(a.y,b.y),gt(a.z,b.z) );}
float4 greaterThan(float4 a, float4 b){ return float4(gt(a.x,b.x),gt(a.y,b.y),gt(a.z,b.z),gt(a.w,b.w) );}

#endif //__GLSLTRANSLATIONS_HLSL__