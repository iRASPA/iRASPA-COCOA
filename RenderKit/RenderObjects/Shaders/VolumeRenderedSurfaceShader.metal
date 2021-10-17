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


struct VolumeRenderedVertexShaderOut
{
  float4 position [[position]];
  float4 pos;
  float3 UV;
  float3 N;
  float3 L;
  float3 V;
};


vertex VolumeRenderedVertexShaderOut VolumeRenderedSurfaceVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                constant FrameUniforms& frameUniforms [[buffer(1)]],
                                                constant StructureUniforms& structureUniforms [[buffer(2)]],
                                                constant IsosurfaceUniforms& isosurfaceUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]])
{
  VolumeRenderedVertexShaderOut vert;
  
  float4 pos = structureUniforms.modelMatrix * isosurfaceUniforms.boxMatrix * vertices[vid].position;
  vert.pos = pos;
  vert.position = frameUniforms.mvpMatrix * pos;
  vert.UV = vertices[vid].position.xyz;
  
  // Calculate normal in modelview-space
  vert.N = (frameUniforms.normalMatrix * structureUniforms.modelMatrix * isosurfaceUniforms.unitCellNormalMatrix * vertices[vid].normal).xyz;
  
  float4 P = frameUniforms.viewMatrix * pos;
  
  // Calculate light vector
  vert.L = (lightUniforms.lights[0].position - P*lightUniforms.lights[0].position.w).xyz;
  
  // Calculate view vector
  vert.V = -P.xyz;

  return vert;
}





// A very simple colour transfer function
float4 colour_transfer(float intensity)
{
  float3 high = float3(1.0, 1.0, 1.0);
  float3 low = float3(0.0, 0.0, 0.0);
  float alpha = (exp(intensity) - 1.0) / (exp(1.0) - 1.0);
  return float4(intensity * high + (1.0 - intensity) * low, alpha);
}



fragment float4 VolumeRenderedSurfaceFragmentShader(VolumeRenderedVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant IsosurfaceUniforms& isosurfaceUniforms [[buffer(2)]],
                                           texture3d<float> texture3D [[ texture(0) ]],
                                           texture1d<float> transferFunction [[ texture(1) ]],
                                           depth2d<float> depthTexture [[ texture(2) ]],
                                           sampler textureSampler [[ sampler(0) ]],
                                           sampler transferFunctionSampler [[ sampler(1) ]] ,
                                           uint sampleId [[sample_id]])
{
  float3 numberOfReplicas = structureUniforms.numberOfReplicas.xyz;
  const int numSamples = 100000;
  const float step_length = isosurfaceUniforms.stepLength/numberOfReplicas.z;
    
  // Normalize the incoming N, L and V vectors
  float3 direction = normalize(vert.pos.xyz - frameUniforms.cameraPosition.xyz);
  float4 dir = float4(direction.x,direction.y,direction.z,0.0);
  //float4 dir = float4(0,0,-1,0);
  float3 ray_direction = (isosurfaceUniforms.inverseBoxMatrix * dir).xyz;
  //float3 ray_direction = dir.xyz;
  
  float3 ray_origin = vert.UV;

  Ray casting_ray{ray_origin, ray_direction};
  AABB bounding_box{float3(1.0,1.0,1.0), float3(0.0,0.0,0.0)};
  float2 t = rayBoxIntersection(casting_ray, bounding_box);

  float3 ray_start = ray_origin + ray_direction * t.x;
  float3 ray_stop = ray_origin + ray_direction * t.y;

  float3 ray = ray_stop - ray_start;
  float ray_length = length(ray);
  float3 step_vector = step_length * ray / ray_length;

  float4 colour = float4(0.0,0.0,0.0,0.0);
  float3 position = ray_start;
  
  float depth = depthTexture.read(uint2(vert.position.xy));
  float newDepth = 1.0;
  float4x4 m = frameUniforms.mvpMatrix * structureUniforms.modelMatrix * isosurfaceUniforms.boxMatrix;
  
  for (int i=0; i < numSamples && ray_length > 0 && colour.a < 1.0; i++)
  {
    float4 values = texture3D.sample(textureSampler, numberOfReplicas * position);
    float3 normal = normalize(float3(values.gba));

    float4 c = transferFunction.sample(transferFunctionSampler,values.r);

    float3 R = reflect(-direction, normal);
    float3 ambient = float3(0.3,0.3,0.3);
    float3 diffuse = float3(max(abs(dot(normal, direction)),0.0));
    float3 specular = float3(pow(max(dot(R, direction), 0.0), 0.4));

    // Alpha-blending
    colour.rgb = c.a * (ambient+diffuse+specular) * c.rgb + (1 - c.a) * colour.a * colour.rgb;
    //colour.rgb = c.a * c.rgb + (1 - c.a) * colour.a * colour.rgb;
    colour.a = c.a + (1 - c.a) * colour.a;

    position = position + step_vector;
    ray_length -= step_length;
    
    float4 clipPosition = m * float4(position,1.0);
    newDepth = (clipPosition.z / clipPosition.w);
    if(newDepth>depth)
    {
      break;
    }
  }
  
  if(colour.a<0.99)
  {
    discard_fragment();
  }
  
  return float4(1.0 - exp2(-colour.rgb * 1.5), colour.a);
}
