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

// works for both orthogonal and perspective
float frontFacing(float4 pos0, float4 pos1, float4 pos2)
{
  return pos0.x*pos1.y - pos1.x*pos0.y + pos1.x*pos2.y - pos2.x*pos1.y + pos2.x*pos0.y - pos0.x*pos2.y;
}

struct InternalBondVertexShaderOut
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 mix;
  float4 ambient;
  float4 specular;
  float3 N;
  float3 L;
  float3 V;
};


vertex InternalBondVertexShaderOut BondCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  InternalBondVertexShaderOut vert;
  
  float4 scale = positions[iid].scale;
  float4 pos =  vertices[vid].position;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  float3 dr = (pos2 - pos1).xyz;
  float bondLength = length(dr);
  
  vert.mix.x = clamp(structureUniforms.atomScaleFactor,0.0,3.7) * scale.x;
  vert.mix.y = vertices[vid].position.y;  // range 0.0..1.0
  vert.mix.z = 1.0 - clamp(structureUniforms.atomScaleFactor,0.0,3.7) * scale.z;
  vert.mix.w = scale.x/scale.z;
  
  
  scale.x = structureUniforms.bondScaling;
  scale.y = bondLength;
  scale.z = structureUniforms.bondScaling;
  scale.w = 1.0;
  
  dr = normalize(dr);
  v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  v2 = normalize(cross(dr,v1));
  
  float4x4 orientationMatrix=float4x4(float4(v2.x,v2.y,v2.z,0),
                                      float4(dr.x,dr.y,dr.z,0),
                                      float4(v1.x,v1.y,v1.z,0),
                                      float4(0,0,0,1));
  
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor* positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
   
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * orientationMatrix * vertices[vid].normal).xyz;
  
  
  float4 P =  frameUniforms.viewMatrix *  structureUniforms.modelMatrix * float4((orientationMatrix * (scale * pos) + pos1).xyz,1.0);
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix *  structureUniforms.modelMatrix * (orientationMatrix * (scale * pos) + pos1);
  
  return vert;
}



fragment float4 BondCylinderFragmentShader(InternalBondVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant LightUniforms& lightUniforms [[buffer(1)]])
{
  // Normalize the incoming N and L vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  //float t = clamp((vert.mix.y - vert.mix.x)/(vert.mix.z - vert.mix.x), 0.0, 1.0);
  float t = vert.mix.y;

  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (t < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,t));
      break;
  }
  
  float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  return float4(hsv2rgb(hsv),1.0);
}


struct ExternalBondVertexShaderOut
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 mix;
  
  float4 ambient;
  float4 specular;
  float3 N;
  float3 L;
  float3 V;
  
  float clipDistance0 [[ center_perspective ]];
  float clipDistance1 [[ center_perspective ]];
  float clipDistance2 [[ center_perspective ]];
  float clipDistance3 [[ center_perspective ]];
  float clipDistance4 [[ center_perspective ]];
  float clipDistance5 [[ center_perspective ]];
};

