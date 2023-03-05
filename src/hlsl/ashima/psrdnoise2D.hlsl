//
// float3  psrdnoise(float2 pos, float2 per, float rot)
// float3  psdnoise(float2 pos, float2 per)
// float psrnoise(float2 pos, float2 per, float rot)
// float psnoise(float2 pos, float2 per)
// float3  srdnoise(float2 pos, float rot)
// float3  sdnoise(float2 pos)
// float srnoise(float2 pos, float rot)
// float snoise(float2 pos)
//
// Periodic (tiling) 2-D simplex noise (hexagonal lattice gradient noise)
// with rotating gradients and analytic derivatives.
// Variants also without the derivative (no "d" in the name), without
// the tiling property (no "p" in the name) and without the rotating
// gradients (no "r" in the name).
//
// This is (yet) another variation on simplex noise. It's similar to the
// version presented by Ken Perlin, but the grid is axis-aligned and
// slightly stretched in the y direction to permit rectangular tiling.
//
// The noise can be made to tile seamlessly to any integer period in x and
// any even integer period in y. Odd periods may be specified for y, but
// then the actual tiling period will be twice that number.
//
// The rotating gradients give the appearance of a swirling motion, and can
// serve a similar purpose for animation as motion along z in 3-D noise.
// The rotating gradients in conjunction with the analytic derivatives
// can make "flow noise" effects as presented by Perlin and Neyret.
//
// float3 {p}s{r}dnoise(float2 pos {, float2 per} {, float rot})
// "pos" is the input (x,y) coordinate
// "per" is the x and y period, where per.x is a positive integer
//    and per.y is a positive even integer
// "rot" is the angle to rotate the gradients (any float value,
//    where 0.0 is no rotation and 1.0 is one full turn)
// The first component of the 3-element return vector is the noise value.
// The second and third components are the x and y partial derivatives.
//
// float {p}s{r}noise(float2 pos {, float2 per} {, float rot})
// "pos" is the input (x,y) coordinate
// "per" is the x and y period, where per.x is a positive integer
//    and per.y is a positive even integer
// "rot" is the angle to rotate the gradients (any float value,
//    where 0.0 is no rotation and 1.0 is one full turn)
// The return value is the noise value.
// Partial derivatives are not computed, making these functions faster.
//
// Author: Stefan Gustavson (stefan.gustavson@gmail.com)
// Version 2016-05-10.
//
// Many thanks to Ian McEwan of Ashima Arts for the
// idea of using a permutation polynomial.
//
// Copyright (c) 2016 Stefan Gustavson. All rights reserved.
// Distributed under the MIT license. See LICENSE file.
// https://github.com/stegu/webgl-noise
//

//
// TODO: One-pixel wide artefacts used to occur due to precision issues with
// the gradient indexing. This is specific to this variant of noise, because
// one axis of the simplex grid is perfectly aligned with the input x axis.
// The errors were rare, and they are now very unlikely to ever be visible
// after a quick fix was introduced: a small offset is added to the y coordinate.
// A proper fix would involve using round() instead of floor() in selected
// places, but the quick fix works fine.
// (If you run into problems with this, please let me know.)
//

#include "../common/stegu-math.hlsl"

// Hashed 2-D gradients with an extra rotation.
// (The constant 0.0243902439 is 1/41)
float2 rgrad2(float2 p, float rot) {
#if 0
// Map from a line to a diamond such that a shift maps to a rotation.
  float u = permute(permute(p.x) + p.y) * 0.0243902439 + rot; // Rotate by shift
  u = 4.0 * frac(u) - 2.0;
  // (This vector could be normalized, exactly or approximately.)
  return float2(abs(u)-1.0, abs(abs(u+1.0)-2.0)-1.0);
#else
// For more isotropic gradients, sin/cos can be used instead.
  float u = permute(permute(p.x) + p.y) * 0.0243902439 + rot; // Rotate by shift
  u = frac(u) * 6.28318530718; // 2*pi
  return float2(cos(u), sin(u));
#endif
}

