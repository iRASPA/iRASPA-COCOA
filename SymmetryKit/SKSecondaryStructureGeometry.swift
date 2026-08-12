/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation
import simd

enum SKSecondaryStructureGeometry
{
  static func alphaCarbonPositions(from chain: SKStrideBackboneChain) -> [SIMD3<Double>?]
  {
    return chain.residues.filter{$0.alphaCarbon != nil}.map{$0.alphaCarbon}
  }
  
  static func alphaCarbonPositionsWithBreaks(from chain: SKStrideBackboneChain,
                                              breakDistance: Double = 4.5) -> [SIMD3<Double>?]
  {
    let residues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard !residues.isEmpty else {return []}
    
    var positions: [SIMD3<Double>?] = []
    for index in residues.indices
    {
      if index > 0,
         let previous: SIMD3<Double> = residues[index - 1].alphaCarbon,
         let current: SIMD3<Double> = residues[index].alphaCarbon,
         distance(previous, current) > breakDistance
      {
        positions.append(nil)
      }
      positions.append(residues[index].alphaCarbon)
    }
    return positions
  }
  
  static func phiPsiDegrees(for chain: SKStrideBackboneChain) -> [(phi: Double, psi: Double)]
  {
    let residues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    var angles: [(phi: Double, psi: Double)] = Array(repeating: (0.0, 0.0), count: residues.count)
    
    for index in residues.indices
    {
      guard let nitrogen: SIMD3<Double> = residues[index].nitrogen,
            let alphaCarbon: SIMD3<Double> = residues[index].alphaCarbon,
            let carbonylCarbon: SIMD3<Double> = residues[index].carbonylCarbon else {continue}
      
      if index > 0, let previousCarbon: SIMD3<Double> = residues[index - 1].carbonylCarbon
      {
        angles[index].phi = torsionAngle(previousCarbon, nitrogen, alphaCarbon, carbonylCarbon)
      }
      if index + 1 < residues.count, let nextNitrogen: SIMD3<Double> = residues[index + 1].nitrogen
      {
        angles[index].psi = torsionAngle(nitrogen, alphaCarbon, carbonylCarbon, nextNitrogen)
      }
    }
    return angles
  }
  
  struct LocalAxisFrame
  {
    var origin: SIMD3<Double>
    var direction: SIMD3<Double>
  }
  
  static func localAxisFrame(at index: Int, positions: [SIMD3<Double>]) -> LocalAxisFrame?
  {
    let windowStart: Int = index - 1
    let windowEnd: Int = index + 2
    guard windowStart >= 0, windowEnd < positions.count else {return nil}
    
    var centroid: SIMD3<Double> = .zero
    for positionIndex in windowStart...windowEnd
    {
      centroid += positions[positionIndex]
    }
    centroid /= 4.0
    
    let direction: SIMD3<Double> = positions[windowEnd] - positions[windowStart]
    let directionLength: Double = length(direction)
    guard directionLength > 1.0e-12 else {return nil}
    
    return LocalAxisFrame(origin: centroid, direction: direction / directionLength)
  }
  
  static func axisRadius(position: SIMD3<Double>, frame: LocalAxisFrame) -> Double
  {
    let vector: SIMD3<Double> = position - frame.origin
    let projected: SIMD3<Double> = vector - dot(vector, frame.direction) * frame.direction
    return length(projected)
  }
  
  static func axisTau(position: SIMD3<Double>, frame: LocalAxisFrame) -> Double
  {
    let vector: SIMD3<Double> = position - frame.origin
    let vectorLength: Double = length(vector)
    guard vectorLength > 1.0e-12 else {return 0.0}
    var scalar: Double = dot(normalize(vector), frame.direction)
    scalar = min(max(scalar, -1.0), 1.0)
    return acos(scalar) * 180.0 / Double.pi
  }
  
  static func maskConsecutive(_ mask: [Bool], minimumLength: Int) -> [Bool]
  {
    guard minimumLength > 0, !mask.isEmpty else {return []}
    var output: [Bool] = Array(repeating: false, count: mask.count)
    var startIndex: Int? = nil
    
    for index in 0..<mask.count
    {
      if mask[index]
      {
        if startIndex == nil {startIndex = index}
      }
      else if let start: Int = startIndex
      {
        if index - start >= minimumLength
        {
          for fillIndex in start..<index {output[fillIndex] = true}
        }
        startIndex = nil
      }
    }
    if let start: Int = startIndex, mask.count - start >= minimumLength
    {
      for fillIndex in start..<mask.count {output[fillIndex] = true}
    }
    return output
  }
  
  static func extendRegion(base: [Bool], extensionMask: [Bool]) -> [Bool]
  {
    guard !base.isEmpty else {return []}
    var output: [Bool] = base
    for index in base.indices where !base[index]
    {
      let leftCandidate: Bool = index > 0 && base[index - 1]
      let rightCandidate: Bool = index + 1 < base.count && base[index + 1]
      if (leftCandidate || rightCandidate) && extensionMask[index]
      {
        output[index] = true
      }
    }
    return output
  }
  
