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

// Metric-aware Voronoi construction with a native fractional-coordinate interface.
//
// Ported from raspa3 `symmetrykit/skvoronoi`. The Voronoi tessellation of a periodic system is not
// invariant under the anisotropic scaling that maps a unit cell onto the fractional unit cube, so
// fractional positions cannot simply be tessellated in the unit cube. This type takes positions in
// fractional coordinates together with the unit-cell matrix h (lattice vectors as columns), bins and
// searches neighbors in fractional space, and accounts for the cell geometry exactly: candidate
// separations are mapped through h, so every bisector plane is the true Cartesian one.
//
// When per-site radii are given, the radical (power) diagram is built instead: the plane between
// sites i and j is offset towards the smaller atom by ½(rᵢ² − rⱼ²)/|Δ|, which is the tessellation
// used by zeo++/voro++ for radii-dependent pore analysis. The Apollonius diagram uses this as a
// cheap adjacency heuristic for candidate site quadruples.

/// A single face of a Voronoi cell; the face is the metric perpendicular bisector between
/// the cell's site and the periodic image `neighborImage` of site `neighborIndex`.
public struct SKVoronoiFace
{
  public var neighborIndex: Int
  public var neighborImage: SIMD3<Int32>
  public var neighborDistance: Double
  public var vertexIndices: [Int]
  public var area: Double
  public var normalCartesian: SIMD3<Double>
}

/// A Voronoi cell; vertex positions are stored relative to the site position, both in
/// fractional coordinates and mapped to Cartesian coordinates.
public struct SKVoronoiCell
{
  public var siteIndex: Int
  public var sitePositionFractional: SIMD3<Double>
  public var verticesFractional: [SIMD3<Double>]
  public var verticesCartesian: [SIMD3<Double>]
  public var faces: [SKVoronoiFace]
  public var volume: Double
  public var centroidCartesian: SIMD3<Double>
}

public enum SKVoronoiError: Error, LocalizedError
{
  case singularUnitCell
  case noPositions
  case radiiSizeMismatch
  case coincidingSites
  case constructionFailed
  
  public var errorDescription: String?
  {
    switch self
    {
    case .singularUnitCell: return "SKVoronoi: singular unit cell"
    case .noPositions: return "SKVoronoi: no positions given"
    case .radiiSizeMismatch: return "SKVoronoi: radii size does not match positions size"
    case .coincidingSites: return "SKVoronoi: coinciding sites"
    case .constructionFailed: return "SKVoronoi: cell construction failed (initial bounding cube face survived)"
    }
  }
}

public struct SKVoronoi
{
  private let unitCell: double3x3
  private let inverseUnitCell: double3x3
  private let cellVolume: Double
  private let perpendicularWidths: SIMD3<Double>
  private let positions: [SIMD3<Double>]
  private let cartesianPositions: [SIMD3<Double>]
  private let radiiSquared: [Double]
  private let maximumRadiusSquared: Double
  private let gridSize: SIMD3<Int32>
  private let bins: [[Int]]
  private let minimumBinWidth: Double
  private let initialHalfWidth: Double
  
