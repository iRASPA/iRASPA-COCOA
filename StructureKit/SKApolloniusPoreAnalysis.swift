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

// The zeo++ pore properties computed from the Apollonius diagram: the pore diameters Di, Df and Dif,
// and the channel/pocket analysis for a probe.
//
// Ported from raspa3 `structurekit/diagrams/apollonius` and the shared `pore_diameters` /
// `channel_analysis` modules. Both analyses run on one pore network read off the additively
// weighted diagram. Building the diagram costs far more than either analysis, which is why they
// are done together here.
//
// The diagram is the exact answer where a radical Voronoi network is an approximation of it. Its
// vertices are the true maxima of the clearance, so Di is the deepest of them rather than the best
// a local ascent could find; its arcs carry the true narrowest point of each passage, so Df is the
// real bottleneck of the percolating path.

/// Largest included / free / included-along-free-path sphere diameters (Di, Df, Dif).
///
///   Di  : diameter of the largest sphere that fits anywhere in the pore space.
///   Df  : diameter of the largest sphere that can travel through the network along a
///         path that percolates through the periodic boundary.
///   Dif : diameter of the largest sphere that can be inscribed anywhere along that same
///         percolating (free-sphere) path.
///
/// A second independent percolating channel (another lattice direction, or a disconnected
/// channel system) gets its own Df and Dif. They stay zero when the network has only one
/// channel. Di is a property of the whole void space, not of a channel.
public struct SKPoreDiameters
{
  public var includedSphereDiameter: Double
  public var freeSphereDiameter: Double
  public var includedAlongFreePathDiameter: Double
  public var freeSphereDiameter2: Double
  public var includedAlongFreePathDiameter2: Double
  
  public init(includedSphereDiameter: Double = 0.0,
              freeSphereDiameter: Double = 0.0,
              includedAlongFreePathDiameter: Double = 0.0,
              freeSphereDiameter2: Double = 0.0,
              includedAlongFreePathDiameter2: Double = 0.0)
  {
    self.includedSphereDiameter = includedSphereDiameter
    self.freeSphereDiameter = freeSphereDiameter
    self.includedAlongFreePathDiameter = includedAlongFreePathDiameter
    self.freeSphereDiameter2 = freeSphereDiameter2
    self.includedAlongFreePathDiameter2 = includedAlongFreePathDiameter2
  }
}

/// Identification of channels and pockets of a pore network for a given probe radius, and their
/// dimensionality. After pruning nodes and edges that are too narrow for the probe, each connected
/// component is examined for periodic self-connection: if a walk reaches a node it has already
/// visited but at a different periodic image, the component percolates and is a channel; otherwise
/// it is an isolated pocket. The dimensionality (1/2/3) is the rank of the lattice-translation
/// vectors along which the component connects to itself.
public struct SKChannelAnalysis
{
  public var numberOfChannels: Int
  public var numberOfPockets: Int
  /// The dimensionality of the pore system as a whole: the widest-running of its channels.
  public var dimensionality: Int
  
  public init(numberOfChannels: Int = 0, numberOfPockets: Int = 0, dimensionality: Int = 0)
  {
    self.numberOfChannels = numberOfChannels
    self.numberOfPockets = numberOfPockets
    self.dimensionality = dimensionality
  }
}

/// The first three crystallographic window sizes in the IZA sense: smallest and largest
/// opposite-oxygen free diameters of the rings that open onto percolating channels, in Å.
/// That is the measurement the zeolite atlas quotes for every framework type (8-, 10-, 12-,
/// 14-rings, …), using the atom radii of the snapshot (atlas oxygen is 1.35 Å). Empty pairs
/// stay zero when fewer than three distinct apertures are present. `ringAtomCounts` is the
/// number of T-atoms (equivalently oxygens) that form each ring.
public struct SKPoreWindowSizes
{
  public var sizes: [SIMD2<Double>]
  public var ringAtomCounts: [Int]
  
  public init(sizes: [SIMD2<Double>] = [SIMD2<Double>(), SIMD2<Double>(), SIMD2<Double>()],
              ringAtomCounts: [Int] = [0, 0, 0])
  {
    var padded = sizes
    while padded.count < 3 { padded.append(SIMD2<Double>()) }
    if padded.count > 3 { padded = Array(padded.prefix(3)) }
    self.sizes = padded
    var rings = ringAtomCounts
    while rings.count < 3 { rings.append(0) }
    if rings.count > 3 { rings = Array(rings.prefix(3)) }
    self.ringAtomCounts = rings
  }
}

/// The Apollonius-diagram pore properties of one framework: Di, Df, Dif, the channel/pocket
/// split for the snapshot's probe, and the first three channel window sizes.
public struct SKApolloniusPoreAnalysis
{
  public var diameters: SKPoreDiameters
  public var channels: SKChannelAnalysis
  public var windows: SKPoreWindowSizes
  
  public init(diameters: SKPoreDiameters = SKPoreDiameters(),
              channels: SKChannelAnalysis = SKChannelAnalysis(),
              windows: SKPoreWindowSizes = SKPoreWindowSizes())
  {
    self.diameters = diameters
    self.channels = channels
    self.windows = windows
  }
  
  /// Atom radius for the diagram: half the Lennard-Jones sigma, as in raspa3.
  public static func atomRadius(sigma: Double) -> Double
  {
    return 0.5 * sigma
  }
  
  /// Probe radius used to prune the network into channels and pockets: half the probe sigma.
  public static func probeRadius(sigma: Double) -> Double
  {
    return 0.5 * sigma
  }
  
  public static func compute(snapshot: SKFrameworkSnapshot) -> SKApolloniusPoreAnalysis
  {
    guard let network = poreNetwork(snapshot: snapshot) else { return SKApolloniusPoreAnalysis() }
    let pores = poreComponents(network: network, probeRadius: probeRadius(sigma: snapshot.probeParameters.y))
    var analysis = SKApolloniusPoreAnalysis()
    analysis.diameters = SKPoreDiameters.compute(network: network)
    analysis.channels = SKChannelAnalysis.from(pores)
    analysis.windows = SKPoreWindowSizes.compute(network: network)
    return analysis
  }
  
  /// One blocking sphere per isolated pocket: the largest inscribed sphere of that pocket, as a
  /// fractional position and a radius in Å. Channels are left open.
  public static func computeBlockingPockets(snapshot: SKFrameworkSnapshot) -> [SIMD4<Double>]
  {
    guard let network = poreNetwork(snapshot: snapshot) else { return [] }
    let pores = poreComponents(network: network, probeRadius: probeRadius(sigma: snapshot.probeParameters.y))
    var pockets: [SIMD4<Double>] = []
    for pore in pores where !pore.isChannel
    {
      guard let deepest = pore.nodeIndices.max(by: { network.nodes[$0].radius < network.nodes[$1].radius }) else { continue }
      let node = network.nodes[deepest]
      if node.radius <= 0.0 { continue }
      pockets.append(SIMD4<Double>(node.fractional.x, node.fractional.y, node.fractional.z, node.radius))
    }
    return pockets
  }
  
  public static func computeBlockingPockets(structures: [SKFrameworkSnapshot]) -> [[SIMD4<Double>]]
  {
    return structures.map { computeBlockingPockets(snapshot: $0) }
  }
  
