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
import MathKit

// The Apollonius diagram (additively weighted Voronoi diagram) of a periodic set of spheres.
//
// Space is divided by the additively weighted distance, the clearance
//
//     d_i(x) = |x - x_i| - r_i,
//
// so the cell of site i is the set of points that a probe can reach more freely from i than from
// any other site. This differs fundamentally from the radical (power) diagram in SKVoronoi,
// which uses |x - x_i|² - r_i². The power distance is what makes the radical diagram cheap: its
// bisectors are planes, so cells are convex polyhedra. The clearance bisector between two spheres
// of unequal radius is instead one sheet of a hyperboloid of revolution about the line joining
// them, degenerating to a plane only when the radii are equal. Apollonius cells are therefore
// bounded by curved patches, are star shaped about their site but not convex, and may be empty
// when one sphere is engulfed by another.
//
// The clearance is the quantity that actually governs whether a probe fits, so this diagram, and
// not the radical one, is what pore geometry should be read from. The radical diagram agrees with
// it exactly when all radii are equal and drifts from it as the radii spread.
//
// Representation. Vertices are points equidistant in clearance from four sites, which is to say
// centres of spheres tangent to and outside all four; this is the classical Apollonius problem and
// has a closed-form solution. Edges and faces are curved and are stored implicitly, by the sites
// whose sheets meet along them, rather than as sampled geometry: an edge is an arc of the trisector
// curve of three sites, and a face is a patch of the bisector sheet of two sites. That keeps the
// representation exact. Sampled positions along an edge can be recovered from its defining sites.
//
// Degenerate input. Four sites is the general case but not the only one: a sphere may touch five or
// more at once, and then all of them meet at that point. It is one vertex of the diagram, of degree
// higher than four, and it is held as one, carrying the whole cotangent set; see SKApolloniusVertex.
// Since the tangency of each quadruple drawn from such a set is satisfied, the vertex is constructed
// once per quadruple, and the copies are gathered afterwards. This costs nothing on a generic input,
// where no two vertices coincide and every set has four members, and it means the complex closes on a
// degenerate one instead of dissolving into a cluster of coincident vertices that pair with nothing.
//
// Robustness. Every vertex reported is certified: its tangent sphere is checked against an exhaustive
// neighbourhood search and contains no site, so no reported vertex is spurious and no reported radius
// overstates the room available. Vertex geometry is therefore sound, and quantities read from vertices
// alone, such as the largest sphere that fits, are trustworthy.
//
// Two regions can be asked for, and the difference matters; see SKApolloniusRegion. A tangency
// solution of negative radius is a point equidistant in clearance from four sites that lies inside the
// spheres. It is a genuine vertex of the diagram as a partition of space, and it is no place a probe
// can be. Over `freeSpace` such solutions are dropped, which clips the complex against the boundary of
// the union of the spheres: an arc running into that boundary stops there rather than at a vertex, so
// Euler's formula and full valence everywhere do not hold and their failure is not a defect.
// `verification` keeps the two apart, counting clipped arcs as `truncatedTriples` and genuine failures
// to pair as `unpairedTriples`. Over `entireSpace` nothing is clipped and the complex closes exactly.
//
// Vertices are located completely in either case. Candidate quadruples are drawn from radical-diagram
// adjacency, which is a heuristic, and are then backed by an exhaustive subdivision sweep in the manner
// of Wang et al., which refines the cell until a box admits only four nearest sites and so cannot pass
// over a vertex.
//
// Ordering the vertices along a trisector, which is what decides the edges, is done from the shape of the
// trisector itself, and a trisector is always a plane conic. Subtracting the tangency conditions pairwise
// gives one equation per pair, linear in the position and in the clearance alike, so unless all three radii
// are alike the clearance can be eliminated between the two, leaving the plane the curve lies in. Within
// that plane the clearance is an affine function of position, so what is left of the tangency is a quadratic,
// and laying the first axis of the plane along the gradient of the clearance leaves it already in principal
// position, an ellipse where that gradient is smaller than one and the branch of a hyperbola where it is
// larger. Its own parameter then orders the vertices, and the direction an edge leaves a vertex in follows
// from the tangent there, both in closed form.
//
// Doing it this way is what keeps degenerate arrangements from being separate cases with thresholds between
// them, where an answer would turn on which side of a threshold an input fell:
//
//   - Collinear centres bisect in coaxial surfaces of revolution and meet in a circle standing at one
//     clearance the whole way round, which nothing ordered by clearance can order. Here it is just a
//     vanishing gradient, so the ellipse is a circle, ordered round by the same formula as any other.
//   - Nearly collinear centres are a small gradient and a nearly round ellipse, ordered by that same formula,
//     so how nearly collinear they are does not enter into it.
//   - Radii nearly alike are a large gradient and a nearly straight branch, again the same formula, tending
//     to the straight line it should.
//   - Radii exactly alike are the one arrangement standing apart, and only because there is then no
//     clearance to eliminate: both equations are planes in their own right and the trisector is the line they
//     cut in, which is the ordinary Voronoi edge. This is no exotic input, being the case in which the whole
//     diagram reduces to the ordinary Voronoi diagram, and it is an exact condition on the radii rather than
//     a judgement about how nearly equal they are.
//
// Collinear centres also defeat the tangency solve, because two of the solve's rows then have parallel
// coefficients of the centre and the centre cannot be written as a function of the radius. The solve takes
// the line of solutions from the null space of its rows instead, which exists either way and needs no such
// function, so that arrangement is not special there either.
//
// The cell may be triclinic. Nothing here assumes the lattice vectors are orthogonal: the neighbour search
// sizes its reach from the perpendicular widths of the cell rather than from lattice vector lengths, and
// the sweep measures a box by the sphere that encloses it, which is what a sheared box needs. A test
// rebuilds the same crystal in a sheared basis of the same lattice and requires the diagram to come out
// unchanged. Skewed cells do cost more, since the sweep subdivides boxes that are parallelepipeds in
// fractional space and a sheared one reaches much further than its volume suggests, so more of them carry
// enough sites to need splitting.
//
// Trisectors carrying no vertex. When no fourth site ever intrudes on a trisector, the curve is closed
// and has no vertex on it anywhere, so nothing that assembles a diagram from its vertices can reach it.
// Wang et al. discuss these in their Sections 4.2 and 5.5 and close the gap by replicating the offending
// site into four perturbed copies, which reintroduces vertices artificially. They are instead found here
// directly: the subdivision sweep already visits the neighbourhood of every trisector, so it records the
// triples it passes, and a triple left without vertices is then tested by sweeping the clearance along
// its trisector. That decides whether the curve is bounded, which is exactly the condition for it to be
// closed, and where it is bounded the same sweep traverses it and certifies that no site intrudes. Such
// a curve is reported as an edge with `isLoop` set and counted in `verification.vertexlessLoops`.
//
// A ring of this kind is not a topological defect to be removed: it is a ring-shaped channel, and its
// narrowest point is a bottleneck like any other edge's. What a ring does need is to be put on the right
// face. A ring is usually not a region of its own but a hole punched in a neighbouring one, where a third
// site bites into the middle of a bisector patch without reaching its rim, and recording it as a separate
// face instead both invents a face and leaves Euler's formula one over. Which of the two it is follows
// from the band of clearances the ring spans, since its own curve is the only place on the patch where the
// third site is equally near: see `ringBoundsOwnFace` in the implementation.
//
// There is no such thing as a bisector patch carrying no edge at all. A patch lies on one branch of a
// hyperboloid of revolution and so is topologically a plane, other sites dominate it far from the pair, so
// every region of it is bounded, and the boundary of a bounded region consists of points equally near some
// third site, which is an edge. A region that looks edgeless is one bounded solely by a ring, which is the
// case above. This is not left as an argument: a test sweeps every bisector patch in clearance and angle,
// counts the regions on the surface itself, and requires the diagram to hold exactly one face for each.
//
// Implementation notes
// --------------------
// Two tangency problems arise, and both collapse onto the same small linear system. Requiring a
// sphere of radius t centred at c to touch site i from outside gives |c - x_i| = r_i + t. Squaring
// yields |c|² - 2 c·x_i + |x_i|² = t² + 2 r_i t + r_i², and subtracting the equation for one chosen
// site cancels both the |c|² and the t² term, leaving conditions that are *linear* in the four
// unknowns (c, t):
//
//     2 (x_i - x_0)·c + 2 (r_i - r_0) t = (|x_i|² - r_i²) - (|x_0|² - r_0²).
//
// Four sites give three such rows, which is exactly enough to write c as an affine function of t;
// substituting back into any one tangency condition leaves a single quadratic in t. That is the
// vertex case. For a point on the trisector curve of three sites, two rows come from tangency and
// the third from the sampling plane, and the same solve applies. So one routine,
// solveTangencyRows, does the algebra for both, and neither case needs iteration or a high-degree
// predicate.
//
// The expensive part is not the algebra but deciding which quadruples of sites to try. Candidates
// are drawn from radical-diagram adjacency: the radical diagram is cheap, coincides with the
// Apollonius diagram when the radii are equal, and stays combinatorially close as they spread.
// Every candidate is then certified against an exhaustive neighbourhood search, so adjacency only
// influences which vertices are *found*, never whether a found vertex is real.

/// One edge leaving a vertex: the triple of the vertex's sites whose trisector it runs along, named by
/// position in the vertex's site list, and the direction it sets off in.
///
/// The trisector runs through the vertex both ways but only one half need be in the diagram, since on
/// the other half a site outside the triple may be the nearer. `direction` is a half that is, following
/// Wang et al., "Robust Computation of 3D Apollonius Diagrams" (Computer Graphics Forum 39(7), 2020),
/// whose vertex record likewise carries a tangent per outgoing edge.
public struct SKApolloniusBranch
{
  public var sites: (Int, Int, Int)
  public var direction: SIMD3<Double>
  
  public init(sites: (Int, Int, Int), direction: SIMD3<Double>)
  {
    self.sites = sites
    self.direction = direction
  }
}

/// A vertex of the diagram: the centre of a sphere tangent to, and outside, four or more sites. Sites
/// are named by index together with the periodic image that participates in the tangency.
///
/// Four sites is the general case, and then four edges leave the vertex, one per triple. More sites is a
/// degenerate configuration, where a sphere happens to touch five or more at once. That is a single
/// vertex of the diagram belonging to all of them, not several vertices at one point, and it is held as
/// one here: `siteIndices` carries the whole cotangent set. It is then no longer true that every triple
/// of the sites carries an edge, so the edges are listed explicitly in `branches` rather than being
/// implied by the sites. Where the tangency points are in general position on the tangent sphere their
/// convex hull is simplicial and a set of n sites yields 2n - 4 branches, which is 4 when n is 4.
public struct SKApolloniusVertex
{
  public var position: SIMD3<Double>
  public var radius: Double
  public var siteIndices: [Int]
  public var siteImages: [SIMD3<Int32>]
  public var branches: [SKApolloniusBranch]
  
  public init(position: SIMD3<Double>,
              radius: Double,
              siteIndices: [Int],
              siteImages: [SIMD3<Int32>],
              branches: [SKApolloniusBranch])
  {
    self.position = position
    self.radius = radius
    self.siteIndices = siteIndices
    self.siteImages = siteImages
    self.branches = branches
  }
}

/// An edge: the arc of the trisector curve of three sites running between two vertices. Along it
/// the clearance is stationary with respect to those three sites, so its narrowest point is the
/// bottleneck a probe must pass to travel between the two vertices.
///
/// An edge need not have endpoints. When no fourth site ever intrudes on a trisector, the curve is
/// closed and carries no vertex, and the whole of it is one edge: a ring-shaped channel. Then `isLoop`
/// is true and `from`, `to` and `toImage` are meaningless, while the sites, bottleneck and length
/// describe the ring as for any other edge.
///
/// Where the bottleneck sits is kept along with how wide it is. It is the narrowest cross-section of
/// the passage, so the plane through `bottleneckPosition` perpendicular to `bottleneckDirection`, the
/// tangent of the arc there, cuts the window a probe has to get through. Both come from the samples
/// that measure the bottleneck in the first place and cost nothing beyond them, and both are in the
/// frame in which `from` sits in the home cell.
public struct SKApolloniusEdge
{
  public var from: Int
  public var to: Int
  public var toImage: SIMD3<Int32>
  public var siteIndices: (Int, Int, Int)
  public var siteImages: (SIMD3<Int32>, SIMD3<Int32>, SIMD3<Int32>)
  public var bottleneckRadius: Double
  public var bottleneckPosition: SIMD3<Double>
  public var bottleneckDirection: SIMD3<Double>
  public var length: Double
  public var isLoop: Bool
  
  public init(from: Int,
              to: Int,
              toImage: SIMD3<Int32>,
              siteIndices: (Int, Int, Int),
              siteImages: (SIMD3<Int32>, SIMD3<Int32>, SIMD3<Int32>),
              bottleneckRadius: Double,
              bottleneckPosition: SIMD3<Double>,
              bottleneckDirection: SIMD3<Double>,
              length: Double,
              isLoop: Bool)
  {
    self.from = from
    self.to = to
    self.toImage = toImage
    self.siteIndices = siteIndices
    self.siteImages = siteImages
    self.bottleneckRadius = bottleneckRadius
    self.bottleneckPosition = bottleneckPosition
    self.bottleneckDirection = bottleneckDirection
    self.length = length
    self.isLoop = isLoop
  }
}

/// A face: a connected region of the clearance bisector sheet between two sites, one face per site so
/// that each cell owns its own, as with SKVoronoiFace. `edgeIndices` is the unordered set of bounding
/// edges. `isClosed` records whether the boundary satisfies the cycle condition, that every vertex on
/// the region is met by exactly two of its edges; the edges are not put into cyclic order, which for a
/// curved patch would require sampling its geometry.
///
/// One bisector sheet may carry more than one such region, and they are separate faces: unlike a Voronoi
/// or power diagram, where the sheet between two sites is a single convex polygon, an Apollonius sheet
/// can be cut by other sheets into several disconnected pieces (Wang et al., Section 5.4). Counting one
/// face per sheet instead of one per region is what makes Euler's formula miss.
///
/// A region need not be a disc either. Its boundary can have several components: an outer rim of arcs
/// together with holes bitten out of its middle, each hole a closed trisector carrying no vertex. All of
/// them appear in `edgeIndices`, which is why that is a set and not a cycle.
public struct SKApolloniusFace
{
  public var site1: Int
  public var site2: Int
  public var site2Image: SIMD3<Int32>
  public var edgeIndices: [Int]
  public var isClosed: Bool
  
  public init(site1: Int, site2: Int, site2Image: SIMD3<Int32>, edgeIndices: [Int], isClosed: Bool)
  {
    self.site1 = site1
    self.site2 = site2
    self.site2Image = site2Image
    self.edgeIndices = edgeIndices
    self.isClosed = isClosed
  }
}

/// A cell: everything incident on one site. An engulfed sphere has no cell at all, which is a
/// genuine feature of the additively weighted diagram rather than a failure.
public struct SKApolloniusCell
{
  public var siteIndex: Int
  public var faceIndices: [Int]
  public var vertexIndices: [Int]
  public var isEmpty: Bool
  
  public init(siteIndex: Int, faceIndices: [Int], vertexIndices: [Int], isEmpty: Bool)
  {
    self.siteIndex = siteIndex
    self.faceIndices = faceIndices
    self.vertexIndices = vertexIndices
    self.isEmpty = isEmpty
  }
}

/// Which part of space the diagram is built over.
///
/// A point equidistant in clearance from four sites has a signed clearance, and where that value is
/// negative the point lies inside the spheres. Both choices below are the same construction; they
/// differ only in whether such points are admitted.
public enum SKApolloniusRegion
{
  /// Only non-negative clearance: the diagram of the space a probe can actually occupy. The complex is
  /// then clipped against the boundary of the union of the spheres, so arcs running inside the spheres
  /// stop at that boundary and the counts of a closed complex do not apply. This is what pore geometry
  /// wants, and it is cheaper, since the interiors of the spheres are never explored.
  case freeSpace
  
  /// Every clearance, negative included: the diagram as a partition of all of space, in the sense of
  /// Wang et al. Equation 15, where the common weighted distance r may be of either sign. Nothing is
  /// clipped, so every vertex is four-valent, every triple pairs, and Euler's formula holds.
  case entireSpace
}

