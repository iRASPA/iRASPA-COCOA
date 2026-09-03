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
using namespace metal;

// The energy of a point the probe cannot occupy, and the ceiling on the accumulated energy.
constant float overlapEnergy = 10000000.0f;

// What a point inside a blocking pocket is worth per angstrom of the depth it lies at, rather than one flat
// overlap energy for the whole sphere.
//
// A flat fill leaves marching cubes nothing to interpolate between two points inside a pocket: the crossing on
// an edge into one is then fixed by the outside end alone and cannot track the sphere, so the rim comes out as
// a staircase on the grid planes. A ramp gives the seam a gradient of the same order as the framework's own
// walls, which is what makes it follow the sphere instead. What it costs is that the excluded region is the
// part of the sphere deeper than isovalue/rate rather than all of it --- nothing for the isovalues the
// inspector offers, which run from the deepest well up to zero.
//
// The rate is the reciprocal of SKMetalWellSurface.energyScale, which is what an angstrom of the distance field
// is worth in kelvin where the well surface trims one against the other. Sharing it makes the two halves of a
// pocket's contribution to the well field --- its energy and its distance --- the same function of depth.
constant float blockedEnergyPerAngstrom = 1000.0f;

// How far a grid point is, in angstrom, from the surface of the nearest blocking pocket: negative inside one,
// and a large positive number when the structure has no pockets.
//
// A pocket is a sphere given as a fractional position of the unit cell with a radius in angstrom, and it is a
// feature of the framework, so it repeats with the unit cell. The atoms are wrapped over the replica cell
// instead, which is a whole number of unit cells wide, so the nearest image here has to be taken in unit-cell
// coordinates: the grid position is scaled up out of the replica cell, wrapped, and scaled back to measure
// the distance with the replica cell matrix the kernels already carry.
static float blockingPocketDistance(float3 gridpos,
                                    int numberOfBlockingPockets,
                                    const device float4* blockingPockets,
                                    float3x3 cell,
                                    float3 replicaCorrection)
{
  float nearest = 1.0e10f;
  const float3 unitCellPosition = gridpos / replicaCorrection;
  for(int i=0;i<numberOfBlockingPockets;i++)
  {
    float3 dr = unitCellPosition - blockingPockets[i].xyz;
    dr -= rint(dr);
    dr = cell * (dr * replicaCorrection);
    nearest = min(nearest, length(dr) - blockingPockets[i].w);
  }
  return nearest;
}

kernel void ComputeEnergyGrid(constant int& numberOfAtoms [[ buffer(0) ]],
                              const device float4* atomPosition [[ buffer(1) ]],
                              const device float4* gridPosition [[ buffer(2) ]],
                              const device float2* potparameters [[ buffer(3) ]],
                              constant float3x3& cell [[ buffer(4) ]],
                              constant int& numberOfReplicas [[ buffer(5) ]],
                              constant float4* replicas [[ buffer(6) ]],
                              device float *output [[ buffer(7) ]],
                              constant int& numberOfBlockingPockets [[ buffer(8) ]],
                              const device float4* blockingPockets [[ buffer(9) ]],
                              constant float3& replicaCorrection [[ buffer(10) ]],
                              uint igrid [[thread_position_in_grid]],
                              uint lsize [[threads_per_threadgroup]],
                              uint lid [[thread_position_in_threadgroup]])
{
  float value = 0.0f;
  float3 t,dr,pos;

  float3 gridpos =  gridPosition[igrid].xyz;

  // A blocked pocket is pore the probe is not allowed into, so the point counts as an overlap and no atom is
  // summed into it. The energy is assigned rather than accumulated, which keeps it the same value however many
  // atom batches the caller runs over the same grid.
  const float pocket = blockingPocketDistance(gridpos, numberOfBlockingPockets, blockingPockets, cell, replicaCorrection);
  if (pocket < 0.0f)
  {
    output[ igrid ] = min(-pocket * blockedEnergyPerAngstrom, overlapEnergy);
    return;
  }

  for(int j=0;j<numberOfReplicas;j++)
  {
    float3 replica = replicas[j].xyz;
    for(int iatom = 0; iatom < numberOfAtoms; iatom++ )
    {
      pos = atomPosition[iatom].xyz;
      float eps = potparameters[iatom].x;
      float size = potparameters[iatom].y;
    
    
      dr = (gridpos - pos) - replica;
      
      t = dr - rint(dr);
      
      dr = cell * t;
      
      float rr = dot(dr,dr);
      
      if (rr<12.0*12.0)
      {
        float temp = size*size/rr;
        float rri3 = temp * temp * temp;
        
        value += eps*(rri3*(rri3-1.0f));
      }
    }
  }
  
  output[ igrid ] += min(value,overlapEnergy);
}