  private static func poreNetwork(snapshot: SKFrameworkSnapshot) -> SKApolloniusPoreNetwork?
  {
    let count = min(snapshot.positions.count, snapshot.potentialParameters.count)
    guard count > 0 else { return nil }
    
    var fractionalPositions: [SIMD3<Double>] = []
    var radii: [Double] = []
    fractionalPositions.reserveCapacity(count)
    radii.reserveCapacity(count)
    for i in 0..<count
    {
      let position = snapshot.positions[i]
      fractionalPositions.append(SIMD3<Double>(position.x - floor(position.x),
                                               position.y - floor(position.y),
                                               position.z - floor(position.z)))
      radii.append(atomRadius(sigma: snapshot.potentialParameters[i].y))
    }
    
    return SKApolloniusPoreNetwork.create(unitCell: snapshot.cell.unitCell,
                                          fractionalPositions: fractionalPositions,
                                          radii: radii)
  }
  
  public static func compute(structures: [SKFrameworkSnapshot]) -> [SKApolloniusPoreAnalysis]
  {
    return structures.map { compute(snapshot: $0) }
  }
  
  public static func computeChannels(structures: [SKFrameworkSnapshot]) -> [SKChannelAnalysis]
  {
    return compute(structures: structures).map { $0.channels }
  }
  
  public static func computeDiameters(structures: [SKFrameworkSnapshot]) -> [SKPoreDiameters]
  {
    return compute(structures: structures).map { $0.diameters }
  }
  
  public static func computeWindows(structures: [SKFrameworkSnapshot]) -> [SKPoreWindowSizes]
  {
    return compute(structures: structures).map { $0.windows }
  }
}

// MARK: - Pore network

struct SKPoreNode
{
  var position: SIMD3<Double>
  var fractional: SIMD3<Double>
  var radius: Double
  var maximalRadius: Double
}

struct SKPoreEdge
{
  var from: Int
  var to: Int
  var delta: SIMD3<Int32>
  var radius: Double
  var bottleneckPosition: SIMD3<Double> = SIMD3<Double>()
  var bottleneckDirection: SIMD3<Double> = SIMD3<Double>()
  var hasBottleneckGeometry: Bool = false
}

struct SKApolloniusPoreNetwork
{
  var nodes: [SKPoreNode] = []
  var edges: [SKPoreEdge] = []
  var numberOfRings: Int = 0
  var unitCell: double3x3 = double3x3()
  var atomPositionsFractional: [SIMD3<Double>] = []
  var atomRadii: [Double] = []
  
  var largestIncludedSphereDiameter: Double
  {
    var maximum = 0.0
    for node in nodes { maximum = max(maximum, node.maximalRadius) }
    return 2.0 * maximum
  }
  
  static func create(unitCell: double3x3,
                     fractionalPositions: [SIMD3<Double>],
                     radii: [Double]) -> SKApolloniusPoreNetwork
  {
    var network = SKApolloniusPoreNetwork()
    network.unitCell = unitCell
    network.atomPositionsFractional = fractionalPositions
    network.atomRadii = radii
    let inverseCell = unitCell.inverse
    let diagram = SKApolloniusDiagram.create(unitCell: unitCell,
                                             fractionalPositions: fractionalPositions,
                                             radii: radii,
                                             neighbourRings: 1,
                                             region: .freeSpace)
    
    network.nodes.reserveCapacity(diagram.vertices.count)
    for vertex in diagram.vertices
    {
      let fractional = inverseCell * vertex.position
      let wrapped = SIMD3<Double>(fractional.x - floor(fractional.x),
                                  fractional.y - floor(fractional.y),
                                  fractional.z - floor(fractional.z))
      network.nodes.append(SKPoreNode(position: vertex.position,
                                      fractional: wrapped,
                                      radius: vertex.radius,
                                      maximalRadius: vertex.radius))
    }
    
    network.edges.reserveCapacity(2 * diagram.edges.count)
    for edge in diagram.edges
    {
      if edge.isLoop
      {
        network.numberOfRings += 1
        continue
      }
      // The arc's bottleneck is given in the frame in which `from` sits in the home cell, so the
      // reverse edge, whose `from` is the other end, sees it one image away.
      let reverseShift = unitCell * SIMD3<Double>(Double(edge.toImage.x), Double(edge.toImage.y), Double(edge.toImage.z))
      network.edges.append(SKPoreEdge(from: edge.from, to: edge.to, delta: edge.toImage, radius: edge.bottleneckRadius,
                                      bottleneckPosition: edge.bottleneckPosition,
                                      bottleneckDirection: edge.bottleneckDirection,
                                      hasBottleneckGeometry: true))
      network.edges.append(SKPoreEdge(from: edge.to, to: edge.from, delta: latticeNegate(edge.toImage), radius: edge.bottleneckRadius,
                                      bottleneckPosition: edge.bottleneckPosition - reverseShift,
                                      bottleneckDirection: -edge.bottleneckDirection,
                                      hasBottleneckGeometry: true))
    }
    return network
  }
}

// MARK: - Diameters

extension SKPoreDiameters
{
  static func compute(network: SKApolloniusPoreNetwork) -> SKPoreDiameters
  {
    var diameters = SKPoreDiameters()
    diameters.includedSphereDiameter = network.largestIncludedSphereDiameter
    if network.nodes.isEmpty || network.edges.isEmpty { return diameters }
    
    let paths = widestIndependentPercolatingPaths(network: network, maxCount: 2)
    if paths.count >= 1
    {
      diameters.freeSphereDiameter = 2.0 * paths[0].radius
      diameters.includedAlongFreePathDiameter = 2.0 * includedRadius(network: network, nodes: paths[0].componentNodes)
    }
    if paths.count >= 2
    {
      diameters.freeSphereDiameter2 = 2.0 * paths[1].radius
      diameters.includedAlongFreePathDiameter2 = 2.0 * includedRadius(network: network, nodes: paths[1].componentNodes)
    }
    return diameters
  }
}

private func includedRadius(network: SKApolloniusPoreNetwork, nodes: [Int]) -> Double
{
  var maximum = 0.0
  for node in nodes { maximum = max(maximum, network.nodes[node].maximalRadius) }
  return maximum
}

private struct SKPercolatingPath
{
  var percolates: Bool = false
  var radius: Double = 0.0
  var limitingEdge: Int = 0
  var componentNodes: [Int] = []
}

/// Union-find over network nodes that also tracks the integer lattice offset of each node
/// relative to its set representative. Merging two nodes that are already connected with a
/// different net offset signals a path that percolates through the periodic boundary.
private struct SKPeriodicUnionFind
{
  var parent: [Int]
  var offset: [SIMD3<Int32>]
  
  init(count: Int)
  {
    self.parent = Array(0..<count)
    self.offset = Array(repeating: SIMD3<Int32>(), count: count)
  }
  
  mutating func find(_ x: Int) -> (Int, SIMD3<Int32>)
  {
    var node = x
    var accumulated = SIMD3<Int32>()
    while parent[node] != node
    {
      accumulated = latticeAdd(accumulated, offset[node])
      node = parent[node]
    }
    return (node, accumulated)
  }
}

