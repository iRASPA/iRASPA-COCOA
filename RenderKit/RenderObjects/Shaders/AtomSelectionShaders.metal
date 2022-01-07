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

struct GlowVertexShaderOut
{
  float4 position [[position]];
  float4 eye_position;
  float2 texcoords;
  float4 ambient [[ flat ]];
  float4 diffuse [[ flat ]];
  float4 specular [[ flat ]];
  float3 frag_pos ;
  float3 frag_center [[ flat]];
  float4 sphere_radius [[ flat ]];
};


vertex GlowVertexShaderOut AtomGlowSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                      const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                      constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                      constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                      constant LightUniforms& lightUniforms [[buffer(4)]],
                                                      uint vid [[vertex_id]],
                                                      uint iid [[instance_id]])
{
  GlowVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos =  scale * vertices[vid].position + positions[iid].position;
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  return vert;
}

fragment float4 AtomGlowSphereFragmentShader(GlowVertexShaderOut vert [[stage_in]],
                                             constant StructureUniforms& structureUniforms [[buffer(0)]],
                                             constant FrameUniforms& frameUniforms [[buffer(1)]],
                                             constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return float4(structureUniforms.atomSelectionIntensity * (vert.ambient.xyz + vert.diffuse.xyz), 1.0);
}




vertex GlowVertexShaderOut AtomGlowSphereImposterOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                          const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                          constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                          constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                          constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                          uint vid [[vertex_id]],
                                                                          uint iid [[instance_id]])
{
  GlowVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  pos2.xy += scale.xy * vertices[vid].position.xy;
  
  vert.frag_pos = pos2.xyz;
  
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}




fragment FragOutput AtomGlowSphereImposterOrthographicFragmentShader(GlowVertexShaderOut vert [[stage_in]],
                                                                     constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                     constant StructureUniforms& structureUniforms [[buffer(1)]])
{
  FragOutput output;
  
  float x = vert.texcoords.x;
  float y = vert.texcoords.y;
  float zz = 1.0 - x*x - y*y;
  
  if (zz <= 0.0)
    discard_fragment();
  
  
  float z = sqrt(zz);  // avoid z-fighting
  float4 pos = vert.eye_position;
  pos.z += vert.sphere_radius.z*z;
  pos = frameUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  output.albedo = float4(structureUniforms.atomSelectionIntensity * (vert.diffuse.xyz+vert.ambient.xyz),1.0);
  
  return output;
  
}

vertex GlowVertexShaderOut AtomGlowSphereImposterPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                         const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                         constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                         constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                         constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                         uint vid [[vertex_id]],
                                                                         uint iid [[instance_id]])
{
  GlowVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput AtomGlowSphereImposterPerspectiveFragmentShader(GlowVertexShaderOut vert [[stage_in]],
                                                                    constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                    constant StructureUniforms& structureUniforms [[buffer(1)]])
{
  FragOutput output;
  
  float3 rij = -vert.frag_center;
  float3 vij = vert.frag_pos;
  
  float A = dot(vij, vij);
  float B = dot(rij, vij);
  float C = dot(rij, rij) - vert.sphere_radius.z * vert.sphere_radius.z;
  float argument = B * B - A * C;
  if (argument < 0.0) discard_fragment();
  
  float t = - C / (B - sqrt(argument));
  float3 hit = t * vij;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  output.albedo = float4(structureUniforms.atomSelectionIntensity *  (vert.diffuse.xyz+vert.ambient.xyz),1.0);
  
  return output;
  
}


struct BlurVertexShaderOut
{
  float4 position [[position]];
  float2 texCoord;
  float2 blurTexCoords0;
  float2 blurTexCoords1;
  float2 blurTexCoords2;
  float2 blurTexCoords3;
  float2 blurTexCoords4;
  float2 blurTexCoords5;
  float2 blurTexCoords6;
  float2 blurTexCoords7;
  float2 blurTexCoords8;
  float2 blurTexCoords9;
  float2 blurTexCoords10;
  float2 blurTexCoords11;
  float2 blurTexCoords12;
  float2 blurTexCoords13;
};

vertex BlurVertexShaderOut blurHorizontalVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                      uint vid [[vertex_id]])
{
  BlurVertexShaderOut vert;
  
  float4 position = vertices[vid].position;
  float2 texCoord = position.xy * float2(0.5) + float2(0.5);
  
  vert.position = position;
  vert.texCoord = texCoord;
  
  vert.blurTexCoords0 = texCoord + float2(-0.028, 0.0);
  vert.blurTexCoords1 = texCoord + float2(-0.024, 0.0);
  vert.blurTexCoords2 = texCoord + float2(-0.020, 0.0);
  vert.blurTexCoords3 = texCoord + float2(-0.016, 0.0);
  vert.blurTexCoords4 = texCoord + float2(-0.012, 0.0);
  vert.blurTexCoords5 = texCoord + float2(-0.008, 0.0);
  vert.blurTexCoords6 = texCoord + float2(-0.004, 0.0);
  vert.blurTexCoords7 = texCoord + float2( 0.004, 0.0);
  vert.blurTexCoords8 = texCoord + float2( 0.008, 0.0);
  vert.blurTexCoords9 = texCoord + float2( 0.012, 0.0);
  vert.blurTexCoords10 = texCoord + float2( 0.016, 0.0);
  vert.blurTexCoords11 = texCoord + float2( 0.020, 0.0);
  vert.blurTexCoords12 = texCoord + float2( 0.024, 0.0);
  vert.blurTexCoords13 = texCoord + float2( 0.028, 0.0);
  
  
  return vert;
}

