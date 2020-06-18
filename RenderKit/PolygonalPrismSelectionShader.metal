/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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


vertex AtomSphereVertexShaderOut PolygonalPrismSelectionStripedVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  AtomSphereVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;

  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * structureUniforms.transformationNormalMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].position.xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}


fragment float4 PolygonalPrismSelectionStripedFragmentShader(AtomSphereVertexShaderOut vert [[stage_in]],
                                              constant StructureUniforms& structureUniforms [[buffer(0)]],
                                              constant FrameUniforms& frameUniforms [[buffer(1)]],
                                              constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  float3 t1 = vert.Model_N;
  
  
  float2 st = float2(0.5 + 0.5 * atan2(t1.x, t1.z)/3.141592653589793, t1.y);
  float uDensity = structureUniforms.atomSelectionStripesDensity;
  float frequency = structureUniforms.atomSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  if (structureUniforms.atomHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.atomHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.atomSelectionIntensity;
  return float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
}


vertex AtomSphereVertexShaderOut PolygonalPrismSelectionWorleyNoise3DVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  AtomSphereVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;

  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * structureUniforms.transformationNormalMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].position.xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}


fragment float4 PolygonalPrismSelectionWorleyNoise3DFragmentShader(AtomSphereVertexShaderOut vert [[stage_in]],
                                              constant StructureUniforms& structureUniforms [[buffer(0)]],
                                              constant FrameUniforms& frameUniforms [[buffer(1)]],
                                              constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float4 ambient = vert.ambient;
  float4 diffuse = max(dot(N, L), 0.0) * vert.diffuse;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.atomShininess) * vert.specular;
  
  float3 t1 = vert.Model_N;
  
  float frequency = structureUniforms.atomSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.atomSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,t1.z,t1.y),jitter);
  float n = F.y-F.x;
  
  float4 color = n * float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.atomHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.atomHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.atomSelectionIntensity;
  return float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
}


vertex AtomSphereVertexShaderOut PolygonalPrismSelectionGlowVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  AtomSphereVertexShaderOut vert;
  
  float4 pos = structureUniforms.transformationMatrix * vertices[vid].position + positions[iid].position;
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * structureUniforms.transformationNormalMatrix *   vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  uint patchNumber=structureUniforms.ambientOcclusionPatchNumber;
  vert.k1=iid%patchNumber;
  vert.k2=iid/patchNumber;
  
  return vert;
}




fragment float4 PolygonalPrismSelectionGlowFragmentShader(AtomSphereVertexShaderOut vert [[stage_in]],
                                              constant StructureUniforms& structureUniforms [[buffer(0)]],
                                              constant FrameUniforms& frameUniforms [[buffer(1)]],
                                              constant LightUniforms& lightUniforms [[buffer(2)]],
                                              texture2d<half>  ambientOcclusionTexture     [[ texture(0) ]],
                                              sampler           shadowMapSampler [[ sampler(0) ]],
                                              bool frontfacing [[ front_facing ]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  float4 ambient;
  float4 diffuse;
  float4 specular;
  float4 color;
  
  if (!frontfacing)
  {
    float3 R = reflect(-L, -N);
    ambient = structureUniforms.primitiveAmbientBackSide;
    diffuse = max(dot(-N, L), 0.0) * structureUniforms.primitiveDiffuseBackSide;
    specular = pow(max(dot(R, V), 0.0), structureUniforms.primitiveShininessBackSide) * structureUniforms.primitiveSpecularBackSide;
    
    color = float4((ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
    if (structureUniforms.primitiveBackSideHDR)
    {
      float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveBackSideHDRExposure);
      vLdrColor.a = 1.0;
      color = vLdrColor;
    }
  }
  else
  {
    float3 R = reflect(-L, N);
    ambient = structureUniforms.primitiveAmbientFrontSide;
    diffuse = max(dot(N, L), 0.0) * structureUniforms.primitiveDiffuseFrontSide;
    specular = pow(max(dot(R, V), 0.0), structureUniforms.primitiveShininessFrontSide) * structureUniforms.primitiveSpecularFrontSide;
    
    color= float4((ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
    if (structureUniforms.primitiveFrontSideHDR)
    {
      float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
      vLdrColor.a = 1.0;
      color = vLdrColor;
    }
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  return float4(hsv2rgb(hsv) * structureUniforms.primitiveDiffuseFrontSide.w,structureUniforms.primitiveDiffuseFrontSide.w);
}
