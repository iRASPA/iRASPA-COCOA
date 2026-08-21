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


vertex BackgroundVertexShaderOut texturedQuadVertex(const device InPerVertex    *pPosition   [[ buffer(0) ]],
                                      uint                     vid        [[ vertex_id ]])
{
  BackgroundVertexShaderOut outVertices;
    
  outVertices.m_Position = pPosition[vid].position;
  outVertices.m_TexCoord = pPosition[vid].position.xy * float2(0.5,-0.5) + float2(0.5);
    
  return outVertices;
}

/// Where the depth of the finished image is to be found.
///
/// Two sources, because the molecular geometry is left out of the raster passes when it is path traced
/// and so is absent from the depth attachment. The tracer writes the depth of whatever won its
/// composite into a buffer instead, and reading that keeps a traced image cued exactly as a rasterized
/// one is rather than silently uncued.
struct SceneDepth
{
  depth2d<float> rasterized;
  const device float *traced;
  bool useTraced;
};

static float deviceDepthAtPixel(SceneDepth sceneDepth, int2 pixel, float2 size)
{
  if (sceneDepth.useTraced)
  {
    return sceneDepth.traced[pixel.y * int(size.x) + pixel.x];
  }
  return sceneDepth.rasterized.read(uint2(pixel));
}

/// Distance from the camera to whatever was drawn at `pixel`, in scene units.
///
/// The stored value is a device depth, which is not proportional to distance under a perspective
/// camera, so it is put back through the inverse projection. Doing that means one threshold in
/// Angstrom holds across the whole image instead of being ten times more sensitive near the far
/// plane than near the eye. An orthographic camera comes out of the same arithmetic unchanged.
static float sceneDistanceAtPixel(SceneDepth sceneDepth, int2 pixel, float2 size, constant FrameUniforms& frameUniforms)
{
  int2 clamped = clamp(pixel, int2(0), int2(size) - 1);
  float deviceDepth = deviceDepthAtPixel(sceneDepth, clamped, size);

  float2 normalized = (float2(clamped) + 0.5) / size;
  float2 clipPosition = normalized * float2(2.0, -2.0) + float2(-1.0, 1.0);
  float4 eyePosition = frameUniforms.projectionMatrixInverse * float4(clipPosition, deviceDepth, 1.0);
  return -eyePosition.z / eyePosition.w;
}

/// Which structure, if any, produced the surface at each pixel, and what it asked for.
///
/// Two sources for the same reason the depth has two: the rasterizer records it in the stencil it
/// was already carrying and never used, while the path tracer, which cannot write a stencil, writes
/// the same byte into a buffer from the resolve kernel.
struct CueMask
{
  texture2d_ms<uint> rasterized;
  const device uchar *traced;
  bool useTraced;
};

/// What a pixel asks for. `cueable` says the pixel belongs to a structure at all, which is what
/// separates an atom wanting no cues from the unit cell and from the background: the first can still
/// be darkened by a halo cast over it, the unit cell never is.
struct Cues
{
  bool contours;
  bool halos;
  bool cueable;
};

static Cues cuesAtPixel(CueMask cueMask, int2 pixel, float2 size)
{
  int2 clamped = clamp(pixel, int2(0), int2(size) - 1);

  uint value = 0;
  if (cueMask.useTraced)
  {
    value = uint(cueMask.traced[clamped.y * int(size.x) + clamped.x]);
  }
  else
  {
    // Sample zero rather than a resolve, see `sceneStencilTexture` in MetalBackgroundShader.
    value = cueMask.rasterized.read(uint2(clamped), 0).r;
  }

  uint mode = value & EDGE_CUEING_STENCIL_MODE_MASK;
  Cues cues;
  cues.contours = (mode == 1 || mode == 3);
  cues.halos = (mode == 2 || mode == 3);
  cues.cueable = (value & EDGE_CUEING_STENCIL_CUEABLE_BIT) != 0;
  return cues;
}