  /// When `radii` is empty the construction is the ordinary (unweighted) Voronoi diagram.
  /// When per-site radii are given, the radical (power) diagram is built instead.
  public init(unitCell: double3x3, fractionalPositions: [SIMD3<Double>], radii: [Double] = []) throws
  {
    let determinant = unitCell.determinant
    if abs(determinant) < 1.0e-12 { throw SKVoronoiError.singularUnitCell }
    if fractionalPositions.isEmpty { throw SKVoronoiError.noPositions }
    if !radii.isEmpty && radii.count != fractionalPositions.count { throw SKVoronoiError.radiiSizeMismatch }
    
    self.unitCell = unitCell
    self.inverseUnitCell = unitCell.inverse
    self.cellVolume = abs(determinant)
    
    var squared = Array(repeating: 0.0, count: fractionalPositions.count)
    var maxSquared = 0.0
    if !radii.isEmpty
    {
      for i in 0..<radii.count
      {
        squared[i] = radii[i] * radii[i]
        maxSquared = max(maxSquared, squared[i])
      }
    }
    self.radiiSquared = squared
    self.maximumRadiusSquared = maxSquared
    
    let a = unitCell[0]
    let b = unitCell[1]
    let c = unitCell[2]
    self.perpendicularWidths = SIMD3<Double>(self.cellVolume / simd_length(simd_cross(b, c)),
                                             self.cellVolume / simd_length(simd_cross(c, a)),
                                             self.cellVolume / simd_length(simd_cross(a, b)))
    
    var wrapped: [SIMD3<Double>] = []
    var cartesian: [SIMD3<Double>] = []
    wrapped.reserveCapacity(fractionalPositions.count)
    cartesian.reserveCapacity(fractionalPositions.count)
    for position in fractionalPositions
    {
      let fractional = SIMD3<Double>(position.x - floor(position.x),
                                     position.y - floor(position.y),
                                     position.z - floor(position.z))
      wrapped.append(fractional)
      cartesian.append(unitCell * fractional)
    }
    self.positions = wrapped
    self.cartesianPositions = cartesian
    
    let targetBinSize = cbrt(self.cellVolume / max(1.0, Double(self.positions.count) / 4.0))
    let grid = SIMD3<Int32>(max(1, Int32(self.perpendicularWidths.x / targetBinSize)),
                            max(1, Int32(self.perpendicularWidths.y / targetBinSize)),
                            max(1, Int32(self.perpendicularWidths.z / targetBinSize)))
    self.gridSize = grid
    self.minimumBinWidth = min(self.perpendicularWidths.x / Double(grid.x),
                               self.perpendicularWidths.y / Double(grid.y),
                               self.perpendicularWidths.z / Double(grid.z))
    
    var bins = Array(repeating: [Int](), count: Int(grid.x) * Int(grid.y) * Int(grid.z))
    for i in 0..<self.positions.count
    {
      let bx = min(Int(grid.x) - 1, Int(self.positions[i].x * Double(grid.x)))
      let by = min(Int(grid.y) - 1, Int(self.positions[i].y * Double(grid.y)))
      let bz = min(Int(grid.z) - 1, Int(self.positions[i].z * Double(grid.z)))
      bins[(bz * Int(grid.y) + by) * Int(grid.x) + bx].append(i)
    }
    self.bins = bins
    
    var maximumBodyDiagonal = 0.0
    for sx in [-1.0, 1.0]
    {
      for sy in [-1.0, 1.0]
      {
        maximumBodyDiagonal = max(maximumBodyDiagonal, simd_length(unitCell * SIMD3<Double>(sx, sy, 1.0)))
      }
    }
    self.initialHalfWidth = 0.5 * maximumBodyDiagonal + 1.0 + sqrt(self.maximumRadiusSquared)
  }
  
