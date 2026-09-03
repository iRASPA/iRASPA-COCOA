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
import Metal
import simd
import LogViewKit

// The well surface: where an adsorbed molecule sits, as opposed to the iso-surface, which is where it turns
// back. Its topology comes from a distance field and its geometry from the energy (see the well-field section
// of ComputeEnergyGrid.metal for the full picture):
//
//   - SKMetalFramework.ComputeWellFieldGrid supplies three floats per grid point: the energy U, the
//     additively weighted (Apollonius) distance d = min over atoms of (|x - a| - 2^(1/6) sigma), whose zero
//     level set is the probe-contact offset surface of the framework, and the medial reliability rel
//     (1 against one wall, 0 on the medial axis of a channel where opposing walls cancel).
//   - The field handed to the ordinary marching cubes is max(-d, s (U - iso)): its zero set bounds the region
//     { d > 0 and U < iso }, the pore trimmed to wells at least iso deep, with smooth isosurface caps at the
//     trim. Being the boundary of a region, it is watertight and single-sheeted --- no interior membranes,
//     domes, or flaps, which were the failure modes of the crease-set extraction this replaces.
//   - SKMetalFramework.RefineWellSurfaceVertexBuffer then slides each vertex along the ray to its nearest
//     atom onto the exact 1D minimum of the analytic energy: the true multi-atom well floor.
//   - Where the channel is narrower than the probe's contact diameter the sheet cannot exist (d < 0 across
//     the whole cross-section), yet those are the deepest wells of all: the transverse minima have merged
//     onto the channel axis, a 1D filament. constructWellFilamentVertexBuffer draws it as a thin tube, the
//     zero set of max(rel - r0, d, s (U - iso)): enclosed by opposing walls, inside the contact region, and
//     at least iso deep. That is where an enclosed adsorbate sits --- there is no wall sheet left. Where the
//     channel widens, d crosses zero on the axis and the tube caps at the tip of the closing sheet; those
//     gaps are physical, not holes. Reliability is not a distance field, so thresholding it still punches
//     one-voxel gaps inside a pinch: morphological closing, clipped to { d < 0, U < iso }, fills those
//     without growing into the contact sheet. It is its own rendering method (the well-surface overlay), so
//     a copy of the structure can superimpose it on the well surface with a distinct material. The sheet
//     constructor returns nil rather than substituting a high marching-cubes isovalue when that region is
//     empty, which would draw a surface inside the atoms. Well-surface mode then draws nothing; the overlay
//     is the only way to see the filament.
public class SKMetalWellSurface
{
  // one angstrom of distance field equals this many kelvin of energy in the combined field; it only shapes
  // interpolation and normals near the trim seam, the zero set itself is independent of it
  public static let energyScale: Float = 0.001

  // The trim level actually used: the isovalue, unless that is below the deepest well on the grid (nothing
  // would remain), in which case a quarter of the deepest well, like the marching-cubes fallback.
  public static func effectiveTrimIsovalue(field: [Float], isovalue: Double, dimensions: SIMD3<Int32>) -> Float
  {
    let numberOfGridPoints: Int = Int(dimensions.x) * Int(dimensions.y) * Int(dimensions.z)
    var minimumEnergy: Float = Float.greatestFiniteMagnitude
    for i in 0..<numberOfGridPoints
    {
      minimumEnergy = min(minimumEnergy, field[3 * i])
    }
    var iso = Float(isovalue)
    if !(iso > minimumEnergy)
    {
      iso = 0.25 * minimumEnergy
      LogQueue.shared.warning(destination: nil, message: String(format: "Iso %.1f K is below the deepest well (%.1f K); trimming the well surface at %.1f K instead.", isovalue, minimumEnergy, iso))
    }
    return iso
  }