vertex ExternalBondVertexShaderOut ExternalBondCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  ExternalBondVertexShaderOut vert;
  
  float4 scale = positions[iid].scale;
  float4 pos =  vertices[vid].position;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  float3 dr = (pos1 - pos2).xyz;
  float bondLength = length(dr);
  
  vert.mix.x = clamp(structureUniforms.atomScaleFactor,0.0,0.7) * scale.x;
  vert.mix.y = vertices[vid].position.y;  // range 0.0..1.0
  vert.mix.z = 1.0 - clamp(structureUniforms.atomScaleFactor,0.0,0.7) * scale.z;
  vert.mix.w = scale.x/scale.z;
  
  
  scale.x = structureUniforms.bondScaling;
  scale.y = bondLength;
  scale.z = structureUniforms.bondScaling;
  scale.w = 1.0;
  
  dr = normalize(dr);
  v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  //if ((dr.z !=0 ) && (-dr.x != dr.y ))
  //  v1=normalize(float3(-dr.y-dr.z,dr.x,dr.x));
  //else
  //  v1=normalize(float3(dr.z,dr.z,-dr.x-dr.y));
  v2 = normalize(cross(dr,v1));
  
  
  float4x4 orientationMatrix=float4x4(float4(-v1.x,-v1.y,-v1.z,0),
                                      float4(-dr.x,-dr.y,-dr.z,0),
                                      float4(-v2.x,-v2.y,-v2.z,0),
                                      float4(0,0,0,1));
  
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor* positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
    
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * orientationMatrix * vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix *  structureUniforms.modelMatrix * float4((orientationMatrix * (scale * pos) + pos1).xyz,1.0);
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  float4 vertexPos =  (orientationMatrix * (scale * pos) + pos1);

  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * vertexPos;
  
  vert.clipDistance0 = dot(structureUniforms.clipPlaneLeft,vertexPos);
  vert.clipDistance1 = dot(structureUniforms.clipPlaneRight,vertexPos);
  vert.clipDistance2 = dot(structureUniforms.clipPlaneTop,vertexPos);
  
  vert.clipDistance3 = dot(structureUniforms.clipPlaneBottom,vertexPos);
  vert.clipDistance4 = dot(structureUniforms.clipPlaneFront,vertexPos);
  vert.clipDistance5 = dot(structureUniforms.clipPlaneBack,vertexPos);
  
  return vert;
}

fragment float4 ExternalBondCylinderFragmentShader(ExternalBondVertexShaderOut vert [[stage_in]],
                                                   constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                   constant LightUniforms& lightUniforms [[buffer(1)]])
{
  // Normalize the incoming N and L vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  //float t = clamp((vert.mix.y - vert.mix.x)/(vert.mix.z - vert.mix.x),0.0,1.0);
  float t = vert.mix.y;
  
  // [[ clip_distance ]] appears to working only for two clipping planes
  // work-around: brute-force 'discard_fragment'
  if (vert.clipDistance0 < 0.0) discard_fragment();
  if (vert.clipDistance1 < 0.0) discard_fragment();
  if (vert.clipDistance2 < 0.0) discard_fragment();
  if (vert.clipDistance3 < 0.0) discard_fragment();
  if (vert.clipDistance4 < 0.0) discard_fragment();
  if (vert.clipDistance5 < 0.0) discard_fragment();
  
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (t < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,t));
      break;
  }
  
  float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  return float4(hsv2rgb(hsv),1.0);
}


struct StencilExternalBondVertexShaderOut
{
  float4 position [[position]];
  
  float clipDistance0 [[ center_perspective ]];
  float clipDistance1 [[ center_perspective ]];
  float clipDistance2 [[ center_perspective ]];
  float clipDistance3 [[ center_perspective ]];
  float clipDistance4 [[ center_perspective ]];
  float clipDistance5 [[ center_perspective ]];
};


