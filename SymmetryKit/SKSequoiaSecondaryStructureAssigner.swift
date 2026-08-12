/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 Sequoia-inspired Cα geometry classifier (Khalife, Malliavin & Liberti, Bioinformatics Advances 2021).
 The published Sequoia method classifies residues with a message-passing neural network over a k-nearest
 neighbour Cα graph whose edge features are (normalised distance, cos Φ) with Φ reconstructed from
 inter-atomic distances via Clifford algebra. This implementation uses the same Cα-only graph features
 in a rule-based assignment suitable for ribbon visualization without bundled PyTorch model weights.
 When coordinates are available, cos Φ is computed directly from the Cα quadruple geometry.
 *************************************************************************************************************/

import Foundation
import simd

public enum SKSequoiaSecondaryStructureAssigner
{
  private static let nearestNeighborCount: Int = 2
  private static let helixScoreThreshold: Double = 0.55
  private static let sheetScoreThreshold: Double = 0.55
  private static let helixMinimumLength: Int = 4
  private static let sheetMinimumLength: Int = 3
  
  public static func assign(for chain: SKStrideBackboneChain) -> [SKSecondaryStructureType]
  {
    let segments: [[SIMD3<Double>]] = alphaCarbonSegments(from: chain)
    guard !segments.isEmpty else {return []}
    
    var assignments: [SKSecondaryStructureType] = []
    for segment in segments where !segment.isEmpty
    {
      assignments.append(contentsOf: assignSegment(positions: segment))
    }
    return assignments
  }
  
  private static func alphaCarbonSegments(from chain: SKStrideBackboneChain) -> [[SIMD3<Double>]]
  {
    let residues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard !residues.isEmpty else {return []}
    
    var segments: [[SIMD3<Double>]] = []
    var currentSegment: [SIMD3<Double>] = []
    
    for index in residues.indices
    {
      guard let alphaCarbon: SIMD3<Double> = residues[index].alphaCarbon else {continue}
      
      if index > 0,
         let previousAlphaCarbon: SIMD3<Double> = residues[index - 1].alphaCarbon,
         SKSecondaryStructureGeometry.distance(previousAlphaCarbon, alphaCarbon) > 4.5
      {
        if !currentSegment.isEmpty
        {
          segments.append(currentSegment)
          currentSegment = []
        }
      }
      currentSegment.append(alphaCarbon)
    }
    
    if !currentSegment.isEmpty
    {
      segments.append(currentSegment)
    }
    return segments
  }
  
  private static func assignSegment(positions: [SIMD3<Double>]) -> [SKSecondaryStructureType]
  {
    let count: Int = positions.count
    guard count >= 4 else {return Array(repeating: .coil, count: count)}
    
    let metrics: SegmentMetrics = computeMetrics(positions: positions)
    let helixScores: [Double] = helixScores(metrics: metrics)
    let sheetScores: [Double] = sheetScores(metrics: metrics)
    
    let helixMask: [Bool] = SKSecondaryStructureGeometry.maskConsecutive(
      helixScores.map{$0 >= helixScoreThreshold},
      minimumLength: helixMinimumLength
    )
    let sheetMask: [Bool] = SKSecondaryStructureGeometry.maskConsecutive(
      zip(sheetScores, helixScores).map{$0.0 >= sheetScoreThreshold && $0.1 < helixScoreThreshold - 0.05},
      minimumLength: sheetMinimumLength
    )
    return mapToTypes(count: count, helix: helixMask, sheet: sheetMask)
  }
  
  private struct SegmentMetrics
  {
    var sequentialDistance2: [Double?]
    var sequentialDistance3: [Double?]
    var sequentialDistance4: [Double?]
    var sequentialCosPhi: [Double?]
    var neighborCosPhiAverage: [Double?]
    var neighborDistanceAverage: [Double?]
  }
  
  private static func computeMetrics(positions: [SIMD3<Double>]) -> SegmentMetrics
  {
    let count: Int = positions.count
    var metrics: SegmentMetrics = SegmentMetrics(sequentialDistance2: Array(repeating: nil, count: count),
                                                 sequentialDistance3: Array(repeating: nil, count: count),
                                                 sequentialDistance4: Array(repeating: nil, count: count),
                                                 sequentialCosPhi: Array(repeating: nil, count: count),
                                                 neighborCosPhiAverage: Array(repeating: nil, count: count),
                                                 neighborDistanceAverage: Array(repeating: nil, count: count))
    
    for index in 1..<(count - 1)
    {
      metrics.sequentialDistance2[index] = SKSecondaryStructureGeometry.distance(positions[index - 1], positions[index + 1])
    }
    for index in 1..<(count - 2)
    {
      metrics.sequentialDistance3[index] = SKSecondaryStructureGeometry.distance(positions[index - 1], positions[index + 2])
      metrics.sequentialCosPhi[index] = pseudoDihedralCosine(positions: positions,
                                                            indices: [index - 1, index, index + 1, index + 2])
    }
    for index in 1..<(count - 3)
    {
      metrics.sequentialDistance4[index] = SKSecondaryStructureGeometry.distance(positions[index - 1], positions[index + 3])
    }
    
    for index in 0..<count
    {
      let neighbors: [(partner: Int, distance: Double)] = nearestNeighbors(for: index, positions: positions)
      guard !neighbors.isEmpty else {continue}
      
      var cosValues: [Double] = []
      var distances: [Double] = []
      for neighbor in neighbors
      {
        distances.append(neighbor.distance)
        if let cosPhi: Double = neighborPseudoDihedralCosine(positions: positions,
                                                            sourceIndex: index,
                                                            partnerIndex: neighbor.partner)
        {
          cosValues.append(cosPhi)
        }
      }
      if !cosValues.isEmpty
      {
        metrics.neighborCosPhiAverage[index] = cosValues.reduce(0.0, +) / Double(cosValues.count)
      }
      metrics.neighborDistanceAverage[index] = distances.reduce(0.0, +) / Double(distances.count)
    }
    return metrics
  }
  