/// Up to `maxCount` independent percolating channels, widest first. A new channel is either a
/// disconnected percolating component or a linearly independent lattice direction of an already
/// percolating component (MFI's two intersecting 10-ring channels).
private func widestIndependentPercolatingPaths(network: SKApolloniusPoreNetwork, maxCount: Int) -> [SKPercolatingPath]
{
  var paths: [SKPercolatingPath] = []
  if network.nodes.isEmpty || network.edges.isEmpty || maxCount <= 0 { return paths }
  
  var order: [Int] = Array(0..<network.edges.count)
  order.sort { network.edges[$0].radius > network.edges[$1].radius }
  
  var unionFind = SKPeriodicUnionFind(count: network.nodes.count)
  var loopVectors: [SIMD3<Int32>] = []
  var percolatedRoots = Set<Int>()
  
  for index in order
  {
    let edge = network.edges[index]
    let (rootFrom, accFrom) = unionFind.find(edge.from)
    let (rootTo, accTo) = unionFind.find(edge.to)
    
    if rootFrom == rootTo
    {
      let net = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
      if net == SIMD3<Int32>() { continue }
      var trial = loopVectors
      trial.append(net)
      let newDirection = latticeVectorRank(trial) > loopVectors.count
      let newComponent = !percolatedRoots.contains(rootFrom)
      if !newDirection && !newComponent { continue }
      
      var path = SKPercolatingPath()
      path.percolates = true
      path.radius = edge.radius
      path.limitingEdge = index
      for node in 0..<network.nodes.count
      {
        if unionFind.find(node).0 == rootFrom { path.componentNodes.append(node) }
      }
      paths.append(path)
      percolatedRoots.insert(rootFrom)
      if newDirection { loopVectors.append(net) }
      if paths.count == maxCount { break }
    }
    else
    {
      unionFind.parent[rootTo] = rootFrom
      unionFind.offset[rootTo] = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
      if percolatedRoots.contains(rootFrom) || percolatedRoots.contains(rootTo)
      {
        percolatedRoots.insert(rootFrom)
      }
    }
  }
  return paths
}

/// The widest path that percolates through the periodic boundary. Widest is in the max-min sense,
/// the path whose narrowest edge is as wide as possible, so the edges are added widest first and
/// the first one that closes a loop with a non-zero net lattice offset is the bottleneck.
private func widestPercolatingPath(network: SKApolloniusPoreNetwork, nodes: [Int]) -> SKPercolatingPath
{
  var path = SKPercolatingPath()
  if network.nodes.isEmpty || network.edges.isEmpty || nodes.isEmpty { return path }
  
  var inSubset = Array(repeating: false, count: network.nodes.count)
  for node in nodes { inSubset[node] = true }
  
  var order: [Int] = []
  order.reserveCapacity(network.edges.count)
  for i in 0..<network.edges.count
  {
    let edge = network.edges[i]
    if inSubset[edge.from] && inSubset[edge.to] { order.append(i) }
  }
  order.sort { network.edges[$0].radius > network.edges[$1].radius }
  
  var unionFind = SKPeriodicUnionFind(count: network.nodes.count)
  var percolatingRoot = 0
  
  for index in order
  {
    let edge = network.edges[index]
    let (rootFrom, accFrom) = unionFind.find(edge.from)
    let (rootTo, accTo) = unionFind.find(edge.to)
    
    if rootFrom == rootTo
    {
      let net = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
      if net != SIMD3<Int32>()
      {
        path.percolates = true
        path.radius = edge.radius
        path.limitingEdge = index
        percolatingRoot = rootFrom
        break
      }
    }
    else
    {
      unionFind.parent[rootTo] = rootFrom
      unionFind.offset[rootTo] = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
    }
  }
  
  if !path.percolates { return path }
  for node in nodes
  {
    if unionFind.find(node).0 == percolatingRoot { path.componentNodes.append(node) }
  }
  return path
}

// MARK: - Channels

private struct SKPoreComponent
{
  var isChannel: Bool
  var dimensionality: Int
  var nodeIndices: [Int]
}

extension SKChannelAnalysis
{
  fileprivate static func from(_ pores: [SKPoreComponent]) -> SKChannelAnalysis
  {
    var analysis = SKChannelAnalysis()
    for pore in pores
    {
      if pore.isChannel
      {
        analysis.numberOfChannels += 1
        analysis.dimensionality = max(analysis.dimensionality, pore.dimensionality)
      }
      else
      {
        analysis.numberOfPockets += 1
      }
    }
    return analysis
  }
  
  static func compute(network: SKApolloniusPoreNetwork, probeRadius: Double) -> SKChannelAnalysis
  {
    return from(poreComponents(network: network, probeRadius: probeRadius))
  }
}

private func poreComponents(network: SKApolloniusPoreNetwork, probeRadius: Double) -> [SKPoreComponent]
{
  var pores: [SKPoreComponent] = []
  let numberOfNodes = network.nodes.count
  if numberOfNodes == 0 { return pores }
  
  var nodeActive = Array(repeating: false, count: numberOfNodes)
  for i in 0..<numberOfNodes { nodeActive[i] = network.nodes[i].radius > probeRadius }
  
  var adjacency: [[(Int, SIMD3<Int32>)]] = Array(repeating: [], count: numberOfNodes)
  for edge in network.edges
  {
    if edge.radius <= probeRadius { continue }
    if !nodeActive[edge.from] || !nodeActive[edge.to] { continue }
    adjacency[edge.from].append((edge.to, edge.delta))
  }
  
  var visited = Array(repeating: false, count: numberOfNodes)
  
  for start in 0..<numberOfNodes
  {
    if !nodeActive[start] || visited[start] { continue }
    
    var displacement: [Int: SIMD3<Int32>] = [start: SIMD3<Int32>()]
    var componentNodes: [Int] = []
    var loopVectors: [SIMD3<Int32>] = []
    var stack: [(Int, SIMD3<Int32>)] = [(start, SIMD3<Int32>())]
    visited[start] = true
    
    while let (node, disp) = stack.popLast()
    {
      componentNodes.append(node)
      for (neighbor, delta) in adjacency[node]
      {
        let newDisp = latticeAdd(disp, delta)
        if let previous = displacement[neighbor]
        {
          let loop = latticeSub(newDisp, previous)
          if loop != SIMD3<Int32>() { loopVectors.append(loop) }
        }
        else
        {
          displacement[neighbor] = newDisp
          visited[neighbor] = true
          stack.append((neighbor, newDisp))
        }
      }
    }
    
    let dimensionality = latticeVectorRank(loopVectors)
    pores.append(SKPoreComponent(isChannel: dimensionality > 0,
                                 dimensionality: dimensionality,
                                 nodeIndices: componentNodes))
  }
  return pores
}

// MARK: - Windows

/// The shape of the narrowest window of a channel: what Df says with one number, said with two.
/// The plane through the bottleneck perpendicular to the passage cuts each atom that reaches it
/// in a disc; the free widths are the shortest and longest free chords through the bottleneck.
private struct SKPoreWindow
{
  var measured: Bool = false
  var clipped: Bool = false
  var boundingAtoms: Int = 0
  var smallestFreeWidth: Double = 0.0
  var largestFreeWidth: Double = 0.0
  
