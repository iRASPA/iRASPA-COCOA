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

// MARK: Bond cylinder imposters
// =============================================================================
// Ray-traced cylinder imposters (ported from the RibbonRendering cylinder
// imposter shaders). Each (sub-)cylinder is drawn as a view-aligned hull of
// three quads (18 vertices, generated from the vertex-id without any vertex
// buffer): a quad at each end-cap plane and a quad on the camera-facing
// tangent plane. The fragment shader ray-traces the analytic capped cylinder
// in eye space and outputs the exact surface depth. Works for both
// orthographic and perspective cameras.

constant float3 bondImposterHullOffsets[18] =
{
  // cap quad at endpoint A
  float3(-1.0, -1.0, -1.0),
  float3( 1.0, -1.0, -1.0),
  float3(-1.0, -1.0,  1.0),
  float3( 1.0, -1.0,  1.0),
  float3(-1.0, -1.0,  1.0),
  float3( 1.0, -1.0, -1.0),
  // camera-facing quad
  float3(-1.0, -1.0,  1.0),
  float3( 1.0, -1.0,  1.0),
  float3(-1.0,  1.0,  1.0),
  float3( 1.0,  1.0,  1.0),
  float3(-1.0,  1.0,  1.0),
  float3( 1.0, -1.0,  1.0),
  // cap quad at endpoint B
  float3(-1.0,  1.0,  1.0),
  float3( 1.0,  1.0,  1.0),
  float3(-1.0,  1.0, -1.0),
  float3( 1.0,  1.0, -1.0),
  float3(-1.0,  1.0, -1.0),
  float3( 1.0,  1.0,  1.0)
};

struct BondCylinderImposterVertexShaderOut
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 ambient [[ flat ]];
  float4 specular [[ flat ]];
  // sample-interpolated: forces per-sample execution of the fragment shader, so the
  // ray-traced silhouette, discards and depth are anti-aliased by MSAA
  float3 frag_pos [[ sample_perspective ]];
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
};

// fragment-input variant of BondCylinderImposterVertexShaderOut (matched to the vertex
// output by member name) with default center interpolation: the "fast" per-pixel
// quality mode, shading once per pixel even under MSAA
struct BondCylinderImposterPerPixelFragmentShaderIn
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 ambient [[ flat ]];
  float4 specular [[ flat ]];
  float3 frag_pos;
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
};

// displacement (in model x,z of the cylinder) of the sub-cylinders of double/triple bonds,
// matching MetalCappedDouble/TripleBondCylinderGeometry
static float2 bondImposterSubCylinderOffset(int type, uint sub, thread float &radiusFactor)
{
  radiusFactor = 1.0;
  float2 offset = float2(0.0, 0.0);
  if (type == 1)  // double bond
  {
    radiusFactor = 0.8;
    offset = float2((sub == 0) ? -1.0 : 1.0, 0.0);
  }
  else if (type == 3)  // triple bond
  {
    radiusFactor = 0.8;
    const float dz = 0.5 * sqrt(3.0);
    offset = (sub == 0) ? float2(-1.0, -dz) : ((sub == 1) ? float2(1.0, -dz) : float2(0.0, dz));
  }
  return offset;
}

// builds the hull vertex position in eye space for a cylinder from a to b
static float3 bondImposterHullPosition(float3 a, float3 b, float radius, uint vid, bool orthographic)
{
  float3 vHalf = 0.5 * (b - a);
  float3 center = a + vHalf;
  
  // direction from the camera towards the bond
  float3 e = orthographic ? float3(0.0, 0.0, -1.0) : center;
  
  float3 u = cross(vHalf, e);
  if (dot(u, u) < 1.0e-8) u = cross(vHalf, float3(0.0, 1.0, 0.0));
  if (dot(u, u) < 1.0e-8) u = cross(vHalf, float3(1.0, 0.0, 0.0));
  u = normalize(u);
  float3 w = normalize(cross(u, normalize(vHalf)));
  if (dot(w, e) > 0.0) w = -w;  // make w point towards the camera
  
  float3 coords = bondImposterHullOffsets[vid % 18];
  return center + radius * (coords.x * u + coords.z * w) + coords.y * vHalf;
}

