/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

// MARK: Path-traced still images
// =============================================================================
// Progressive path tracer used by the picture-export path (renderPictureData) when the
// render mode is set to ray tracing. Atoms and bonds are analytic spheres and capped
// cylinders held in bounding-box acceleration structures; ribbons are the indexed
// triangle mesh of RKRibbonMesh. The sphere and cylinder intersection code is the same
// analytic math the imposter fragment shaders use, but the ray arrives in structure
// space (the instance transform is the structure's modelMatrix), so the clip planes of
// StructureUniforms apply directly without the eye-space round trip.
//
// Rather than adding a constant ambient term the way the rasterizer does, the ambient
// colour of a surface is treated as uniform environment radiance: it is collected only
// when the following cosine-weighted bounce ray escapes the scene. Averaged over many
// samples that reproduces ambient occlusion and colour bleeding for free, and replaces
// the pre-baked shadow-map ambient occlusion of the raster path.

#include <metal_stdlib>
#include <metal_raytracing>
#include "Common.h"
#include "PathTracerCommon.h"

using namespace metal;
using namespace raytracing;

// Buffer bindings of the intersection function table are shared by every function in the
// table, so the sphere and the cylinder arrays occupy distinct indices (0 and 3) even
// though each function only reads one of them.

// Written by the intersection functions, read back by the kernel after a hit. The
// normal is in structure space and is not normalized for cylinders' end caps.
struct PathTracerPayload
{
  float3 normal;
  float  axialFraction;   // 0 at pointA, 1 at pointB; unused for spheres
};

struct PathTracerBoundingBoxResult
{
  bool  accept   [[accept_intersection]];
  float distance [[distance]];
};

// MARK: Selection patterns
// =============================================================================
// The striped and Worley-noise selection styles, as the raster selection shaders draw them. Both
// are functions of where a point sits on the surface of the atom or the bond, measured in the
// structure's own space, which is what keeps a pattern still on the model while the camera moves
// around it.
//
// The stripes are the one pattern that settles visibility rather than colour: the raster shader
// discards the fragments between the bands, and that is what lets a selected atom show through its
// own selection. The intersection functions reject those points instead, so the ray carries on to
// whatever the gap reveals.

/// Whether a point lies on one of the bands the stripes are drawn on.
static bool pathTracerStripeCovers(float2 st, float density, float frequency)
{
  return fract(st.x * frequency) < density || fract(st.y * frequency) < density;
}

/// Longitude and latitude of a point on an atom, from the direction out of its centre.
static float2 pathTracerSphereStripeCoordinates(float3 radial)
{
  float3 n = normalize(radial);
  return float2(0.5 + 0.5 * atan2(n.z, n.x) / M_PI_F,
                0.5 - asin(clamp(n.y, -1.0, 1.0)) / M_PI_F);
}

/// Where a point on a bond sits in the model space of its cylinder: x and z across the axis,
/// measured from the bond's own two axes, and y along it. Mirrors bondSelectionImposterModelCoords.
static float3 pathTracerCylinderModelCoordinates(PathTracerCylinder cylinder, float3 offsetFromPointA, float axialFraction)
{
  float3 axis = cylinder.pointB.xyz - cylinder.pointA.xyz;
  float3 radial = (offsetFromPointA - axialFraction * axis) / cylinder.pointA.w;
  return float3(dot(radial, cylinder.axisX.xyz), axialFraction, dot(radial, cylinder.axisZ.xyz));
}

/// The angle around a bond and how far along it, which is what its stripes are wound from.
static float2 pathTracerCylinderStripeCoordinates(float3 modelCoordinates)
{
  return float2(0.5 + 0.5 * atan2(modelCoordinates.x, modelCoordinates.z) / M_PI_F, modelCoordinates.y);
}

/// How brightly the Worley-noise selection marks a point: the gap between the distances to the two
/// nearest cell centres, which darkens to nothing along the boundaries between the cells.
static float pathTracerWorleyNoise(float3 coordinates, float frequency, float jitter)
{
  float2 F = cellular3D(frequency * coordinates, jitter);
  return F.y - F.x;
}

/// Where a point on a ribbon sits within its own residue: x along the residue, y around the
/// cross-section, both running 0 to 1. Carried per vertex rather than derived, the ribbon having no
/// closed form to measure an angle from, so the barycentric weights of the hit interpolate it.
static float2 pathTracerRibbonStripeCoordinates(const device InPerVertex *vertices,
                                                const device uint *indices,
                                                uint triangle,
                                                float2 barycentric)
{
  uint i0 = indices[3 * triangle + 0];
  uint i1 = indices[3 * triangle + 1];
  uint i2 = indices[3 * triangle + 2];
  float w0 = 1.0 - barycentric.x - barycentric.y;
  return w0 * vertices[i0].stripeST + barycentric.x * vertices[i1].stripeST + barycentric.y * vertices[i2].stripeST;
}

/// How strongly the striped ribbon selection marks a point, tapering to nothing at the four edges
/// of the residue band so that the marking on one residue does not run into the next.
static float pathTracerRibbonStripeBand(float2 st)
{
  float along  = smoothstep(0.0, 0.06, st.x) * smoothstep(0.0, 0.06, 1.0 - st.x);
  float around = smoothstep(0.0, 0.10, st.y) * smoothstep(0.0, 0.10, 1.0 - st.y);
  return along * around;
}

/// Whether a point lies on one of the squares of a striped ribbon selection. The pattern is a
/// checkerboard over the residue band rather than the bands the atoms and the bonds are marked with.
static bool pathTracerRibbonStripeCovers(float2 st, float density, float frequency)
{
  if (pathTracerRibbonStripeBand(st) < 0.01) return false;
  return (fract(st.x * frequency) < density) != (fract(st.y * frequency) < density);
}

// MARK: Analytic intersections
// =============================================================================

// Entry point of the convex intersection of a solid with the six unit-cell clip planes.
// The visible solid is an intersection of convex constraints, so the entry parameter is
// the largest of all entry parameters and the exit parameter the smallest of all exit
// parameters. `entryPlane` is set to the index of the clip plane that produced the entry
// point, or -1 when the entry point lies on the solid itself.
//
// Unlike the imposter fragment shaders, which discard clipped fragments and therefore
// show hollow shells, the clipped opening is capped here: a path tracer must not let
// light leak into the interior of an atom or a bond.
static bool pathTracerClipPlanes(float3 origin,
                                 float3 direction,
                                 constant StructureUniforms &structureUniforms,
                                 thread float &tmin,
                                 thread float &tmax,
                                 thread int &entryPlane)
{
  float4 planes[6] = { structureUniforms.clipPlaneLeft,  structureUniforms.clipPlaneRight,
                       structureUniforms.clipPlaneTop,   structureUniforms.clipPlaneBottom,
                       structureUniforms.clipPlaneFront, structureUniforms.clipPlaneBack };
  float4 so = float4(origin, 1.0);
  float4 sd = float4(direction, 0.0);

  for (int i = 0; i < 6; i++)
  {
    float f0 = dot(planes[i], so);
    float df = dot(planes[i], sd);
    if (abs(df) < 1.0e-8)
    {
      if (f0 < 0.0) return false;
    }
    else
    {
      float tp = -f0 / df;
      if (df > 0.0)
      {
        if (tp > tmin) { tmin = tp; entryPlane = i; }
      }
      else
      {
        tmax = min(tmax, tp);
      }
    }
  }
  return true;
}

