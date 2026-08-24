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
  // the frame the baked occlusion measures the angle around the axis from, and the patch it lives in
  float3 aoAxis1 [[ flat ]];
  float3 aoAxis2 [[ flat ]];
  uint aoPatch [[ flat ]];
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
  float3 aoAxis1 [[ flat ]];
  float3 aoAxis2 [[ flat ]];
  uint aoPatch [[ flat ]];
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

/// One of the cylinders a bond is drawn as, placed in whichever frame the caller's matrix leads to, with
/// the two axes perpendicular to it that the occlusion atlas measures its angle from.
struct BondCylinderFrame
{
  float3 a;
  float3 b;
  float radius;
  float3 axis1;
  float3 axis2;
};

/// Places sub-cylinder `sub` of bond `iid`. The internal and external bonds disagree on the direction of
/// the axis and on which model axis each sub-cylinder offset follows, so both conventions live here and
/// every pass that needs the geometry — the drawn bonds, the occluders written into the bake's depth map,
/// and the bake of the bonds' own occlusion — asks for it in the same way.
static BondCylinderFrame bondCylinderFrame(const device InPerInstanceAttributesBonds *positions,
                                           constant StructureUniforms& structureUniforms,
                                           float4x4 modelView,
                                           uint iid,
                                           uint sub,
                                           bool external)
{
  float4 pos1 = positions[iid].position1;
  float4 pos2 = positions[iid].position2;

  float radiusFactor;
  int type = structureUniforms.isUnity ? 0 : positions[iid].type;
  float2 offset = bondImposterSubCylinderOffset(type, sub, radiusFactor);

  float3 dr = normalize((external ? (pos1 - pos2) : (pos2 - pos1)).xyz);
  float3 v1 = normalize(abs(dr.x) > abs(dr.z) ? float3(-dr.y, dr.x, 0.0) : float3(0.0, -dr.z, dr.y));
  float3 v2 = normalize(cross(dr, v1));

  // internal: model x maps to v2 and model z to v1; external: model x to -v1 and model z to -v2. These
  // match the orientationMatrix of the triangle-mesh bond shaders.
  float3 displacement = structureUniforms.bondScaling * (external ? (offset.x * (-v1) + offset.y * (-v2))
                                                                  : (offset.x * v2 + offset.y * v1));

  BondCylinderFrame frame;
  frame.a = (modelView * float4(pos1.xyz + displacement, 1.0)).xyz;
  frame.b = (modelView * float4(pos2.xyz + displacement, 1.0)).xyz;
  frame.radius = structureUniforms.bondScaling * radiusFactor;
  frame.axis1 = normalize((modelView * float4(v1, 0.0)).xyz);
  frame.axis2 = normalize((modelView * float4(v2, 0.0)).xyz);
  return frame;
}

/// Where in the occlusion atlas sub-cylinder `sub` of bond `iid` keeps its patch. The external bonds are
/// numbered from zero like the internal ones and moved past them here, so that one texture serves both.
static uint bondAmbientOcclusionPatch(const device InPerInstanceAttributesBonds *positions,
                                      constant StructureUniforms& structureUniforms,
                                      uint iid,
                                      uint sub,
                                      bool external)
{
  uint base = external ? uint(structureUniforms.externalBondAmbientOcclusionPatchBase) : 0u;
  return base + positions[iid].ambientOcclusionPatch + sub;
}

