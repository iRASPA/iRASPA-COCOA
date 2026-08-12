/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 P-SEA algorithm adapted from Biotite structure/sse.py (BSD-3-Clause),
 based on Labesse et al., J. Mol. Biol. 1997, 235:107-120.
 *************************************************************************************************************/

import Foundation
import simd

public enum SKPSeaSecondaryStructureAssigner
{
  public static func assign(for chain: SKStrideBackboneChain) -> [SKSecondaryStructureType]
  {
    let positions: [SIMD3<Double>?] = SKSecondaryStructureGeometry.alphaCarbonPositionsWithBreaks(from: chain)
    
    // A placeholder is inserted at every chain break so that the metric windows do not span the gap,
    // but callers index the assignment against the residues. The placeholders are dropped again so
    // that there is exactly one entry per alpha-carbon residue, as the other five assigners return.
    func perResidue(_ padded: [SKSecondaryStructureType]) -> [SKSecondaryStructureType]
    {
      return zip(positions, padded).compactMap { position, type in
        position == nil ? nil : type
      }
    }
    
    guard positions.count > 5 else
    {
      return perResidue(Array(repeating: .coil, count: positions.count))
    }
    
    let metrics: Metrics = computeMetrics(positions: positions)
    let helixMask: [Bool] = assignHelices(metrics: metrics)
    let sheetMask: [Bool] = assignStrands(metrics: metrics, positions: positions)
    return perResidue(mapToTypes(count: positions.count, helix: helixMask, sheet: sheetMask))
  }
  
  private struct Metrics
  {
    var distance2: [Double?]
    var distance3: [Double?]
    var distance4: [Double?]
    var angle: [Double?]
    var dihedral: [Double?]
  }
  
  private static func computeMetrics(positions: [SIMD3<Double>?]) -> Metrics
  {
    let count: Int = positions.count
    var metrics: Metrics = Metrics(distance2: Array(repeating: nil, count: count),
                                   distance3: Array(repeating: nil, count: count),
                                   distance4: Array(repeating: nil, count: count),
                                   angle: Array(repeating: nil, count: count),
                                   dihedral: Array(repeating: nil, count: count))
    
    for index in 1..<(count - 1)
    {
      if let p0: SIMD3<Double> = positions[index - 1],
         let p2: SIMD3<Double> = positions[index + 1]
      {
        metrics.distance2[index] = SKSecondaryStructureGeometry.distance(p0, p2)
      }
      if let p0: SIMD3<Double> = positions[index - 1],
         let p1: SIMD3<Double> = positions[index],
         let p2: SIMD3<Double> = positions[index + 1]
      {
        metrics.angle[index] = SKSecondaryStructureGeometry.angle(p0, p1, p2)
      }
    }
    
    for index in 1..<(count - 2)
    {
      if let p0: SIMD3<Double> = positions[index - 1],
         let p3: SIMD3<Double> = positions[index + 2]
      {
        metrics.distance3[index] = SKSecondaryStructureGeometry.distance(p0, p3)
      }
      if let p0: SIMD3<Double> = positions[index - 1],
         let p1: SIMD3<Double> = positions[index],
         let p2: SIMD3<Double> = positions[index + 1],
         let p3: SIMD3<Double> = positions[index + 2]
      {
        metrics.dihedral[index] = SKSecondaryStructureGeometry.torsionAngle(p0, p1, p2, p3)
      }
    }
    
    for index in 1..<(count - 3)
    {
      if let p0: SIMD3<Double> = positions[index - 1],
         let p4: SIMD3<Double> = positions[index + 3]
      {
        metrics.distance4[index] = SKSecondaryStructureGeometry.distance(p0, p4)
      }
    }
    return metrics
  }
  
  private static func assignHelices(metrics: Metrics) -> [Bool]
  {
    let count: Int = metrics.distance3.count
    var relaxedHelix: [Bool] = Array(repeating: false, count: count)
    var strictHelix: [Bool] = Array(repeating: false, count: count)
    
    for index in 0..<count
    {
      let d3InRange: Bool = inRange(metrics.distance3[index], 4.8, 5.8)
      let d4InRange: Bool = inRange(metrics.distance4[index], 5.8, 7.0)
      let angleInRange: Bool = inRange(metrics.angle[index], 77.0, 101.0)
      let dihedralInRange: Bool = inRange(metrics.dihedral[index], 30.0, 70.0)
      
      relaxedHelix[index] = d3InRange || angleInRange
      strictHelix[index] = (d3InRange && d4InRange) || (angleInRange && dihedralInRange)
    }
    
    var helixMask: [Bool] = SKSecondaryStructureGeometry.maskConsecutive(strictHelix, minimumLength: 5)
    helixMask = SKSecondaryStructureGeometry.extendRegion(base: helixMask, extensionMask: relaxedHelix)
    return helixMask
  }
  