  static func measure(network: SKApolloniusPoreNetwork, position: SIMD3<Double>, normal: SIMD3<Double>) -> SKPoreWindow
  {
    var window = SKPoreWindow()
    let normalLength = simd_length(normal)
    if normalLength <= 0.0 || network.atomPositionsFractional.isEmpty { return window }
    let axisNormal = normal / normalLength
    
    let helper: SIMD3<Double>
    if abs(axisNormal.x) <= abs(axisNormal.y) && abs(axisNormal.x) <= abs(axisNormal.z)
    {
      helper = SIMD3<Double>(1.0, 0.0, 0.0)
    }
    else if abs(axisNormal.y) <= abs(axisNormal.z)
    {
      helper = SIMD3<Double>(0.0, 1.0, 0.0)
    }
    else
    {
      helper = SIMD3<Double>(0.0, 0.0, 1.0)
    }
    var firstAxis = simd_cross(axisNormal, helper)
    firstAxis = firstAxis / simd_length(firstAxis)
    let secondAxis = simd_cross(axisNormal, firstAxis)
    
    let cell = network.unitCell
    let inverseCell = cell.inverse
    let radii = network.atomRadii
    let widths = perpendicularWidths(of: cell)
    let maximumRadius = radii.max() ?? 0.0
    let positionFractional = inverseCell * position
    
    func forEachAtomImage(searchRadius: Double, visit: (Int, SIMD3<Double>) -> Void)
    {
      let extent = searchRadius + maximumRadius
      let span = SIMD3<Int32>(Int32(ceil(extent / widths.x)) + 1,
                              Int32(ceil(extent / widths.y)) + 1,
                              Int32(ceil(extent / widths.z)) + 1)
      for j in 0..<network.atomPositionsFractional.count
      {
        let relative = network.atomPositionsFractional[j] - positionFractional
        let nearest = SIMD3<Double>(relative.x - round(relative.x),
                                    relative.y - round(relative.y),
                                    relative.z - round(relative.z))
        var ox = -span.x
        while ox <= span.x
        {
          var oy = -span.y
          while oy <= span.y
          {
            var oz = -span.z
            while oz <= span.z
            {
              let delta = cell * SIMD3<Double>(nearest.x + Double(ox), nearest.y + Double(oy), nearest.z + Double(oz))
              if simd_length(delta) - radii[j] <= searchRadius { visit(j, delta) }
              oz += 1
            }
            oy += 1
          }
          ox += 1
        }
      }
    }
    
    let cellReach = 0.5 * min(widths.x, widths.y, widths.z)
    var clearance = Double.greatestFiniteMagnitude
    var searchRadius = cellReach
    while clearance == Double.greatestFiniteMagnitude && searchRadius < 64.0 * cellReach
    {
      forEachAtomImage(searchRadius: searchRadius) { j, delta in
        clearance = min(clearance, simd_length(delta) - radii[j])
      }
      searchRadius *= 2.0
    }
    if clearance == Double.greatestFiniteMagnitude { return window }
    if clearance <= 1.0e-9 { return window }
    
    let reach = max(cellReach, 3.0 * clearance)
    
    struct WindowDisc
    {
      var first: Double
      var second: Double
      var radius: Double
      var gap: Double
    }
    var discs: [WindowDisc] = []
    forEachAtomImage(searchRadius: reach) { j, delta in
      let standoff = simd_dot(delta, axisNormal)
      let squared = radii[j] * radii[j] - standoff * standoff
      if squared <= 0.0 { return }
      let disc = WindowDisc(first: simd_dot(delta, firstAxis),
                            second: simd_dot(delta, secondAxis),
                            radius: sqrt(squared),
                            gap: 0.0)
      var stored = disc
      stored.gap = stored.first * stored.first + stored.second * stored.second - squared
      if stored.gap <= 0.0 { return }
      if hypot(stored.first, stored.second) - stored.radius > reach { return }
      discs.append(stored)
    }
    
    let directionCount = 360
    var extent = Array(repeating: 0.0, count: directionCount)
    var bounds = Array(repeating: false, count: discs.count)
    for i in 0..<directionCount
    {
      let angle = 2.0 * Double.pi * Double(i) / Double(directionCount)
      let cosine = cos(angle)
      let sine = sin(angle)
      var nearest = reach
      var nearestDisc = discs.count
      for d in 0..<discs.count
      {
        let disc = discs[d]
        let along = cosine * disc.first + sine * disc.second
        if along <= 0.0 { continue }
        let discriminant = along * along - disc.gap
        if discriminant <= 0.0 { continue }
        let distance = along - sqrt(discriminant)
        if distance < nearest
        {
          nearest = distance
          nearestDisc = d
        }
      }
      extent[i] = nearest
      if nearestDisc < discs.count
      {
        bounds[nearestDisc] = true
      }
      else
      {
        window.clipped = true
      }
    }
    window.boundingAtoms = bounds.filter { $0 }.count
    
    window.smallestFreeWidth = Double.greatestFiniteMagnitude
    for i in 0..<(directionCount / 2)
    {
      let width = extent[i] + extent[i + directionCount / 2]
      window.smallestFreeWidth = min(window.smallestFreeWidth, width)
      window.largestFreeWidth = max(window.largestFreeWidth, width)
    }
    window.measured = true
    return window
  }
  
  /// Prefer a plane that is actually a ring of atoms. The arc tangent is the passage direction,
  /// but at a channel crossing (MFI) that plane cuts along the other channel and the long
  /// chord is not an atlas aperture. Oxygens whose clearance is only a little larger than
  /// the bottleneck are the ring; their best-fit plane is the one the tables quote.
  static func measureBest(network: SKApolloniusPoreNetwork, position: SIMD3<Double>, normal: SIMD3<Double>, bottleneckRadius: Double) -> SKPoreWindow
  {
    var candidates: [SKPoreWindow] = []
    let alongPassage = measure(network: network, position: position, normal: normal)
    if alongPassage.measured { candidates.append(alongPassage) }
    let ringAtoms = nearbyOxygenDeltas(network: network, position: position, maxClearance: bottleneckRadius + 0.85)
    if (8...14).contains(ringAtoms.count), let ringNormal = planeNormal(of: ringAtoms)
    {
      let inRing = measure(network: network, position: position, normal: ringNormal)
      if inRing.measured { candidates.append(inRing) }
    }
    for count in [8, 10, 12]
    {
      if let ringNormal = ringPlaneNormal(network: network, position: position, atomCount: count)
      {
        let inRing = measure(network: network, position: position, normal: ringNormal)
        if inRing.measured { candidates.append(inRing) }
      }
    }
    return candidates.min(by: { atlasScore($0) < atlasScore($1) }) ?? alongPassage
  }
  
  /// Lower is a better match to a crystallographic window: a closed ring, about ten
  /// bounding atoms, and only a modest difference between the two free widths.
  static func atlasScore(_ window: SKPoreWindow) -> Double
  {
    if !window.measured { return 1.0e9 }
    let span = window.largestFreeWidth - window.smallestFreeWidth
    let aspect = window.smallestFreeWidth > 1.0e-6 ? window.largestFreeWidth / window.smallestFreeWidth : 10.0
    let ringPenalty = (8...12).contains(window.boundingAtoms) ? 0.0 : 2.0 + Double(abs(window.boundingAtoms - 10))
    return (window.clipped ? 20.0 : 0.0) + span + 2.0 * max(0.0, aspect - 1.25) + ringPenalty
  }
  