// ============================================================================
// Well field
// ============================================================================
//
// The well surface is where an adsorbed molecule sits: the floor of the energy well that lines every pore
// wall. It is extracted in two steps that separate topology from geometry:
//
//   1. Topology from a distance field. d(x) = min over atoms of (|x - a| - rmin), the additively weighted
//      (Apollonius) distance, with rmin = 2^(1/6) sigma the probe-atom contact optimum. Its zero level set
//      is a smooth offset surface wrapping every wall: it cannot produce interior membranes, domes across
//      intersections, or flaps at sheet junctions, because d has exactly one zero crossing along any ray
//      into a wall. Necks narrower than the probe pinch closed of their own accord. The depth trim is a CSG
//      intersection with the energy grid: the field passed to the ordinary marching cubes is
//      max(-d, s (U - iso)), whose zero set bounds the region { d > 0 and U < iso } --- the pore, trimmed
//      to wells at least iso deep, with smooth isosurface caps where the trim cuts.
//
//   2. Geometry from the energy. Each marching-cubes vertex is slid along the ray toward its nearest atom
//      (the direction "orthogonal into the wall") to the 1D minimum of the exact analytic U, a bracketed
//      golden-section search that cannot wander. That lands the surface on the true multi-atom well floor,
//      which sits slightly off |x - a| = rmin wherever more than one atom contributes.
//
// This replaces an earlier extraction of the crease set F = grad U . e1 = 0 of the Hessian eigenframe, which
// was mathematically correct but visually unusable: the crease set genuinely contains one-sided sheets ---
// window membranes, intersection domes, flaps over wall bumps --- and no local quantity separates them from
// the wall sheet.
//
// Batched over atoms like ComputeEnergyGrid, accumulating one float2 per grid point: (U, d), plus one
// float4: the softmin-weighted sum of unit vectors toward the atoms and the sum of the weights. The ratio
// |sum| / weightSum is the medial "reliability" the refinement kernel also uses: 1 against a single wall,
// 0 on the medial axis of a channel where opposing walls cancel. Its low set marks where the channel is
// too narrow for the contact sheet and the well degenerates into a 1D filament (the tube overlay).
// The weights exp(-(r - rmin)/tau) share no per-point reference, so they accumulate across atom batches;
// the common factor cancels in the ratio. The caller initializes the buffers to (0, +large) and zero.
kernel void ComputeWellFieldGrid(constant int& numberOfAtoms [[ buffer(0) ]],
                                 const device float4* atomPosition [[ buffer(1) ]],
                                 const device float4* gridPosition [[ buffer(2) ]],
                                 const device float2* potparameters [[ buffer(3) ]],
                                 constant float3x3& cell [[ buffer(4) ]],
                                 constant int& numberOfReplicas [[ buffer(5) ]],
                                 constant float4* replicas [[ buffer(6) ]],
                                 device float2 *accumulated [[ buffer(7) ]],
                                 device float4 *softmin [[ buffer(8) ]],
                                 constant int& numberOfBlockingPockets [[ buffer(9) ]],
                                 const device float4* blockingPockets [[ buffer(10) ]],
                                 constant float3& replicaCorrection [[ buffer(11) ]],
                                 uint igrid [[thread_position_in_grid]])
{
  float value = 0.0f;
  float distance = 1.0e10f;
  float3 directionSum = float3(0.0f);
  float weightSum = 0.0f;
  const float tau = 0.4f;   // the same softmin temperature as RefineWellSurfaceVertices
  float3 t,dr,pos;

  float3 gridpos = gridPosition[igrid].xyz;

  // A blocking pocket closes the surface the way a sphere of framework would: its own signed distance joins
  // the minimum that the contact surface is the zero set of, which wraps the surface smoothly around the
  // sphere, and its interior is an overlap so the depth trim discards it as well. Because the energy inside a
  // pocket ramps at the reciprocal of the scale the trim converts the distance with, the two agree there and
  // the combined field stays a distance to the sphere.
  const float pocket = blockingPocketDistance(gridpos, numberOfBlockingPockets, blockingPockets, cell, replicaCorrection);

  for(int j=0;j<numberOfReplicas;j++)
  {
    float3 replica = replicas[j].xyz;
    for(int iatom = 0; iatom < numberOfAtoms; iatom++ )
    {
      pos = atomPosition[iatom].xyz;
      float eps = potparameters[iatom].x;
      float size = potparameters[iatom].y;

      dr = (gridpos - pos) - replica;

      t = dr - rint(dr);

      dr = cell * t;

      // An atom sitting exactly on a grid point would make r*r zero and the energy NaN; a floor of 1e-8
      // puts such a point deep inside the repulsive core instead.
      float rr = max(dot(dr,dr), 1.0e-8f);

      if (rr<12.0*12.0)
      {
        float temp = size*size/rr;
        float rri3 = temp * temp * temp;

        value += eps*(rri3*(rri3-1.0f));
        float r = sqrt(rr);
        float contact = r - 1.12246204831f * size;
        distance = min(distance, contact);
        float w = exp(-contact / tau);
        directionSum += w * (-dr / r);   // toward the atom
        weightSum += w;
      }
    }
  }

  float2 previous = accumulated[igrid];
  const float energy = pocket < 0.0f ? min(-pocket * blockedEnergyPerAngstrom, overlapEnergy) : previous.x + min(value, overlapEnergy);
  accumulated[igrid] = float2(energy, min(min(previous.y, distance), pocket));
  float4 previousSoftmin = softmin[igrid];
  softmin[igrid] = float4(previousSoftmin.xyz + directionSum, previousSoftmin.w + weightSum);
}


