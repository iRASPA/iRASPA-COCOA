/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 SEGNO algorithm adapted from Cubellis et al., BMC Bioinformatics 2005, 6(S4):S8.
 Uses a four-residue Cα window for local axis geometry, backbone dihedral angles,
 and peptide-plane dihedrals.
 *************************************************************************************************************/

import Foundation
import simd

public enum SKSegnoSecondaryStructureAssigner
{
  public static func assign(for chain: SKStrideBackboneChain) -> [SKSecondaryStructureType]
  {
    let residues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard !residues.isEmpty else {return []}
    
    let positions: [SIMD3<Double>] = residues.compactMap{$0.alphaCarbon}
    let angles: [(phi: Double, psi: Double)] = SKSecondaryStructureGeometry.phiPsiDegrees(for: chain)
    
    let helixMask: [Bool] = helixMask(residues: residues, positions: positions, angles: angles)
    let sheetMask: [Bool] = sheetMask(residues: residues, positions: positions, angles: angles)
    return mapToTypes(count: residues.count, helix: helixMask, sheet: sheetMask)
  }
  
  private static func helixMask(residues: [SKStrideBackboneResidue],
                                positions: [SIMD3<Double>],
                                angles: [(phi: Double, psi: Double)]) -> [Bool]
  {
    var mask: [Bool] = Array(repeating: false, count: residues.count)
    
    for index in residues.indices
    {
      guard let frame: SKSecondaryStructureGeometry.LocalAxisFrame =
        SKSecondaryStructureGeometry.localAxisFrame(at: index, positions: positions),
        let alphaCarbon: SIMD3<Double> = residues[index].alphaCarbon else {continue}
      
      let radius: Double = SKSecondaryStructureGeometry.axisRadius(position: alphaCarbon, frame: frame)
      let tau: Double = SKSecondaryStructureGeometry.axisTau(position: alphaCarbon, frame: frame)
      let phi: Double = angles[index].phi
      let psi: Double = angles[index].psi
      
      let tauValid: Bool = SKSecondaryStructureGeometry.inRange(tau, 68.0, 130.0)
      
      mask[index] = SKSecondaryStructureGeometry.inRange(radius, 1.7, 3.0)
      && tauValid
      && SKSecondaryStructureGeometry.inRange(phi, -95.0, -35.0)
      && SKSecondaryStructureGeometry.inRange(psi, -70.0, -10.0)
    }
    return SKSecondaryStructureGeometry.maskConsecutive(mask, minimumLength: 4)
  }
  
  private static func sheetMask(residues: [SKStrideBackboneResidue],
                                positions: [SIMD3<Double>],
                                angles: [(phi: Double, psi: Double)]) -> [Bool]
  {
    var mask: [Bool] = Array(repeating: false, count: residues.count)
    
    for index in residues.indices
    {
      guard let frame: SKSecondaryStructureGeometry.LocalAxisFrame =
        SKSecondaryStructureGeometry.localAxisFrame(at: index, positions: positions),
        let alphaCarbon: SIMD3<Double> = residues[index].alphaCarbon else {continue}
      
      let tau: Double = SKSecondaryStructureGeometry.axisTau(position: alphaCarbon, frame: frame)
      guard tau > 110.0 else {continue}
      
      let pairedWithNext: Bool = index + 1 < residues.count
      && forwardBetaPair(currentIndex: index, residues: residues, angles: angles)
      let pairedWithPrevious: Bool = index > 0
      && backwardBetaPair(currentIndex: index, residues: residues, angles: angles)
      
      mask[index] = pairedWithNext || pairedWithPrevious
    }
    return SKSecondaryStructureGeometry.maskConsecutive(mask, minimumLength: 3)
  }
  
  private static func forwardBetaPair(currentIndex: Int,
                                      residues: [SKStrideBackboneResidue],
                                      angles: [(phi: Double, psi: Double)]) -> Bool
  {
    let nextIndex: Int = currentIndex + 1
    guard nextIndex < residues.count else {return false}
    
    let omega1: Double = peptidePlaneDihedral(between: currentIndex, and: nextIndex, residues: residues)
    guard SKSecondaryStructureGeometry.inWrappedRange(omega1, 123.0, 210.0) else {return false}
    
    return betaRamachandran(phi: angles[nextIndex].phi, psi: angles[currentIndex].psi)
  }
  