  public func computeCell(siteIndex: Int) throws -> SKVoronoiCell
  {
    let site = positions[siteIndex]
    let siteCartesian = cartesianPositions[siteIndex]
    let siteBin = SIMD3<Int32>(Int32(min(Int(gridSize.x) - 1, Int(site.x * Double(gridSize.x)))),
                               Int32(min(Int(gridSize.y) - 1, Int(site.y * Double(gridSize.y)))),
                               Int32(min(Int(gridSize.z) - 1, Int(site.z * Double(gridSize.z)))))
    
    var workspace = SKVoronoiWorkspace()
    let siteRadiusSquared = radiiSquared[siteIndex]
    var poly = SKVoronoiPolyhedron.makeInitialCube(halfWidth: initialHalfWidth)
    var maxRadiusSquared = poly.maximumRadiusSquared()
    
    func searchRadiusSquaredOf(_ circumRadiusSquared: Double) -> Double
    {
      let c = max(0.0, maximumRadiusSquared - siteRadiusSquared)
      let s = sqrt(circumRadiusSquared) + sqrt(circumRadiusSquared + c)
      return s * s
    }
    var searchRadiusSquared = searchRadiusSquaredOf(maxRadiusSquared)
    
    func binAndImage(_ coordinate: Int, _ gridExtent: Int) -> (Int, Int)
    {
      let image: Int
      if coordinate >= 0
      {
        image = coordinate / gridExtent
      }
      else
      {
        image = -((-coordinate + gridExtent - 1) / gridExtent)
      }
      return (coordinate - image * gridExtent, image)
    }
    
    var k = 0
    while true
    {
      let lowerBound = Double(k - 1) * minimumBinWidth
      if k > 0 && lowerBound * lowerBound > searchRadiusSquared { break }
      
      workspace.shellCandidates.removeAll(keepingCapacity: true)
      for ox in -k...k
      {
        for oy in -k...k
        {
          for oz in -k...k
          {
            if max(abs(ox), abs(oy), abs(oz)) != k { continue }
            
            let (bx, lx) = binAndImage(Int(siteBin.x) + ox, Int(gridSize.x))
            let (by, ly) = binAndImage(Int(siteBin.y) + oy, Int(gridSize.y))
            let (bz, lz) = binAndImage(Int(siteBin.z) + oz, Int(gridSize.z))
            
            let imageShift = unitCell * SIMD3<Double>(Double(lx), Double(ly), Double(lz)) - siteCartesian
            for j in bins[(bz * Int(gridSize.y) + by) * Int(gridSize.x) + bx]
            {
              if j == siteIndex && lx == 0 && ly == 0 && lz == 0 { continue }
              let delta = cartesianPositions[j] + imageShift
              let rsq = simd_length_squared(delta)
              if rsq < 1.0e-16 { throw SKVoronoiError.coincidingSites }
              workspace.shellCandidates.append(SKVoronoiCandidate(rsq: rsq, delta: delta, index: j,
                                                                  image: SIMD3<Int32>(Int32(lx), Int32(ly), Int32(lz))))
            }
          }
        }
      }
      
      workspace.shellOrder = workspace.shellCandidates.enumerated().map { ($0.element.rsq, $0.offset) }
      workspace.shellOrder.sort { $0.0 < $1.0 }
      
      for (candidateDistance, candidateIndex) in workspace.shellOrder
      {
        if candidateDistance > searchRadiusSquared { break }
        let candidate = workspace.shellCandidates[candidateIndex]
        
        var source = SKVoronoiPolyFace()
        source.hasSource = true
        source.neighborIndex = candidate.index
        source.neighborImage = candidate.image
        source.rsq = candidate.rsq
        source.delta = candidate.delta
        
        let offset = 0.5 * (candidate.rsq + siteRadiusSquared - radiiSquared[candidate.index])
        if poly.cutByPlane(n: candidate.delta, b: offset, source: source, workspace: &workspace)
        {
          if poly.faces.isEmpty { break }
          maxRadiusSquared = poly.maximumRadiusSquared()
          searchRadiusSquared = searchRadiusSquaredOf(maxRadiusSquared)
        }
      }
      if poly.faces.isEmpty { break }
      k += 1
    }
    
    if poly.vertices.isEmpty
    {
      return SKVoronoiCell(siteIndex: siteIndex,
                           sitePositionFractional: site,
                           verticesFractional: [],
                           verticesCartesian: [],
                           faces: [],
                           volume: 0.0,
                           centroidCartesian: SIMD3<Double>())
    }
    
    if poly.faces.contains(where: { !$0.hasSource })
    {
      throw SKVoronoiError.constructionFailed
    }
    
    var cell = SKVoronoiCell(siteIndex: siteIndex,
                             sitePositionFractional: site,
                             verticesFractional: [],
                             verticesCartesian: poly.vertices,
                             faces: [],
                             volume: 0.0,
                             centroidCartesian: SIMD3<Double>())
    cell.verticesFractional.reserveCapacity(cell.verticesCartesian.count)
    for x in cell.verticesCartesian
    {
      cell.verticesFractional.append(inverseUnitCell * x)
    }
    
    cell.faces.reserveCapacity(poly.faces.count)
    for face in poly.faces
    {
      var output = SKVoronoiFace(neighborIndex: face.neighborIndex,
                                 neighborImage: face.neighborImage,
                                 neighborDistance: sqrt(face.rsq),
                                 vertexIndices: face.vertexIndices,
                                 area: 0.0,
                                 normalCartesian: simd_normalize(face.delta))
      var areaVector = SIMD3<Double>()
      let p0 = cell.verticesCartesian[output.vertexIndices[0]]
      var k = 1
      while k + 1 < output.vertexIndices.count
      {
        let p1 = cell.verticesCartesian[output.vertexIndices[k]]
        let p2 = cell.verticesCartesian[output.vertexIndices[k + 1]]
        areaVector += simd_cross(p1 - p0, p2 - p0)
        k += 1
      }
      output.area = 0.5 * simd_length(areaVector)
      cell.faces.append(output)
    }
    
    var volume = 0.0
    var centroid = SIMD3<Double>()
    for face in cell.faces
    {
      let p0 = cell.verticesCartesian[face.vertexIndices[0]]
      var k = 1
      while k + 1 < face.vertexIndices.count
      {
        let p1 = cell.verticesCartesian[face.vertexIndices[k]]
        let p2 = cell.verticesCartesian[face.vertexIndices[k + 1]]
        let tetrahedronVolume = simd_dot(p0, simd_cross(p1, p2)) / 6.0
        volume += tetrahedronVolume
        centroid += tetrahedronVolume * 0.25 * (p0 + p1 + p2)
        k += 1
      }
    }
    cell.volume = volume
    cell.centroidCartesian = volume != 0.0 ? centroid / volume : SIMD3<Double>()
    return cell
  }
  
