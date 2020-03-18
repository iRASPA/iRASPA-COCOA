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
  float t = clamp((vert.mix.y - vert.mix.x)/(vert.mix.z - vert.mix.x),0.0,1.0);

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
  float t = clamp((vert.mix.y - vert.mix.x)/(vert.mix.z - vert.mix.x),0.0,1.0);
  
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

// Mark: Licorice
// ===============

struct LicoriceSphereVertexShaderOut
{
  float4 position [[position]];
  float4 ambient [[ flat ]];
  float4 diffuse [[ flat ]];
  float4 specular [[ flat ]];
  
  float3 N;
  float3 Model_N;
  float3 L;
  float3 V;
  float k1 [[ flat ]];    // must be float on ATI-cards  (int does not work)
  float k2 [[ flat ]];
  float4 ambientOcclusionTransformMatrix1 [[ flat ]];
  float4 ambientOcclusionTransformMatrix2 [[ flat ]];
  float4 ambientOcclusionTransformMatrix3 [[ flat ]];
  float4 ambientOcclusionTransformMatrix4 [[ flat ]];
  
  float clipDistance0 [[ center_perspective ]];
  float clipDistance1 [[ center_perspective ]];
  float clipDistance2 [[ center_perspective ]];
  float clipDistance3 [[ center_perspective ]];
  float clipDistance4 [[ center_perspective ]];
  float clipDistance5 [[ center_perspective ]];
};


vertex LicoriceSphereVertexShaderOut LicoriceSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                        const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                        constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                        constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                        constant LightUniforms& lightUniforms [[buffer(4)]],
                                                        uint vid [[vertex_id]],
                                                        uint iid [[instance_id]])
{
  LicoriceSphereVertexShaderOut vert;
  
  float4 scale = float4(structureUniforms.bondScaling,structureUniforms.bondScaling,structureUniforms.bondScaling,1.0);
  float4 pos =  scale * vertices[vid].position + positions[iid].position;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
  }
  else
  {
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  }
  
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].normal.xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  
  float4 vertexPos =  pos;
  
  if(structureUniforms.clipBondsAtUnitCell)
  {
    vert.clipDistance0 = dot(structureUniforms.clipPlaneLeft,vertexPos);
    vert.clipDistance1 = dot(structureUniforms.clipPlaneRight,vertexPos);
    vert.clipDistance2 = dot(structureUniforms.clipPlaneTop,vertexPos);
  
    vert.clipDistance3 = dot(structureUniforms.clipPlaneBottom,vertexPos);
    vert.clipDistance4 = dot(structureUniforms.clipPlaneFront,vertexPos);
    vert.clipDistance5 = dot(structureUniforms.clipPlaneBack,vertexPos);
  }
  return vert;
}


fragment float4 LicoriceSphereFragmentShader(LicoriceSphereVertexShaderOut vert [[stage_in]],
                                         constant StructureUniforms& structureUniforms [[buffer(0)]],
                                         constant FrameUniforms& frameUniforms [[buffer(1)]],
                                         constant LightUniforms& lightUniforms [[buffer(2)]])
{
  if(structureUniforms.clipBondsAtUnitCell)
  {
    // [[ clip_distance ]] appears to working only for two clipping planes
    // work-around: brute-force 'discard_fragment'
    if (vert.clipDistance0 < 0.0) discard_fragment();
    if (vert.clipDistance1 < 0.0) discard_fragment();
    if (vert.clipDistance2 < 0.0) discard_fragment();
    if (vert.clipDistance3 < 0.0) discard_fragment();
    if (vert.clipDistance4 < 0.0) discard_fragment();
    if (vert.clipDistance5 < 0.0) discard_fragment();
  }
  
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float4 ambient = vert.ambient;
  float4 diffuse = max(dot(N, L), 0.0) * vert.diffuse;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  
  
  float4 color = ambient + diffuse + specular;
  
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


// Mark: Sphere-imposter orthographic





vertex AtomSphereImposterVertexShaderOut LicoriceSphereImposterOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                    const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                    constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                    constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                    constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                    uint vid [[vertex_id]],
                                                                                    uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = float4(structureUniforms.bondScaling,structureUniforms.bondScaling,structureUniforms.bondScaling,1.0);
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
  }
  else
  {
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  }
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  vert.N = float3(0,0,1);
  float4x4 ambientOcclusionTransformMatrix = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.ambientOcclusionTransformMatrix1 = ambientOcclusionTransformMatrix[0];
  vert.ambientOcclusionTransformMatrix2 = ambientOcclusionTransformMatrix[1];
  vert.ambientOcclusionTransformMatrix3 = ambientOcclusionTransformMatrix[2];
  vert.ambientOcclusionTransformMatrix4 = ambientOcclusionTransformMatrix[3];
  vert.instancePosition = positions[iid].position;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - vert.eye_position*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -vert.eye_position.xyz;
  
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  pos2.xy += scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  
  vert.frag_pos = pos2.xyz;
  
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}


fragment FragOutput LicoriceSphereImposterOrthographicFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                 constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                 constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                                 constant LightUniforms& lightUniforms [[buffer(2)]],
                                                                 texture2d<half>  ambientOcclusionTexture     [[ texture(0) ]],
                                                                 sampler          ambientOcclusionSampler [[ sampler(0) ]])
{
  FragOutput output;
  
  float x = vert.texcoords.x;
  float y = vert.texcoords.y;
  float zz = 1.0 - x*x - y*y;
  
  if (zz <= 0.0)
    discard_fragment();
  float z = sqrt(zz);
  
  
  
  float4 pos = vert.eye_position;
  pos.z += vert.sphere_radius.z*z;
  
  if(structureUniforms.clipBondsAtUnitCell)
  {
    float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
    float4 vertexPosition =  ambientOcclusionTransformMatrix * (vert.sphere_radius * float4(x,y,z,1.0));
    float4 position = float4(vert.instancePosition.xyz + vertexPosition.xyz,1.0);
    if (dot(structureUniforms.clipPlaneLeft,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneRight,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneTop,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneBottom,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneFront,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneBack,position)< 0.0) discard_fragment();
  }
  
  pos = frameUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  
  
  // Normalize the incoming N, L and V vectors
  float3 N = float3(x,y,z);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float4 ambient = vert.ambient;
  float4 diffuse = max(dot(N, L), 0.0) * vert.diffuse;
  float4 specular = pow(max(dot(R, V), 0.0), lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  
  float4 color = ambient + diffuse + specular;
  
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


// Mark: Sphere-imposter perspective

vertex AtomSphereImposterVertexShaderOut LicoriceSphereImposterPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                   const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                   constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                   constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                   constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                   uint vid [[vertex_id]],
                                                                                   uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = float4(structureUniforms.bondScaling,structureUniforms.bondScaling,structureUniforms.bondScaling,1.0);
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
  }
  else
  {
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  }
  
  vert.N = float3(0,0,1);
  float4x4 ambientOcclusionTransformMatrix = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.ambientOcclusionTransformMatrix1 = ambientOcclusionTransformMatrix[0];
  vert.ambientOcclusionTransformMatrix2 = ambientOcclusionTransformMatrix[1];
  vert.ambientOcclusionTransformMatrix3 = ambientOcclusionTransformMatrix[2];
  vert.ambientOcclusionTransformMatrix4 = ambientOcclusionTransformMatrix[3];
  vert.instancePosition = positions[iid].position;
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - vert.eye_position*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -vert.eye_position.xyz;
  
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput LicoriceSphereImposterPerspectiveFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                                constant LightUniforms& lightUniforms [[buffer(2)]],
                                                                texture2d<half>  ambientOcclusionTexture     [[ texture(0) ]],
                                                                sampler          ambientOcclusionSampler [[ sampler(0) ]])
{
  FragOutput output;
  
  float3 rij = -vert.frag_center;
  float3 vij = vert.frag_pos;
  
  float A = dot(vij, vij);
  float B = 2.0 * dot(rij, vij);
  float C = dot(rij, rij) - vert.sphere_radius.z * vert.sphere_radius.z;
  float argument = B * B - 4.0 * A * C;
  if (argument < 0.0) discard_fragment();
  float t = 0.5 * (-B - sqrt(argument)) / A;
  
  float3 hit = t * vij;
  
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(hit - vert.frag_center);
  
  if(structureUniforms.clipBondsAtUnitCell)
  {
    float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
    float4 vertexPosition = ambientOcclusionTransformMatrix * (vert.sphere_radius * float4(N.xyz,1.0));
    float4 position = float4(vert.instancePosition.xyz + vertexPosition.xyz,1.0);
    if (dot(structureUniforms.clipPlaneLeft,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneRight,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneTop,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneBottom,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneFront,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneBack,position)< 0.0) discard_fragment();
  }
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w ;
  
  
  
  // Normalize the incoming N, L and V vectors
  //float3 N = float3(x,y,z);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float4 ambient = vert.ambient;
  float4 diffuse = max(dot(N, L), 0.0) * vert.diffuse;
  float4 specular = pow(max(dot(R, V), 0.0), lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  
  float4 color = ambient + diffuse + specular;
  
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