// ray-traces a capped cylinder from a to b; returns the ray parameter t (or a negative
// value when there is no intersection) and sets the surface normal and the fraction
// ct (0 at a, 1 at b) along the axis
static float bondImposterIntersect(float3 ro, float3 rd, float3 a, float3 b, float r,
                                   thread float3 &N, thread float &ct)
{
  float3 ba = b - a;
  float3 oc = ro - a;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - r * r * baba;
  float h = k1 * k1 - k2 * k0;
  if (h < 0.0) return -1.0;
  h = sqrt(h);
  float t = (-k1 - h) / k2;
  
  // body of the cylinder
  float y = baoc + t * bard;
  if (y > 0.0 && y < baba)
  {
    N = (oc + t * rd - ba * y / baba) / r;
    ct = y / baba;
    return t;
  }
  
  // flat end-caps
  t = (((y < 0.0) ? 0.0 : baba) - baoc) / bard;
  if (abs(k1 + k2 * t) >= h) return -1.0;
  N = ba * sign(y) / sqrt(baba);
  ct = (y < 0.0) ? 0.0 : 1.0;
  return t;
}

// ray-traces the capped cylinder from a to b clipped by the six unit-cell planes,
// analytically generating the flat caps at the cell boundary (this replaces the
// stencil-based cap pass of the triangle-mesh path). The visible solid is an
// intersection of convex constraints (infinite cylinder, axis slab, six half-spaces),
// so the entry point is simply the largest of all entry parameters and the exit
// point the smallest of all exit parameters. The ray is traced in eye space;
// toStructure transforms eye-space points to the structure space of the clip planes.
// Returns the ray parameter t (negative when there is no intersection) and sets the
// eye-space surface normal and the fraction ct (0 at a, 1 at b) along the axis.
static float bondImposterClippedIntersect(float3 ro, float3 rd, float3 a, float3 b, float r,
                                          float4x4 toStructure,
                                          constant StructureUniforms& structureUniforms,
                                          thread float3 &N, thread float &ct)
{
  float3 ba = b - a;
  float3 oc = ro - a;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - r * r * baba;

  float tmin = -1.0e30;
  float tmax = 1.0e30;

  // -1: undetermined, 0: cylinder mantle, 1: end-cap, 2..7: clip plane
  int entryType = -1;

  // infinite cylinder around the axis
  if (k2 > 1.0e-6 * baba)
  {
    float h = k1 * k1 - k2 * k0;
    if (h < 0.0) return -1.0;
    h = sqrt(h);
    tmin = (-k1 - h) / k2;
    tmax = (-k1 + h) / k2;
    entryType = 0;
  }
  else if (k0 > 0.0)
  {
    // ray (nearly) parallel to the axis and outside the cylinder
    return -1.0;
  }

  // slab between the two end-cap planes: 0 <= baoc + t * bard <= baba
  if (abs(bard) > 1.0e-6)
  {
    float tCapA = (0.0 - baoc) / bard;
    float tCapB = (baba - baoc) / bard;
    float tEnter = min(tCapA, tCapB);
    float tExit = max(tCapA, tCapB);
    if (tEnter > tmin) { tmin = tEnter; entryType = 1; }
    tmax = min(tmax, tExit);
  }
  else if (baoc < 0.0 || baoc > baba)
  {
    return -1.0;
  }

  // the six clip planes of the unit cell (in structure space)
  float4 planes[6] = { structureUniforms.clipPlaneLeft, structureUniforms.clipPlaneRight,
                       structureUniforms.clipPlaneTop, structureUniforms.clipPlaneBottom,
                       structureUniforms.clipPlaneFront, structureUniforms.clipPlaneBack };
  float4 so = toStructure * float4(ro, 1.0);
  float4 sd = toStructure * float4(rd, 0.0);
  for (int i = 0; i < 6; i++)
  {
    float f0 = dot(planes[i], so);
    float df = dot(planes[i], sd);
    if (abs(df) < 1.0e-8)
    {
      if (f0 < 0.0) return -1.0;
    }
    else
    {
      float tp = -f0 / df;
      if (df > 0.0)
      {
        if (tp > tmin) { tmin = tp; entryType = 2 + i; }
      }
      else
      {
        tmax = min(tmax, tp);
      }
    }
  }

  if (tmax < tmin || tmin < 0.0 || entryType < 0) return -1.0;

  float t = tmin;
  float y = baoc + t * bard;
  ct = clamp(y / baba, 0.0, 1.0);

  if (entryType == 0)
  {
    N = (oc + t * rd - ba * y / baba) / r;
  }
  else if (entryType == 1)
  {
    N = (y < 0.5 * baba) ? -ba / sqrt(baba) : ba / sqrt(baba);
  }
  else
  {
    // clipped flat cap: the outward normal is opposite to the plane's inward
    // gradient; planes transform as covectors from structure to eye space
    float4 planeEye = transpose(toStructure) * planes[entryType - 2];
    N = -normalize(planeEye.xyz);
  }
  return t;
}