static float3 pathTracerClipPlaneNormal(int plane, constant StructureUniforms &structureUniforms)
{
  float4 planes[6] = { structureUniforms.clipPlaneLeft,  structureUniforms.clipPlaneRight,
                       structureUniforms.clipPlaneTop,   structureUniforms.clipPlaneBottom,
                       structureUniforms.clipPlaneFront, structureUniforms.clipPlaneBack };
  // the outward normal of the cap is opposite to the plane's inward gradient
  return -normalize(planes[plane].xyz);
}

[[intersection(bounding_box, triangle_data, instancing)]]
PathTracerBoundingBoxResult pathTracerSphereIntersection(float3 origin        [[origin]],
                                                         float3 direction     [[direction]],
                                                         float  minDistance   [[min_distance]],
                                                         float  maxDistance   [[max_distance]],
                                                         uint   primitiveIndex [[primitive_id]],
                                                         uint   instanceIndex  [[instance_id]],
                                                         ray_data PathTracerPayload &payload [[payload]],
                                                         const device PathTracerSphere *spheres        [[buffer(0)]],
                                                         const device PathTracerInstance *instances    [[buffer(1)]],
                                                         constant StructureUniforms *structureUniforms [[buffer(2)]])
{
  PathTracerBoundingBoxResult result;
  result.accept = false;
  result.distance = maxDistance;

  PathTracerInstance instance = instances[instanceIndex];
  PathTracerSphere sphere = spheres[instance.primitiveBase + primitiveIndex];

  float3 center = sphere.center.xyz;
  float  radius = sphere.center.w;

  float3 oc = origin - center;
  float a = dot(direction, direction);
  float b = dot(oc, direction);
  float c = dot(oc, oc) - radius * radius;
  float discriminant = b * b - a * c;
  if (discriminant < 0.0) return result;

  float root = sqrt(discriminant);
  float tmin = (-b - root) / a;
  float tmax = (-b + root) / a;
  int entryPlane = -1;

  if (instance.clipAtUnitCell != 0)
  {
    if (!pathTracerClipPlanes(origin, direction, structureUniforms[instance.structureIndex], tmin, tmax, entryPlane))
    {
      return result;
    }
  }

  if (tmax < tmin || tmin < minDistance || tmin > maxDistance) return result;

  // between the bands of a striped selection there is no surface at all, so that the atom the
  // shell encloses shows through its own selection
  if (instance.selectionStyle == PATH_TRACER_SELECTION_STRIPED)
  {
    constant StructureUniforms &su = structureUniforms[instance.structureIndex];
    float2 st = pathTracerSphereStripeCoordinates(oc + tmin * direction);
    if (!pathTracerStripeCovers(st, su.atomSelectionStripesDensity, su.atomSelectionStripesFrequency)) return result;
  }

  payload.normal = (entryPlane < 0)
      ? (oc + tmin * direction) / radius
      : pathTracerClipPlaneNormal(entryPlane, structureUniforms[instance.structureIndex]);
  payload.axialFraction = 0.0;

  result.accept = true;
  result.distance = tmin;
  return result;
}

[[intersection(bounding_box, triangle_data, instancing)]]
PathTracerBoundingBoxResult pathTracerCylinderIntersection(float3 origin        [[origin]],
                                                           float3 direction     [[direction]],
                                                           float  minDistance   [[min_distance]],
                                                           float  maxDistance   [[max_distance]],
                                                           uint   primitiveIndex [[primitive_id]],
                                                           uint   instanceIndex  [[instance_id]],
                                                           ray_data PathTracerPayload &payload [[payload]],
                                                           const device PathTracerInstance *instances   [[buffer(1)]],
                                                           constant StructureUniforms *structureUniforms [[buffer(2)]],
                                                           const device PathTracerCylinder *cylinders   [[buffer(3)]])
{
  PathTracerBoundingBoxResult result;
  result.accept = false;
  result.distance = maxDistance;

  PathTracerInstance instance = instances[instanceIndex];
  PathTracerCylinder cylinder = cylinders[instance.primitiveBase + primitiveIndex];

  float3 pointA = cylinder.pointA.xyz;
  float3 pointB = cylinder.pointB.xyz;
  float  radius = cylinder.pointA.w;

  // the k2/k1/k0 formulation of the imposter shaders assumes a normalized direction, but
  // the direction handed to an intersection function is not normalized, so work with a
  // normalized copy and convert the resulting ray parameter back at the end
  float invLength = 1.0 / length(direction);
  float3 rd = direction * invLength;

  float3 ba = pointB - pointA;
  float3 oc = origin - pointA;
  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);
  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - radius * radius * baba;

  float tmin = -1.0e30;
  float tmax = 1.0e30;
  // -1 undetermined, 0 cylinder mantle, 1 end cap
  int entryType = -1;

  // the infinite cylinder around the axis
  if (k2 > 1.0e-6 * baba)
  {
    float h = k1 * k1 - k2 * k0;
    if (h < 0.0) return result;
    h = sqrt(h);
    tmin = (-k1 - h) / k2;
    tmax = (-k1 + h) / k2;
    entryType = 0;
  }
  else if (k0 > 0.0)
  {
    // the ray is (nearly) parallel to the axis and lies outside the cylinder
    return result;
  }

  // the slab between the two end-cap planes: 0 <= baoc + t * bard <= baba
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
    return result;
  }

  int entryPlane = -1;
  if (instance.clipAtUnitCell != 0)
  {
    // the clip-plane parameters are measured along the same normalized direction
    if (!pathTracerClipPlanes(origin, rd, structureUniforms[instance.structureIndex], tmin, tmax, entryPlane))
    {
      return result;
    }
    if (entryPlane >= 0) entryType = 2;
  }

  if (tmax < tmin || entryType < 0) return result;

  // convert back to the parameterisation of the unnormalized ray direction
  float t = tmin * invLength;
  if (t < minDistance || t > maxDistance) return result;

  float y = baoc + tmin * bard;
  float axialFraction = clamp(y / baba, 0.0, 1.0);

  // as for the atoms above: the gaps between the bands are not surface, so the bond shows through
  if (instance.selectionStyle == PATH_TRACER_SELECTION_STRIPED)
  {
    constant StructureUniforms &su = structureUniforms[instance.structureIndex];
    float3 modelCoordinates = pathTracerCylinderModelCoordinates(cylinder, oc + tmin * rd, axialFraction);
    float2 st = pathTracerCylinderStripeCoordinates(modelCoordinates);
    if (!pathTracerStripeCovers(st, su.bondSelectionStripesDensity, su.bondSelectionStripesFrequency)) return result;
  }

  payload.axialFraction = axialFraction;

  if (entryType == 0)
  {
    payload.normal = (oc + tmin * rd - ba * y / baba) / radius;
  }
  else if (entryType == 1)
  {
    payload.normal = (y < 0.5 * baba) ? -ba / sqrt(baba) : ba / sqrt(baba);
  }
  else
  {
    payload.normal = pathTracerClipPlaneNormal(entryPlane, structureUniforms[instance.structureIndex]);
  }

  result.accept = true;
  result.distance = t;
  return result;
}