  public func computeAllCells() throws -> [SKVoronoiCell]
  {
    var cells: [SKVoronoiCell] = []
    cells.reserveCapacity(positions.count)
    for i in 0..<positions.count
    {
      cells.append(try computeCell(siteIndex: i))
    }
    return cells
  }
}

private struct SKVoronoiPolyFace
{
  var vertexIndices: [Int] = []
  var hasSource: Bool = false
  var neighborIndex: Int = 0
  var neighborImage: SIMD3<Int32> = SIMD3<Int32>()
  var rsq: Double = 0.0
  var delta: SIMD3<Double> = SIMD3<Double>()
}

private struct SKVoronoiPolyhedron
{
  var vertices: [SIMD3<Double>] = []
  var faces: [SKVoronoiPolyFace] = []
  
  static func makeInitialCube(halfWidth: Double) -> SKVoronoiPolyhedron
  {
    var poly = SKVoronoiPolyhedron()
    let h = halfWidth
    poly.vertices = [
      SIMD3<Double>(-h, -h, -h), SIMD3<Double>(h, -h, -h),
      SIMD3<Double>(h, h, -h), SIMD3<Double>(-h, h, -h),
      SIMD3<Double>(-h, -h, h), SIMD3<Double>(h, -h, h),
      SIMD3<Double>(h, h, h), SIMD3<Double>(-h, h, h)
    ]
    poly.faces = [
      SKVoronoiPolyFace(vertexIndices: [0, 3, 2, 1]),
      SKVoronoiPolyFace(vertexIndices: [4, 5, 6, 7]),
      SKVoronoiPolyFace(vertexIndices: [0, 1, 5, 4]),
      SKVoronoiPolyFace(vertexIndices: [2, 3, 7, 6]),
      SKVoronoiPolyFace(vertexIndices: [0, 4, 7, 3]),
      SKVoronoiPolyFace(vertexIndices: [1, 2, 6, 5])
    ]
    return poly
  }
  
  func maximumRadiusSquared() -> Double
  {
    var maximum = 0.0
    for x in vertices { maximum = max(maximum, simd_length_squared(x)) }
    return maximum
  }
  
  mutating func compactVertices(workspace: inout SKVoronoiWorkspace)
  {
    workspace.remap = Array(repeating: Int.max, count: vertices.count)
    workspace.compactedVertices.removeAll(keepingCapacity: true)
    for i in 0..<faces.count
    {
      for j in 0..<faces[i].vertexIndices.count
      {
        let index = faces[i].vertexIndices[j]
        if workspace.remap[index] == Int.max
        {
          workspace.remap[index] = workspace.compactedVertices.count
          workspace.compactedVertices.append(vertices[index])
        }
        faces[i].vertexIndices[j] = workspace.remap[index]
      }
    }
    swap(&vertices, &workspace.compactedVertices)
  }
  