vertex BondCylinderImposterVertexShaderOut BondCylinderImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondCylinderImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos2 - pos1).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to v2, model z-axis maps to v1 (matches the orientationMatrix of BondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * v2 + offset.y * v1);
  float radius = structureUniforms.bondScaling * radiusFactor;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

template <typename VertexIn>
static FragOutput BondCylinderImposterFragmentImpl(VertexIn vert,
                                                   constant StructureUniforms& structureUniforms,
                                                   constant LightUniforms& lightUniforms,
                                                   constant FrameUniforms& frameUniforms)
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float3 V = normalize(-pos);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  output.albedo = float4(hsv2rgb(hsv),1.0);
  
  return output;
}

fragment FragOutput BondCylinderImposterFragmentShader(BondCylinderImposterVertexShaderOut vert [[stage_in]],
                                                       constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                       constant LightUniforms& lightUniforms [[buffer(1)]],
                                                       constant FrameUniforms& frameUniforms [[buffer(2)]])
{
  return BondCylinderImposterFragmentImpl(vert, structureUniforms, lightUniforms, frameUniforms);
}

// "fast" per-pixel variant: identical shading, but with center interpolation the
// fragment shader runs once per pixel even under MSAA
fragment FragOutput BondCylinderImposterPerPixelFragmentShader(BondCylinderImposterPerPixelFragmentShaderIn vert [[stage_in]],
                                                               constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                               constant LightUniforms& lightUniforms [[buffer(1)]],
                                                               constant FrameUniforms& frameUniforms [[buffer(2)]])
{
  return BondCylinderImposterFragmentImpl(vert, structureUniforms, lightUniforms, frameUniforms);
}



vertex BondCylinderImposterVertexShaderOut ExternalBondCylinderImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondCylinderImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos1 - pos2).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to -v1, model z-axis maps to -v2 (matches the orientationMatrix of ExternalBondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * (-v1) + offset.y * (-v2));
  float radius = structureUniforms.bondScaling * radiusFactor;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

