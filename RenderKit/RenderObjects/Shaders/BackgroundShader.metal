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
#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>

#include <metal_stdlib>
#include "Common.h"
using namespace metal;


struct BackgroundVertexShaderOut
{
  float4 m_Position [[position]];
  float2 m_TexCoord [[user(texturecoord)]];
};


vertex BackgroundVertexShaderOut backgroundQuadVertex(const device InPerVertex *pPosition [[ buffer(0) ]],
                                                      uint vid [[ vertex_id ]])
{
  BackgroundVertexShaderOut outVertices;
  
  outVertices.m_Position = pPosition[vid].position;
  outVertices.m_TexCoord = pPosition[vid].position.xy * float2(0.5,-0.5) + float2(0.5);
  
  return outVertices;
}

fragment half4 backgroundQuadFragment(BackgroundVertexShaderOut inFrag [[ stage_in ]],
                                      texture2d<half> tex2D [[ texture(0) ]],
                                      constant FrameUniforms& frameUniforms [[buffer(0)]],
                                      sampler quadSampler [[ sampler(0) ]])
{
  half4 color = tex2D.sample(quadSampler, inFrag.m_TexCoord);
  //color.r = 0.0;
  //color.g = 1.0;
  //color.b = 0.0;
  //color.w = 0.5;
  return color;
}