// ============================================================================
// Well-surface vertex refinement
// ============================================================================
//
// Marching cubes puts the vertices on the Apollonius surface d = 0, the single-atom contact optimum. The
// true well floor deviates from it where several atoms contribute --- deeper and slightly shifted --- so each
// vertex is slid into the wall to the minimum of the exact analytic U on that line.
//
// The direction is the softmin-weighted average of the unit vectors toward the nearby atoms, a smoothed
// gradient of the distance field. Three properties make it the right choice, each learned the hard way:
// it depends only on the (quantized) position, so shared vertices refine bitwise identically and the mesh
// stays watertight; it is continuous across the Apollonius creases (two atoms equally near), where the ray
// to the single nearest atom would tear neighbors apart; and its magnitude reports reliability --- between
// opposing walls the contributions cancel, which is exactly where a big probe's surface runs close to the
// medial ridge of a narrow channel and any fixed search line turns near-tangent to the sheet. There the
// 1D minimum is sideways rather than into the wall, and following it sprays spikes (the nitrogen/methane
// artifacts); instead the search span is scaled down with the reliability, holding those vertices near the
// contact surface. Vertices on the trim caps (U = iso, the CSG seam) belong to the isosurface, not the
// well sheet, and are left alone.
//
// Positions travel in fractional coordinates of the replica cell, the same convention as the grid kernels:
// the VBO holds fractional coordinates of the unit cell, replicaCorrection = 1/numberOfReplicas per axis.

// U at one point (replica-cell fractional coordinates)
static float wellPotentialEnergy(float3 point,
                                 int numberOfAtoms,
                                 const device float4* atomPosition,
                                 const device float2* potparameters,
                                 float3x3 cell,
                                 int numberOfReplicas,
                                 constant float4* replicas)
{
  float value = 0.0f;
  for(int j=0;j<numberOfReplicas;j++)
  {
    float3 replica = replicas[j].xyz;
    for(int iatom = 0; iatom < numberOfAtoms; iatom++)
    {
      float3 dr = (point - atomPosition[iatom].xyz) - replica;
      float3 t = dr - rint(dr);
      dr = cell * t;
      float rr = max(dot(dr,dr), 1.0e-8f);
      if (rr<12.0*12.0)
      {
        float temp = potparameters[iatom].y*potparameters[iatom].y/rr;
        float rri3 = temp * temp * temp;
        value += potparameters[iatom].x*(rri3*(rri3-1.0f));
      }
    }
  }
  return value;
}