  static func freeSphere(network: SKApolloniusPoreNetwork) -> SKPoreWindow
  {
    let path = widestPercolatingPath(network: network, nodes: Array(0..<network.nodes.count))
    guard path.percolates, path.limitingEdge < network.edges.count else { return SKPoreWindow() }
    let edge = network.edges[path.limitingEdge]
    guard edge.hasBottleneckGeometry else { return SKPoreWindow() }
    return measureBest(network: network, position: edge.bottleneckPosition, normal: edge.bottleneckDirection, bottleneckRadius: edge.radius)
  }
}

/// IZA window sizes of a 4-connected T–O framework: opposite oxygen spans of the
/// rings that open onto percolating channels, minus the two oxygen radii. One pair
/// per distinct aperture. Frameworks that are not tetrahedral nets (a cubic lattice
/// of one atom, a MOF, …) fall back to the free-chord measurement at the Df saddle.
extension SKPoreWindowSizes
{
  fileprivate static func compute(network: SKApolloniusPoreNetwork) -> SKPoreWindowSizes
  {
    if network.nodes.isEmpty || network.edges.isEmpty { return SKPoreWindowSizes() }
    
    let rings = frameworkWindowRings(network: network)
    var entries: [SKPoreWindow] = []
    if !rings.isEmpty
    {
      entries = directionWindows(rings: rings, network: network)
    }
    if entries.isEmpty
    {
      entries = latticeLoopWindows(network: network)
    }
    entries.sort { $0.smallestFreeWidth < $1.smallestFreeWidth }
    
    var sizes = SKPoreWindowSizes()
    for i in 0..<min(3, entries.count)
    {
      sizes.sizes[i] = SIMD2<Double>(entries[i].smallestFreeWidth, entries[i].largestFreeWidth)
      sizes.ringAtomCounts[i] = entries[i].boundingAtoms
    }
    return sizes
  }
}

/// Oxygens (or other sized atoms) whose nearest image is no farther than `maxClearance`
/// from `position`. A 10-ring's members all sit just outside the inscribed sphere.
private func nearbyOxygenDeltas(network: SKApolloniusPoreNetwork, position: SIMD3<Double>, maxClearance: Double) -> [SIMD3<Double>]
{
  let cell = network.unitCell
  let inverseCell = cell.inverse
  let positionFractional = inverseCell * position
  var deltas: [SIMD3<Double>] = []
  for j in 0..<network.atomPositionsFractional.count
  {
    let radius = network.atomRadii[j]
    if radius <= 0.0 { continue }
    let relative = network.atomPositionsFractional[j] - positionFractional
    let wrapped = SIMD3<Double>(relative.x - round(relative.x),
                                relative.y - round(relative.y),
                                relative.z - round(relative.z))
    let delta = cell * wrapped
    if simd_length(delta) - radius <= maxClearance { deltas.append(delta) }
  }
  return deltas
}

private func oxygenDeltasSorted(network: SKApolloniusPoreNetwork, position: SIMD3<Double>) -> [SIMD3<Double>]
{
  let cell = network.unitCell
  let inverseCell = cell.inverse
  let positionFractional = inverseCell * position
  var nearest: [(clearance: Double, delta: SIMD3<Double>)] = []
  for j in 0..<network.atomPositionsFractional.count
  {
    let radius = network.atomRadii[j]
    if radius <= 0.0 { continue }
    let relative = network.atomPositionsFractional[j] - positionFractional
    let wrapped = SIMD3<Double>(relative.x - round(relative.x),
                                relative.y - round(relative.y),
                                relative.z - round(relative.z))
    let delta = cell * wrapped
    nearest.append((simd_length(delta) - radius, delta))
  }
  nearest.sort { $0.clearance < $1.clearance }
  return nearest.map { $0.delta }
}

/// Best-fit plane of the `atomCount` atoms with the smallest clearance at `position`.
private func ringPlaneNormal(network: SKApolloniusPoreNetwork, position: SIMD3<Double>, atomCount: Int = 10) -> SIMD3<Double>?
{
  let deltas = oxygenDeltasSorted(network: network, position: position)
  guard deltas.count >= 3 else { return nil }
  return planeNormal(of: Array(deltas.prefix(min(atomCount, deltas.count))))
}

private func planeNormal(of points: [SIMD3<Double>]) -> SIMD3<Double>?
{
  guard points.count >= 3 else { return nil }
  var centroid = SIMD3<Double>()
  for point in points { centroid += point }
  centroid /= Double(points.count)
  var xx = 0.0, yy = 0.0, zz = 0.0, xy = 0.0, xz = 0.0, yz = 0.0
  for point in points
  {
    let d = point - centroid
    xx += d.x * d.x
    yy += d.y * d.y
    zz += d.z * d.z
    xy += d.x * d.y
    xz += d.x * d.z
    yz += d.y * d.z
  }
  return smallestEigenvector(xx, yy, zz, xy, xz, yz)
}

/// One even T–O ring of a tetrahedral framework, with IZA opposite-oxygen free diameters.
private struct SKFrameworkRing
{
  var atomCount: Int
  var centroid: SIMD3<Double>
  var normal: SIMD3<Double>
  var inscribedRadius: Double
  var smallestFreeWidth: Double
  var largestFreeWidth: Double
}

/// IZA apertures at the bottlenecks of the percolating void network. Every zeolite
/// window is such a bottleneck lined by one T–O ring (6- through 18-rings). The
/// atlas pair is the smallest and largest opposite-oxygen free diameter of that
/// ring, using the snapshot radii (1.35 Å for Zeo-Atlas oxygen).
private func frameworkWindowRings(network: SKApolloniusPoreNetwork) -> [SKFrameworkRing]
{
  let path = widestPercolatingPath(network: network, nodes: Array(0..<network.nodes.count))
  guard path.percolates, path.limitingEdge < network.edges.count else { return [] }
  let freeRadius = network.edges[path.limitingEdge].radius
  let freeDiameter = 2.0 * freeRadius
  let cell = network.unitCell
  let inverseCell = cell.inverse
  var sites: [(position: SIMD3<Double>, radius: Double, direction: SIMD3<Double>)] = []
  for edge in network.edges
  {
    if !edge.hasBottleneckGeometry { continue }
    if edge.radius < 0.65 * freeRadius { continue }
    var passage = edge.bottleneckDirection
    let passageLength = simd_length(passage)
    if passageLength > 1.0e-12 { passage /= passageLength }
    let isDuplicate = sites.contains { existing in
      let relative = inverseCell * (edge.bottleneckPosition - existing.position)
      let wrapped = cell * SIMD3<Double>(relative.x - round(relative.x),
                                         relative.y - round(relative.y),
                                         relative.z - round(relative.z))
      return simd_length(wrapped) < 0.40 && abs(simd_dot(existing.direction, passage)) > 0.85
    }
    if isDuplicate { continue }
    sites.append((edge.bottleneckPosition, edge.radius, passage))
  }
  var rings: [SKFrameworkRing] = []
  for site in sites
  {
    rings.append(contentsOf: localIZARings(at: site.position,
                                          inscribed: site.radius,
                                          passage: site.direction,
                                          network: network))
  }
  return rings.filter { $0.smallestFreeWidth >= 0.70 * freeDiameter }
}

