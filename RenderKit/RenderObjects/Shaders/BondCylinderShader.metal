/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
