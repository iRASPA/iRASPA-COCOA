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


struct PickingVertexShaderOut
{
  float4 position [[position]];
  float4 eye_position;
  float2 texcoords;
  float3 frag_pos ;
  float3 frag_center [[ flat]];
  float4 sphere_radius [[ flat ]];
  int instanceId [[ flat ]];
};


typedef struct
{
  uint4 albedo [[color(0)]];
  float  depth [[depth(less)]];
} PickingFragOutput;

vertex PickingVertexShaderOut AtomSpherePickingVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                    const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                    constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                    constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                    uint vid [[vertex_id]],
                                                    uint iid [[instance_id]])
{
  PickingVertexShaderOut vert;
  
  vert.instanceId = positions[iid].tag;
  float4 scale = structureUniforms.atomScaleFactor * positions[iid].scale;
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = structureUniforms.atomScaleFactor * positions[iid].scale;
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  pos2.xy += scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  
  vert.frag_pos = pos2.xyz;
  
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}



fragment PickingFragOutput AtomSpherePickingFragmentShader(PickingVertexShaderOut vert [[stage_in]],
                                                    constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                    constant StructureUniforms& structureUniforms [[buffer(1)]])
{
  PickingFragOutput output;
  
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

  output.albedo = uint4(1,0,structureUniforms.structureIdentifier, vert.instanceId);
  
  return output;

}


struct PickingBondVertexShaderOut
{
  float4 position [[position]];
  int instanceId [[ flat ]];
};

typedef struct
{
  uint4 albedo [[color(0)]];
} PickingBondFragOutput;


vertex PickingBondVertexShaderOut PickingInternalBondCylinderVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  PickingBondVertexShaderOut vert;
  
  float4 scale = positions[iid].scale;
  float4 pos =  vertices[vid].position;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  float3 dr = (pos2 - pos1).xyz;
  float bondLength = length(dr);
  
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
  
  vert.instanceId = positions[iid].tag;
  vert.position = frameUniforms.mvpMatrix *  structureUniforms.modelMatrix * (orientationMatrix * (scale * pos) + pos1);
  
  return vert;
}



fragment PickingBondFragOutput PickingInternalBondCylinderFragmentShader(PickingBondVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]])
{
  PickingBondFragOutput output;
  
  output.albedo = uint4(2,0,structureUniforms.structureIdentifier, vert.instanceId);
  return output;
}



struct PickingExternalBondVertexShaderOut
{
  float4 position [[position]];
  int instanceId [[ flat ]];
  
  float clipDistance0 [[ center_perspective ]];
  float clipDistance1 [[ center_perspective ]];
  float clipDistance2 [[ center_perspective ]];
  float clipDistance3 [[ center_perspective ]];
  float clipDistance4 [[ center_perspective ]];
  float clipDistance5 [[ center_perspective ]];
};

vertex PickingExternalBondVertexShaderOut PickingExternalBondVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  float3 v1,v2;
  PickingExternalBondVertexShaderOut vert;
  
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

  vert.instanceId =  positions[iid].tag;
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * vertexPos;
  
  vert.clipDistance0 = dot(structureUniforms.clipPlaneLeft,vertexPos);
  vert.clipDistance1 = dot(structureUniforms.clipPlaneRight,vertexPos);
  vert.clipDistance2 = dot(structureUniforms.clipPlaneTop,vertexPos);
  
  vert.clipDistance3 = dot(structureUniforms.clipPlaneBottom,vertexPos);
  vert.clipDistance4 = dot(structureUniforms.clipPlaneFront,vertexPos);
  vert.clipDistance5 = dot(structureUniforms.clipPlaneBack,vertexPos);
  
  return vert;
}

fragment PickingBondFragOutput PickingExternalBondFragmentShader(PickingExternalBondVertexShaderOut vert [[stage_in]],
                                                   constant StructureUniforms& structureUniforms [[buffer(0)]])
{
  PickingBondFragOutput output;
  
  // [[ clip_distance ]] appears to working only for two clipping planes
  // work-around: brute-force 'discard_fragment'
  if (vert.clipDistance0 < 0.0) discard_fragment();
  if (vert.clipDistance1 < 0.0) discard_fragment();
  if (vert.clipDistance2 < 0.0) discard_fragment();
  if (vert.clipDistance3 < 0.0) discard_fragment();
  if (vert.clipDistance4 < 0.0) discard_fragment();
  if (vert.clipDistance5 < 0.0) discard_fragment();
  
  output.albedo = uint4(2,0,structureUniforms.structureIdentifier, vert.instanceId);
  return output;
}


vertex PickingVertexShaderOut PickingPolygonalPrismVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                             const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                             constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                             constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                             constant LightUniforms& lightUniforms [[buffer(4)]],
                                                             uint vid [[vertex_id]],
                                                             uint iid [[instance_id]])
{
  PickingVertexShaderOut vert;
  
  vert.instanceId = positions[iid].tag;
  float4 pos = structureUniforms.transformationMatrix * vertices[vid].position + positions[iid].position;
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}




fragment PickingBondFragOutput PickingPolygonalPrismFragmentShader(PickingVertexShaderOut vert [[stage_in]],
                                              constant StructureUniforms& structureUniforms [[buffer(0)]])
                                              
{
  PickingBondFragOutput output;
  
  output.albedo = uint4(1,0,structureUniforms.structureIdentifier, vert.instanceId);
  return output;
}
