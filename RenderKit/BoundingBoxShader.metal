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

struct BoundingBoxVertexShaderOut
{
  float4 position [[position]];
  float4 ambient [[ flat ]];
  float4 diffuse [[ flat ]];
  float4 specular [[ flat ]];
  
  float3 N;
  float3 L;
  float3 V;
};


vertex BoundingBoxVertexShaderOut BoundingBoxSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                          const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                          constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                          constant LightUniforms& lightUniforms [[buffer(3)]],
                                                          uint vid [[vertex_id]],
                                                          uint iid [[instance_id]])
{
  BoundingBoxVertexShaderOut vert;
  
  float4 scale =  positions[iid].scale;
  
  float4 pos =  float4((scale * vertices[vid].position + positions[iid].position).xyz,1.0);
  vert.ambient = lightUniforms.lights[0].ambient * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * positions[iid].specular;
  
  vert.N = (frameUniforms.normalMatrix * vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * pos;
  
  vert.position = frameUniforms.mvpMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  return vert;
}




fragment float4 BoundingBoxSphereFragmentShader(BoundingBoxVertexShaderOut vert [[stage_in]],
                                             constant FrameUniforms& frameUniforms [[buffer(0)]],
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
  
  return float4((float3(0.0,0.75,1.0) * diffuse.xyz), 1.0);
}



vertex BoundingBoxVertexShaderOut BoundingBoxCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                            const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                            constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                            constant LightUniforms& lightUniforms [[buffer(3)]],
                                                            uint vid [[vertex_id]],
                                                            uint iid [[instance_id]])
{
  float3 v1,v2;
  BoundingBoxVertexShaderOut vert;
  
  vert.ambient = lightUniforms.lights[0].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse;
  vert.specular = lightUniforms.lights[0].specular;
  
  float4 scale = positions[iid].scale;
  float4 pos =  scale * float4((vertices[vid].position).xyz,1.0);
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  float3 dr = (pos1 - pos2).xyz;
  float bondLength = length(dr);
  
  
  scale.x = 1.0;
  scale.y = bondLength;
  scale.z = 1.0;
  
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
  
  
  
  vert.N = (frameUniforms.normalMatrix * orientationMatrix * vertices[vid].normal).xyz;
  
  float4 P =  frameUniforms.viewMatrix * float4((orientationMatrix * (scale * pos) + pos1).xyz,1.0);
  
  vert.position = frameUniforms.mvpMatrix * float4((orientationMatrix * (scale * pos) + pos1).xyz,1.0);
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  return vert;
}


fragment float4 BoundingBoxCylinderFragmentShader(BoundingBoxVertexShaderOut vert [[stage_in]],
                                               constant FrameUniforms& frameUniforms [[buffer(0)]])
{
  // Normalize the incoming N and L vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  return float4(float3(0.0,0.75,1.0) * diffuse.xyz, 1.0);
}
