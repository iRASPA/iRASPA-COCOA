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

import Foundation
import simd
import SymmetryKit

// The surface of the union of the probe-inflated atoms, measured patch by patch instead of by throwing
// points at it. The atoms may be inflated from Lennard-Jones sigma (force-field geometric surface) or
// from Bondi van der Waals radii (VDW geometric surface); the probe contribution is ½ σ_probe in both.
//
// Ported from raspa3 `structurekit/diagrams/exact`. The surface in question is the sheet the probe's
// centre traces when it is rolled over the framework. A patch is the part of one atom's sphere that
// lies outside every other inflated atom, which asks only for the atoms and a neighbour list. Every
// point of the union's boundary is on exactly one such patch, so the patches are the surface, with
// nothing missed and nothing counted twice.
//
// Each patch is bounded by the circles in which its neighbours cut the sphere. The GPU draws a patch
// as a sphere imposter whose fragment shader discards the directions that fall inside a neighbouring
// sphere, which is the same test.

/// One neighbouring sphere that clips a patch, as a centre in Cartesian angstrom and an inflated radius.
public struct SKGeometricSurfaceClip
{
  public var center: SIMD3<Double>
  public var radius: Double
  
  public init(center: SIMD3<Double>, radius: Double)
  {
    self.center = center
    self.radius = radius
  }
}

/// The exposed part of one probe-inflated atom: a spherical patch bounded by the caps its neighbours cut.
public struct SKGeometricSurfacePatch
{
  public var atomIndex: Int
  public var center: SIMD3<Double>
  public var radius: Double
  public var clips: [SKGeometricSurfaceClip]
  /// Exact area of this atom's exposed surface, in Å², from the latitude sweep.
  public var area: Double
  
  public init(atomIndex: Int, center: SIMD3<Double>, radius: Double, clips: [SKGeometricSurfaceClip], area: Double)
  {
    self.atomIndex = atomIndex
    self.center = center
    self.radius = radius
    self.clips = clips
    self.area = area
  }
}

/// The geometric accessible surface of a framework: the list of spherical patches the probe's centre
/// traces, and the exact area of their union.
public struct SKGeometricSurface
{
  public var patches: [SKGeometricSurfacePatch]
  /// Total exposed area in Å². Sum of the patch areas; each point of the union belongs to one patch.
  public var area: Double
  
  public init(patches: [SKGeometricSurfacePatch], area: Double)
  {
    self.patches = patches
    self.area = area
  }
  
  /// Inflated radius of an atom for the geometric accessible surface: half the mixed Lennard-Jones
  /// sigma, which is the contact distance of the probe's centre with that atom.
  public static func inflatedRadius(atomSigma: Double, probeSigma: Double) -> Double
  {
    return 0.5 * (atomSigma + probeSigma)
  }
  
  /// Inflated Bondi van der Waals radius: the VDW sphere plus the probe's collision radius
  /// `½ σ_probe`, so a vanishing probe sits on the drawn VDW atoms.
  public static func inflatedVanDerWaalsRadius(atomVDW: Double, probeSigma: Double) -> Double
  {
    return atomVDW + 0.5 * probeSigma
  }
  
  /// Builds the patches of the union of the given spheres.
  public static func build(fractionalPositions: [SIMD3<Double>],
                           radii: [Double],
                           cell: SKCell,
                           blockingPockets: [SIMD4<Double>] = [],
                           subdivisions: Int = 1) -> SKGeometricSurface
  {
    let count = min(fractionalPositions.count, radii.count)
    guard count > 0 else { return SKGeometricSurface(patches: [], area: 0.0) }
    
    let unitCell: double3x3 = cell.unitCell
    var centres: [SIMD3<Double>] = []
    centres.reserveCapacity(count)
    var usedRadii: [Double] = []
    usedRadii.reserveCapacity(count)
    for i in 0..<count
    {
      let wrapped = SKGeometricSurface.wrappedFractional(fractionalPositions[i])
      centres.append(unitCell * wrapped)
      usedRadii.append(radii[i])
    }
    
    var clipperCentres: [SIMD3<Double>] = centres
    var clipperRadii: [Double] = usedRadii
    clipperCentres.reserveCapacity(count + blockingPockets.count)
    clipperRadii.reserveCapacity(count + blockingPockets.count)
    for pocket in blockingPockets
    {
      if pocket.w <= 0.0
      {
        continue
      }
      let wrapped = SKGeometricSurface.wrappedFractional(SIMD3<Double>(pocket.x, pocket.y, pocket.z))
      clipperCentres.append(unitCell * wrapped)
      clipperRadii.append(pocket.w)
    }
    
    let maxRadius = usedRadii.max() ?? 0.0
    let maxClipperRadius = clipperRadii.max() ?? maxRadius
    let replicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: max(maxRadius + maxClipperRadius, 1.0))
    
    var patches: [SKGeometricSurfacePatch] = []
    patches.reserveCapacity(count)
    var totalArea: Double = 0.0
    var work = SKSweepWorkspace()
    