/// The gaps of a striped ribbon selection. Ribbons are triangles rather than analytic solids, so
/// their shells are traced with the built-in triangle test and this only settles which of its hits
/// count: everywhere the raster shader discards, the shell is not there and the ray carries on to
/// whatever the gap reveals. Only the striped shells are routed through here, the Worley-noise ones
/// covering their whole mesh.
[[intersection(triangle, triangle_data, instancing)]]
bool pathTracerRibbonSelectionIntersection(float2 barycentric  [[barycentric_coord]],
                                           uint primitiveIndex [[primitive_id]],
                                           uint instanceIndex  [[instance_id]],
                                           const device PathTracerInstance *instances    [[buffer(1)]],
                                           constant StructureUniforms *structureUniforms [[buffer(2)]],
                                           const device InPerVertex *ribbonVertices      [[buffer(4)]],
                                           const device uint *ribbonIndices              [[buffer(5)]])
{
  PathTracerInstance instance = instances[instanceIndex];
  constant StructureUniforms &su = structureUniforms[instance.structureIndex];

  float2 st = pathTracerRibbonStripeCoordinates(ribbonVertices, ribbonIndices,
                                                instance.primitiveBase + primitiveIndex, barycentric);
  return pathTracerRibbonStripeCovers(st, su.atomSelectionStripesDensity, su.atomSelectionStripesFrequency);
}

// MARK: Sampling
// =============================================================================

static uint pathTracerHash(uint x)
{
  x ^= x >> 16;
  x *= 0x7feb352du;
  x ^= x >> 15;
  x *= 0x846ca68bu;
  x ^= x >> 16;
  return x;
}

static float pathTracerRandom(thread uint &state)
{
  state = state * 1664525u + 1013904223u;
  return float(pathTracerHash(state) >> 8) * (1.0 / 16777216.0);
}