template <typename VertexIn>
static FragOutput ExternalBondCylinderImposterFragmentImpl(VertexIn vert,
                                                           constant StructureUniforms& structureUniforms,
                                                           constant LightUniforms& lightUniforms,
                                                           constant FrameUniforms& frameUniforms)
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  // ray-trace the capped cylinder clipped at the unit cell; the flat caps at the
  // cell boundary are generated analytically (no stencil pass needed)
  float4x4 toStructure = structureUniforms.inverseModelMatrix * frameUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float3 V = normalize(-pos);
  
  // Calculate R locally
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  float4 color= float4(ambient.xyz + diffuse.xyz + specular.xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float3 hsv = rgb2hsv(color.xyz);
  hsv.x = hsv.x * structureUniforms.bondHue;
  hsv.y = hsv.y * structureUniforms.bondSaturation;
  hsv.z = hsv.z * structureUniforms.bondValue;
  output.albedo = float4(hsv2rgb(hsv),1.0);
  
  return output;
}

fragment FragOutput ExternalBondCylinderImposterFragmentShader(BondCylinderImposterVertexShaderOut vert [[stage_in]],
                                                               constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                               constant LightUniforms& lightUniforms [[buffer(1)]],
                                                               constant FrameUniforms& frameUniforms [[buffer(2)]])
{
  return ExternalBondCylinderImposterFragmentImpl(vert, structureUniforms, lightUniforms, frameUniforms);
}

// "fast" per-pixel variant: identical shading, but with center interpolation the
// fragment shader runs once per pixel even under MSAA
fragment FragOutput ExternalBondCylinderImposterPerPixelFragmentShader(BondCylinderImposterPerPixelFragmentShaderIn vert [[stage_in]],
                                                                       constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                                       constant LightUniforms& lightUniforms [[buffer(1)]],
                                                                       constant FrameUniforms& frameUniforms [[buffer(2)]])
{
  return ExternalBondCylinderImposterFragmentImpl(vert, structureUniforms, lightUniforms, frameUniforms);
}


// MARK: Bond cylinder imposter picking
// =============================================================================
// Picking counterparts of the bond imposters: the same hull and ray-tracing,
// but the fragment shader writes the picking identifiers and the exact surface
// depth instead of a shaded color.

struct BondCylinderPickingImposterVertexShaderOut
{
  float4 position [[position]];
  float3 frag_pos;
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
  int instanceId [[ flat ]];
};

struct BondCylinderPickingImposterFragOutput
{
  uint4 albedo [[color(0)]];
  float depth [[depth(any)]];
};

vertex BondCylinderPickingImposterVertexShaderOut PickingInternalBondCylinderImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondCylinderPickingImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.instanceId = positions[iid].tag;
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos2 - pos1).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to v2, model z-axis maps to v1 (matches the orientationMatrix of BondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * v2 + offset.y * v1);
  float radius = structureUniforms.bondScaling * radiusFactor;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

fragment BondCylinderPickingImposterFragOutput PickingInternalBondCylinderImposterFragmentShader(BondCylinderPickingImposterVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant FrameUniforms& frameUniforms [[buffer(1)]])
{
  BondCylinderPickingImposterFragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  output.albedo = uint4(2,0,structureUniforms.structureIdentifier, vert.instanceId);
  return output;
}

vertex BondCylinderPickingImposterVertexShaderOut PickingExternalBondCylinderImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondCylinderPickingImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.instanceId = positions[iid].tag;
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos1 - pos2).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to -v1, model z-axis maps to -v2 (matches the orientationMatrix of ExternalBondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * (-v1) + offset.y * (-v2));
  float radius = structureUniforms.bondScaling * radiusFactor;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

fragment BondCylinderPickingImposterFragOutput PickingExternalBondCylinderImposterFragmentShader(BondCylinderPickingImposterVertexShaderOut vert [[stage_in]],
                                           constant StructureUniforms& structureUniforms [[buffer(0)]],
                                           constant FrameUniforms& frameUniforms [[buffer(1)]])
{
  BondCylinderPickingImposterFragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  // ray-trace the capped cylinder clipped at the unit cell (matches the rendered surface)
  float4x4 toStructure = structureUniforms.inverseModelMatrix * frameUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  output.albedo = uint4(2,0,structureUniforms.structureIdentifier, vert.instanceId);
  return output;
}

