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

struct UnitCellVertexShaderOut
{
  float4 position [[position]];
  float4 ambient [[ flat ]];
  float4 diffuse [[ flat ]];
  float4 specular [[ flat ]];
  
  float3 N;
  float3 L;
  float3 V;
};


vertex UnitCellVertexShaderOut UnitCellSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                  const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                  constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                  constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                  constant LightUniforms& lightUniforms [[buffer(4)]],
                                                  uint vid [[vertex_id]],
                                                  uint iid [[instance_id]])
{
  UnitCellVertexShaderOut vert;
  
  float4 scale =  positions[iid].scale;
  scale.xyz *= structureUniforms.unitCellScaling;

  float4 pos =  float4((scale * vertices[vid].position + positions[iid].position).xyz,1.0);
  vert.ambient = lightUniforms.lights[0].ambient * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * positions[iid].specular;
  
  vert.N = (frameUniforms.normalMatrix * vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  return vert;
}




fragment float4 UnitCellSphereFragmentShader(UnitCellVertexShaderOut vert [[stage_in]],
                                             constant StructureUniforms& structureUniforms [[buffer(0)]],
                                             constant FrameUniforms& frameUniforms [[buffer(1)]],
                                             texture2d<half>  ambientOcclusionTexture     [[ texture(0) ]],
                                             sampler           shadowMapSampler [[ sampler(0) ]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  //float3 V = normalize(vert.V);
  
  // Calculate R locally
  //float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  
  float ao = 1.0;
  float4 color= float4(ao * (structureUniforms.unitCellColor.xyz * diffuse.xyz), 1.0);
                       
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  return float4(hsv2rgb(hsv),1.0);
}



vertex UnitCellVertexShaderOut UnitCellCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  UnitCellVertexShaderOut vert;
  
  vert.ambient = lightUniforms.lights[0].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse;
  vert.specular = lightUniforms.lights[0].specular;
  
  float4 scale = positions[iid].scale;
  float4 pos =  scale * float4((vertices[vid].position).xyz,1.0);
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  float3 dr = (pos1 - pos2).xyz;
  float bondLength = length(dr);
  
  
  scale.x = structureUniforms.unitCellScaling;
  scale.y = bondLength;
  scale.z = structureUniforms.unitCellScaling;
  
  dr = normalize(dr);
  if ((dr.z !=0 ) && (-dr.x != dr.y ))
    v1=normalize(float3(-dr.y-dr.z,dr.x,dr.x));
  else
    v1=normalize(float3(dr.z,dr.z,-dr.x-dr.y));
  
  v2=normalize(cross(dr,v1));
  
  float4x4 orientationMatrix=float4x4(float4(-v1.x,-v1.y,-v1.z,0),
                                      float4(-dr.x,-dr.y,-dr.z,0),
                                      float4(-v2.x,-v2.y,-v2.z,0),
                                      float4(0,0,0,1));
  
  
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * orientationMatrix * vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix *  structureUniforms.modelMatrix * float4((orientationMatrix * (scale * pos) + pos1).xyz,1.0);
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * float4((orientationMatrix * (scale * pos) + pos1).xyz,1.0);
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  
  return vert;
}



fragment float4 UnitCellCylinderFragmentShader(UnitCellVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant FrameUniforms& frameUniforms [[buffer(1)]])

{
  // Normalize the incoming N and L vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  float ao = 1.0;
  float4 color= float4(ao * (structureUniforms.unitCellColor.xyz * diffuse.xyz), 1.0);
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  return float4(hsv2rgb(hsv),1.0);
}


