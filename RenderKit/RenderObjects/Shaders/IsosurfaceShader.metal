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


struct IsosurfaceVertexShaderOut
{
  float4 position [[position]];
  float3 N;
  float3 L;
  float3 V;
};


vertex IsosurfaceVertexShaderOut IsosurfaceVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                const device float4 *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant IsosurfaceUniforms& isosurfaceUniforms [[buffer(4)]],
                                                constant LightUniforms& lightUniforms [[buffer(5)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  IsosurfaceVertexShaderOut vert;
  
  float4 pos = isosurfaceUniforms.unitCellMatrix * (vertices[vid].position + positions[iid]);
  vert.position = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate normal in modelview-space
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * isosurfaceUniforms.unitCellNormalMatrix * vertices[vid].normal).xyz;
  
  float4 P = frameUniforms.viewMatrix * structureUniforms.modelMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;

  return vert;
}




fragment float4 IsosurfaceFragmentShader(IsosurfaceVertexShaderOut vert [[stage_in]],
                                         constant FrameUniforms& frameUniforms [[buffer(0)]],
                                         constant StructureUniforms& structureUniforms [[buffer(1)]],
                                         constant IsosurfaceUniforms& isosurfaceUniforms [[buffer(2)]],
                                         bool frontfacing [[ front_facing ]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  
  float4 ambient;
  float4 diffuse;
  float4 specular;
  float4 color;
  
  if (!frontfacing)
  {
    float3 R = reflect(-L, -N);
    ambient = isosurfaceUniforms.ambientBackSide;
    diffuse = max(dot(-N, L), 0.0) * isosurfaceUniforms.diffuseBackSide;
    specular = pow(max(dot(R, V), 0.0), isosurfaceUniforms.shininessBackSide) * isosurfaceUniforms.specularBackSide;
    
    color = float4((ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
    if (isosurfaceUniforms.backHDR)
    {
      float4 vLdrColor = 1.0 - exp2(-color * isosurfaceUniforms.backHDRExposure);
      vLdrColor.a = 1.0;
      color = vLdrColor;
    }
  }
  else
  {
    float3 R = reflect(-L, N);
    ambient = isosurfaceUniforms.ambientFrontSide;
    diffuse = max(dot(N, L), 0.0) * isosurfaceUniforms.diffuseFrontSide;
    specular = pow(max(dot(R, V), 0.0), isosurfaceUniforms.shininessFrontSide) * isosurfaceUniforms.specularFrontSide;
    
    color= float4((ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
    if (isosurfaceUniforms.frontHDR)
    {
      float4 vLdrColor = 1.0 - exp2(-color * isosurfaceUniforms.frontHDRExposure);
      vLdrColor.a = 1.0;
      color = vLdrColor;
    }
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * isosurfaceUniforms.hue;
  hsv.y = hsv.y * isosurfaceUniforms.saturation;
  hsv.z = hsv.z * isosurfaceUniforms.value;
  return float4(hsv2rgb(hsv) * isosurfaceUniforms.diffuseFrontSide.w,isosurfaceUniforms.diffuseFrontSide.w);

  
  return color;
  
}
