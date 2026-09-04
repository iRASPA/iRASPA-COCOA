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

// Sweeping the exposed part of one sphere, latitude by latitude.
//
// Ported from raspa3 `structurekit/diagrams/exact/sphere_sweep`. Three of the exact analyses need
// the part of a sphere that no other sphere covers. The surface area sweeps the boundary of the
// union of the inflated atoms. The region is a sphere less a set of spherical caps. Cut it into
// circles of latitude in a frame chosen so that no cap sits on the pole, and on each circle the
// covered part is a union of arcs, one per cap that reaches that latitude. What is left between
// them is exposed, in closed form, and the integral over latitude is smooth between the latitudes
// at which the arcs appear, vanish, or run into one another.

/// How many nodes the latitude rule uses on each half of each smooth piece. Ten integrate a
/// polynomial of degree nineteen exactly.
public let SKExactQuadratureOrder: Int = 10

/// Gaps in a circle of latitude shorter than this are dropped. They are the seams where two caps
/// meet almost tangentially.
public let SKSweepGapTolerance: Double = 1.0e-12

/// Covered has to mean covered with room to spare. A framework is symmetric, so three spheres
/// meeting in one point is the ordinary case rather than a coincidence.
public let SKCapCoverTolerance: Double = 1.0e-9

/// How long a panel of the latitude rule may be where it sits next to a pole, as a multiple of the
/// room between the piece it belongs to and that pole.
public let SKPoleClearance: Double = 4.0

/// A unit vector perpendicular to `axis`, chosen so that the cross product behind it is well conditioned.
public func SKPerpendicularTo(_ axis: SIMD3<Double>) -> SIMD3<Double>
{
  var helper = SIMD3<Double>(1.0, 0.0, 0.0)
  if abs(axis.y) < abs(axis.x)
  {
    helper = SIMD3<Double>(0.0, 1.0, 0.0)
  }
  if abs(axis.z) < min(abs(axis.x), abs(axis.y))
  {
    helper = SIMD3<Double>(0.0, 0.0, 1.0)
  }
  let perpendicular = simd_cross(helper, axis)
  let length = simd_length(perpendicular)
  return length > 0.0 ? perpendicular / length : SIMD3<Double>(1.0, 0.0, 0.0)
}

/// A polar angle folded back into [0, pi], which is where the extreme latitudes of a cap live.
public func SKFoldedPolarAngle(_ angle: Double) -> Double
{
  var wrapped = abs(angle).truncatingRemainder(dividingBy: 2.0 * Double.pi)
  if wrapped > Double.pi
  {
    wrapped = 2.0 * Double.pi - wrapped
  }
  return wrapped
}

/// The frame a sphere is swept in, given the axes of the caps covering it. Latitude slicing
/// degenerates for a cap whose axis sits on the polar axis, so the polar axis is chosen to be as
/// far as possible from every one of them. Returned as `{first, second, polar}`.
public func SKSweepFrame(_ axes: [SIMD3<Double>]) -> (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>)
{
  let candidates: [SIMD3<Double>] = [
    SIMD3<Double>(1.0, 2.0, 3.0),
    SIMD3<Double>(-3.0, 1.0, 2.0),
    SIMD3<Double>(2.0, -3.0, 1.0),
    SIMD3<Double>(3.0, 2.0, -1.0),
    SIMD3<Double>(1.0, -3.0, -2.0),
    SIMD3<Double>(-2.0, 3.0, -1.0)
  ]
  
  var polarAxis = simd_normalize(candidates[0])
  var bestSeparation: Double = -1.0
  for candidate in candidates
  {
    let direction = simd_normalize(candidate)
    var separation: Double = 1.0
    for axis in axes
    {
      separation = min(separation, 1.0 - abs(simd_dot(direction, axis)))
    }
    if separation > bestSeparation
    {
      bestSeparation = separation
      polarAxis = direction
    }
    if bestSeparation > 0.01
    {
      break
    }
  }
  
  let first = SKPerpendicularTo(polarAxis)
  var second = simd_cross(polarAxis, first)
  let secondLength = simd_length(second)
  if secondLength > 0.0
  {
    second = second / secondLength
  }
  return (first, second, polarAxis)
}

