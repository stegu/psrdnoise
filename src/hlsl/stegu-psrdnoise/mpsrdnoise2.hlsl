// This variant of the 2D "psrdnoise" function is compatible with the
// 16-bit half-precision float type. Useful on platforms where
// half-floats are faster, or where 32-bit floats are unavailable.

#ifdef GL_ES
precision mediump float;
#endif

// mpsrdnoise (c) Stefan Gustavson and Ian McEwan,
// ver. 2022-03-29, published under the MIT license:
// https://github.com/stegu/psrdnoise/

#include "../common/stegu-math.hlsl"

float mpsrdnoise(float2 x, float2 period, float alpha, out float2 gradient)
{
	float2 uv = float2(x.x + x.y*0.5, x.y);
	float2 i0 = floor(uv), f0 = frac(uv);
	float cmp = step(f0.y, f0.x);
	float2 o1 = float2(cmp, 1.0-cmp);
	float2 i1 = i0 + o1, i2 = i0 + 1.0;
	float2 v0 = float2(i0.x - i0.y*0.5, i0.y);
	float2 v1 = float2(v0.x + o1.x - o1.y*0.5, v0.y + o1.y);
	float2 v2 = float2(v0.x + 0.5, v0.y + 1.0);
	float2 x0 = x - v0, x1 = x - v1, x2 = x - v2;
	float3 iu, iv, xw, yw;
	if(any(greaterThan(period, float2(0.0, 0.0)))) {
		xw = float3(v0.x, v1.x, v2.x);
		yw = float3(v0.y, v1.y, v2.y);
		if(period.x > 0.0)
			xw = mod(float3(v0.x, v1.x, v2.x), period.x);
		if(period.y > 0.0)
			yw = mod(float3(v0.y, v1.y, v2.y), period.y);
		iu = floor(xw + 0.5*yw + 0.5); iv = floor(yw + 0.5);
	} else {
		iu = float3(i0.x, i1.x, i2.x); iv = float3(i0.y, i1.y, i2.y);
	}
	// Hash permutation carefully tuned to stay within the range
	// of exact representation of integers in a half-float.
	// Tons of mod() operations here, sadly.
	float3 iu_m49 = mod(iu, 49.0);
	float3 iv_m49 = mod(iv, 49.0);
	float3 hashtemp = mod(14.0*iu_m49 + 2.0, 49.0);
	hashtemp = mod(hashtemp*iu_m49 + iv_m49, 49.0);
	float3 hash = mod(14.0*hashtemp + 4.0, 49.0);
	hash = mod(hash*hashtemp, 49.0);
	
	float3 psi = hash*0.1282283 + alpha; // 0.1282283 is 2*pi/49
	float3 gx = cos(psi); float3 gy = sin(psi);
	float2 g0 = float2(gx.x, gy.x);
	float2 g1 = float2(gx.y, gy.y);
	float2 g2 = float2(gx.z, gy.z);
	float3 w = 0.8 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
	w = max(w, 0.0); float3 w2 = w*w; float3 w4 = w2*w2;
	float3 gdotx = float3(dot(g0, x0), dot(g1, x1), dot(g2, x2));
	float n = dot(w4, gdotx);
	float3 w3 = w2*w; float3 dw = -8.0*w3*gdotx;
	float2 dn0 = w4.x*g0 + dw.x*x0;
	float2 dn1 = w4.y*g1 + dw.y*x1;
	float2 dn2 = w4.z*g2 + dw.z*x2;
	gradient = 10.9*(dn0 + dn1 + dn2);
	return 10.9*n;
}

// Adapted to HLSL by Dom Portera, published under the MIT license
// https://github.com/domportera/hlsl-noise