/// How much of the step to a neighbour is a break in the surface rather than the slope of it.
///
/// Reading the step on its own marks anything steep, which over a van der Waals sphere is most of the
/// sphere: the depth falls away quickly towards the rim without there being any edge to draw, and the
/// cue becomes a wash of shading instead of a line. Adding the step in the opposite direction cancels
/// the slope, a surface that recedes on one side rising by as much on the other, and leaves what does
/// not cancel: nothing on a smooth surface, and the size of the jump where one surface ends and
/// another begins.
static float depthBreakAlong(SceneDepth sceneDepth, int2 pixel, int2 offset, float2 size, constant FrameUniforms& frameUniforms, float distanceHere)
{
  float forward = sceneDistanceAtPixel(sceneDepth, pixel + offset, size, frameUniforms);
  float backward = sceneDistanceAtPixel(sceneDepth, pixel - offset, size, frameUniforms);
  return (forward - distanceHere) + (backward - distanceHere);
}

/// How strongly a contour line falls on this pixel, between nothing and full darkness.
///
/// Rings of growing radius are tested against thresholds that grow with them, so that a wider band
/// has to be earned by a larger depth step. A pixel one away from an edge is reached by every ring
/// and darkens even for a shallow step, while a pixel three away is reached only by the outermost
/// ring and so darkens only where the step is large. The width of the line therefore reports the
/// size of the depth discontinuity, which is the whole point of the cue: an edge against the
/// background reads as further away than an edge between two touching strands.
///
/// Only pixels nearer than their surroundings are darkened, which keeps the line inside the
/// silhouette of the nearer surface, where the halo pass is not also working.
static float contourLineStrength(SceneDepth sceneDepth, int2 pixel, float2 size, constant FrameUniforms& frameUniforms)
{
  float distanceHere = sceneDistanceAtPixel(sceneDepth, pixel, size, frameUniforms);
  int widest = int(clamp(frameUniforms.edgeCueing.y, 1.0, 5.0));

  float line = 0.0;
  for (int radius = 1; radius <= widest; radius++)
  {
    float step = 0.0;
    step = max(step, depthBreakAlong(sceneDepth, pixel, int2(radius, 0), size, frameUniforms, distanceHere));
    step = max(step, depthBreakAlong(sceneDepth, pixel, int2(0, radius), size, frameUniforms, distanceHere));

    float needed = frameUniforms.edgeCueingContourDepth * float(radius) / float(widest);
    line = max(line, smoothstep(0.4 * needed, needed, step));
  }
  return line;
}

/// How strongly a halo falls on this pixel: a band of darkness on the farther of two surfaces,
/// hugging the silhouette of the nearer one, so that a strand passing behind another detaches from it.
///
/// Rings of growing radius are searched for a neighbour lying nearer than this pixel, and the
/// strongest find wins, weighted down by the radius it was found at. A pixel immediately behind a
/// silhouette is reached by the innermost ring and takes nearly the full darkness, one further out is
/// reached only by a wider ring and takes less, and beyond the outermost ring nothing is found at all.
/// That is what grades the band and what confines it, in place of blurring.
///
/// A neighbour has to be nearer by an appreciable fraction of `edgeCueingHaloDepth` before it counts
/// for anything. Without that floor every gently curving surface qualifies as its own silhouette,
/// since a ribbon recedes a little across any few pixels, and the cue spreads into a wash of shading
/// over whole surfaces instead of marking the places where one surface passes in front of another.
static float haloStrength(SceneDepth sceneDepth, CueMask cueMask, int2 pixel, float2 size, constant FrameUniforms& frameUniforms)
{
  const int taps = 8;
  const float2 directions[taps] = {float2( 1.0,  0.0), float2( 0.0,  1.0), float2(-1.0,  0.0), float2( 0.0, -1.0),
                                   float2( 0.707,  0.707), float2(-0.707,  0.707), float2(-0.707, -0.707), float2( 0.707, -0.707)};
  const int rings = 3;

  /// Fraction of the reference depth a step has to reach before it is read as one surface in front of
  /// another rather than as the slope of a single curved one.
  const float floorFraction = 0.35;

  float distanceHere = sceneDistanceAtPixel(sceneDepth, pixel, size, frameUniforms);
  float reach = max(frameUniforms.edgeCueing.w, 1.0);
  float scale = max(frameUniforms.edgeCueingHaloDepth, 1.0e-6);

  float halo = 0.0;
  for (int ring = 1; ring <= rings; ring++)
  {
    float radius = reach * float(ring) / float(rings);
    float weight = 1.0 - float(ring - 1) / float(rings);

    for (int i = 0; i < taps; i++)
    {
      int2 offset = int2(round(directions[i] * radius));
      if (!cuesAtPixel(cueMask, pixel + offset, size).halos) {continue;}

      float distanceThere = sceneDistanceAtPixel(sceneDepth, pixel + offset, size, frameUniforms);
      float step = (distanceHere - distanceThere) / scale;
      halo = max(halo, weight * smoothstep(floorFraction, 1.0, step));
    }
  }
  return halo;
}