/// Whether the disc of the inner cap lies within the disc of the outer, so that the inner one
/// bounds nothing of its own and covers nothing the outer does not.
public func SKDiscWithinDisc(cosineBetweenAxes: Double, cosineInner: Double, sineInner: Double, cosineOuter: Double, sineOuter: Double) -> Bool
{
  if cosineOuter > cosineInner
  {
    return false
  }
  return cosineBetweenAxes >= cosineOuter * cosineInner + sineOuter * sineInner
}

/// A point where two of the caps cross that no third one covers, with the two caps it belongs to.
public struct SKCapCrossing
{
  public var firstCircle: Int = 0
  public var secondCircle: Int = 0
  public var direction: SIMD3<Double> = SIMD3<Double>()
}

/// One cap of the sphere being swept, placed in the frame the sweep is done in.
public struct SKSweepCircle
{
  public var axis: SIMD3<Double> = SIMD3<Double>()
  public var cosineHalfAngle: Double = 0.0
  public var sineHalfAngle: Double = 0.0
  public var halfAngle: Double = 0.0
  
  public var polarAngle: Double = 0.0
  public var cosinePolar: Double = 0.0
  public var sinePolar: Double = 0.0
  public var azimuth: Double = 0.0
  public var cosineAzimuth: Double = 1.0
  public var sineAzimuth: Double = 0.0
  
  public var lowestLatitude: Double = 0.0
  public var highestLatitude: Double = 0.0
  public var reachesOverPole: Bool = false
  public var reachesOverAntipole: Bool = false
}

/// A cap from an axis and the cosine of its half angle, or nil where the cap covers none of the sphere.
public func SKMakeSweepCircle(axis: SIMD3<Double>, cosineHalfAngle: Double) -> SKSweepCircle?
{
  if cosineHalfAngle >= 1.0
  {
    return nil
  }
  
  var circle = SKSweepCircle()
  circle.axis = axis
  circle.cosineHalfAngle = cosineHalfAngle
  if cosineHalfAngle <= -1.0
  {
    circle.halfAngle = Double.pi
    circle.sineHalfAngle = 0.0
    return circle
  }
  circle.halfAngle = acos(cosineHalfAngle)
  circle.sineHalfAngle = sin(circle.halfAngle)
  return circle
}

/// Drops the caps whose discs lie inside another's.
public func SKPruneContainedDiscs(_ circles: inout [SKSweepCircle])
{
  if circles.count < 2
  {
    return
  }
  
  var redundant = [Bool](repeating: false, count: circles.count)
  for i in 0..<circles.count
  {
    for j in 0..<circles.count
    {
      if i == j || redundant[j]
      {
        continue
      }
      if SKDiscWithinDisc(cosineBetweenAxes: simd_dot(circles[i].axis, circles[j].axis),
                          cosineInner: circles[i].cosineHalfAngle,
                          sineInner: circles[i].sineHalfAngle,
                          cosineOuter: circles[j].cosineHalfAngle,
                          sineOuter: circles[j].sineHalfAngle)
      {
        redundant[i] = true
        break
      }
    }
  }
  
  circles = circles.enumerated().compactMap { redundant[$0.offset] ? nil : $0.element }
}

