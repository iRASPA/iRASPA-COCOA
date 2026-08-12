/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
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

public final class ProteinBSpline
{
  private let controlPoints: [SIMD3<Double>]
  private let orientationVectors: [SIMD3<Double>]
  private let degree: Int
  private let knots: [Double]
  private let arcLengthCache: [Double]
  /// Control points of the analytic derivative curve: Q_i = degree * (P_{i+1} - P_i) / (u_{i+degree+1} - u_{i+1}).
  private let derivativeControlPoints: [SIMD3<Double>]
  /// Knot vector of the derivative curve (degree - 1): the original knots with the first and last dropped.
  private let derivativeKnots: [Double]
  
  public init(controlPoints: [SIMD3<Double>], orientationVectors: [SIMD3<Double>], degree: Int = 3)
  {
    precondition(controlPoints.count == orientationVectors.count)
    precondition(controlPoints.count >= 2)
    
    self.controlPoints = controlPoints
    self.orientationVectors = orientationVectors
    self.degree = min(degree, controlPoints.count - 1)
    self.knots = ProteinBSpline.computeKnots(numberOfControlPoints: controlPoints.count, degree: self.degree)
    (self.derivativeControlPoints, self.derivativeKnots) = ProteinBSpline.computeDerivativeCurve(controlPoints: controlPoints,
                                                                                                 degree: self.degree,
                                                                                                 knots: self.knots)
    self.arcLengthCache = ProteinBSpline.buildArcLengthCache(controlPoints: controlPoints, degree: self.degree, knots: self.knots)
  }
  
  public var numberOfControlPoints: Int
  {
    return controlPoints.count
  }
  
  public func arcLength(_ t: Double) -> Double
  {
    guard !arcLengthCache.isEmpty else {return 0.0}
    if t <= 0.0 {return 0.0}
    if t >= 1.0 {return arcLengthCache.last ?? 0.0}
    
    let index: Double = t * Double(arcLengthCache.count - 1)
    let i0: Int = Int(index)
    let i1: Int = min(i0 + 1, arcLengthCache.count - 1)
    let fraction: Double = index - Double(i0)
    return arcLengthCache[i0] * (1.0 - fraction) + arcLengthCache[i1] * fraction
  }
  
  public func parameterFromArcLength(targetLength: Double) -> Double
  {
    guard !arcLengthCache.isEmpty else {return 0.0}
    let totalLength: Double = arcLengthCache.last ?? 0.0
    if targetLength <= 0.0 {return 0.0}
    if targetLength >= totalLength {return 1.0}
    
    var low: Int = 0
    var high: Int = arcLengthCache.count - 1
    while low < high
    {
      let mid: Int = (low + high) / 2
      if arcLengthCache[mid] < targetLength
      {
        low = mid + 1
      }
      else
      {
        high = mid
      }
    }
    let index: Int = max(low, 1)
    
    let lengthBefore: Double = arcLengthCache[index - 1]
    let lengthAfter: Double = arcLengthCache[index]
    let span: Double = max(lengthAfter - lengthBefore, 1.0e-18)
    let fraction: Double = (targetLength - lengthBefore) / span
    let tBefore: Double = Double(index - 1) / Double(arcLengthCache.count - 1)
    let tAfter: Double = Double(index) / Double(arcLengthCache.count - 1)
    return tBefore + fraction * (tAfter - tBefore)
  }
  
  public func evaluate(_ t: Double) -> SIMD3<Double>
  {
    return ProteinBSpline.evaluatePoint(t: t, controlPoints: controlPoints, degree: degree, knots: knots)
  }
  
  public func evaluateOrientation(_ t: Double) -> SIMD3<Double>
  {
    if t <= 0.0 {return normalize(orientationVectors[0])}
    if t >= 1.0 {return normalize(orientationVectors[orientationVectors.count - 1])}
    
    let clampedT: Double = min(max(t, knots[degree]), knots[controlPoints.count] - 1.0e-12)
    let span: Int = ProteinBSpline.findSpan(u: clampedT, degree: degree, knots: knots, controlPointCount: controlPoints.count)
    let basis: [Double] = ProteinBSpline.basisFunctions(span: span, u: clampedT, degree: degree, knots: knots)
    
    var orientation: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    for i in 0...degree
    {
      orientation += basis[i] * orientationVectors[span - degree + i]
    }
    
    let tangent: SIMD3<Double> = derivative(t)
    orientation = -cross(tangent, cross(tangent, orientation))
    let orientationLength: Double = length(orientation)
    if orientationLength > 1.0e-12
    {
      return orientation / orientationLength
    }
    return orientation
  }
  
  /// Analytic first derivative: the derivative of a clamped B-spline of degree p is a
  /// B-spline of degree p-1 over the trimmed knot vector (Piegl & Tiller, eq. 3.4).
  public func derivative(_ t: Double) -> SIMD3<Double>
  {
    return ProteinBSpline.evaluatePoint(t: t,
                                        controlPoints: derivativeControlPoints,
                                        degree: degree - 1,
                                        knots: derivativeKnots)
  }
  
