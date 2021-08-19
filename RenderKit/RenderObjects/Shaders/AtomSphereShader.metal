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

vertex AtomSphereVertexShaderOut AtomSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                              const device InPerInstanceAttributes *positions [[buffer(1)]],
                                              constant FrameUniforms& frameUniforms [[buffer(2)]],
                                              constant StructureUniforms& structureUniforms [[buffer(3)]],
                                              constant LightUniforms& lightUniforms [[buffer(4)]],
                                              uint vid [[vertex_id]],
                                              uint iid [[instance_id]])
{
  AtomSphereVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos =  scale * vertices[vid].position + positions[iid].position;
  if (structureUniforms.colorAtomsWithBondColor)
  {
    vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
    vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  }
  else
  {
    vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
    vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  }
  

  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].normal.xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
            
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  uint patchNumber=structureUniforms.ambientOcclusionPatchNumber;
  vert.k1=iid%patchNumber;
  vert.k2=iid/patchNumber;
  
  if(structureUniforms.clipAtomsAtUnitCell)
  {
    vert.clippingDistance0 = dot(structureUniforms.clipPlaneBack,pos);
    vert.clippingDistance1 = dot(structureUniforms.clipPlaneBottom,pos);
    vert.clippingDistance2 = dot(structureUniforms.clipPlaneLeft,pos);
    
    vert.clippingDistance3 = dot(structureUniforms.clipPlaneFront,pos);
    vert.clippingDistance4 = dot(structureUniforms.clipPlaneTop,pos);
    vert.clippingDistance5 = dot(structureUniforms.clipPlaneRight,pos);
  }
  
  return vert;
}



static float2 textureCoordinateForSphereSurfacePositionNew(float3 sphereSurfacePosition)
{
  float3 absoluteSphereSurfacePosition = fabs(sphereSurfacePosition);
  float d = absoluteSphereSurfacePosition.x + absoluteSphereSurfacePosition.y + absoluteSphereSurfacePosition.z;
  
  return (sphereSurfacePosition.z > 0.0) ? sphereSurfacePosition.xy / d : float2(sign(sphereSurfacePosition.x) * ( 1.0 - absoluteSphereSurfacePosition.y/ d),sign(sphereSurfacePosition.y) * ( 1.0 - absoluteSphereSurfacePosition.x/ d));
}