  public static func constructWellSurfaceVertexBuffer(device: MTLDevice?, commandQueue: MTLCommandQueue?, field: [Float], isovalue: Double, dimensions: SIMD3<Int32>, onGPU: Bool = true) throws -> MTLBuffer?
  {
    let numberOfGridPoints: Int = Int(dimensions.x) * Int(dimensions.y) * Int(dimensions.z)
    guard numberOfGridPoints > 0, field.count >= 3 * numberOfGridPoints else {
      LogQueue.shared.error(destination: nil, message: "Well surface: the field grid is empty or does not match the dimensions")
      return nil
    }

    let iso: Float = effectiveTrimIsovalue(field: field, isovalue: isovalue, dimensions: dimensions)

    // the pore, trimmed: inside is negative, like the energy grid the isosurface machinery expects
    var combined: [Float] = [Float](repeating: 0.0, count: numberOfGridPoints)
    var distanceMax: Float = -.greatestFiniteMagnitude
    for i in 0..<numberOfGridPoints
    {
      combined[i] = max(-field[3 * i + 1], energyScale * (field[3 * i] - iso))
      distanceMax = max(distanceMax, field[3 * i + 1])
    }

    // { d > 0 and U < iso } empty: the probe's contact diameter does not fit, so there is no sheet.
    // Marching cubes must not invent a high isovalue on this mixed-unit field --- that surface sits
    // inside the atoms, closer to them than the 0 K isosurface. Return nil; well-surface mode draws
    // nothing. The merged-well filament along the channel axis is the overlay, not a stand-in.
    guard let minC = combined.min(), let maxC = combined.max(), minC < 0.0 && maxC > 0.0 else
    {
      LogQueue.shared.warning(destination: nil, message: String(format: "Well surface: the probe does not fit as a contact sheet (largest opening %.3f Å relative to the contact diameter). The adsorbed molecule sits on the channel axis instead.", distanceMax))
      return nil
    }

    return try SKMetalMarchingCubes.constructIsoSurfaceVertexBuffer(device: device, commandQueue: commandQueue, data: combined, isovalue: 0.0, dimensions: dimensions, substituteIsovalueIfNeeded: false)
  }

  // Where opposing walls cancel (rel below this) the point is close enough to the channel medial axis to
  // belong to the merged-well filament. Between fully surrounding walls rel falls to 0; against one wall,
  // even in the creases between its atoms, the directions cannot cancel and rel stays above ~0.46 (measured
  // in MFI). The 0.45 threshold sits just under that floor, giving the tube its full transverse extent
  // (~0.4 A in a deep pinch, about the thermal amplitude of a trapped molecule at room temperature) while
  // the crease set stays out; whatever grazes through is specks, removed by the area filter below.
  public static let filamentReliabilityThreshold: Float = 0.45

  // Isolated filament specks smaller than this are crease leakage, not channel filaments: a real merged-well
  // tube runs the length of a channel segment and measures several square angstrom.
  public static let filamentMinimumArea: Double = 2.0

  // Closing radius, in voxels, for reliability holes inside a pinch. Clipped to { d < 0, U < iso }, so it
  // cannot grow into the contact sheet or join separate pinches through a wide pore.
  public static let filamentClosingRadius: Int = 2

  // The merged-well filament: the boundary of { rel < r0, d < 0, U < iso } --- enclosed by opposing walls,
  // in a channel too narrow for the contact sheet, and at least iso deep. That is where the adsorbate sits
  // when there is no wall sheet left. Morphological closing fills reliability holes inside that region;
  // where d crosses zero the tube still caps at the sheet. Returns nil when no wells have merged.
  public static func constructWellFilamentVertexBuffer(device: MTLDevice?, commandQueue: MTLCommandQueue?, field: [Float], isovalue: Double, dimensions: SIMD3<Int32>, unitCell: double3x3, onGPU: Bool = true) throws -> MTLBuffer?
  {
    let nx: Int = Int(dimensions.x)
    let ny: Int = Int(dimensions.y)
    let nz: Int = Int(dimensions.z)
    let numberOfGridPoints: Int = nx * ny * nz
    guard nx > 0, ny > 0, nz > 0, field.count >= 3 * numberOfGridPoints else { return nil }

    let iso: Float = effectiveTrimIsovalue(field: field, isovalue: isovalue, dimensions: dimensions)

    var candidate: [Bool] = [Bool](repeating: false, count: numberOfGridPoints)
    var seeds: [Bool] = [Bool](repeating: false, count: numberOfGridPoints)
    var anySeed: Bool = false
    for i in 0..<numberOfGridPoints
    {
      let energyTerm: Float = energyScale * (field[3 * i] - iso)
      let distance: Float = field[3 * i + 1]
      if distance < 0.0 && energyTerm < 0.0
      {
        candidate[i] = true
        if field[3 * i + 2] < filamentReliabilityThreshold
        {
          seeds[i] = true
          anySeed = true
        }
      }
    }
    if !anySeed { return nil }

    // Geodesic closing inside the contact/energy region: fill reliability gaps, then restore any rim
    // seeds that erosion ate because the pinch is only a voxel or two thick.
    var closed: [Bool] = seeds
    for _ in 0..<filamentClosingRadius
    {
      closed = dilateBinary(closed, nx: nx, ny: ny, nz: nz)
      for i in 0..<numberOfGridPoints where !candidate[i] { closed[i] = false }
    }
    for _ in 0..<filamentClosingRadius { closed = erodeBinary(closed, nx: nx, ny: ny, nz: nz) }
    for i in 0..<numberOfGridPoints
    {
      if !candidate[i] { closed[i] = false }
      else if seeds[i] { closed[i] = true }
    }
    fillEnclosedCavities(closed: &closed, candidate: candidate, nx: nx, ny: ny, nz: nz)

    var combined: [Float] = [Float](repeating: 0.0, count: numberOfGridPoints)
    var interiorPoints: Int = 0
    for i in 0..<numberOfGridPoints
    {
      let energyTerm: Float = energyScale * (field[3 * i] - iso)
      let distance: Float = field[3 * i + 1]
      let raw: Float = max(field[3 * i + 2] - filamentReliabilityThreshold, max(distance, energyTerm))
      // Filled holes keep max(d, s(U-iso)), the same two fields the well surface is built from, so the
      // d = 0 cap still meets the sheet. Reliability stays in the raw field on the tube's side wall.
      let value: Float = closed[i] && raw >= 0.0 ? min(-1.0e-4, max(distance, energyTerm)) : raw
      combined[i] = value
      if value < 0.0 { interiorPoints += 1 }
    }
    if interiorPoints == 0 { return nil }

    guard let buffer: MTLBuffer = try SKMetalMarchingCubes.constructIsoSurfaceVertexBuffer(device: device, commandQueue: commandQueue, data: combined, isovalue: 0.0, dimensions: dimensions, substituteIsovalueIfNeeded: false) else { return nil }
    return removeFilamentSpecks(device: device, buffer: buffer, unitCell: unitCell)
  }