  private static func computeDerivativeCurve(controlPoints: [SIMD3<Double>],
                                             degree: Int,
                                             knots: [Double]) -> (controlPoints: [SIMD3<Double>], knots: [Double])
  {
    var derivativeControls: [SIMD3<Double>] = []
    derivativeControls.reserveCapacity(controlPoints.count - 1)
    for i in 0..<(controlPoints.count - 1)
    {
      let denominator: Double = knots[i + degree + 1] - knots[i + 1]
      if denominator > 1.0e-18
      {
        derivativeControls.append((Double(degree) / denominator) * (controlPoints[i + 1] - controlPoints[i]))
      }
      else
      {
        derivativeControls.append(SIMD3<Double>(0.0, 0.0, 0.0))
      }
    }
    let trimmedKnots: [Double] = Array(knots[1..<(knots.count - 1)])
    return (derivativeControls, trimmedKnots)
  }
  
  private static func evaluatePoint(t: Double, controlPoints: [SIMD3<Double>], degree: Int, knots: [Double]) -> SIMD3<Double>
  {
    if t <= 0.0 {return controlPoints[0]}
    if t >= 1.0 {return controlPoints[controlPoints.count - 1]}
    
    let clampedT: Double = min(max(t, knots[degree]), knots[controlPoints.count] - 1.0e-12)
    let span: Int = findSpan(u: clampedT, degree: degree, knots: knots, controlPointCount: controlPoints.count)
    let basis: [Double] = basisFunctions(span: span, u: clampedT, degree: degree, knots: knots)
    
    var point: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    for i in 0...degree
    {
      point += basis[i] * controlPoints[span - degree + i]
    }
    return point
  }
  
  /// Binary search for the knot span index such that knots[span] <= u < knots[span+1].
  private static func findSpan(u: Double, degree: Int, knots: [Double], controlPointCount: Int) -> Int
  {
    if u >= knots[controlPointCount]
    {
      return controlPointCount - 1
    }
    if u <= knots[degree]
    {
      return degree
    }
    
    var low: Int = degree
    var high: Int = controlPointCount
    var mid: Int = (low + high) / 2
    while u < knots[mid] || u >= knots[mid + 1]
    {
      if u < knots[mid]
      {
        high = mid
      }
      else
      {
        low = mid
      }
      mid = (low + high) / 2
    }
    return mid
  }
  
  /// Non-zero basis functions N_{span-degree,degree} … N_{span,degree} (Piegl & Tiller, Alg. A2.2).
  private static func basisFunctions(span: Int, u: Double, degree: Int, knots: [Double]) -> [Double]
  {
    var basis: [Double] = Array(repeating: 0.0, count: degree + 1)
    var left: [Double] = Array(repeating: 0.0, count: degree + 1)
    var right: [Double] = Array(repeating: 0.0, count: degree + 1)
    basis[0] = 1.0
    guard degree > 0 else {return basis}
    
    for j in 1...degree
    {
      left[j] = u - knots[span + 1 - j]
      right[j] = knots[span + j] - u
      var saved: Double = 0.0
      for r in 0..<j
      {
        let denom: Double = right[r + 1] + left[j - r]
        let temp: Double = abs(denom) > 1.0e-18 ? basis[r] / denom : 0.0
        basis[r] = saved + right[r + 1] * temp
        saved = left[j - r] * temp
      }
      basis[j] = saved
    }
    return basis
  }
  
  private static func computeKnots(numberOfControlPoints n: Int, degree: Int) -> [Double]
  {
    let m: Int = n + degree + 1
    var knots: [Double] = [Double](repeating: 0.0, count: m)
    for i in 0...degree
    {
      knots[i] = 0.0
    }
    if n > degree + 1
    {
      for i in (degree + 1)..<n
      {
        knots[i] = Double(i - degree) / Double(n - degree)
      }
    }
    for i in n..<m
    {
      knots[i] = 1.0
    }
    return knots
  }
  
  private static func buildArcLengthCache(controlPoints: [SIMD3<Double>], degree: Int, knots: [Double]) -> [Double]
  {
    let numberOfSamples: Int = max(64, controlPoints.count * 4)
    var cache: [Double] = [0.0]
    cache.reserveCapacity(numberOfSamples + 1)
    let dt: Double = 1.0 / Double(numberOfSamples)
    for i in 0..<numberOfSamples
    {
      let t1: Double = Double(i) * dt
      let t2: Double = Double(i + 1) * dt
      let p1: SIMD3<Double> = evaluatePoint(t: t1, controlPoints: controlPoints, degree: degree, knots: knots)
      let p2: SIMD3<Double> = evaluatePoint(t: t2, controlPoints: controlPoints, degree: degree, knots: knots)
      cache.append(cache[cache.count - 1] + length(p2 - p1))
    }
    return cache
  }
}