public struct SKApolloniusDiagram
{
  /// Whether the complex came out combinatorially consistent. In the diagram over `entireSpace` every
  /// vertex carries an edge along each of its branches and every triple supporting a vertex supports
  /// exactly one more, since an arc has two ends. Those identities are weakened over `freeSpace`, which
  /// clips arcs that run inside the spheres; `truncatedTriples` counts the clipped ones, and each costs
  /// its surviving vertex one unit of valence. A shortfall beyond that is a real failure of construction,
  /// and these counters are the honest measure of it.
  ///
  /// They hold on a degenerate input as well. A vertex where more than four sites are cotangent has more
  /// than four branches, so valence is compared against a vertex's own branch count rather than against
  /// four, and the identities are then the same ones. `degenerateVertices` reports that the input is
  /// degenerate; it does not mean anything is wrong.
  public struct Verification
  {
    public var vertexCount: Int
    public var verticesOfFullValence: Int
    public var unpairedTriples: Int
    public var truncatedTriples: Int
    public var overpairedTriples: Int
    public var coincidentVertices: Int
    public var unclosedFaces: Int
    public var vertexlessLoops: Int
    public var ringsOfUncertainFace: Int
    /// Places where the sweep refined as far as it goes, a thousandth of an Ångström, and still had more
    /// sites able to be nearest than it can take in quadruples cheaply, which needs seventeen of them
    /// cotangent to within that. Those boxes are solved over the sites they have, so this is not a defect
    /// either, but it is the one case the sweep resolves neither by refining nor by finishing early, and it
    /// is reported so that it is never silent. An ordinary degeneracy does not reach it: the sweep finishes a
    /// box as soon as its sites are few or as soon as splitting stops reducing them, and the second of those
    /// is what a degeneracy does, which is what makes it no harder than the general case.
    public var degenerateSweepBoxes: Int
    public var degenerateVertices: Int
    public var ambiguousBranches: Int
    /// Arcs along which a sample point could not be placed, so their narrowest point is not proven.
    /// A bottleneck read from the samples that did land can only come out too wide, never too narrow,
    /// and a bottleneck too wide is a passage reported open that is shut.
    public var unsampledArcs: Int
    
    public init(vertexCount: Int = 0,
                verticesOfFullValence: Int = 0,
                unpairedTriples: Int = 0,
                truncatedTriples: Int = 0,
                overpairedTriples: Int = 0,
                coincidentVertices: Int = 0,
                unclosedFaces: Int = 0,
                vertexlessLoops: Int = 0,
                ringsOfUncertainFace: Int = 0,
                degenerateSweepBoxes: Int = 0,
                degenerateVertices: Int = 0,
                ambiguousBranches: Int = 0,
                unsampledArcs: Int = 0)
    {
      self.vertexCount = vertexCount
      self.verticesOfFullValence = verticesOfFullValence
      self.unpairedTriples = unpairedTriples
      self.truncatedTriples = truncatedTriples
      self.overpairedTriples = overpairedTriples
      self.coincidentVertices = coincidentVertices
      self.unclosedFaces = unclosedFaces
      self.vertexlessLoops = vertexlessLoops
      self.ringsOfUncertainFace = ringsOfUncertainFace
      self.degenerateSweepBoxes = degenerateSweepBoxes
      self.degenerateVertices = degenerateVertices
      self.ambiguousBranches = ambiguousBranches
      self.unsampledArcs = unsampledArcs
    }
    
    /// True when the complex closes as far as the free region allows: every triple is paired except
    /// those clipped by the boundary, every vertex carries an edge along each of its branches except
    /// where a clipped arc leaves it one short, and no face is left open except around a clipped arc. An
    /// arc lies on the trisector of three sites and so borders three bisector patches, one for each pair
    /// among them, which bounds how many faces one clipped arc can leave unclosed.
    ///
    /// Two vertices at one point would be a cotangent set that failed to be gathered into the single
    /// vertex it is, and a branch of undecided direction is an edge that may have been sent the wrong way,
    /// so both are disqualifying.
    public func isComplete() -> Bool
    {
      return vertexCount > 0 && coincidentVertices == 0 && ambiguousBranches == 0 && unpairedTriples == 0 &&
             overpairedTriples == 0 && unsampledArcs == 0 &&
             verticesOfFullValence + truncatedTriples >= vertexCount && unclosedFaces <= 3 * truncatedTriples
    }
  }
  
  public var vertices: [SKApolloniusVertex]
  public var edges: [SKApolloniusEdge]
  public var faces: [SKApolloniusFace]
  public var cells: [SKApolloniusCell]
  public var verification: Verification
  
  public init(vertices: [SKApolloniusVertex] = [],
              edges: [SKApolloniusEdge] = [],
              faces: [SKApolloniusFace] = [],
              cells: [SKApolloniusCell] = [],
              verification: Verification = Verification())
  {
    self.vertices = vertices
    self.edges = edges
    self.faces = faces
    self.cells = cells
    self.verification = verification
  }
  
  /// Radius of the largest sphere that fits anywhere, and where it sits. This is the diagram's
  /// deepest vertex, and it is exact rather than approximated from a discretisation.
  public func largestEmptySphereRadius() -> Double
  {
    var maximum = 0.0
    for vertex in vertices
    {
      maximum = max(maximum, vertex.radius)
    }
    return maximum
  }
  
  public func largestEmptySpherePosition() -> SIMD3<Double>
  {
    var maximum = -1.0
    var position = SIMD3<Double>()
    for vertex in vertices
    {
      if vertex.radius > maximum
      {
        maximum = vertex.radius
        position = vertex.position
      }
    }
    return position
  }
  
  /// `neighbourRings` controls how far candidate site quadruples are drawn from radical-diagram
  /// adjacency: 1 uses direct neighbours, 2 also uses neighbours of neighbours. Raising it widens
  /// the search, at cubic cost in the neighbour count, and is the lever to pull when
  /// `verification.isComplete()` is false.
  public static func create(unitCell: double3x3,
                            fractionalPositions: [SIMD3<Double>],
                            radii: [Double],
                            neighbourRings: Int = 1,
                            region: SKApolloniusRegion = .freeSpace) -> SKApolloniusDiagram
  {
    return SKApolloniusBuild.create(unitCell: unitCell,
                                    fractionalPositions: fractionalPositions,
                                    radii: radii,
                                    neighbourRings: neighbourRings,
                                    region: region)
  }
}

/// The spheres tangent to all four given spheres, the classical Apollonius problem in three dimensions.
/// Four tangency conditions fix the centre and radius up to a quadratic, so there are at most two solutions;
/// fewer are returned when the quadratic has no real root, when `allowNegativeRadius` is false and no root is
/// non-negative, or when the four spheres admit no isolated tangent sphere in the first place, as four
/// coplanar spheres of equal radii do not: they admit either none or a whole family, never one or two.
///
/// Coplanar centres are otherwise no obstacle, nor are three collinear ones, which arise together and which
/// no arrangement of the four spheres avoids once three of their centres line up.
///
/// A negative radius is a real solution of the same equations: the point is equidistant in clearance
/// from the four sites with that clearance negative, so it lies inside them. Such a solution is a
/// vertex of the diagram over all of space but not of the diagram of the free space.
public struct SKApolloniusTangentSphere
{
  public var centre: SIMD3<Double>
  public var radius: Double
  
  public init(centre: SIMD3<Double>, radius: Double)
  {
    self.centre = centre
    self.radius = radius
  }
}

public func skApolloniusTangentSpheres(centres: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>, SIMD3<Double>),
                                       radii: (Double, Double, Double, Double),
                                       allowNegativeRadius: Bool = false) -> [SKApolloniusTangentSphere]
{
  let centreArray = [centres.0, centres.1, centres.2, centres.3]
  let radiusArray = [radii.0, radii.1, radii.2, radii.3]
  return SKApolloniusAlgebra.tangentSpheresOf(centres: centreArray, radii: radiusArray,
                                              allowNegativeRadius: allowNegativeRadius)
}

/// The point on the trisector curve of three sites at parameter `t` in [0,1] between two vertex
/// positions, obtained by projecting the straight chord onto the curve. Used to sample edges for
/// bottleneck and length calculations, and available to callers that need edge geometry.
///
/// An arc between two vertices of the free space can still dip inside the sites along the way: the
/// window between two cages is such an arc, open at both ends and closed in the middle. Measuring
/// its bottleneck means following it there, so `allowNegativeRadius` admits the stretch of the curve
/// that lies inside the sites. Without it the dip returns nothing and a passage no probe can pass is
/// left looking as wide as its ends.
public func skApolloniusTrisectorPoint(centres: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>),
                                       radii: (Double, Double, Double),
                                       from: SIMD3<Double>,
                                       to: SIMD3<Double>,
                                       t: Double,
                                       allowNegativeRadius: Bool = false) -> SKApolloniusTangentSphere?
{
  // Two rows from tangency to sites 1 and 2 relative to site 0, and a third from the plane cutting
  // the chord at parameter t, which selects one point on the curve.
  let chord = to - from
  let chordLength = simd_length(chord)
  if chordLength < 1.0e-12
  {
    return nil
  }
  let normal = chord / chordLength
  let planePoint = from + t * chord
  
  var rows = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
  var timeArray = [0.0, 0.0, 0.0]
  var constantArray = [0.0, 0.0, 0.0]
  let centreArray = [centres.0, centres.1, centres.2]
  let radiusArray = [radii.0, radii.1, radii.2]
  for i in 0..<2
  {
    SKApolloniusAlgebra.tangencyRow(centre: centreArray[i + 1], radius: radiusArray[i + 1],
                                    referenceCentre: centreArray[0], referenceRadius: radiusArray[0],
                                    row: &rows[i], timeCoefficient: &timeArray[i], constant: &constantArray[i])
  }
  rows[2] = normal
  timeArray[2] = 0.0
  constantArray[2] = simd_dot(normal, planePoint)
  
  let solutions = SKApolloniusAlgebra.solveTangencyRows(rows: (rows[0], rows[1], rows[2]),
                                                        timeCoefficients: SIMD3<Double>(timeArray[0], timeArray[1], timeArray[2]),
                                                        constants: SIMD3<Double>(constantArray[0], constantArray[1], constantArray[2]),
                                                        referenceCentre: centreArray[0],
                                                        referenceRadius: radiusArray[0],
                                                        allowNegativeRadius: allowNegativeRadius)
  
  // The rows carry the tangency to sites 1 and 2 squared, so a root of them need not satisfy the
  // unsquared condition. With the clearance confined to be non-negative it always does; once the curve
  // is followed inside the sites the wrong branch of each square root becomes a solution too, and has
  // to be thrown out.
  //
  // The plane meets the curve in up to two points, on opposite branches; the one nearest the chord is
  // kept, which is the branch the arc between the two vertices runs along.
  var best: SKApolloniusTangentSphere?
  var bestDistance = Double.greatestFiniteMagnitude
  for sphere in solutions
  {
    var tangent = true
    for i in 0..<3 where tangent
    {
      let tangentDistance = radiusArray[i] + sphere.radius
      if tangentDistance < 0.0 || abs(simd_length(sphere.centre - centreArray[i]) - tangentDistance) >
           1.0e-6 * max(1.0, tangentDistance)
      {
        tangent = false
      }
    }
    if !tangent
    {
      continue
    }
    
    let distance = simd_length(sphere.centre - planePoint)
    if distance < bestDistance
    {
      bestDistance = distance
      best = sphere
    }
  }
  return best
}

// MARK: - File-private algebra and search helpers

fileprivate func skFract(_ p: SIMD3<Double>) -> SIMD3<Double>
{
  return SIMD3<Double>(p.x - floor(p.x), p.y - floor(p.y), p.z - floor(p.z))
}

fileprivate func skTripleGet<T>(_ values: (T, T, T), _ i: Int) -> T
{
  switch i
  {
  case 0: return values.0
  case 1: return values.1
  default: return values.2
  }
}

fileprivate func skSiteImageLess(_ lhs: (Int, SIMD3<Int32>), _ rhs: (Int, SIMD3<Int32>)) -> Bool
{
  if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
  if lhs.1.x != rhs.1.x { return lhs.1.x < rhs.1.x }
  if lhs.1.y != rhs.1.y { return lhs.1.y < rhs.1.y }
  return lhs.1.z < rhs.1.z
}

fileprivate func skSiteImageEqual(_ lhs: (Int, SIMD3<Int32>), _ rhs: (Int, SIMD3<Int32>)) -> Bool
{
  return lhs.0 == rhs.0 && lhs.1 == rhs.1
}

fileprivate func skUniquedSiteImages(_ items: [(Int, SIMD3<Int32>)]) -> [(Int, SIMD3<Int32>)]
{
  var sorted = items
  sorted.sort(by: skSiteImageLess)
  var unique: [(Int, SIMD3<Int32>)] = []
  unique.reserveCapacity(sorted.count)
  for item in sorted
  {
    if unique.isEmpty || !skSiteImageEqual(unique[unique.count - 1], item)
    {
      unique.append(item)
    }
  }
  return unique
}

fileprivate func skSplitCoordinate(_ coordinate: Int32, extent: Int32) -> (bin: Int32, image: Int32)
{
  let image: Int32
  if coordinate >= 0
  {
    image = coordinate / extent
  }
  else
  {
    image = -(((-coordinate) + extent - 1) / extent)
  }
  return (coordinate - image * extent, image)
}

fileprivate func skFindParent(_ parent: inout [Int], _ node: Int) -> Int
{
  var current = node
  while parent[current] != current
  {
    parent[current] = parent[parent[current]]
    current = parent[current]
  }
  return current
}

fileprivate func skFindMapParent(_ parent: inout [Int: Int], _ node: Int) -> Int
{
  var current = node
  while parent[current] != current
  {
    parent[current] = parent[parent[current]!]
    current = parent[current]!
  }
  return current
}

/// Identifies a vertex by its four sites in a translation-invariant way, so that every periodic
/// copy, and every one of the four sites that generates it, yields the same key.
///
/// The four sites alone are not an identity. A quadruple admits up to two distinct tangent spheres,
/// the two roots of the quadratic, and both can be empty and so both be genuine vertices; Kamarianakis
/// distinguishes them as v_ijkl and v_ikjl by the orientation of the tetrahedron of tangency points.
/// Keying on the sites alone therefore collides two different vertices and silently drops one, which
/// leaves the arcs between them unpaired. `orientation` separates them.
fileprivate struct SKApolloniusSiteTuple: Hashable, Comparable
{
  var data: [Int64]
  var orientation: Int64
  
  init()
  {
    data = Array(repeating: 0, count: 16)
    orientation = 0
  }
  
  static func < (lhs: SKApolloniusSiteTuple, rhs: SKApolloniusSiteTuple) -> Bool
  {
    if lhs.data != rhs.data
    {
      return lhs.data.lexicographicallyPrecedes(rhs.data)
    }
    return lhs.orientation < rhs.orientation
  }
}

/// Sorts (site, image) pairs and rebases the images on the first pair, which removes the lattice
/// translation. `count` pairs are used; the remainder of the key stays zero. When `permutation` is
/// requested it receives the sorted order, so that a caller can evaluate the orientation of the tangency
/// tetrahedron in the same canonical order and get a sign that does not depend on how the quadruple
/// happened to be enumerated.
fileprivate func skCanonicalTuple(indices: [Int],
                                  images: [SIMD3<Int32>],
                                  count: Int,
                                  permutation: inout [Int]?) -> (key: SKApolloniusSiteTuple, appliedOffset: SIMD3<Int32>)
{
  var pairs = [(Int64, Int64, Int64, Int64, Int64)](repeating: (0, 0, 0, 0, 0), count: 4)
  for i in 0..<count
  {
    pairs[i] = (Int64(indices[i]), Int64(images[i].x), Int64(images[i].y), Int64(images[i].z), Int64(i))
  }
  var prefix = Array(pairs[0..<count])
  prefix.sort
  {
    lhs, rhs in
    if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
    if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
    if lhs.2 != rhs.2 { return lhs.2 < rhs.2 }
    return lhs.3 < rhs.3
  }
  for i in 0..<count
  {
    pairs[i] = prefix[i]
  }
  
  let appliedOffset = SIMD3<Int32>(Int32(pairs[0].1), Int32(pairs[0].2), Int32(pairs[0].3))
  var key = SKApolloniusSiteTuple()
  for i in 0..<count
  {
    key.data[4 * i + 0] = pairs[i].0
    key.data[4 * i + 1] = pairs[i].1 - Int64(appliedOffset.x)
    key.data[4 * i + 2] = pairs[i].2 - Int64(appliedOffset.y)
    key.data[4 * i + 3] = pairs[i].3 - Int64(appliedOffset.z)
    if permutation != nil
    {
      permutation![i] = Int(pairs[i].4)
    }
  }
  return (key, appliedOffset)
}

fileprivate func skCanonicalTuple(indices: [Int], images: [SIMD3<Int32>], count: Int) -> (key: SKApolloniusSiteTuple, appliedOffset: SIMD3<Int32>)
{
  var unused: [Int]? = nil
  return skCanonicalTuple(indices: indices, images: images, count: count, permutation: &unused)
}