  private static func assignStrands(metrics: Metrics, positions: [SIMD3<Double>?]) -> [Bool]
  {
    let count: Int = metrics.distance3.count
    var relaxedStrand: [Bool] = Array(repeating: false, count: count)
    var strictStrand: [Bool] = Array(repeating: false, count: count)
    
    for index in 0..<count
    {
      let d2InRange: Bool = inRange(metrics.distance2[index], 6.1, 7.3)
      let d3InRange: Bool = inRange(metrics.distance3[index], 9.0, 10.8)
      let d4InRange: Bool = inRange(metrics.distance4[index], 10.3, 13.5)
      let angleInRange: Bool = inRange(metrics.angle[index], 110.0, 138.0)
      let dihedralInRange: Bool = strandDihedralInRange(metrics.dihedral[index])
      
      relaxedStrand[index] = d3InRange
      strictStrand[index] = (d2InRange && d3InRange && d4InRange) || (angleInRange && dihedralInRange)
    }
    
    var strandMask: [Bool] = SKSecondaryStructureGeometry.maskConsecutive(strictStrand, minimumLength: 4)
    let shortStrandSeed: [Bool] = SKSecondaryStructureGeometry.maskConsecutive(strictStrand, minimumLength: 3)
    let shortStrandMask: [Bool] = maskRegionsWithContacts(positions: positions,
                                                            candidateMask: shortStrandSeed,
                                                            minimumContacts: 5,
                                                            minimumDistance: 4.2,
                                                            maximumDistance: 5.2)
    var combinedStrand: [Bool] = zip(strandMask, shortStrandMask).map{$0 || $1}
    combinedStrand = SKSecondaryStructureGeometry.extendRegion(base: combinedStrand, extensionMask: relaxedStrand)
    return combinedStrand
  }
  
  private static func maskRegionsWithContacts(positions: [SIMD3<Double>?],
                                              candidateMask: [Bool],
                                              minimumContacts: Int,
                                              minimumDistance: Double,
                                              maximumDistance: Double) -> [Bool]
  {
    guard !positions.isEmpty else {return []}
    
    let validPositions: [SIMD3<Double>] = positions.compactMap{$0}
    guard !validPositions.isEmpty else {return Array(repeating: false, count: positions.count)}
    
    var contacts: [Int] = Array(repeating: 0, count: positions.count)
    for index in positions.indices where candidateMask[index]
    {
      guard let position: SIMD3<Double> = positions[index] else {continue}
      var contactCount: Int = 0
      for other in validPositions
      {
        let separation: Double = SKSecondaryStructureGeometry.distance(position, other)
        if separation > minimumDistance && separation <= maximumDistance
        {
          contactCount += 1
        }
      }
      contacts[index] = contactCount
    }
    
    var output: [Bool] = Array(repeating: false, count: positions.count)
    var regionStart: Int? = nil
    
    for index in 0...positions.count
    {
      let inRegion: Bool = index < positions.count && candidateMask[index]
      if inRegion
      {
        if regionStart == nil {regionStart = index}
      }
      else if let start: Int = regionStart
      {
        let totalContacts: Int = contacts[start..<index].reduce(0, +)
        if totalContacts >= minimumContacts
        {
          for fillIndex in start..<index {output[fillIndex] = true}
        }
        regionStart = nil
      }
    }
    return output
  }
  
  private static func inRange(_ value: Double?, _ lower: Double, _ upper: Double) -> Bool
  {
    guard let value: Double = value else {return false}
    return value >= lower && value <= upper
  }
  
  private static func strandDihedralInRange(_ value: Double?) -> Bool
  {
    guard let value: Double = value else {return false}
    return (value >= -180.0 && value <= -125.0) || (value >= 145.0 && value <= 180.0)
  }
  
  private static func mapToTypes(count: Int, helix: [Bool], sheet: [Bool]) -> [SKSecondaryStructureType]
  {
    var assignments: [SKSecondaryStructureType] = Array(repeating: .coil, count: count)
    for index in 0..<count where helix[index]
    {
      assignments[index] = .helix
    }
    for index in 0..<count where sheet[index]
    {
      assignments[index] = .sheet
    }
    return assignments
  }
}