    for atomIndex in 0..<count
    {
      let radius = usedRadii[atomIndex]
      if radius <= 0.0
      {
        continue
      }
      
      var circles: [SKSweepCircle] = []
      var clips: [SKGeometricSurfaceClip] = []
      var buried = false
      
      let nx = Int(replicas.x)
      let ny = Int(replicas.y)
      let nz = Int(replicas.z)
      outer: for j in 0..<clipperCentres.count
      {
        let neighbourRadius = clipperRadii[j]
        if neighbourRadius <= 0.0
        {
          continue
        }
        for kx in -nx...nx
        {
          for ky in -ny...ny
          {
            for kz in -nz...nz
            {
              if j == atomIndex && kx == 0 && ky == 0 && kz == 0
              {
                continue
              }
              let image = SIMD3<Double>(Double(kx), Double(ky), Double(kz))
              let neighbourCentre = clipperCentres[j] + unitCell * image
              let delta = neighbourCentre - centres[atomIndex]
              let distance = simd_length(delta)
              if distance < 1.0e-12
              {
                if neighbourRadius > radius
                {
                  buried = true
                  break outer
                }
                continue
              }
              
              let cosineHalfAngle = (radius * radius + distance * distance - neighbourRadius * neighbourRadius) / (2.0 * radius * distance)
              if cosineHalfAngle >= 1.0
              {
                continue
              }
              if cosineHalfAngle <= -1.0
              {
                buried = true
                break outer
              }
              
              let axis = delta / distance
              if let circle = SKMakeSweepCircle(axis: axis, cosineHalfAngle: cosineHalfAngle)
              {
                circles.append(circle)
                clips.append(SKGeometricSurfaceClip(center: neighbourCentre, radius: neighbourRadius))
              }
            }
          }
        }
      }
      
      if buried
      {
        continue
      }
      
      // Contained discs add latitudes at which nothing happens to the area sweep; they do not change
      // the clip test, a point inside an inner sphere already being inside the outer one.
      SKPruneContainedDiscs(&circles)
      
      var area: Double = 0.0
      if circles.isEmpty
      {
        area = 4.0 * Double.pi * radius * radius
      }
      else
      {
        work.axes = circles.map { $0.axis }
        let frame = SKSweepFrame(work.axes)
        SKSweepExposedLatitudes(&circles, frame: frame, knownCrossings: nil, subdivisions: subdivisions, work: &work) { gap in
          area += radius * radius * gap.sineLatitude * gap.span * gap.weight
        }
      }
      
      if area <= 0.0
      {
        continue
      }
      
      patches.append(SKGeometricSurfacePatch(atomIndex: atomIndex,
                                             center: centres[atomIndex],
                                             radius: radius,
                                             clips: clips,
                                             area: area))
      totalArea += area
    }
    
    return SKGeometricSurface(patches: patches, area: totalArea)
  }
  
  /// Force-field geometric surface: each atom is inflated by half the mixed Lennard-Jones sigma
  /// with `probeSigma`. Periodic images that can reach an atom are taken from `cell`. An atom swallowed
  /// whole by a neighbour is dropped, since it carries no exposed surface.
  ///
  /// `blockingPockets` are the applied pockets: a fractional centre and a radius in Å. Each is an extra
  /// clipping sphere, the same role they play on the energy grid, so an inaccessible cage's internal
  /// sheet is cut out rather than counted.
  public static func build(fractionalPositions: [SIMD3<Double>],
                           potentialParameters: [SIMD2<Double>],
                           probeSigma: Double,
                           cell: SKCell,
                           blockingPockets: [SIMD4<Double>] = [],
                           subdivisions: Int = 1) -> SKGeometricSurface
  {
    let count = min(fractionalPositions.count, potentialParameters.count)
    let radii: [Double] = (0..<count).map { inflatedRadius(atomSigma: potentialParameters[$0].y, probeSigma: probeSigma) }
    return build(fractionalPositions: Array(fractionalPositions.prefix(count)),
                 radii: radii,
                 cell: cell,
                 blockingPockets: blockingPockets,
                 subdivisions: subdivisions)
  }
  
  /// Van der Waals geometric surface: Bondi radii inflated by half the probe sigma.
  public static func buildVanDerWaals(fractionalPositions: [SIMD3<Double>],
                                      elementIdentifiers: [Int],
                                      probeSigma: Double,
                                      cell: SKCell,
                                      blockingPockets: [SIMD4<Double>] = [],
                                      subdivisions: Int = 1) -> SKGeometricSurface
  {
    let count = min(fractionalPositions.count, elementIdentifiers.count)
    let elements: [SKElement] = PredefinedElements.sharedInstance.elementSet
    let radii: [Double] = (0..<count).map { i in
      let elementId = elementIdentifiers[i]
      let vdw = (elementId >= 0 && elementId < elements.count) ? elements[elementId].VDWRadius : 0.0
      return inflatedVanDerWaalsRadius(atomVDW: vdw, probeSigma: probeSigma)
    }
    return build(fractionalPositions: Array(fractionalPositions.prefix(count)),
                 radii: radii,
                 cell: cell,
                 blockingPockets: blockingPockets,
                 subdivisions: subdivisions)
  }
  
  /// Fractional coordinates folded into the unit cube [0, 1). A patch whose centre sat outside the
  /// cell is the same patch after a lattice translation, and drawing it there puts it back inside.
  public static func wrappedFractional(_ s: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(s.x - floor(s.x), s.y - floor(s.y), s.z - floor(s.z))
  }
  
  /// Exact geometric accessible surface area of each snapshot, in the same volumetric and gravimetric
  /// units as the nitrogen and well-surface areas. Blocking pockets on the snapshot are always applied.
  public static func surfaceAreas(of snapshots: [SKFrameworkSnapshot]) -> [SKSurfaceAreaResult]
  {
    return snapshots.map { snapshot in
      let surface = SKGeometricSurface.build(fractionalPositions: snapshot.positions,
                                             potentialParameters: snapshot.potentialParameters,
                                             probeSigma: snapshot.probeParameters.y,
                                             cell: snapshot.cell,
                                             blockingPockets: snapshot.blockingPockets)
      return SKSurfaceAreaResult(area: surface.area, structure: snapshot)
    }
  }
}