/// For each position, one of the positions it coincides with to within `tolerance`, the same one for all of
/// a coinciding set, so that what shares an answer is what is the same point. Coincidence is periodic: a
/// point near a face of the cell coincides with one near the opposite face.
///
/// A grid of the tolerance's own size is laid over the cell and the points are dropped into it, so a point
/// can only coincide with the points in its own cell of the grid or in one of the twenty-six around it, and
/// what has to be searched does not grow with how many points coincide. Nothing is gained by looking further
/// than the first match, the rest of the set being reached through it.
///
/// The grid may be coarser than the tolerance and still be right, since what it has to do is put every pair
/// closer than the tolerance within a cell of each other, which a coarser grid also does; that is what lets
/// the division count be capped, and it is capped so that a very large cell cannot ask for more divisions
/// than there are numbers to count them with. Only the occupied cells are held, so the count costs nothing.
fileprivate func skCoincidentGroups(unitCell: double3x3,
                                    inverseCell: double3x3,
                                    perpendicularWidths: SIMD3<Double>,
                                    positions: [SIMD3<Double>],
                                    tolerance: Double) -> [Int]
{
  let mostDivisions: Int32 = 1 << 20
  func divisionsAlong(_ width: Double) -> Int32
  {
    let raw = min(width / tolerance, 1.0e9)
    return max(1, min(Int32(raw), mostDivisions))
  }
  let divisions = SIMD3<Int32>(divisionsAlong(perpendicularWidths.x),
                               divisionsAlong(perpendicularWidths.y),
                               divisionsAlong(perpendicularWidths.z))
  
  func cellOf(_ position: SIMD3<Double>) -> SIMD3<Int32>
  {
    let fractional = skFract(inverseCell * position)
    return SIMD3<Int32>(min(divisions.x - 1, Int32(fractional.x * Double(divisions.x))),
                        min(divisions.y - 1, Int32(fractional.y * Double(divisions.y))),
                        min(divisions.z - 1, Int32(fractional.z * Double(divisions.z))))
  }
  
  var occupants: [SIMD3<Int32>: [Int]] = [:]
  var group = [Int](repeating: 0, count: positions.count)
  for p in 0..<positions.count
  {
    group[p] = p
    let own = cellOf(positions[p])
    
    var found = false
    oxLoop: for ox in Int32(-1)...1
    {
      for oy in Int32(-1)...1
      {
        for oz in Int32(-1)...1
        {
          let neighbour = SIMD3<Int32>((own.x + ox + divisions.x) % divisions.x,
                                       (own.y + oy + divisions.y) % divisions.y,
                                       (own.z + oz + divisions.z) % divisions.z)
          guard let others = occupants[neighbour] else { continue }
          for other in others
          {
            var delta = inverseCell * (positions[p] - positions[other])
            delta = SIMD3<Double>(delta.x - Darwin.round(delta.x),
                                  delta.y - Darwin.round(delta.y),
                                  delta.z - Darwin.round(delta.z))
            if simd_length(unitCell * delta) < tolerance
            {
              group[p] = other
              found = true
              break oxLoop
            }
          }
        }
      }
    }
    occupants[own, default: []].append(p)
    if found
    {
      continue
    }
  }
  return group
}

/// The edges leaving a vertex: which triples of its sites carry one, and in which direction.
///
/// Wang et al. give the tangent to the trisector of three sites at a point v as the cross product of
/// the differences of the unit vectors from v to the sites, each such difference being the normal of
/// one bisector sheet at v. That fixes the line but not which of its two halves is in the diagram.
/// Moving off v along the trisector keeps the three sites equidistant while every other site becomes
/// nearer or farther; only where all of them become farther does the tangent sphere stay empty and the
/// arc belong to the diagram. The clearance to site m has gradient u_m, the unit vector from m to v, so
/// the gap between site m and the triple grows along a direction d at the rate (u_m - u_i)·d, and its
/// sign is the test. A half on which no site encroaches is an edge.
///
/// With four sites each triple omits one site, whose gap grows one way and shrinks the other, so exactly
/// one half of each of the four trisectors survives and there are four branches. With more, a triple can
/// lose both halves, to different sites, and only those triples whose tangency points span a facet of
/// the hull of all of them keep one.
///
/// A rate too small to have a reliable sign leaves the half undecided: the gap is then governed by
/// curvature rather than slope, which this test cannot see. Rather than guess, such a branch is admitted
/// and reported through `ambiguous`, so that a diagram resting on a guess cannot claim to be consistent.
fileprivate func skVertexBranches(centre: SIMD3<Double>,
                                  siteCentres: [SIMD3<Double>],
                                  ambiguous: inout Int) -> [SKApolloniusBranch]
{
  let count = siteCentres.count
  var unitToSite = [SIMD3<Double>](repeating: SIMD3<Double>(), count: count)
  for s in 0..<count
  {
    let delta = centre - siteCentres[s]
    let length = simd_length(delta)
    unitToSite[s] = (length > 1.0e-12) ? (1.0 / length) * delta : SIMD3<Double>()
  }
  
  let decidableRate = 1.0e-9
  var branches: [SKApolloniusBranch] = []
  for i in 0..<count
  {
    for j in (i + 1)..<count
    {
      for k in (j + 1)..<count
      {
        var tangent = simd_cross(unitToSite[i] - unitToSite[j], unitToSite[j] - unitToSite[k])
        let length = simd_length(tangent)
        if length < 1.0e-14
        {
          continue  // the three bisector normals are dependent: no trisector here
        }
        tangent = (1.0 / length) * tangent
        
        for sign in [1.0, -1.0]
        {
          let direction = sign * tangent
          var outgoing = true
          var undecided = false
          var m = 0
          while m < count && outgoing
          {
            if m != i && m != j && m != k
            {
              let rate = simd_dot(unitToSite[m] - unitToSite[i], direction)
              if rate < -decidableRate
              {
                outgoing = false
              }
              else if rate <= decidableRate
              {
                undecided = true
              }
            }
            m += 1
          }
          if !outgoing
          {
            continue
          }
          if undecided
          {
            ambiguous += 1
          }
          branches.append(SKApolloniusBranch(sites: (i, j, k), direction: direction))
        }
      }
    }
  }
  return branches
}

/// Orientation of the tetrahedron formed by the points at which a tangent sphere touches its four
/// sites, taken in canonical site order. This is the sign that distinguishes the two vertices a
/// quadruple can support.
fileprivate func skTangencyOrientation(centre: SIMD3<Double>,
                                       radius: Double,
                                       siteCentres: [SIMD3<Double>],
                                       permutation: [Int]) -> Int64
{
  var tangency = [SIMD3<Double>](repeating: SIMD3<Double>(), count: 4)
  for i in 0..<4
  {
    let delta = siteCentres[permutation[i]] - centre
    let length = simd_length(delta)
    tangency[i] = (length > 1.0e-12) ? centre + (radius / length) * delta : centre
  }
  let determinant = simd_dot(tangency[1] - tangency[0],
                             simd_cross(tangency[2] - tangency[0], tangency[3] - tangency[0]))
  return (determinant >= 0.0) ? 1 : -1
}

fileprivate enum SKApolloniusAlgebra
{
  /// Solves three rows that are linear in the four unknowns (c, t) together with the tangency condition for
  /// the reference site, returning the at most two (c, t), restricted to t >= 0 unless negative clearance is
  /// admitted. Rows are given as `rows[i]·c + timeCoefficients[i] * t = constants[i]`.
  ///
  /// Three rows in four unknowns leave a line, and the tangency condition, being quadratic, meets that line at
  /// most twice. The line is taken from the null space of the rows rather than by writing c as a function of t
  /// and substituting, because that function does not always exist. Three collinear site centres contribute
  /// two rows with parallel coefficients of c, leaving those coefficients of rank two; what the rows then fix
  /// is t, with c free to move along a direction, which is the circle of tangent spheres that three collinear
  /// spheres share. It is the same line either way, so reading it off the null space treats the arrangements
  /// alike, and the arrangement that has no c as a function of t is not special: it is simply the one whose
  /// null vector has no component along t.
  static func solveTangencyRows(rows: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>),
                                timeCoefficients: SIMD3<Double>,
                                constants: SIMD3<Double>,
                                referenceCentre: SIMD3<Double>,
                                referenceRadius: Double,
                                allowNegativeRadius: Bool = false) -> [SKApolloniusTangentSphere]
  {
    let rowArray = [rows.0, rows.1, rows.2]
    var system = [[Double]](repeating: [0.0, 0.0, 0.0, 0.0], count: 3)
    var scale = 0.0
    for i in 0..<3
    {
      system[i] = [rowArray[i].x, rowArray[i].y, rowArray[i].z, timeCoefficients[i]]
      scale = max(scale, sqrt(simd_length_squared(rowArray[i]) + timeCoefficients[i] * timeCoefficients[i]))
    }
    
    // The determinant of the rows with one column struck out. Alternating in sign these are the components of
    // the null vector, the generalised cross product of the three rows.
    func minorWithout(_ skipped: Int) -> Double
    {
      var kept = [0, 0, 0]
      var written = 0
      for column in 0..<4
      {
        if column != skipped
        {
          kept[written] = column
          written += 1
        }
      }
      func entry(_ row: Int, _ column: Int) -> Double
      {
        return system[row][kept[column]]
      }
      return entry(0, 0) * (entry(1, 1) * entry(2, 2) - entry(1, 2) * entry(2, 1)) -
             entry(0, 1) * (entry(1, 0) * entry(2, 2) - entry(1, 2) * entry(2, 0)) +
             entry(0, 2) * (entry(1, 0) * entry(2, 1) - entry(1, 1) * entry(2, 0))
    }
    
    var along = [minorWithout(0), -minorWithout(1), minorWithout(2), -minorWithout(3)]
    let alongNorm = sqrt(along[0] * along[0] + along[1] * along[1] + along[2] * along[2] + along[3] * along[3])
    
    // Every minor vanishing means the rows have rank below three and leave a surface rather than a line, so
    // there is no isolated solution to find: four concyclic centres of equal radii, say, or for the trisector
    // case a sampling plane that holds the curve instead of cutting it.
    if scale <= 0.0 || alongNorm < 1.0e-12 * scale * scale * scale
    {
      return []
    }
    for i in 0..<4
    {
      along[i] /= alongNorm
    }
    
    // A point on the line, found by striking out the column whose minor is largest, which is the best
    // conditioned of the four ways to do it, and holding that unknown at zero.
    var held = 0
    for column in 1..<4
    {
      if abs(along[column]) > abs(along[held])
      {
        held = column
      }
    }
    var kept = [0, 0, 0]
    var written = 0
    for column in 0..<4
    {
      if column != held
      {
        kept[written] = column
        written += 1
      }
    }
    
    // double3x3 is built from columns, so each column of the reduced rows becomes one of its columns.
    let reduced = double3x3(SIMD3<Double>(system[0][kept[0]], system[1][kept[0]], system[2][kept[0]]),
                            SIMD3<Double>(system[0][kept[1]], system[1][kept[1]], system[2][kept[1]]),
                            SIMD3<Double>(system[0][kept[2]], system[1][kept[2]], system[2][kept[2]]))
    let solved = reduced.inverse * constants
    
    var base = [0.0, 0.0, 0.0, 0.0]
    base[held] = 0.0
    for column in 0..<3
    {
      base[kept[column]] = solved[column]
    }
    
    let baseCentre = SIMD3<Double>(base[0], base[1], base[2])
    let baseRadius = base[3]
    let alongCentre = SIMD3<Double>(along[0], along[1], along[2])
    let alongRadius = along[3]
    
    // Substituting c = baseCentre + s * alongCentre and t = baseRadius + s * alongRadius into the unsquared
    // tangency |c - x_ref| = r_ref + t, squared.
    let offset = baseCentre - referenceCentre
    let reach = referenceRadius + baseRadius
    let a = simd_dot(alongCentre, alongCentre) - alongRadius * alongRadius
    let b = 2.0 * (simd_dot(offset, alongCentre) - reach * alongRadius)
    let c = simd_dot(offset, offset) - reach * reach
    
    var roots = [0.0, 0.0]
    var rootCount = 0
    if abs(a) < 1.0e-14
    {
      if abs(b) > 1.0e-14 * scale
      {
        roots[rootCount] = -c / b
        rootCount += 1
      }
    }
    else
    {
      let discriminant = b * b - 4.0 * a * c
      if discriminant < 0.0
      {
        return []
      }
      let squareRoot = sqrt(discriminant)
      roots[rootCount] = (-b + squareRoot) / (2.0 * a)
      rootCount += 1
      roots[rootCount] = (-b - squareRoot) / (2.0 * a)
      rootCount += 1
    }
    
    var spheres: [SKApolloniusTangentSphere] = []
    for root in 0..<rootCount
    {
      let s = roots[root]
      let t = baseRadius + s * alongRadius
      if t < 0.0 && !allowNegativeRadius
      {
        continue
      }
      
      // The rows hold the tangency conditions squared, so a root only satisfies the unsquared condition
      // |c - x| = r + t when r + t is not negative. With t confined to be non-negative this is automatic;
      // once negative t is admitted it has to be imposed, or the extraneous roots of the squaring are
      // taken for vertices.
      if referenceRadius + t < 0.0
      {
        continue
      }
      
      spheres.append(SKApolloniusTangentSphere(centre: baseCentre + s * alongCentre, radius: t))
    }
    return spheres
  }
  
  /// The row contributed by requiring tangency to `centre`/`radius` relative to a reference site.
  static func tangencyRow(centre: SIMD3<Double>,
                          radius: Double,
                          referenceCentre: SIMD3<Double>,
                          referenceRadius: Double,
                          row: inout SIMD3<Double>,
                          timeCoefficient: inout Double,
                          constant: inout Double)
  {
    row = 2.0 * (centre - referenceCentre)
    timeCoefficient = 2.0 * (radius - referenceRadius)
    constant = (simd_dot(centre, centre) - radius * radius) -
               (simd_dot(referenceCentre, referenceCentre) - referenceRadius * referenceRadius)
  }
  
  /// The points of the trisector of three sites at one value of the clearance.
  ///
  /// Imposing all three tangencies at a fixed clearance leaves two linear conditions on the centre, whose
  /// intersection is a line, and one quadratic, so a trisector meets each clearance level in at most two
  /// points, one on each of the two branches that make up the curve. Sweeping the clearance therefore
  /// traverses the whole curve, and, usefully, the sweep runs out at a finite clearance exactly when the
  /// curve is closed: an open trisector reaches every clearance above its minimum.
  static func trisectorPointsAtClearance(centres: [SIMD3<Double>],
                                         radii: [Double],
                                         clearance: Double) -> [SIMD3<Double>]
  {
    let referenceDistance = radii[0] + clearance
    if referenceDistance < 0.0
    {
      return []
    }
    
    var rows = [SIMD3<Double>(), SIMD3<Double>()]
    var constants = [0.0, 0.0]
    for i in 0..<2
    {
      var timeCoefficient = 0.0
      tangencyRow(centre: centres[i + 1], radius: radii[i + 1],
                  referenceCentre: centres[0], referenceRadius: radii[0],
                  row: &rows[i], timeCoefficient: &timeCoefficient, constant: &constants[i])
      constants[i] -= timeCoefficient * clearance
    }
    
    let direction = simd_cross(rows[0], rows[1])
    let directionLength = simd_length(direction)
    let scale = max(simd_length(rows[0]), simd_length(rows[1]))
    if scale <= 0.0 || directionLength < 1.0e-12 * scale * scale
    {
      return []
    }
    
    // Any point on the line where the two planes meet; the third row pins it down along the line.
    let matrix = double3x3(SIMD3<Double>(rows[0].x, rows[1].x, direction.x),
                           SIMD3<Double>(rows[0].y, rows[1].y, direction.y),
                           SIMD3<Double>(rows[0].z, rows[1].z, direction.z))
    if abs(matrix.determinant) < 1.0e-30
    {
      return []
    }
    let base = matrix.inverse * SIMD3<Double>(constants[0], constants[1], 0.0)
    
    let offset = base - centres[0]
    let a = simd_dot(direction, direction)
    let b = 2.0 * simd_dot(offset, direction)
    let c = simd_dot(offset, offset) - referenceDistance * referenceDistance
    let discriminant = b * b - 4.0 * a * c
    if discriminant < 0.0
    {
      return []
    }
    
    let root = sqrt(discriminant)
    var points: [SIMD3<Double>] = []
    points.append(base + ((-b + root) / (2.0 * a)) * direction)
    if root > 1.0e-9 * (abs(b) + a)
    {
      points.append(base + ((-b - root) / (2.0 * a)) * direction)
    }
    return points
  }
  
  /// A point of the bisector sheet of two sites, at one clearance and one angle about the axis joining their
  /// centres. The sheet is one branch of a hyperboloid of revolution about that axis, so at each clearance
  /// the two tangent spheres meet in a circle, and the circle shrinks to a point at the apex below which the
  /// sheet does not reach.
  static func bisectorSheetPoint(firstCentre: SIMD3<Double>,
                                 firstRadius: Double,
                                 secondCentre: SIMD3<Double>,
                                 secondRadius: Double,
                                 clearance: Double,
                                 angle: Double) -> SIMD3<Double>?
  {
    let firstDistance = firstRadius + clearance
    let secondDistance = secondRadius + clearance
    if firstDistance < 0.0 || secondDistance < 0.0
    {
      return nil
    }
    
    var axis = secondCentre - firstCentre
    let separation = simd_length(axis)
    if separation < 1.0e-12
    {
      return nil
    }
    axis = (1.0 / separation) * axis
    
    let along = (separation * separation + firstDistance * firstDistance - secondDistance * secondDistance) /
                (2.0 * separation)
    let radialSquared = firstDistance * firstDistance - along * along
    if radialSquared < 0.0
    {
      return nil
    }
    let radial = sqrt(radialSquared)
    
    let reference = abs(axis.x) < 0.9 ? SIMD3<Double>(1.0, 0.0, 0.0) : SIMD3<Double>(0.0, 1.0, 0.0)
    var inPlane = simd_cross(axis, reference)
    inPlane = (1.0 / simd_length(inPlane)) * inPlane
    let across = simd_cross(axis, inPlane)
    
    return firstCentre + along * axis + (radial * cos(angle)) * inPlane + (radial * sin(angle)) * across
  }
  
  /// The spheres tangent to four sites, as `skApolloniusTangentSpheres` gives them.
  static func tangentSpheresOf(centres: [SIMD3<Double>],
                               radii: [Double],
                               allowNegativeRadius: Bool) -> [SKApolloniusTangentSphere]
  {
    var rows = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
    var timeArray = [0.0, 0.0, 0.0]
    var constantArray = [0.0, 0.0, 0.0]
    for i in 0..<3
    {
      tangencyRow(centre: centres[i + 1], radius: radii[i + 1],
                  referenceCentre: centres[0], referenceRadius: radii[0],
                  row: &rows[i], timeCoefficient: &timeArray[i], constant: &constantArray[i])
    }
    
    let solutions = solveTangencyRows(rows: (rows[0], rows[1], rows[2]),
                                      timeCoefficients: SIMD3<Double>(timeArray[0], timeArray[1], timeArray[2]),
                                      constants: SIMD3<Double>(constantArray[0], constantArray[1], constantArray[2]),
                                      referenceCentre: centres[0],
                                      referenceRadius: radii[0],
                                      allowNegativeRadius: allowNegativeRadius)
    
    // solveTangencyRows can only impose the unsquared tangency for the site it was given as reference.
    // The other three were folded into differences of squares, so each needs the same test, and each
    // needs its distance to come out right rather than merely right in magnitude.
    var kept: [SKApolloniusTangentSphere] = []
    for sphere in solutions
    {
      var tangent = true
      var i = 0
      while i < 4 && tangent
      {
        let tangentDistance = radii[i] + sphere.radius
        if tangentDistance < 0.0 || abs(simd_length(sphere.centre - centres[i]) - tangentDistance) >
             1.0e-6 * max(1.0, tangentDistance)
        {
          tangent = false
        }
        i += 1
      }
      if tangent
      {
        kept.append(sphere)
      }
    }
    return kept
  }
}

