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

struct ExternalBondSelectionVertexShaderOut
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
  float3 Model_N;
  
  float clipDistance0 [[ center_perspective ]];
  float clipDistance1 [[ center_perspective ]];
  float clipDistance2 [[ center_perspective ]];
  float clipDistance3 [[ center_perspective ]];
  float clipDistance4 [[ center_perspective ]];
  float clipDistance5 [[ center_perspective ]];
};


vertex ExternalBondSelectionVertexShaderOut externalBondSelectionWorleyNoise3DCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  ExternalBondSelectionVertexShaderOut vert;
  
  float4 scale = positions[iid].scale;
  
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
  
  vert.Model_N = vertices[vid].position.xyz;
  
  float4 pos;
  float4 scaleFactor = float4(1.01 * structureUniforms.bondSelectionScaling,1.0,1.01 * structureUniforms.bondSelectionScaling,1.0);
  switch(positions[iid].type)
  {
    case 1: // double bond
      pos = (vertices[vid].position-float4(sign(vertices[vid].position.x),0.0,0.0,0.0))*scaleFactor+float4(sign(vertices[vid].position.x),0.0,0.0,0.0);
      break;
    case 3: // triple bond
      if(vertices[vid].position.x<0.0 && vertices[vid].position.z<0.0)
      {
        pos = (vertices[vid].position+float4(1.0,0.0,0.5*sqrt(3.0),0.0))*scaleFactor-float4(1.0,0.0,0.5*sqrt(3.0),0.0);
      }
      else if(vertices[vid].position.x>0.0 && vertices[vid].position.z<0.0)
      {
        pos = (vertices[vid].position+float4(-1.0,0.0,0.5*sqrt(3.0),0.0))*scaleFactor-float4(-1.0,0.0,0.5*sqrt(3.0),0.0);
      }
      else
      {
        pos = (vertices[vid].position-float4(0.0,0.0,0.5*sqrt(3.0),0.0))*scaleFactor+float4(0.0,0.0,0.5*sqrt(3.0),0.0);
      }
      break;
    default: // single bond
      pos = vertices[vid].position * scaleFactor;
      
  }
  
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



fragment float4 externalBondSelectionWorleyNoise3DCylinderFragmentShader(ExternalBondSelectionVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // [[ clip_distance ]] appears to working only for two clipping planes
  // work-around: brute-force 'discard_fragment'
  if (vert.clipDistance0 < 0.0) discard_fragment();
  if (vert.clipDistance1 < 0.0) discard_fragment();
  if (vert.clipDistance2 < 0.0) discard_fragment();
  if (vert.clipDistance3 < 0.0) discard_fragment();
  if (vert.clipDistance4 < 0.0) discard_fragment();
  if (vert.clipDistance5 < 0.0) discard_fragment();
  
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
  
  float3 t1 = vert.Model_N;
  
  float frequency = structureUniforms.bondSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.bondSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,2.0*t1.y,t1.z), jitter);
  float n = F.y-F.x;
  
  float4 color = n * (ambient + diffuse + specular);
  
  //float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
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
  float intensity = frameUniforms.bloomLevel *  structureUniforms.bondSelectionIntensity;
  return float4(hsv2rgb(hsv) * intensity, intensity);
}




vertex ExternalBondSelectionVertexShaderOut externalBondSelectionGlowVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  ExternalBondSelectionVertexShaderOut vert;
  
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



fragment float4 externalBondSelectionGlowFragmentShader(ExternalBondSelectionVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // [[ clip_distance ]] appears to working only for two clipping planes
  // work-around: brute-force 'discard_fragment'
  if (vert.clipDistance0 < 0.0) discard_fragment();
  if (vert.clipDistance1 < 0.0) discard_fragment();
  if (vert.clipDistance2 < 0.0) discard_fragment();
  if (vert.clipDistance3 < 0.0) discard_fragment();
  if (vert.clipDistance4 < 0.0) discard_fragment();
  if (vert.clipDistance5 < 0.0) discard_fragment();
  
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
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  return float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
}


vertex ExternalBondSelectionVertexShaderOut externalBondSelectionStripedCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  ExternalBondSelectionVertexShaderOut vert;
  
  float4 scale = positions[iid].scale;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.Model_N = vertices[vid].position.xyz;
  
  
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
  
  float4 pos;
  float4 scaleFactor = float4(1.01 * structureUniforms.bondSelectionScaling,1.0,1.01 * structureUniforms.bondSelectionScaling,1.0);
  switch(positions[iid].type)
  {
    case 1: // double bond
      pos = (vertices[vid].position-float4(sign(vertices[vid].position.x),0.0,0.0,0.0))*scaleFactor+float4(sign(vertices[vid].position.x),0.0,0.0,0.0);
      break;
    case 3: // triple bond
      if(vertices[vid].position.x<0.0 && vertices[vid].position.z<0.0)
      {
        pos = (vertices[vid].position+float4(1.0,0.0,0.5*sqrt(3.0),0.0))*scaleFactor-float4(1.0,0.0,0.5*sqrt(3.0),0.0);
      }
      else if(vertices[vid].position.x>0.0 && vertices[vid].position.z<0.0)
      {
        pos = (vertices[vid].position+float4(-1.0,0.0,0.5*sqrt(3.0),0.0))*scaleFactor-float4(-1.0,0.0,0.5*sqrt(3.0),0.0);
      }
      else
      {
        pos = (vertices[vid].position-float4(0.0,0.0,0.5*sqrt(3.0),0.0))*scaleFactor+float4(0.0,0.0,0.5*sqrt(3.0),0.0);
      }
      break;
    default: // single bond
      pos = vertices[vid].position * scaleFactor;
      
  }
  
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



fragment float4 externalBondSelectionStripedCylinderFragmentShader(ExternalBondSelectionVertexShaderOut vert [[stage_in]],
                                                                   constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                   constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                                   constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // [[ clip_distance ]] appears to working only for two clipping planes
  // work-around: brute-force 'discard_fragment'
  if (vert.clipDistance0 < 0.0) discard_fragment();
  if (vert.clipDistance1 < 0.0) discard_fragment();
  if (vert.clipDistance2 < 0.0) discard_fragment();
  if (vert.clipDistance3 < 0.0) discard_fragment();
  if (vert.clipDistance4 < 0.0) discard_fragment();
  if (vert.clipDistance5 < 0.0) discard_fragment();
  
  // Normalize the incoming N and L vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  float3 t1 = vert.Model_N;
  
  float2 st = float2(0.5 + 0.5 * atan2(t1.x, t1.z)/3.141592653589793, t1.y);
  float uDensity = structureUniforms.bondSelectionStripesDensity;
  float frequency = structureUniforms.bondSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  if (structureUniforms.atomHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.atomHDRExposure);
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  return float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
}


