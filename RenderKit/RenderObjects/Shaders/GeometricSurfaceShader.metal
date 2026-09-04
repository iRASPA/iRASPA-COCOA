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

// Geometric accessible surface: each patch is the exposed part of one probe-inflated atom, drawn as
// a sphere imposter. The fragment shader reconstructs the ray-sphere hit and discards the fragment
// where that point lies inside a neighbouring inflated atom, which is exactly the spherical cap the
// exact surface-area sweep integrates around.

struct GeometricSurfaceImposterVertexOut
{
  float4 position [[position]];
  float4 eye_position;
  float4 instancePosition [[flat]];
  float2 texcoords;
  float3 frag_pos;
  float3 frag_center [[flat]];
  float3 V;
  float4 sphere_radius [[flat]];
  uint firstClip [[flat]];
  uint clipCount [[flat]];
  uint clipToCell [[flat]];
  float3 cellOrigin [[flat]];
  float4 modelFromView1 [[flat]];
  float4 modelFromView2 [[flat]];
  float4 modelFromView3 [[flat]];
  float4 modelFromView4 [[flat]];
};

vertex GeometricSurfaceImposterVertexOut GeometricSurfaceOrthographicVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                  const device GeometricSurfacePatchInstance *patches [[buffer(1)]],
                                                                                  constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                  constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                  uint vid [[vertex_id]],
                                                                                  uint iid [[instance_id]])
{
  GeometricSurfaceImposterVertexOut vert;
  
  float4 scale = patches[iid].scale;
  vert.instancePosition = patches[iid].position;
  vert.firstClip = patches[iid].firstClip;
  vert.clipCount = patches[iid].clipCount;
  vert.clipToCell = patches[iid].clipToCell;
  vert.cellOrigin = patches[iid].cellOrigin.xyz;
  vert.sphere_radius = scale;
  
  float4x4 modelFromView = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.modelFromView1 = modelFromView[0];
  vert.modelFromView2 = modelFromView[1];
  vert.modelFromView3 = modelFromView[2];
  vert.modelFromView4 = modelFromView[3];
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * patches[iid].position;
  vert.V = -vert.eye_position.xyz;
  vert.frag_center = vert.eye_position.xyz;
  vert.texcoords = vertices[vid].position.xy;
  
  float4 pos2 = vert.eye_position;
  pos2.xy += scale.xy * float2(vertices[vid].position.x, vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

vertex GeometricSurfaceImposterVertexOut GeometricSurfacePerspectiveVertexShader(const device InPerVertex *vertices [[buffer(0)]],
                                                                                 const device GeometricSurfacePatchInstance *patches [[buffer(1)]],
                                                                                 constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                                                 constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                 uint vid [[vertex_id]],
                                                                                 uint iid [[instance_id]])
{
  GeometricSurfaceImposterVertexOut vert;
  
  float4 scale = patches[iid].scale;
  vert.instancePosition = patches[iid].position;
  vert.firstClip = patches[iid].firstClip;
  vert.clipCount = patches[iid].clipCount;
  vert.clipToCell = patches[iid].clipToCell;
  vert.cellOrigin = patches[iid].cellOrigin.xyz;
  vert.sphere_radius = scale;
  
  float4x4 modelFromView = transpose(frameUniforms.normalMatrix * structureUniforms.modelMatrix);
  vert.modelFromView1 = modelFromView[0];
  vert.modelFromView2 = modelFromView[1];
  vert.modelFromView3 = modelFromView[2];
  vert.modelFromView4 = modelFromView[3];
  
  vert.eye_position = frameUniforms.viewMatrix * structureUniforms.modelMatrix * patches[iid].position;
  vert.V = -vert.eye_position.xyz;
  vert.frag_center = vert.eye_position.xyz;
  vert.texcoords = vertices[vid].position.xy;
  
  float4 pos2 = vert.eye_position;
  pos2.xy += 1.5 * scale.xy * float2(vertices[vid].position.x, vertices[vid].position.y);
  vert.frag_pos = pos2.xyz;
  vert.position = frameUniforms.projectionMatrix * pos2;
  
  return vert;
}

static bool geometricSurfaceHitIsInsideCell(float3 hitModel,
                                            float3 cellOrigin,
                                            constant IsosurfaceUniforms& isosurfaceUniforms)
{
  // Fractional coordinates of the hit in the instance's unit cell. Keeping [0, 1) and drawing the
  // lattice-translated copy of anything that stuck out puts the overflow on the opposite face
  // instead of outside the box, and avoids drawing the identified faces twice.
  float3 frac = (isosurfaceUniforms.inverseUnitCellMatrix * float4(hitModel - cellOrigin, 1.0)).xyz;
  return frac.x >= 0.0 && frac.x < 1.0 &&
         frac.y >= 0.0 && frac.y < 1.0 &&
         frac.z >= 0.0 && frac.z < 1.0;
}

static bool geometricSurfaceHitIsExposed(float3 hitModel,
                                         uint firstClip,
                                         uint clipCount,
                                         const device GeometricSurfaceClip *clips)
{
  // A point of this atom's sphere is on the union's boundary iff it is not strictly inside any
  // neighbouring inflated atom. The intersection circle belongs to both patches and is kept.
  const uint count = min(clipCount, 64u);
  for (uint i = 0; i < count; ++i)
  {
    float4 sphere = clips[firstClip + i].sphere;
    float3 delta = hitModel - sphere.xyz;
    float radius = sphere.w;
    if (dot(delta, delta) < radius * radius)
    {
      return false;
    }
  }
  return true;
}

static bool geometricSurfaceHitIsValid(float3 hitModel,
                                       uint clipToCell,
                                       float3 cellOrigin,
                                       uint firstClip,
                                       uint clipCount,
                                       const device GeometricSurfaceClip *clips,
                                       constant IsosurfaceUniforms& isosurfaceUniforms)
{
  if (clipToCell != 0u && !geometricSurfaceHitIsInsideCell(hitModel, cellOrigin, isosurfaceUniforms))
  {
    return false;
  }
  return geometricSurfaceHitIsExposed(hitModel, firstClip, clipCount, clips);
}

static float4 shadeGeometricSurface(float3 N,
                                    float3 V,
                                    float4 surfaceEyePosition,
                                    bool frontfacing,
                                    constant LightUniforms& lightUniforms,
                                    constant IsosurfaceUniforms& isosurfaceUniforms)
{
  float3 normal = frontfacing ? N : -N;
  LightingWeights lighting = accumulateLighting(lightUniforms, normal, V, surfaceEyePosition,
                                                frontfacing ? isosurfaceUniforms.shininessFrontSide : isosurfaceUniforms.shininessBackSide);
  
  float4 ambient = float4(lighting.ambient, 1.0) * (frontfacing ? isosurfaceUniforms.ambientFrontSide : isosurfaceUniforms.ambientBackSide);
  float4 diffuse = float4(lighting.diffuse, 1.0) * (frontfacing ? isosurfaceUniforms.diffuseFrontSide : isosurfaceUniforms.diffuseBackSide);
  float4 specular = float4(lighting.specular, 1.0) * (frontfacing ? isosurfaceUniforms.specularFrontSide : isosurfaceUniforms.specularBackSide);
  
  float4 color = float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  bool hdr = frontfacing ? isosurfaceUniforms.frontHDR : isosurfaceUniforms.backHDR;
  float exposure = frontfacing ? isosurfaceUniforms.frontHDRExposure : isosurfaceUniforms.backHDRExposure;
  if (hdr)
  {
    color = 1.0 - exp2(-color * exposure);
    color.a = 1.0;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * isosurfaceUniforms.hue;
  hsv.y = hsv.y * isosurfaceUniforms.saturation;
  hsv.z = hsv.z * isosurfaceUniforms.value;
  float opacity = isosurfaceUniforms.diffuseFrontSide.w;
  return float4(hsv2rgb(hsv) * opacity, opacity);
}

fragment FragOutput GeometricSurfaceOrthographicFragmentShader(GeometricSurfaceImposterVertexOut vert [[stage_in]],
                                                               constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                               constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                               constant IsosurfaceUniforms& isosurfaceUniforms [[buffer(2)]],
                                                               constant LightUniforms& lightUniforms [[buffer(3)]],
                                                               const device GeometricSurfaceClip *clips [[buffer(4)]])
{
  FragOutput output;
  
  float x = vert.texcoords.x;
  float y = vert.texcoords.y;
  float zz = 1.0 - x * x - y * y;
  if (zz <= 0.0)
  {
    discard_fragment();
  }
  float z = sqrt(zz);
  
  // The billboard always faces the camera, so `front_facing` is not the surface's front/back.
  // A patch can sit on either hemisphere: try the near hit, then the far one, so the same
  // sheet is visible from both sides instead of vanishing when the atom is between you and it.
  float4x4 modelFromView = float4x4(vert.modelFromView1, vert.modelFromView2, vert.modelFromView3, vert.modelFromView4);
  float3 N = float3(x, y, z);
  float3 hitModel = vert.instancePosition.xyz + (modelFromView * (vert.sphere_radius * float4(N, 1.0))).xyz;
  float4 pos = vert.eye_position;
  bool frontfacing = true;
  if (geometricSurfaceHitIsValid(hitModel, vert.clipToCell, vert.cellOrigin, vert.firstClip, vert.clipCount, clips, isosurfaceUniforms))
  {
    pos.z += vert.sphere_radius.z * z;
  }
  else
  {
    N = float3(x, y, -z);
    hitModel = vert.instancePosition.xyz + (modelFromView * (vert.sphere_radius * float4(N, 1.0))).xyz;
    if (!geometricSurfaceHitIsValid(hitModel, vert.clipToCell, vert.cellOrigin, vert.firstClip, vert.clipCount, clips, isosurfaceUniforms))
    {
      discard_fragment();
    }
    pos.z -= vert.sphere_radius.z * z;
    frontfacing = false;
  }
  
  float4 projected = frameUniforms.projectionMatrix * pos;
  output.depth = projected.z / projected.w;
  
  float3 V = normalize(vert.V);
  output.albedo = shadeGeometricSurface(N, V, pos, frontfacing, lightUniforms, isosurfaceUniforms);
  return output;
}

fragment FragOutput GeometricSurfacePerspectiveFragmentShader(GeometricSurfaceImposterVertexOut vert [[stage_in]],
                                                              constant FrameUniforms& frameUniforms [[buffer(0)]],
                                                              constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                              constant IsosurfaceUniforms& isosurfaceUniforms [[buffer(2)]],
                                                              constant LightUniforms& lightUniforms [[buffer(3)]],
                                                              const device GeometricSurfaceClip *clips [[buffer(4)]])
{
  FragOutput output;
  
  float3 rij = -vert.frag_center;
  float3 vij = vert.frag_pos;
  float A = dot(vij, vij);
  float B = 2.0 * dot(rij, vij);
  float C = dot(rij, rij) - vert.sphere_radius.z * vert.sphere_radius.z;
  float argument = B * B - 4.0 * A * C;
  if (argument < 0.0)
  {
    discard_fragment();
  }
  float disc = sqrt(argument);
  float tNear = 0.5 * (-B - disc) / A;
  float tFar = 0.5 * (-B + disc) / A;
  
  float4x4 modelFromView = float4x4(vert.modelFromView1, vert.modelFromView2, vert.modelFromView3, vert.modelFromView4);
  
  float t = tNear;
  float3 hit = t * vij;
  float3 N = normalize(hit - vert.frag_center);
  float3 hitModel = vert.instancePosition.xyz + (modelFromView * (vert.sphere_radius * float4(N, 1.0))).xyz;
  bool frontfacing = true;
  bool nearOK = tNear > 0.0 && geometricSurfaceHitIsValid(hitModel, vert.clipToCell, vert.cellOrigin, vert.firstClip, vert.clipCount, clips, isosurfaceUniforms);
  if (!nearOK)
  {
    t = tFar;
    hit = t * vij;
    N = normalize(hit - vert.frag_center);
    hitModel = vert.instancePosition.xyz + (modelFromView * (vert.sphere_radius * float4(N, 1.0))).xyz;
    if (tFar <= 0.0 || !geometricSurfaceHitIsValid(hitModel, vert.clipToCell, vert.cellOrigin, vert.firstClip, vert.clipCount, clips, isosurfaceUniforms))
    {
      discard_fragment();
    }
    frontfacing = false;
  }
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(hit, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 V = normalize(vert.V);
  output.albedo = shadeGeometricSurface(N, V, float4(hit, 1.0), frontfacing, lightUniforms, isosurfaceUniforms);
  return output;
}
