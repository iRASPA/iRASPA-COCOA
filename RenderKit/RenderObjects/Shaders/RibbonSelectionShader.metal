/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

#include <metal_stdlib>
#include "Common.h"
using namespace metal;


struct RibbonSelectionVertexShaderOut
{
  float4 position [[position]];
  float3 N;
  float3 L;
  float3 V;
  float3 Model_N;
  float3 ambient;
  float3 diffuse;
  float3 specular;
  float2 stripeST;
};


static float3 ribbonSelectionExpandedPosition(const device InPerVertex *vertices,
                                              uint vid,
                                              constant StructureUniforms& structureUniforms,
                                              float expansionScale)
{
  float3 localNormal = normalize(vertices[vid].normal.xyz);
  float expansion = (structureUniforms.atomSelectionScaling - 1.0) * expansionScale;
  return vertices[vid].position.xyz + localNormal * expansion;
}


static RibbonSelectionVertexShaderOut ribbonSelectionVertex(const device InPerVertex *vertices,
                                                            constant FrameUniforms& frameUniforms,
                                                            constant StructureUniforms& structureUniforms,
                                                            constant LightUniforms& lightUniforms,
                                                            uint vid,
                                                            float expansionScale)
{
  RibbonSelectionVertexShaderOut vert;
  
  float3 expandedPosition = ribbonSelectionExpandedPosition(vertices, vid, structureUniforms, expansionScale);
  float4 pos = float4(expandedPosition, 1.0);
  float3 localNormal = normalize(vertices[vid].normal.xyz);
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * float4(localNormal, 0.0)).xyz;
  vert.Model_N = localNormal;
  vert.stripeST = vertices[vid].stripeST;
  
  float3 baseColor = float3(1.0, 1.0, 0.0);
  vert.ambient = (lightUniforms.lights[0].ambient * structureUniforms.ribbonAmbientColor * float4(baseColor, 1.0)).xyz;
  vert.diffuse = (lightUniforms.lights[0].diffuse * structureUniforms.ribbonDiffuseColor * float4(baseColor, 1.0)).xyz;
  vert.specular = (lightUniforms.lights[0].specular * structureUniforms.ribbonSpecularColor).xyz;
  
  float4 P = frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  vert.L = (lightUniforms.lights[0].position - P * lightUniforms.lights[0].position.w).xyz;
  vert.V = -P.xyz;
  
  return vert;
}


vertex RibbonSelectionVertexShaderOut RibbonSelectionGlowVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                      constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                      constant StructureUniforms& structureUniforms [[buffer(2)]],
                                                                      constant LightUniforms& lightUniforms [[buffer(3)]],
                                                                      uint vid [[vertex_id]])
{
  return ribbonSelectionVertex(vertices, frameUniforms, structureUniforms, lightUniforms, vid, 0.2);
}


fragment float4 RibbonSelectionGlowFragmentShader(RibbonSelectionVertexShaderOut vert [[stage_in]],
                                                  constant StructureUniforms& structureUniforms [[buffer(0)]])
{
  return float4(structureUniforms.atomSelectionIntensity * (vert.ambient + vert.diffuse), 1.0);
}


vertex RibbonSelectionVertexShaderOut RibbonSelectionWorleyVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                        constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                        constant StructureUniforms& structureUniforms [[buffer(2)]],
                                                                        constant LightUniforms& lightUniforms [[buffer(3)]],
                                                                        uint vid [[vertex_id]])
{
  return ribbonSelectionVertex(vertices, frameUniforms, structureUniforms, lightUniforms, vid, 0.2);
}


fragment float4 RibbonSelectionWorleyFragmentShader(RibbonSelectionVertexShaderOut vert [[stage_in]],
                                                  constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                  constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                  constant LightUniforms& lightUniforms [[buffer(2)]])
{
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  float3 R = reflect(-L, N);
  
  float4 ambient = float4(vert.ambient, 1.0);
  float4 diffuse = max(dot(N, L), 0.0) * float4(vert.diffuse, 1.0);
  float4 specular = pow(max(dot(R, V), 0.0), lightUniforms.lights[0].shininess + structureUniforms.ribbonShininess) * float4(vert.specular, 1.0);
  
  float3 t1 = vert.Model_N;
  float frequency = structureUniforms.atomSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.atomSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency * float3(t1.x, t1.z, t1.y), jitter);
  float n = F.y - F.x;
  
  float4 color = n * (ambient + diffuse + specular);
  if (structureUniforms.ribbonHDR)
  {
    color = 1.0 - exp2(-color * structureUniforms.ribbonHDRExposure);
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.ribbonHue;
  hsv.y = hsv.y * structureUniforms.ribbonSaturation;
  hsv.z = hsv.z * structureUniforms.ribbonValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.atomSelectionIntensity;
  return float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
}


vertex RibbonSelectionVertexShaderOut RibbonSelectionStripedVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                         constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                         constant StructureUniforms& structureUniforms [[buffer(2)]],
                                                                         constant LightUniforms& lightUniforms [[buffer(3)]],
                                                                         uint vid [[vertex_id]])
{
  return ribbonSelectionVertex(vertices, frameUniforms, structureUniforms, lightUniforms, vid, 0.45);
}


fragment float4 RibbonSelectionStripedFragmentShader(RibbonSelectionVertexShaderOut vert [[stage_in]],
                                                   constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                   constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                   constant LightUniforms& lightUniforms [[buffer(2)]])
{
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float4 color = max(dot(N, L), 0.0) * float4(1.0, 1.0, 0.0, 1.0);
  
  float2 stripeST = vert.stripeST;
  float uDensity = structureUniforms.atomSelectionStripesDensity;
  float frequency = structureUniforms.atomSelectionStripesFrequency;
  
  // Soft rectangular band mask along the residue span and around the cross-section.
  float bandAlong = smoothstep(0.0, 0.06, stripeST.x) * smoothstep(0.0, 0.06, 1.0 - stripeST.x);
  float bandAround = smoothstep(0.0, 0.10, stripeST.y) * smoothstep(0.0, 0.10, 1.0 - stripeST.y);
  float bandMask = bandAlong * bandAround;
  if (bandMask < 0.01)
  {
    discard_fragment();
  }
  
  // Checkered rectangular stripes on the residue band (not spherical coordinates).
  float stripeU = fract(stripeST.x * frequency);
  float stripeV = fract(stripeST.y * frequency);
  bool inStripe = (stripeU < uDensity) != (stripeV < uDensity);
  if (!inStripe)
  {
    discard_fragment();
  }
  
  color *= bandMask;
  
  if (structureUniforms.ribbonHDR)
  {
    color = 1.0 - exp2(-color * structureUniforms.ribbonHDRExposure);
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.ribbonHue;
  hsv.y = hsv.y * structureUniforms.ribbonSaturation;
  hsv.z = hsv.z * structureUniforms.ribbonValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.atomSelectionIntensity;
  return float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
}
