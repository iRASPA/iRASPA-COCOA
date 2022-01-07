/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
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


vertex PrimitiveVertexShaderOut PrimitiveCylinderSelectionStripedVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 scale = structureUniforms.primitiveSelectionScaling * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;
  
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


fragment float4 PrimitiveCylinderSelectionStripedFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  //float2  st = float2(0.5 + 0.5 * atan2(t1.z, t1.x)/3.141592653589793, 0.5 - asin(t1.y)/3.141592653589793);
  float uDensity = structureUniforms.primitiveSelectionStripesDensity;
  float frequency = structureUniforms.primitiveSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  if (structureUniforms.primitiveFrontSideHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv), 1.0);
}

vertex PrimitiveVertexShaderOut PrimitiveEllipsoidSelectionStripedVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 scale = structureUniforms.primitiveSelectionScaling * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;
  
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


fragment float4 PrimitiveEllipsoidSelectionStripedFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
                                              constant StructureUniforms& structureUniforms [[buffer(0)]],
                                              constant FrameUniforms& frameUniforms [[buffer(1)]],
                                              constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  float3 t1 = vert.Model_N;
  
  
  float2 st = float2(0.5 + 0.5 * atan2(t1.z, t1.x)/3.141592653589793, 0.5 - asin(t1.y)/3.141592653589793);
  float uDensity = structureUniforms.primitiveSelectionStripesDensity;
  float frequency = structureUniforms.primitiveSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  if (structureUniforms.primitiveFrontSideHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv), 1.0);
}


vertex PrimitiveVertexShaderOut PrimitivePolygonalPrismSelectionStripedVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 scale = structureUniforms.primitiveSelectionScaling * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;
  
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


fragment float4 PrimitivePolygonalPrismSelectionStripedFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  float uDensity = structureUniforms.primitiveSelectionStripesDensity;
  float frequency = structureUniforms.primitiveSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  if (structureUniforms.primitiveFrontSideHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv), 1.0);
}



vertex PrimitiveVertexShaderOut PrimitiveEllipsoidSelectionWorleyNoise3DVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 scale = structureUniforms.primitiveSelectionScaling * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;
  
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


fragment float4 PrimitiveEllipsoidSelectionWorleyNoise3DFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  float4 ambient = structureUniforms.primitiveAmbientFrontSide;
  float4 diffuse = max(dot(N, L), 0.0) * structureUniforms.primitiveDiffuseFrontSide;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.primitiveShininessFrontSide) * structureUniforms.primitiveSpecularFrontSide;
  
  float3 t1 = vert.Model_N;
  
  float frequency = structureUniforms.primitiveSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.primitiveSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,t1.z,t1.y),jitter);
  float n = F.y-F.x;
  
  float4 color = n * float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.primitiveFrontSideHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv), 1.0);
}

vertex PrimitiveVertexShaderOut PrimitiveCylinderSelectionWorleyNoise3DVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 scale = structureUniforms.primitiveSelectionScaling * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;
  
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


fragment float4 PrimitiveCylinderSelectionWorleyNoise3DFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  float4 ambient = structureUniforms.primitiveAmbientFrontSide;
  float4 diffuse = max(dot(N, L), 0.0) * structureUniforms.primitiveDiffuseFrontSide;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.primitiveShininessFrontSide) * structureUniforms.primitiveSpecularFrontSide;
  
  float3 t1 = vert.Model_N;
  
  float frequency = structureUniforms.primitiveSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.primitiveSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,t1.z,t1.y),jitter);
  float n = F.y-F.x;
  
  float4 color = n * float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.primitiveFrontSideHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv), 1.0);
}

vertex PrimitiveVertexShaderOut PrimitivePolygonalPrismSelectionWorleyNoise3DVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 scale = structureUniforms.primitiveSelectionScaling * positions[iid].scale;
  float4 pos =  structureUniforms.transformationMatrix * (scale * vertices[vid].position) + positions[iid].position;
  
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


fragment float4 PrimitivePolygonalPrismSelectionWorleyNoise3DFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  float4 ambient = structureUniforms.primitiveAmbientFrontSide;
  float4 diffuse = max(dot(N, L), 0.0) * structureUniforms.primitiveDiffuseFrontSide;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.primitiveShininessFrontSide) * structureUniforms.primitiveSpecularFrontSide;
  
  float3 t1 = vert.Model_N;
  
  float frequency = structureUniforms.primitiveSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.primitiveSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,t1.z,t1.y),jitter);
  float n = F.y-F.x;
  
  float4 color = n * float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.primitiveFrontSideHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.primitiveFrontSideHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv), 1.0);
}


vertex PrimitiveVertexShaderOut PrimitiveEllipsoidSelectionGlowVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 pos = structureUniforms.transformationMatrix * vertices[vid].position + positions[iid].position;
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * structureUniforms.transformationNormalMatrix *   vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;

  return vert;
}




fragment float4 PrimitiveEllipsoidSelectionGlowFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv),1.0);
}

vertex PrimitiveVertexShaderOut PrimitiveCylinderSelectionGlowVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 pos = structureUniforms.transformationMatrix * vertices[vid].position + positions[iid].position;
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * structureUniforms.transformationNormalMatrix *   vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}




fragment float4 PrimitiveCylinderSelectionGlowFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv),1.0);
}

vertex PrimitiveVertexShaderOut PrimitivePolygonalPrismSelectionGlowVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PrimitiveVertexShaderOut vert;
  
  float4 pos = structureUniforms.transformationMatrix * vertices[vid].position + positions[iid].position;
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * structureUniforms.transformationNormalMatrix *   vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}




fragment float4 PrimitivePolygonalPrismSelectionGlowFragmentShader(PrimitiveVertexShaderOut vert [[stage_in]],
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
  hsv.x = hsv.x * structureUniforms.primitiveHue;
  hsv.y = hsv.y * structureUniforms.primitiveSaturation;
  hsv.z = hsv.z * structureUniforms.primitiveValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.primitiveSelectionIntensity;
  return bloomLevel * float4(hsv2rgb(hsv),1.0);
}
