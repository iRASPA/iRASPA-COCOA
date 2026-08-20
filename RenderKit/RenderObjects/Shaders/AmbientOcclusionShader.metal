/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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


struct ShadowMapVertexShaderOut
{
  float4 position [[position]];
  float4 eye_position;   // flat?
  float2 texcoords;
  float3 frag_center [[ flat]];
  float4 sphere_radius [[ flat ]];
};

vertex ShadowMapVertexShaderOut AtomShadowMapVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                          const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                          constant ShadowUniforms& shadowUniforms [[buffer(2)]],
                                                          constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                          uint vid [[vertex_id]],
                                                          uint iid [[instance_id]])
{
  ShadowMapVertexShaderOut vert;
  
  float4 scale = structureUniforms.atomScaleFactor * positions[iid].scale;
  
  vert.eye_position = shadowUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = positions[iid].scale;
  
  float4 pos2 = shadowUniforms.viewMatrix * structureUniforms.modelMatrix *  positions[iid].position;
  pos2.xy += scale.xy * vertices[vid].position.xy;
  vert.position = shadowUniforms.projectionMatrix * pos2;
  
  return vert;
}

typedef struct
{
  float  depth [[depth(less)]];
} ShadowMapOutput;

fragment ShadowMapOutput AtomShadowMapFragmentShader(ShadowMapVertexShaderOut vert [[stage_in]],
                                                     constant ShadowUniforms& shadowUniforms [[buffer(0)]])
{
  ShadowMapOutput output;
  
  float x = vert.texcoords.x;
  float y = vert.texcoords.y;
  float zz = 1.0 - x*x - y*y;
  
  if (zz <= 0.0) discard_fragment();
  
  float4 pos = vert.eye_position;
  pos = shadowUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  
  return output;
}



struct AmbientOcclusionVertexShaderOut
{
  float4 position [[position]];
  float4 atomCenterPosition [[ flat ]];     // the Cartesian instance-position of the atom
  float2 texcoords;              // the -1.0..1.0 range
  float4 sphere_radius [[ flat ]];
};



// In the vertex-shader we handle all instance positions of the atoms. We then compute the texture-region this atom corresponds to.
// The 'texture-positions' are generated for this region by the rasterizer. Importantly, we now know the atom-id this region corresponds to,
// which we need in the fragment-shader.

vertex AmbientOcclusionVertexShaderOut AmbientOcclusionVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                    const device InPerInstanceAttributes *instance [[buffer(1)]],
                                                                    constant ShadowUniforms& shadowUniforms [[buffer(2)]],
                                                                    constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                    uint vid [[vertex_id]],
                                                                    uint iid [[instance_id]])
{
  AmbientOcclusionVertexShaderOut vert;
  
  vert.atomCenterPosition = structureUniforms.modelMatrix *  instance[iid].position;
  vert.sphere_radius = structureUniforms.atomScaleFactor * instance[iid].scale;
  
  uint patchNumber=structureUniforms.ambientOcclusionPatchNumber;
  float patchSize=structureUniforms.ambientOcclusionPatchSize;
  int k1=iid%patchNumber;
  int k2=iid/patchNumber;
  
  
  float2 offset = float2(patchSize,patchSize)*float2(k1,k2)*structureUniforms.ambientOcclusionInverseTextureSize;
  
  float2 position = offset * 2.0 - 1.0;  // make beteen -1.0 and 1.0
  
  float tmp = 2.0*patchSize*structureUniforms.ambientOcclusionInverseTextureSize;
  
  vert.texcoords = vertices[vid].position.xy;
  
  vert.position = float4(position + tmp * (vertices[vid].position.xy*0.5+float2(0.5)),0.0,1.0);
  vert.position.y = - vert.position.y;
  
  return vert;
}


static float3 coordinateFromTexturePosition(float2 texturePosition)
{
  float2 absoluteTexturePosition = abs(texturePosition);
  float h = 1.0 - absoluteTexturePosition.x - absoluteTexturePosition.y;
  
  if (h >= 0.0)
  {
    return float3(texturePosition.x, texturePosition.y, h);
  }
  else
  {
    return float3(sign(texturePosition.x) * (1.0 - absoluteTexturePosition.y), sign(texturePosition.y) * (1.0 - absoluteTexturePosition.x), h);
  }
}



