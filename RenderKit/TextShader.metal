/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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


vertex AtomSphereImposterVertexShaderOut textVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                          const device InPerInstanceTextAttributes *instanceData [[buffer(1)]],
                                          constant FrameUniforms& frameUniforms [[buffer(2)]],
                                          constant StructureUniforms& structureUniforms [[buffer(3)]],
                                          constant LightUniforms& lightUniforms [[buffer(4)]],
                                          uint vid [[vertex_id]],
                                          uint iid [[instance_id]])
{
  AtomSphereImposterVertexShaderOut outVert;
  float4 pos2 = frameUniforms.viewMatrix * structureUniforms.modelMatrix * instanceData[iid].position;
  
  outVert.eye_position = pos2;
  outVert.sphere_radius = structureUniforms.atomScaleFactor * instanceData[iid].scale;
  
  pos2.x += structureUniforms.atomAnnotationTextScaling * instanceData[iid].vertexPosition[vid/2];
  pos2.y -= structureUniforms.atomAnnotationTextScaling * instanceData[iid].vertexPosition[vid%2 + 2];
  
  pos2.xy += structureUniforms.atomAnnotationTextDisplacement.xy;
  
  outVert.position = frameUniforms.projectionMatrix * pos2;
  outVert.texcoords.x = instanceData[iid].st[vid/2];
  outVert.texcoords.y = instanceData[iid].st[vid%2 + 2];
  
  return outVert;
}

fragment FragOutput textFragmentShader(AtomSphereImposterVertexShaderOut vert [[stage_in]],
                                       constant FrameUniforms& frameUniforms [[buffer(1)]],
                                       constant StructureUniforms& structureUniforms [[buffer(2)]],
                              sampler samplr [[sampler(0)]],
                              texture2d<float, access::sample> texture [[texture(0)]])
{
  FragOutput output;
  
  float4 pos = vert.eye_position;
  pos.z += vert.sphere_radius.z + structureUniforms.atomAnnotationTextDisplacement.z;
  pos = frameUniforms.projectionMatrix * pos;
  output.depth = (pos.z / pos.w);
  
  float4 color = structureUniforms.atomAnnotationTextColor;
  // Outline of glyph is the isocontour with value 50%
  float edgeDistance = 0.5;
  // Sample the signed-distance field to find distance from this fragment to the glyph outline
  float sampleDistance = texture.sample(samplr, vert.texcoords).r;
  // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
  float edgeWidth = 0.75 * length(float2(dfdx(sampleDistance), dfdy(sampleDistance)));
  // Smooth the glyph edge by interpolating across the boundary in a band with the width determined above
  float insideness = smoothstep(edgeDistance - edgeWidth, edgeDistance + edgeWidth, sampleDistance);
  output.albedo = float4(color.r * insideness, color.g * insideness, color.b * insideness, insideness);
  
  return output;
}