vertex StencilExternalBondVertexShaderOut StencilExternalBondCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                           const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                                           constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                           constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                           constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                           uint vid [[vertex_id]],
                                                                           uint iid [[instance_id]])
{
  float3 v1,v2;
  StencilExternalBondVertexShaderOut vert;
  
  float4 scale = positions[iid].scale;
  float4 pos =  vertices[vid].position;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  float3 dr = (pos1 - pos2).xyz;
  float bondLength = length(dr);
  
  scale.x = structureUniforms.bondScaling;
  scale.y = bondLength;
  scale.z = structureUniforms.bondScaling;
  scale.w = 1.0;
  
  dr = normalize(dr);
  v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  v2 = normalize(cross(dr,v1));
   
  float4x4 orientationMatrix=float4x4(float4(-v1.x,-v1.y,-v1.z,0),
                                      float4(-dr.x,-dr.y,-dr.z,0),
                                      float4(-v2.x,-v2.y,-v2.z,0),
                                      float4(0,0,0,1));
  
  float4 vertexPos =  (orientationMatrix * (scale * pos) + pos1);
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * vertexPos;
  
  // compute 3 reference points to determine front- or backfacing
  float4x4 matrix = frameUniforms.mvpMatrix *  structureUniforms.modelMatrix * structureUniforms.boxMatrix;
  float4 boxPosition0 = matrix * float4(0.0, 0.0, 0.0, 1.0);
  float4 boxPosition1 = matrix * float4(1.0, 0.0, 0.0, 1.0);
  float4 boxPosition2 = matrix * float4(1.0, 1.0, 0.0, 1.0);
  float4 boxPosition3 = matrix * float4(0.0, 1.0, 0.0, 1.0);
  float4 boxPosition4 = matrix * float4(0.0, 0.0, 1.0, 1.0);
  float4 boxPosition5 = matrix * float4(1.0, 0.0, 1.0, 1.0);
  float4 boxPosition6 = matrix * float4(1.0, 1.0, 1.0, 1.0);
  float4 boxPosition7 = matrix * float4(0.0, 1.0, 1.0, 1.0);
  
  
  // perspective division
  boxPosition0 = boxPosition0/boxPosition0.w;
  boxPosition1 = boxPosition1/boxPosition1.w;
  boxPosition2 = boxPosition2/boxPosition2.w;
  boxPosition3 = boxPosition3/boxPosition3.w;
  boxPosition4 = boxPosition4/boxPosition4.w;
  boxPosition5 = boxPosition5/boxPosition5.w;
  boxPosition6 = boxPosition6/boxPosition6.w;
  boxPosition7 = boxPosition7/boxPosition7.w;
  
  float leftFrontfacing = frontFacing(boxPosition0, boxPosition3, boxPosition7);
  float rightFrontfacing = frontFacing(boxPosition1, boxPosition5, boxPosition2);
  
  float topFrontFacing = frontFacing(boxPosition3, boxPosition2, boxPosition7);
  float bottomFrontFacing = frontFacing(boxPosition0, boxPosition4, boxPosition1);
  
  float frontFrontFacing = frontFacing(boxPosition4, boxPosition6, boxPosition5);
  float backFrontFacing = frontFacing(boxPosition0, boxPosition1, boxPosition2);
  
  
  vert.clipDistance0 = (leftFrontfacing<0.0) ? dot(structureUniforms.clipPlaneLeft,vertexPos) : 0.0;
  vert.clipDistance1 = (rightFrontfacing<0.0) ? dot(structureUniforms.clipPlaneRight,vertexPos) : 0.0;
  
  vert.clipDistance2 = (topFrontFacing<0.0) ? dot(structureUniforms.clipPlaneTop,vertexPos) : 0.0;
  vert.clipDistance3 = (bottomFrontFacing<0.0) ? dot(structureUniforms.clipPlaneBottom,vertexPos) : 0.0;
  
  vert.clipDistance4 = (frontFrontFacing<0.0) ? dot(structureUniforms.clipPlaneFront,vertexPos) : 0.0;
  vert.clipDistance5 = (backFrontFacing<0.0) ? dot(structureUniforms.clipPlaneBack,vertexPos) : 0.0;
  
  return vert;
}



fragment float4 StencilExternalBondCylinderFragmentShader(StencilExternalBondVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant LightUniforms& lightUniforms [[buffer(1)]])

{
   // [[ clip_distance ]] appears to working only for two clipping planes
  // work-around: brute-force 'discard_fragment'
  if (vert.clipDistance0 < 0.0) discard_fragment();
  if (vert.clipDistance1 < 0.0) discard_fragment();
  if (vert.clipDistance2 < 0.0) discard_fragment();
  if (vert.clipDistance3 < 0.0) discard_fragment();
  if (vert.clipDistance4 < 0.0) discard_fragment();
  if (vert.clipDistance5 < 0.0) discard_fragment();
  
  // any color-write will do
  return float4(1.0,1.0,1.0,1);
}



