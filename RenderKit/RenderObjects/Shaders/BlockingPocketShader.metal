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

struct BlockingPocketVertexShaderOut
{
  float4 position [[position]];
  
  float3 N;
  float3 V;
};

/// A blocking pocket is a sphere of a given radius in Angstrom around a position in the cell, so the
/// unit sphere mesh only needs the per-instance radius and centre; unlike the unit cell and the bounding
/// box there is no scaling of the geometry to keep it readable, the radius is the quantity of interest.
vertex BlockingPocketVertexShaderOut BlockingPocketSphereVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                      const device InPerInstanceAttributes *positions [[buffer(1)]],
                                                                      constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                      constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                      constant LightUniforms& lightUniforms [[buffer(4)]],
                                                                      uint vid [[vertex_id]],
                                                                      uint iid [[instance_id]])
{
  BlockingPocketVertexShaderOut vert;
  
  float4 pos = float4((positions[iid].scale * vertices[vid].position + positions[iid].position).xyz, 1.0);
  
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * vertices[vid].normal).xyz;
  
  float4 P = frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  return vert;
}

/// Both faces of the sphere are drawn, so the normal is flipped on the inside to keep the far wall of a
/// pocket shaded rather than black. The opacity travels in the alpha of the diffuse colour and the result
/// is premultiplied by it, which is what the blend state of the transparent pass expects.
fragment float4 BlockingPocketSphereFragmentShader(BlockingPocketVertexShaderOut vert [[stage_in]],
                                                   constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                   constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                   constant LightUniforms& lightUniforms [[buffer(2)]],
                                                   constant BlockingPocketUniforms& blockingPocketUniforms [[buffer(3)]],
                                                   bool frontfacing [[ front_facing ]])
{
  float3 N = normalize(vert.N);
  float3 V = normalize(vert.V);
  
  LightingWeights lighting = accumulateLighting(lightUniforms, frontfacing ? N : -N, V, float4(-vert.V, 1.0), blockingPocketUniforms.shininess);
  
  float3 ambient = lighting.ambient * blockingPocketUniforms.ambient.xyz;
  float3 diffuse = lighting.diffuse * blockingPocketUniforms.diffuse.xyz;
  float3 specular = lighting.specular * blockingPocketUniforms.specular.xyz;
  
  float4 color = float4(ambient + diffuse + specular, 1.0);
  if (blockingPocketUniforms.hdr)
  {
    color = 1.0 - exp2(-color * blockingPocketUniforms.hdrExposure);
  }
  
  float opacity = blockingPocketUniforms.diffuse.w;
  return opacity * float4(color.xyz, 1.0);
}