vertex BlurVertexShaderOut blurVerticalVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                    uint vid [[vertex_id]])
{
  BlurVertexShaderOut vert;
  
  float4 position = vertices[vid].position;
  float2 texCoord = position.xy * float2(0.5) + float2(0.5);
  
  vert.position = position;
  vert.texCoord = texCoord;
  
  vert.blurTexCoords0 = texCoord + float2(0.0, -0.028);
  vert.blurTexCoords1 = texCoord + float2(0.0, -0.024);
  vert.blurTexCoords2 = texCoord + float2(0.0, -0.020);
  vert.blurTexCoords3 = texCoord + float2(0.0, -0.016);
  vert.blurTexCoords4 = texCoord + float2(0.0, -0.012);
  vert.blurTexCoords5 = texCoord + float2(0.0, -0.008);
  vert.blurTexCoords6 = texCoord + float2(0.0, -0.004);
  vert.blurTexCoords7 = texCoord + float2(0.0,  0.004);
  vert.blurTexCoords8 = texCoord + float2(0.0,  0.008);
  vert.blurTexCoords9 = texCoord + float2(0.0,  0.012);
  vert.blurTexCoords10 = texCoord + float2(0.0,  0.016);
  vert.blurTexCoords11 = texCoord + float2(0.0,  0.020);
  vert.blurTexCoords12 = texCoord + float2(0.0,  0.024);
  vert.blurTexCoords13 = texCoord + float2(0.0,  0.028);
  
  return vert;
}

fragment float4 blurFragmentShader(BlurVertexShaderOut vert [[stage_in]],
                                   texture2d<float>  tex2D     [[ texture(0) ]],
                                   sampler           quadSampler [[ sampler(0) ]])

{
  float4 output;
  
  output = float4(0.0);
  output += tex2D.sample(quadSampler, vert.blurTexCoords0)*0.0044299121055113265;
  output += tex2D.sample(quadSampler, vert.blurTexCoords1)*0.00895781211794;
  output += tex2D.sample(quadSampler, vert.blurTexCoords2)*0.0215963866053;
  output += tex2D.sample(quadSampler, vert.blurTexCoords3)*0.0443683338718;
  output += tex2D.sample(quadSampler, vert.blurTexCoords4)*0.0776744219933;
  output += tex2D.sample(quadSampler, vert.blurTexCoords5)*0.115876621105;
  output += tex2D.sample(quadSampler, vert.blurTexCoords6)*0.147308056121;
  output += tex2D.sample(quadSampler, vert.texCoord      )*0.159576912161;
  output += tex2D.sample(quadSampler, vert.blurTexCoords7)*0.147308056121;
  output += tex2D.sample(quadSampler, vert.blurTexCoords8)*0.115876621105;
  output += tex2D.sample(quadSampler, vert.blurTexCoords9)*0.0776744219933;
  output += tex2D.sample(quadSampler, vert.blurTexCoords10)*0.0443683338718;
  output += tex2D.sample(quadSampler, vert.blurTexCoords11)*0.0215963866053;
  output += tex2D.sample(quadSampler, vert.blurTexCoords12)*0.00895781211794;
  output += tex2D.sample(quadSampler, vert.blurTexCoords13)*0.0044299121055113265;
  
  return output;
}


// Mark: Worley noise 3D full

vertex AtomSphereVertexShaderOut AtomSelectionWorleyNoise3DSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                        const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                        constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                        constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                        constant LightUniforms& lightUniforms [[buffer(4)]],
                                                        uint vid [[vertex_id]],
                                                        uint iid [[instance_id]])
{
  AtomSphereVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos =  scale * vertices[vid].position + positions[iid].position;
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].normal.xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}