/// Every crossing of two of the caps that no third one covers.
public func SKUncoveredCrossings(_ circles: [SKSweepCircle]) -> [SKCapCrossing]
{
  var crossings: [SKCapCrossing] = []
  guard circles.count >= 2 else { return crossings }
  
  for j in 0..<(circles.count - 1)
  {
    for k in (j + 1)..<circles.count
    {
      let first = circles[j]
      let second = circles[k]
      let alignment = simd_dot(first.axis, second.axis)
      let denominator = 1.0 - alignment * alignment
      if denominator < 1.0e-14
      {
        continue
      }
      
      let alongFirst = (first.cosineHalfAngle - alignment * second.cosineHalfAngle) / denominator
      let alongSecond = (second.cosineHalfAngle - alignment * first.cosineHalfAngle) / denominator
      let outOfPlaneSquared = (1.0 - alongFirst * first.cosineHalfAngle - alongSecond * second.cosineHalfAngle) / denominator
      if outOfPlaneSquared <= 0.0
      {
        continue
      }
      
      let inPlane = first.axis * alongFirst + second.axis * alongSecond
      let outOfPlane = simd_cross(first.axis, second.axis) * sqrt(outOfPlaneSquared)
      for side in 0..<2
      {
        var direction = (side == 0) ? inPlane + outOfPlane : inPlane - outOfPlane
        let length = simd_length(direction)
        if length <= 0.0
        {
          continue
        }
        direction = direction / length
        
        var covered = false
        for l in 0..<circles.count
        {
          if l == j || l == k
          {
            continue
          }
          if simd_dot(direction, circles[l].axis) > circles[l].cosineHalfAngle + SKCapCoverTolerance
          {
            covered = true
            break
          }
        }
        if !covered
        {
          crossings.append(SKCapCrossing(firstCircle: j, secondCircle: k, direction: direction))
        }
      }
    }
  }
  return crossings
}

/// One exposed stretch of one circle of latitude, as the sweep hands it to whatever is being measured.
public struct SKLatitudeGap
{
  public var sineLatitude: Double = 0.0
  public var cosineLatitude: Double = 0.0
  public var weight: Double = 0.0
  
  public var begin: Double = 0.0
  public var end: Double = 0.0
  public var span: Double = 0.0
  
  public var cosineBegin: Double = 1.0
  public var sineBegin: Double = 0.0
  public var cosineEnd: Double = 1.0
  public var sineEnd: Double = 0.0
  
  public func at(frame: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>), cosineAzimuth: Double, sineAzimuth: Double) -> SIMD3<Double>
  {
    return frame.0 * (sineLatitude * cosineAzimuth) + frame.1 * (sineLatitude * sineAzimuth) + frame.2 * cosineLatitude
  }
  
  public func atBegin(frame: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>)) -> SIMD3<Double>
  {
    return at(frame: frame, cosineAzimuth: cosineBegin, sineAzimuth: sineBegin)
  }
  
  public func atEnd(frame: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>)) -> SIMD3<Double>
  {
    return at(frame: frame, cosineAzimuth: cosineEnd, sineAzimuth: sineEnd)
  }
}

/// One arc of a circle of latitude that a cap covers.
public struct SKCoveredArc
{
  public var begin: Double = 0.0
  public var end: Double = 0.0
  public var cosineBegin: Double = 1.0
  public var sineBegin: Double = 0.0
  public var cosineEnd: Double = 1.0
  public var sineEnd: Double = 0.0
}

/// Scratch the sweep needs, kept by the caller so that a structure's worth of spheres costs one
/// allocation rather than one per sphere.
public struct SKSweepWorkspace
{
  public var axes: [SIMD3<Double>] = []
  public var crossings: [SKCapCrossing] = []
  public var breakpoints: [Double] = []
  public var cutting: [Int] = []
  public var panels: [Double] = []
  public var covered: [SKCoveredArc] = []
  
  public init() {}
}

/// Gauss-Legendre nodes and weights on the unit interval, found once by Newton's method on the
/// Legendre polynomial with the usual Chebyshev starting guess.
public struct SKGaussRule
{
  public var nodes: [Double]
  public var weights: [Double]
}