  mutating func cutByPlane(n: SIMD3<Double>, b: Double, source: SKVoronoiPolyFace, workspace: inout SKVoronoiWorkspace) -> Bool
  {
    let tolerance = 1.0e-10 * max(1.0, abs(b))
    let oldVertexCount = vertices.count
    
    workspace.distance = vertices.map { simd_dot($0, n) - b }
    workspace.side = workspace.distance.map { $0 > tolerance ? Int8(1) : ($0 < -tolerance ? Int8(-1) : Int8(0)) }
    let anyOutside = workspace.side.contains { $0 > 0 }
    let anyInside = workspace.side.contains { $0 < 0 }
    if !anyOutside { return false }
    if !anyInside
    {
      vertices.removeAll()
      faces.removeAll()
      return true
    }
    
    workspace.edgeCuts.removeAll(keepingCapacity: true)
    for i in 0..<faces.count
    {
      let count = faces[i].vertexIndices.count
      var touched = false
      for k in 0..<count where workspace.side[faces[i].vertexIndices[k]] >= 0
      {
        touched = true
        break
      }
      if !touched { continue }
      
      workspace.clipped.removeAll(keepingCapacity: true)
      for k in 0..<count
      {
        let a = faces[i].vertexIndices[k]
        let b2 = faces[i].vertexIndices[(k + 1) % count]
        if workspace.side[a] <= 0 { workspace.clipped.append(a) }
        if Int(workspace.side[a]) * Int(workspace.side[b2]) < 0
        {
          let lo = min(a, b2)
          let hi = max(a, b2)
          var newIndex = Int.max
          for cut in workspace.edgeCuts where cut.a == lo && cut.b == hi
          {
            newIndex = cut.index
            break
          }
          if newIndex == Int.max
          {
            let t = workspace.distance[a] / (workspace.distance[a] - workspace.distance[b2])
            vertices.append(vertices[a] + t * (vertices[b2] - vertices[a]))
            newIndex = vertices.count - 1
            workspace.edgeCuts.append(SKVoronoiWorkspace.EdgeCut(a: lo, b: hi, index: newIndex))
          }
          workspace.clipped.append(newIndex)
        }
      }
      faces[i].vertexIndices = workspace.clipped
    }
    faces.removeAll { $0.vertexIndices.count < 3 }
    
    workspace.loop.removeAll(keepingCapacity: true)
    for cut in workspace.edgeCuts { workspace.loop.append((0.0, cut.index)) }
    for i in 0..<oldVertexCount where workspace.side[i] == 0
    {
      workspace.loop.append((0.0, i))
    }
    
    if workspace.loop.count >= 3
    {
      let axis = simd_normalize(n)
      let helper = abs(axis.x) < 0.9 ? SIMD3<Double>(1.0, 0.0, 0.0) : SIMD3<Double>(0.0, 1.0, 0.0)
      let u = simd_normalize(simd_cross(helper, axis))
      let v = simd_cross(axis, u)
      
      var center = SIMD3<Double>()
      for (_, index) in workspace.loop { center += vertices[index] }
      center /= Double(workspace.loop.count)
      
      for i in 0..<workspace.loop.count
      {
        let p = vertices[workspace.loop[i].1] - center
        let x = simd_dot(p, u)
        let y = simd_dot(p, v)
        let r = abs(x) + abs(y)
        let q = r > 0.0 ? y / r : 0.0
        let angle = x >= 0.0 ? q : (q >= 0.0 ? 2.0 - q : -2.0 - q)
        workspace.loop[i].0 = angle
      }
      workspace.loop.sort { $0.0 < $1.0 }
      
      var closing = source
      closing.vertexIndices = workspace.loop.map { $0.1 }
      faces.append(closing)
    }
    
    compactVertices(workspace: &workspace)
    return true
  }
}

private struct SKVoronoiCandidate
{
  var rsq: Double
  var delta: SIMD3<Double>
  var index: Int
  var image: SIMD3<Int32>
}

private struct SKVoronoiWorkspace
{
  struct EdgeCut
  {
    var a: Int
    var b: Int
    var index: Int
  }
  
  var distance: [Double] = []
  var side: [Int8] = []
  var clipped: [Int] = []
  var edgeCuts: [EdgeCut] = []
  var loop: [(Double, Int)] = []
  var remap: [Int] = []
  var compactedVertices: [SIMD3<Double>] = []
  var shellCandidates: [SKVoronoiCandidate] = []
  var shellOrder: [(Double, Int)] = []
}