fragment half AmbientOcclusionFragmentShader(AmbientOcclusionVertexShaderOut vert [[ stage_in ]],
                                             constant ShadowUniforms& shadowUniforms [[ buffer(0) ]],
                                             constant StructureUniforms& structureUniforms [[ buffer(1) ]],
                                             constant float& weight [[buffer(2)]],
                                             depth2d<float>  shadowMap     [[ texture(0) ]],
                                             sampler         shadowMapSampler [[ sampler(0) ]])
{
  
  float patchSize=structureUniforms.ambientOcclusionPatchSize;
  uint2 impostorSpaceCoordinate = uint2(floor(float2(vert.position.x,vert.position.y))) % uint2(patchSize,patchSize);     // ambient-Occlusion coordinate 0..pathSize-1
  float2 newImpostorSpaceCoordinate = (2.0*float2(impostorSpaceCoordinate)/float2(patchSize-1.0)-float2(1.0));          // imposter coordinate -1.0..1.0
  
  float3 imposterXYZ =  normalize(coordinateFromTexturePosition(newImpostorSpaceCoordinate));       // from the imposter coordinate, get the x,y,z coordinate in normalized coordinates
  
  // add the instance-position of the atom to get the Cartesian x,y,z position
  float3 pos = vert.sphere_radius.xyx * imposterXYZ +  vert.atomCenterPosition.xyz;
  
  float4 shadowCoordinate = shadowUniforms.shadowMatrix * float4(pos,1.0);                          // transform to the position in the shadow-map
  shadowCoordinate.y = 1.0 - shadowCoordinate.y;
  
  
  float4 shadowPos = shadowCoordinate/shadowCoordinate.w;
  
  float4 normal = shadowUniforms.normalMatrix * float4(imposterXYZ,1.0);
  
  
  if (normal.z < 0.0)
  {
    return 0.0;
  }
  
  // Write additional value to the framebuffer
  if (shadowMap.sample(shadowMapSampler, shadowPos.xy) >= shadowPos.z)
  {
    //return 1.0;
    return weight*normal.z;
  }

  return 0.0;
}


struct RibbonAODebugUniforms
{
  int mode;
  int textureWidth;
  int textureHeight;
  int patchNumber;
  float patchSize;
  float inverseTextureSize;
  float pad;
};


struct RibbonAOPatchUniforms
{
  int patchNumber;
  float patchSize;
  float inverseTextureSize;
  int pad;
};


struct RibbonAmbientOcclusionVertexShaderOut
{
  float4 position [[position]];
  float3 worldPosition;
  float3 worldNormal;
};


vertex RibbonAmbientOcclusionVertexShaderOut RibbonAmbientOcclusionVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                uint vid [[vertex_id]])
{
  RibbonAmbientOcclusionVertexShaderOut vert;
  float2 atlasUV = vertices[vid].st;
  float2 clipPos = atlasUV * 2.0 - 1.0;
  vert.position = float4(clipPos.x, -clipPos.y, 0.0, 1.0);
  
  float4 localPosition = vertices[vid].position;
  vert.worldPosition = (structureUniforms.modelMatrix * localPosition).xyz;
  float3 localNormal = vertices[vid].normal.xyz;
  vert.worldNormal = normalize((structureUniforms.modelMatrix * float4(localNormal, 0.0)).xyz);
  return vert;
}


fragment half RibbonAmbientOcclusionFragmentShader(RibbonAmbientOcclusionVertexShaderOut vert [[stage_in]],
                                                   constant ShadowUniforms& shadowUniforms [[buffer(0)]],
                                                   constant float& weight [[buffer(1)]],
                                                   depth2d<float> shadowMap [[texture(0)]],
                                                   sampler shadowMapSampler [[sampler(0)]])
{
  float3 pos = vert.worldPosition;
  float3 worldNormal = normalize(vert.worldNormal);
  
  float4 shadowCoordinate = shadowUniforms.shadowMatrix * float4(pos, 1.0);
  shadowCoordinate.y = 1.0 - shadowCoordinate.y;
  float4 shadowPos = shadowCoordinate / shadowCoordinate.w;
  
  float4 viewNormal = shadowUniforms.viewMatrix * float4(worldNormal, 0.0);
  float normalWeight = max(viewNormal.z, 0.0);
  if (normalWeight < 1.0e-4)
  {
    return 0.0;
  }
  
  // Along most of these directions the point being tested is itself the nearest surface, so its own
  // depth and the stored depth are the same number up to rounding and the linear filter used to read
  // it. Without a margin the surface shadows itself, and since that error can only ever remove light
  // it accumulates over every direction into occlusion that is not there.
  const float depthBias = RIBBON_AMBIENT_OCCLUSION_DEPTH_BIAS;
  if (shadowMap.sample(shadowMapSampler, shadowPos.xy) >= shadowPos.z - depthBias)
  {
    return weight * normalWeight;
  }
  return 0.0;
}