//
// 2-D tiling simplex noise with rotating gradients and analytical derivative.
// The first component of the 3-element return vector is the noise value,
// and the second and third components are the x and y partial derivatives.
//
float3 psrdnoise(float2 pos, float2 per, float rot) {
  // Hack: offset y slightly to hide some rare artifacts
  pos.y += 0.01;
  // Skew to hexagonal grid
  float2 uv = float2(pos.x + pos.y*0.5, pos.y);
  
  float2 i0 = floor(uv);
  float2 f0 = frac(uv);
  // Traversal order
  float2 i1 = (f0.x > f0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);

  // Unskewed grid points in (x,y) space
  float2 p0 = float2(i0.x - i0.y * 0.5, i0.y);
  float2 p1 = float2(p0.x + i1.x - i1.y * 0.5, p0.y + i1.y);
  float2 p2 = float2(p0.x + 0.5, p0.y + 1.0);

  // Integer grid point indices in (u,v) space
  i1 = i0 + i1;
  float2 i2 = i0 + float2(1.0, 1.0);

  // Vectors in unskewed (x,y) coordinates from
  // each of the simplex corners to the evaluation point
  float2 d0 = pos - p0;
  float2 d1 = pos - p1;
  float2 d2 = pos - p2;

  // Wrap i0, i1 and i2 to the desired period before gradient hashing:
  // wrap points in (x,y), map to (u,v)
  float3 xw = mod(float3(p0.x, p1.x, p2.x), per.x);
  float3 yw = mod(float3(p0.y, p1.y, p2.y), per.y);
  float3 iuw = xw + 0.5 * yw;
  float3 ivw = yw;
  
  // Create gradients from indices
  float2 g0 = rgrad2(float2(iuw.x, ivw.x), rot);
  float2 g1 = rgrad2(float2(iuw.y, ivw.y), rot);
  float2 g2 = rgrad2(float2(iuw.z, ivw.z), rot);

  // Gradients dot vectors to corresponding corners
  // (The derivatives of this are simply the gradients)
  float3 w = float3(dot(g0, d0), dot(g1, d1), dot(g2, d2));
  
  // Radial weights from corners
  // 0.8 is the square of 2/sqrt(5), the distance from
  // a grid point to the nearest simplex boundary
  float3 t = 0.8 - float3(dot(d0, d0), dot(d1, d1), dot(d2, d2));

  // Partial derivatives for analytical gradient computation
  float3 dtdx = -2.0 * float3(d0.x, d1.x, d2.x);
  float3 dtdy = -2.0 * float3(d0.y, d1.y, d2.y);

  // Set influence of each surflet to zero outside radius sqrt(0.8)
  if (t.x < 0.0) {
    dtdx.x = 0.0;
    dtdy.x = 0.0;
	t.x = 0.0;
  }
  if (t.y < 0.0) {
    dtdx.y = 0.0;
    dtdy.y = 0.0;
	t.y = 0.0;
  }
  if (t.z < 0.0) {
    dtdx.z = 0.0;
    dtdy.z = 0.0;
	t.z = 0.0;
  }

  // Fourth power of t (and third power for derivative)
  float3 t2 = t * t;
  float3 t4 = t2 * t2;
  float3 t3 = t2 * t;
  
  // Final noise value is:
  // sum of ((radial weights) times (gradient dot vector from corner))
  float n = dot(t4, w);
  
  // Final analytical derivative (gradient of a sum of scalar products)
  float2 dt0 = float2(dtdx.x, dtdy.x) * 4.0 * t3.x;
  float2 dn0 = t4.x * g0 + dt0 * w.x;
  float2 dt1 = float2(dtdx.y, dtdy.y) * 4.0 * t3.y;
  float2 dn1 = t4.y * g1 + dt1 * w.y;
  float2 dt2 = float2(dtdx.z, dtdy.z) * 4.0 * t3.z;
  float2 dn2 = t4.z * g2 + dt2 * w.z;

  return 11.0*float3(n, dn0 + dn1 + dn2);
}

//
// 2-D tiling simplex noise with fixed gradients
// and analytical derivative.
// This function is implemented as a wrapper to "psrdnoise",
// at the minimal cost of three extra additions.
//
float3 psdnoise(float2 pos, float2 per) {
  return psrdnoise(pos, per, 0.0);
}