kernel void RefineWellSurfaceVertices(constant int& numberOfAtoms [[ buffer(0) ]],
                                      const device float4* atomPosition [[ buffer(1) ]],
                                      const device float2* potparameters [[ buffer(2) ]],
                                      constant float3x3& cell [[ buffer(3) ]],
                                      constant float3x3& inverseCell [[ buffer(4) ]],
                                      constant int& numberOfReplicas [[ buffer(5) ]],
                                      constant float4* replicas [[ buffer(6) ]],
                                      constant float3& replicaCorrection [[ buffer(7) ]],
                                      constant float& isovalue [[ buffer(8) ]],
                                      constant uint& numberOfVertices [[ buffer(9) ]],
                                      device float4* VBOBuffer [[ buffer(10) ]],
                                      constant int& numberOfBlockingPockets [[ buffer(11) ]],
                                      const device float4* blockingPockets [[ buffer(12) ]],
                                      uint vertexId [[thread_position_in_grid]])
{
  if (vertexId >= numberOfVertices) return;

  // three float4 per vertex: position (unit-cell fractional), normal, pad. Twin copies of a shared vertex
  // can differ by an ulp across cubes; quantizing the inputs welds them bitwise, so they refine identically
  // and the mesh stays watertight.
  const float3 quantized = rint(VBOBuffer[3*vertexId].xyz * 1048576.0f) / 1048576.0f;
  const float3 point = quantized * replicaCorrection;

  // vertices on or near the trim cap lie on the U = iso isosurface, not the well sheet: skip them
  const float energyHere = wellPotentialEnergy(point, numberOfAtoms, atomPosition, potparameters, cell, numberOfReplicas, replicas);
  if (energyHere > isovalue - 0.02f * fabs(isovalue)) return;

  // the line: softmin-weighted direction into the wall
  const float tau = 0.4f;   // softmin temperature: creases between atoms this close in distance blend
  float nearest = 1.0e10f;
  for(int j=0;j<numberOfReplicas;j++)
  {
    float3 replica = replicas[j].xyz;
    for(int iatom = 0; iatom < numberOfAtoms; iatom++)
    {
      float3 dr = (point - atomPosition[iatom].xyz) - replica;
      float3 t = dr - rint(dr);
      dr = cell * t;
      nearest = min(nearest, length(dr) - 1.12246204831f * potparameters[iatom].y);
    }
  }

  // A blocking pocket has no potential, so there is no well floor to slide onto against one. Vertices whose
  // closest wall is a pocket rather than an atom are the ones on its sphere, and they are left where the
  // distance field put them.
  if (blockingPocketDistance(point, numberOfBlockingPockets, blockingPockets, cell, replicaCorrection) < nearest) return;

  float3 directionSum = float3(0.0f);
  float weightSum = 0.0f;
  for(int j=0;j<numberOfReplicas;j++)
  {
    float3 replica = replicas[j].xyz;
    for(int iatom = 0; iatom < numberOfAtoms; iatom++)
    {
      float3 dr = (point - atomPosition[iatom].xyz) - replica;
      float3 t = dr - rint(dr);
      dr = cell * t;
      const float r = length(dr);
      if (!(r > 1.0e-6f)) continue;
      const float weighted = r - 1.12246204831f * potparameters[iatom].y;
      if (weighted - nearest > 6.0f * tau) continue;
      const float w = exp(-(weighted - nearest) / tau);
      directionSum += w * (-dr / r);   // toward the atom
      weightSum += w;
    }
  }
  if (!(weightSum > 0.0f)) return;
  const float reliability = length(directionSum) / weightSum;   // 1 one wall, 0 opposing walls cancelling
  const float span = 0.7f * smoothstep(0.25f, 0.6f, reliability);
  if (span < 0.05f) return;
  const float3 rayFractional = inverseCell * normalize(directionSum);   // replica-cell fractional step per angstrom

  // bracket the 1D minimum of U along the ray by coarse sampling of s in [-span, span]
  const int coarse = 14;
  float sBest = 0.0f;
  float uBest = energyHere;
  for (int i = -coarse; i <= coarse; i++)
  {
    const float s = span * float(i) / float(coarse);
    const float u = wellPotentialEnergy(point + s * rayFractional, numberOfAtoms, atomPosition, potparameters, cell, numberOfReplicas, replicas);
    if (u < uBest) { uBest = u; sBest = s; }
  }
  // an interior minimum only; if the best sample is an endpoint the floor is out of reach, leave the vertex
  if (fabs(sBest) >= span - 0.5f * span / float(coarse)) return;

  // golden-section on the bracketing interval [sBest - step, sBest + step]
  const float invphi = 0.6180339887f;
  float a = sBest - span / float(coarse);
  float b = sBest + span / float(coarse);
  float x1 = b - invphi * (b - a);
  float x2 = a + invphi * (b - a);
  float f1 = wellPotentialEnergy(point + x1 * rayFractional, numberOfAtoms, atomPosition, potparameters, cell, numberOfReplicas, replicas);
  float f2 = wellPotentialEnergy(point + x2 * rayFractional, numberOfAtoms, atomPosition, potparameters, cell, numberOfReplicas, replicas);
  // enough iterations that the final interval (0.05 A * 0.618^n) is well under 1e-5 A: twin copies of a
  // shared vertex differ by an ulp across cubes, and the search tolerance bounds how far they can split
  for (int iteration = 0; iteration < 20; iteration++)
  {
    if (f1 < f2)
    {
      b = x2; x2 = x1; f2 = f1;
      x1 = b - invphi * (b - a);
      f1 = wellPotentialEnergy(point + x1 * rayFractional, numberOfAtoms, atomPosition, potparameters, cell, numberOfReplicas, replicas);
    }
    else
    {
      a = x1; x1 = x2; f1 = f2;
      x2 = a + invphi * (b - a);
      f2 = wellPotentialEnergy(point + x2 * rayFractional, numberOfAtoms, atomPosition, potparameters, cell, numberOfReplicas, replicas);
    }
  }
  const float s = 0.5f * (a + b);

  VBOBuffer[3*vertexId] = float4((point + s * rayFractional) / replicaCorrection, 1.0f);
}