private let _unitIntervalGaussRule: SKGaussRule = {
  var constructed = SKGaussRule(nodes: [Double](repeating: 0.0, count: SKExactQuadratureOrder),
                                weights: [Double](repeating: 0.0, count: SKExactQuadratureOrder))
  let order = Double(SKExactQuadratureOrder)
  for i in 0..<SKExactQuadratureOrder
  {
    var abscissa = cos(Double.pi * (Double(i) + 0.75) / (order + 0.5))
    var derivative: Double = 0.0
    for _ in 0..<100
    {
      var previous: Double = 1.0
      var current = abscissa
      if SKExactQuadratureOrder >= 2
      {
        for k in 2...SKExactQuadratureOrder
        {
          let next = ((2.0 * Double(k) - 1.0) * abscissa * current - (Double(k) - 1.0) * previous) / Double(k)
          previous = current
          current = next
        }
      }
      derivative = order * (abscissa * current - previous) / (abscissa * abscissa - 1.0)
      let step = current / derivative
      abscissa -= step
      if abs(step) < 1.0e-15
      {
        break
      }
    }
    constructed.nodes[i] = 0.5 * (1.0 - abscissa)
    constructed.weights[i] = 1.0 / ((1.0 - abscissa * abscissa) * derivative * derivative)
  }
  return constructed
}()

public func SKUnitIntervalGaussRule() -> SKGaussRule
{
  return _unitIntervalGaussRule
}

/// Places every cap in the frame, puts them in order of their own azimuth, and collects the
/// latitudes at which the exposed length of a circle of latitude stops being analytic.
public func SKPrepareSweep(_ circles: inout [SKSweepCircle],
                           frame: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>),
                           knownCrossings: [SIMD3<Double>]?,
                           work: inout SKSweepWorkspace)
{
  let firstAxis = frame.0
  let secondAxis = frame.1
  let polarAxis = frame.2
  
  work.breakpoints.removeAll(keepingCapacity: true)
  work.breakpoints.append(0.0)
  work.breakpoints.append(Double.pi)
  
  for i in 0..<circles.count
  {
    circles[i].polarAngle = acos(min(1.0, max(-1.0, simd_dot(circles[i].axis, polarAxis))))
    circles[i].cosinePolar = cos(circles[i].polarAngle)
    circles[i].sinePolar = sin(circles[i].polarAngle)
    circles[i].azimuth = atan2(simd_dot(circles[i].axis, secondAxis), simd_dot(circles[i].axis, firstAxis))
    if circles[i].azimuth < 0.0
    {
      circles[i].azimuth += 2.0 * Double.pi
    }
    circles[i].cosineAzimuth = cos(circles[i].azimuth)
    circles[i].sineAzimuth = sin(circles[i].azimuth)
    
    circles[i].lowestLatitude = SKFoldedPolarAngle(circles[i].polarAngle - circles[i].halfAngle)
    circles[i].highestLatitude = SKFoldedPolarAngle(circles[i].polarAngle + circles[i].halfAngle)
    circles[i].reachesOverPole = circles[i].polarAngle < circles[i].halfAngle
    circles[i].reachesOverAntipole = Double.pi - circles[i].polarAngle < circles[i].halfAngle
    
    work.breakpoints.append(circles[i].lowestLatitude)
    work.breakpoints.append(circles[i].highestLatitude)
  }
  
  circles.sort { $0.azimuth < $1.azimuth }
  
  if let knownCrossings
  {
    for crossing in knownCrossings
    {
      work.breakpoints.append(acos(min(1.0, max(-1.0, simd_dot(crossing, polarAxis)))))
    }
  }
  else
  {
    work.crossings = SKUncoveredCrossings(circles)
    for crossing in work.crossings
    {
      work.breakpoints.append(acos(min(1.0, max(-1.0, simd_dot(crossing.direction, polarAxis)))))
    }
  }
  
  work.breakpoints.sort()
}