//
// 2-D tiling simplex noise with rotating gradients,
// but without the analytical derivative.
//
float psrnoise(float2 pos, float2 per, float rot) {
  // Offset y slightly to hide some rare artifacts
  pos.y += 0.001;
  // Skew to hexagonal grid
  float2 uv = float2(pos.x + pos.y*0.5, pos.y);
  
  float2 i0 = floor(uv);
  float2 f0 = frac(uv);
  // Traversal order
  float2 i1 = (f0.x > f0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);

  // Unskewed grid points in (x,y) space
  float2 p0 = float2(i0.x - i0.y * 0.5, i0.y);
  float2 p1 = float2(p0.x + i1.x - i1.y * 0.5, p0.y + i1.y);
  float2 p2 = float2(p0.x + 0.5, p0.y + 1.0);

  // Integer grid point indices in (u,v) space
  i1 = i0 + i1;
  float2 i2 = i0 + float2(1.0, 1.0);

  // Vectors in unskewed (x,y) coordinates from
  // each of the simplex corners to the evaluation point
  float2 d0 = pos - p0;
  float2 d1 = pos - p1;
  float2 d2 = pos - p2;

  // Wrap i0, i1 and i2 to the desired period before gradient hashing:
  // wrap points in (x,y), map to (u,v)
  float3 xw = mod(float3(p0.x, p1.x, p2.x), per.x);
  float3 yw = mod(float3(p0.y, p1.y, p2.y), per.y);
  float3 iuw = xw + 0.5 * yw;
  float3 ivw = yw;
  
  // Create gradients from indices
  float2 g0 = rgrad2(float2(iuw.x, ivw.x), rot);
  float2 g1 = rgrad2(float2(iuw.y, ivw.y), rot);
  float2 g2 = rgrad2(float2(iuw.z, ivw.z), rot);

  // Gradients dot vectors to corresponding corners
  // (The derivatives of this are simply the gradients)
  float3 w = float3(dot(g0, d0), dot(g1, d1), dot(g2, d2));
  
  // Radial weights from corners
  // 0.8 is the square of 2/sqrt(5), the distance from
  // a grid point to the nearest simplex boundary
  float3 t = 0.8 - float3(dot(d0, d0), dot(d1, d1), dot(d2, d2));

  // Set influence of each surflet to zero outside radius sqrt(0.8)
  t = max(t, 0.0);

  // Fourth power of t
  float3 t2 = t * t;
  float3 t4 = t2 * t2;
  
  // Final noise value is:
  // sum of ((radial weights) times (gradient dot vector from corner))
  float n = dot(t4, w);
  
  // Rescale to cover the range [-1,1] reasonably well
  return 11.0*n;
}

//
// 2-D tiling simplex noise with fixed gradients,
// without the analytical derivative.
// This function is implemented as a wrapper to "psrnoise",
// at the minimal cost of three extra additions.
//
float psnoise(float2 pos, float2 per) {
  return psrnoise(pos, per, 0.0);
}

//
// 2-D non-tiling simplex noise with rotating gradients and analytical derivative.
// The first component of the 3-element return vector is the noise value,
// and the second and third components are the x and y partial derivatives.
//
float3 srdnoise(float2 pos, float rot) {
  // Offset y slightly to hide some rare artifacts
  pos.y += 0.001;
  // Skew to hexagonal grid
  float2 uv = float2(pos.x + pos.y*0.5, pos.y);
  
  float2 i0 = floor(uv);
  float2 f0 = frac(uv);
  // Traversal order
  float2 i1 = (f0.x > f0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);

  // Unskewed grid points in (x,y) space
  float2 p0 = float2(i0.x - i0.y * 0.5, i0.y);
  float2 p1 = float2(p0.x + i1.x - i1.y * 0.5, p0.y + i1.y);
  float2 p2 = float2(p0.x + 0.5, p0.y + 1.0);

  // Integer grid point indices in (u,v) space
  i1 = i0 + i1;
  float2 i2 = i0 + float2(1.0, 1.0);

  // Vectors in unskewed (x,y) coordinates from
  // each of the simplex corners to the evaluation point
  float2 d0 = pos - p0;
  float2 d1 = pos - p1;
  float2 d2 = pos - p2;

  float3 x = float3(p0.x, p1.x, p2.x);
  float3 y = float3(p0.y, p1.y, p2.y);
  float3 iuw = x + 0.5 * y;
  float3 ivw = y;
  
  // Avoid precision issues in permutation
  iuw = mod289(iuw);
  ivw = mod289(ivw);

  // Create gradients from indices
  float2 g0 = rgrad2(float2(iuw.x, ivw.x), rot);
  float2 g1 = rgrad2(float2(iuw.y, ivw.y), rot);
  float2 g2 = rgrad2(float2(iuw.z, ivw.z), rot);

  // Gradients dot vectors to corresponding corners
  // (The derivatives of this are simply the gradients)
  float3 w = float3(dot(g0, d0), dot(g1, d1), dot(g2, d2));
  
  // Radial weights from corners
  // 0.8 is the square of 2/sqrt(5), the distance from
  // a grid point to the nearest simplex boundary
  float3 t = 0.8 - float3(dot(d0, d0), dot(d1, d1), dot(d2, d2));

  // Partial derivatives for analytical gradient computation
  float3 dtdx = -2.0 * float3(d0.x, d1.x, d2.x);
  float3 dtdy = -2.0 * float3(d0.y, d1.y, d2.y);

  // Set influence of each surflet to zero outside radius sqrt(0.8)
  if (t.x < 0.0) {
    dtdx.x = 0.0;
    dtdy.x = 0.0;
	t.x = 0.0;
  }
  if (t.y < 0.0) {
    dtdx.y = 0.0;
    dtdy.y = 0.0;
	t.y = 0.0;
  }
  if (t.z < 0.0) {
    dtdx.z = 0.0;
    dtdy.z = 0.0;
	t.z = 0.0;
  }

  // Fourth power of t (and third power for derivative)
  float3 t2 = t * t;
  float3 t4 = t2 * t2;
  float3 t3 = t2 * t;
  
  // Final noise value is:
  // sum of ((radial weights) times (gradient dot vector from corner))
  float n = dot(t4, w);
  
  // Final analytical derivative (gradient of a sum of scalar products)
  float2 dt0 = float2(dtdx.x, dtdy.x) * 4.0 * t3.x;
  float2 dn0 = t4.x * g0 + dt0 * w.x;
  float2 dt1 = float2(dtdx.y, dtdy.y) * 4.0 * t3.y;
  float2 dn1 = t4.y * g1 + dt1 * w.y;
  float2 dt2 = float2(dtdx.z, dtdy.z) * 4.0 * t3.z;
  float2 dn2 = t4.z * g2 + dt2 * w.z;

  return 11.0*float3(n, dn0 + dn1 + dn2);
}

