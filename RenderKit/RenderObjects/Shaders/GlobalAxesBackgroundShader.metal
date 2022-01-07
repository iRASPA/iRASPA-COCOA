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


vertex BackgroundVertexShaderOut globalAxesBackgroundQuadVertex(const device InPerVertex *pPosition [[ buffer(0) ]],
                                                                constant GlobalAxesUniforms& axesUniforms [[buffer(1)]],
                                                                uint vid [[ vertex_id ]])
{
  BackgroundVertexShaderOut outVertices;
  outVertices.m_Position = pPosition[vid].position;
  outVertices.m_TexCoord = pPosition[vid].position.xy * float2(0.5,-0.5) + float2(0.5);
  
  return outVertices;
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float Sphere(float2 p, float s)
{
  return length(p)-s;
}

float RoundedBox( float2 p, float2 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float RoundedBoxBorder( float2 p, float2 b, float r, float borderFactor )
{
  return max(-RoundedBox(p, b*borderFactor, r), RoundedBox(p, b, r));
}

float Rectangle(float2 uv, float2 pos, float2 size)
{
  return (step(pos.x, uv.x)         - step(pos.x + size.x,uv.x))
       * (step(pos.y - size.y,uv.y) - step(pos.y, uv.y));
}

fragment float4 globalAxesBackgroundQuadFragment(BackgroundVertexShaderOut inFrag [[ stage_in ]],
                                      constant FrameUniforms& frameUniforms [[buffer(0)]],
                                      constant GlobalAxesUniforms& axesUniforms [[buffer(1)]])
{
  float alpha = axesUniforms.axesBackgroundColor.w;
  switch(axesUniforms.axesBackGroundStyle)
  {
    case 0:
      alpha = 0.0;
    case 1: // filled circle
      if (Sphere(inFrag.m_TexCoord - float2(0.5,0.5), 0.5) > 0.0)
        alpha = 0.0;
    case 2: // filled square
      break;
    case 3:  // filled square
      if(RoundedBox(inFrag.m_TexCoord - float2(0.5,0.5), float2(0.3,0.3), 0.2 )>0.0)
        alpha = 0.0;
      break;
    case 4:  // circle
      if (max(-Sphere(inFrag.m_TexCoord - float2(0.5,0.5), 0.48), Sphere(inFrag.m_TexCoord - float2(0.5,0.5), 0.5)) > 0.0)
        alpha = 0.0;
      break;
    case 5:  // square
      if(Rectangle(inFrag.m_TexCoord- float2(0.5,0.5), float2(-0.48,0.48), 0.96) > 0.0)
        alpha = 0.0;
      break;
    case 6:  //  rounded square
      if(max(-RoundedBox(inFrag.m_TexCoord - float2(0.5,0.5), float2(0.30,0.30), 0.17 ), RoundedBox(inFrag.m_TexCoord - float2(0.5,0.5), float2(0.3,0.3), 0.2 ))>0.0)
        alpha = 0.0;
    default:
      break;
  }
 
  
  return float4(axesUniforms.axesBackgroundColor.x * alpha,
                axesUniforms.axesBackgroundColor.y * alpha,
                axesUniforms.axesBackgroundColor.z * alpha,
                alpha);
}