// Cosine-weighted direction in the hemisphere around `normal`. Cosine weighting cancels
// the N.L factor of the diffuse BRDF, so the bounce carries the albedo unmodified.
static float3 pathTracerCosineDirection(float3 normal, thread uint &state)
{
  float u1 = pathTracerRandom(state);
  float u2 = pathTracerRandom(state);

  float radius = sqrt(u1);
  float phi = 2.0 * M_PI_F * u2;

  float3 up = abs(normal.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
  float3 tangent = normalize(cross(up, normal));
  float3 bitangent = cross(normal, tangent);

  return normalize(tangent * (radius * cos(phi)) +
                   bitangent * (radius * sin(phi)) +
                   normal * sqrt(max(0.0, 1.0 - u1)));
}

// MARK: Materials
// =============================================================================

struct PathTracerSurface
{
  float3 ambient;
  float3 diffuse;
  float3 specular;
  float  shininess;
  uint   category;
};

static float3 pathTracerRibbonColor(float structureType, constant StructureUniforms &structureUniforms)
{
  if (structureType < 0.5) return structureUniforms.ribbonCoilColor.xyz;
  if (structureType < 1.5) return structureUniforms.ribbonHelixColor.xyz;
  return structureUniforms.ribbonSheetColor.xyz;
}

static PathTracerSurface pathTracerSphereSurface(PathTracerSphere sphere, constant StructureUniforms &su)
{
  PathTracerSurface surface;

  if (su.colorAtomsWithBondColor)
  {
    surface.ambient  = su.bondAmbientColor.xyz;
    surface.diffuse  = su.bondDiffuseColor.xyz;
    surface.specular = su.bondSpecularColor.xyz;
  }
  else
  {
    surface.ambient  = (su.atomAmbientColor  * sphere.ambient).xyz;
    surface.diffuse  = (su.atomDiffuseColor  * sphere.diffuse).xyz;
    surface.specular = (su.atomSpecularColor * sphere.specular).xyz;
  }
  surface.shininess = su.atomShininess;
  surface.category = PATH_TRACER_CATEGORY_ATOM;

  return surface;
}

static PathTracerSurface pathTracerCylinderSurface(PathTracerCylinder cylinder, float axialFraction, constant StructureUniforms &su)
{
  PathTracerSurface surface;

  float4 diffuseColor = (su.bondColorMode == 0) ? su.bondDiffuseColor : su.atomDiffuseColor;
  float4 color1 = diffuseColor * cylinder.color1;
  float4 color2 = diffuseColor * cylinder.color2;

  surface.ambient  = su.bondAmbientColor.xyz;
  surface.specular = su.bondSpecularColor.xyz;
  switch (su.bondColorMode)
  {
    case 0:
      surface.diffuse = su.bondDiffuseColor.xyz;
      break;
    case 1:
      surface.diffuse = (axialFraction < 0.5 ? color1 : color2).xyz;
      break;
    default:
      surface.diffuse = mix(color1, color2, smoothstep(0.0, 1.0, axialFraction)).xyz;
      break;
  }
  surface.shininess = su.bondShininess;
  surface.category = PATH_TRACER_CATEGORY_BOND;

  return surface;
}

/// The exposure and the hue/saturation/value adjustment belonging to whichever of the atoms, the
/// bonds or the ribbons of a structure a colour came from. `adjustHueSaturationValue` is there for
/// the bond selections, which the raster shaders exposure-map without also shifting.
static float3 pathTracerToneMap(float3 radiance, uint category, constant StructureUniforms &su,
                                bool adjustHueSaturationValue = true)
{
  bool  useHDR = su.atomHDR;
  float exposure = su.atomHDRExposure;
  float hueScale = su.atomHue;
  float saturationScale = su.atomSaturation;
  float valueScale = su.atomValue;

  if (category == PATH_TRACER_CATEGORY_BOND)
  {
    useHDR = su.bondHDR;
    exposure = su.bondHDRExposure;
    hueScale = su.bondHue;
    saturationScale = su.bondSaturation;
    valueScale = su.bondValue;
  }
  else if (category == PATH_TRACER_CATEGORY_RIBBON)
  {
    useHDR = su.ribbonHDR;
    exposure = su.ribbonHDRExposure;
    hueScale = su.ribbonHue;
    saturationScale = su.ribbonSaturation;
    valueScale = su.ribbonValue;
  }

  float3 color = useHDR ? (1.0 - exp2(-radiance * exposure)) : radiance;

  if (!adjustHueSaturationValue) return color;

  float3 hsv = rgb2hsv(color);
  hsv.x = hsv.x * hueScale;
  hsv.y = hsv.y * saturationScale;
  hsv.z = hsv.z * valueScale;

  return hsv2rgb(hsv);
}

// MARK: Lights
// =============================================================================

/// The lights of the raster path are written in eye space, so they are brought into the world space
/// the trace works in once per pixel rather than once per hit.
struct PathTracerLights
{
  float3 position[NUMBER_OF_LIGHTS];
  float3 direction[NUMBER_OF_LIGHTS];
  float3 spotAxis[NUMBER_OF_LIGHTS];
};

static PathTracerLights pathTracerWorldLights(constant FrameUniforms &frameUniforms,
                                              constant LightUniforms &lightUniforms)
{
  PathTracerLights lights;

  for (uint li = 0; li < NUMBER_OF_LIGHTS; li++)
  {
    float4 lightPosition = lightUniforms.lights[li].position;
    lights.position[li] = (frameUniforms.viewMatrixInverse * float4(lightPosition.xyz, 1.0)).xyz;
    lights.direction[li] = normalize((frameUniforms.viewMatrixInverse * float4(lightPosition.xyz, 0.0)).xyz);
    lights.spotAxis[li] = normalize((frameUniforms.viewMatrixInverse * float4(lightUniforms.lights[li].spotDirection.xyz, 0.0)).xyz);
  }

  return lights;
}

/// The direction to a light and how much of it survives the distance and the spotlight cone. The
/// same falloff the rasterizer applies, so that the two renderers agree.
struct PathTracerLightSample
{
  float3 direction;
  float  distance;
  float  attenuation;
};

static PathTracerLightSample pathTracerSampleLight(constant LightUniforms &lightUniforms,
                                                   PathTracerLights lights,
                                                   uint index,
                                                   float3 position)
{
  float3 lightWorldPosition = lights.position[index];
  float3 lightWorldDirection = lights.direction[index];
  float3 spotWorldAxis = lights.spotAxis[index];

  PathTracerLightSample light;

  bool positional = lightUniforms.lights[index].position.w > 0.5;
  light.direction = positional ? normalize(lightWorldPosition - position) : lightWorldDirection;
  light.distance = positional ? length(lightWorldPosition - position) : INFINITY;
  light.attenuation = 1.0;

  if (positional)
  {
    light.attenuation = 1.0 / max(lightUniforms.lights[index].constantAttenuation +
                                  lightUniforms.lights[index].linearAttenuation * light.distance +
                                  lightUniforms.lights[index].quadraticAttenuation * light.distance * light.distance,
                                  1.0e-4);

    if (lightUniforms.lights[index].lightType > 1.5) // spot
    {
      float spotCosine = dot(-light.direction, spotWorldAxis);
      float cutoffCosine = cos((M_PI_F / 180.0) * clamp(lightUniforms.lights[index].spotCutoff, 0.0, 180.0));
      light.attenuation *= (spotCosine < cutoffCosine)
                               ? 0.0
                               : pow(spotCosine, max(lightUniforms.lights[index].spotExponent, 0.0));
    }
  }

  return light;
}

/// Ambient, diffuse and specular of every enabled light, with nothing shadowed and nothing
/// occluded. What accumulateLighting does for the raster shaders, and what the selection overlay
/// wants: the raster selection imposters read neither the shadow mask nor the baked occlusion map,
/// a selection being a marking on the model rather than a part of it.
static float3 pathTracerLocalLighting(constant LightUniforms &lightUniforms,
                                      PathTracerLights lights,
                                      PathTracerSurface surface,
                                      float3 position,
                                      float3 normal,
                                      float3 viewDirection)
{
  float3 color = surface.ambient * lightUniforms.sceneAmbient.xyz;

  for (uint li = 0; li < NUMBER_OF_LIGHTS; li++)
  {
    if (lightUniforms.lights[li].enabled < 0.5) continue;

    PathTracerLightSample light = pathTracerSampleLight(lightUniforms, lights, li, position);
    if (light.attenuation <= 0.0) continue;

    float cosTheta = max(dot(normal, light.direction), 0.0);
    color += surface.diffuse * light.attenuation * lightUniforms.lights[li].diffuse.xyz * cosTheta;

    float3 reflectDirection = reflect(-light.direction, normal);
    float specularFactor = pow(max(dot(reflectDirection, viewDirection), 0.0),
                               lightUniforms.lights[li].shininess + surface.shininess);
    color += surface.specular * light.attenuation * lightUniforms.lights[li].specular.xyz * specularFactor;
  }

  return color;
}

/// The colour and the coverage of the selection overlay where a primary ray met a selection shell,
/// premultiplied, in the form the resolve pass composites.
static float4 pathTracerSelectionOverlay(PathTracerInstance instance,
                                         constant StructureUniforms &su,
                                         constant FrameUniforms &frameUniforms,
                                         constant LightUniforms &lightUniforms,
                                         PathTracerLights lights,
                                         const device PathTracerSphere *spheres,
                                         const device PathTracerCylinder *cylinders,
                                         const device InPerVertex *ribbonVertices,
                                         const device uint *ribbonIndices,
                                         uint primitiveIndex,
                                         float3 position,
                                         float3 normal,
                                         float3 viewDirection,
                                         float axialFraction,
                                         float2 barycentric)
{
  // the shell is placed by the structure's model matrix, so a pattern anchored to the model is read
  // at the hit brought back into the space the geometry was packed in
  float3 structurePosition = (su.inverseModelMatrix * float4(position, 1.0)).xyz;

  PathTracerSurface surface;
  float intensity;
  // the striped ribbons fade their marking out towards the ends of a residue; everything else marks
  // at full strength wherever it marks at all
  float radianceScale = 1.0;

  if (instance.kind == PATH_TRACER_KIND_RIBBON)
  {
    uint triangle = instance.primitiveBase + primitiveIndex;
    uint i0 = ribbonIndices[3 * triangle + 0];
    uint i1 = ribbonIndices[3 * triangle + 1];
    uint i2 = ribbonIndices[3 * triangle + 2];
    float w0 = 1.0 - barycentric.x - barycentric.y;

    // A ribbon is marked in the colour of a selection rather than its own, so the residue colours
    // play no part here. The selection of a ribbon is driven by the atom settings throughout, there
    // being no ribbon-specific ones, but it takes the material of the ribbon it lies on.
    float3 baseColor = float3(1.0, 1.0, 0.0);
    surface.ambient  = (su.ribbonAmbientColor  * float4(baseColor, 1.0)).xyz;
    surface.diffuse  = (su.ribbonDiffuseColor  * float4(baseColor, 1.0)).xyz;
    surface.specular = su.ribbonSpecularColor.xyz;
    surface.shininess = su.ribbonShininess;
    surface.category = PATH_TRACER_CATEGORY_RIBBON;
    intensity = su.atomSelectionIntensity;

    if (instance.selectionStyle == PATH_TRACER_SELECTION_WORLEY)
    {
      // left unnormalized, as the interpolated normal of the raster shader is
      float3 t1 = w0 * ribbonVertices[i0].normal.xyz +
                  barycentric.x * ribbonVertices[i1].normal.xyz +
                  barycentric.y * ribbonVertices[i2].normal.xyz;
      float n = pathTracerWorleyNoise(float3(t1.x, t1.z, t1.y),
                                      su.atomSelectionWorleyNoise3DFrequency,
                                      su.atomSelectionWorleyNoise3DJitter);
      surface.ambient *= n;
      surface.diffuse *= n;
      surface.specular *= n;
    }
    else
    {
      float2 st = w0 * ribbonVertices[i0].stripeST +
                  barycentric.x * ribbonVertices[i1].stripeST +
                  barycentric.y * ribbonVertices[i2].stripeST;
      radianceScale = pathTracerRibbonStripeBand(st);
    }
  }
  else if (instance.kind == PATH_TRACER_KIND_SPHERE)
  {
    PathTracerSphere sphere = spheres[instance.primitiveBase + primitiveIndex];
    surface = pathTracerSphereSurface(sphere, su);
    // A marking keeps the colours of the atom it marks even where the atoms themselves are drawn in
    // the colour of their bonds: the raster selection imposters carry no colorAtomsWithBondColor
    // branch, unlike the atom shader whose material pathTracerSphereSurface reproduces.
    surface.ambient  = (su.atomAmbientColor  * sphere.ambient).xyz;
    surface.diffuse  = (su.atomDiffuseColor  * sphere.diffuse).xyz;
    surface.specular = (su.atomSpecularColor * sphere.specular).xyz;
    intensity = su.atomSelectionIntensity;

    if (instance.selectionStyle == PATH_TRACER_SELECTION_WORLEY)
    {
      float3 t1 = normalize(structurePosition - sphere.center.xyz);
      float n = pathTracerWorleyNoise(float3(t1.x, t1.z, t1.y),
                                      su.atomSelectionWorleyNoise3DFrequency,
                                      su.atomSelectionWorleyNoise3DJitter);
      surface.ambient *= n;
      surface.diffuse *= n;
      surface.specular *= n;
    }
  }
  else
  {
    PathTracerCylinder cylinder = cylinders[instance.primitiveBase + primitiveIndex];
    surface = pathTracerCylinderSurface(cylinder, axialFraction, su);
    intensity = su.bondSelectionIntensity;

    if (instance.selectionStyle == PATH_TRACER_SELECTION_WORLEY)
    {
      float3 t1 = pathTracerCylinderModelCoordinates(cylinder, structurePosition - cylinder.pointA.xyz, axialFraction);
      float n = pathTracerWorleyNoise(float3(t1.x, 2.0 * t1.y, t1.z),
                                      su.bondSelectionWorleyNoise3DFrequency,
                                      su.bondSelectionWorleyNoise3DJitter);
      surface.ambient *= n;
      surface.diffuse *= n;
      surface.specular *= n;
    }
  }

  if (instance.selectionStyle == PATH_TRACER_SELECTION_STRIPED)
  {
    // the raster selection shaders draw the bands as a flat yellow diffuse surface, taking neither
    // the ambient nor the specular of whatever they mark
    surface.ambient = float3(0.0);
    surface.diffuse = float3(1.0, 1.0, 0.0);
    surface.specular = float3(0.0);
    surface.shininess = 0.0;
  }

  float3 radiance = radianceScale * pathTracerLocalLighting(lightUniforms, lights, surface, position, normal, viewDirection);

  // Tone mapped here rather than in the resolve pass because the rasterizer maps the overlay and
  // the surface under it separately and blends the two afterwards, and the mapping is not linear.
  // The bond selection shaders stop at the exposure, unlike the atom and the ribbon ones, so neither
  // does this.
  float3 color = pathTracerToneMap(radiance, surface.category, su,
                                   surface.category != PATH_TRACER_CATEGORY_BOND);

  // Not held at one. The selection intensity level reaches two, and above one the raster blend
  // over-drives the marking rather than saturating, its destination factor going negative. The
  // resolve pass mixes by this same weight, which extrapolates past the overlay colour in exactly
  // the way that blend does.
  float alpha = max(frameUniforms.bloomLevel * intensity, 0.0);
  return float4(alpha * color, alpha);
}

// MARK: Shadow mask
// =============================================================================
// The rasterizer has no way of knowing whether something stands between a surface and a light,
// so with an off-axis rig it lights faces that the path tracer leaves in shadow. This kernel
// answers that one question for the whole frame: it finds the molecular surface at each pixel
// the same way the tracer's primary ray does, and casts one occlusion ray per enabled light.
//
// It is a compute pass rather than a test inside the fragment shaders because a ray query in a
// fragment shader needs a newer Metal than this deployment target allows, and because imposters
// write their own depth and so defeat early-z: a per-pixel pass traces once for what a
// per-fragment one would trace several times over.
//
// The mask records visibility only. Falloff, the spotlight cone and the surface's own
// orientation stay with the rasterizer, which already computes them.

/// One bit per light, set when the light reaches the surface at this pixel.
kernel void pathTracerShadowMaskKernel(uint2 gid [[thread_position_in_grid]],
                                       constant PathTracerUniforms &uniforms          [[buffer(0)]],
                                       constant FrameUniforms &frameUniforms          [[buffer(1)]],
                                       constant StructureUniforms *structureUniforms  [[buffer(2)]],
                                       constant LightUniforms &lightUniforms          [[buffer(3)]],
                                       const device PathTracerInstance *instances     [[buffer(4)]],
                                       const device InPerVertex *ribbonVertices       [[buffer(5)]],
                                       const device uint *ribbonIndices               [[buffer(6)]],
                                       instance_acceleration_structure accelerationStructure [[buffer(7)]],
                                       intersection_function_table<triangle_data, instancing> functionTable [[buffer(8)]],
                                       texture2d<uint, access::write> shadowMask      [[texture(0)]])
{
  if (gid.x >= uniforms.width || gid.y >= uniforms.height) return;

  // every light lit: the value that leaves the rasterizer's shading untouched
  const uint allLit = (NUMBER_OF_LIGHTS >= 32) ? 0xFFFFFFFFu : ((1u << NUMBER_OF_LIGHTS) - 1u);

  // the primary ray runs through the pixel centre rather than a jittered point, so the mask is
  // the same every frame and shadow edges do not crawl
  float2 uv = (float2(gid) + 0.5) / float2(float(uniforms.width), float(uniforms.height));
  float2 ndc = float2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);

  float4 nearEye = frameUniforms.projectionMatrixInverse * float4(ndc, 0.0, 1.0);
  float4 farEye  = frameUniforms.projectionMatrixInverse * float4(ndc, 1.0, 1.0);
  nearEye /= nearEye.w;
  farEye  /= farEye.w;
  float3 rayOrigin = (frameUniforms.viewMatrixInverse * nearEye).xyz;
  float3 rayDirection = normalize((frameUniforms.viewMatrixInverse * farEye).xyz - rayOrigin);

  intersector<triangle_data, instancing> primaryIntersector;
  primaryIntersector.assume_geometry_type(geometry_type::bounding_box | geometry_type::triangle);

  intersector<triangle_data, instancing> shadowIntersector;
  shadowIntersector.assume_geometry_type(geometry_type::bounding_box | geometry_type::triangle);
  shadowIntersector.accept_any_intersection(true);

  ray primaryRay;
  primaryRay.origin = rayOrigin;
  primaryRay.direction = rayDirection;
  primaryRay.min_distance = 0.0;
  primaryRay.max_distance = INFINITY;

  PathTracerPayload payload;
  payload.normal = float3(0.0, 0.0, 1.0);
  payload.axialFraction = 0.0;

  // the selection shells are left out: the raster selection is not shadowed and does not shadow
  intersector<triangle_data, instancing>::result_type hit =
      primaryIntersector.intersect(primaryRay, accelerationStructure, PATH_TRACER_MASK_SURFACE, functionTable, payload);

  if (hit.type == intersection_type::none)
  {
    shadowMask.write(uint4(allLit, 0, 0, 0), gid);
    return;
  }

  PathTracerInstance instance = instances[hit.instance_id];
  constant StructureUniforms &su = structureUniforms[instance.structureIndex];

  float3 hitPosition = rayOrigin + hit.distance * rayDirection;
  float3 normal;

  if (instance.kind == PATH_TRACER_KIND_RIBBON)
  {
    uint triangle = instance.primitiveBase + hit.primitive_id;
    uint i0 = ribbonIndices[3 * triangle + 0];
    uint i1 = ribbonIndices[3 * triangle + 1];
    uint i2 = ribbonIndices[3 * triangle + 2];

    float2 barycentric = hit.triangle_barycentric_coord;
    float w0 = 1.0 - barycentric.x - barycentric.y;
    float3 localNormal = w0 * ribbonVertices[i0].normal.xyz +
                         barycentric.x * ribbonVertices[i1].normal.xyz +
                         barycentric.y * ribbonVertices[i2].normal.xyz;
    normal = normalize((su.modelMatrix * float4(localNormal, 0.0)).xyz);
  }
  else
  {
    normal = normalize((su.modelMatrix * float4(normalize(payload.normal), 0.0)).xyz);
  }

  if (dot(normal, rayDirection) > 0.0) normal = -normal;

  uint mask = allLit;

  for (uint li = 0; li < NUMBER_OF_LIGHTS; li++)
  {
    if (lightUniforms.lights[li].enabled < 0.5) continue;

    float4 lightPosition = lightUniforms.lights[li].position;
    bool positionalLight = lightPosition.w > 0.5;

    float3 lightWorldPosition = (frameUniforms.viewMatrixInverse * float4(lightPosition.xyz, 1.0)).xyz;
    float3 lightDirection = positionalLight
                                ? normalize(lightWorldPosition - hitPosition)
                                : normalize((frameUniforms.viewMatrixInverse * float4(lightPosition.xyz, 0.0)).xyz);
    float lightDistance = positionalLight ? length(lightWorldPosition - hitPosition) : INFINITY;

    // a surface turned away from a light is left marked as lit: the rasterizer's own N.L already
    // takes all of that light away, and tracing from behind the surface would only hit itself
    if (dot(normal, lightDirection) <= 0.0) continue;

    ray shadowRay;
    shadowRay.origin = hitPosition + normal * uniforms.rayEpsilon;
    shadowRay.direction = lightDirection;
    shadowRay.min_distance = 0.0;
    shadowRay.max_distance = lightDistance;

    PathTracerPayload shadowPayload;
    shadowPayload.normal = float3(0.0, 0.0, 1.0);
    shadowPayload.axialFraction = 0.0;

    intersection_type shadowHit =
        shadowIntersector.intersect(shadowRay, accelerationStructure, PATH_TRACER_MASK_SURFACE, functionTable, shadowPayload).type;

    if (shadowHit != intersection_type::none)
    {
      mask &= ~(1u << li);
    }
  }

  shadowMask.write(uint4(mask, 0, 0, 0), gid);
}