//
// 2-D non-tiling simplex noise with fixed gradients and analytical derivative.
// This function is implemented as a wrapper to "srdnoise",
// at the minimal cost of three extra additions.
//
float3 sdnoise(float2 pos) {
  return srdnoise(pos, 0.0);
}

//
// 2-D non-tiling simplex noise with rotating gradients,
// without the analytical derivative.
//
float srnoise(float2 pos, float rot) {
  // Offset y slightly to hide some rare artifacts
  pos.y += 0.001;
  // Skew to hexagonal grid
  float2 uv = float2(pos.x + pos.y*0.5, pos.y);
  
  float2 i0 = floor(uv);
  float2 f0 = frac(uv);
  // Traversal order
  float2 i1 = (f0.x > f0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);

  // Unskewed grid points in (x,y) space
  float2 p0 = float2(i0.x - i0.y * 0.5, i0.y);
  float2 p1 = float2(p0.x + i1.x - i1.y * 0.5, p0.y + i1.y);
  float2 p2 = float2(p0.x + 0.5, p0.y + 1.0);

  // Integer grid point indices in (u,v) space
  i1 = i0 + i1;
  float2 i2 = i0 + float2(1.0, 1.0);

  // Vectors in unskewed (x,y) coordinates from
  // each of the simplex corners to the evaluation point
  float2 d0 = pos - p0;
  float2 d1 = pos - p1;
  float2 d2 = pos - p2;

  // Wrap i0, i1 and i2 to the desired period before gradient hashing:
  // wrap points in (x,y), map to (u,v)
  float3 x = float3(p0.x, p1.x, p2.x);
  float3 y = float3(p0.y, p1.y, p2.y);
  float3 iuw = x + 0.5 * y;
  float3 ivw = y;
  
  // Avoid precision issues in permutation
  iuw = mod289(iuw);
  ivw = mod289(ivw);

  // Create gradients from indices
  float2 g0 = rgrad2(float2(iuw.x, ivw.x), rot);
  float2 g1 = rgrad2(float2(iuw.y, ivw.y), rot);
  float2 g2 = rgrad2(float2(iuw.z, ivw.z), rot);

  // Gradients dot vectors to corresponding corners
  // (The derivatives of this are simply the gradients)
  float3 w = float3(dot(g0, d0), dot(g1, d1), dot(g2, d2));
  
  // Radial weights from corners
  // 0.8 is the square of 2/sqrt(5), the distance from
  // a grid point to the nearest simplex boundary
  float3 t = 0.8 - float3(dot(d0, d0), dot(d1, d1), dot(d2, d2));

  // Set influence of each surflet to zero outside radius sqrt(0.8)
  t = max(t, 0.0);

  // Fourth power of t
  float3 t2 = t * t;
  float3 t4 = t2 * t2;
  
  // Final noise value is:
  // sum of ((radial weights) times (gradient dot vector from corner))
  float n = dot(t4, w);
  
  // Rescale to cover the range [-1,1] reasonably well
  return 11.0*n;
}

//
// 2-D non-tiling simplex noise with fixed gradients,
// without the analytical derivative.
// This function is implemented as a wrapper to "srnoise",
// at the minimal cost of three extra additions.
// Note: if this kind of noise is all you want, there are faster
// GLSL implementations of non-tiling simplex noise out there.
// This one is included mainly for completeness and compatibility
// with the other functions in the file.
//
float snoise_srnoise(float2 pos) {
  return srnoise(pos, 0.0);
}