  private static func dilateBinary(_ mask: [Bool], nx: Int, ny: Int, nz: Int) -> [Bool]
  {
    var out: [Bool] = mask
    let nxy: Int = nx * ny
    for z in 0..<nz
    {
      let zm: Int = (z == 0) ? nz - 1 : z - 1
      let zp: Int = (z + 1 == nz) ? 0 : z + 1
      for y in 0..<ny
      {
        let ym: Int = (y == 0) ? ny - 1 : y - 1
        let yp: Int = (y + 1 == ny) ? 0 : y + 1
        let yz: [Int] = [ym, y, yp]
        let zz: [Int] = [zm, z, zp]
        for x in 0..<nx
        {
          let i: Int = x + nx * y + nxy * z
          if mask[i] { continue }
          let xm: Int = (x == 0) ? nx - 1 : x - 1
          let xp: Int = (x + 1 == nx) ? 0 : x + 1
          var found: Bool = false
          for zb in zz
          {
            for yb in yz
            {
              let row: Int = nx * yb + nxy * zb
              if mask[xm + row] || mask[x + row] || mask[xp + row] { found = true; break }
            }
            if found { break }
          }
          if found { out[i] = true }
        }
      }
    }
    return out
  }

  private static func erodeBinary(_ mask: [Bool], nx: Int, ny: Int, nz: Int) -> [Bool]
  {
    var out: [Bool] = mask
    let nxy: Int = nx * ny
    for z in 0..<nz
    {
      let zm: Int = (z == 0) ? nz - 1 : z - 1
      let zp: Int = (z + 1 == nz) ? 0 : z + 1
      for y in 0..<ny
      {
        let ym: Int = (y == 0) ? ny - 1 : y - 1
        let yp: Int = (y + 1 == ny) ? 0 : y + 1
        let yz: [Int] = [ym, y, yp]
        let zz: [Int] = [zm, z, zp]
        for x in 0..<nx
        {
          let i: Int = x + nx * y + nxy * z
          if !mask[i] { continue }
          let xm: Int = (x == 0) ? nx - 1 : x - 1
          let xp: Int = (x + 1 == nx) ? 0 : x + 1
          var keep: Bool = true
          outer: for zb in zz
          {
            for yb in yz
            {
              let row: Int = nx * yb + nxy * zb
              if !mask[xm + row] || !mask[x + row] || !mask[xp + row] { keep = false; break outer }
            }
          }
          if !keep { out[i] = false }
        }
      }
    }
    return out
  }