// MARK: Bond cylinder imposter selection
// =============================================================================
// Selection counterparts of the bond imposters (glow, striped, worley-noise).
// The hull is inflated by the bond-selection scaling. The striped and
// worley-noise patterns need the model-space coordinates of the hit point on
// the unit cylinder; these are reconstructed from the eye-space directions of
// the cylinder model x/z axes (axisX/axisZ) and the fraction ct along the axis.

struct BondSelectionImposterVertexShaderOut
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 ambient [[ flat ]];
  float4 specular [[ flat ]];
  // center-interpolated: the selection effects don't need the per-sample anti-aliased
  // treatment of the main bond imposters, so they always shade once per pixel
  float3 frag_pos;
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
  float3 axisX [[ flat ]];
  float3 axisZ [[ flat ]];
};

vertex BondSelectionImposterVertexShaderOut internalBondSelectionImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondSelectionImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos2 - pos1).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to v2, model z-axis maps to v1 (matches the orientationMatrix of BondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * v2 + offset.y * v1);
  float radius = structureUniforms.bondScaling * radiusFactor * 1.01 * structureUniforms.bondSelectionScaling;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  vert.axisX = normalize((mv * float4(v2, 0.0)).xyz);
  vert.axisZ = normalize((mv * float4(v1, 0.0)).xyz);
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

vertex BondSelectionImposterVertexShaderOut externalBondSelectionImposterVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                constant LightUniforms& lightUniforms [[buffer(4)]],
                                                uint vid [[vertex_id]],
                                                uint iid [[instance_id]])
{
  BondSelectionImposterVertexShaderOut vert;
  
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;
  
  vert.ambient = lightUniforms.lights[0].ambient * structureUniforms.bondAmbientColor;
  vert.specular = lightUniforms.lights[0].specular * structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = lightUniforms.lights[0].diffuse * structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  // sub-cylinder displacement for double/triple bonds (all bonds drawn as single cylinders in 'unity'-mode)
  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, vid / 18, radiusFactor);
  
  float3 dr = normalize((pos1 - pos2).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));
  
  // model x-axis maps to -v1, model z-axis maps to -v2 (matches the orientationMatrix of ExternalBondCylinderVertexShader)
  float3 displacement = structureUniforms.bondScaling * (offset.x * (-v1) + offset.y * (-v2));
  float radius = structureUniforms.bondScaling * radiusFactor * 1.01 * structureUniforms.bondSelectionScaling;
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  float3 a = (mv * float4(pos1.xyz + displacement, 1.0)).xyz;
  float3 b = (mv * float4(pos2.xyz + displacement, 1.0)).xyz;
  
  vert.axisX = normalize((mv * float4(-v1, 0.0)).xyz);
  vert.axisZ = normalize((mv * float4(-v2, 0.0)).xyz);
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(a, b, radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = a;
  vert.pointB = b;
  vert.radius = radius;
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

// shared shading of the selection surface color (glow and worley-noise variants)
static float4 bondSelectionImposterShade(BondSelectionImposterVertexShaderOut vert,
                                         constant StructureUniforms& structureUniforms,
                                         constant LightUniforms& lightUniforms,
                                         float3 pos, float3 N, float ct)
{
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float3 V = normalize(-pos);
  float3 R = reflect(-L, N);
  
  float4 ambient = vert.ambient;
  float4 specular = pow(max(dot(R, V), 0.0),  lightUniforms.lights[0].shininess + structureUniforms.bondShininess) * vert.specular;
  float4 diffuse = max(dot(N, L), 0.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= lightUniforms.lights[0].diffuse * structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  return ambient + diffuse + specular;
}

// model-space coordinates of the hit point on the unit cylinder (x,z on the unit
// circle for mantle hits, y = ct in 0..1), matching the Model_N of the mesh path
static float3 bondSelectionImposterModelCoords(BondSelectionImposterVertexShaderOut vert, float3 pos, float ct)
{
  float3 axisPos = mix(vert.pointA, vert.pointB, ct);
  float3 pr = (pos - axisPos) / vert.radius;
  return float3(dot(pr, vert.axisX), ct, dot(pr, vert.axisZ));
}

fragment FragOutput internalBondSelectionGlowImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float4 color = float4(bondSelectionImposterShade(vert, structureUniforms, lightUniforms, pos, N, ct).xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  output.albedo = float4(color.xyz * bloomLevel, bloomLevel);
  return output;
}


fragment FragOutput internalBondSelectionStripedImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 t1 = bondSelectionImposterModelCoords(vert, pos, ct);
  float2 st = float2(0.5 + 0.5 * atan2(t1.x, t1.z)/3.141592653589793, t1.y);
  float uDensity = structureUniforms.bondSelectionStripesDensity;
  float frequency = structureUniforms.bondSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    color= vLdrColor;
  }
  
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  output.albedo = float4(color.xyz * bloomLevel, bloomLevel);
  return output;
}