private struct SKLocalBond
{
  var other: Int
  var delta: SIMD3<Int32>
}

private struct SKLocalTTEdge
{
  var to: Int
  var delta: SIMD3<Int32>
  var oxygen: Int
  var oxygenDelta: SIMD3<Int32>
}

/// T–O rings that line `position`. T and O come from coordination in the
/// distance bond graph (4-connected T, 2-connected O), not from atom radii:
/// Zeo++ and UFF give silicon a radius, so a radius-based split misses every
/// T-site and falls back to a free-chord atom count that is not a ring size.
private func localIZARings(at position: SIMD3<Double>,
                           inscribed: Double,
                           passage: SIMD3<Double>,
                           network: SKApolloniusPoreNetwork) -> [SKFrameworkRing]
{
  let cell = network.unitCell
  let inverseCell = cell.inverse
  let positionFractional = inverseCell * position
  let count = network.atomPositionsFractional.count
  
  // Neighbourhood of the bottleneck: every atom whose centre is close enough that
  // it can belong to the lining ring for any of the common force-field radii.
  var nearAtoms: [Int] = []
  let centreReach = inscribed + 3.6
  for j in 0..<count
  {
    let relative = network.atomPositionsFractional[j] - positionFractional
    let nearest = SIMD3<Double>(relative.x - round(relative.x),
                                relative.y - round(relative.y),
                                relative.z - round(relative.z))
    if simd_length(cell * nearest) > centreReach { continue }
    nearAtoms.append(j)
  }
  if nearAtoms.count < 12 { return [] }
  
  var bonds: [Int: [SKLocalBond]] = [:]
  for i in 0..<nearAtoms.count
  {
    let a = nearAtoms[i]
    for j in (i + 1)..<nearAtoms.count
    {
      let b = nearAtoms[j]
      let relative = network.atomPositionsFractional[b] - network.atomPositionsFractional[a]
      let nearest = SIMD3<Double>(relative.x - round(relative.x),
                                  relative.y - round(relative.y),
                                  relative.z - round(relative.z))
      let distance = simd_length(cell * nearest)
      if distance < 1.30 || distance > 2.10 { continue }
      let lattice = SIMD3<Int32>(Int32(round(relative.x)), Int32(round(relative.y)), Int32(round(relative.z)))
      bonds[a, default: []].append(SKLocalBond(other: b, delta: lattice))
      bonds[b, default: []].append(SKLocalBond(other: a, delta: latticeNegate(lattice)))
    }
  }
  
  var tAtoms: [Int] = []
  var oAtoms: [Int] = []
  for atom in nearAtoms
  {
    let coordination = bonds[atom]?.count ?? 0
    if coordination == 4 || coordination == 3 { tAtoms.append(atom) }
    else if coordination == 2 { oAtoms.append(atom) }
  }
  tAtoms.sort()
  if tAtoms.count < 6 || oAtoms.count < 6 { return [] }
  
  // Oxygens that line the passage: clearance close to the bottleneck radius.
  var liningOxygen: [Int] = []
  for oxygen in oAtoms
  {
    let radius = max(network.atomRadii[oxygen], 0.0)
    let relative = network.atomPositionsFractional[oxygen] - positionFractional
    let nearest = SIMD3<Double>(relative.x - round(relative.x),
                                relative.y - round(relative.y),
                                relative.z - round(relative.z))
    let clearance = simd_length(cell * nearest) - radius
    if clearance < inscribed - 0.45 || clearance > inscribed + 2.20 { continue }
    liningOxygen.append(oxygen)
  }
  if liningOxygen.count < 6 || liningOxygen.count > 28 { return [] }
  let oxygenSet = Set(liningOxygen)
  let tSet = Set(tAtoms)
  
  var adjacency: [Int: [SKLocalTTEdge]] = [:]
  for t in tAtoms
  {
    for bond in bonds[t] ?? [] where oxygenSet.contains(bond.other)
    {
      let oxygen = bond.other
      for second in bonds[oxygen] ?? []
      {
        if second.other == t { continue }
        if !tSet.contains(second.other) { continue }
        adjacency[t, default: []].append(SKLocalTTEdge(to: second.other,
                                                       delta: latticeAdd(bond.delta, second.delta),
                                                       oxygen: oxygen,
                                                       oxygenDelta: bond.delta))
      }
    }
  }
  
  var bestByOrientation: [SKFrameworkRing] = []
  var seen = Set<String>()
  
  for start in tAtoms
  {
    var pathT: [Int] = [start]
    var pathLat: [SIMD3<Int32>] = [SIMD3<Int32>()]
    var pathO: [Int] = []
    var pathOLat: [SIMD3<Int32>] = []
    
    func visit()
    {
      let last = pathT[pathT.count - 1]
      let lastLat = pathLat[pathLat.count - 1]
      let n = pathT.count
      if n >= 6 && n <= 14 && n % 2 == 0
      {
        for edge in adjacency[last] ?? [] where edge.to == start
        {
          if latticeAdd(lastLat, edge.delta) != SIMD3<Int32>() { continue }
          let key = pathT.sorted().map(String.init).joined(separator: ",")
          if seen.contains(key) { continue }
          var oxygens = pathO
          var oxygenLattices = pathOLat
          oxygens.append(edge.oxygen)
          oxygenLattices.append(latticeAdd(lastLat, edge.oxygenDelta))
          seen.insert(key)
          guard let ring = measureLocalRing(network: network,
                                            oxygens: oxygens,
                                            oxygenLattices: oxygenLattices,
                                            inscribed: inscribed,
                                            cell: cell) else { continue }
          let facing = abs(simd_dot(ring.normal, passage))
          var window = SKPoreWindow()
          window.measured = true
          window.boundingAtoms = ring.atomCount
          window.smallestFreeWidth = ring.smallestFreeWidth
          window.largestFreeWidth = ring.largestFreeWidth
          let score = SKPoreWindow.atlasScore(window)
            + 0.15 * simd_length(wrappedDelta(ring.centroid - position, cell: cell, inverse: inverseCell))
            + 1.5 * (1.0 - facing)
            + 0.55 * Double(max(0, ring.atomCount - 10))
            + 0.25 * abs(ring.inscribedRadius - inscribed)
          if let match = bestByOrientation.firstIndex(where: { abs(simd_dot($0.normal, ring.normal)) > 0.80 })
          {
            let currentFacing = abs(simd_dot(bestByOrientation[match].normal, passage))
            var currentWindow = SKPoreWindow()
            currentWindow.measured = true
            currentWindow.boundingAtoms = bestByOrientation[match].atomCount
            currentWindow.smallestFreeWidth = bestByOrientation[match].smallestFreeWidth
            currentWindow.largestFreeWidth = bestByOrientation[match].largestFreeWidth
            let currentScore = SKPoreWindow.atlasScore(currentWindow)
              + 0.15 * simd_length(wrappedDelta(bestByOrientation[match].centroid - position, cell: cell, inverse: inverseCell))
              + 1.5 * (1.0 - currentFacing)
              + 0.55 * Double(max(0, bestByOrientation[match].atomCount - 10))
              + 0.25 * abs(bestByOrientation[match].inscribedRadius - inscribed)
            if score < currentScore { bestByOrientation[match] = ring }
          }
          else
          {
            bestByOrientation.append(ring)
          }
        }
      }
      if n == 14 { return }
      let used = Set(pathT)
      for edge in adjacency[last] ?? []
      {
        if used.contains(edge.to) || edge.to < start { continue }
        pathT.append(edge.to)
        pathLat.append(latticeAdd(lastLat, edge.delta))
        pathO.append(edge.oxygen)
        pathOLat.append(latticeAdd(lastLat, edge.oxygenDelta))
        visit()
        pathT.removeLast()
        pathLat.removeLast()
        pathO.removeLast()
        pathOLat.removeLast()
      }
    }
    visit()
  }
  return bestByOrientation
}