// MARK: Path tracing kernel
// =============================================================================

kernel void pathTracerAccumulateKernel(uint2 gid [[thread_position_in_grid]],
                                       constant PathTracerUniforms &uniforms          [[buffer(0)]],
                                       constant FrameUniforms &frameUniforms          [[buffer(1)]],
                                       constant StructureUniforms *structureUniforms  [[buffer(2)]],
                                       constant LightUniforms &lightUniforms          [[buffer(3)]],
                                       const device PathTracerSphere *spheres         [[buffer(4)]],
                                       const device PathTracerCylinder *cylinders     [[buffer(5)]],
                                       const device PathTracerInstance *instances     [[buffer(6)]],
                                       const device InPerVertex *ribbonVertices       [[buffer(7)]],
                                       const device uint *ribbonIndices               [[buffer(8)]],
                                       instance_acceleration_structure accelerationStructure [[buffer(9)]],
                                       intersection_function_table<triangle_data, instancing> functionTable [[buffer(10)]],
                                       device float4 *accumulation [[buffer(11)]],
                                       device float4 *surfaceInfo  [[buffer(12)]],
                                       device float4 *indirect     [[buffer(13)]],
                                       device float4 *selection    [[buffer(14)]])
{
  if (gid.x >= uniforms.width || gid.y >= uniforms.height) return;

  PathTracerLights lights = pathTracerWorldLights(frameUniforms, lightUniforms);
  // ambient belongs to the scene rather than to the lights, so which lights are on does not alter it
  float3 totalAmbient = lightUniforms.sceneAmbient.xyz;

  uint state = pathTracerHash(gid.x + gid.y * uniforms.width + pathTracerHash(uniforms.seed));

  float3 accumulatedDirect = float3(0.0);
  float3 accumulatedIndirect = float3(0.0);
  float  accumulatedCoverage = 0.0;
  float  accumulatedVisibility = 0.0;

  // the selection overlay, premultiplied: rgb summed already weighted by the coverage in a
  float3 accumulatedSelection = float3(0.0);
  float  accumulatedSelectionCoverage = 0.0;

  float primaryDepth = 1.0;
  uint  primaryStructure = 0;
  uint  primaryCategory = PATH_TRACER_CATEGORY_ATOM;
  bool  recordedPrimary = false;

  // 1.0 leaves the overlay behind anything the rasterizer drew, which is what a pixel without a
  // selection on it should be
  float selectionDepth = 1.0;
  bool  recordedSelection = false;

  intersector<triangle_data, instancing> primaryIntersector;
  primaryIntersector.assume_geometry_type(geometry_type::bounding_box | geometry_type::triangle);

  intersector<triangle_data, instancing> shadowIntersector;
  shadowIntersector.assume_geometry_type(geometry_type::bounding_box | geometry_type::triangle);
  shadowIntersector.accept_any_intersection(true);

  for (uint sampleIndex = 0; sampleIndex < uniforms.samplesPerDispatch; sampleIndex++)
  {
    float2 jitter = float2(pathTracerRandom(state), pathTracerRandom(state));
    float2 uv = (float2(gid) + jitter) / float2(float(uniforms.width), float(uniforms.height));
    // the framebuffer origin is top-left, normalized device coordinates point up
    float2 ndc = float2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);

    float4 nearEye = frameUniforms.projectionMatrixInverse * float4(ndc, 0.0, 1.0);
    float4 farEye  = frameUniforms.projectionMatrixInverse * float4(ndc, 1.0, 1.0);
    nearEye /= nearEye.w;
    farEye  /= farEye.w;
    float3 rayOrigin = (frameUniforms.viewMatrixInverse * nearEye).xyz;
    float3 rayTarget = (frameUniforms.viewMatrixInverse * farEye).xyz;
    float3 rayDirection = normalize(rayTarget - rayOrigin);

    // kept for the selection overlay, which is traced along the same ray once the path is done
    float3 primaryOrigin = rayOrigin;
    float3 primaryDirection = rayDirection;
    float  primaryDistance = INFINITY;

    float3 direct = float3(0.0);
    float3 indirectRadiance = float3(0.0);
    float3 throughput = float3(1.0);
    float3 pendingAmbient = float3(0.0);
    bool   hitAnything = false;
    // the cosine-sampled ray leaving the primary hit is exactly one sample of the
    // cosine-weighted hemispherical visibility that the baked occlusion map integrates
    // over its 1992 directions, so its escape rate is the same quantity
    bool   primaryRayEscaped = false;

    for (uint bounce = 0; bounce <= uniforms.maximumBounces; bounce++)
    {
      ray r;
      r.origin = rayOrigin;
      r.direction = rayDirection;
      r.min_distance = (bounce == 0) ? 0.0 : uniforms.rayEpsilon;
      r.max_distance = INFINITY;

      PathTracerPayload payload;
      payload.normal = float3(0.0, 0.0, 1.0);
      payload.axialFraction = 0.0;

      // the path sees the model alone: a selection shell neither occludes nor bounces light
      intersector<triangle_data, instancing>::result_type hit =
          primaryIntersector.intersect(r, accelerationStructure, PATH_TRACER_MASK_SURFACE, functionTable, payload);

      if (hit.type == intersection_type::none)
      {
        if (bounce == 1) primaryRayEscaped = true;
        // the surface of the previous bounce sees the environment
        indirectRadiance += pendingAmbient;
        break;
      }

      PathTracerInstance instance = instances[hit.instance_id];
      constant StructureUniforms &su = structureUniforms[instance.structureIndex];

      float3 hitPosition = rayOrigin + hit.distance * rayDirection;
      float3 normal;
      PathTracerSurface surface;

      if (instance.kind == PATH_TRACER_KIND_RIBBON)
      {
        uint triangle = instance.primitiveBase + hit.primitive_id;
        uint i0 = ribbonIndices[3 * triangle + 0];
        uint i1 = ribbonIndices[3 * triangle + 1];
        uint i2 = ribbonIndices[3 * triangle + 2];

        float2 barycentric = hit.triangle_barycentric_coord;
        float w0 = 1.0 - barycentric.x - barycentric.y;
        float3 localNormal = w0 * ribbonVertices[i0].normal.xyz +
                             barycentric.x * ribbonVertices[i1].normal.xyz +
                             barycentric.y * ribbonVertices[i2].normal.xyz;
        normal = normalize((su.modelMatrix * float4(localNormal, 0.0)).xyz);

        float3 baseColor = pathTracerRibbonColor(ribbonVertices[i0].pad.x, su);
        surface.ambient  = (su.ribbonAmbientColor  * float4(baseColor, 1.0)).xyz;
        surface.diffuse  = (su.ribbonDiffuseColor  * float4(baseColor, 1.0)).xyz;
        surface.specular = su.ribbonSpecularColor.xyz;
        surface.shininess = su.ribbonShininess;
        surface.category = PATH_TRACER_CATEGORY_RIBBON;
      }
      else
      {
        normal = normalize((su.modelMatrix * float4(normalize(payload.normal), 0.0)).xyz);

        if (instance.kind == PATH_TRACER_KIND_SPHERE)
        {
          surface = pathTracerSphereSurface(spheres[instance.primitiveBase + hit.primitive_id], su);
        }
        else
        {
          surface = pathTracerCylinderSurface(cylinders[instance.primitiveBase + hit.primitive_id], payload.axialFraction, su);
        }
      }

      // ribbons are drawn double-sided, and a bounce ray can start inside a cut solid
      if (dot(normal, rayDirection) > 0.0) normal = -normal;

      if (bounce == 0)
      {
        hitAnything = true;
        primaryDistance = hit.distance;
        if (!recordedPrimary)
        {
          float4 clipPosition = frameUniforms.projectionMatrix * frameUniforms.viewMatrix * float4(hitPosition, 1.0);
          primaryDepth = clipPosition.z / clipPosition.w;
          primaryStructure = instance.structureIndex;
          primaryCategory = surface.category;
          recordedPrimary = true;
        }
      }

      // direct lighting, with one shadow ray per enabled light
      for (uint li = 0; li < NUMBER_OF_LIGHTS; li++)
      {
        if (lightUniforms.lights[li].enabled < 0.5) continue;

        PathTracerLightSample light = pathTracerSampleLight(lightUniforms, lights, li, hitPosition);
        float cosTheta = max(dot(normal, light.direction), 0.0);
        if (cosTheta <= 0.0) continue;
        if (light.attenuation <= 0.0) continue;

        ray shadowRay;
        shadowRay.origin = hitPosition + normal * uniforms.rayEpsilon;
        shadowRay.direction = light.direction;
        shadowRay.min_distance = 0.0;
        shadowRay.max_distance = light.distance;

        PathTracerPayload shadowPayload;
        shadowPayload.normal = float3(0.0, 0.0, 1.0);
        shadowPayload.axialFraction = 0.0;

        intersector<triangle_data, instancing>::result_type shadowHit =
            shadowIntersector.intersect(shadowRay, accelerationStructure, PATH_TRACER_MASK_SURFACE, functionTable, shadowPayload);

        if (shadowHit.type == intersection_type::none)
        {
          float3 lightDiffuse = light.attenuation * lightUniforms.lights[li].diffuse.xyz;

          if (bounce == 0)
          {
            direct += surface.diffuse * lightDiffuse * cosTheta;
            float3 reflectDirection = reflect(-light.direction, normal);
            float specularFactor = pow(max(dot(reflectDirection, -rayDirection), 0.0),
                                       lightUniforms.lights[li].shininess + surface.shininess);
            direct += surface.specular * light.attenuation * lightUniforms.lights[li].specular.xyz * specularFactor;
          }
          else
          {
            // light picked up further along the path is indirect illumination
            indirectRadiance += throughput * surface.diffuse * lightDiffuse * cosTheta;
          }
        }
      }

      pendingAmbient = throughput * surface.ambient * totalAmbient;
      throughput *= surface.diffuse;

      rayOrigin = hitPosition + normal * uniforms.rayEpsilon;
      rayDirection = pathTracerCosineDirection(normal, state);
    }

    accumulatedDirect += direct;
    accumulatedIndirect += indirectRadiance;
    accumulatedCoverage += hitAnything ? 1.0 : 0.0;
    accumulatedVisibility += (hitAnything && primaryRayEscaped) ? 1.0 : 0.0;

    // The selection overlay. Traced along the same primary ray, but on its own and after the path,
    // so that a selection lights and marks the model without taking any part in how the model is
    // lit: the same standing the raster selection imposters have, being drawn over a finished scene
    // pass and writing no depth of their own.
    ray selectionRay;
    selectionRay.origin = primaryOrigin;
    selectionRay.direction = primaryDirection;
    selectionRay.min_distance = 0.0;
    // a shell further off than the surface is hidden behind it, so the surface is the far limit
    selectionRay.max_distance = primaryDistance;

    PathTracerPayload selectionPayload;
    selectionPayload.normal = float3(0.0, 0.0, 1.0);
    selectionPayload.axialFraction = 0.0;

    intersector<triangle_data, instancing>::result_type selectionHit =
        primaryIntersector.intersect(selectionRay, accelerationStructure, PATH_TRACER_MASK_SELECTION, functionTable, selectionPayload);

    if (selectionHit.type != intersection_type::none)
    {
      PathTracerInstance instance = instances[selectionHit.instance_id];
      constant StructureUniforms &su = structureUniforms[instance.structureIndex];

      float3 hitPosition = primaryOrigin + selectionHit.distance * primaryDirection;

      // the analytic shells leave their normal in the payload; a ribbon shell is triangles, so
      // its normal comes from the vertices the hit falls between
      float2 barycentric = selectionHit.triangle_barycentric_coord;
      float3 localNormal = normalize(selectionPayload.normal);
      if (instance.kind == PATH_TRACER_KIND_RIBBON)
      {
        uint triangle = instance.primitiveBase + selectionHit.primitive_id;
        uint i0 = ribbonIndices[3 * triangle + 0];
        uint i1 = ribbonIndices[3 * triangle + 1];
        uint i2 = ribbonIndices[3 * triangle + 2];
        float w0 = 1.0 - barycentric.x - barycentric.y;
        localNormal = w0 * ribbonVertices[i0].normal.xyz +
                      barycentric.x * ribbonVertices[i1].normal.xyz +
                      barycentric.y * ribbonVertices[i2].normal.xyz;
      }

      float3 normal = normalize((su.modelMatrix * float4(localNormal, 0.0)).xyz);
      if (dot(normal, primaryDirection) > 0.0) normal = -normal;

      float4 overlay = pathTracerSelectionOverlay(instance, su, frameUniforms, lightUniforms, lights,
                                                  spheres, cylinders, ribbonVertices, ribbonIndices,
                                                  selectionHit.primitive_id,
                                                  hitPosition, normal, -primaryDirection,
                                                  selectionPayload.axialFraction, barycentric);
      accumulatedSelection += overlay.rgb;
      accumulatedSelectionCoverage += overlay.a;

      if (!recordedSelection)
      {
        float4 clipPosition = frameUniforms.projectionMatrix * frameUniforms.viewMatrix * float4(hitPosition, 1.0);
        selectionDepth = clipPosition.z / clipPosition.w;
        recordedSelection = true;
      }
    }
  }

  uint pixel = gid.y * uniforms.width + gid.x;
  bool first = (uniforms.sampleOffset == 0);
  float4 previousDirect = first ? float4(0.0) : accumulation[pixel];
  float4 previousIndirect = first ? float4(0.0) : indirect[pixel];
  float4 previousSelection = first ? float4(0.0) : selection[pixel];
  accumulation[pixel] = previousDirect + float4(accumulatedDirect, accumulatedCoverage);
  indirect[pixel] = previousIndirect + float4(accumulatedIndirect, accumulatedVisibility);
  selection[pixel] = previousSelection + float4(accumulatedSelection, accumulatedSelectionCoverage);

  if (first)
  {
    surfaceInfo[pixel] = float4(primaryDepth, float(primaryStructure), float(primaryCategory), selectionDepth);
  }
}