  static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double
  {
    return length(a - b)
  }
  
  static func angle(_ p0: SIMD3<Double>, _ p1: SIMD3<Double>, _ p2: SIMD3<Double>) -> Double
  {
    let vector0: SIMD3<Double> = p0 - p1
    let vector1: SIMD3<Double> = p2 - p1
    let length0: Double = length(vector0)
    let length1: Double = length(vector1)
    if length0 < 1.0e-12 || length1 < 1.0e-12 {return 0.0}
    var scalar: Double = dot(vector0, vector1) / (length0 * length1)
    scalar = min(max(scalar, -1.0), 1.0)
    return acos(scalar) * 180.0 / Double.pi
  }
  
  static func torsionAngle(_ p0: SIMD3<Double>, _ p1: SIMD3<Double>, _ p2: SIMD3<Double>, _ p3: SIMD3<Double>) -> Double
  {
    let bond0: SIMD3<Double> = p1 - p0
    let bond1: SIMD3<Double> = p2 - p1
    let bond2: SIMD3<Double> = p3 - p2
    
    var normal0: SIMD3<Double> = cross(bond0, bond1)
    var normal1: SIMD3<Double> = cross(bond1, bond2)
    let length0: Double = length(normal0)
    let length1: Double = length(normal1)
    if length0 < 1.0e-12 || length1 < 1.0e-12 {return 0.0}
    normal0 /= length0
    normal1 /= length1
    
    var scalar: Double = dot(normal0, normal1)
    scalar = min(max(scalar, -1.0 + 1.0e-6), 1.0 - 1.0e-6)
    let absoluteAngle: Double = acos(scalar) * 180.0 / Double.pi
    return dot(bond0, normal1) > 0.0 ? absoluteAngle : -absoluteAngle
  }
  
  static func normalize(_ vector: SIMD3<Double>) -> SIMD3<Double>
  {
    let lengthValue: Double = length(vector)
    guard lengthValue > 1.0e-12 else {return .zero}
    return vector / lengthValue
  }
  
  static func localHelixAxis(at index: Int, positions: [SIMD3<Double>]) -> SIMD3<Double>?
  {
    let start: Int = max(0, index - 1)
    let end: Int = min(positions.count - 1, index + 2)
    guard end > start else {return nil}
    
    var average: SIMD3<Double> = .zero
    var count: Int = 0
    for positionIndex in start...end
    {
      average += positions[positionIndex]
      count += 1
    }
    guard count >= 3 else {return nil}
    average /= Double(count)
    
    let direction: SIMD3<Double> = positions[end] - positions[start]
    let directionLength: Double = length(direction)
    guard directionLength > 1.0e-12 else {return nil}
    return normalize(direction)
  }
  
  static func helixRadius(at index: Int, positions: [SIMD3<Double>], axisOrigin: SIMD3<Double>, axis: SIMD3<Double>) -> Double
  {
    let vector: SIMD3<Double> = positions[index] - axisOrigin
    let projected: SIMD3<Double> = vector - dot(vector, axis) * axis
    return length(projected)
  }
  
  static func tauAngle(position: SIMD3<Double>, axisOrigin: SIMD3<Double>, axis: SIMD3<Double>) -> Double
  {
    let vector: SIMD3<Double> = position - axisOrigin
    let projected: SIMD3<Double> = vector - dot(vector, axis) * axis
    if length(projected) < 1.0e-12 || length(vector) < 1.0e-12 {return 0.0}
    var scalar: Double = dot(normalize(projected), normalize(vector))
    scalar = min(max(scalar, -1.0), 1.0)
    return acos(scalar) * 180.0 / Double.pi
  }
  
  static func inRange(_ value: Double, _ lower: Double, _ upper: Double) -> Bool
  {
    return value >= lower && value <= upper
  }
  
  static func inWrappedRange(_ value: Double, _ lower: Double, _ upper: Double) -> Bool
  {
    if upper > 180.0 && value < 0.0
    {
      return value + 360.0 >= lower && value + 360.0 <= upper
    }
    return value >= lower && value <= upper
  }
  
  static func acutePeptidePlaneAngle(firstNitrogen: SIMD3<Double>,
                                     firstAlphaCarbon: SIMD3<Double>,
                                     firstCarbonylCarbon: SIMD3<Double>,
                                     secondNitrogen: SIMD3<Double>,
                                     secondAlphaCarbon: SIMD3<Double>,
                                     secondCarbonylCarbon: SIMD3<Double>) -> Double
  {
    let firstNormal: SIMD3<Double> = normalize(cross(firstAlphaCarbon - firstNitrogen,
                                                      firstCarbonylCarbon - firstNitrogen))
    let secondNormal: SIMD3<Double> = normalize(cross(secondAlphaCarbon - secondNitrogen,
                                                       secondCarbonylCarbon - secondNitrogen))
    var scalar: Double = abs(dot(firstNormal, secondNormal))
    scalar = min(max(scalar, -1.0), 1.0)
    return acos(scalar) * 180.0 / Double.pi
  }
}