private func measureLocalRing(network: SKApolloniusPoreNetwork,
                              oxygens: [Int],
                              oxygenLattices: [SIMD3<Int32>],
                              inscribed: Double,
                              cell: double3x3) -> SKFrameworkRing?
{
  let n = oxygens.count
  guard n >= 6, n == oxygenLattices.count else { return nil }
  var points: [SIMD3<Double>] = []
  var radii: [Double] = []
  for i in 0..<n
  {
    let lattice = SIMD3<Double>(Double(oxygenLattices[i].x),
                                Double(oxygenLattices[i].y),
                                Double(oxygenLattices[i].z))
    points.append(cell * (network.atomPositionsFractional[oxygens[i]] + lattice))
    radii.append(network.atomRadii[oxygens[i]])
  }
  var centroid = SIMD3<Double>()
  for point in points { centroid += point }
  centroid /= Double(n)
  
  var ringInscribed = Double.greatestFiniteMagnitude
  for i in 0..<n
  {
    ringInscribed = min(ringInscribed, simd_length(points[i] - centroid) - radii[i])
  }
  if ringInscribed < 0.25 || abs(ringInscribed - inscribed) > 1.45 { return nil }
  
  guard let normal = planeNormal(of: points) else { return nil }
  var planeError = 0.0
  for point in points
  {
    let d = simd_dot(point - centroid, normal)
    planeError += d * d
  }
  if sqrt(planeError / Double(n)) > 0.85 { return nil }
  
  let half = n / 2
  var widths: [Double] = []
  for i in 0..<half
  {
    let p = points[i] - centroid
    let q = points[i + half] - centroid
    let chord = q - p
    let chord2 = simd_dot(chord, chord)
    if chord2 < 1.0 { continue }
    let t = -simd_dot(p, chord) / chord2
    if t < 0.28 || t > 0.72 { continue }
    if simd_length(p + t * chord) > 1.35 { continue }
    let width = sqrt(chord2) - radii[i] - radii[i + half]
    if width > 0.5 { widths.append(width) }
  }
  guard widths.count >= max(2, half - 1) else { return nil }
  guard let smallest = widths.min(), let largest = widths.max() else { return nil }
  if smallest < 1.0 || largest > 16.0 || largest / smallest > 2.4 { return nil }
  
  return SKFrameworkRing(atomCount: n,
                         centroid: centroid,
                         normal: normal,
                         inscribedRadius: ringInscribed,
                         smallestFreeWidth: smallest,
                         largestFreeWidth: largest)
}

private func wrappedDelta(_ delta: SIMD3<Double>, cell: double3x3, inverse: double3x3) -> SIMD3<Double>
{
  let fractional = inverse * delta
  return cell * SIMD3<Double>(fractional.x - round(fractional.x),
                              fractional.y - round(fractional.y),
                              fractional.z - round(fractional.z))
}

/// One window per distinct channel direction. A 3D net can have three independent
/// lattice loops and still only two apertures (MFI: two 10-rings whose intersection
/// supplies the third dimension). A later loop that lands on a ring of the same
/// orientation, or the same size, is that intersection, not a new window.
private func directionWindows(rings: [SKFrameworkRing], network: SKApolloniusPoreNetwork) -> [SKPoreWindow]
{
  let cell = network.unitCell
  let inverseCell = cell.inverse
  var kept: [(window: SKPoreWindow, normal: SIMD3<Double>)] = []
  var order: [Int] = Array(0..<network.edges.count)
  order.sort { network.edges[$0].radius > network.edges[$1].radius }
  var unionFind = SKPeriodicUnionFind(count: network.nodes.count)
  var loopVectors: [SIMD3<Int32>] = []
  
  for index in order
  {
    let edge = network.edges[index]
    let (rootFrom, accFrom) = unionFind.find(edge.from)
    let (rootTo, accTo) = unionFind.find(edge.to)
    if rootFrom == rootTo
    {
      let net = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
      if net == SIMD3<Int32>() { continue }
      var trial = loopVectors
      trial.append(net)
      if latticeVectorRank(trial) <= loopVectors.count { continue }
      guard edge.hasBottleneckGeometry else { continue }
      var channel = cell * SIMD3<Double>(Double(net.x), Double(net.y), Double(net.z))
      let channelLength = simd_length(channel)
      if channelLength <= 1.0e-12 { continue }
      channel /= channelLength
      var best: SKFrameworkRing?
      var bestScore = Double.greatestFiniteMagnitude
      for ring in rings
      {
        let align = abs(simd_dot(ring.normal, channel))
        let relative = inverseCell * (edge.bottleneckPosition - ring.centroid)
        let wrapped = cell * SIMD3<Double>(relative.x - round(relative.x),
                                           relative.y - round(relative.y),
                                           relative.z - round(relative.z))
        let distance = simd_length(wrapped)
        // Prefer a ring that faces the channel; fall back to a nearby ring of any
        // orientation so a force field that moves the bottleneck off-centre still
        // reports every distinct aperture.
        let score = (align > 0.40 ? 0.0 : 4.0) + distance + 0.2 * Double(max(0, ring.atomCount - 10))
        if score < bestScore
        {
          bestScore = score
          best = ring
        }
      }
      guard let ring = best, bestScore < 8.0 else { continue }
      loopVectors.append(net)
      
      if let match = kept.firstIndex(where: { sameChannelAperture($0.window, $0.normal, ring) })
      {
        if ring.smallestFreeWidth < kept[match].window.smallestFreeWidth
        {
          kept[match] = (windowFromRing(ring), ring.normal)
        }
        continue
      }
      
      kept.append((windowFromRing(ring), ring.normal))
      if kept.count == 3 { break }
    }
    else
    {
      unionFind.parent[rootTo] = rootFrom
      unionFind.offset[rootTo] = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
    }
  }
  return kept.map { $0.window }
}

private func windowFromRing(_ ring: SKFrameworkRing) -> SKPoreWindow
{
  var window = SKPoreWindow()
  window.measured = true
  window.boundingAtoms = ring.atomCount
  window.smallestFreeWidth = ring.smallestFreeWidth
  window.largestFreeWidth = ring.largestFreeWidth
  return window
}

