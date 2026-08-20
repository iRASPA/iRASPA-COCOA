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

#ifndef PathTracerCommon_h
#define PathTracerCommon_h

#include <simd/simd.h>

// Layouts shared between MetalPathTracerShader.swift and PathTracer.metal. The Swift side
// mirrors these by hand (as it does for StructureUniforms in Common.h); keep both in step.

// Geometry kinds referenced by the instances of the top-level acceleration structure.
#define PATH_TRACER_KIND_SPHERE    0
#define PATH_TRACER_KIND_CYLINDER  1
#define PATH_TRACER_KIND_RIBBON    2

// Material categories, selecting which set of HDR/hue/saturation/value and shininess
// parameters of StructureUniforms applies to a hit.
#define PATH_TRACER_CATEGORY_ATOM    0
#define PATH_TRACER_CATEGORY_BOND    1
#define PATH_TRACER_CATEGORY_RIBBON  2

// An atom, in the structure space of its owning structure. Colours are the raw
// per-instance colours of RKInPerInstanceAttributesAtoms; the light and structure
// colours are folded in by the kernel, exactly as the imposter vertex shader does.
typedef struct PathTracerSphere
{
  simd_float4 center;     // xyz = center, w = radius
  simd_float4 ambient;
  simd_float4 diffuse;
  simd_float4 specular;
} PathTracerSphere;

// One (sub-)cylinder of a bond, in structure space. Double and triple bonds are
// expanded into their sub-cylinders when the buffer is packed, so the intersection
// function only ever deals with a single capped cylinder.
typedef struct PathTracerCylinder
{
  simd_float4 pointA;     // xyz = first end cap centre, w = radius
  simd_float4 pointB;     // xyz = second end cap centre, w unused
  simd_float4 color1;     // raw per-instance colour at pointA
  simd_float4 color2;     // raw per-instance colour at pointB
} PathTracerCylinder;

// One instance of the top-level acceleration structure. `primitiveBase` turns the
// geometry-local primitive_id into an index into the concatenated global buffers.
typedef struct PathTracerInstance
{
  unsigned int kind;
  unsigned int primitiveBase;
  unsigned int structureIndex;   // index into the StructureUniforms array
  unsigned int clipAtUnitCell;   // non-zero when the six clip planes apply
} PathTracerInstance;

typedef struct PathTracerUniforms
{
  unsigned int width;
  unsigned int height;
  unsigned int samplesPerDispatch;
  unsigned int sampleOffset;      // number of samples already accumulated

  unsigned int maximumBounces;    // 0 = direct lighting only
  unsigned int seed;
  float        rayEpsilon;        // secondary-ray offset, scaled to the scene size
  float        accumulatedSamples;// total sample count, used by the resolve kernel

  // How much of the traced ambient occlusion is applied to the *direct* lighting, which is
  // what the raster path does when it multiplies its baked occlusion into
  // (ambient + diffuse + specular). 0 leaves the direct term physically unoccluded, 1
  // reproduces the look of the rasterized "Fancy" ribbons.
  float        ambientOcclusionStrength;
  float        pad0;
  float        pad1;
  float        pad2;
} PathTracerUniforms;

#endif /* PathTracerCommon_h */
