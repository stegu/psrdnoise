//
// psrddnoise3.glsl
//
// Authors: Stefan Gustavson (stefan.gustavson@gmail.com)
// and Ian McEwan (ijm567@gmail.com)
// Version 2021-12-02, published under the MIT license (see below)
//
// Copyright (c) 2021 Stefan Gustavson and Ian McEwan.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

//
// Periodic (tiling) 3-D simplex noise (tetrahedral lattice gradient noise)
// with rotating gradients and analytic derivatives.
//
// This is (yet) another variation on simplex noise. Unlike previous
// implementations, the grid is axis-aligned to permit rectangular tiling.
// The noise pattern can be made to tile seamlessly to any integer periods
// up to 289 units in the x, y and z directions. Specifying a longer
// period than 289 will result in errors in the noise field.
//
// This particular version of 3-D noise also implements animation by rotating
// the generating gradient at each lattice point around a pseudo-random axis.
// The rotating gradients give the appearance of a swirling motion, and
// can serve a similar purpose for animation as motion along the fourth
// dimension in 4-D noise. 
//
// The rotating gradients in conjunction with the built-in ability to
// compute exact analytic derivatives allow for "flow noise" effects
// as presented by Ken Perlin and Fabrice Neyret.
//

// Use Perlin's rotated grid instead of the new tiling grid?
// Enabling this adds about 1% to the execution time and
// requires all periods to be multiples of 3. Other
// integer periods can be specified, but when not evenly
// divisible by 3, the actual period will be 3 times longer.
// Take care not to overstep the maximum allowed period (288).
//#define PERLINGRID

// Enable faster gradient rotations?
// Enabling this saves about 10% on execution time,
// but the function will not run faster for alpha = 0.
//#define FASTROTATION


//
// 3-D tiling simplex noise with rotating gradients and first and
// second order analytical derivatives.
// "float3 x" is the point (x,y,z) to evaluate
// "float3 period" is the desired periods along x,y,z, up to 289.
// (If Perlin's grid is used, multiples of 3 up to 288 are allowed.)
// "float alpha" is the rotation (in radians) for the swirling gradients.
// The "float" return value is the noise value n,
// the "out float3 gradient" argument returns the x,y,z 1st order derivatives,
// and "out float3 dg, out float3 dg2" return the 2nd order derivatives, with
// dg = (d2n/dx2, d2ndy2, d2n/dz2) dg2 = (d2n/dxy, d2n/dyz, d2n/dxz).
//
// The function executes 15% faster if alpha is dynamically constant == 0.0
// across all fragments being executed in parallel.
// (This speedup will not happen if FASTROTATION is enabled. Do not specify
// FASTROTATION if you are not actually going to use the rotation.)
//
// Setting any period to 0.0 or a negative value will skip the periodic
// wrap for that dimension. Setting all periods to 0.0 makes the function
// execute about 10% faster.
//
// Not using the return values for the first or second order derivatives
// will make the compiler eliminate the code for computing that value.
// Not using "dg" and "dg2" speeds up the function by 15-20%. Using
// none of "gradient", "dg" and "dg2" speeds up the function by 25-30%.
//

#include "../common/stegu-math.hlsl"