/// The latitudes one smooth piece is cut at.
public func SKPanelBoundaries(begin: Double, end: Double, subdivisions: Int, cut: Bool, panels: inout [Double])
{
  let parts = max(1, subdivisions)
  panels.removeAll(keepingCapacity: true)
  for part in 0...parts
  {
    panels.append(begin + (end - begin) * Double(part) / Double(parts))
  }
  panels[0] = begin
  panels[panels.count - 1] = end
  
  if !cut
  {
    return
  }
  
  let halvingLimit = 60
  let roomBelow = begin
  for _ in 0..<halvingLimit
  {
    if panels[1] - panels[0] <= SKPoleClearance * roomBelow
    {
      break
    }
    panels.insert(0.5 * (panels[0] + panels[1]), at: 1)
  }
  
  let roomAbove = Double.pi - end
  for _ in 0..<halvingLimit
  {
    let last = panels.count - 1
    if panels[last] - panels[last - 1] <= SKPoleClearance * roomAbove
    {
      break
    }
    panels.insert(0.5 * (panels[last - 1] + panels[last]), at: last)
  }
}

private func sortByBeginning(_ arcs: inout [SKCoveredArc])
{
  if arcs.count < 2
  {
    return
  }
  for i in 1..<arcs.count
  {
    let held = arcs[i]
    var j = i
    while j > 0 && arcs[j - 1].begin > held.begin
    {
      arcs[j] = arcs[j - 1]
      j -= 1
    }
    arcs[j] = held
  }
}

