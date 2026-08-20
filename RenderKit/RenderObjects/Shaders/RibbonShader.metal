/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
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


struct RibbonAODebugUniforms
{
  int mode;
  int textureWidth;
  int textureHeight;
  int patchNumber;
  float patchSize;
  float inverseTextureSize;
  int viewportWidth;
  int viewportHeight;
};


struct RibbonVertexShaderOut
{
  float4 position [[position]];
  float3 N;
  /// The direction to the eye, unnormalized, so that negating it recovers the eye-space position that
  /// the positional lights need.
  float3 V;
  float3 ambient;
  float3 diffuse;
  float3 specular;
  float2 aoUV;
  float3 baseColor;
};


static float3 ribbonColorForStructureType(float structureType, constant StructureUniforms& structureUniforms)
{
  if (structureType < 0.5)
  {
    return structureUniforms.ribbonCoilColor.xyz;
  }
  if (structureType < 1.5)
  {
    return structureUniforms.ribbonHelixColor.xyz;
  }
  return structureUniforms.ribbonSheetColor.xyz;
}


static float sampleRibbonAmbientOcclusion(texture2d<half> ambientOcclusionTexture,
                                          sampler ambientOcclusionSampler,
                                          float2 uv,
                                          float2 inverseTextureSize)
{
  float sum = 0.0;
  float weight = 0.0;
  for (int dy = -1; dy <= 1; dy++)
  {
    for (int dx = -1; dx <= 1; dx++)
    {
      float2 offset = float2(float(dx), float(dy)) * inverseTextureSize;
      float value = float(ambientOcclusionTexture.sample(ambientOcclusionSampler, uv + offset).r);
      float tapWeight = (dx == 0 && dy == 0) ? 2.0 : 1.0;
      sum += value * tapWeight;
      weight += tapWeight;
    }
  }
  return sum / max(weight, 1.0);
}


vertex RibbonVertexShaderOut RibbonVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                constant StructureUniforms& structureUniforms [[buffer(2)]],
                                                constant LightUniforms& lightUniforms [[buffer(3)]],
                                                uint vid [[vertex_id]])
{
  RibbonVertexShaderOut vert;
  
  float4 pos = vertices[vid].position;
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  float3 localNormal = vertices[vid].normal.xyz;
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * float4(localNormal, 0.0)).xyz;
  
  float3 baseColor = ribbonColorForStructureType(vertices[vid].pad.x, structureUniforms);
  vert.baseColor = baseColor;
  // the material colours only; the lights are summed in the fragment shader, where the normal is known
  vert.ambient = (structureUniforms.ribbonAmbientColor * float4(baseColor, 1.0)).xyz;
  vert.diffuse = (structureUniforms.ribbonDiffuseColor * float4(baseColor, 1.0)).xyz;
  vert.specular = structureUniforms.ribbonSpecularColor.xyz;
  vert.aoUV = vertices[vid].st;
  
  float4 P = frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  vert.V = -P.xyz;
  
  return vert;
}


fragment float4 RibbonFragmentShader(RibbonVertexShaderOut vert [[stage_in]],
                                     constant FrameUniforms& frameUniforms [[buffer(0)]],
                                     constant StructureUniforms& structureUniforms [[buffer(1)]],
                                     constant LightUniforms& lightUniforms [[buffer(2)]],
                                     constant RibbonAODebugUniforms& aoDebug [[buffer(3)]],
                                     texture2d<half> ambientOcclusionTexture [[texture(0)]],
                                     sampler ambientOcclusionSampler [[sampler(0)]],
                                     texture2d<uint> shadowMask [[texture(1)]])
{
  float2 inverseTextureSize = float2(1.0 / max(float(aoDebug.textureWidth), 1.0),
                                     1.0 / max(float(aoDebug.textureHeight), 1.0));
  float aoSample = 1.0;
  if (structureUniforms.ribbonAmbientOcclusion)
  {
    aoSample = sampleRibbonAmbientOcclusion(ambientOcclusionTexture,
                                            ambientOcclusionSampler,
                                            vert.aoUV,
                                            inverseTextureSize);
  }
  
  if (aoDebug.mode != 0)
  {
    if (aoDebug.mode == 1)
    {
      return float4(vert.aoUV.x, vert.aoUV.y, 0.0, 1.0);
    }
    if (aoDebug.mode == 2)
    {
      return float4(aoSample, aoSample, aoSample, 1.0);
    }
    if (aoDebug.mode == 3)
    {
      float2 texelCoord = vert.aoUV * float2(float(aoDebug.textureWidth), float(aoDebug.textureHeight));
      int2 checker = int2(floor(texelCoord));
      float c = float((checker.x + checker.y) & 1);
      return float4(c, c, c, 1.0);
    }
    if (aoDebug.mode == 4)
    {
      return float4(vert.baseColor, 1.0);
    }
    if (aoDebug.mode == 5)
    {
      float2 screenUV = vert.position.xy / float2(max(float(aoDebug.viewportWidth), 1.0),
                                             max(float(aoDebug.viewportHeight), 1.0));
      if (screenUV.y < 0.12)
      {
        float band = screenUV.x * 3.0;
        if (band < 1.0)
        {
          return float4(structureUniforms.ribbonCoilColor.xyz, 1.0);
        }
        if (band < 2.0)
        {
          return float4(structureUniforms.ribbonHelixColor.xyz, 1.0);
        }
        return float4(structureUniforms.ribbonSheetColor.xyz, 1.0);
      }
      return float4(vert.baseColor, 1.0);
    }
  }
  
  float3 N = normalize(vert.N);
  float3 V = normalize(vert.V);
  
  LightingWeights lighting = accumulateLighting(lightUniforms, N, V, float4(-vert.V, 1.0), structureUniforms.ribbonShininess,
                                                shadowMaskAtFragment(shadowMask, vert.position));
  
  float3 ambient = lighting.ambient * vert.ambient;
  float3 diffuse = lighting.diffuse * vert.diffuse;
  float3 specular = lighting.specular * vert.specular;
  
  float ao = 1.0;
  if (structureUniforms.ribbonAmbientOcclusion)
  {
    ao = aoSample;
  }
  
  // occlusion says how much of the environment the point can see, so physically it belongs on the
  // ambient term alone; the strength blends it back into the direct terms to recover the contrast of
  // the older "Fancy" look, which a camera light cannot otherwise produce since it casts no shadows
  float aoDirect = mix(1.0, ao, clamp(structureUniforms.ambientOcclusionStrength, 0.0, 1.0));
  float4 color = float4(ao * ambient + aoDirect * (diffuse + specular), 1.0);
  if (structureUniforms.ribbonHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.ribbonHDRExposure);
    vLdrColor.a = 1.0;
    color = vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.ribbonHue;
  hsv.y = hsv.y * structureUniforms.ribbonSaturation;
  hsv.z = hsv.z * structureUniforms.ribbonValue;
  return float4(hsv2rgb(hsv), 1.0);
}