private func sameChannelAperture(_ window: SKPoreWindow, _ normal: SIMD3<Double>, _ ring: SKFrameworkRing) -> Bool
{
  if abs(simd_dot(normal, ring.normal)) > 0.80 { return true }
  return window.boundingAtoms == ring.atomCount &&
    abs(window.smallestFreeWidth - ring.smallestFreeWidth) < 0.10 &&
    abs(window.largestFreeWidth - ring.largestFreeWidth) < 0.10
}

/// Non-zeolite fallback: one window per independent percolating lattice loop, measured
/// as free chords through that loop's bottleneck.
private func latticeLoopWindows(network: SKApolloniusPoreNetwork) -> [SKPoreWindow]
{
  var windows: [SKPoreWindow] = []
  var order: [Int] = Array(0..<network.edges.count)
  order.sort { network.edges[$0].radius > network.edges[$1].radius }
  var unionFind = SKPeriodicUnionFind(count: network.nodes.count)
  var loopVectors: [SIMD3<Int32>] = []
  
  for index in order
  {
    let edge = network.edges[index]
    let (rootFrom, accFrom) = unionFind.find(edge.from)
    let (rootTo, accTo) = unionFind.find(edge.to)
    if rootFrom == rootTo
    {
      let net = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
      if net == SIMD3<Int32>() { continue }
      var trial = loopVectors
      trial.append(net)
      if latticeVectorRank(trial) <= loopVectors.count { continue }
      guard edge.hasBottleneckGeometry else { continue }
      var window = SKPoreWindow.measureBest(network: network,
                                            position: edge.bottleneckPosition,
                                            normal: edge.bottleneckDirection,
                                            bottleneckRadius: edge.radius)
      guard window.measured else { continue }
      // Free-chord discs are not crystallographic rings; leave the N-ring field empty.
      window.boundingAtoms = 0
      loopVectors.append(net)
      windows.append(window)
      if windows.count == 3 { break }
    }
    else
    {
      unionFind.parent[rootTo] = rootFrom
      unionFind.offset[rootTo] = latticeSub(latticeAdd(accFrom, edge.delta), accTo)
    }
  }
  if windows.isEmpty
  {
    var window = SKPoreWindow.freeSphere(network: network)
    if window.measured
    {
      window.boundingAtoms = 0
      windows.append(window)
    }
  }
  return windows
}

/// Unit eigenvector of the smallest eigenvalue of a 3×3 symmetric matrix (Jacobi).
private func smallestEigenvector(_ xx: Double, _ yy: Double, _ zz: Double,
                                 _ xy: Double, _ xz: Double, _ yz: Double) -> SIMD3<Double>?
{
  var a: [[Double]] = [[xx, xy, xz], [xy, yy, yz], [xz, yz, zz]]
  var v: [[Double]] = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
  for _ in 0..<16
  {
    var p = 0, q = 1
    var maxOff = abs(a[0][1])
    if abs(a[0][2]) > maxOff { p = 0; q = 2; maxOff = abs(a[0][2]) }
    if abs(a[1][2]) > maxOff { p = 1; q = 2; maxOff = abs(a[1][2]) }
    if maxOff < 1.0e-14 { break }
    let app = a[p][p], aqq = a[q][q], apq = a[p][q]
    let tau = (aqq - app) / (2.0 * apq)
    let t = (tau >= 0.0 ? 1.0 : -1.0) / (abs(tau) + sqrt(1.0 + tau * tau))
    let c = 1.0 / sqrt(1.0 + t * t)
    let s = t * c
    for i in 0..<3 where i != p && i != q
    {
      let aip = a[i][p], aiq = a[i][q]
      a[i][p] = c * aip - s * aiq
      a[p][i] = a[i][p]
      a[i][q] = s * aip + c * aiq
      a[q][i] = a[i][q]
    }
    a[p][p] = c * c * app - 2.0 * s * c * apq + s * s * aqq
    a[q][q] = s * s * app + 2.0 * s * c * apq + c * c * aqq
    a[p][q] = 0.0
    a[q][p] = 0.0
    for i in 0..<3
    {
      let vip = v[i][p], viq = v[i][q]
      v[i][p] = c * vip - s * viq
      v[i][q] = s * vip + c * viq
    }
  }
  var best = 0
  if a[1][1] < a[best][best] { best = 1 }
  if a[2][2] < a[best][best] { best = 2 }
  let normal = SIMD3<Double>(v[0][best], v[1][best], v[2][best])
  let length = simd_length(normal)
  if length <= 1.0e-10 { return nil }
  return normal / length
}

private func perpendicularWidths(of cell: double3x3) -> SIMD3<Double>
{
  let a = cell[0]
  let b = cell[1]
  let c = cell[2]
  let volume = abs(simd_dot(a, simd_cross(b, c)))
  return SIMD3<Double>(volume / simd_length(simd_cross(b, c)),
                       volume / simd_length(simd_cross(c, a)),
                       volume / simd_length(simd_cross(a, b)))
}

/// Rank (0..3) of a set of integer lattice vectors, i.e. the dimensionality they span.
/// In integers throughout: a vector is off a line when its cross product with that line does
/// not vanish, and off a plane when its product with the plane's normal does not.
func SKLatticeVectorRank(_ vectors: [SIMD3<Int32>]) -> Int
{
  return latticeVectorRank(vectors)
}

private func latticeAdd(_ a: SIMD3<Int32>, _ b: SIMD3<Int32>) -> SIMD3<Int32>
{
  return SIMD3<Int32>(a.x &+ b.x, a.y &+ b.y, a.z &+ b.z)
}

private func latticeSub(_ a: SIMD3<Int32>, _ b: SIMD3<Int32>) -> SIMD3<Int32>
{
  return SIMD3<Int32>(a.x &- b.x, a.y &- b.y, a.z &- b.z)
}

private func latticeNegate(_ a: SIMD3<Int32>) -> SIMD3<Int32>
{
  return SIMD3<Int32>(0 &- a.x, 0 &- a.y, 0 &- a.z)
}

private func latticeVectorRank(_ vectors: [SIMD3<Int32>]) -> Int
{
  typealias Vector = (Int64, Int64, Int64)
  func cross(_ u: Vector, _ v: Vector) -> Vector
  {
    return (u.1 * v.2 - u.2 * v.1, u.2 * v.0 - u.0 * v.2, u.0 * v.1 - u.1 * v.0)
  }
  func nonZero(_ u: Vector) -> Bool
  {
    return u.0 != 0 || u.1 != 0 || u.2 != 0
  }
  
  var along: Vector = (0, 0, 0)
  var normal: Vector = (0, 0, 0)
  var rank = 0
  for v in vectors
  {
    let row: Vector = (Int64(v.x), Int64(v.y), Int64(v.z))
    if !nonZero(row) { continue }
    if rank == 0
    {
      along = row
      rank = 1
    }
    else if rank == 1
    {
      let off = cross(along, row)
      if nonZero(off)
      {
        normal = off
        rank = 2
      }
    }
    else if normal.0 * row.0 + normal.1 * row.1 + normal.2 * row.2 != 0
    {
      return 3
    }
  }
  return rank
}