/// A cell list over site images, used for the exhaustive emptiness certification. The certification
/// must not depend on the candidate adjacency, or a spurious vertex could slip through.
fileprivate struct SKApolloniusSiteGrid
{
  var cell = double3x3()
  var inverseCell = double3x3()
  var binCount = SIMD3<Int32>(1, 1, 1)
  var binWidth = SIMD3<Double>(1.0, 1.0, 1.0)
  var positions: [SIMD3<Double>] = []
  var bins: [[Int]] = []
  
  mutating func build(unitCell: double3x3,
                      unitCellInverse: double3x3,
                      perpendicularWidths: SIMD3<Double>,
                      fractionalPositions: [SIMD3<Double>],
                      volume: Double)
  {
    cell = unitCell
    inverseCell = unitCellInverse
    let count = fractionalPositions.count
    let target = cbrt(volume / max(1.0, Double(count) / 4.0))
    binCount = SIMD3<Int32>(max(1, Int32(perpendicularWidths.x / target)),
                            max(1, Int32(perpendicularWidths.y / target)),
                            max(1, Int32(perpendicularWidths.z / target)))
    binWidth = SIMD3<Double>(perpendicularWidths.x / Double(binCount.x),
                             perpendicularWidths.y / Double(binCount.y),
                             perpendicularWidths.z / Double(binCount.z))
    
    positions = [SIMD3<Double>](repeating: SIMD3<Double>(), count: count)
    bins = [[Int]](repeating: [], count: Int(binCount.x) * Int(binCount.y) * Int(binCount.z))
    for i in 0..<count
    {
      let fractional = skFract(fractionalPositions[i])
      positions[i] = cell * fractional
      let bx = min(binCount.x - 1, Int32(fractional.x * Double(binCount.x)))
      let by = min(binCount.y - 1, Int32(fractional.y * Double(binCount.y)))
      let bz = min(binCount.z - 1, Int32(fractional.z * Double(binCount.z)))
      bins[Int((bz * binCount.y + by) * binCount.x + bx)].append(i)
    }
  }
  
  /// Visits every site image whose centre lies within `searchRadius` of `wrappedCentre`, reporting
  /// the site index, its image position, and the lattice image it came from.
  func forEachNear(wrappedCentre: SIMD3<Double>,
                   searchRadius: Double,
                   visit: (Int, SIMD3<Double>, SIMD3<Int32>) -> Void)
  {
    let fractional = inverseCell * wrappedCentre
    let cx = min(binCount.x - 1, Int32(fractional.x * Double(binCount.x)))
    let cy = min(binCount.y - 1, Int32(fractional.y * Double(binCount.y)))
    let cz = min(binCount.z - 1, Int32(fractional.z * Double(binCount.z)))
    
    let span = SIMD3<Int32>(Int32(ceil(searchRadius / binWidth.x)) + 1,
                            Int32(ceil(searchRadius / binWidth.y)) + 1,
                            Int32(ceil(searchRadius / binWidth.z)) + 1)
    
    for oz in -span.z...span.z
    {
      for oy in -span.y...span.y
      {
        for ox in -span.x...span.x
        {
          let x = skSplitCoordinate(cx + ox, extent: binCount.x)
          let y = skSplitCoordinate(cy + oy, extent: binCount.y)
          let z = skSplitCoordinate(cz + oz, extent: binCount.z)
          let image = SIMD3<Int32>(x.image, y.image, z.image)
          let shift = cell * SIMD3<Double>(image)
          for j in bins[Int((z.bin * binCount.y + y.bin) * binCount.x + x.bin)]
          {
            visit(j, positions[j] + shift, image)
          }
        }
      }
    }
  }
  
  /// Whether any site image overlaps the sphere of radius `radius` about `wrappedCentre`, which is to say
  /// whether any site comes nearer to it than r_j + radius. This is the certification a candidate vertex
  /// has to pass, and nearly every candidate proposed fails it, so what the test costs is decided by how
  /// quickly a failure is found. The bins are therefore taken in shells outwards from the one the centre
  /// is in, and the search stops at the first site that overlaps: an intruder is usually close by, being a
  /// site that was nearly a site of the vertex, and is met in the first shell or two. A sphere that is
  /// genuinely empty costs the full search, as it must.
  func intrudes(wrappedCentre: SIMD3<Double>,
                radius: Double,
                radii: [Double],
                maximumRadius: Double,
                tolerance: Double) -> Bool
  {
    let searchRadius = max(0.0, radius + maximumRadius)
    let fractional = inverseCell * wrappedCentre
    let cx = min(binCount.x - 1, Int32(fractional.x * Double(binCount.x)))
    let cy = min(binCount.y - 1, Int32(fractional.y * Double(binCount.y)))
    let cz = min(binCount.z - 1, Int32(fractional.z * Double(binCount.z)))
    
    let span = SIMD3<Int32>(Int32(ceil(searchRadius / binWidth.x)) + 1,
                            Int32(ceil(searchRadius / binWidth.y)) + 1,
                            Int32(ceil(searchRadius / binWidth.z)) + 1)
    let widest = max(span.x, max(span.y, span.z))
    
    for shell in Int32(0)...widest
    {
      let zLimit = min(shell, span.z)
      for oz in -zLimit...zLimit
      {
        let yLimit = min(shell, span.y)
        for oy in -yLimit...yLimit
        {
          let xLimit = min(shell, span.x)
          for ox in -xLimit...xLimit
          {
            if max(abs(ox), max(abs(oy), abs(oz))) != shell
            {
              continue
            }
            
            let x = skSplitCoordinate(cx + ox, extent: binCount.x)
            let y = skSplitCoordinate(cy + oy, extent: binCount.y)
            let z = skSplitCoordinate(cz + oz, extent: binCount.z)
            let shift = cell * SIMD3<Double>(Double(x.image), Double(y.image), Double(z.image))
            for j in bins[Int((z.bin * binCount.y + y.bin) * binCount.x + x.bin)]
            {
              if simd_length(wrappedCentre - (positions[j] + shift)) < radii[j] + radius - tolerance
              {
                return true
              }
            }
          }
        }
      }
    }
    return false
  }
  
  /// Clearance min_j(|x - x_j| - r_j) at a point, together with the site image that attains it.
  /// `upperBound` must be an upper bound on the answer so the search radius can be sized exactly.
  func clearance(wrappedPoint: SIMD3<Double>,
                 radii: [Double],
                 upperBound: Double,
                 maximumRadius: Double,
                 nearestIndex: inout Int,
                 nearestImage: inout SIMD3<Int32>) -> Double
  {
    var best = upperBound
    nearestIndex = Int.max
    forEachNear(wrappedCentre: wrappedPoint, searchRadius: upperBound + maximumRadius)
    {
      j, image, latticeImage in
      let value = simd_length(wrappedPoint - image) - radii[j]
      if value < best
      {
        best = value
        nearestIndex = j
        nearestImage = latticeImage
      }
    }
    return best
  }
}