fragment float4 AtomSphereFragmentShader(AtomSphereVertexShaderOut vert [[stage_in]],
                                         constant StructureUniforms& structureUniforms [[buffer(0)]],
                                         constant FrameUniforms& frameUniforms [[buffer(1)]],
                                         constant LightUniforms& lightUniforms [[buffer(2)]],
                                         texture2d<half>  ambientOcclusionTexture     [[ texture(0) ]],
                                         sampler           shadowMapSampler [[ sampler(0) ]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  if(structureUniforms.clipAtomsAtUnitCell)
  {
    if (vert.clippingDistance0 < 0.0) discard_fragment();
    if (vert.clippingDistance1 < 0.0) discard_fragment();
    if (vert.clippingDistance2 < 0.0) discard_fragment();
    if (vert.clippingDistance3 < 0.0) discard_fragment();
    if (vert.clippingDistance4 < 0.0) discard_fragment();
    if (vert.clippingDistance5 < 0.0) discard_fragment();
  }
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  float3 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.atomShininess) * vert.specular.xyz;

  
  float ao = 1.0;
  
  if (structureUniforms.ambientOcclusion)
  {
    float patchSize=structureUniforms.ambientOcclusionPatchSize;
    float3 t1 = vert.Model_N;
    float2 m2 = (float2(patchSize*(vert.k1+0.5),patchSize*(vert.k2+0.5))+0.5*(patchSize-1.0)*(textureCoordinateForSphereSurfacePositionNew(t1)))*structureUniforms.ambientOcclusionInverseTextureSize;
    
    ao = ambientOcclusionTexture.sample(shadowMapSampler, m2).r;
  }
  
  float4 color= float4(ao * (ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
  
  if (structureUniforms.atomHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.atomHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  return float4(hsv2rgb(hsv),1.0);
}


// Mark: Sphere-imposter orthographic





vertex AtomSphereImposterVertexShaderOut AtomSphereImposterOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                 const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                 constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                 constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                 constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                 uint vid [[vertex_id]],
                                                                 uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomScaleFactor * positions[iid].scale;
  
  if (structureUniforms.colorAtomsWithBondColor)
  {
    vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
    vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  }
  else
  {
    vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
    vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  }
  
  vert.N = float3(0,0,1);
  vert.instancePosition = positions[iid].position;
  
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
  
  uint patchNumber=structureUniforms.ambientOcclusionPatchNumber;
  vert.k1=iid%patchNumber;
  vert.k2=iid/patchNumber;
  
  return vert;
}


static float2 textureCoordinateForSphereSurfacePosition(float3 sphereSurfacePosition)
{
  float3 absoluteSphereSurfacePosition = fabs(sphereSurfacePosition);
  float d = absoluteSphereSurfacePosition.x + absoluteSphereSurfacePosition.y + absoluteSphereSurfacePosition.z;
  
  return (sphereSurfacePosition.z > 0.0) ? sphereSurfacePosition.xy / d : float2(sign(sphereSurfacePosition.x) * ( 1.0 - absoluteSphereSurfacePosition.y/ d),sign(sphereSurfacePosition.y) * ( 1.0 - absoluteSphereSurfacePosition.x/ d));
}

fragment FragOutput AtomSphereImposterOrthographicFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
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
  
  if(structureUniforms.clipAtomsAtUnitCell)
  {
    float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,
                                                        vert.ambientOcclusionTransformMatrix2,
                                                        vert.ambientOcclusionTransformMatrix3,
                                                        vert.ambientOcclusionTransformMatrix4);
    float3 vertexPosition = (ambientOcclusionTransformMatrix * (vert.sphere_radius * float4(x,y,z,1.0))).xyz;
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
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  float3 specular = pow(max(dot(R, V), 0.0), lightUniforms.lights[0].shininess + structureUniforms.atomShininess) * vert.specular.xyz;
  
  float ao = 1.0;
  
  if (structureUniforms.ambientOcclusion)
  {
    float patchSize=structureUniforms.ambientOcclusionPatchSize;
    float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
    float3 t1 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
    float2 m2 = (float2(patchSize*(vert.k1+0.5),patchSize*(vert.k2+0.5))+0.5*(patchSize-1.0)*(textureCoordinateForSphereSurfacePosition(t1)))*structureUniforms.ambientOcclusionInverseTextureSize;
    ao = ambientOcclusionTexture.sample(ambientOcclusionSampler, m2).r;
  }
  
  float4 color= float4(ao * (ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
    
  if (structureUniforms.atomHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.atomHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  output.albedo = float4(hsv2rgb(hsv),1.0);
  
  return output;
}


// Mark: Sphere-imposter perspective

vertex AtomSphereImposterVertexShaderOut AtomSphereImposterPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                uint vid [[vertex_id]],
                                                                uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomScaleFactor * positions[iid].scale;
  
  if (structureUniforms.colorAtomsWithBondColor)
  {
    vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
    vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  }
  else
  {
    vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
    vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
    vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  }
  
  vert.N = float3(0,0,1);
  vert.instancePosition = positions[iid].position;
  
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
  
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = structureUniforms.atomScaleFactor * positions[iid].scale;
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  uint patchNumber=structureUniforms.ambientOcclusionPatchNumber;
  vert.k1=iid%patchNumber;
  vert.k2=iid/patchNumber;
  
  return vert;
}

fragment FragOutput AtomSphereImposterPerspectiveFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
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
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w ;
  
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(hit - vert.frag_center);
  
  if(structureUniforms.clipAtomsAtUnitCell)
  {
    float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,
                                                        vert.ambientOcclusionTransformMatrix2,
                                                        vert.ambientOcclusionTransformMatrix3,
                                                        vert.ambientOcclusionTransformMatrix4);
    float3 vertexPosition = (ambientOcclusionTransformMatrix * (vert.sphere_radius * float4(N,1.0))).xyz;
    float4 position = float4(vert.instancePosition.xyz + vertexPosition.xyz,1.0);
    if (dot(structureUniforms.clipPlaneLeft,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneRight,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneTop,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneBottom,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneFront,position)< 0.0) discard_fragment();
    if (dot(structureUniforms.clipPlaneBack,position)< 0.0) discard_fragment();
  }
  
  // Normalize the incoming N, L and V vectors
  //float3 N = float3(x,y,z);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  float3 specular = pow(max(dot(R, V), 0.0), lightUniforms.lights[0].shininess + structureUniforms.atomShininess) * vert.specular.xyz;
  
  float ao = 1.0;
  
  if (structureUniforms.ambientOcclusion)
  {
    
    float patchSize=structureUniforms.ambientOcclusionPatchSize;
    float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
    float3 t1 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
    float2 m2 = (float2(patchSize*(vert.k1+0.5),patchSize*(vert.k2+0.5))+0.5*(patchSize-1.0)*(textureCoordinateForSphereSurfacePosition(t1)))*structureUniforms.ambientOcclusionInverseTextureSize;
    ao = ambientOcclusionTexture.sample(ambientOcclusionSampler, m2).r;
  }
  
  float4 color= float4(ao * (ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
  
  if (structureUniforms.atomHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.atomHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.atomHue;
  hsv.y = hsv.y * structureUniforms.atomSaturation;
  hsv.z = hsv.z * structureUniforms.atomValue;
  output.albedo = float4(hsv2rgb(hsv),1.0);
  
  return output;
}