fragment FragOutput internalBondSelectionWorleyNoise3DImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 t1 = bondSelectionImposterModelCoords(vert, pos, ct);
  float frequency = structureUniforms.bondSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.bondSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,2.0*t1.y,t1.z), jitter);
  float n = F.y-F.x;
  
  float4 color = n * bondSelectionImposterShade(vert, structureUniforms, lightUniforms, pos, N, ct);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float intensity = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  output.albedo = float4(color.xyz * intensity, intensity);
  return output;
}


fragment FragOutput externalBondSelectionGlowImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float4x4 toStructure = structureUniforms.inverseModelMatrix * frameUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float4 color = float4(bondSelectionImposterShade(vert, structureUniforms, lightUniforms, pos, N, ct).xyz, 1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  output.albedo = float4(color.xyz * bloomLevel, bloomLevel);
  return output;
}


fragment FragOutput externalBondSelectionStripedImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float4x4 toStructure = structureUniforms.inverseModelMatrix * frameUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 t1 = bondSelectionImposterModelCoords(vert, pos, ct);
  float2 st = float2(0.5 + 0.5 * atan2(t1.x, t1.z)/3.141592653589793, t1.y);
  float uDensity = structureUniforms.bondSelectionStripesDensity;
  float frequency = structureUniforms.bondSelectionStripesFrequency;
  if (fract(st.x*frequency) >= uDensity && fract(st.y*frequency) >= uDensity)
    discard_fragment();
  
  float3 L = normalize((lightUniforms.lights[0].position - float4(pos, 1.0) * lightUniforms.lights[0].position.w).xyz);
  float4 color = max(dot(N, L), 0.0) * float4(1.0,1.0,0.0,1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    color= vLdrColor;
  }
  
  float bloomLevel = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  output.albedo = float4(color.xyz * bloomLevel, bloomLevel);
  return output;
}


fragment FragOutput externalBondSelectionWorleyNoise3DImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float4x4 toStructure = structureUniforms.inverseModelMatrix * frameUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 t1 = bondSelectionImposterModelCoords(vert, pos, ct);
  float frequency = structureUniforms.bondSelectionWorleyNoise3DFrequency;
  float jitter = structureUniforms.bondSelectionWorleyNoise3DJitter;
  float2 F = cellular3D(frequency*float3(t1.x,2.0*t1.y,t1.z), jitter);
  float n = F.y-F.x;
  
  float4 color = n * bondSelectionImposterShade(vert, structureUniforms, lightUniforms, pos, N, ct);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
    vLdrColor.a = 1.0;
    color= vLdrColor;
  }
  
  float intensity = frameUniforms.bloomLevel * structureUniforms.bondSelectionIntensity;
  output.albedo = float4(color.xyz * intensity, intensity);
  return output;
}

