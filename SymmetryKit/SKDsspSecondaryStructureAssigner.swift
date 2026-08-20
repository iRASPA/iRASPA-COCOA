/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 DSSP algorithm adapted from Kabsch & Sander (1983), Biopolymers 22:2577-2637.
 Hydrogen-bond map and assignment logic follows pydssp (Shintaro Minami, MIT License)
 as re-implemented in MDAnalysis.analysis.dssp.pydssp_numpy.
 *************************************************************************************************************/

import Foundation
import simd

public enum SKDsspSecondaryStructureAssigner
{
  private struct ResidueState
  {
    var residueName: String
    var nitrogen: SIMD3<Double>
    var alphaCarbon: SIMD3<Double>
    var carbonylCarbon: SIMD3<Double>
    var carbonylOxygen: SIMD3<Double>
    var implicitHydrogen: SIMD3<Double>?
    var isDonor: Bool
  }
  
  private static let coulombFactor: Double = 0.084 * 332.0
  private static let energyCutoff: Double = -0.5
  private static let energyMargin: Double = 1.0
  private static let hydrogenBondSearchCutoff: Double = 5.0
  private static let nitrogenHydrogenBondLength: Double = 1.01
  
  public static func assign(for chain: SKStrideBackboneChain) -> [SKSecondaryStructureType]
  {
    let sourceResidues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard !sourceResidues.isEmpty else {return []}
    
    var assignments: [SKSecondaryStructureType] = Array(repeating: .coil, count: sourceResidues.count)
    let states: [ResidueState] = buildStates(from: sourceResidues)
    guard states.count >= 6 else {return assignments}
    
    let hydrogenBondMap: [[Double]] = hydrogenBondMap(for: states)
    let labels: [Character] = assignSecondaryStructure(from: hydrogenBondMap)
    
    var stateIndex: Int = 0
    for (sourceIndex, residue) in sourceResidues.enumerated()
    {
      guard isCompleteBackbone(residue) else {continue}
      if stateIndex < labels.count
      {
        assignments[sourceIndex] = structureType(for: labels[stateIndex])
      }
      stateIndex += 1
    }
    return assignments
  }
  
  private static func isCompleteBackbone(_ residue: SKStrideBackboneResidue) -> Bool
  {
    return residue.nitrogen != nil &&
      residue.alphaCarbon != nil &&
      residue.carbonylCarbon != nil &&
      residue.carbonylOxygen != nil
  }
  
  private static func buildStates(from residues: [SKStrideBackboneResidue]) -> [ResidueState]
  {
    var states: [ResidueState] = []
    states.reserveCapacity(residues.count)
    
    for residue in residues
    {
      guard let nitrogen: SIMD3<Double> = residue.nitrogen,
            let alphaCarbon: SIMD3<Double> = residue.alphaCarbon,
            let carbonylCarbon: SIMD3<Double> = residue.carbonylCarbon,
            let carbonylOxygen: SIMD3<Double> = residue.carbonylOxygen else {continue}
      
      states.append(ResidueState(residueName: residue.residueName,
                                 nitrogen: nitrogen,
                                 alphaCarbon: alphaCarbon,
                                 carbonylCarbon: carbonylCarbon,
                                 carbonylOxygen: carbonylOxygen,
                                 implicitHydrogen: nil,
                                 isDonor: residue.residueName.uppercased() != "PRO"))
    }
    
    for index in 1..<states.count
    {
      guard states[index].isDonor else {continue}
      let previousCarbon: SIMD3<Double> = states[index - 1].carbonylCarbon
      let nitrogen: SIMD3<Double> = states[index].nitrogen
      let alphaCarbon: SIMD3<Double> = states[index].alphaCarbon
      
      let carbonToNitrogen: SIMD3<Double> = normalize(nitrogen - previousCarbon)
      let alphaCarbonToNitrogen: SIMD3<Double> = normalize(nitrogen - alphaCarbon)
      let hydrogenDirection: SIMD3<Double> = normalize(carbonToNitrogen + alphaCarbonToNitrogen)
      states[index].implicitHydrogen = nitrogen + nitrogenHydrogenBondLength * hydrogenDirection
    }
    return states
  }
  
