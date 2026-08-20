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
  float4 scale = (structureUniforms.isUnity ? structureUniforms.bondScaling : 1.0) * structureUniforms.atomScaleFactor * positions[iid].scale;
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
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

vertex PickingVertexShaderOut AtomSpherePickingPerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                    const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                    constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                    constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                    uint vid [[vertex_id]],
                                                    uint iid [[instance_id]])
{
  PickingVertexShaderOut vert;
  
  vert.instanceId = positions[iid].tag;
  float4 scale = (structureUniforms.isUnity ? structureUniforms.bondScaling : 1.0) * structureUniforms.atomScaleFactor * positions[iid].scale;
  
  vert.frag_center = (frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position).xyz;
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x, vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

fragment PickingFragOutput AtomSpherePickingPerspectiveFragmentShader(PickingVertexShaderOut vert [[stage_in]],
                                                              constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                              constant StructureUniforms& structureUniforms [[buffer(1)]])
{
  PickingFragOutput output;
  
  float3 rij = -vert.frag_center;
  float3 vij = vert.frag_pos;
  
  float A = dot(vij, vij);
  float B = 2.0 * dot(rij, vij);
  float C = dot(rij, rij) - vert.sphere_radius.z * vert.sphere_radius.z;
  float argument = B * B - 4.0 * A * C;
  if (argument < 0.0)
    discard_fragment();
  float t = 0.5 * (-B - sqrt(argument)) / A;
  
  float3 hit = t * vij;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  output.albedo = uint4(1,0,structureUniforms.structureIdentifier, vert.instanceId);
  
  return output;
}

typedef struct
{
  uint4 albedo [[color(0)]];
} PickingBondFragOutput;


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


struct RibbonPickingVertexShaderOut
{
  float4 position [[position]];
  uint segmentIndex [[flat]];
  uint residueIndex [[flat]];
};


vertex RibbonPickingVertexShaderOut RibbonPickingVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                              constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                              constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                              uint vid [[vertex_id]])
{
  RibbonPickingVertexShaderOut vert;
  float4 pos = vertices[vid].position;
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  vert.segmentIndex = uint(vertices[vid].normal.w);
  vert.residueIndex = uint(vertices[vid].pad.y);
  return vert;
}


fragment PickingFragOutput RibbonPickingFragmentShader(RibbonPickingVertexShaderOut vert [[stage_in]],
                                                       constant StructureUniforms& structureUniforms [[buffer(1)]])
{
  PickingFragOutput output;
  output.depth = vert.position.z / vert.position.w;
  // type 3 = ribbon; z = secondary-structure segment index, w = residue index
  output.albedo = uint4(3, structureUniforms.structureIdentifier, vert.segmentIndex, vert.residueIndex);
  return output;
}