// MARK: Resolve and composite
// =============================================================================
// Applies the HDR exposure and hue/saturation/value adjustments of the structure that
// the primary ray hit, then composites over the rasterized scene. Tone mapping runs on
// the converged average rather than per sample, which is the correct order for what is
// a display transform. The selection overlay is the exception, being mapped as it is
// gathered: the rasterizer maps a selection and the surface under it separately and blends
// the two afterwards, and only mapping first reproduces that.

kernel void pathTracerResolveKernel(uint2 gid [[thread_position_in_grid]],
                                    constant PathTracerUniforms &uniforms         [[buffer(0)]],
                                    constant StructureUniforms *structureUniforms [[buffer(1)]],
                                    const device float4 *accumulation             [[buffer(2)]],
                                    const device float4 *surfaceInfo              [[buffer(3)]],
                                    const device float4 *indirect                 [[buffer(4)]],
                                    device float *compositeDepth                  [[buffer(5)]],
                                    device uchar *compositeCueMask                [[buffer(6)]],
                                    const device float4 *selection                [[buffer(7)]],
                                    texture2d<float, access::read> sceneColor      [[texture(0)]],
                                    depth2d<float> sceneDepth                     [[texture(1)]],
                                    texture2d<float, access::write> output         [[texture(2)]])
{
  if (gid.x >= uniforms.width || gid.y >= uniforms.height) return;

  constexpr sampler depthSampler(coord::normalized, filter::nearest, address::clamp_to_edge);

  uint pixel = gid.y * uniforms.width + gid.x;
  float4 raster = sceneColor.read(gid);
  float4 accumulated = accumulation[pixel];

  // The rasterized scene still holds every primitive that is not an atom, a bond or a ribbon
  // (unit cell, isosurfaces, text, axes), so its depth decides what the trace is allowed to cover.
  float2 uv = (float2(gid) + 0.5) / float2(float(uniforms.width), float(uniforms.height));
  float rasterDepth = sceneDepth.sample(depthSampler, uv);

  float coverage = accumulated.a / max(uniforms.accumulatedSamples, 1.0);

  float4 info = surfaceInfo[pixel];

  // what the pixel holds before the selection overlay goes on, which for an uncovered pixel is
  // whatever the rasterizer left there
  float4 composited = raster;
  float visibleDepth = rasterDepth;
  uchar cueMask = 0;

  if (coverage > 0.0)
  {
    // averages over the samples that hit something, so partially covered edge pixels are not
    // darkened before the composite below weights them by coverage
    float hits = max(accumulated.a, 1.0e-6);
    float4 accumulatedIndirect = indirect[pixel];
    float3 directRadiance = accumulated.rgb / hits;
    float3 indirectRadiance = accumulatedIndirect.rgb / hits;
    float visibility = accumulatedIndirect.a / hits;

    // The raster path multiplies its baked occlusion into the whole shaded colour, direct
    // lighting included. That is not physical, but it is what the "Fancy" style looks like,
    // so the same factor is applied here to the direct term. The indirect term already
    // carries its own occlusion, having been collected only along rays that escaped.
    float occlusion = mix(1.0, visibility, clamp(uniforms.ambientOcclusionStrength, 0.0, 1.0));
    float3 radiance = occlusion * directRadiance + indirectRadiance;

    float pathTracedDepth = info.r;
    constant StructureUniforms &su = structureUniforms[uint(info.g)];
    uint category = uint(info.b);

    float4 color = float4(pathTracerToneMap(radiance, category, su), 1.0);

    bool tracedIsNearer = (pathTracedDepth <= rasterDepth);
    composited = mix(raster, color, tracedIsNearer ? coverage : 0.0);

    // The depth of what is actually visible here, which the rasterizer's own depth buffer cannot say
    // because the molecular geometry was left out of it. Written out so that the compositing pass has a
    // depth buffer to find its edges in, and so a traced image is cued exactly as a rasterized one is.
    visibleDepth = tracedIsNearer ? pathTracedDepth : rasterDepth;

    // The same mask the rasterizer records in its stencil, which it cannot do here because the molecular
    // geometry never went through a raster pass. Where the trace did not win, what is visible is
    // rasterized guide geometry or the background, neither of which takes cues.
    float cueing = (category == PATH_TRACER_CATEGORY_RIBBON) ? su.edgeCueingRibbons : su.edgeCueingAtoms;
    uchar mode = uchar(clamp(cueing, 0.0, 3.0)) & EDGE_CUEING_STENCIL_MODE_MASK;
    cueMask = tracedIsNearer ? (EDGE_CUEING_STENCIL_CUEABLE_BIT | mode) : 0;
  }

  // The selection overlay goes on last and over everything, which is where the rasterizer draws its
  // own: after the scene it marks, writing neither depth nor a cueing mask, so what is recorded
  // below stays the surface underneath rather than the marking on it. It reaches beyond that surface,
  // the shell being the larger of the two, so it is composited whether the trace covered the pixel
  // or not.
  float4 selectionLayer = selection[pixel];
  float selectionCoverage = selectionLayer.a / max(uniforms.accumulatedSamples, 1.0);
  if (selectionCoverage > 0.0 && info.a <= rasterDepth)
  {
    // the accumulated colour is weighted by the coverage, so dividing by it recovers the average
    // colour of the samples the overlay actually covered
    float3 selectionColor = selectionLayer.rgb / max(selectionLayer.a, 1.0e-6);
    // The weight passes one once the selection intensity level is turned up, carrying the mix past
    // the overlay colour just as the raster blend's negative destination factor does. Held at black
    // from below, which is where a render target leaves it anyway.
    composited = float4(max(mix(composited.rgb, selectionColor, selectionCoverage), 0.0), 1.0);
  }

  output.write(composited, gid);
  compositeDepth[pixel] = visibleDepth;
  compositeCueMask[pixel] = cueMask;
}