  private static func hydrogenBondMap(for states: [ResidueState]) -> [[Double]]
  {
    let count: Int = states.count
    var energyMap: [[Double]] = Array(repeating: Array(repeating: 0.0, count: count), count: count)
    
    for donorIndex in 1..<count
    {
      guard states[donorIndex].isDonor,
            let hydrogen: SIMD3<Double> = states[donorIndex].implicitHydrogen else {continue}
      
      let donorNitrogen: SIMD3<Double> = states[donorIndex].nitrogen
      
      for acceptorIndex in 0..<(count - 1)
      {
        if abs(acceptorIndex - donorIndex) < 2 {continue}
        
        let acceptorOxygen: SIMD3<Double> = states[acceptorIndex].carbonylOxygen
        let acceptorCarbon: SIMD3<Double> = states[acceptorIndex].carbonylCarbon
        
        let nitrogenOxygenDistance: Double = distance(donorNitrogen, acceptorOxygen)
        if nitrogenOxygenDistance > hydrogenBondSearchCutoff {continue}
        
        let carbonHydrogenDistance: Double = distance(acceptorCarbon, hydrogen)
        let oxygenHydrogenDistance: Double = distance(acceptorOxygen, hydrogen)
        let carbonNitrogenDistance: Double = distance(acceptorCarbon, donorNitrogen)
        
        guard carbonHydrogenDistance > 1.0e-6,
              oxygenHydrogenDistance > 1.0e-6,
              carbonNitrogenDistance > 1.0e-6 else {continue}
        
        let energy: Double = coulombFactor *
          (1.0 / nitrogenOxygenDistance +
           1.0 / carbonHydrogenDistance -
           1.0 / oxygenHydrogenDistance -
           1.0 / carbonNitrogenDistance)
        
        energyMap[donorIndex][acceptorIndex] = energy
      }
    }
    
    return energyMap.map{row in
      row.map{energy in
        let clipped: Double = min(max(energyCutoff - energyMargin - energy, -energyMargin), energyMargin)
        return (sin(clipped / energyMargin * Double.pi / 2.0) + 1.0) / 2.0
      }
    }
  }
  
  private static func assignSecondaryStructure(from hydrogenBondMap: [[Double]]) -> [Character]
  {
    let count: Int = hydrogenBondMap.count
    var hbmap: [[Double]] = Array(repeating: Array(repeating: 0.0, count: count), count: count)
    for rowIndex in 0..<count
    {
      for columnIndex in 0..<count
      {
        hbmap[rowIndex][columnIndex] = hydrogenBondMap[columnIndex][rowIndex]
      }
    }
    
    let turn3: [Bool] = diagonalGreaterThanZero(hbmap, offset: 3)
    let turn4: [Bool] = diagonalGreaterThanZero(hbmap, offset: 4)
    let turn5: [Bool] = diagonalGreaterThanZero(hbmap, offset: 5)
    
    var h3: [Bool] = paddedPairProduct(turn3, leadingPadding: 1, trailingPadding: 3)
    var h4: [Bool] = paddedPairProduct(turn4, leadingPadding: 1, trailingPadding: 4)
    var h5: [Bool] = paddedPairProduct(turn5, leadingPadding: 1, trailingPadding: 5)
    
    var helix4: [Bool] = rollingSum(h4, window: 4)
    let helix4Previous: [Bool] = shift(helix4, by: -1)
    h3 = zip(zip(h3, helix4Previous), helix4).map{$0.0.0 && !$0.0.1 && !$0.1}
    h5 = zip(zip(h5, helix4Previous), helix4).map{$0.0.0 && !$0.0.1 && !$0.1}
    
    let helix3: [Bool] = rollingSum(h3, window: 3)
    helix4 = rollingSum(h4, window: 4)
    let helix5: [Bool] = rollingSum(h5, window: 5)
    
    let helix: [Bool] = zip(zip(helix3, helix4), helix5).map{$0.0.0 || $0.0.1 || $0.1}
    let strand: [Bool] = detectBetaLadder(from: hbmap)
    
    return zip(helix, strand).map{$0 ? "H" : ($1 ? "E" : "-")}
  }
  
  private static func diagonalGreaterThanZero(_ matrix: [[Double]], offset: Int) -> [Bool]
  {
    let count: Int = matrix.count
    var values: [Bool] = []
    values.reserveCapacity(max(0, count - offset))
    for index in 0..<(count - offset)
    {
      values.append(matrix[index][index + offset] > 0.0)
    }
    return values
  }
  
  private static func paddedPairProduct(_ values: [Bool], leadingPadding: Int, trailingPadding: Int) -> [Bool]
  {
    var padded: [Bool] = Array(repeating: false, count: leadingPadding)
    if values.count >= 2
    {
      for index in 0..<(values.count - 1)
      {
        padded.append(values[index] && values[index + 1])
      }
    }
    padded.append(contentsOf: Array(repeating: false, count: trailingPadding))
    return padded
  }
  