// Inputs from vertex shader
struct BoxVertexOut
{
  float4 position [[position]];
  float4 ambient;
  float4 diffuse;
  float4 specular;

  float3 N;
  float3 L;
  float3 V;
};

vertex BoxVertexOut boxVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                    constant FrameUniforms& frameUniforms [[buffer(1)]],
                                    constant StructureUniforms& structureUniforms [[buffer(2)]],
                                    constant LightUniforms& lightUniforms [[buffer(3)]],
                                    uint vid [[vertex_id]],
                                    uint iid [[instance_id]])
{
  BoxVertexOut vert;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  
  
  // Calculate normal in view-space
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * vertices[vid].normal).xyz;
  
  float4 P = frameUniforms.viewMatrix * structureUniforms.modelMatrix * structureUniforms.boxMatrix * vertices[vid].position;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.projectionMatrix * P;
  
  return vert;
}

fragment float4 boxFragmentShader(BoxVertexOut vert [[stage_in]],
                                  constant StructureUniforms& structureUniforms [[buffer(0)]],
                                  constant LightUniforms& lightUniforms [[buffer(1)]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  //float3 V = normalize(vert.V);
  
  // Calculate R locally
  //float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  //float4 specular = pow(max(dot(R, V), 0.0), lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0) * vert.diffuse;

  
  // Compute the diffuse and specular components for each fragment
  float4 color= float4(ambient.xyz + diffuse.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  return float4(hsv2rgb(hsv),1.0);
}


// MARK: Bond cylinder imposters
// =============================================================================
// Ray-traced cylinder imposters (ported from the RibbonRendering cylinder
// imposter shaders). Each (sub-)cylinder is drawn as a view-aligned hull of
// three quads (18 vertices, generated from the vertex-id without any vertex
// buffer): a quad at each end-cap plane and a quad on the camera-facing
// tangent plane. The fragment shader ray-traces the analytic capped cylinder
// in eye space and outputs the exact surface depth. Works for both
// orthographic and perspective cameras.

constant float3 bondImposterHullOffsets[18] =
{
  // cap quad at endpoint A
  float3(-1.0, -1.0, -1.0),
  float3( 1.0, -1.0, -1.0),
  float3(-1.0, -1.0,  1.0),
  float3( 1.0, -1.0,  1.0),
  float3(-1.0, -1.0,  1.0),
  float3( 1.0, -1.0, -1.0),
  // camera-facing quad
  float3(-1.0, -1.0,  1.0),
  float3( 1.0, -1.0,  1.0),
  float3(-1.0,  1.0,  1.0),
  float3( 1.0,  1.0,  1.0),
  float3(-1.0,  1.0,  1.0),
  float3( 1.0, -1.0,  1.0),
  // cap quad at endpoint B
  float3(-1.0,  1.0,  1.0),
  float3( 1.0,  1.0,  1.0),
  float3(-1.0,  1.0, -1.0),
  float3( 1.0,  1.0, -1.0),
  float3(-1.0,  1.0, -1.0),
  float3( 1.0,  1.0,  1.0)
};

struct BondCylinderImposterVertexShaderOut
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 ambient [[ flat ]];
  float4 specular [[ flat ]];
  float3 frag_pos;
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
};

// displacement (in model x,z of the cylinder) of the sub-cylinders of double/triple bonds,
// matching MetalCappedDouble/TripleBondCylinderGeometry
static float2 bondImposterSubCylinderOffset(int type, uint sub, thread float &radiusFactor)
{
  radiusFactor = 1.0;
  float2 offset = float2(0.0, 0.0);
  if (type == 1)  // double bond
  {
    radiusFactor = 0.8;
    offset = float2((sub == 0) ? -1.0 : 1.0, 0.0);
  }
  else if (type == 3)  // triple bond
  {
    radiusFactor = 0.8;
    const float dz = 0.5 * sqrt(3.0);
    offset = (sub == 0) ? float2(-1.0, -dz) : ((sub == 1) ? float2(1.0, -dz) : float2(0.0, dz));
  }
  return offset;
}

// builds the hull vertex position in eye space for a cylinder from a to b
static float3 bondImposterHullPosition(float3 a, float3 b, float radius, uint vid, bool orthographic)
{
  float3 vHalf = 0.5 * (b - a);
  float3 center = a + vHalf;
  
  // direction from the camera towards the bond
  float3 e = orthographic ? float3(0.0, 0.0, -1.0) : center;
  
  float3 u = cross(vHalf, e);
  if (dot(u, u) < 1.0e-8) u = cross(vHalf, float3(0.0, 1.0, 0.0));
  if (dot(u, u) < 1.0e-8) u = cross(vHalf, float3(1.0, 0.0, 0.0));
  u = normalize(u);
  float3 w = normalize(cross(u, normalize(vHalf)));
  if (dot(w, e) > 0.0) w = -w;  // make w point towards the camera
  
  float3 coords = bondImposterHullOffsets[vid % 18];
  return center + radius * (coords.x * u + coords.z * w) + coords.y * vHalf;
}

// ray-traces a capped cylinder from a to b; returns the ray parameter t (or a negative
// value when there is no intersection) and sets the surface normal and the fraction
// ct (0 at a, 1 at b) along the axis
static float bondImposterIntersect(float3 ro, float3 rd, float3 a, float3 b, float r,
                                   thread float3 &N, thread float &ct)
{
  float3 ba = b - a;
  float3 oc = ro - a;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - r * r * baba;
  float h = k1 * k1 - k2 * k0;
  if (h < 0.0) return -1.0;
  h = sqrt(h);
  float t = (-k1 - h) / k2;
  
  // body of the cylinder
  float y = baoc + t * bard;
  if (y > 0.0 && y < baba)
  {
    N = (oc + t * rd - ba * y / baba) / r;
    ct = y / baba;
    return t;
  }
  
  // flat end-caps
  t = (((y < 0.0) ? 0.0 : baba) - baoc) / bard;
  if (abs(k1 + k2 * t) >= h) return -1.0;
  N = ba * sign(y) / sqrt(baba);
  ct = (y < 0.0) ? 0.0 : 1.0;
  return t;
}

// ray-traces the capped cylinder from a to b clipped by the six unit-cell planes,
// analytically generating the flat caps at the cell boundary (this replaces the
// stencil-based cap pass of the triangle-mesh path). The visible solid is an
// intersection of convex constraints (infinite cylinder, axis slab, six half-spaces),
// so the entry point is simply the largest of all entry parameters and the exit
// point the smallest of all exit parameters. The ray is traced in eye space;
// toStructure transforms eye-space points to the structure space of the clip planes.
// Returns the ray parameter t (negative when there is no intersection) and sets the
// eye-space surface normal and the fraction ct (0 at a, 1 at b) along the axis.
static float bondImposterClippedIntersect(float3 ro, float3 rd, float3 a, float3 b, float r,
                                          float4x4 toStructure,
                                          constant StructureUniforms& structureUniforms,
                                          thread float3 &N, thread float &ct)
{
  float3 ba = b - a;
  float3 oc = ro - a;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - r * r * baba;

  float tmin = -1.0e30;
  float tmax = 1.0e30;

  // -1: undetermined, 0: cylinder mantle, 1: end-cap, 2..7: clip plane
  int entryType = -1;

  // infinite cylinder around the axis
  if (k2 > 1.0e-6 * baba)
  {
    float h = k1 * k1 - k2 * k0;
    if (h < 0.0) return -1.0;
    h = sqrt(h);
    tmin = (-k1 - h) / k2;
    tmax = (-k1 + h) / k2;
    entryType = 0;
  }
  else if (k0 > 0.0)
  {
    // ray (nearly) parallel to the axis and outside the cylinder
    return -1.0;
  }

  // slab between the two end-cap planes: 0 <= baoc + t * bard <= baba
  if (abs(bard) > 1.0e-6)
  {
    float tCapA = (0.0 - baoc) / bard;
    float tCapB = (baba - baoc) / bard;
    float tEnter = min(tCapA, tCapB);
    float tExit = max(tCapA, tCapB);
    if (tEnter > tmin) { tmin = tEnter; entryType = 1; }
    tmax = min(tmax, tExit);
  }
  else if (baoc < 0.0 || baoc > baba)
  {
    return -1.0;
  }

  // the six clip planes of the unit cell (in structure space)
  float4 planes[6] = { structureUniforms.clipPlaneLeft, structureUniforms.clipPlaneRight,
                       structureUniforms.clipPlaneTop, structureUniforms.clipPlaneBottom,
                       structureUniforms.clipPlaneFront, structureUniforms.clipPlaneBack };
  float4 so = toStructure * float4(ro, 1.0);
  float4 sd = toStructure * float4(rd, 0.0);
  for (int i = 0; i < 6; i++)
  {
    float f0 = dot(planes[i], so);
    float df = dot(planes[i], sd);
    if (abs(df) < 1.0e-8)
    {
      if (f0 < 0.0) return -1.0;
    }
    else
    {
      float tp = -f0 / df;
      if (df > 0.0)
      {
        if (tp > tmin) { tmin = tp; entryType = 2 + i; }
      }
      else
      {
        tmax = min(tmax, tp);
      }
    }
  }

  if (tmax < tmin || tmin < 0.0 || entryType < 0) return -1.0;

  float t = tmin;
  float y = baoc + t * bard;
  ct = clamp(y / baba, 0.0, 1.0);

  if (entryType == 0)
  {
    N = (oc + t * rd - ba * y / baba) / r;
  }
  else if (entryType == 1)
  {
    N = (y < 0.5 * baba) ? -ba / sqrt(baba) : ba / sqrt(baba);
  }
  else
  {
    // clipped flat cap: the outward normal is opposite to the plane's inward
    // gradient; planes transform as covectors from structure to eye space
    float4 planeEye = transpose(toStructure) * planes[entryType - 2];
    N = -normalize(planeEye.xyz);
  }
  return t;
}

vertex BondCylinderImposterVertexShaderOut BondCylinderImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondCylinderImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos2 - pos1).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to v2, model z-axis maps to v1 (matches the orientationMatrix of BondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * v2 + offset.y * v1);
  float radius = structureUniforms.bondScaling * radiusFactor;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

fragment FragOutput BondCylinderImposterFragmentShader(BondCylinderImposterVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant LightUniforms& lightUniforms [[buffer(1)]],
                                           constant FrameUniforms& frameUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float3 V = normalize(-pos);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  output.albedo = float4(hsv2rgb(hsv),1.0);
  
  return output;
}


vertex BondCylinderImposterVertexShaderOut ExternalBondCylinderImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondCylinderImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos1 - pos2).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to -v1, model z-axis maps to -v2 (matches the orientationMatrix of ExternalBondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * (-v1) + offset.y * (-v2));
  float radius = structureUniforms.bondScaling * radiusFactor;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

fragment FragOutput ExternalBondCylinderImposterFragmentShader(BondCylinderImposterVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant LightUniforms& lightUniforms [[buffer(1)]],
                                           constant FrameUniforms& frameUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  // ray-trace the capped cylinder clipped at the unit cell; the flat caps at the
  // cell boundary are generated analytically (no stencil pass needed)
  float4x4 toStructure = structureUniforms.inverseModelMatrix * frameUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float3 V = normalize(-pos);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  output.albedo = float4(hsv2rgb(hsv),1.0);
  
  return output;
}