/// Reads the occlusion baked for a point on a bond, given the surface normal and how far along the axis
/// the point lies. The atlas stores one patch per drawn cylinder, the angle around the axis running across
/// it and the distance along the axis down it.
static float bondAmbientOcclusionAt(constant StructureUniforms& structureUniforms,
                                    texture2d<half> ambientOcclusionTexture,
                                    sampler ambientOcclusionSampler,
                                    uint patch,
                                    float3 axis1,
                                    float3 axis2,
                                    float3 N,
                                    float axialFraction)
{
  float patchSize = structureUniforms.bondAmbientOcclusionPatchSize;
  uint patchNumber = uint(structureUniforms.bondAmbientOcclusionPatchNumber);
  float2 patchOrigin = float2(float(patch % patchNumber), float(patch / patchNumber));

  // On the flat end-caps the normal is along the axis and carries no angle; those texels are hidden inside
  // the atom the bond ends in whenever the bond is shorter than the two radii, which is the usual case.
  float angle = atan2(dot(N, axis2), dot(N, axis1));
  if (angle < 0.0) angle += 2.0 * M_PI_F;

  float2 uv = float2(angle / (2.0 * M_PI_F), clamp(axialFraction, 0.0, 1.0));
  float2 texel = patchSize * patchOrigin + float2(0.5) + (patchSize - 1.0) * uv;
  return float(ambientOcclusionTexture.sample(ambientOcclusionSampler, texel * structureUniforms.bondAmbientOcclusionInverseTextureSize).r);
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
// ct (0 at a, 1 at b) along the axis. With AnalyticCoverage the miss is reported as a
// coverage of zero rather than as a negative t, and a pixel the silhouette runs through
// gets the fraction of it that the cylinder covers; the ray is then still traced, to the
// closest point it comes to the surface, so that sliver of cylinder has a colour and a depth.
template <bool AnalyticCoverage>
static float bondImposterIntersectImpl(float3 ro, float3 rd, float3 a, float3 b, float r,
                                       thread float3 &N, thread float &ct, thread float &coverage)
{
  float3 ba = b - a;
  float3 oc = ro - a;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - r * r * baba;
  float disc = k1 * k1 - k2 * k0;
  
  coverage = 1.0;
  if (AnalyticCoverage)
  {
    // The solid is the infinite cylinder cut by the slab between the two end-cap planes, so the ray
    // is inside it for as long as both hold and the length of that stretch passes through zero right
    // on the silhouette, mantle and cap rim alike. One expression covering the whole outline is what
    // makes it measurable: the screen-space derivative it is divided by only means anything where the
    // neighbouring pixels of the quad computed the same quantity.
    float h = sign(disc) * sqrt(abs(disc));
    float tEnter = (-k1 - h) / max(k2, 1.0e-6 * baba);
    float tExit = (-k1 + h) / max(k2, 1.0e-6 * baba);
    float invBard = 1.0 / (abs(bard) > 1.0e-6 ? bard : 1.0e-6);
    float tCapA = (0.0 - baoc) * invBard;
    float tCapB = (baba - baoc) * invBard;
    coverage = coverageFromEdge(min(tExit, max(tCapA, tCapB)) - max(tEnter, min(tCapA, tCapB)));
  }
  
  if (!AnalyticCoverage && disc < 0.0) return -1.0;
  float h = sqrt(max(disc, 0.0));
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
  if (!AnalyticCoverage && abs(k1 + k2 * t) >= h) return -1.0;
  N = ba * sign(y) / sqrt(baba);
  ct = (y < 0.0) ? 0.0 : 1.0;
  return t;
}

// the plain hit test, for the callers that have no use for a coverage fraction
static float bondImposterIntersect(float3 ro, float3 rd, float3 a, float3 b, float r,
                                   thread float3 &N, thread float &ct)
{
  float coverage;
  return bondImposterIntersectImpl<false>(ro, rd, a, b, r, N, ct, coverage);
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
// AnalyticCoverage behaves as it does in bondImposterIntersectImpl.
template <bool AnalyticCoverage>
static float bondImposterClippedIntersectImpl(float3 ro, float3 rd, float3 a, float3 b, float r,
                                              float4x4 toStructure,
                                              constant StructureUniforms& structureUniforms,
                                              thread float3 &N, thread float &ct, thread float &coverage)
{
  float3 ba = b - a;
  float3 oc = ro - a;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - r * r * baba;
  
  // the six clip planes of the unit cell (in structure space)
  float4 planes[6] = { structureUniforms.clipPlaneLeft, structureUniforms.clipPlaneRight,
                       structureUniforms.clipPlaneTop, structureUniforms.clipPlaneBottom,
                       structureUniforms.clipPlaneFront, structureUniforms.clipPlaneBack };
  float4 so = toStructure * float4(ro, 1.0);
  float4 sd = toStructure * float4(rd, 0.0);
  
  coverage = 1.0;
  if (AnalyticCoverage)
  {
    // The same interval as below, but taken without any of its branches and with the discriminant
    // left signed, so that it shrinks smoothly past zero instead of stopping there. Its width is
    // what the whole outline of the clipped solid — mantle, end-cap and cut face — has in common,
    // and the pixel-to-pixel rate at which it shrinks says how much of this pixel is still inside.
    // Every pixel of the quad has to arrive at that derivative having computed the same expression,
    // which is why nothing here is skipped over.
    bool alongAxis = k2 <= 1.0e-6 * baba;
    bool acrossCaps = abs(bard) > 1.0e-6;
    
    float disc = k1 * k1 - k2 * k0;
    float h = sign(disc) * sqrt(abs(disc));
    float tEnter = alongAxis ? -1.0e30 : (-k1 - h) / k2;
    float tExit = alongAxis ? 1.0e30 : (-k1 + h) / k2;
    
    float tCapA = acrossCaps ? (0.0 - baoc) / bard : -1.0e30;
    float tCapB = acrossCaps ? (baba - baoc) / bard : 1.0e30;
    tEnter = max(tEnter, min(tCapA, tCapB));
    tExit = min(tExit, max(tCapA, tCapB));
    
    for (int i = 0; i < 6; i++)
    {
      float f0 = dot(planes[i], so);
      float df = dot(planes[i], sd);
      bool crosses = abs(df) > 1.0e-8;
      float tp = crosses ? -f0 / df : 0.0;
      tEnter = max(tEnter, (crosses && df > 0.0) ? tp : -1.0e30);
      tExit = min(tExit, crosses ? (df > 0.0 ? 1.0e30 : tp) : (f0 < 0.0 ? -1.0e30 : 1.0e30));
    }
    
    float intervalCoverage = coverageFromEdge(tExit - tEnter);
    
    // configurations the interval cannot speak for: a ray along the axis but outside the cylinder,
    // one that crosses neither cap plane while lying beyond them, and one entering behind the eye
    bool misses = (alongAxis && k0 > 0.0) || (!acrossCaps && (baoc < 0.0 || baoc > baba)) || tEnter < 0.0;
    coverage = misses ? 0.0 : intervalCoverage;
  }
  
  float tmin = -1.0e30;
  float tmax = 1.0e30;
  
  // -1: undetermined, 0: cylinder mantle, 1: end-cap, 2..7: clip plane
  int entryType = -1;
  
  // infinite cylinder around the axis
  if (k2 > 1.0e-6 * baba)
  {
    float h = k1 * k1 - k2 * k0;
    if (h < 0.0)
    {
      if (!AnalyticCoverage) return -1.0;
      h = 0.0;
    }
    h = sqrt(h);
    tmin = (-k1 - h) / k2;
    tmax = (-k1 + h) / k2;
    entryType = 0;
  }
  else if (k0 > 0.0)
  {
    // ray (nearly) parallel to the axis and outside the cylinder
    if (!AnalyticCoverage) return -1.0;
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
    if (!AnalyticCoverage) return -1.0;
  }
  
  for (int i = 0; i < 6; i++)
  {
    float f0 = dot(planes[i], so);
    float df = dot(planes[i], sd);
    if (abs(df) < 1.0e-8)
    {
      if (f0 < 0.0)
      {
        if (!AnalyticCoverage) return -1.0;
        tmax = -1.0e30;
      }
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
  
  if (tmax < tmin || tmin < 0.0 || entryType < 0)
  {
    if (!AnalyticCoverage) return -1.0;
    
    // the coverage has already written this pixel off, but the ray parameter still has to stay
    // finite: it goes on to be shaded, only to be masked away afterwards
    if (!(tmin >= 0.0 && tmin < 1.0e30)) tmin = 0.0;
    entryType = max(entryType, 0);
  }
  
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

// the plain hit test, for the callers that have no use for a coverage fraction
static float bondImposterClippedIntersect(float3 ro, float3 rd, float3 a, float3 b, float r,
                                          float4x4 toStructure,
                                          constant StructureUniforms& structureUniforms,
                                          thread float3 &N, thread float &ct)
{
  float coverage;
  return bondImposterClippedIntersectImpl<false>(ro, rd, a, b, r, toStructure, structureUniforms, N, ct, coverage);
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
  
  vert.ambient = structureUniforms.bondAmbientColor;
  vert.specular = structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  uint sub = vid / 18;
  BondCylinderFrame frame = bondCylinderFrame(positions, structureUniforms, mv, iid, sub, false);
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(frame.a, frame.b, frame.radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = frame.a;
  vert.pointB = frame.b;
  vert.radius = frame.radius;
  vert.aoAxis1 = frame.axis1;
  vert.aoAxis2 = frame.axis2;
  vert.aoPatch = bondAmbientOcclusionPatch(positions, structureUniforms, iid, sub, false);
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

template <typename VertexIn, bool AnalyticCoverage>
static FragOutput BondCylinderImposterFragmentImpl(VertexIn vert,
                                                   constant StructureUniforms& structureUniforms,
                                                   constant LightUniforms& lightUniforms,
                                                   constant FrameUniforms& frameUniforms,
                                                   texture2d<half> ambientOcclusionTexture,
                                                   sampler ambientOcclusionSampler,
                                                   texture2d<uint> shadowMask,
                                                   thread float &coverage)
{
  FragOutput output;
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 ro = orthographic ? float3(vert.frag_pos.xy, 0.0) : float3(0.0);
  float3 rd = orthographic ? float3(0.0, 0.0, -1.0) : normalize(vert.frag_pos);
  
  float3 N;
  float ct;
  float t = bondImposterIntersectImpl<AnalyticCoverage>(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct, coverage);
  if (AnalyticCoverage) coverage = (t < 0.0) ? 0.0 : coverage;
  else if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 V = normalize(-pos);
  
  LightingWeights lighting = accumulateLighting(lightUniforms, N, V, float4(pos, 1.0), structureUniforms.bondShininess,
                                                shadowMaskAtFragment(shadowMask, vert.position));
  
  float4 ambient = float4(lighting.ambient, 1.0) * vert.ambient;
  float4 specular = float4(lighting.specular, 1.0) * vert.specular;
  float4 diffuse = float4(lighting.diffuse, 1.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  float ao = 1.0;
  if (structureUniforms.bondAmbientOcclusion)
  {
    ao = bondAmbientOcclusionAt(structureUniforms, ambientOcclusionTexture, ambientOcclusionSampler,
                                vert.aoPatch, vert.aoAxis1, vert.aoAxis2, N, ct);
  }
  
  // see the note on ambientOcclusionStrength in Common.h
  float aoDirect = mix(1.0, ao, clamp(structureUniforms.ambientOcclusionStrength, 0.0, 1.0));
  float4 color= float4(ao * ambient.xyz + aoDirect * (diffuse.xyz + specular.xyz), 1.0);
  
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
                                                       constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                       texture2d<half>  ambientOcclusionTexture [[texture(0)]],
                                                       sampler          ambientOcclusionSampler [[sampler(0)]],
                                                       texture2d<uint> shadowMask [[texture(1)]])
{
  float coverage;
  return BondCylinderImposterFragmentImpl<BondCylinderImposterVertexShaderOut, false>(vert, structureUniforms, lightUniforms, frameUniforms, ambientOcclusionTexture, ambientOcclusionSampler, shadowMask, coverage);
}

// "fast" per-pixel variant: identical shading, but with center interpolation the fragment shader runs
// once per pixel even under MSAA. Silhouette coverage is written as alpha; the pipeline's
// alpha-to-coverage then keeps only that fraction of the pixel's samples, including their depth,
// so glow and selection still see the same kind of rim they do in the per-sample still path.
fragment FragOutput BondCylinderImposterPerPixelFragmentShader(BondCylinderImposterPerPixelFragmentShaderIn vert [[stage_in]],
                                                               constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                               constant LightUniforms& lightUniforms [[buffer(1)]],
                                                               constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                       texture2d<half>  ambientOcclusionTexture [[texture(0)]],
                                                       sampler          ambientOcclusionSampler [[sampler(0)]],
                                                       texture2d<uint> shadowMask [[texture(1)]])
{
  float coverage;
  FragOutput output = BondCylinderImposterFragmentImpl<BondCylinderImposterPerPixelFragmentShaderIn, true>(vert, structureUniforms, lightUniforms, frameUniforms, ambientOcclusionTexture, ambientOcclusionSampler, shadowMask, coverage);
  if (!(coverage > 0.0)) discard_fragment();
  output.albedo.w = coverage;
  return output;
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
  
  vert.ambient = structureUniforms.bondAmbientColor;
  vert.specular = structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.atomDiffuseColor * positions[iid].color2;
  }
  
  float4x4 mv = frameUniforms.viewMatrix * structureUniforms.modelMatrix;
  uint sub = vid / 18;
  BondCylinderFrame frame = bondCylinderFrame(positions, structureUniforms, mv, iid, sub, true);
  
  bool orthographic = (frameUniforms.projectionMatrix[3][3] > 0.5);
  float3 posEye = bondImposterHullPosition(frame.a, frame.b, frame.radius, vid, orthographic);
  
  vert.frag_pos = posEye;
  vert.pointA = frame.a;
  vert.pointB = frame.b;
  vert.radius = frame.radius;
  vert.aoAxis1 = frame.axis1;
  vert.aoAxis2 = frame.axis2;
  vert.aoPatch = bondAmbientOcclusionPatch(positions, structureUniforms, iid, sub, true);
  vert.position = frameUniforms.projectionMatrix * float4(posEye, 1.0);
  
  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (pos1.w < 0.0 || pos2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }
  
  return vert;
}

template <typename VertexIn, bool AnalyticCoverage>
static FragOutput ExternalBondCylinderImposterFragmentImpl(VertexIn vert,
                                                           constant StructureUniforms& structureUniforms,
                                                           constant LightUniforms& lightUniforms,
                                                           constant FrameUniforms& frameUniforms,
                                                           texture2d<half> ambientOcclusionTexture,
                                                           sampler ambientOcclusionSampler,
                                                           texture2d<uint> shadowMask,
                                                           thread float &coverage)
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
  float t = bondImposterClippedIntersectImpl<AnalyticCoverage>(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct, coverage);
  if (AnalyticCoverage) coverage = (t < 0.0) ? 0.0 : coverage;
  else if (t < 0.0) discard_fragment();
  
  float3 pos = ro + t * rd;
  
  float4 screen_pos = frameUniforms.projectionMatrix * float4(pos, 1.0);
  output.depth = screen_pos.z / screen_pos.w;
  
  float3 V = normalize(-pos);
  
  LightingWeights lighting = accumulateLighting(lightUniforms, N, V, float4(pos, 1.0), structureUniforms.bondShininess,
                                                shadowMaskAtFragment(shadowMask, vert.position));
  
  float4 ambient = float4(lighting.ambient, 1.0) * vert.ambient;
  float4 specular = float4(lighting.specular, 1.0) * vert.specular;
  float4 diffuse = float4(lighting.diffuse, 1.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= structureUniforms.bondDiffuseColor;
      break;
    case 1:
      diffuse *= (ct < 0.5 ? vert.color1 : vert.color2);
      break;
    case 2:
      diffuse *= mix(vert.color1,vert.color2,smoothstep(0.0,1.0,ct));
      break;
  }
  
  float ao = 1.0;
  if (structureUniforms.bondAmbientOcclusion)
  {
    ao = bondAmbientOcclusionAt(structureUniforms, ambientOcclusionTexture, ambientOcclusionSampler,
                                vert.aoPatch, vert.aoAxis1, vert.aoAxis2, N, ct);
  }
  
  // see the note on ambientOcclusionStrength in Common.h
  float aoDirect = mix(1.0, ao, clamp(structureUniforms.ambientOcclusionStrength, 0.0, 1.0));
  float4 color= float4(ao * ambient.xyz + aoDirect * (diffuse.xyz + specular.xyz), 1.0);
  
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
                                                               constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                       texture2d<half>  ambientOcclusionTexture [[texture(0)]],
                                                       sampler          ambientOcclusionSampler [[sampler(0)]],
                                                       texture2d<uint> shadowMask [[texture(1)]])
{
  float coverage;
  return ExternalBondCylinderImposterFragmentImpl<BondCylinderImposterVertexShaderOut, false>(vert, structureUniforms, lightUniforms, frameUniforms, ambientOcclusionTexture, ambientOcclusionSampler, shadowMask, coverage);
}

// "fast" per-pixel variant, see BondCylinderImposterPerPixelFragmentShader
fragment FragOutput ExternalBondCylinderImposterPerPixelFragmentShader(BondCylinderImposterPerPixelFragmentShaderIn vert [[stage_in]],
                                                                       constant StructureUniforms& structureUniforms [[buffer(0)]],
                                                                       constant LightUniforms& lightUniforms [[buffer(1)]],
                                                                       constant FrameUniforms& frameUniforms [[buffer(2)]],
                                                       texture2d<half>  ambientOcclusionTexture [[texture(0)]],
                                                       sampler          ambientOcclusionSampler [[sampler(0)]],
                                                       texture2d<uint> shadowMask [[texture(1)]])
{
  float coverage;
  FragOutput output = ExternalBondCylinderImposterFragmentImpl<BondCylinderImposterPerPixelFragmentShaderIn, true>(vert, structureUniforms, lightUniforms, frameUniforms, ambientOcclusionTexture, ambientOcclusionSampler, shadowMask, coverage);
  if (!(coverage > 0.0)) discard_fragment();
  output.albedo.w = coverage;
  return output;
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
  // center-interpolated: the pixel-rate side, used while the scene bonds shade per pixel too
  float3 frag_pos;
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
  float3 axisX [[ flat ]];
  float3 axisZ [[ flat ]];
};

// The same varyings interpolated per MSAA sample (matched to the vertex output by member name).
// The selection overlay sits a whisker in front of the bond it decorates and depth-tests against
// it, so the two surfaces have to be measured at the same points. Measured at different points, the
// comparison is off by the depth slope times the sub-pixel offset, which outgrows the overlay's
// clearance on the cylinder's flanks and flips the test there in bands aligned to the screen's
// fixed sample pattern. The overlay therefore follows the scene's shading rate: this struct while
// the bonds shade per sample (still frames), the pixel-rate struct above while they shade per
// pixel (interaction).
struct BondSelectionImposterPerSampleFragmentShaderIn
{
  float4 position [[position]];
  float4 color1 [[ flat ]];
  float4 color2 [[ flat ]];
  float4 ambient [[ flat ]];
  float4 specular [[ flat ]];
  float3 frag_pos [[ sample_perspective ]];
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
  
  vert.ambient = structureUniforms.bondAmbientColor;
  vert.specular = structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.atomDiffuseColor * positions[iid].color2;
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
  
  vert.ambient = structureUniforms.bondAmbientColor;
  vert.specular = structureUniforms.bondSpecularColor;
  if (structureUniforms.bondColorMode == 0)
  {
    vert.color1 = structureUniforms.bondDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.bondDiffuseColor * positions[iid].color2;
  }
  else
  {
    vert.color1 = structureUniforms.atomDiffuseColor * positions[iid].color1;
    vert.color2 = structureUniforms.atomDiffuseColor * positions[iid].color2;
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
template <typename VertexIn>
static float4 bondSelectionImposterShade(VertexIn vert,
                                         constant StructureUniforms& structureUniforms,
                                         constant LightUniforms& lightUniforms,
                                         float3 pos, float3 N, float ct)
{
  float3 V = normalize(-pos);
  
  LightingWeights lighting = accumulateLighting(lightUniforms, N, V, float4(pos, 1.0), structureUniforms.bondShininess);
  
  float4 ambient = float4(lighting.ambient, 1.0) * vert.ambient;
  float4 specular = float4(lighting.specular, 1.0) * vert.specular;
  float4 diffuse = float4(lighting.diffuse, 1.0);
  
  switch(structureUniforms.bondColorMode)
  {
    case 0:
      diffuse *= structureUniforms.bondDiffuseColor;
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
template <typename VertexIn>
static float3 bondSelectionImposterModelCoords(VertexIn vert, float3 pos, float ct)
{
  float3 axisPos = mix(vert.pointA, vert.pointB, ct);
  float3 pr = (pos - axisPos) / vert.radius;
  return float3(dot(pr, vert.axisX), ct, dot(pr, vert.axisZ));
}

template <typename VertexIn>
static FragOutput internalBondSelectionGlowImposterFragmentImpl(VertexIn vert,
                                           constant FrameUniforms& frameUniforms,
                                           constant StructureUniforms& structureUniforms,
                                           constant LightUniforms& lightUniforms)
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

fragment FragOutput internalBondSelectionGlowImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return internalBondSelectionGlowImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

// used while the scene bonds shade per-pixel, see BondSelectionImposterPerSampleFragmentShaderIn
fragment FragOutput internalBondSelectionGlowImposterPerSampleFragmentShader(BondSelectionImposterPerSampleFragmentShaderIn vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return internalBondSelectionGlowImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}


template <typename VertexIn>
static FragOutput internalBondSelectionStripedImposterFragmentImpl(VertexIn vert,
                                           constant FrameUniforms& frameUniforms,
                                           constant StructureUniforms& structureUniforms,
                                           constant LightUniforms& lightUniforms)
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
  
  LightingWeights lighting = accumulateLighting(lightUniforms, N, normalize(-pos), float4(pos, 1.0), 0.0);
  float4 color = float4(lighting.diffuse, 1.0) * float4(1.0,1.0,0.0,1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
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
  return internalBondSelectionStripedImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

// used while the scene bonds shade per-pixel, see BondSelectionImposterPerSampleFragmentShaderIn
fragment FragOutput internalBondSelectionStripedImposterPerSampleFragmentShader(BondSelectionImposterPerSampleFragmentShaderIn vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return internalBondSelectionStripedImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}


template <typename VertexIn>
static FragOutput internalBondSelectionWorleyNoise3DImposterFragmentImpl(VertexIn vert,
                                           constant FrameUniforms& frameUniforms,
                                           constant StructureUniforms& structureUniforms,
                                           constant LightUniforms& lightUniforms)
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
  float n = filteredWorleyFactor(frequency*float3(t1.x,2.0*t1.y,t1.z), jitter);

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

fragment FragOutput internalBondSelectionWorleyNoise3DImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return internalBondSelectionWorleyNoise3DImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

// used while the scene bonds shade per-pixel, see BondSelectionImposterPerSampleFragmentShaderIn
fragment FragOutput internalBondSelectionWorleyNoise3DImposterPerSampleFragmentShader(BondSelectionImposterPerSampleFragmentShaderIn vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return internalBondSelectionWorleyNoise3DImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}


template <typename VertexIn>
static FragOutput externalBondSelectionGlowImposterFragmentImpl(VertexIn vert,
                                           constant FrameUniforms& frameUniforms,
                                           constant StructureUniforms& structureUniforms,
                                           constant LightUniforms& lightUniforms)
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

fragment FragOutput externalBondSelectionGlowImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return externalBondSelectionGlowImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

// used while the scene bonds shade per-pixel, see BondSelectionImposterPerSampleFragmentShaderIn
fragment FragOutput externalBondSelectionGlowImposterPerSampleFragmentShader(BondSelectionImposterPerSampleFragmentShaderIn vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return externalBondSelectionGlowImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}


template <typename VertexIn>
static FragOutput externalBondSelectionStripedImposterFragmentImpl(VertexIn vert,
                                           constant FrameUniforms& frameUniforms,
                                           constant StructureUniforms& structureUniforms,
                                           constant LightUniforms& lightUniforms)
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
  
  LightingWeights lighting = accumulateLighting(lightUniforms, N, normalize(-pos), float4(pos, 1.0), 0.0);
  float4 color = float4(lighting.diffuse, 1.0) * float4(1.0,1.0,0.0,1.0);
  
  if (structureUniforms.bondHDR)
  {
    float4 vLdrColor = 1.0 - exp2(-color * structureUniforms.bondHDRExposure);
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
  return externalBondSelectionStripedImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

// used while the scene bonds shade per-pixel, see BondSelectionImposterPerSampleFragmentShaderIn
fragment FragOutput externalBondSelectionStripedImposterPerSampleFragmentShader(BondSelectionImposterPerSampleFragmentShaderIn vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return externalBondSelectionStripedImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}


// MARK: Occlusion bake
// =============================================================================
// The bake looks at the structure from a few hundred directions and records, for each direction, a depth
// map of everything that could stand in the way. Atoms and ribbons have always been written into that map;
// these shaders put the bonds in it too, so that a bond darkens the atoms and ribbons it lies against.
//
// They live in this file rather than with the rest of the bake because they reuse the hull construction and
// the cylinder intersection the drawn bonds use, which keeps the occluding shape and the drawn shape the
// same thing by construction. The bake's camera is always orthographic, so the ray is fixed.

struct BondShadowMapVertexShaderOut
{
  float4 position [[position]];
  float3 frag_pos;
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float radius [[ flat ]];
};

/// Unlike the shadow-map output of the atoms and ribbons, this one cannot promise to write a depth no
/// greater than the rasterized one: the hull encloses the cylinder and so lies in front of it.
struct BondShadowMapOutput
{
  float depth [[depth(any)]];
};

/// The depth written for a bond, given where the ray met it: that of the point on the bond's axis rather than
/// of the surface itself.
///
/// The atoms are written into this map as flat discs at their centre depth rather than as hemispheres, so that
/// an atom never occludes itself; the axis of a bond is the same idea one dimension along. Writing the true
/// surface instead makes bonds much stronger occluders than the atoms beside them, and since a bond runs from
/// one atom centre to the other it then darkens both of them along the ring where the two surfaces touch.
///
/// It also means no depth margin is needed: a surface lying against a bond is in front of its axis by the
/// bond's radius, which is far more than any rounding between the two passes.
static float bondShadowMapAxisDepth(constant ShadowUniforms& shadowUniforms,
                                    float3 a, float3 b, float axialFraction)
{
  float4 axisPoint = shadowUniforms.projectionMatrix * float4(a + axialFraction * (b - a), 1.0);
  return axisPoint.z / axisPoint.w;
}

/// Places one hull vertex of a bond in the frame of the bake's camera. `vid / 18` selects the sub-cylinder,
/// so a double or triple bond occludes with the several cylinders it is drawn as.
static BondShadowMapVertexShaderOut bondShadowMapHull(const device InPerInstanceAttributesBonds *positions,
                                                      constant ShadowUniforms& shadowUniforms,
                                                      constant StructureUniforms& structureUniforms,
                                                      uint vid,
                                                      uint iid,
                                                      bool external)
{
  BondShadowMapVertexShaderOut vert;

  float4x4 mv = shadowUniforms.viewMatrix * structureUniforms.modelMatrix;
  BondCylinderFrame frame = bondCylinderFrame(positions, structureUniforms, mv, iid, vid / 18, external);

  float3 posEye = bondImposterHullPosition(frame.a, frame.b, frame.radius, vid, true);

  vert.frag_pos = posEye;
  vert.pointA = frame.a;
  vert.pointB = frame.b;
  vert.radius = frame.radius;
  vert.position = shadowUniforms.projectionMatrix * float4(posEye, 1.0);

  // invisible bonds have w set to -1, leading to clipping of the entire hull
  if (positions[iid].position1.w < 0.0 || positions[iid].position2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }

  return vert;
}

vertex BondShadowMapVertexShaderOut BondShadowMapVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                              constant ShadowUniforms& shadowUniforms [[buffer(2)]],
                                                              constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                              uint vid [[vertex_id]],
                                                              uint iid [[instance_id]])
{
  return bondShadowMapHull(positions, shadowUniforms, structureUniforms, vid, iid, false);
}

vertex BondShadowMapVertexShaderOut ExternalBondShadowMapVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                                      constant ShadowUniforms& shadowUniforms [[buffer(2)]],
                                                                      constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                      uint vid [[vertex_id]],
                                                                      uint iid [[instance_id]])
{
  return bondShadowMapHull(positions, shadowUniforms, structureUniforms, vid, iid, true);
}

fragment BondShadowMapOutput BondShadowMapFragmentShader(BondShadowMapVertexShaderOut vert [[stage_in]],
                                                         constant ShadowUniforms& shadowUniforms [[buffer(0)]])
{
  BondShadowMapOutput output;

  float3 ro = float3(vert.frag_pos.xy, 0.0);
  const float3 rd = float3(0.0, 0.0, -1.0);

  float3 N;
  float ct;
  float t = bondImposterIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, N, ct);
  if (t < 0.0) discard_fragment();

  output.depth = bondShadowMapAxisDepth(shadowUniforms, vert.pointA, vert.pointB, ct);

  return output;
}

fragment BondShadowMapOutput ExternalBondShadowMapFragmentShader(BondShadowMapVertexShaderOut vert [[stage_in]],
                                                                 constant ShadowUniforms& shadowUniforms [[buffer(0)]],
                                                                 constant StructureUniforms& structureUniforms [[buffer(1)]])
{
  BondShadowMapOutput output;

  float3 ro = float3(vert.frag_pos.xy, 0.0);
  const float3 rd = float3(0.0, 0.0, -1.0);

  // an external bond is drawn cut off at the cell boundary, so it has to occlude cut off as well
  float4x4 toStructure = structureUniforms.inverseModelMatrix * shadowUniforms.viewMatrixInverse;
  float3 N;
  float ct;
  float t = bondImposterClippedIntersect(ro, rd, vert.pointA, vert.pointB, vert.radius, toStructure, structureUniforms, N, ct);
  if (t < 0.0) discard_fragment();

  output.depth = bondShadowMapAxisDepth(shadowUniforms, vert.pointA, vert.pointB, ct);

  return output;
}

// MARK: Bond ambient occlusion bake
// =============================================================================
// The other half of the bake: what the bonds receive rather than what they cast. Each drawn cylinder owns a
// square patch of an atlas, the angle around the axis running across it and the distance along the axis
// down it, and the pass below adds up how much of the sky reaches each of those texels.
//
// The pass rasterizes the patches themselves, not the bonds: six vertices place a quad over the patch, and
// the fragment shader turns the texel it lands on back into a point on the cylinder to test against the
// depth map. This mirrors how the atoms' atlas is filled, and like it the whole atlas is redrawn once per
// direction and blended.

struct BondAmbientOcclusionVertexShaderOut
{
  float4 position [[position]];
  // in the space the depth map was drawn in, so the structure's model matrix but not the bake's view
  float3 pointA [[ flat ]];
  float3 pointB [[ flat ]];
  float3 axis1 [[ flat ]];
  float3 axis2 [[ flat ]];
  float radius [[ flat ]];
};

static BondAmbientOcclusionVertexShaderOut bondAmbientOcclusionPatchQuad(const device InPerInstanceAttributesBonds *positions,
                                                                        constant StructureUniforms& structureUniforms,
                                                                        uint vid,
                                                                        uint iid,
                                                                        bool external)
{
  BondAmbientOcclusionVertexShaderOut vert;

  uint sub = vid / 6;
  BondCylinderFrame frame = bondCylinderFrame(positions, structureUniforms, structureUniforms.modelMatrix, iid, sub, external);
  vert.pointA = frame.a;
  vert.pointB = frame.b;
  vert.axis1 = frame.axis1;
  vert.axis2 = frame.axis2;
  vert.radius = frame.radius;

  uint patch = bondAmbientOcclusionPatch(positions, structureUniforms, iid, sub, external);
  uint patchNumber = uint(structureUniforms.bondAmbientOcclusionPatchNumber);
  float patchSize = structureUniforms.bondAmbientOcclusionPatchSize;
  float2 patchOrigin = float2(float(patch % patchNumber), float(patch / patchNumber));

  const float2 corners[6] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0),
                             float2(0.0, 1.0), float2(1.0, 0.0), float2(1.0, 1.0)};
  float2 corner = corners[vid % 6];

  float2 origin = patchSize * patchOrigin * structureUniforms.bondAmbientOcclusionInverseTextureSize;
  float extent = patchSize * structureUniforms.bondAmbientOcclusionInverseTextureSize;
  float2 clipPosition = (origin + extent * corner) * 2.0 - 1.0;
  vert.position = float4(clipPosition.x, -clipPosition.y, 0.0, 1.0);

  // invisible bonds have w set to -1; leaving their patches empty is harmless as nothing samples them
  if (positions[iid].position1.w < 0.0 || positions[iid].position2.w < 0.0)
  {
    vert.position = float4(0.0, 0.0, 0.0, -1.0);
  }

  return vert;
}

vertex BondAmbientOcclusionVertexShaderOut BondAmbientOcclusionVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                                           constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                           uint vid [[vertex_id]],
                                                                           uint iid [[instance_id]])
{
  return bondAmbientOcclusionPatchQuad(positions, structureUniforms, vid, iid, false);
}

vertex BondAmbientOcclusionVertexShaderOut ExternalBondAmbientOcclusionVertexShader(const device InPerInstanceAttributesBonds *positions [[buffer(1)]],
                                                                                   constant StructureUniforms& structureUniforms [[buffer(3)]],
                                                                                   uint vid [[vertex_id]],
                                                                                   uint iid [[instance_id]])
{
  return bondAmbientOcclusionPatchQuad(positions, structureUniforms, vid, iid, true);
}

fragment half BondAmbientOcclusionFragmentShader(BondAmbientOcclusionVertexShaderOut vert [[stage_in]],
                                                 constant ShadowUniforms& shadowUniforms [[buffer(0)]],
                                                 constant StructureUniforms& structureUniforms [[buffer(1)]],
                                                 constant float& weight [[buffer(2)]],
                                                 depth2d<float> shadowMap [[texture(0)]],
                                                 sampler shadowMapSampler [[sampler(0)]])
{
  float patchSize = structureUniforms.bondAmbientOcclusionPatchSize;
  uint2 texel = uint2(floor(vert.position.xy)) % uint2(patchSize, patchSize);
  // the two ends of the angular range are the same line of the cylinder, so both edge columns hold it and
  // the filter has a neighbour to reach for either side of the seam
  float2 uv = float2(texel) / float2(max(patchSize - 1.0, 1.0));

  float angle = 2.0 * M_PI_F * uv.x;
  float3 N = cos(angle) * vert.axis1 + sin(angle) * vert.axis2;
  float3 pos = mix(vert.pointA, vert.pointB, uv.y) + vert.radius * N;

  float4 shadowCoordinate = shadowUniforms.shadowMatrix * float4(pos, 1.0);
  shadowCoordinate.y = 1.0 - shadowCoordinate.y;
  float4 shadowPos = shadowCoordinate / shadowCoordinate.w;

  float4 normal = shadowUniforms.normalMatrix * float4(N, 0.0);
  if (normal.z < 0.0)
  {
    return 0.0;
  }

  // No margin is needed against the bond's own entry in the depth map: that entry is the axis, and every
  // point this pass tests is in front of it by the radius wherever it faces the camera at all.
  if (shadowMap.sample(shadowMapSampler, shadowPos.xy) >= shadowPos.z)
  {
    return weight * normal.z;
  }
  return 0.0;
}


template <typename VertexIn>
static FragOutput externalBondSelectionWorleyNoise3DImposterFragmentImpl(VertexIn vert,
                                           constant FrameUniforms& frameUniforms,
                                           constant StructureUniforms& structureUniforms,
                                           constant LightUniforms& lightUniforms)
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
  float n = filteredWorleyFactor(frequency*float3(t1.x,2.0*t1.y,t1.z), jitter);

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

fragment FragOutput externalBondSelectionWorleyNoise3DImposterFragmentShader(BondSelectionImposterVertexShaderOut vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return externalBondSelectionWorleyNoise3DImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

// used while the scene bonds shade per-pixel, see BondSelectionImposterPerSampleFragmentShaderIn
fragment FragOutput externalBondSelectionWorleyNoise3DImposterPerSampleFragmentShader(BondSelectionImposterPerSampleFragmentShaderIn vert [[stage_in]],
                                           constant FrameUniforms& frameUniforms [[buffer(0)]],
                                           constant StructureUniforms& structureUniforms [[buffer(1)]],
                                           constant LightUniforms& lightUniforms [[buffer(2)]])
{
  return externalBondSelectionWorleyNoise3DImposterFragmentImpl(vert, frameUniforms, structureUniforms, lightUniforms);
}

