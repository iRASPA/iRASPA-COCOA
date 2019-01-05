/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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