float psrddnoise(float3 x, float3 period, float alpha, out float3 gradient,
	out float3 dg, out float3 dg2)
{

#ifndef PERLINGRID
  // Transformation matrices for the axis-aligned simplex grid
  const float3x3 M = float3x3(0.0, 1.0, 1.0,
                      1.0, 0.0, 1.0,
                      1.0, 1.0, 0.0);

  const float3x3 Mi = float3x3(-0.5, 0.5, 0.5,
                        0.5,-0.5, 0.5,
                        0.5, 0.5,-0.5);
#endif

  float3 uvw;

  // Transform to simplex space (tetrahedral grid)
#ifndef PERLINGRID
  // Use matrix multiplication, let the compiler optimise
  uvw = mul(M, x);
#else
  // Optimised transformation to uvw (slightly faster than
  // the equivalent matrix multiplication on most platforms)
  uvw = x + dot(x, float3(1.0/3.0));
#endif

  // Determine which simplex we're in, i0 is the "base corner"
  float3 i0 = floor(uvw);
  float3 f0 = frac(uvw); // coords within "skewed cube"

  // To determine which simplex corners are closest, rank order the
  // magnitudes of u,v,w, resolving ties in priority order u,v,w,
  // and traverse the four corners from largest to smallest magnitude.
  // o1, o2 are offsets in simplex space to the 2nd and 3rd corners.
  float3 g_ = step(f0.xyx, f0.yzz); // Makes comparison "less-than"
  float3 l_ = 1.0 - g_;             // complement is "greater-or-equal"
  float3 g = float3(l_.z, g_.xy);
  float3 l = float3(l_.xy, g_.z);
  float3 o1 = min( g, l );
  float3 o2 = max( g, l );

  // Enumerate the remaining simplex corners
  float3 i1 = i0 + o1;
  float3 i2 = i0 + o2;
  float3 i3 = i0 + float3(1.0, 1.0, 1.0);

  float3 v0, v1, v2, v3;

  // Transform the corners back to texture space
#ifndef PERLINGRID
  v0 = mul(Mi, i0);
  v1 = mul(Mi, i1);
  v2 = mul(Mi, i2);
  v3 = mul(Mi, i3);
#else
  // Optimised transformation (mostly slightly faster than a matrix)
  v0 = i0 - dot(i0, float3(1.0/6.0));
  v1 = i1 - dot(i1, float3(1.0/6.0));
  v2 = i2 - dot(i2, float3(1.0/6.0));
  v3 = i3 - dot(i3, float3(1.0/6.0));
#endif

  // Compute vectors to each of the simplex corners
  float3 x0 = x - v0;
  float3 x1 = x - v1;
  float3 x2 = x - v2;
  float3 x3 = x - v3;

  if(any(greaterThan(period, float3(0.0, 0.0, 0.0)))) {
    // Wrap to periods and transform back to simplex space
    float4 vx = float4(v0.x, v1.x, v2.x, v3.x);
    float4 vy = float4(v0.y, v1.y, v2.y, v3.y);
    float4 vz = float4(v0.z, v1.z, v2.z, v3.z);
	// Wrap to periods where specified
	if(period.x > 0.0) vx = mod(vx, period.x);
	if(period.y > 0.0) vy = mod(vy, period.y);
	if(period.z > 0.0) vz = mod(vz, period.z);
    // Transform back
#ifndef PERLINGRID
    i0 = mul(M, float3(vx.x, vy.x, vz.x));
    i1 = mul(M, float3(vx.y, vy.y, vz.y));
    i2 = mul(M, float3(vx.z, vy.z, vz.z));
    i3 = mul(M, float3(vx.w, vy.w, vz.w));
#else
    v0 = float3(vx.x, vy.x, vz.x);
    v1 = float3(vx.y, vy.y, vz.y);
    v2 = float3(vx.z, vy.z, vz.z);
    v3 = float3(vx.w, vy.w, vz.w);
    // Transform wrapped coordinates back to uvw
    i0 = v0 + dot(v0, float3(1.0/3.0));
    i1 = v1 + dot(v1, float3(1.0/3.0));
    i2 = v2 + dot(v2, float3(1.0/3.0));
    i3 = v3 + dot(v3, float3(1.0/3.0));
#endif
	// Fix rounding errors
    i0 = floor(i0 + 0.5);
    i1 = floor(i1 + 0.5);
    i2 = floor(i2 + 0.5);
    i3 = floor(i3 + 0.5);
  }

  // Compute one pseudo-random hash value for each corner
  float4 hash = permute2( permute2( permute2( 
              float4(i0.z, i1.z, i2.z, i3.z ))
            + float4(i0.y, i1.y, i2.y, i3.y ))
            + float4(i0.x, i1.x, i2.x, i3.x ));

  // Compute generating gradients from a Fibonacci spiral on the unit sphere
  float4 theta = hash * 3.883222077;  // 2*pi/golden ratio
  float4 sz    = hash * -0.006920415 + 0.996539792; // 1-(hash+0.5)*2/289
  float4 psi   = hash * 0.108705628 ; // 10*pi/289, chosen to avoid correlation

  float4 Ct = cos(theta);
  float4 St = sin(theta);
  float4 sz_prime = sqrt( 1.0 - sz*sz ); // s is a point on a unit fib-sphere

  float4 gx, gy, gz;

  // Rotate gradients by angle alpha around a pseudo-random ortogonal axis
#ifdef FASTROTATION
  // Fast algorithm, but without dynamic shortcut for alpha = 0
  float4 qx = St;         // q' = norm ( cross(s, n) )  on the equator
  float4 qy = -Ct; 
  float4 qz = float4(0.0, 0.0, 0.0, 0.0);

  float4 px =  sz * qy;   // p' = cross(q, s)
  float4 py = -sz * qx;
  float4 pz = sz_prime;

  psi += alpha;         // psi and alpha in the same plane
  float4 Sa = sin(psi);
  float4 Ca = cos(psi);

  gx = Ca * px + Sa * qx;
  gy = Ca * py + Sa * qy;
  gz = Ca * pz + Sa * qz;
#else
  // Slightly slower algorithm, but with g = s for alpha = 0, and a
  // strong conditional speedup for alpha = 0 across all fragments
  if(alpha != 0.0) {
    float4 Sp = sin(psi);          // q' from psi on equator
    float4 Cp = cos(psi);

    float4 px = Ct * sz_prime;     // px = sx
    float4 py = St * sz_prime;     // py = sy
    float4 pz = sz;

    float4 Ctp = St*Sp - Ct*Cp;    // q = (rotate( cross(s,n), dot(s,n))(q')
    float4 qx = lerp( Ctp*St, Sp, sz);
    float4 qy = lerp(-Ctp*Ct, Cp, sz);
    float4 qz = -(py*Cp + px*Sp);

    float sinalpha = sin(alpha);
    float cosalpha = cos(alpha);
    float4 Sa = float4(sinalpha, sinalpha, sinalpha, sinalpha);       // psi and alpha in different planes
    float4 Ca = float4(cosalpha, cosalpha, cosalpha, cosalpha);

    gx = Ca * px + Sa * qx;
    gy = Ca * py + Sa * qy;
    gz = Ca * pz + Sa * qz;
  }
  else {
    gx = Ct * sz_prime;  // alpha = 0, use s directly as gradient
    gy = St * sz_prime;
    gz = sz;  
  }
#endif

  // Reorganize for dot products below
  float3 g0 = float3(gx.x, gy.x, gz.x);
  float3 g1 = float3(gx.y, gy.y, gz.y);
  float3 g2 = float3(gx.z, gy.z, gz.z);
  float3 g3 = float3(gx.w, gy.w, gz.w);

  // Radial decay with distance from each simplex corner
  float4 w = 0.5 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3));
  w = max(w, 0.0);
  float4 w2 = w * w;
  float4 w3 = w2 * w;

  // The value of the linear ramp from each of the corners
  float4 gdotx = float4(dot(g0,x0), dot(g1,x1), dot(g2,x2), dot(g3,x3));

  // Multiply by the radial decay and sum up the noise value
  float n = dot(w3, gdotx);

  // Compute the first order partial derivatives
  float4 dw = -6.0 * w2 * gdotx;
  float3 dn0 = w3.x * g0 + dw.x * x0;
  float3 dn1 = w3.y * g1 + dw.y * x1;
  float3 dn2 = w3.z * g2 + dw.z * x2;
  float3 dn3 = w3.w * g3 + dw.w * x3;
  gradient = 39.5 * (dn0 + dn1 + dn2 + dn3);

  // Compute the second order partial derivatives
  float4 dw2 = 24.0 * w * gdotx;
  float3 dga0 = dw2.x * x0 * x0 - 6.0 * w2.x * (gdotx.x + 2.0 * g0 * x0);
  float3 dga1 = dw2.y * x1 * x1 - 6.0 * w2.y * (gdotx.y + 2.0 * g1 * x1);
  float3 dga2 = dw2.z * x2 * x2 - 6.0 * w2.z * (gdotx.z + 2.0 * g2 * x2);
  float3 dga3 = dw2.w * x3 * x3 - 6.0 * w2.w * (gdotx.w + 2.0 * g3 * x3);
  dg = 35.0 * (dga0 + dga1 + dga2 + dga3); // (d2n/dx2, d2n/dy2, d2n/dz2)
  float3 dgb0 = dw2.x * x0 * x0.yzx - 6.0 * w2.x * (g0 * x0.yzx + g0.yzx * x0);
  float3 dgb1 = dw2.y * x1 * x1.yzx - 6.0 * w2.y * (g1 * x1.yzx + g1.yzx * x1);
  float3 dgb2 = dw2.z * x2 * x2.yzx - 6.0 * w2.z * (g2 * x2.yzx + g2.yzx * x2);
  float3 dgb3 = dw2.w * x3 * x3.yzx - 6.0 * w2.w * (g3 * x3.yzx + g3.yzx * x3);
  dg2 = 39.5 * (dgb0 + dgb1 + dgb2 + dgb3); // (d2n/dxy, d2n/dyz, d2n/dxz)

  // Scale the return value to fit nicely into the range [-1,1]
  return 39.5 * n;
}

// Adapted to HLSL by Dom Portera, published under the MIT license
// https://github.com/domportera/hlsl-noise