fileprivate enum SKApolloniusBuild
{
  struct IncidentBranch
  {
    var vertex: Int
    var branch: Int
    var offset: SIMD3<Int32>
  }
  
  struct CandidateSite
  {
    var index: Int
    var image: SIMD3<Int32>
    var position: SIMD3<Double>
  }
  
  struct Cube
  {
    var originFractional: SIMD3<Double>
    var level: Int
    var parentNearestCount: Int
  }
  
  struct PatchEdge
  {
    var edgeIndex: Int
    var ownerLocal: Int
    var otherLocal: Int
  }
  
  struct PrimitivePatch
  {
    var owner: Int
    var other: Int
    var relativeImage: SIMD3<Int32>
    var edges: [PatchEdge]
  }
  
  static func create(unitCell: double3x3,
                     fractionalPositions: [SIMD3<Double>],
                     radii: [Double],
                     neighbourRings: Int,
                     region: SKApolloniusRegion) -> SKApolloniusDiagram
  {
    // Over all of space a vertex of negative clearance is admitted, and a site intrudes on a candidate
    // only if its own clearance there is smaller, which is the same test read with a signed radius.
    let allowNegativeRadius = (region == .entireSpace)
    
    var diagram = SKApolloniusDiagram()
    let siteCount = fractionalPositions.count
    // One site in a periodic cell is already an infinite set of spheres, and the four a vertex needs may
    // be four images of it, so what has to be non-empty is the cell and not the count of sites in it.
    if siteCount == 0 || radii.count != siteCount
    {
      return diagram
    }
    
    let inverseCell = unitCell.inverse
    let volume = abs(unitCell.determinant)
    
    // Perpendicular widths of the cell, needed to size the bins. The columns of the cell matrix are the
    // lattice vectors, so they are what the widths are built from; taking the rows instead would give the
    // widths of a different cell whenever the cell is not orthogonal.
    let a = unitCell[0]
    let b = unitCell[1]
    let c = unitCell[2]
    let perpendicularWidths = SIMD3<Double>(volume / simd_length(simd_cross(b, c)),
                                            volume / simd_length(simd_cross(c, a)),
                                            volume / simd_length(simd_cross(a, b)))
    
    var maximumRadius = 0.0
    for radius in radii
    {
      maximumRadius = max(maximumRadius, radius)
    }
    
    // An upper bound on the radius of any empty sphere. Four sites in near-degenerate position have a
    // common tangent sphere that is astronomically large, and such a sphere is never a vertex here
    // because periodicity guarantees a site image within the lattice covering radius of every point.
    // Half the sum of the lattice vector lengths bounds all four half-diagonals and so bounds the
    // covering radius. Discarding candidates above it keeps the emptiness search radius finite, which
    // it otherwise would not be.
    let emptyRadiusBound = 0.5 * (simd_length(a) + simd_length(b) + simd_length(c))
    
    var grid = SKApolloniusSiteGrid()
    grid.build(unitCell: unitCell, unitCellInverse: inverseCell, perpendicularWidths: perpendicularWidths,
               fractionalPositions: fractionalPositions, volume: volume)
    
    // Candidate adjacency from the radical diagram. It coincides with Apollonius adjacency for equal
    // radii and stays close as they spread, which makes it a strong seed; correctness of the result
    // does not rest on it, only the chance of finding every vertex does.
    var adjacency: [[(Int, SIMD3<Int32>)]] = Array(repeating: [], count: siteCount)
    do
    {
      let radical = try SKVoronoi(unitCell: unitCell, fractionalPositions: fractionalPositions, radii: radii)
      let radicalCells = try radical.computeAllCells()
      for i in 0..<siteCount
      {
        for face in radicalCells[i].faces
        {
          adjacency[i].append((face.neighborIndex, face.neighborImage))
        }
      }
    }
    catch
    {
    }
    
    // Widening by extra rings composes the image shifts, so a neighbour of a neighbour is recorded at
    // the image where it actually sits relative to the original site.
    var ring = 1
    while ring < max(1, neighbourRings)
    {
      var widened = adjacency
      for i in 0..<siteCount
      {
        for (j, imageJ) in adjacency[i]
        {
          for (k, imageK) in adjacency[j]
          {
            let image = SIMD3<Int32>(imageJ.x + imageK.x, imageJ.y + imageK.y, imageJ.z + imageK.z)
            if k == i && image.x == 0 && image.y == 0 && image.z == 0
            {
              continue
            }
            widened[i].append((k, image))
          }
        }
        widened[i] = skUniquedSiteImages(widened[i])
      }
      adjacency = widened
      ring += 1
    }
    
    // Enumerate quadruples: each site together with three of its candidate neighbours. Every vertex
    // is reachable from all four of its sites, so it will be proposed several times and deduplicated
    // by its canonical site tuple.
    var vertexLookup: [SKApolloniusSiteTuple: Int] = [:]
    let emptinessTolerance = 1.0e-7
    
    // Quadruples already solved, keyed by their canonical form, from which the lattice translation has been
    // removed. A quadruple is reached from each of its four sites, and in the sweep below from every box that
    // its vertex is near, so most of the ones proposed have been solved already. What a quadruple gives is
    // fixed by the shape it makes: translating it translates its tangent spheres, which are wrapped back into
    // the cell and canonicalised to the same keys, and leaves the emptiness of those spheres alone. So a
    // quadruple seen a second time can add nothing, and both the tangency and the certification of it are
    // spared.
    var solvedQuadruples = Set<SKApolloniusSiteTuple>()
    func quadrupleIsNew(indices: [Int], images: [SIMD3<Int32>]) -> Bool
    {
      let result = skCanonicalTuple(indices: indices, images: images, count: 4)
      return solvedQuadruples.insert(result.key).inserted
    }
    
    for i in 0..<siteCount
    {
      let neighbours = adjacency[i]
      let count = neighbours.count
      let centreI = grid.positions[i]
      
      if count < 3
      {
        continue
      }
      for p in 0..<count
      {
        for q in (p + 1)..<count
        {
          for r in (q + 1)..<count
          {
            let siteIndices = [i, neighbours[p].0, neighbours[q].0, neighbours[r].0]
            let siteImages = [SIMD3<Int32>(), neighbours[p].1, neighbours[q].1, neighbours[r].1]
            
            if !quadrupleIsNew(indices: siteIndices, images: siteImages)
            {
              continue
            }
            
            var centres = [SIMD3<Double>](repeating: SIMD3<Double>(), count: 4)
            var tangentRadii = [0.0, 0.0, 0.0, 0.0]
            centres[0] = centreI
            tangentRadii[0] = radii[i]
            for s in 1..<4
            {
              centres[s] = grid.positions[siteIndices[s]] + unitCell * SIMD3<Double>(siteImages[s])
              tangentRadii[s] = radii[siteIndices[s]]
            }
            
            for sphere in SKApolloniusAlgebra.tangentSpheresOf(centres: centres, radii: tangentRadii,
                                                               allowNegativeRadius: allowNegativeRadius)
            {
              storeCertifiedVertex(unitCell: unitCell,
                                   inverseCell: inverseCell,
                                   radii: radii,
                                   maximumRadius: maximumRadius,
                                   emptyRadiusBound: emptyRadiusBound,
                                   emptinessTolerance: emptinessTolerance,
                                   grid: grid,
                                   siteIndices: siteIndices,
                                   siteImages: siteImages,
                                   centres: centres,
                                   sphere: sphere,
                                   diagram: &diagram,
                                   vertexLookup: &vertexLookup)
            }
          }
        }
      }
    }
    
    func buildTripleLookup() -> [SKApolloniusSiteTuple: [IncidentBranch]]
    {
      var lookup: [SKApolloniusSiteTuple: [IncidentBranch]] = [:]
      for v in 0..<diagram.vertices.count
      {
        let vertex = diagram.vertices[v]
        for b in 0..<vertex.branches.count
        {
          var indices = [0, 0, 0]
          var images = [SIMD3<Int32>(), SIMD3<Int32>(), SIMD3<Int32>()]
          for s in 0..<3
          {
            let local = skTripleGet(vertex.branches[b].sites, s)
            indices[s] = vertex.siteIndices[local]
            images[s] = vertex.siteImages[local]
          }
          let result = skCanonicalTuple(indices: indices, images: images, count: 3)
          lookup[result.key, default: []].append(IncidentBranch(vertex: v, branch: b, offset: result.appliedOffset))
        }
      }
      return lookup
    }
    
    // Completeness pass, following the vertex location of Wang et al., Section 5.2. Enumerating
    // candidate quadruples from radical adjacency is a heuristic and does miss vertices. Rather than
    // widen it, which converges slowly and costs cubically, the cell is swept: a box is subdivided
    // until few enough sites can be nearest anywhere inside it to take those sites in quadruples, and
    // every quadruple of them is solved. Since every vertex has four nearest sites, and the sites that
    // can be nearest in a box containing it include them, the quadruple that gives it is among those
    // solved, so no vertex can escape the sweep whenever the box holding it is finished. Boxes near a
    // face or an edge of the diagram come down to two or three sites and cost nothing, which is what
    // keeps the refinement local.
    //
    // The sweep also collects the triples it passes, which is how the trisectors that carry no vertex are
    // later found: they cannot be reached from the vertices, so they need a source of candidates that
    // does not depend on vertices existing.
    var candidateTriples = Set<SKApolloniusSiteTuple>()
    sweepCell(unitCell: unitCell,
              inverseCell: inverseCell,
              perpendicularWidths: perpendicularWidths,
              radii: radii,
              maximumRadius: maximumRadius,
              emptyRadiusBound: emptyRadiusBound,
              emptinessTolerance: emptinessTolerance,
              allowNegativeRadius: allowNegativeRadius,
              grid: grid,
              diagram: &diagram,
              vertexLookup: &vertexLookup,
              solvedQuadruples: &solvedQuadruples,
              candidateTriples: &candidateTriples)
    
    // Cotangent sets, and the branches that follow from them.
    //
    // A sphere touching more than four sites is one vertex of the diagram belonging to all of them, but its
    // tangency is satisfied by each quadruple drawn from the set, so the two passes above have constructed
    // it once per quadruple. Those copies sit at the same point and are gathered here into the single vertex
    // they are, carrying the union of their sites. Nothing else can coincide: the radius of a certified
    // tangent sphere is the clearance at its centre, so its centre determines it, and two vertices at one
    // point can only be one vertex found twice.
    //
    // Coincidence is judged on the minimum image, since a vertex on a cell face may be wrapped to either
    // side of it. Which copies to compare comes from a grid of the tolerance's own size laid over the cell:
    // a copy can only coincide with one in its own cell of that grid or in a neighbouring one, and the cells
    // wrap, so a vertex on a face of the unit cell meets the copies of it that came out on the far side. Which
    // matters because a degenerate configuration can produce a hundred copies of one vertex and there is no
    // bound on how many: comparing the copies with one another would be quadratic in a quantity that is not
    // the size of the answer.
    mergeCotangentVertices(unitCell: unitCell,
                           inverseCell: inverseCell,
                           perpendicularWidths: perpendicularWidths,
                           grid: grid,
                           diagram: &diagram)
    
    let tripleLookup = buildTripleLookup()
    pairEdges(unitCell: unitCell,
              radii: radii,
              grid: grid,
              tripleLookup: tripleLookup,
              diagram: &diagram)
    
    // Trisectors that carry no vertex.
    //
    // Everything above reaches the diagram through its vertices, so a trisector on which no fourth site
    // ever intrudes is invisible to it: there is no vertex to start from. Such a curve is closed, and it
    // is a real Apollonius edge, a ring-shaped channel whose narrowest point is a bottleneck a probe must
    // pass. Wang et al. describe them in Sections 4.2 and 5.5 and close the gap by replicating the
    // offending site into four perturbed copies, which reintroduces vertices artificially. They are found
    // directly here instead, by sweeping the clearance along each candidate trisector: the sweep decides
    // whether the curve is bounded, and where it is bounded it also traverses it, so the same pass proves
    // the curve closed, proves no site intrudes, and measures the bottleneck and length.
    //
    // The widest clearance each ring reaches is kept alongside it: together with the bottleneck it gives the
    // band of clearances the ring occupies, which is what decides later whether the ring bounds a face of
    // its own or is a hole in a larger one.
    var ringTopClearance: [Int: Double] = [:]
    recoverRings(unitCell: unitCell,
                 inverseCell: inverseCell,
                 radii: radii,
                 maximumRadius: maximumRadius,
                 emptyRadiusBound: emptyRadiusBound,
                 allowNegativeRadius: allowNegativeRadius,
                 grid: grid,
                 candidateTriples: candidateTriples,
                 tripleLookup: tripleLookup,
                 diagram: &diagram,
                 ringTopClearance: &ringTopClearance)
    
    assembleFacesAndCells(unitCell: unitCell,
                          radii: radii,
                          grid: grid,
                          siteCount: siteCount,
                          ringTopClearance: ringTopClearance,
                          diagram: &diagram)
    
    verifyDiagram(unitCell: unitCell,
                  inverseCell: inverseCell,
                  perpendicularWidths: perpendicularWidths,
                  diagram: &diagram)
    
    return diagram
  }
  
  static func storeCertifiedVertex(unitCell: double3x3,
                                   inverseCell: double3x3,
                                   radii: [Double],
                                   maximumRadius: Double,
                                   emptyRadiusBound: Double,
                                   emptinessTolerance: Double,
                                   grid: SKApolloniusSiteGrid,
                                   siteIndices: [Int],
                                   siteImages: [SIMD3<Int32>],
                                   centres: [SIMD3<Double>],
                                   sphere: SKApolloniusTangentSphere,
                                   diagram: inout SKApolloniusDiagram,
                                   vertexLookup: inout [SKApolloniusSiteTuple: Int])
  {
    if sphere.radius > emptyRadiusBound
    {
      return
    }
    
    let wrappedCentre = unitCell * skFract(inverseCell * sphere.centre)
    let latticeShift = wrappedCentre - sphere.centre
    if grid.intrudes(wrappedCentre: wrappedCentre, radius: sphere.radius, radii: radii,
                     maximumRadius: maximumRadius, tolerance: emptinessTolerance)
    {
      return
    }
    
    let shiftFractional = inverseCell * latticeShift
    let shift = SIMD3<Int32>(Int32(llround(shiftFractional.x)),
                             Int32(llround(shiftFractional.y)),
                             Int32(llround(shiftFractional.z)))
    var shiftedImages = [SIMD3<Int32>](repeating: SIMD3<Int32>(), count: 4)
    for s in 0..<4
    {
      shiftedImages[s] = SIMD3<Int32>(siteImages[s].x + shift.x,
                                      siteImages[s].y + shift.y,
                                      siteImages[s].z + shift.z)
    }
    
    var permutation: [Int]? = [0, 0, 0, 0]
    var key = skCanonicalTuple(indices: siteIndices, images: shiftedImages, count: 4, permutation: &permutation).key
    var shiftedCentres = [SIMD3<Double>](repeating: SIMD3<Double>(), count: 4)
    for s in 0..<4
    {
      shiftedCentres[s] = centres[s] + latticeShift
    }
    key.orientation = skTangencyOrientation(centre: wrappedCentre, radius: sphere.radius,
                                            siteCentres: shiftedCentres, permutation: permutation!)
    if vertexLookup[key] != nil
    {
      return
    }
    
    // Branches are left until the cotangent sets are known, since a vertex found here as a
    // quadruple may turn out to be part of a larger set and its edges depend on the whole of it.
    vertexLookup[key] = diagram.vertices.count
    diagram.vertices.append(SKApolloniusVertex(position: wrappedCentre,
                                               radius: sphere.radius,
                                               siteIndices: siteIndices,
                                               siteImages: shiftedImages,
                                               branches: []))
  }
  
  // `nearby` is the list of the box the quadruple came from, which is at hand and in cache. Nearly every
  // quadruple proposed meets at no vertex, and the site that spoils it is usually one of these, so trying
  // them before the grid is what most candidates cost in total. It is only a shortcut: a candidate that
  // survives it is still certified against everything.
  static func certifyAndStore(unitCell: double3x3,
                              inverseCell: double3x3,
                              radii: [Double],
                              maximumRadius: Double,
                              emptyRadiusBound: Double,
                              emptinessTolerance: Double,
                              allowNegativeRadius: Bool,
                              grid: SKApolloniusSiteGrid,
                              quadIndices: [Int],
                              quadImages: [SIMD3<Int32>],
                              nearby: [CandidateSite],
                              diagram: inout SKApolloniusDiagram,
                              vertexLookup: inout [SKApolloniusSiteTuple: Int],
                              solvedQuadruples: inout Set<SKApolloniusSiteTuple>)
  {
    let result = skCanonicalTuple(indices: quadIndices, images: quadImages, count: 4)
    if !solvedQuadruples.insert(result.key).inserted
    {
      return
    }
    
    var quadCentres = [SIMD3<Double>](repeating: SIMD3<Double>(), count: 4)
    var quadRadii = [0.0, 0.0, 0.0, 0.0]
    for s in 0..<4
    {
      quadCentres[s] = grid.positions[quadIndices[s]] + unitCell * SIMD3<Double>(quadImages[s])
      quadRadii[s] = radii[quadIndices[s]]
    }
    
    for sphere in SKApolloniusAlgebra.tangentSpheresOf(centres: quadCentres, radii: quadRadii,
                                                       allowNegativeRadius: allowNegativeRadius)
    {
      if sphere.radius > emptyRadiusBound
      {
        continue
      }
      
      var spoiled = false
      var s = 0
      while s < nearby.count && !spoiled
      {
        spoiled = simd_length(sphere.centre - nearby[s].position) <
                  radii[nearby[s].index] + sphere.radius - emptinessTolerance
        s += 1
      }
      if spoiled
      {
        continue
      }
      
      storeCertifiedVertex(unitCell: unitCell,
                           inverseCell: inverseCell,
                           radii: radii,
                           maximumRadius: maximumRadius,
                           emptyRadiusBound: emptyRadiusBound,
                           emptinessTolerance: emptinessTolerance,
                           grid: grid,
                           siteIndices: quadIndices,
                           siteImages: quadImages,
                           centres: quadCentres,
                           sphere: sphere,
                           diagram: &diagram,
                           vertexLookup: &vertexLookup)
    }
  }
  
  static func sweepCell(unitCell: double3x3,
                        inverseCell: double3x3,
                        perpendicularWidths: SIMD3<Double>,
                        radii: [Double],
                        maximumRadius: Double,
                        emptyRadiusBound: Double,
                        emptinessTolerance: Double,
                        allowNegativeRadius: Bool,
                        grid: SKApolloniusSiteGrid,
                        diagram: inout SKApolloniusDiagram,
                        vertexLookup: inout [SKApolloniusSiteTuple: Int],
                        solvedQuadruples: inout Set<SKApolloniusSiteTuple>,
                        candidateTriples: inout Set<SKApolloniusSiteTuple>)
  {
    // Wang et al. describe a cube carrying the sites that may dominate part of it, and reach that set by
    // a Dijkstra-like propagation over cubes through a queue of distance events. What matters about the
    // propagation is that a cube is told which sites to reckon with by its parent rather than by a fresh
    // search: a box lies inside its parent, so the sites that concern it are among those that concerned
    // the parent, and the whole sweep then costs one distance per site per box instead of a range query
    // per box. The queue itself is unnecessary, since a box knows its own parent.
    //
    // For the parent's list to answer for the child it has to be drawn a little wider than the test the
    // child applies to it, and the margin that closes is four times the circumradius. Writing d_i for the
    // clearance to site i and S(c, r, a) for {i : d_i(c) <= min_j d_j(c) + a r}, the clearance is
    // 1-Lipschitz, so for a child of centre c' and circumradius r/2 inside a parent of centre c and
    // circumradius r,
    //
    //     i in S(c', r/2, 4)  =>  d_i(c) <= d_i(c') + r <= min_j d_j(c') + 2r + r <= min_j d_j(c) + 4r,
    //
    // that is S(c', r/2, 4) is contained in S(c, r, 4). The margin four is the fixed point of that
    // recursion and so is the one that lets the lists nest all the way down. Theorem 6 needs only
    // S(c, r, 2) to decide the box, which is read off the wider list at no cost.
    //
    // The list belongs to the level rather than to the box. All eight children of a box reckon with the
    // same sites, and the boxes are taken depth first, so while a box of some level is being processed no
    // other box of that level has been reached and the one list per level is the only one any of them
    // needs. That is what keeps the sweep free of allocation: a box costs one distance per site on its
    // list and nothing else.
    // A box is its corner and its level, since every box of a level has the same size: the size and the
    // circumradius that go with it are worked out once per level rather than once per box. It also carries
    // how many sites could be nearest in its parent, which is what tells it whether splitting is achieving
    // anything.
    
    // Half the longest diagonal, the radius of the sphere about the centre that encloses the box.
    func circumradius(_ sizeFractional: SIMD3<Double>) -> Double
    {
      var largest = 0.0
      for sx in [-0.5, 0.5]
      {
        for sy in [-0.5, 0.5]
        {
          for sz in [-0.5, 0.5]
          {
            largest = max(largest, simd_length(unitCell * SIMD3<Double>(sx * sizeFractional.x,
                                                                       sy * sizeFractional.y,
                                                                       sz * sizeFractional.z)))
          }
        }
      }
      return largest
    }
    
    // The list a box of the coarsest level starts from, which is the only one that has to come out of the
    // grid. The query has to reach every site within 4r of the nearest one, and how far that is is not
    // known until the nearest is, so it widens until it does.
    func gatherFromGrid(centre: SIMD3<Double>, radius: Double, out: inout [CandidateSite])
    {
      out.removeAll(keepingCapacity: true)
      var searchRadius = maximumRadius + 4.0 * radius + 1.0
      var smallest = 0.0
      var found = false
      for _ in 0..<8
      {
        found = false
        smallest = Double.greatestFiniteMagnitude
        grid.forEachNear(wrappedCentre: centre, searchRadius: searchRadius)
        {
          j, image, _ in
          found = true
          smallest = min(smallest, simd_length(centre - image) - radii[j])
        }
        if found && searchRadius >= smallest + 4.0 * radius + maximumRadius
        {
          break
        }
        searchRadius = found ? (smallest + 4.0 * radius + maximumRadius + 1.0e-6) : (2.0 * searchRadius)
      }
      if !found
      {
        return
      }
      
      let threshold = smallest + 4.0 * radius
      grid.forEachNear(wrappedCentre: centre, searchRadius: searchRadius)
      {
        j, image, imageOffset in
        if simd_length(centre - image) - radii[j] <= threshold
        {
          out.append(CandidateSite(index: j, image: imageOffset, position: image))
        }
      }
    }
    
    // A floor on refinement, at a box far smaller than any site separation, so that the recursion has a
    // bound that does not depend on the sites being in any particular position. The rules below finish a
    // box long before it, and on the structures this has been run on it is never reached; it is here for
    // the configuration that would defeat them.
    let smallestBoxCircumradius = 1.0e-3
    
    // The coarsest boxes are sized by the geometry and not as a fraction of the cell, so that the list a
    // box has to reckon with is set by how the sites are packed rather than by how large the cell is.
    // Dividing the cell a fixed number of times would grow that list with the cell, which is the one way
    // this sweep could fail to be linear in the number of sites.
    let initialBoxEdge = 3.0
    let initialDivisions = SIMD3<Int32>(max(1, Int32(llround(perpendicularWidths.x / initialBoxEdge))),
                                        max(1, Int32(llround(perpendicularWidths.y / initialBoxEdge))),
                                        max(1, Int32(llround(perpendicularWidths.z / initialBoxEdge))))
    let initialSize = SIMD3<Double>(1.0 / Double(initialDivisions.x),
                                    1.0 / Double(initialDivisions.y),
                                    1.0 / Double(initialDivisions.z))
    
    var stack: [Cube] = []
    var levelReachable: [[CandidateSite]] = [[]]
    var levelSize: [SIMD3<Double>] = [initialSize]
    var levelRadius: [Double] = [circumradius(initialSize)]
    func reachLevel(_ level: Int)
    {
      while levelSize.count <= level
      {
        levelSize.append(0.5 * levelSize[levelSize.count - 1])
        levelRadius.append(0.5 * levelRadius[levelRadius.count - 1])
      }
      if levelReachable.count <= level
      {
        levelReachable.append(contentsOf: Array(repeating: [], count: level + 1 - levelReachable.count))
      }
    }
    
    for ix in Int32(0)..<initialDivisions.x
    {
      for iy in Int32(0)..<initialDivisions.y
      {
        for iz in Int32(0)..<initialDivisions.z
        {
          stack.append(Cube(originFractional: SIMD3<Double>(Double(ix) * initialSize.x,
                                                            Double(iy) * initialSize.y,
                                                            Double(iz) * initialSize.z),
                            level: 0,
                            parentNearestCount: Int.max))
        }
      }
    }
    
    var clearances: [Double] = []
    var nearestSites: [(Int, SIMD3<Int32>)] = []
    var finishedSets = Set<[Int64]>()
    
    while !stack.isEmpty
    {
      let cube = stack.removeLast()
      
      // Room for this box's own list and for the one it may write for its children, taken before either is
      // referred to so that neither reference is left dangling by the growth.
      reachLevel(cube.level + 1)
      
      let centre = unitCell * (cube.originFractional + 0.5 * levelSize[cube.level])
      let radius = levelRadius[cube.level]
      
      // A box of the coarsest level is the one that has no parent to inherit from.
      if cube.level == 0
      {
        gatherFromGrid(centre: centre, radius: radius, out: &levelReachable[0])
      }
      let reachable = levelReachable[cube.level]
      
      clearances = [Double](repeating: 0.0, count: reachable.count)
      var smallest = Double.greatestFiniteMagnitude
      for s in 0..<reachable.count
      {
        clearances[s] = simd_length(centre - reachable[s].position) - radii[reachable[s].index]
        smallest = min(smallest, clearances[s])
      }
      if reachable.isEmpty
      {
        continue
      }
      
      // Over the free region alone, a box whose clearance is negative throughout holds no vertex and no
      // point of any trisector the diagram keeps, since the clearance cannot rise by more than the
      // circumradius anywhere in the box. Such a box lies inside the sites and is not explored.
      if !allowNegativeRadius && smallest + radius < 0.0
      {
        continue
      }
      
      nearestSites.removeAll(keepingCapacity: true)
      for s in 0..<reachable.count
      {
        if clearances[s] < smallest + 2.0 * radius
        {
          nearestSites.append((reachable[s].index, reachable[s].image))
        }
      }
      
      // Where a box is down to a few possible nearest sites there is nothing left to narrow: whatever the
      // diagram does inside it, it does with those sites and no others. So the box is finished here rather
      // than refined, by taking its sites in threes and in fours.
      //
      // Every quadruple is solved, and each vertex inside the box is tangent to four sites that are nearest
      // there, so it is tangent to four of these and is among the solutions; the certification throws out
      // the quadruples that meet at no vertex of the diagram, as it does everywhere else. Every triple is
      // recorded, and a trisector inside the box likewise runs on three of these, which is what the search
      // for the closed ones later needs. And since a child box lies inside this one, the same holds of
      // anything in any of them: refining could turn up nothing that solving these does not.
      //
      // Since that argument holds of a box of any size, a box may be finished whenever finishing it is
      // cheaper than splitting it, and when to do so is a question of cost alone and not of correctness.
      // Two things answer it. One is that the box is down to few sites, eight being where the seventy
      // quadruples of eight still cost less than another level of refinement. The other is that splitting
      // the parent did not reduce the count, so splitting this box is unlikely to either. This second is
      // what a degeneracy looks like from inside the sweep: sites exactly cotangent stay cotangent
      // however far a box around them is split, and Wang et al.'s condition of refining until four sites
      // remain is precisely the one that would never be met.
      //
      // An open cavity (a MOF cage) is the large-n form of that degeneracy. Many lining atoms sit at
      // nearly equal clearance, so the nearest-site count stays large throughout the void. Refining
      // those boxes down to `smallestBoxCircumradius` fills the cavity with 8^k cells and does not
      // return. The box is therefore finished at any count once splitting has stopped helping. Quadruples
      // are still solved only up to sixteen sites, where C(16, 4) is cheap; a wider set's vertices are
      // already proposed by the radical-adjacency pass, and solving C(n, 4) of a 40-atom lining would
      // only rebuild the same cotangent vertex tens of thousands of times. Triples are recorded at any
      // count, which is what the vertexless-loop search needs.
      let fewSites = 8
      let affordableSites = 16
      let splittingIsHelping = nearestSites.count < cube.parentNearestCount
      if nearestSites.count <= fewSites || radius < smallestBoxCircumradius || !splittingIsHelping
      {
        if nearestSites.count > fewSites
        {
          diagram.verification.degenerateSweepBoxes += 1
        }
        
        if nearestSites.count >= 3
        {
          // Boxes far outnumber the sets of sites they finish with: the boxes along one edge of the diagram
          // are finished by the same three sites, those around one vertex by the same four, and a box in one
          // corner of the cell by the same set as its periodic twin in another. So the set is asked about
          // before it is worked with, and only a set not seen before is taken in threes and fours. What the
          // set is asked in is its canonical form, sorted and with the lattice translation removed, which is
          // what makes the twins the same set.
          nearestSites.sort(by: skSiteImageLess)
          let base = nearestSites[0].1
          var finishedKey: [Int64] = []
          finishedKey.reserveCapacity(nearestSites.count * 4)
          for pair in nearestSites
          {
            finishedKey.append(Int64(pair.0))
            finishedKey.append(Int64(pair.1.x - base.x))
            finishedKey.append(Int64(pair.1.y - base.y))
            finishedKey.append(Int64(pair.1.z - base.z))
          }
          if !finishedSets.insert(finishedKey).inserted
          {
            continue
          }
          
          let sites = nearestSites
          for i in 0..<sites.count
          {
            for j in (i + 1)..<sites.count
            {
              for k in (j + 1)..<sites.count
              {
                let tripleIndices = [sites[i].0, sites[j].0, sites[k].0]
                let tripleImages = [sites[i].1, sites[j].1, sites[k].1]
                candidateTriples.insert(skCanonicalTuple(indices: tripleIndices, images: tripleImages, count: 3).key)
                
                if sites.count <= affordableSites
                {
                  for l in (k + 1)..<sites.count
                  {
                    certifyAndStore(unitCell: unitCell,
                                    inverseCell: inverseCell,
                                    radii: radii,
                                    maximumRadius: maximumRadius,
                                    emptyRadiusBound: emptyRadiusBound,
                                    emptinessTolerance: emptinessTolerance,
                                    allowNegativeRadius: allowNegativeRadius,
                                    grid: grid,
                                    quadIndices: [sites[i].0, sites[j].0, sites[k].0, sites[l].0],
                                    quadImages: [sites[i].1, sites[j].1, sites[k].1, sites[l].1],
                                    nearby: reachable,
                                    diagram: &diagram,
                                    vertexLookup: &vertexLookup,
                                    solvedQuadruples: &solvedQuadruples)
                  }
                }
              }
            }
          }
        }
        continue
      }
      
      // The sites the children reckon with, which are those on this box's list that they can still be
      // concerned by, written to the level below for all eight of them to read.
      var childReachable: [CandidateSite] = []
      for s in 0..<reachable.count
      {
        if clearances[s] <= smallest + 4.0 * radius
        {
          childReachable.append(reachable[s])
        }
      }
      levelReachable[cube.level + 1] = childReachable
      
      let half = levelSize[cube.level + 1]
      for ix in 0..<2
      {
        for iy in 0..<2
        {
          for iz in 0..<2
          {
            stack.append(Cube(originFractional: cube.originFractional + SIMD3<Double>(Double(ix) * half.x,
                                                                                      Double(iy) * half.y,
                                                                                      Double(iz) * half.z),
                              level: cube.level + 1,
                              parentNearestCount: nearestSites.count))
          }
        }
      }
    }
    
  }
  
  static func mergeCotangentVertices(unitCell: double3x3,
                                     inverseCell: double3x3,
                                     perpendicularWidths: SIMD3<Double>,
                                     grid: SKApolloniusSiteGrid,
                                     diagram: inout SKApolloniusDiagram)
  {
    let coincidenceTolerance = 1.0e-6
    let rawCount = diagram.vertices.count
    var parent = [Int](repeating: 0, count: rawCount)
    for v in 0..<rawCount
    {
      parent[v] = v
    }
    
    var rawPositions: [SIMD3<Double>] = []
    rawPositions.reserveCapacity(rawCount)
    for vertex in diagram.vertices
    {
      rawPositions.append(vertex.position)
    }
    let groupOf = skCoincidentGroups(unitCell: unitCell, inverseCell: inverseCell,
                                     perpendicularWidths: perpendicularWidths,
                                     positions: rawPositions, tolerance: coincidenceTolerance)
    for v in 0..<rawCount
    {
      let left = skFindParent(&parent, v)
      let right = skFindParent(&parent, groupOf[v])
      if left != right
      {
        parent[left] = right
      }
    }
    
    var groups: [Int: [Int]] = [:]
    for v in 0..<rawCount
    {
      groups[skFindParent(&parent, v), default: []].append(v)
    }
    
    var merged: [SKApolloniusVertex] = []
    merged.reserveCapacity(groups.count)
    for (_, members) in groups.sorted(by: { $0.key < $1.key })
    {
      // The first member's frame is the one the set is expressed in; the others are shifted onto it, so
      // that a copy wrapped to the far face of the cell contributes its sites at the images they occupy
      // as seen from here.
      let leader = diagram.vertices[members[0]]
      var cotangent: [(Int, SIMD3<Int32>)] = []
      for member in members
      {
        let copy = diagram.vertices[member]
        let delta = inverseCell * (leader.position - copy.position)
        let shift = SIMD3<Int32>(Int32(llround(delta.x)), Int32(llround(delta.y)), Int32(llround(delta.z)))
        for s in 0..<copy.siteIndices.count
        {
          cotangent.append((copy.siteIndices[s],
                            SIMD3<Int32>(copy.siteImages[s].x + shift.x,
                                         copy.siteImages[s].y + shift.y,
                                         copy.siteImages[s].z + shift.z)))
        }
      }
      cotangent = skUniquedSiteImages(cotangent)
      
      var vertex = SKApolloniusVertex(position: leader.position, radius: leader.radius,
                                      siteIndices: [], siteImages: [], branches: [])
      var siteCentres: [SIMD3<Double>] = []
      for pair in cotangent
      {
        vertex.siteIndices.append(pair.0)
        vertex.siteImages.append(pair.1)
        siteCentres.append(grid.positions[pair.0] + unitCell * SIMD3<Double>(pair.1))
      }
      vertex.branches = skVertexBranches(centre: vertex.position, siteCentres: siteCentres,
                                         ambiguous: &diagram.verification.ambiguousBranches)
      if vertex.siteIndices.count > 4
      {
        diagram.verification.degenerateVertices += 1
      }
      merged.append(vertex)
    }
    diagram.vertices = merged
  }
  
  static func pairEdges(unitCell: double3x3,
                        radii: [Double],
                        grid: SKApolloniusSiteGrid,
                        tripleLookup: [SKApolloniusSiteTuple: [IncidentBranch]],
                        diagram: inout SKApolloniusDiagram)
  {
    enum Shape
    {
      case line     // three equal radii: the ordinary Voronoi edge, ordered along its direction
      case ellipse  // ordered by the angle round it, and closed, so its last vertex meets its first
      case branch   // one branch of a hyperbola, or a parabola, ordered across the axis of the conic
    }
    
    struct OrderedVertex
    {
      var vertex: Int
      var offset: SIMD3<Int32>
      var along: Double
      var forward: Bool
    }
    
    for (key, incident) in tripleLookup.sorted(by: { $0.key < $1.key })
    {
      if incident.count < 2
      {
        // One vertex on a triple means its arc does not end at a second vertex inside the free region.
        // The subdivision sweep above is exhaustive over vertices of non-negative clearance, so the
        // missing end cannot be one this construction was entitled to find: it is a vertex of negative
        // clearance, lying inside the spheres, at which the arc leaves the free region. Such an arc is
        // clipped rather than absent, and is counted apart from a genuine pairing failure.
        diagram.verification.truncatedTriples += 1
        continue
      }
      
      // The triple as seen in the frame of the key itself, i.e. with zero applied offset.
      var baseIndices = [0, 0, 0]
      var baseImages = [SIMD3<Int32>(), SIMD3<Int32>(), SIMD3<Int32>()]
      var baseCentres = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
      var tangentRadii = [0.0, 0.0, 0.0]
      for s in 0..<3
      {
        baseIndices[s] = Int(key.data[4 * s + 0])
        baseImages[s] = SIMD3<Int32>(Int32(key.data[4 * s + 1]),
                                     Int32(key.data[4 * s + 2]),
                                     Int32(key.data[4 * s + 3]))
        baseCentres[s] = grid.positions[baseIndices[s]] + unitCell * SIMD3<Double>(baseImages[s])
        tangentRadii[s] = radii[baseIndices[s]]
      }
      
      // A trisector carries an ordering of its points, and a vertex bounds an edge together with its
      // neighbour in that ordering, not with an arbitrary partner. What orders it is the curve's own
      // parameter, which is come by in closed form, because a trisector is always a plane conic.
      //
      // Subtracting the tangency conditions pairwise leaves, for i = 1 and 2,
      //
      //     n_i . x + d_i t = K_i,   n_i = 2(c_i - c_0),  d_i = 2(r_i - r_0),
      //                              K_i = |c_i|^2 - |c_0|^2 - r_i^2 + r_0^2,
      //
      // one equation for each pair, linear in the position x and in the clearance t alike. Unless all three
      // radii are alike, t can be eliminated between the two, and what is left is a single linear equation in
      // x: the plane the curve lies in. Within that plane t is an affine function of position, so what remains
      // of the tangency to site 0, |x - c_0| = r_0 + t, is a quadratic. Laying the plane's first axis along the
      // gradient of t leaves that quadratic already in principal position, with coefficients 1 - g^2 and 1 for
      // g the size of the gradient, so there is no eigenproblem to solve: the conic is an ellipse for g below
      // one and the branch of a hyperbola for g above it, and either way its own parameter is at hand.
      //
      // Nothing in this is a special arrangement to be recognised, which is the point of doing it this way.
      // Collinear centres are g = 0: the clearance does not vary within the plane, the ellipse is a circle,
      // and the angle round it orders the vertices. That is the arrangement no ordering by clearance can
      // handle, since the clearance is the same at every point of it. Nearly collinear centres are a small g
      // and a nearly round ellipse, ordered by the very same formula, so nothing turns on how nearly collinear
      // they are, which is what a threshold on collinearity would have turned on. Radii nearly alike are a
      // large g and a nearly straight branch, and again the same formula, approaching the straight line it
      // ought to. Only radii exactly alike stand apart, and only because there is then no t to eliminate: the
      // two equations are planes in their own right and the curve is the line they cut in.
      
      // The two pairwise equations, the one with the larger difference of radii first so that the clearance is
      // eliminated using the better conditioned of the two.
      var difference = [SIMD3<Double>(), SIMD3<Double>()]
      var radiusDifference = [0.0, 0.0]
      var constants = [0.0, 0.0]
      for i in 0..<2
      {
        difference[i] = 2.0 * (baseCentres[i + 1] - baseCentres[0])
        radiusDifference[i] = 2.0 * (tangentRadii[i + 1] - tangentRadii[0])
        constants[i] = simd_dot(baseCentres[i + 1], baseCentres[i + 1]) -
                       simd_dot(baseCentres[0], baseCentres[0]) - tangentRadii[i + 1] * tangentRadii[i + 1] +
                       tangentRadii[0] * tangentRadii[0]
      }
      if abs(radiusDifference[1]) > abs(radiusDifference[0])
      {
        difference.swapAt(0, 1)
        radiusDifference.swapAt(0, 1)
        constants.swapAt(0, 1)
      }
      
      var shape = Shape.line
      var lineDirection = SIMD3<Double>()
      var planeOrigin = SIMD3<Double>()
      var firstAxis = SIMD3<Double>()
      var secondAxis = SIMD3<Double>()
      var centreOffset = 0.0
      var firstSemiAxis = 0.0
      var secondSemiAxis = 0.0
      // The clearance is affine along the first axis, t = originClearance + rate * u, which is what makes
      // the bottleneck of an arc a matter of the least u it reaches and no search at all.
      var rate = 0.0
      var originClearance = 0.0
      var reach = 0.0
      var flattening = 0.0
      var extent = 0.0
      var heightSquared = 0.0
      
      let radiusScale = max(max(tangentRadii[0], tangentRadii[1]), max(tangentRadii[2], 1.0))
      if abs(radiusDifference[0]) < 1.0e-14 * radiusScale
      {
        lineDirection = simd_cross(difference[0], difference[1])
        let straightness = simd_length(difference[0]) * simd_length(difference[1])
        if simd_length(lineDirection) < 1.0e-12 * straightness
        {
          // Equal radii on collinear centres: the two planes are parallel and there is no curve to order.
          diagram.verification.unpairedTriples += 1
          continue
        }
        lineDirection = lineDirection / simd_length(lineDirection)
      }
      else
      {
        var planeNormal = radiusDifference[0] * difference[1] - radiusDifference[1] * difference[0]
        let planeScale = abs(radiusDifference[0]) * simd_length(difference[1]) +
                         abs(radiusDifference[1]) * simd_length(difference[0])
        if simd_length(planeNormal) < 1.0e-12 * planeScale
        {
          // The two equations say the same thing, so the points of equal clearance are a surface rather than
          // a curve and there is no ordering to make. No vertex can arise on such a triple to begin with.
          diagram.verification.unpairedTriples += 1
          continue
        }
        let planeConstant = (radiusDifference[0] * constants[1] - radiusDifference[1] * constants[0]) /
                            simd_length(planeNormal)
        planeNormal = planeNormal / simd_length(planeNormal)
        
        // The plane, taken with its origin at the point of it nearest site 0, so that the offset from that
        // site is along the normal and drops out of the conic's linear terms.
        planeOrigin = baseCentres[0] + (planeConstant - simd_dot(planeNormal, baseCentres[0])) * planeNormal
        let fromSite = planeOrigin - baseCentres[0]
        
        let gradient = -(difference[0] - simd_dot(difference[0], planeNormal) * planeNormal) / radiusDifference[0]
        rate = simd_length(gradient)
        if rate > 0.0
        {
          firstAxis = gradient / rate
        }
        else
        {
          firstAxis = simd_cross(planeNormal, (abs(planeNormal.x) < 0.9) ? SIMD3<Double>(1.0, 0.0, 0.0)
                                                                          : SIMD3<Double>(0.0, 1.0, 0.0))
        }
        firstAxis = firstAxis / simd_length(firstAxis)
        secondAxis = simd_cross(planeNormal, firstAxis)
        
        originClearance = (constants[0] - simd_dot(difference[0], planeOrigin)) / radiusDifference[0]
        reach = tangentRadii[0] + originClearance
        heightSquared = simd_dot(fromSite, fromSite)
        flattening = 1.0 - rate * rate
        
        if rate < 1.0
        {
          // (1 - g^2)(u - u_c)^2 + v^2 = C, an ellipse, and a circle when the clearance does not vary at all.
          shape = .ellipse
          centreOffset = reach * rate / flattening
          extent = reach * reach / flattening - heightSquared
          if extent <= 0.0
          {
            // No real curve at all, so the vertices reported on it cannot be there.
            diagram.verification.unpairedTriples += 1
            continue
          }
          secondSemiAxis = sqrt(extent)
          firstSemiAxis = sqrt(extent / flattening)
        }
        else
        {
          // Above one the conic opens: each branch of it, and a parabola too, gives the first coordinate as a
          // function of the second, so the second orders the curve outright. Only one of the two branches can
          // be a trisector, the other being where the tangency holds with its sign reversed, so there is one
          // curve to order here as much as in the other cases.
          shape = .branch
          // The same constants as the ellipse's, and used the same way to place a point on the curve. At
          // exactly one they are not there to be had, the conic being a parabola, which is carried by its
          // own form below rather than by a case of its own.
          if abs(flattening) > 1.0e-12
          {
            centreOffset = reach * rate / flattening
            extent = reach * reach / flattening - heightSquared
          }
        }
      }
      
      var ordered: [OrderedVertex] = []
      ordered.reserveCapacity(incident.count)
      for entry in incident
      {
        // Undo the offset that canonicalisation applied, which puts every incident vertex in the
        // single frame in which they all share this copy of the triple.
        let incidentVertex = diagram.vertices[entry.vertex]
        let position = incidentVertex.position - unitCell * SIMD3<Double>(entry.offset)
        let outgoing = incidentVertex.branches[entry.branch].direction
        
        var along = 0.0
        var forward = false
        if shape == .line
        {
          along = simd_dot(position, lineDirection)
          forward = simd_dot(outgoing, lineDirection) > 0.0
        }
        else
        {
          let first = simd_dot(position - planeOrigin, firstAxis) - centreOffset
          let second = simd_dot(position - planeOrigin, secondAxis)
          let firstStep = simd_dot(outgoing, firstAxis)
          let secondStep = simd_dot(outgoing, secondAxis)
          if shape == .ellipse
          {
            // The angle of the point on the ellipse, taken on the ellipse's own scale in each direction so
            // that a flattened one is measured as soundly as a round one, and the tangent there.
            along = atan2(second / secondSemiAxis, first / firstSemiAxis)
            forward = secondSemiAxis * secondSemiAxis * first * secondStep -
                      firstSemiAxis * firstSemiAxis * second * firstStep > 0.0
          }
          else
          {
            along = second
            forward = secondStep > 0.0
          }
        }
        ordered.append(OrderedVertex(vertex: entry.vertex, offset: entry.offset, along: along, forward: forward))
      }
      if ordered.count < 2
      {
        diagram.verification.unpairedTriples += 1
        continue
      }
      ordered.sort { $0.along < $1.along }
      
      // A point of the curve at a given value of that same parameter, and the clearance there. Both are in
      // closed form: the position because the conic is in principal position in the plane's own axes, and
      // the clearance because it is affine along the first of them, t = originClearance + g u. So a sample
      // costs a cosine at worst and needs no tangency system solved for it.
      //
      // The straight line of three equal radii is the one case with no such t to be had, the clearance
      // there being the distance to a site rather than an affine function, and it is taken as it comes.
      var lineBase = SIMD3<Double>()
      var branchSign = 1.0
      let reference = ordered[0]
      let referencePosition = diagram.vertices[reference.vertex].position -
                              unitCell * SIMD3<Double>(reference.offset)
      if shape == .line
      {
        lineBase = referencePosition - reference.along * lineDirection
      }
      else if shape == .branch && abs(flattening) > 1.0e-12
      {
        // Which of the hyperbola's two branches is the trisector, the other holding the tangency with
        // its sign reversed. The whole curve is on one of them, so one vertex settles it.
        let first = simd_dot(referencePosition - planeOrigin, firstAxis) - centreOffset
        branchSign = (first < 0.0) ? -1.0 : 1.0
      }
      
      func curvePoint(_ along: Double) -> (SIMD3<Double>, Double)?
      {
        if shape == .line
        {
          let position = lineBase + along * lineDirection
          return (position, simd_length(position - baseCentres[0]) - tangentRadii[0])
        }
        
        var first = 0.0
        var second = 0.0
        if shape == .ellipse
        {
          first = firstSemiAxis * cos(along)
          second = secondSemiAxis * sin(along)
        }
        else
        {
          second = along
          if abs(flattening) > 1.0e-12
          {
            let squared = (extent - second * second) / flattening
            if squared < 0.0
            {
              return nil
            }
            first = branchSign * sqrt(squared)
          }
          else
          {
            // Equal to one the conic is a parabola, which has no centre to measure from: 2 h u = v^2 +
            // |c_0 - o|^2 - h^2 for h the reach, straight from the tangency to site 0.
            if abs(reach) < 1.0e-12
            {
              return nil
            }
            first = (second * second + heightSquared - reach * reach) / (2.0 * reach)
          }
        }
        
        let alongFirstAxis = centreOffset + first
        return (planeOrigin + alongFirstAxis * firstAxis + second * secondAxis,
                originClearance + rate * alongFirstAxis)
      }
      
      // The clearance along the curve is smooth and turns at one point at most: the far end of the ellipse,
      // the waist of the open branch, or the foot of the perpendicular from site 0 on the straight line. The
      // least clearance on an arc is therefore at one of its two ends or at that point, so putting it among
      // the samples makes the bottleneck exact instead of as fine as the sampling is.
      var turningPoints = [0.0, 0.0, 0.0]
      var turningCount = 0
      if shape == .line
      {
        turningPoints[turningCount] = simd_dot(baseCentres[0] - lineBase, lineDirection)
        turningCount += 1
      }
      else if shape == .ellipse
      {
        // Where the first coordinate is least, which is where an affine clearance is least. A circle, the
        // mark of collinear centres, has the same clearance everywhere and no turn to look for.
        if rate > 0.0
        {
          turningPoints[turningCount] = -Double.pi
          turningCount += 1
          turningPoints[turningCount] = Double.pi
          turningCount += 1
          turningPoints[turningCount] = 3.0 * Double.pi
          turningCount += 1
        }
      }
      else
      {
        turningPoints[turningCount] = 0.0
        turningCount += 1
      }
      
      // Consecutive vertices along the curve delimit its arcs, including the arc that wraps from the
      // last back to the first, which is a real edge on a closed trisector and is the pair of infinite
      // ends on an open one. An arc is in the diagram only if the edges leaving both of its endpoints
      // run into it, which is what tells the two apart and needs no classification of the curve: on an
      // open trisector the extreme vertices send their edges outwards, so the wrapping arc is refused.
      for p in 0..<ordered.count
      {
        let q = (p + 1) % ordered.count
        if q == p
        {
          continue
        }
        
        // Going from p to q runs with the ordering, so p must leave that way and q must leave against it
        // for the arc between them to be an edge.
        if !ordered[p].forward
        {
          continue
        }
        if ordered[q].forward
        {
          continue
        }
        
        let fromVertex = ordered[p].vertex
        let toVertex = ordered[q].vertex
        let fromOffset = ordered[p].offset
        let toOffset = ordered[q].offset
        
        // The two halves of a trisector that runs through a vertex are consecutive in this ordering, and
        // the arc between them is the point itself rather than an edge.
        if fromVertex == toVertex && fromOffset.x == toOffset.x && fromOffset.y == toOffset.y &&
           fromOffset.z == toOffset.z
        {
          continue
        }
        
        let toImage = SIMD3<Int32>(fromOffset.x - toOffset.x, fromOffset.y - toOffset.y, fromOffset.z - toOffset.z)
        
        let indices = (baseIndices[0], baseIndices[1], baseIndices[2])
        var images = [SIMD3<Int32>(), SIMD3<Int32>(), SIMD3<Int32>()]
        var centres = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
        for s in 0..<3
        {
          images[s] = SIMD3<Int32>(baseImages[s].x + fromOffset.x,
                                   baseImages[s].y + fromOffset.y,
                                   baseImages[s].z + fromOffset.z)
          centres[s] = grid.positions[baseIndices[s]] + unitCell * SIMD3<Double>(images[s])
        }
        
        let from = diagram.vertices[fromVertex].position
        let to = diagram.vertices[toVertex].position + unitCell * SIMD3<Double>(toImage)
        
        // Sample the arc to get its bottleneck and length, walking the curve in its own parameter: the very
        // one the vertices were ordered by, so that the samples land on the stretch of curve between them
        // and nowhere else. Cutting the chord into equal parts instead reaches only the part of a strongly
        // curved arc that projects onto the chord, and where the cutting plane meets the curve twice it
        // takes whichever point is nearer the chord, which on such an arc is the wrong one. Either way it
        // reads a bottleneck wider than the arc really has, and a probe is then let through a wall.
        //
        // The stretch of the curve inside the sites is followed too. An arc of the free space may leave
        // it in the middle and return: that is what the window between two cages is, wide at both ends
        // and shut where it passes the ring of atoms. Its bottleneck is the clearance at that ring, and
        // it is negative, which is how a passage a probe cannot pass is told apart from one it can. Stop
        // at the boundary of the free region instead and both look alike.
        // The samples are kept, since the narrowest of them is where the passage is tightest and the
        // window across it is cut there; a sample that could not be placed is left out of that choice,
        // as it is left out of the bottleneck.
        let sampleCount = 16
        var curve = [SIMD3<Double>](repeating: SIMD3<Double>(), count: sampleCount + 1 + 3)
        var clearance = [Double](repeating: 0.0, count: sampleCount + 1 + 3)
        
        // The arc runs from p to q the way the ordering runs. On the closed ellipse the last vertex meets
        // the first the long way round, which is a turn of the parameter past its wrap.
        let alongFrom = ordered[p].along
        var alongTo = ordered[q].along
        var spanned = true
        if alongTo < alongFrom
        {
          if shape == .ellipse
          {
            alongTo += 2.0 * Double.pi
          }
          else
          {
            spanned = false  // an open curve is ordered one way only, so there is no such arc to walk
          }
        }
        
        // The curve is placed in the frame of the key, and this arc in the frame where its own `from`
        // vertex sits at the position it is stored at.
        let toArcFrame = unitCell * SIMD3<Double>(fromOffset)
        
        curve[0] = from
        clearance[0] = diagram.vertices[fromVertex].radius
        curve[sampleCount] = to
        clearance[sampleCount] = diagram.vertices[toVertex].radius
        
        var length = 0.0
        var sampled = spanned
        for s in 1...sampleCount
        {
          let parameter = Double(s) / Double(sampleCount)
          let point = spanned ? curvePoint(alongFrom + parameter * (alongTo - alongFrom)) : nil
          if let point, s < sampleCount
          {
            curve[s] = point.0 + toArcFrame
            clearance[s] = point.1
          }
          else if s < sampleCount
          {
            curve[s] = from + parameter * (to - from)
            clearance[s] = Double.greatestFiniteMagnitude
            sampled = false
          }
          length += simd_length(curve[s] - curve[s - 1])
        }
        
        // The turn of the clearance, where the arc reaches it, which is the bottleneck exactly. Its own
        // neighbours are kept alongside it, since the samples no longer run in order once it is added and
        // the direction across the passage is read off them below.
        var sampleTotal = sampleCount + 1
        var turningChord = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
        if spanned
        {
          for k in 0..<turningCount
          {
            let turn = turningPoints[k]
            if turn <= alongFrom || turn >= alongTo
            {
              continue
            }
            guard let point = curvePoint(turn) else
            {
              sampled = false
              continue
            }
            let step = 1.0e-4 * max(abs(alongTo - alongFrom), 1.0e-6)
            let before = curvePoint(max(turn - step, alongFrom))
            let after = curvePoint(min(turn + step, alongTo))
            turningChord[sampleTotal - (sampleCount + 1)] =
              (before != nil && after != nil) ? after!.0 - before!.0 : to - from
            curve[sampleTotal] = point.0 + toArcFrame
            clearance[sampleTotal] = point.1
            sampleTotal += 1
          }
        }
        if !sampled
        {
          diagram.verification.unsampledArcs += 1
        }
        
        var narrowest = 0
        for s in 1..<sampleTotal
        {
          if clearance[s] < clearance[narrowest]
          {
            narrowest = s
          }
        }
        
        // The tangent of the trisector at the narrowest sample. The curve is the intersection of two
        // clearance bisectors, whose normals at a point are the differences of the unit vectors from the
        // sites to it, so the tangent is the cross product of those two differences: exact, and no more
        // work than the chord between neighbouring samples would be. It is oriented by that chord, since
        // the cross product fixes the line and not which way along it the arc runs. Where the two normals
        // are parallel, which is where the curve is not cut out by them transversally, the chord is all
        // there is.
        var chord: SIMD3<Double>
        if narrowest > sampleCount
        {
          chord = turningChord[narrowest - (sampleCount + 1)]
        }
        else
        {
          chord = curve[min(narrowest + 1, sampleCount)] - curve[narrowest > 0 ? narrowest - 1 : 0]
        }
        var fromSite = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
        for s in 0..<3
        {
          let offset = curve[narrowest] - centres[s]
          let offsetLength = simd_length(offset)
          fromSite[s] = offsetLength > 0.0 ? offset / offsetLength : SIMD3<Double>()
        }
        var tangent = simd_cross(fromSite[0] - fromSite[1], fromSite[0] - fromSite[2])
        if simd_length(tangent) < 1.0e-10
        {
          tangent = chord
        }
        if simd_dot(tangent, chord) < 0.0
        {
          tangent = -tangent
        }
        
        let tangentLength = simd_length(tangent)
        let direction = tangentLength > 0.0 ? tangent / tangentLength : SIMD3<Double>()
        
        diagram.edges.append(SKApolloniusEdge(from: fromVertex,
                                              to: toVertex,
                                              toImage: toImage,
                                              siteIndices: indices,
                                              siteImages: (images[0], images[1], images[2]),
                                              bottleneckRadius: clearance[narrowest],
                                              bottleneckPosition: curve[narrowest],
                                              bottleneckDirection: direction,
                                              length: length,
                                              isLoop: false))
      }
    }
  }
  
  static func recoverRings(unitCell: double3x3,
                           inverseCell: double3x3,
                           radii: [Double],
                           maximumRadius: Double,
                           emptyRadiusBound: Double,
                           allowNegativeRadius: Bool,
                           grid: SKApolloniusSiteGrid,
                           candidateTriples: Set<SKApolloniusSiteTuple>,
                           tripleLookup: [SKApolloniusSiteTuple: [IncidentBranch]],
                           diagram: inout SKApolloniusDiagram,
                           ringTopClearance: inout [Int: Double])
  {
    var smallestRadius = Double.greatestFiniteMagnitude
    for radius in radii
    {
      smallestRadius = min(smallestRadius, radius)
    }
    let lowestClearance = allowNegativeRadius ? -smallestRadius : 0.0
    
    let bracketSamples = 192
    let traverseSamples = 96
    let bisectionSteps = 40
    let intrusionTolerance = 1.0e-7
    
    // In the order the triples canonicalise in, so that the rings come out in an order that is the
    // structure's and not the hash table's.
    var ringCandidates = Array(candidateTriples)
    ringCandidates.sort()
    
    for key in ringCandidates
    {
      if tripleLookup[key] != nil
      {
        continue  // the curve already carries vertices
      }
      
      var indices = [0, 0, 0]
      var images = [SIMD3<Int32>(), SIMD3<Int32>(), SIMD3<Int32>()]
      var centres = [SIMD3<Double>(), SIMD3<Double>(), SIMD3<Double>()]
      var tripleRadii = [0.0, 0.0, 0.0]
      for s in 0..<3
      {
        indices[s] = Int(key.data[4 * s + 0])
        images[s] = SIMD3<Int32>(Int32(key.data[4 * s + 1]),
                                 Int32(key.data[4 * s + 2]),
                                 Int32(key.data[4 * s + 3]))
        centres[s] = grid.positions[indices[s]] + unitCell * SIMD3<Double>(images[s])
        tripleRadii[s] = radii[indices[s]]
      }
      
      // An open trisector reaches every clearance above its minimum, so if the curve still exists at the
      // largest clearance any empty sphere can have, it is not closed and is not what is sought here.
      if !SKApolloniusAlgebra.trisectorPointsAtClearance(centres: centres, radii: tripleRadii,
                                                         clearance: emptyRadiusBound).isEmpty
      {
        continue
      }
      
      // Bracket the clearances the curve occupies.
      var firstPresent = 0.0
      var lastPresent = 0.0
      var anyPresent = false
      for sample in 0...bracketSamples
      {
        let clearance = lowestClearance + (emptyRadiusBound - lowestClearance) *
                        Double(sample) / Double(bracketSamples)
        if SKApolloniusAlgebra.trisectorPointsAtClearance(centres: centres, radii: tripleRadii,
                                                          clearance: clearance).isEmpty
        {
          continue
        }
        if !anyPresent
        {
          firstPresent = clearance
        }
        lastPresent = clearance
        anyPresent = true
      }
      if !anyPresent
      {
        continue
      }
      
      // Refine the two ends of that range. They are where the branches meet, so the lower end is the
      // bottleneck of the ring and the upper end its widest point.
      var clearanceBelow = max(lowestClearance, firstPresent - (emptyRadiusBound - lowestClearance) /
                               Double(bracketSamples))
      var minimumClearance = firstPresent
      for _ in 0..<bisectionSteps
      {
        let middle = 0.5 * (clearanceBelow + minimumClearance)
        if SKApolloniusAlgebra.trisectorPointsAtClearance(centres: centres, radii: tripleRadii,
                                                          clearance: middle).isEmpty
        {
          clearanceBelow = middle
        }
        else
        {
          minimumClearance = middle
        }
      }
      var clearanceAbove = lastPresent + (emptyRadiusBound - lowestClearance) / Double(bracketSamples)
      var maximumClearance = lastPresent
      for _ in 0..<bisectionSteps
      {
        let middle = 0.5 * (maximumClearance + clearanceAbove)
        if SKApolloniusAlgebra.trisectorPointsAtClearance(centres: centres, radii: tripleRadii,
                                                          clearance: middle).isEmpty
        {
          clearanceAbove = middle
        }
        else
        {
          maximumClearance = middle
        }
      }
      if maximumClearance <= minimumClearance
      {
        continue
      }
      
      // Traverse the ring, on both branches, and reject it the moment any site is nearer than the
      // clearance the three defining sites share. Those three sit exactly at that clearance, so the
      // tolerance excludes them without having to identify them.
      var intruded = false
      var length = 0.0
      var previousOnBranch: [SIMD3<Double>?] = [nil, nil]
      var firstOnBranch = [SIMD3<Double>(), SIMD3<Double>()]
      var secondOnBranch: [SIMD3<Double>?] = [nil, nil]
      var sample = 0
      while sample <= traverseSamples && !intruded
      {
        let clearance = minimumClearance + (maximumClearance - minimumClearance) *
                        Double(sample) / Double(traverseSamples)
        let points = SKApolloniusAlgebra.trisectorPointsAtClearance(centres: centres, radii: tripleRadii,
                                                                    clearance: clearance)
        var branch = 0
        while branch < points.count && !intruded
        {
          let wrapped = unitCell * skFract(inverseCell * points[branch])
          grid.forEachNear(wrappedCentre: wrapped, searchRadius: max(0.0, clearance + maximumRadius))
          {
            j, image, _ in
            if simd_length(wrapped - image) - radii[j] < clearance - intrusionTolerance
            {
              intruded = true
            }
          }
          
          if let previous = previousOnBranch[branch]
          {
            length += simd_length(points[branch] - previous)
            if secondOnBranch[branch] == nil
            {
              secondOnBranch[branch] = points[branch]
            }
          }
          else
          {
            firstOnBranch[branch] = points[branch]
          }
          previousOnBranch[branch] = points[branch]
          branch += 1
        }
        sample += 1
      }
      if intruded
      {
        continue
      }
      
      // The two branches meet at both ends, so closing the ring joins their far ends to each other.
      if previousOnBranch[0] != nil && previousOnBranch[1] != nil
      {
        length += simd_length(previousOnBranch[0]! - previousOnBranch[1]!)
        length += simd_length(firstOnBranch[0] - firstOnBranch[1])
      }
      
      // The narrowest point of a ring is the pinch where its two branches meet, at the lowest clearance
      // it reaches. The ring runs from one branch to the other through that point, so the chord between
      // the branches just above the pinch is the direction it runs in there.
      var pinch = previousOnBranch[0] != nil ? firstOnBranch[0] : firstOnBranch[1]
      var chord = SIMD3<Double>()
      if previousOnBranch[0] != nil && previousOnBranch[1] != nil
      {
        pinch = 0.5 * (firstOnBranch[0] + firstOnBranch[1])
        if secondOnBranch[0] != nil && secondOnBranch[1] != nil
        {
          chord = secondOnBranch[0]! - secondOnBranch[1]!
        }
      }
      let chordLength = simd_length(chord)
      
      ringTopClearance[diagram.edges.count] = maximumClearance
      diagram.edges.append(SKApolloniusEdge(from: Int.max,
                                            to: Int.max,
                                            toImage: SIMD3<Int32>(),
                                            siteIndices: (indices[0], indices[1], indices[2]),
                                            siteImages: (images[0], images[1], images[2]),
                                            bottleneckRadius: minimumClearance,
                                            bottleneckPosition: pinch,
                                            bottleneckDirection: chordLength > 0.0 ? chord / chordLength : SIMD3<Double>(),
                                            length: length,
                                            isLoop: true))
      diagram.verification.vertexlessLoops += 1
    }
  }
  
  static func assembleFacesAndCells(unitCell: double3x3,
                                    radii: [Double],
                                    grid: SKApolloniusSiteGrid,
                                    siteCount: Int,
                                    ringTopClearance: [Int: Double],
                                    diagram: inout SKApolloniusDiagram)
  {
    func faceKey(owner: Int, other: Int, relativeImage: SIMD3<Int32>) -> SKApolloniusSiteTuple
    {
      var key = SKApolloniusSiteTuple()
      key.data[0] = Int64(owner)
      key.data[4] = Int64(other)
      key.data[5] = Int64(relativeImage.x)
      key.data[6] = Int64(relativeImage.y)
      key.data[7] = Int64(relativeImage.z)
      return key
    }
    
    // Group the edges by the bisector surface they lie on. That surface is not yet a face: the edges on
    // one surface can enclose several regions of it that are separate faces of the diagram (Wang et al.,
    // Section 5.4), so each group is split below into its connected parts. Which two of an edge's three
    // sites the surface belongs to is kept with it, since a ring needs to know its third site to work out
    // which region of the surface it bounds.
    var patches: [PrimitivePatch] = []
    var patchLookup: [SKApolloniusSiteTuple: Int] = [:]
    
    for e in 0..<diagram.edges.count
    {
      let edge = diagram.edges[e]
      for s in 0..<3
      {
        for o in 0..<3
        {
          if s == o
          {
            continue
          }
          let relative = SIMD3<Int32>(skTripleGet(edge.siteImages, o).x - skTripleGet(edge.siteImages, s).x,
                                      skTripleGet(edge.siteImages, o).y - skTripleGet(edge.siteImages, s).y,
                                      skTripleGet(edge.siteImages, o).z - skTripleGet(edge.siteImages, s).z)
          let key = faceKey(owner: skTripleGet(edge.siteIndices, s),
                            other: skTripleGet(edge.siteIndices, o),
                            relativeImage: relative)
          if let existing = patchLookup[key]
          {
            patches[existing].edges.append(PatchEdge(edgeIndex: e, ownerLocal: s, otherLocal: o))
          }
          else
          {
            patchLookup[key] = patches.count
            patches.append(PrimitivePatch(owner: skTripleGet(edge.siteIndices, s),
                                          other: skTripleGet(edge.siteIndices, o),
                                          relativeImage: relative,
                                          edges: [PatchEdge(edgeIndex: e, ownerLocal: s, otherLocal: o)]))
          }
        }
      }
    }
    
    // Which region of a bisector surface a ring bounds.
    //
    // A ring is a closed curve confined to the band of clearances it spans, and its own trisector is the
    // only place on the surface where the third site is exactly as near, so the parts of the surface below
    // and above that band each lie wholly on one side of the ring. The diagram keeps the side where the
    // third site is the farther one, so testing that site just outside the band settles which side that is.
    // If either part beyond the band is kept, the region next to the ring reaches past it and the ring is
    // one boundary component of a larger region, a hole punched in it. If neither is, the region is the disc
    // the ring encloses and the ring bounds a face on its own, which is the face hump of Wang et al.,
    // Section 5.5.
    func ringBoundsOwnFace(_ patchEdge: PatchEdge) -> Bool
    {
      let ring = diagram.edges[patchEdge.edgeIndex]
      guard let top = ringTopClearance[patchEdge.edgeIndex] else
      {
        return true
      }
      
      let thirdLocal = 3 - patchEdge.ownerLocal - patchEdge.otherLocal
      func centreOf(_ local: Int) -> SIMD3<Double>
      {
        return grid.positions[skTripleGet(ring.siteIndices, local)] +
               unitCell * SIMD3<Double>(skTripleGet(ring.siteImages, local))
      }
      let thirdCentre = centreOf(thirdLocal)
      let thirdRadius = radii[skTripleGet(ring.siteIndices, thirdLocal)]
      
      let margin = max(1.0e-6, 1.0e-3 * (top - ring.bottleneckRadius))
      for clearance in [ring.bottleneckRadius - margin, top + margin]
      {
        guard let point = SKApolloniusAlgebra.bisectorSheetPoint(
          firstCentre: centreOf(patchEdge.ownerLocal),
          firstRadius: radii[skTripleGet(ring.siteIndices, patchEdge.ownerLocal)],
          secondCentre: centreOf(patchEdge.otherLocal),
          secondRadius: radii[skTripleGet(ring.siteIndices, patchEdge.otherLocal)],
          clearance: clearance,
          angle: 0.0)
        else
        {
          continue
        }
        if simd_length(point - thirdCentre) - thirdRadius > clearance
        {
          return false
        }
      }
      return true
    }
    
    // Two edges of a surface belong to the same face when they meet at a vertex, so the faces are the
    // connected components of the surface's boundary. Rings meet nothing and so cannot be placed that way;
    // each is instead assigned to the region it bounds, which is either a region already found, as one more
    // boundary component of it, or a region of its own.
    for patch in patches
    {
      var parent: [Int: Int] = [:]
      for patchEdge in patch.edges
      {
        if diagram.edges[patchEdge.edgeIndex].isLoop
        {
          continue
        }
        let from = diagram.edges[patchEdge.edgeIndex].from
        let to = diagram.edges[patchEdge.edgeIndex].to
        if parent[from] == nil { parent[from] = from }
        if parent[to] == nil { parent[to] = to }
      }
      for patchEdge in patch.edges
      {
        if diagram.edges[patchEdge.edgeIndex].isLoop
        {
          continue
        }
        let left = skFindMapParent(&parent, diagram.edges[patchEdge.edgeIndex].from)
        let right = skFindMapParent(&parent, diagram.edges[patchEdge.edgeIndex].to)
        if left != right
        {
          parent[left] = right
        }
      }
      
      var componentFace: [Int: Int] = [:]
      for patchEdge in patch.edges
      {
        if diagram.edges[patchEdge.edgeIndex].isLoop
        {
          continue
        }
        let root = skFindMapParent(&parent, diagram.edges[patchEdge.edgeIndex].from)
        if let existing = componentFace[root]
        {
          diagram.faces[existing].edgeIndices.append(patchEdge.edgeIndex)
        }
        else
        {
          componentFace[root] = diagram.faces.count
          diagram.faces.append(SKApolloniusFace(site1: patch.owner,
                                                site2: patch.other,
                                                site2Image: patch.relativeImage,
                                                edgeIndices: [patchEdge.edgeIndex],
                                                isClosed: false))
        }
      }
      
      for patchEdge in patch.edges
      {
        if !diagram.edges[patchEdge.edgeIndex].isLoop
        {
          continue
        }
        
        if !componentFace.isEmpty && !ringBoundsOwnFace(patchEdge)
        {
          // A hole belongs to the region around it. Deciding which region that is only takes work when the
          // surface carries several, since then the hole is inside one of them and the others are elsewhere
          // on the same surface; that has not been seen, and rather than guess it is counted so that it
          // cannot pass unnoticed.
          if componentFace.count > 1
          {
            diagram.verification.ringsOfUncertainFace += 1
          }
          let host = componentFace.min(by: { $0.key < $1.key })!.value
          diagram.faces[host].edgeIndices.append(patchEdge.edgeIndex)
          continue
        }
        
        diagram.faces.append(SKApolloniusFace(site1: patch.owner,
                                              site2: patch.other,
                                              site2Image: patch.relativeImage,
                                              edgeIndices: [patchEdge.edgeIndex],
                                              isClosed: true))
      }
    }
    
    // A patch closes when every vertex on its boundary is met by exactly two of its edges. A ring carries no
    // vertex, so it neither satisfies nor violates that condition, and a face bounded only by rings is closed
    // by construction.
    for f in 0..<diagram.faces.count
    {
      var incidence: [Int: Int] = [:]
      for e in diagram.faces[f].edgeIndices
      {
        if diagram.edges[e].isLoop
        {
          continue
        }
        incidence[diagram.edges[e].from, default: 0] += 1
        incidence[diagram.edges[e].to, default: 0] += 1
      }
      diagram.faces[f].isClosed = !diagram.faces[f].edgeIndices.isEmpty
      for (_, degree) in incidence
      {
        if degree != 2
        {
          diagram.faces[f].isClosed = false
        }
      }
      if !diagram.faces[f].isClosed
      {
        diagram.verification.unclosedFaces += 1
      }
    }
    
    diagram.cells = (0..<siteCount).map { SKApolloniusCell(siteIndex: $0, faceIndices: [], vertexIndices: [], isEmpty: true) }
    for f in 0..<diagram.faces.count
    {
      diagram.cells[diagram.faces[f].site1].faceIndices.append(f)
      diagram.cells[diagram.faces[f].site1].isEmpty = false
    }
    for v in 0..<diagram.vertices.count
    {
      for site in diagram.vertices[v].siteIndices
      {
        diagram.cells[site].vertexIndices.append(v)
      }
    }
    for i in 0..<diagram.cells.count
    {
      diagram.cells[i].vertexIndices.sort()
      var unique: [Int] = []
      for vertex in diagram.cells[i].vertexIndices
      {
        if unique.last != vertex
        {
          unique.append(vertex)
        }
      }
      diagram.cells[i].vertexIndices = unique
    }
  }
  
  static func verifyDiagram(unitCell: double3x3,
                            inverseCell: double3x3,
                            perpendicularWidths: SIMD3<Double>,
                            diagram: inout SKApolloniusDiagram)
  {
    // Verification: a vertex carries one edge along each of its branches, four of them in the general
    // case and more where the configuration is degenerate.
    var valence = [Int](repeating: 0, count: diagram.vertices.count)
    for edge in diagram.edges
    {
      if edge.isLoop
      {
        continue  // a closed trisector has no endpoints to contribute valence to
      }
      valence[edge.from] += 1
      valence[edge.to] += 1
    }
    diagram.verification.vertexCount = diagram.vertices.count
    for v in 0..<diagram.vertices.count
    {
      if valence[v] == diagram.vertices[v].branches.count
      {
        diagram.verification.verticesOfFullValence += 1
      }
    }
    
    // Vertices left sharing a position would be a cotangent set that the gathering above failed to bring
    // together, which would leave each copy pairing along triples the others also claim. The gathering is
    // meant to make this impossible, so any survivor is a defect and is reported as one.
    var mergedPositions: [SIMD3<Double>] = []
    mergedPositions.reserveCapacity(diagram.vertices.count)
    for vertex in diagram.vertices
    {
      mergedPositions.append(vertex.position)
    }
    let coincidentWith = skCoincidentGroups(unitCell: unitCell, inverseCell: inverseCell,
                                            perpendicularWidths: perpendicularWidths,
                                            positions: mergedPositions, tolerance: 1.0e-6)
    for v in 0..<coincidentWith.count
    {
      if coincidentWith[v] != v
      {
        diagram.verification.coincidentVertices += 1
      }
    }
  }
}