fragment float4 texturedQuadFragment(BackgroundVertexShaderOut     inFrag    [[ stage_in ]],
                                    const texture2d<float>  tex2D     [[ texture(0) ]],
                                    const texture2d<float>  blurTexture     [[ texture(1) ]],
                                    depth2d<float>          rasterizedDepth [[ texture(2) ]],
                                    texture2d_ms<uint>      rasterizedCueMask [[ texture(3) ]],
                                    constant FrameUniforms& frameUniforms [[ buffer(0) ]],
                                    const device float*     tracedDepth   [[ buffer(1) ]],
                                    const device uchar*     tracedCueMask [[ buffer(2) ]],
                                    sampler           quadSampler [[ sampler(0) ]])
{
  float4 color = float4(tex2D.sample(quadSampler, inFrag.m_TexCoord));

  // Edge cueing, after Tarini et al. section 5. It reads the depth of the finished scene and a mask
  // saying which structure drew each pixel, so the two cues can be asked for by one structure and not
  // another while the rasterizer and the path tracer stay in step. The selection glow is added
  // afterwards, being a light rather than a surface.
  float2 size = float2(rasterizedDepth.get_width(), rasterizedDepth.get_height());
  int2 pixel = int2(inFrag.m_TexCoord * size);
  bool traced = frameUniforms.edgeCueingUsesTracedDepth > 0.5;
  SceneDepth sceneDepth = {rasterizedDepth, tracedDepth, traced};
  CueMask cueMask = {rasterizedCueMask, tracedCueMask, traced};

  Cues here = cuesAtPixel(cueMask, pixel, size);

  // A contour belongs to the surface it outlines, so this pixel decides. A ribbon crossing in front
  // of the unit cell is outlined; the unit cell in front of a ribbon is not.
  if (here.contours)
  {
    float line = contourLineStrength(sceneDepth, pixel, size, frameUniforms);
    color.xyz *= 1.0 - frameUniforms.edgeCueing.x * line;
  }

  // A halo falls on what lies behind, so the surface in front decides whether one is cast while this
  // pixel decides only whether it can receive one. The background can, being what most halos land on;
  // the unit cell and the axes cannot, having asked for no part in this.
  bool isBackground = deviceDepthAtPixel(sceneDepth, clamp(pixel, int2(0), int2(size) - 1), size) >= 0.99999;
  if (here.cueable || isBackground)
  {
    float halo = haloStrength(sceneDepth, cueMask, pixel, size, frameUniforms);
    color.xyz *= 1.0 - frameUniforms.edgeCueing.z * halo;
  }

  float4 glow = frameUniforms.bloomPulse * frameUniforms.bloomLevel * float4(blurTexture.sample(quadSampler, inFrag.m_TexCoord));

  // The scene keeps to the standard range and the glow alone is allowed out of it. Clamping the scene
  // is what the 8-bit drawable this pass used to write to did implicitly, so the surfaces look exactly
  // as they did; letting them through instead would brighten every unclamped specular on an EDR
  // display and change the appearance of scenes nobody asked to alter.
  //
  // `maximumEDRvalue` is the headroom the display can show beyond standard white this frame. It is
  // 1.0 on a standard screen, on a display whose headroom has collapsed at high brightness, and for
  // every picture and movie export, so this multiply does nothing at all in those cases.
  return clamp(color, 0.0, 1.0) + float4(glow.xyz * frameUniforms.maximumEDRvalue, 0.0);
}