  // Bubbles inside the tube that do not reach { d > 0 or U > iso }. Flood from the true exterior through
  // the open voxels and mark whatever remains as interior.
  private static func fillEnclosedCavities(closed: inout [Bool], candidate: [Bool], nx: Int, ny: Int, nz: Int)
  {
    let n: Int = nx * ny * nz
    let nxy: Int = nx * ny
    var exterior: [Bool] = [Bool](repeating: false, count: n)
    var stack: [Int] = []
    stack.reserveCapacity(n / 8)
    for i in 0..<n where !closed[i] && !candidate[i]
    {
      exterior[i] = true
      stack.append(i)
    }
    while let i = stack.popLast()
    {
      let x: Int = i % nx
      let y: Int = (i / nx) % ny
      let z: Int = i / nxy
      let xm: Int = (x == 0) ? nx - 1 : x - 1
      let xp: Int = (x + 1 == nx) ? 0 : x + 1
      let ym: Int = (y == 0) ? ny - 1 : y - 1
      let yp: Int = (y + 1 == ny) ? 0 : y + 1
      let zm: Int = (z == 0) ? nz - 1 : z - 1
      let zp: Int = (z + 1 == nz) ? 0 : z + 1
      let neighbors: [Int] = [
        xm + nx * y + nxy * z, xp + nx * y + nxy * z,
        x + nx * ym + nxy * z, x + nx * yp + nxy * z,
        x + nx * y + nxy * zm, x + nx * y + nxy * zp
      ]
      for nb in neighbors where !closed[nb] && !exterior[nb]
      {
        exterior[nb] = true
        stack.append(nb)
      }
    }
    for i in 0..<n where !closed[i] && !exterior[i] { closed[i] = true }
  }

  // Connected components of the filament mesh by periodically welded vertices; components below
  // filamentMinimumArea are dropped. The filament buffer is small, a CPU pass.
  private static func removeFilamentSpecks(device: MTLDevice?, buffer: MTLBuffer, unitCell: double3x3) -> MTLBuffer?
  {
    let triangles: Int = buffer.length / (9 * MemoryLayout<SIMD4<Float>>.stride)
    guard triangles > 0 else { return nil }
    let vertices = buffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: 9 * triangles)

    var parent: [Int] = Array(0..<triangles)
    func findRoot(_ i: Int) -> Int
    {
      var r = i; while parent[r] != r { r = parent[r] }
      var w = i; while parent[w] != r { let nx = parent[w]; parent[w] = r; w = nx }
      return r
    }
    struct Key: Hashable { let x: Int32; let y: Int32; let z: Int32 }
    // a vertex on the face x = 1 is the same point as its twin on x = 0
    func quantize(_ x: Float) -> Int32 { let r = Int32((x * 1048576.0).rounded()); return r == 1048576 ? 0 : r }
    var seen: [Key: Int] = [:]
    seen.reserveCapacity(3 * triangles)
    for t in 0..<triangles
    {
      for v in 0..<3
      {
        let p = vertices[9 * t + 3 * v]
        let key = Key(x: quantize(p.x), y: quantize(p.y), z: quantize(p.z))
        if let other = seen[key]
        {
          let a = findRoot(t), b = findRoot(other)
          if a != b { parent[max(a, b)] = min(a, b) }
        }
        else { seen[key] = t }
      }
    }

    var area: [Int: Double] = [:]
    for t in 0..<triangles
    {
      var corners: [SIMD3<Double>] = []
      for v in 0..<3
      {
        let p = vertices[9 * t + 3 * v]
        corners.append(unitCell * SIMD3<Double>(Double(p.x), Double(p.y), Double(p.z)))
      }
      area[findRoot(t), default: 0.0] += 0.5 * simd_length(simd_cross(corners[1] - corners[0], corners[2] - corners[0]))
    }

    var kept: [Int] = []
    kept.reserveCapacity(triangles)
    for t in 0..<triangles
    {
      if area[findRoot(t), default: 0.0] >= filamentMinimumArea { kept.append(t) }
    }
    guard !kept.isEmpty else { return nil }
    if kept.count == triangles { return buffer }

    let triangleStride: Int = 9 * MemoryLayout<SIMD4<Float>>.stride
    guard let filtered: MTLBuffer = device?.makeBuffer(length: kept.count * triangleStride, options: .storageModeShared) else { return buffer }
    for (i, t) in kept.enumerated()
    {
      memcpy(filtered.contents() + i * triangleStride, buffer.contents() + t * triangleStride, triangleStride)
    }
    return filtered
  }

}