struct RibbonShadowMapVertexShaderOut
{
  float4 position [[position]];
  float4 eyePosition;
};


vertex RibbonShadowMapVertexShaderOut RibbonShadowMapVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                 constant ShadowUniforms& shadowUniforms [[buffer(1)]],
                                                                 constant StructureUniforms& structureUniforms [[buffer(2)]],
                                                                 uint vid [[vertex_id]])
{
  RibbonShadowMapVertexShaderOut vert;
  float4 localPosition = vertices[vid].position;
  vert.eyePosition = shadowUniforms.viewMatrix * structureUniforms.modelMatrix * localPosition;
  vert.position = shadowUniforms.projectionMatrix * vert.eyePosition;
  return vert;
}


fragment ShadowMapOutput RibbonShadowMapFragmentShader(RibbonShadowMapVertexShaderOut vert [[stage_in]])
{
  ShadowMapOutput output;
  output.depth = vert.position.z / vert.position.w;
  return output;
}


struct RibbonAOBlurUniforms
{
  float2 inverseTextureSize;
};


struct RibbonAOBlurVertexOut
{
  float4 position [[position]];
  float2 texCoord;
};


vertex RibbonAOBlurVertexOut ribbonAOBlurVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                       uint vid [[vertex_id]])
{
  RibbonAOBlurVertexOut vert;
  float4 position = float4(vertices[vid].position.xyz, 1.0);
  vert.position = position;
  // Match blurHorizontalVertexShader: fullscreen quad st is unset; derive UV from clip position.
  vert.texCoord = position.xy * float2(0.5) + float2(0.5);
  return vert;
}


fragment half ribbonAOBlurHorizontalFragmentShader(RibbonAOBlurVertexOut vert [[stage_in]],
                                                   constant RibbonAOBlurUniforms& blurUniforms [[buffer(0)]],
                                                   texture2d<half, access::sample> sourceTexture [[texture(0)]],
                                                   sampler sourceSampler [[sampler(0)]])
{
  float2 texCoord = vert.texCoord;
  float2 du = float2(blurUniforms.inverseTextureSize.x, 0.0);
  const float weights[8] = {
    0.159576912161, 0.147308056121, 0.115876621105, 0.0776744219933,
    0.0443683338718, 0.0215963866053, 0.00895781211794, 0.0044299121055113265
  };
  const float steps[7] = {8.0, 16.0, 24.0, 32.0, 40.0, 48.0, 56.0};
  
  float sum = float(sourceTexture.sample(sourceSampler, texCoord).r) * weights[0];
  for (int i = 0; i < 7; i++)
  {
    float2 offset = du * steps[i];
    sum += float(sourceTexture.sample(sourceSampler, texCoord - offset).r) * weights[i + 1];
    sum += float(sourceTexture.sample(sourceSampler, texCoord + offset).r) * weights[i + 1];
  }
  return half(sum);
}


fragment half ribbonAOBlurVerticalFragmentShader(RibbonAOBlurVertexOut vert [[stage_in]],
                                                  constant RibbonAOBlurUniforms& blurUniforms [[buffer(0)]],
                                                  texture2d<half, access::sample> sourceTexture [[texture(0)]],
                                                  sampler sourceSampler [[sampler(0)]])
{
  float2 texCoord = vert.texCoord;
  float2 dv = float2(0.0, blurUniforms.inverseTextureSize.y);
  const float weights[8] = {
    0.159576912161, 0.147308056121, 0.115876621105, 0.0776744219933,
    0.0443683338718, 0.0215963866053, 0.00895781211794, 0.0044299121055113265
  };
  const float steps[7] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0};
  
  float sum = float(sourceTexture.sample(sourceSampler, texCoord).r) * weights[0];
  for (int i = 0; i < 7; i++)
  {
    float2 offset = dv * steps[i];
    sum += float(sourceTexture.sample(sourceSampler, texCoord - offset).r) * weights[i + 1];
    sum += float(sourceTexture.sample(sourceSampler, texCoord + offset).r) * weights[i + 1];
  }
  return half(sum);
}