/// One drawing copy of a patch: the sphere may be placed on a neighbouring lattice image so that the
/// part which stuck out of the cell re-enters through the opposite face. `cellOrigin` is the
/// Cartesian origin of the cell the copy is clipped to.
public struct SKGeometricSurfacePatchCopy
{
  public var center: SIMD3<Double>
  public var clips: [SKGeometricSurfaceClip]
  public var cellOrigin: SIMD3<Double>
  
  public init(center: SIMD3<Double>, clips: [SKGeometricSurfaceClip], cellOrigin: SIMD3<Double>)
  {
    self.center = center
    self.clips = clips
    self.cellOrigin = cellOrigin
  }
}

extension SKGeometricSurfacePatch
{
  /// The home copy (centre already in the cell) plus a translated copy for every face, edge or
  /// corner the sphere overlaps, so that clipping each copy to the cell reconstructs the whole
  /// patch inside the box and nothing is drawn outside it.
  public func copiesInsideUnitCell(cell: SKCell) -> [SKGeometricSurfacePatchCopy]
  {
    let inverse: double3x3 = cell.inverseUnitCell
    let unitCell: double3x3 = cell.unitCell
    var fractional = inverse * center
    fractional = SKGeometricSurface.wrappedFractional(fractional)
    let wrappedCenter: SIMD3<Double> = unitCell * fractional
    let wrapShift: SIMD3<Double> = wrappedCenter - center
    let wrappedClips: [SKGeometricSurfaceClip] = clips.map { SKGeometricSurfaceClip(center: $0.center + wrapShift, radius: $0.radius) }
    
    let extent = SKGeometricSurfacePatch.fractionalExtent(radius: radius, inverseUnitCell: inverse)
    let nx = max(1, Int(ceil(extent.x)))
    let ny = max(1, Int(ceil(extent.y)))
    let nz = max(1, Int(ceil(extent.z)))
    
    var copies: [SKGeometricSurfacePatchCopy] = []
    for wx in -nx...nx
    {
      for wy in -ny...ny
      {
        for wz in -nz...nz
        {
          let offset = SIMD3<Double>(Double(wx), Double(wy), Double(wz))
          let image = fractional + offset
          if image.x + extent.x > 0.0 && image.x - extent.x < 1.0 &&
             image.y + extent.y > 0.0 && image.y - extent.y < 1.0 &&
             image.z + extent.z > 0.0 && image.z - extent.z < 1.0
          {
            let shift: SIMD3<Double> = unitCell * offset
            copies.append(SKGeometricSurfacePatchCopy(center: wrappedCenter + shift,
                                                      clips: wrappedClips.map { SKGeometricSurfaceClip(center: $0.center + shift, radius: $0.radius) },
                                                      cellOrigin: SIMD3<Double>()))
          }
        }
      }
    }
    return copies
  }
  
  /// How far in fractional coordinates a sphere of `radius` can reach along each cell axis. Used to
  /// decide which lattice images of a patch still overlap the unit cell.
  public static func fractionalExtent(radius: Double, inverseUnitCell: double3x3) -> SIMD3<Double>
  {
    let inv: double3x3 = inverseUnitCell
    return SIMD3<Double>(radius * simd_length(SIMD3<Double>(inv[0][0], inv[1][0], inv[2][0])),
                         radius * simd_length(SIMD3<Double>(inv[0][1], inv[1][1], inv[2][1])),
                         radius * simd_length(SIMD3<Double>(inv[0][2], inv[1][2], inv[2][2])))
  }
}
