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


// Mark: Measurement orthographic

vertex AtomSphereImposterVertexShaderOut AtomMeasurementSphereImposterOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                               const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                               constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                               constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                               constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                               uint vid [[vertex_id]],
                                                                                               uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = 1.01*structureUniforms.atomScaleFactor * positions[iid].scale;
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.N = float3(0,0,1);
  
  float4x4 ambientOcclusionTransformMatrix = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.ambientOcclusionTransformMatrix1 = ambientOcclusionTransformMatrix[0];
  vert.ambientOcclusionTransformMatrix2 = ambientOcclusionTransformMatrix[1];
  vert.ambientOcclusionTransformMatrix3 = ambientOcclusionTransformMatrix[2];
  vert.ambientOcclusionTransformMatrix4 = ambientOcclusionTransformMatrix[3];
  
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - vert.eye_position*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -vert.eye_position.xyz;
  
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  pos2.xy += scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  
  vert.frag_pos = pos2.xyz;
  
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput AtomMeasurementSphereImposterOrthographicFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                            constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                                            constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                            constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  float x = vert.texcoords.x;
  float y = vert.texcoords.y;
  float zz = 1.0 - x*x - y*y;
  
  if (zz <= 0.0)
    discard_fragment();
  
  
  float z = sqrt(zz);
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t3 = (ambientOcclusionTransformMatrix * float4(x,y,z,1.0)).xyz;
  float2  st = float2(0.5 + 0.5 * atan2(t3.z, t3.x)/3.141592653589793, 0.5 - asin(t3.y)/3.141592653589793);
  float uDensity = 0.125;
  
  if (fract(st.x*8.0) >= uDensity && fract(st.y*8.0) >= uDensity)
    discard_fragment();
  
  float4 pos = vert.eye_position;
  pos.z += vert.sphere_radius.z*z;
  pos = frameUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  
  
  // Normalize the incoming N, L and V vectors
  float3 N = float3(x,y,z);
  float3 L = normalize(vert.L);
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  
  output.albedo = float4((ambient.xyz + diffuse.xyz) * 0.8, 0.8);
  
  return output;
}

// Mark: Measurement perspective

vertex AtomSphereImposterVertexShaderOut AtomMeasurementSphereImposterPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                              const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                              constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                              constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                              constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                              uint vid [[vertex_id]],
                                                                                              uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = 1.01 * structureUniforms.atomScaleFactor * positions[iid].scale;
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  float4x4 ambientOcclusionTransformMatrix = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.ambientOcclusionTransformMatrix1 = ambientOcclusionTransformMatrix[0];
  vert.ambientOcclusionTransformMatrix2 = ambientOcclusionTransformMatrix[1];
  vert.ambientOcclusionTransformMatrix3 = ambientOcclusionTransformMatrix[2];
  vert.ambientOcclusionTransformMatrix4 = ambientOcclusionTransformMatrix[3];
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;  // avoid z-fighting
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput AtomMeasurementSphereImposterPerspectiveFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                                           constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                           constant LightUniforms& lightUniforms [[buffer(2)]])
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
  
  
  
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w ;
  
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(hit - vert.frag_center);
  float3 L = normalize(vert.L);
  
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t3 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
  float2  st = float2(0.5 + 0.5 * atan2(t3.z, t3.x)/3.141592653589793, 0.5 - asin(t3.y)/3.141592653589793);
  float uDensity = 0.125;
  
  if (fract(st.x*8.0) >= uDensity && fract(st.y*8.0) >= uDensity)
    discard_fragment();
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  
  output.albedo = float4((ambient.xyz + diffuse.xyz) * 0.8, 0.8);
  
  return output;
}


// Mark: Licorice Measurement orthographic

vertex AtomSphereImposterVertexShaderOut LicoriceMeasurementSphereImposterOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                               const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                               constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                               constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                               constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                               uint vid [[vertex_id]],
                                                                                               uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float scaleFactor = 1.5 * 0.15*structureUniforms.bondScaling;
  float4 scale = float4(scaleFactor,scaleFactor,scaleFactor,1.0);
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.N = float3(0,0,1);
  
  float4x4 ambientOcclusionTransformMatrix = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.ambientOcclusionTransformMatrix1 = ambientOcclusionTransformMatrix[0];
  vert.ambientOcclusionTransformMatrix2 = ambientOcclusionTransformMatrix[1];
  vert.ambientOcclusionTransformMatrix3 = ambientOcclusionTransformMatrix[2];
  vert.ambientOcclusionTransformMatrix4 = ambientOcclusionTransformMatrix[3];
  
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
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

fragment FragOutput LicoriceMeasurementSphereImposterOrthographicFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                            constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                                            constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                            constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  float x = vert.texcoords.x;
  float y = vert.texcoords.y;
  float zz = 1.0 - x*x - y*y;
  
  if (zz <= 0.0)
    discard_fragment();
  
  
  float z = sqrt(zz);
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t3 = (ambientOcclusionTransformMatrix * float4(x,y,z,1.0)).xyz;
  float2  st = float2(0.5 + 0.5 * atan2(t3.z, t3.x)/3.141592653589793, 0.5 - asin(t3.y)/3.141592653589793);
  float uDensity = 0.125;
  
  if (fract(st.x*8.0) >= uDensity && fract(st.y*8.0) >= uDensity)
    discard_fragment();
  
  float4 pos = vert.eye_position;
  pos.z += vert.sphere_radius.z*z;
  pos = frameUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  
  
  // Normalize the incoming N, L and V vectors
  float3 N = float3(x,y,z);
  float3 L = normalize(vert.L);
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  
  output.albedo = float4((ambient.xyz + diffuse.xyz) * 0.8, 0.8);
  
  return output;
}

// Mark: Licorice Measurement perspective

vertex AtomSphereImposterVertexShaderOut LicoriceMeasurementSphereImposterPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                              const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                              constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                              constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                              constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                              uint vid [[vertex_id]],
                                                                                              uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float scaleFactor = 1.5 * 0.15*structureUniforms.bondScaling;
  float4 scale = float4(scaleFactor,scaleFactor,scaleFactor,1.0);
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  float4x4 ambientOcclusionTransformMatrix = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.ambientOcclusionTransformMatrix1 = ambientOcclusionTransformMatrix[0];
  vert.ambientOcclusionTransformMatrix2 = ambientOcclusionTransformMatrix[1];
  vert.ambientOcclusionTransformMatrix3 = ambientOcclusionTransformMatrix[2];
  vert.ambientOcclusionTransformMatrix4 = ambientOcclusionTransformMatrix[3];
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;  // avoid z-fighting
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput LicoriceMeasurementSphereImposterPerspectiveFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                                           constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                                           constant LightUniforms& lightUniforms [[buffer(2)]])
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
  
  
  
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w ;
  
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(hit - vert.frag_center);
  float3 L = normalize(vert.L);
  
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t3 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
  float2  st = float2(0.5 + 0.5 * atan2(t3.z, t3.x)/3.141592653589793, 0.5 - asin(t3.y)/3.141592653589793);
  float uDensity = 0.125;
  
  if (fract(st.x*8.0) >= uDensity && fract(st.y*8.0) >= uDensity)
    discard_fragment();
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  
  output.albedo = float4((ambient.xyz + diffuse.xyz) * 0.8, 0.8);
  
  return output;
}