fragment float4 AtomSelectionWorleyNoise3DSphereFragmentShader(AtomSphereVertexShaderOut vert [[stage_in]],
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
  float2 F = cellular3D(frequency*float3(t1.x,t1.z,t1.y), jitter);
  float n = F.y-F.x;
  
  float4 color = n * (ambient + diffuse + specular);
  
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


// Mark: Worley noise 3D orthographic

vertex AtomSphereImposterVertexShaderOut AtomSelectionWorleyNoise3DOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                            const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                            constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                            constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                            constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                            uint vid [[vertex_id]],
                                                                                            uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
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

fragment FragOutput AtomSelectionWorleyNoise3DOrthographicFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                         constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                         constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                                         constant LightUniforms& lightUniforms [[buffer(2)]])
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
  
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t1 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
  
  float frequency = structureUniforms.atomSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.atomSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,t1.z,t1.y), jitter);
  float n = F.y-F.x;
  
  float4 color= n * float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
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
  output.albedo = float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
  
  return output;
}

// Mark: Worley noise 3D perspective

vertex AtomSphereImposterVertexShaderOut AtomSelectionWorleyNoise3DPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                           const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                           constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                           constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                           constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                           uint vid [[vertex_id]],
                                                                                           uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
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
  
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput AtomSelectionWorleyNoise3DPerspectiveFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                        constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                        constant StructureUniforms& structureUniforms [[buffer(1)]],
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
  
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t1 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
  
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
  output.albedo = float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
  
  return output;
}

// Mark: Stripes 3D full

vertex AtomSphereVertexShaderOut AtomSelectionStripedSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                        const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                        constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                        constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                        constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                        uint vid [[vertex_id]],
                                                                        uint iid [[instance_id]])
{
  AtomSphereVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos =  scale * vertices[vid].position + positions[iid].position;
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.atomAmbientColor * positions[iid].ambient;
  vert.diffuse = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].diffuse;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.atomSpecularColor * positions[iid].specular;
  
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].normal.xyz;
  
  float4 P =  frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}

fragment float4 AtomSelectionStripedSphereFragmentShader(AtomSphereVertexShaderOut vert [[stage_in]],
                                                               constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                               constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                               constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  float3 t1 = vert.Model_N;
  
  float2  st = float2(0.5 + 0.5 * atan2(t1.z, t1.x)/3.141592653589793, 0.5 - asin(t1.y)/3.141592653589793);
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


// Mark: Stripes orthographic

vertex AtomSphereImposterVertexShaderOut AtomSelectionStripedSphereOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                            const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                            constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                            constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                            constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                            uint vid [[vertex_id]],
                                                                                            uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
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

fragment FragOutput AtomSelectionStripedSphereOrthographicFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                         constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                         constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                                         constant LightUniforms& lightUniforms [[buffer(2)]])
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
  pos = frameUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  
  
  // Normalize the incoming N, L and V vectors
  float3 N = float3(x,y,z);
  float3 L = normalize(vert.L);
  
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t1 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
  
  
  float2  st = float2(0.5 + 0.5 * atan2(t1.z, t1.x)/3.141592653589793, 0.5 - asin(t1.y)/3.141592653589793);
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
  output.albedo = float4(hsv2rgb(hsv) * bloomLevel, bloomLevel);
  
  return output;
}

// Mark: Stripes 3D perspective

vertex AtomSphereImposterVertexShaderOut AtomSelectionStripedSpherePerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                           const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                                           constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                           constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                           constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                                           uint vid [[vertex_id]],
                                                                                           uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomSelectionScaling * structureUniforms.atomScaleFactor * positions[iid].scale;
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
  
  vert.frag_center= (frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment FragOutput AtomSelectionStripedSpherePerspectiveFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                                                        constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                                        constant StructureUniforms& structureUniforms [[buffer(1)]],
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
  
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  float4x4 ambientOcclusionTransformMatrix = float4x4(vert.ambientOcclusionTransformMatrix1,vert.ambientOcclusionTransformMatrix2,vert.ambientOcclusionTransformMatrix3,vert.ambientOcclusionTransformMatrix4);
  float3 t1 = (ambientOcclusionTransformMatrix * float4(N,1.0)).xyz;
  
  
  float2  st = float2(0.5 + 0.5 * atan2(t1.z, t1.x)/3.141592653589793, 0.5 - asin(t1.y)/3.141592653589793);
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
  float intensity = frameUniforms.bloomLevel * structureUniforms.atomSelectionIntensity;
  output.albedo = float4(hsv2rgb(hsv) * intensity, intensity);
  
  return output;
}
