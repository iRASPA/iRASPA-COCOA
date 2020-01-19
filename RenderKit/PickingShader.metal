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


struct PickingVertexShaderOut
{
  float4 position [[position]];
  float4 eye_position;
  float2 texcoords;
  float3 frag_pos ;
  float3 frag_center [[ flat]];
  float4 sphere_radius [[ flat ]];
  float k1 [[ flat ]];
  float k2 [[ flat ]];
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
  
  vert.instanceId = iid;
  float4 scale = structureUniforms.atomScaleFactor * positions[iid].scale;
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
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

  output.albedo = uint4(1,structureUniforms.sceneIdentifier,structureUniforms.MovieIdentifier, vert.instanceId);
  
  return output;

}

vertex PickingVertexShaderOut LicoriceSpherePickingVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                            const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                            constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                            constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                            uint vid [[vertex_id]],
                                                            uint iid [[instance_id]])
{
  PickingVertexShaderOut vert;
  
  vert.instanceId = iid;
  
  float scaleFactor = structureUniforms.selectionScaling * 0.15*structureUniforms.bondScaling;
  float4 scale = float4(scaleFactor,scaleFactor,scaleFactor,1.0);
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  
  vert.texcoords = vertices[vid].position.xy;
  vert.sphere_radius = scale;
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * positions[iid].position;
  pos2.xy += scale.xy * float2(vertices[vid].position.x,vertices[vid].position.y);
  
  vert.frag_pos = pos2.xyz;
  
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  uint patchNumber=structureUniforms.ambientOcclusionPatchNumber;
  vert.k1=iid%patchNumber;
  vert.k2=iid/patchNumber;
  
  return vert;
}



fragment PickingFragOutput LicoriceSpherePickingFragmentShader(PickingVertexShaderOut vert [[stage_in]],
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
  
  output.albedo = uint4(1,structureUniforms.sceneIdentifier,structureUniforms.MovieIdentifier, vert.instanceId);
  
  return output;
  
}