/// Walks the exposed part of the sphere and calls `measure` for every exposed stretch of every
/// circle of latitude the quadrature visits. The whole of the geometry is here and none of what is
/// being measured: the area of a gap is `radius * radius * gap.sineLatitude * gap.span * gap.weight`.
public func SKSweepExposedLatitudes(_ circles: inout [SKSweepCircle],
                                    frame: (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>),
                                    knownCrossings: [SIMD3<Double>]?,
                                    subdivisions: Int,
                                    work: inout SKSweepWorkspace,
                                    measure: (SKLatitudeGap) -> Void)
{
  SKPrepareSweep(&circles, frame: frame, knownCrossings: knownCrossings, work: &work)
  
  let rule = SKUnitIntervalGaussRule()
  let twoPi = 2.0 * Double.pi
  let parts = max(1, subdivisions)
  
  var piece = 0
  while piece + 1 < work.breakpoints.count
  {
    let pieceBegin = work.breakpoints[piece]
    let pieceEnd = work.breakpoints[piece + 1]
    piece += 1
    if pieceEnd - pieceBegin < 1.0e-14
    {
      continue
    }
    
    let interior = 0.5 * (pieceBegin + pieceEnd)
    work.cutting.removeAll(keepingCapacity: true)
    var buried = false
    for i in 0..<circles.count
    {
      let circle = circles[i]
      if interior > circle.lowestLatitude && interior < circle.highestLatitude
      {
        work.cutting.append(i)
      }
      else if (interior <= circle.lowestLatitude && circle.reachesOverPole) ||
                (interior >= circle.highestLatitude && circle.reachesOverAntipole)
      {
        buried = true
        break
      }
    }
    if buried
    {
      continue
    }
    
    SKPanelBoundaries(begin: pieceBegin, end: pieceEnd, subdivisions: parts, cut: !work.cutting.isEmpty, panels: &work.panels)
    
    var panel = 0
    while panel + 1 < work.panels.count
    {
      let begin = work.panels[panel]
      let end = work.panels[panel + 1]
      panel += 1
      let middle = 0.5 * (begin + end)
      
      for half in 0..<2
      {
        let anchor = (half == 0) ? begin : end
        let span = (half == 0) ? middle - begin : end - middle
        let direction: Double = (half == 0) ? 1.0 : -1.0
        
        for node in 0..<SKExactQuadratureOrder
        {
          let parameter = rule.nodes[node]
          let latitude = anchor + direction * span * parameter * parameter
          let sineLatitude = sin(latitude)
          if sineLatitude <= 0.0
          {
            continue
          }
          
          var gap = SKLatitudeGap()
          gap.sineLatitude = sineLatitude
          gap.cosineLatitude = cos(latitude)
          gap.weight = 2.0 * span * parameter * rule.weights[node]
          
          work.covered.removeAll(keepingCapacity: true)
          for i in work.cutting
          {
            let circle = circles[i]
            let cosineHalfWidth = (circle.cosineHalfAngle - gap.cosineLatitude * circle.cosinePolar) / (sineLatitude * circle.sinePolar)
            if cosineHalfWidth >= 1.0
            {
              continue
            }
            
            let whole = cosineHalfWidth <= -1.0
            let halfWidth = whole ? Double.pi : acos(cosineHalfWidth)
            let cosineHalfWidthClamped = whole ? -1.0 : cosineHalfWidth
            let sineHalfWidth = whole ? 0.0 : sqrt(max(0.0, 1.0 - cosineHalfWidth * cosineHalfWidth))
            
            var arc = SKCoveredArc()
            arc.begin = circle.azimuth - halfWidth
            arc.end = circle.azimuth + halfWidth
            arc.cosineBegin = circle.cosineAzimuth * cosineHalfWidthClamped + circle.sineAzimuth * sineHalfWidth
            arc.sineBegin = circle.sineAzimuth * cosineHalfWidthClamped - circle.cosineAzimuth * sineHalfWidth
            arc.cosineEnd = circle.cosineAzimuth * cosineHalfWidthClamped - circle.sineAzimuth * sineHalfWidth
            arc.sineEnd = circle.sineAzimuth * cosineHalfWidthClamped + circle.cosineAzimuth * sineHalfWidth
            
            if arc.begin < 0.0
            {
              work.covered.append(SKCoveredArc(begin: arc.begin + twoPi, end: twoPi, cosineBegin: arc.cosineBegin, sineBegin: arc.sineBegin, cosineEnd: 1.0, sineEnd: 0.0))
              work.covered.append(SKCoveredArc(begin: 0.0, end: arc.end, cosineBegin: 1.0, sineBegin: 0.0, cosineEnd: arc.cosineEnd, sineEnd: arc.sineEnd))
            }
            else if arc.end > twoPi
            {
              work.covered.append(SKCoveredArc(begin: arc.begin, end: twoPi, cosineBegin: arc.cosineBegin, sineBegin: arc.sineBegin, cosineEnd: 1.0, sineEnd: 0.0))
              work.covered.append(SKCoveredArc(begin: 0.0, end: arc.end - twoPi, cosineBegin: 1.0, sineBegin: 0.0, cosineEnd: arc.cosineEnd, sineEnd: arc.sineEnd))
            }
            else
            {
              work.covered.append(arc)
            }
          }
          sortByBeginning(&work.covered)
          
          var cursor: Double = 0.0
          var cosineCursor: Double = 1.0
          var sineCursor: Double = 0.0
          for arcIndex in 0...work.covered.count
          {
            let last = (arcIndex == work.covered.count)
            let gapEnd = last ? twoPi : work.covered[arcIndex].begin
            
            if gapEnd - cursor > SKSweepGapTolerance
            {
              gap.begin = cursor
              gap.end = gapEnd
              gap.span = gapEnd - cursor
              gap.cosineBegin = cosineCursor
              gap.sineBegin = sineCursor
              gap.cosineEnd = last ? 1.0 : work.covered[arcIndex].cosineBegin
              gap.sineEnd = last ? 0.0 : work.covered[arcIndex].sineBegin
              measure(gap)
            }
            
            if !last && work.covered[arcIndex].end > cursor
            {
              cursor = work.covered[arcIndex].end
              cosineCursor = work.covered[arcIndex].cosineEnd
              sineCursor = work.covered[arcIndex].sineEnd
            }
          }
        }
      }
    }
  }
}
