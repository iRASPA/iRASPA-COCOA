/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

#include <metal_stdlib>
#include "Common.h"
using namespace metal;


LightingWeights accumulateLighting(constant LightUniforms& lightUniforms,
                                   float3 N,
                                   float3 V,
                                   float4 eyePosition,
                                   float materialShininess)
{
  return accumulateLighting(lightUniforms, N, V, eyePosition, materialShininess, 0xFFu);
}

uint shadowMaskAtFragment(texture2d<uint> shadowMask, float4 windowPosition)
{
  uint2 pixel = uint2(windowPosition.xy);
  // the fallback the renderer binds when shadows are off is a single texel, so clamping to the
  // texture rather than to the framebuffer reports every light lit at every pixel
  pixel = min(pixel, uint2(shadowMask.get_width() - 1, shadowMask.get_height() - 1));
  return shadowMask.read(pixel).r;
}

LightingWeights accumulateLighting(constant LightUniforms& lightUniforms,
                                   float3 N,
                                   float3 V,
                                   float4 eyePosition,
                                   float materialShininess,
                                   uint lightVisibility)
{
  LightingWeights weights;

  // ambient belongs to the scene, so it is set once here rather than summed over the lights
  weights.ambient = lightUniforms.sceneAmbient.xyz;
  weights.diffuse = float3(0.0);
  weights.specular = float3(0.0);

  for (int i = 0; i < NUMBER_OF_LIGHTS; i++)
  {
    if (lightUniforms.lights[i].enabled < 0.5)
    {
      continue;
    }

    // in shadow for this light: no direct light of any kind reaches the point
    if ((lightVisibility & (1u << uint(i))) == 0u)
    {
      continue;
    }

    // w selects the meaning of position: a direction for a directional light, a location otherwise
    float4 lightPosition = lightUniforms.lights[i].position;
    float3 toLight = (lightPosition - eyePosition * lightPosition.w).xyz;
    float distanceToLight = length(toLight);
    float3 L = (distanceToLight > 0.0) ? toLight / distanceToLight : float3(0.0, 0.0, 1.0);

    float attenuation = 1.0;
    if (lightPosition.w > 0.5)
    {
      attenuation = 1.0 / max(lightUniforms.lights[i].constantAttenuation +
                              lightUniforms.lights[i].linearAttenuation * distanceToLight +
                              lightUniforms.lights[i].quadraticAttenuation * distanceToLight * distanceToLight,
                              1.0e-4);

      if (lightUniforms.lights[i].lightType > 1.5) // spot
      {
        float3 spotAxis = normalize(lightUniforms.lights[i].spotDirection.xyz);
        float spotCosine = dot(-L, spotAxis);
        float cutoffCosine = cos((M_PI_F / 180.0) * clamp(lightUniforms.lights[i].spotCutoff, 0.0, 180.0));
        attenuation *= (spotCosine < cutoffCosine)
                           ? 0.0
                           : pow(spotCosine, max(lightUniforms.lights[i].spotExponent, 0.0));
      }
    }

    float3 R = reflect(-L, N);
    float specularFactor = pow(max(dot(R, V), 0.0), lightUniforms.lights[i].shininess + materialShininess);

    weights.diffuse += attenuation * max(dot(N, L), 0.0) * lightUniforms.lights[i].diffuse.xyz;
    weights.specular += attenuation * specularFactor * lightUniforms.lights[i].specular.xyz;
  }

  return weights;
}


// Modulo 289, optimizes to code without divisions
float mod289(float x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 289, optimizes to code without divisions
float2 mod289(float2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 289, optimizes to code without divisions
float3 mod289(float3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 289, optimizes to code without divisions
float4 mod289(float4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Permutation polynomial (ring size 289 = 17*17)
float permute(float x) {
  return mod289(((x*34.0)+1.0)*x);
}

float3 permute(float3 x) {
  return mod289(((x*34.0)+1.0)*x);
}


// Permutation polynomial (ring size 289 = 17*17)
float4 permute(float4 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float3 rgb2hsv(float3 c)
{
  float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
  float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
  
  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c)
{
  float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Slab method for ray-box intersection
float2 rayBoxIntersection(Ray ray, AABB box)
{
  float t_0=0.0;
  float t_1=0.0;
  float3 direction_inv = 1.0 / ray.direction;
  float3 t_top = direction_inv * (box.top - ray.origin);
  float3 t_bottom = direction_inv * (box.bottom - ray.origin);
  float3 t_min = min(t_top, t_bottom);
  float2 t = max(t_min.xx, t_min.yz);
  t_0 = max(0.0, max(t.x, t.y));
  float3 t_max = max(t_top, t_bottom);
  t = min(t_max.xx, t_max.yz);
  t_1 = min(t.x, t.y);
  return float2(t_0,t_1);
}