  private static func helixScores(metrics: SegmentMetrics) -> [Double]
  {
    var scores: [Double] = Array(repeating: 0.0, count: metrics.sequentialDistance3.count)
    
    for index in scores.indices
    {
      var score: Double = 0.0
      score += gaussianScore(metrics.sequentialDistance3[index], center: 5.3, width: 0.5, weight: 0.30)
      score += gaussianScore(metrics.sequentialDistance4[index], center: 6.4, width: 0.6, weight: 0.25)
      score += gaussianScore(metrics.sequentialCosPhi[index], center: 0.64, width: 0.35, weight: 0.20)
      score += gaussianScore(metrics.neighborCosPhiAverage[index], center: 0.55, width: 0.40, weight: 0.15)
      score += gaussianScore(metrics.neighborDistanceAverage[index], center: 5.5, width: 1.5, weight: 0.10)
      scores[index] = min(score, 1.0)
    }
    return scores
  }
  
  private static func sheetScores(metrics: SegmentMetrics) -> [Double]
  {
    var scores: [Double] = Array(repeating: 0.0, count: metrics.sequentialDistance3.count)
    
    for index in scores.indices
    {
      var score: Double = 0.0
      score += gaussianScore(metrics.sequentialDistance2[index], center: 6.7, width: 0.6, weight: 0.20)
      score += gaussianScore(metrics.sequentialDistance3[index], center: 9.9, width: 0.9, weight: 0.35)
      score += gaussianScore(metrics.sequentialDistance4[index], center: 12.4, width: 1.1, weight: 0.20)
      
      if let cosPhi: Double = metrics.sequentialCosPhi[index], cosPhi <= -0.5
      {
        score += 0.10
      }
      if let neighborCos: Double = metrics.neighborCosPhiAverage[index], neighborCos <= -0.35
      {
        score += 0.15
      }
      scores[index] = min(score, 1.0)
    }
    return scores
  }
  
  private static func nearestNeighbors(for index: Int, positions: [SIMD3<Double>]) -> [(partner: Int, distance: Double)]
  {
    var neighbors: [(partner: Int, distance: Double)] = []
    for partnerIndex in positions.indices where partnerIndex != index
    {
      let separation: Double = SKSecondaryStructureGeometry.distance(positions[index], positions[partnerIndex])
      neighbors.append((partnerIndex, separation))
    }
    neighbors.sort{$0.distance < $1.distance}
    return Array(neighbors.prefix(nearestNeighborCount))
  }
  
  private static func neighborPseudoDihedralCosine(positions: [SIMD3<Double>],
                                                     sourceIndex: Int,
                                                     partnerIndex: Int) -> Double?
  {
    let sortedBySource: [(partner: Int, distance: Double)] = nearestNeighbors(for: sourceIndex, positions: positions)
    guard sortedBySource.count >= 2 else {return nil}
    
    let sourcePrimeIndex: Int = sortedBySource[1].partner
    let sortedByPartner: [(partner: Int, distance: Double)] = nearestNeighbors(for: partnerIndex, positions: positions)
    guard let partnerPrimeIndex: Int = sortedByPartner.map{$0.partner}.first(where: {$0 != sourceIndex && $0 != sourcePrimeIndex}) else {return nil}
    
    return pseudoDihedralCosine(positions: positions,
                                indices: [sourcePrimeIndex, sourceIndex, partnerIndex, partnerPrimeIndex])
  }
  
  private static func pseudoDihedralCosine(positions: [SIMD3<Double>], indices: [Int]) -> Double?
  {
    guard indices.count == 4,
          indices.allSatisfy({$0 >= 0 && $0 < positions.count}) else {return nil}
    
    let angleDegrees: Double = SKSecondaryStructureGeometry.torsionAngle(positions[indices[0]],
                                                                        positions[indices[1]],
                                                                        positions[indices[2]],
                                                                        positions[indices[3]])
    return cos(angleDegrees * Double.pi / 180.0)
  }
  
  private static func gaussianScore(_ value: Double?, center: Double, width: Double, weight: Double) -> Double
  {
    guard let value: Double = value else {return 0.0}
    let normalized: Double = (value - center) / width
    return weight * exp(-0.5 * normalized * normalized)
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