  private static func shift(_ values: [Bool], by amount: Int) -> [Bool]
  {
    guard !values.isEmpty else {return []}
    if amount == 0 {return values}
    if amount > 0
    {
      return Array(repeating: false, count: amount) + values.dropLast(amount)
    }
    let positiveAmount: Int = -amount
    return Array(values.dropFirst(positiveAmount)) + Array(repeating: false, count: positiveAmount)
  }
  
  private static func rollingSum(_ values: [Bool], window: Int) -> [Bool]
  {
    guard !values.isEmpty else {return []}
    var summed: [Bool] = values
    for offset in 1..<window
    {
      let shifted: [Bool] = shift(values, by: offset)
      summed = zip(summed, shifted).map{$0 || $1}
    }
    return summed
  }
  
  private static func detectBetaLadder(from hbmap: [[Double]]) -> [Bool]
  {
    let count: Int = hbmap.count
    guard count >= 3 else {return Array(repeating: false, count: count)}
    
    let unfolded: [[[[Bool]]]] = upsampleBooleanMap(hbmap, window: 3)
    let rowCount: Int = unfolded.count
    let columnCount: Int = unfolded.first?.count ?? 0
    
    var parallelBridge: [[Bool]] = Array(repeating: Array(repeating: false, count: columnCount), count: rowCount)
    var antiparallelBridge: [[Bool]] = Array(repeating: Array(repeating: false, count: columnCount), count: rowCount)
    
    for rowIndex in 0..<rowCount
    {
      for columnIndex in 0..<columnCount
      {
        let block: [[Bool]] = unfolded[rowIndex][columnIndex]
        guard block.count == 3, block[0].count == 3 else {continue}
        let reversedBlock: [[Bool]] = block.reversed().map{$0.reversed()}
        
        parallelBridge[rowIndex][columnIndex] =
          (block[0][1] && reversedBlock[1][2]) ||
          (reversedBlock[0][1] && block[1][2])
        
        antiparallelBridge[rowIndex][columnIndex] =
          (block[1][1] && reversedBlock[1][1]) ||
          (block[0][2] && reversedBlock[0][2])
      }
    }
    
    parallelBridge = padBridgeMap(parallelBridge)
    antiparallelBridge = padBridgeMap(antiparallelBridge)
    
    var ladder: [Bool] = Array(repeating: false, count: count)
    for rowIndex in 0..<parallelBridge.count
    {
      let hasBridge: Bool = zip(parallelBridge[rowIndex], antiparallelBridge[rowIndex]).contains{$0.0 || $0.1}
      if rowIndex < count
      {
        ladder[rowIndex] = hasBridge
      }
    }
    return ladder
  }
  
  private static func upsampleBooleanMap(_ matrix: [[Double]], window: Int) -> [[[[Bool]]]]
  {
    let rowWindows: [[[Double]]] = unfoldAlongRows(matrix, window: window)
    return rowWindows.map{slab in
      unfoldAlongColumns(slab, window: window).map{$0.map{$0.map{$0 > 0.0}}}
    }
  }
  
  private static func unfoldAlongRows(_ matrix: [[Double]], window: Int) -> [[[Double]]]
  {
    let rowCount: Int = matrix.count
    guard rowCount >= window else {return []}
    return (0..<(rowCount - window + 1)).map{startRow in
      (0..<window).map{offset in matrix[startRow + offset]}
    }
  }
  
  private static func unfoldAlongColumns(_ matrix: [[Double]], window: Int) -> [[[Double]]]
  {
    guard let columnCount: Int = matrix.first?.count, columnCount >= window else {return []}
    return (0..<(columnCount - window + 1)).map{startColumn in
      matrix.map{row in
        (0..<window).map{offset in row[startColumn + offset]}
      }
    }
  }
  
  private static func padBridgeMap(_ map: [[Bool]]) -> [[Bool]]
  {
    let emptyRow: [Bool] = Array(repeating: false, count: map.first?.count ?? 0)
    return [emptyRow] + map + [emptyRow]
  }
  
  private static func structureType(for code: Character) -> SKSecondaryStructureType
  {
    switch code
    {
    case "H", "G", "I": return .helix
    case "E", "B": return .sheet
    default: return .coil
    }
  }
  
  private static func normalize(_ vector: SIMD3<Double>) -> SIMD3<Double>
  {
    let lengthValue: Double = length(vector)
    guard lengthValue > 1.0e-12 else {return .zero}
    return vector / lengthValue
  }
  
  private static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double
  {
    return length(a - b)
  }
}