  private static func backwardBetaPair(currentIndex: Int,
                                       residues: [SKStrideBackboneResidue],
                                       angles: [(phi: Double, psi: Double)]) -> Bool
  {
    let previousIndex: Int = currentIndex - 1
    guard previousIndex >= 0 else {return false}
    guard let previousNitrogen: SIMD3<Double> = residues[previousIndex].nitrogen,
          let previousAlphaCarbon: SIMD3<Double> = residues[previousIndex].alphaCarbon,
          let previousCarbon: SIMD3<Double> = residues[previousIndex].carbonylCarbon,
          let nitrogen: SIMD3<Double> = residues[currentIndex].nitrogen,
          let alphaCarbon: SIMD3<Double> = residues[currentIndex].alphaCarbon,
          let carbonylCarbon: SIMD3<Double> = residues[currentIndex].carbonylCarbon else {return false}
    
    let acutePlaneAngle: Double = SKSecondaryStructureGeometry.acutePeptidePlaneAngle(
      firstNitrogen: previousNitrogen,
      firstAlphaCarbon: previousAlphaCarbon,
      firstCarbonylCarbon: previousCarbon,
      secondNitrogen: nitrogen,
      secondAlphaCarbon: alphaCarbon,
      secondCarbonylCarbon: carbonylCarbon
    )
    let carbonylDihedral: Double = carbonylPlaneDihedral(currentIndex: currentIndex, residues: residues)
    
    guard acutePlaneAngle < 80.0,
          SKSecondaryStructureGeometry.inWrappedRange(carbonylDihedral, 125.0, 210.0) else {return false}
    
    return betaRamachandran(phi: angles[currentIndex].phi, psi: angles[currentIndex].psi)
  }
  
  private static func betaRamachandran(phi: Double, psi: Double) -> Bool
  {
    let referencePhi: Double = phi < 0.0 ? phi + 360.0 : phi
    let referencePsi: Double = psi < 0.0 ? psi + 360.0 : psi
    return SKSecondaryStructureGeometry.inRange(referencePhi, 170.0, 290.0)
      && SKSecondaryStructureGeometry.inRange(referencePsi, 60.0, 185.0)
  }
  
  private static func peptidePlaneDihedral(between firstIndex: Int,
                                           and secondIndex: Int,
                                           residues: [SKStrideBackboneResidue]) -> Double
  {
    guard firstIndex >= 0, secondIndex < residues.count else {return 0.0}
    guard let firstAlphaCarbon: SIMD3<Double> = residues[firstIndex].alphaCarbon,
          let firstCarbon: SIMD3<Double> = residues[firstIndex].carbonylCarbon,
          let secondNitrogen: SIMD3<Double> = residues[secondIndex].nitrogen,
          let secondAlphaCarbon: SIMD3<Double> = residues[secondIndex].alphaCarbon else {return 0.0}
    return SKSecondaryStructureGeometry.torsionAngle(firstAlphaCarbon,
                                                     firstCarbon,
                                                     secondNitrogen,
                                                     secondAlphaCarbon)
  }
  
  private static func carbonylPlaneDihedral(currentIndex: Int, residues: [SKStrideBackboneResidue]) -> Double
  {
    let previousIndex: Int = currentIndex - 1
    guard previousIndex >= 0 else {return 0.0}
    guard let previousCarbon: SIMD3<Double> = residues[previousIndex].carbonylCarbon,
          let previousOxygen: SIMD3<Double> = residues[previousIndex].carbonylOxygen,
          let currentCarbon: SIMD3<Double> = residues[currentIndex].carbonylCarbon,
          let currentOxygen: SIMD3<Double> = residues[currentIndex].carbonylOxygen else {return 0.0}
    return SKSecondaryStructureGeometry.torsionAngle(previousCarbon, previousOxygen, currentCarbon, currentOxygen)
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
