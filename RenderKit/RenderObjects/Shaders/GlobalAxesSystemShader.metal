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

vertex AxesVertexShaderOut GlobalAxesSystemVertexShader(const device InPrimitivePerVertex *vertices [[buffer(0)]],
                                              constant FrameUniforms& frameUniforms [[buffer(1)]],
                                              constant LightUniforms& lightUniforms [[buffer(2)]],
                                              constant GlobalAxesUniforms& axesUniforms [[buffer(3)]],
                                              uint vid [[vertex_id]])
{
  AxesVertexShaderOut vert;
  
  float4 scale = float4(axesUniforms.axesScale,axesUniforms.axesScale,axesUniforms.axesScale,1);
  float4 pos =  scale * vertices[vid].position + float4(0.0,0.0,0.0,1.0);
  
  
  vert.N = (frameUniforms.normalMatrix * vertices[vid].normal).xyz;
  vert.Model_N = vertices[vid].normal.xyz;
  
  vert.ambient = vertices[vid].color * 0.2;
  vert.diffuse = vertices[vid].color;
  vert.specular = float4(0.5,0.5,0.5,1.0);
  
  float4 P =  frameUniforms.axesViewMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
            
  // Calculate view vector
  vert.V = -P.xyz;
  
  vert.position = frameUniforms.axesMvpMatrix * pos;
  
  return vert;
}

fragment float4 GlobalAxesSystemFragmentShader(AxesVertexShaderOut vert [[stage_in]],
                                         constant FrameUniforms& frameUniforms [[buffer(1)]],
                                         constant LightUniforms& lightUniforms [[buffer(2)]])
{
  // Normalize the incoming N, L and V vectors
  float3 N = normalize(vert.N);
  float3 L = normalize(vert.L);
  float3 V = normalize(vert.V);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  // Compute the diffuse and specular components for each fragment
  float3 ambient = vert.ambient.xyz;
  float3 diffuse = max(dot(N, L), 0.0) * vert.diffuse.xyz;
  float3 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess) * vert.specular.xyz;
  
  float4 color= float4((ambient.xyz + diffuse.xyz + specular.xyz), 1.0);
  
  float4 vLdrColor = 1.0 - exp2(-color * 1.5);
  vLdrColor.a = 1.0;
  color= vLdrColor;
    
  return color;
}
