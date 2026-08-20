/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import simd

public final class ProteinCatmullRomSpline: ProteinRibbonCenterlinePath
{
  private let controlPoints: [SIMD3<Double>]
  private let orientationVectors: [SIMD3<Double>]
  private let arcLengthCache: [Double]
  
  public init(controlPoints: [SIMD3<Double>], orientationVectors: [SIMD3<Double>])
  {
    precondition(controlPoints.count == orientationVectors.count)
    precondition(controlPoints.count >= 2)
    
    self.controlPoints = controlPoints
    self.orientationVectors = orientationVectors
    self.arcLengthCache = ProteinCatmullRomSpline.buildArcLengthCache(controlPoints: controlPoints)
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
    if t <= 0.0 {return controlPoints[0]}
    if t >= 1.0 {return controlPoints[controlPoints.count - 1]}
    
    let segmentCount: Int = controlPoints.count - 1
    let scaled: Double = t * Double(segmentCount)
    let segmentIndex: Int = min(Int(scaled), segmentCount - 1)
    let localU: Double = scaled - Double(segmentIndex)
    return evaluateSegmentPosition(segmentIndex: segmentIndex, u: localU)
  }
  
  public func evaluateOrientation(_ t: Double) -> SIMD3<Double>
  {
    if t <= 0.0 {return normalize(orientationVectors[0])}
    if t >= 1.0 {return normalize(orientationVectors[orientationVectors.count - 1])}
    
    let segmentCount: Int = controlPoints.count - 1
    let scaled: Double = t * Double(segmentCount)
    let segmentIndex: Int = min(Int(scaled), segmentCount - 1)
    let localU: Double = scaled - Double(segmentIndex)
    
    var orientation: SIMD3<Double> = evaluateSegmentOrientation(segmentIndex: segmentIndex, u: localU)
    let tangent: SIMD3<Double> = derivative(t)
    orientation = -cross(tangent, cross(tangent, orientation))
    let orientationLength: Double = length(orientation)
    if orientationLength > 1.0e-12
    {
      return orientation / orientationLength
    }
    return orientation
  }
  
  /// Analytic first derivative of the Catmull–Rom segment polynomial, scaled by the
  /// segment count (chain rule for the global parameter u = t * segmentCount - segmentIndex).
  public func derivative(_ t: Double) -> SIMD3<Double>
  {
    let segmentCount: Int = controlPoints.count - 1
    let clampedT: Double = min(max(t, 0.0), 1.0)
    let scaled: Double = clampedT * Double(segmentCount)
    let segmentIndex: Int = min(Int(scaled), segmentCount - 1)
    let localU: Double = scaled - Double(segmentIndex)
    
    let p0: SIMD3<Double> = controlPoint(at: segmentIndex - 1)
    let p1: SIMD3<Double> = controlPoint(at: segmentIndex)
    let p2: SIMD3<Double> = controlPoint(at: segmentIndex + 1)
    let p3: SIMD3<Double> = controlPoint(at: segmentIndex + 2)
    return Double(segmentCount) * Self.catmullRomDerivative(p0: p0, p1: p1, p2: p2, p3: p3, u: localU)
  }
  
  private func controlPoint(at index: Int) -> SIMD3<Double>
  {
    if index < 0 {return controlPoints[0]}
    if index >= controlPoints.count {return controlPoints[controlPoints.count - 1]}
    return controlPoints[index]
  }
  
  private func orientationVector(at index: Int) -> SIMD3<Double>
  {
    if index < 0 {return orientationVectors[0]}
    if index >= orientationVectors.count {return orientationVectors[orientationVectors.count - 1]}
    return orientationVectors[index]
  }
  
  private func evaluateSegmentPosition(segmentIndex: Int, u: Double) -> SIMD3<Double>
  {
    let p0: SIMD3<Double> = controlPoint(at: segmentIndex - 1)
    let p1: SIMD3<Double> = controlPoint(at: segmentIndex)
    let p2: SIMD3<Double> = controlPoint(at: segmentIndex + 1)
    let p3: SIMD3<Double> = controlPoint(at: segmentIndex + 2)
    return Self.catmullRomPoint(p0: p0, p1: p1, p2: p2, p3: p3, u: u)
  }
  
  private func evaluateSegmentOrientation(segmentIndex: Int, u: Double) -> SIMD3<Double>
  {
    let o0: SIMD3<Double> = orientationVector(at: segmentIndex - 1)
    let o1: SIMD3<Double> = orientationVector(at: segmentIndex)
    let o2: SIMD3<Double> = orientationVector(at: segmentIndex + 1)
    let o3: SIMD3<Double> = orientationVector(at: segmentIndex + 2)
    return Self.catmullRomPoint(p0: o0, p1: o1, p2: o2, p3: o3, u: u)
  }
  
  private static func catmullRomPoint(p0: SIMD3<Double>, p1: SIMD3<Double>, p2: SIMD3<Double>, p3: SIMD3<Double>, u: Double) -> SIMD3<Double>
  {
    let u2: Double = u * u
    let u3: Double = u2 * u
    let term0: SIMD3<Double> = 2.0 * p1
    let term1: SIMD3<Double> = (-p0 + p2) * u
    let term2: SIMD3<Double> = (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2
    let term3: SIMD3<Double> = (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3
    return 0.5 * (term0 + term1 + term2 + term3)
  }
  
  private static func catmullRomDerivative(p0: SIMD3<Double>, p1: SIMD3<Double>, p2: SIMD3<Double>, p3: SIMD3<Double>, u: Double) -> SIMD3<Double>
  {
    let term1: SIMD3<Double> = -p0 + p2
    let term2: SIMD3<Double> = (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * (2.0 * u)
    let term3: SIMD3<Double> = (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * (3.0 * u * u)
    return 0.5 * (term1 + term2 + term3)
  }
  
  private static func buildArcLengthCache(controlPoints: [SIMD3<Double>]) -> [Double]
  {
    let numberOfSamples: Int = max(64, controlPoints.count * 8)
    var cache: [Double] = [0.0]
    let dt: Double = 1.0 / Double(numberOfSamples)
    let segmentCount: Int = controlPoints.count - 1
    
    func point(at index: Int) -> SIMD3<Double>
    {
      if index < 0 {return controlPoints[0]}
      if index >= controlPoints.count {return controlPoints[controlPoints.count - 1]}
      return controlPoints[index]
    }
    
    func evaluateAtGlobalT(_ t: Double) -> SIMD3<Double>
    {
      if t <= 0.0 {return controlPoints[0]}
      if t >= 1.0 {return controlPoints[controlPoints.count - 1]}
      let scaled: Double = t * Double(segmentCount)
      let segmentIndex: Int = min(Int(scaled), segmentCount - 1)
      let localU: Double = scaled - Double(segmentIndex)
      return catmullRomPoint(p0: point(at: segmentIndex - 1),
                             p1: point(at: segmentIndex),
                             p2: point(at: segmentIndex + 1),
                             p3: point(at: segmentIndex + 2),
                             u: localU)
    }
    
    for i in 0..<numberOfSamples
    {
      let t1: Double = Double(i) * dt
      let t2: Double = Double(i + 1) * dt
      cache.append(cache.last! + length(evaluateAtGlobalT(t2) - evaluateAtGlobalT(t1)))
    }
    return cache
  }
}
