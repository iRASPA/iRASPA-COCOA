/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 PyMOL DSS (Define Secondary Structure) algorithm adapted from SelectorAssignSS in pymol-open-source
 (Warren Lyford Delano / DeLano Scientific, MIT License).
 *************************************************************************************************************/

import Foundation
import simd

public enum SKSecondaryStructureAssignmentMethod: Sendable
{
  case stride
  case dss
  case dssp
  case psea
  case sequoia
  case segno
}

public enum SKDssSecondaryStructureAssigner
{
  private struct DssResidue
  {
    var isReal: Bool = false
    var residueName: String = ""
    var nitrogen: SIMD3<Double>?
    var alphaCarbon: SIMD3<Double>?
    var carbonylCarbon: SIMD3<Double>?
    var carbonylOxygen: SIMD3<Double>?
    var implicitHydrogen: SIMD3<Double>?
    var phiDegrees: Double = 0.0
    var psiDegrees: Double = 0.0
    var assignment: Character = "L"
    var flags: Flags = []
    var acceptorPartners: [Int] = []
    var donorPartners: [Int] = []
  }
  
  private struct Flags: OptionSet
  {
    let rawValue: UInt16
    
    static let helix3HBond: Flags = Flags(rawValue: 0x0001)
    static let helix4HBond: Flags = Flags(rawValue: 0x0002)
    static let helix5HBond: Flags = Flags(rawValue: 0x0004)
    static let gotPhiPsi: Flags = Flags(rawValue: 0x0008)
    static let phiPsiHelix: Flags = Flags(rawValue: 0x0010)
    static let phiPsiNotHelix: Flags = Flags(rawValue: 0x0020)
    static let phiPsiStrand: Flags = Flags(rawValue: 0x0040)
    static let phiPsiNotStrand: Flags = Flags(rawValue: 0x0080)
    static let antiStrandSingleHB: Flags = Flags(rawValue: 0x0100)
    static let antiStrandDoubleHB: Flags = Flags(rawValue: 0x0200)
    static let antiStrandBulgeHB: Flags = Flags(rawValue: 0x0400)
    static let antiStrandSkip: Flags = Flags(rawValue: 0x0800)
    static let paraStrandSingleHB: Flags = Flags(rawValue: 0x1000)
    static let paraStrandDoubleHB: Flags = Flags(rawValue: 0x2000)
    static let paraStrandSkip: Flags = Flags(rawValue: 0x4000)
    
    static let helixHBond: Flags = [.helix3HBond, .helix4HBond, .helix5HBond]
    static let antiStrandHB: Flags = [.antiStrandSingleHB, .antiStrandDoubleHB]
    static let paraStrandHB: Flags = [.paraStrandSingleHB, .paraStrandDoubleHB]
  }
  
  private struct HBondCriteria
  {
    let maxAngle: Double = 63.0
    let maxDistAtMaxAngle: Double = 3.2
    let maxDistAtZero: Double = 4.0
    let powerA: Double = 1.6
    let powerB: Double = 5.0
    let coneCosine: Double = 0.0
    let factorA: Double
    let factorB: Double
    let cutoff: Double
    
    init()
    {
      factorA = 0.5 / pow(maxAngle, powerA)
      factorB = 0.5 / pow(maxAngle, powerB)
      cutoff = max(maxDistAtMaxAngle, maxDistAtZero)
    }
  }
  
  private static let breakSize: Int = 5
  private static let maxHydrogenBondPartners: Int = 6
  private static let connectedAlphaCarbonDistance: Double = 4.5
  /// Minimum sequence separation for backbone H-bonds. PyMOL uses `SelectorCheckNeighbors`
  /// (covalent bond-path distance ≤ 5 atoms) to skip same-chain neighbours; for a linear
  /// backbone that corresponds roughly to |i − j| ≥ 3, which keeps i+3/i+4/i+5 helix bonds.
  private static let minimumBackboneSequenceSeparation: Int = 3
  
  private static let helixPsiTarget: Double = -48.0
  private static let helixPsiInclude: Double = 55.0
  private static let helixPsiExclude: Double = 85.0
  private static let helixPhiTarget: Double = -57.0
  private static let helixPhiInclude: Double = 55.0
  private static let helixPhiExclude: Double = 85.0
  private static let strandPsiTarget: Double = 124.0
  private static let strandPsiInclude: Double = 40.0
  private static let strandPsiExclude: Double = 90.0
  private static let strandPhiTarget: Double = -129.0
  private static let strandPhiInclude: Double = 40.0
  private static let strandPhiExclude: Double = 100.0
  
  public static func assign(for chain: SKStrideBackboneChain) -> [SKSecondaryStructureType]
  {
    let sourceResidues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard !sourceResidues.isEmpty else {return []}
    
    var paddedResidues: [DssResidue] = Array(repeating: DssResidue(), count: breakSize)
    var sourceIndices: [Int?] = Array(repeating: nil, count: breakSize)
    var lastPackedSourceIndex: Int? = nil
    
    for index in sourceResidues.indices
    {
      let residue: SKStrideBackboneResidue = sourceResidues[index]
      guard isCompleteBackbone(residue) else {continue}
      
      if let previousIndex: Int = lastPackedSourceIndex
      {
        if needsChainBreak(between: sourceResidues[previousIndex], and: residue)
        {
          appendBreakPadding(to: &paddedResidues, sourceIndices: &sourceIndices)
        }
      }
      
      var dssResidue: DssResidue = DssResidue()
      dssResidue.isReal = true
      dssResidue.residueName = residue.residueName
      dssResidue.nitrogen = residue.nitrogen
      dssResidue.alphaCarbon = residue.alphaCarbon
      dssResidue.carbonylCarbon = residue.carbonylCarbon
      dssResidue.carbonylOxygen = residue.carbonylOxygen
      paddedResidues.append(dssResidue)
      sourceIndices.append(index)
      lastPackedSourceIndex = index
    }
    
    appendBreakPadding(to: &paddedResidues, sourceIndices: &sourceIndices)
    
    guard paddedResidues.count > 2 * breakSize else
    {
      return sourceResidues.map{_ in .coil}
    }
    
    placeImplicitHydrogens(residues: &paddedResidues)
    findHydrogenBonds(residues: &paddedResidues)
    computePhiPsiFlags(residues: &paddedResidues)
    
    for index in breakSize..<(paddedResidues.count - breakSize)
    {
      if paddedResidues[index].isReal
      {
        paddedResidues[index].assignment = "L"
      }
    }
    
    assignPatternFlags(residues: &paddedResidues)
    assignHelices(residues: &paddedResidues)
    assignSheets(residues: &paddedResidues)
    filterShortSegments(residues: &paddedResidues)
    
    var assignments: [SKSecondaryStructureType] = Array(repeating: .coil, count: sourceResidues.count)
    for (paddedIndex, sourceIndex) in sourceIndices.enumerated()
    {
      guard let sourceIndex: Int = sourceIndex,
            paddedResidues[paddedIndex].isReal else {continue}
      assignments[sourceIndex] = structureType(for: paddedResidues[paddedIndex].assignment)
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
  
  private static func needsChainBreak(between previous: SKStrideBackboneResidue, and current: SKStrideBackboneResidue) -> Bool
  {
    guard let previousAlphaCarbon: SIMD3<Double> = previous.alphaCarbon,
          let currentAlphaCarbon: SIMD3<Double> = current.alphaCarbon else {return true}
    return distance(previousAlphaCarbon, currentAlphaCarbon) > connectedAlphaCarbonDistance
  }
  
  private static func appendBreakPadding(to residues: inout [DssResidue], sourceIndices: inout [Int?])
  {
    for _ in 0..<breakSize
    {
      residues.append(DssResidue())
      sourceIndices.append(nil)
    }
  }
  
  private static func placeImplicitHydrogens(residues: inout [DssResidue])
  {
    for index in 1..<residues.count
    {
      guard residues[index].isReal,
            !isProline(residues[index]),
            let nitrogen: SIMD3<Double> = residues[index].nitrogen,
            let alphaCarbon: SIMD3<Double> = residues[index].alphaCarbon,
            let previousCarbon: SIMD3<Double> = residues[index - 1].carbonylCarbon else {continue}
      
      var direction: SIMD3<Double> = normalize(-(previousCarbon - nitrogen))
      direction += normalize(-(alphaCarbon - nitrogen))
      let directionLength: Double = length(direction)
      guard directionLength > 1.0e-12 else {continue}
      residues[index].implicitHydrogen = nitrogen + direction / directionLength
    }
  }
  
  private static func findHydrogenBonds(residues: inout [DssResidue])
  {
    let criteria: HBondCriteria = HBondCriteria()
    let count: Int = residues.count
    
    for acceptorIndex in 0..<count
    {
      guard residues[acceptorIndex].isReal,
            let acceptorOxygen: SIMD3<Double> = residues[acceptorIndex].carbonylOxygen,
            let acceptorCarbon: SIMD3<Double> = residues[acceptorIndex].carbonylCarbon,
            let acceptorAlphaCarbon: SIMD3<Double> = residues[acceptorIndex].alphaCarbon else {continue}
      
      for donorIndex in 0..<count
      {
        guard donorIndex != acceptorIndex,
              residues[donorIndex].isReal,
              !isProline(residues[donorIndex]),
              abs(donorIndex - acceptorIndex) >= minimumBackboneSequenceSeparation,
              let donorNitrogen: SIMD3<Double> = residues[donorIndex].nitrogen,
              let hydrogen: SIMD3<Double> = residues[donorIndex].implicitHydrogen else {continue}
        
        let donorToAcceptor: SIMD3<Double> = acceptorOxygen - donorNitrogen
        if length(donorToAcceptor) > criteria.cutoff {continue}
        
        let acceptorPlane: SIMD3<Double>? = averageAcceptorPlane(acceptorOxygen: acceptorOxygen,
                                                                  acceptorCarbon: acceptorCarbon,
                                                                  acceptorAlphaCarbon: acceptorAlphaCarbon,
                                                                  incoming: acceptorOxygen - hydrogen)
        
        if checkHydrogenBond(donorNitrogen: donorNitrogen,
                             hydrogen: hydrogen,
                             acceptorOxygen: acceptorOxygen,
                             acceptorPlane: acceptorPlane,
                             criteria: criteria)
        {
          appendPartner(&residues[acceptorIndex].acceptorPartners, donorIndex)
          appendPartner(&residues[donorIndex].donorPartners, acceptorIndex)
        }
      }
    }
  }
  
  private static func appendPartner(_ partners: inout [Int], _ index: Int)
  {
    if partners.count < maxHydrogenBondPartners && !partners.contains(index)
    {
      partners.append(index)
    }
  }
  
  private static func averageAcceptorPlane(acceptorOxygen: SIMD3<Double>,
                                           acceptorCarbon: SIMD3<Double>,
                                           acceptorAlphaCarbon: SIMD3<Double>,
                                           incoming: SIMD3<Double>) -> SIMD3<Double>?
  {
    var average: SIMD3<Double> = normalize(acceptorOxygen - acceptorCarbon)
    average += normalize(acceptorOxygen - acceptorAlphaCarbon)
    let averageLength: Double = length(average)
    guard averageLength > 0.1 else {return nil}
    var plane: SIMD3<Double> = average / averageLength
    
    let incomingLength: Double = length(incoming)
    if incomingLength > 1.0e-12
    {
      let incomingNormalized: SIMD3<Double> = incoming / incomingLength
      if abs(dot(plane, incomingNormalized)) < 0.99
      {
        let perpendicular: SIMD3<Double> = incomingNormalized - dot(incomingNormalized, plane) * plane
        let perpendicularLength: Double = length(perpendicular)
        if perpendicularLength > 1.0e-12
        {
          let adjusted: SIMD3<Double> = 0.333644 * plane + 0.942699 * (perpendicular / perpendicularLength)
          plane = normalize(plane - adjusted)
        }
      }
    }
    return plane
  }
  
  private static func checkHydrogenBond(donorNitrogen: SIMD3<Double>,
                                        hydrogen: SIMD3<Double>,
                                        acceptorOxygen: SIMD3<Double>,
                                        acceptorPlane: SIMD3<Double>?,
                                        criteria: HBondCriteria) -> Bool
  {
    let donorToAcceptor: SIMD3<Double> = acceptorOxygen - donorNitrogen
    let donorToHydrogen: SIMD3<Double> = hydrogen - donorNitrogen
    let hydrogenToAcceptor: SIMD3<Double> = acceptorOxygen - hydrogen
    
    let normalizedHydrogenToAcceptor: SIMD3<Double> = normalize(hydrogenToAcceptor)
    if let acceptorPlane: SIMD3<Double> = acceptorPlane
    {
      if dot(normalizedHydrogenToAcceptor, acceptorPlane) > (-criteria.coneCosine)
      {
        return false
      }
    }
    
    let adhCosine: Double = dot(normalize(donorToHydrogen), normalize(donorToAcceptor))
    let angle: Double
    if adhCosine < 1.0 && adhCosine > 0.0
    {
      angle = acos(min(max(adhCosine, -1.0), 1.0)) * 180.0 / Double.pi
    }
    else if adhCosine > 0.0
    {
      angle = 0.0
    }
    else
    {
      angle = 90.0
    }
    
    if angle > criteria.maxAngle {return false}
    
    let curve: Double = pow(angle, criteria.powerA) * criteria.factorA +
      pow(angle, criteria.powerB) * criteria.factorB
    let cutoff: Double = criteria.maxDistAtMaxAngle * curve + criteria.maxDistAtZero * (1.0 - curve)
    return length(donorToAcceptor) <= cutoff
  }
  
  private static func computePhiPsiFlags(residues: inout [DssResidue])
  {
    let count: Int = residues.count
    for index in 1..<count
    {
      guard residues[index].isReal, residues[index - 1].isReal,
            let carbonylCarbon: SIMD3<Double> = residues[index].carbonylCarbon,
            let alphaCarbon: SIMD3<Double> = residues[index].alphaCarbon,
            let nitrogen: SIMD3<Double> = residues[index].nitrogen,
            let previousCarbon: SIMD3<Double> = residues[index - 1].carbonylCarbon else {continue}
      
      residues[index].phiDegrees = torsionAngle(carbonylCarbon, alphaCarbon, nitrogen, previousCarbon)
      
      if index + 1 < count,
         residues[index + 1].isReal,
         let nextNitrogen: SIMD3<Double> = residues[index + 1].nitrogen
      {
        // PyMOL ObjectMoleculeGetPhiPsi order: phi = dihedral(C, CA, N, C-1), psi = dihedral(N+1, C, CA, N)
        residues[index].psiDegrees = torsionAngle(nextNitrogen, carbonylCarbon, alphaCarbon, nitrogen)
      }
      
      residues[index].flags.insert(.gotPhiPsi)
      
      let helixPsiDelta: Double = wrappedDelta(residues[index].psiDegrees, helixPsiTarget)
      let helixPhiDelta: Double = wrappedDelta(residues[index].phiDegrees, helixPhiTarget)
      let strandPsiDelta: Double = wrappedDelta(residues[index].psiDegrees, strandPsiTarget)
      let strandPhiDelta: Double = wrappedDelta(residues[index].phiDegrees, strandPhiTarget)
      
      if helixPsiDelta > helixPsiExclude || helixPhiDelta > helixPhiExclude
      {
        residues[index].flags.insert(.phiPsiNotHelix)
      }
      else if helixPsiDelta < helixPsiInclude && helixPhiDelta < helixPhiInclude
      {
        residues[index].flags.insert(.phiPsiHelix)
      }
      
      if strandPsiDelta > strandPsiExclude || strandPhiDelta > strandPhiExclude
      {
        residues[index].flags.insert(.phiPsiNotStrand)
      }
      else if strandPsiDelta < strandPsiInclude && strandPhiDelta < strandPhiInclude
      {
        residues[index].flags.insert(.phiPsiStrand)
      }
    }
  }
  
  private static func assignPatternFlags(residues: inout [DssResidue])
  {
    let count: Int = residues.count
    for index in breakSize..<(count - breakSize)
    {
      guard residues[index].isReal else {continue}
      
      for partner in residues[index].acceptorPartners
      {
        if partner == index + 3 {residues[index].flags.insert(.helix3HBond)}
        if partner == index + 4 {residues[index].flags.insert(.helix4HBond)}
        if partner == index + 5 {residues[index].flags.insert(.helix5HBond)}
      }
      for partner in residues[index].donorPartners
      {
        if partner == index - 3 {residues[index].flags.insert(.helix3HBond)}
        if partner == index - 4 {residues[index].flags.insert(.helix4HBond)}
        if partner == index - 5 {residues[index].flags.insert(.helix5HBond)}
      }
      
      for acceptorPartner in residues[index].acceptorPartners
      {
        guard residues[acceptorPartner].isReal else {continue}
        for nestedPartner in residues[acceptorPartner].acceptorPartners where nestedPartner == index
        {
          residues[index].flags.insert(.antiStrandDoubleHB)
          residues[acceptorPartner].flags.insert(.antiStrandDoubleHB)
        }
        
        if acceptorPartner + 1 < count, residues[acceptorPartner + 1].isReal
        {
          for nestedPartner in residues[acceptorPartner + 1].acceptorPartners where nestedPartner == index
          {
            residues[index].flags.insert(.antiStrandDoubleHB)
            residues[acceptorPartner + 1].flags.insert(.antiStrandBulgeHB)
            residues[acceptorPartner].flags.insert(.antiStrandBulgeHB)
          }
        }
      }
      
      if index + 2 < count, residues[index + 1].isReal, residues[index + 2].isReal
      {
        for acceptorPartner in residues[index].acceptorPartners
        {
          let partnerIndex: Int = acceptorPartner - 2
          guard partnerIndex >= 0, residues[partnerIndex].isReal else {continue}
          for nestedPartner in residues[partnerIndex].acceptorPartners where nestedPartner == index + 2
          {
            residues[index].flags.insert(.antiStrandSingleHB)
            residues[index + 1].flags.insert(.antiStrandSkip)
            residues[index + 2].flags.insert(.antiStrandSingleHB)
            residues[partnerIndex].flags.insert(.antiStrandSingleHB)
            if partnerIndex + 1 < count, residues[partnerIndex + 1].isReal
            {
              residues[partnerIndex + 1].flags.insert(.antiStrandSkip)
            }
            if partnerIndex + 2 < count, residues[partnerIndex + 2].isReal
            {
              residues[partnerIndex + 2].flags.insert(.antiStrandSingleHB)
            }
          }
        }
        
        for acceptorPartner in residues[index].acceptorPartners
        {
          guard residues[acceptorPartner].isReal else {continue}
          for nestedPartner in residues[acceptorPartner].acceptorPartners where nestedPartner == index + 2
          {
            residues[index].flags.insert(.paraStrandSingleHB)
            residues[index + 1].flags.insert(.paraStrandSkip)
            residues[index + 2].flags.insert(.paraStrandSingleHB)
            residues[acceptorPartner].flags.insert(.paraStrandDoubleHB)
          }
        }
      }
    }
  }
  
  private static func assignHelices(residues: inout [DssResidue])
  {
    let count: Int = residues.count
    for index in breakSize..<(count - breakSize)
    {
      guard residues[index].isReal else {continue}
      
      if residues[index - 1].flags.intersection(.helixHBond) != [],
         residues[index].flags.intersection(.helixHBond) != [],
         residues[index + 1].flags.intersection(.helixHBond) != [],
         !residues[index].flags.contains(.phiPsiNotHelix)
      {
        residues[index].assignment = "H"
      }
      
      if residues[index - 2].flags.intersection(.helixHBond) != [],
         residues[index - 1].flags.intersection(.helixHBond) != [],
         residues[index - 1].flags.contains(.phiPsiHelix),
         residues[index].flags.contains(.phiPsiHelix),
         residues[index + 1].flags.intersection(.helixHBond) != [],
         residues[index + 1].flags.contains(.phiPsiHelix),
         residues[index + 2].flags.intersection(.helixHBond) != []
      {
        residues[index].assignment = "h"
      }
    }
    
    for index in breakSize..<(count - breakSize) where residues[index].isReal && residues[index].assignment == "h"
    {
      residues[index].flags.formUnion(.helixHBond)
      residues[index].assignment = "H"
    }
    
    for index in breakSize..<(count - breakSize)
    {
      guard residues[index].isReal else {continue}
      
      if residues[index].flags.intersection(.helixHBond) != [],
         residues[index].flags.contains(.phiPsiHelix),
         residues[index + 1].flags.intersection(.helixHBond) != [],
         residues[index + 1].flags.contains(.phiPsiHelix),
         residues[index + 2].flags.intersection(.helixHBond) != [],
         residues[index + 2].flags.contains(.phiPsiHelix),
         residues[index + 1].assignment == "H"
      {
        residues[index].assignment = "H"
      }
      
      if residues[index].flags.intersection(.helixHBond) != [],
         residues[index].flags.contains(.phiPsiHelix),
         residues[index - 1].flags.intersection(.helixHBond) != [],
         residues[index - 1].flags.contains(.phiPsiHelix),
         residues[index - 2].flags.intersection(.helixHBond) != [],
         residues[index - 2].flags.contains(.phiPsiHelix),
         residues[index - 1].assignment == "H"
      {
        residues[index].assignment = "H"
      }
    }
  }
  
  private static func assignSheets(residues: inout [DssResidue])
  {
    let count: Int = residues.count
    for index in breakSize..<(count - breakSize)
    {
      guard residues[index].isReal else {continue}
      
      if residues[index].flags.contains(.antiStrandDoubleHB),
         !residues[index].flags.contains(.phiPsiNotStrand)
      {
        residues[index].assignment = "S"
      }
      
      if residues[index].flags.contains(.antiStrandBulgeHB),
         residues[index + 1].flags.contains(.antiStrandBulgeHB)
      {
        residues[index].assignment = "S"
        residues[index + 1].assignment = "S"
      }
      
      if residues[index - 1].flags.contains(.antiStrandDoubleHB),
         residues[index].flags.contains(.antiStrandSkip),
         !residues[index].flags.contains(.phiPsiNotStrand),
         residues[index + 1].flags.intersection(.antiStrandHB) != []
      {
        residues[index].assignment = "S"
      }
      
      if residues[index - 1].flags.intersection(.antiStrandHB) != [],
         residues[index].flags.contains(.antiStrandSkip),
         !residues[index].flags.contains(.phiPsiNotStrand),
         residues[index + 1].flags.contains(.antiStrandDoubleHB)
      {
        residues[index].assignment = "S"
      }
      
      if residues[index - 1].flags.intersection(.antiStrandHB) != [],
         residues[index - 1].flags.contains(.phiPsiStrand),
         !residues[index - 1].flags.contains(.phiPsiNotStrand),
         residues[index].flags.contains(.phiPsiStrand),
         !residues[index].flags.contains(.phiPsiNotStrand),
         residues[index + 1].flags.intersection(.antiStrandHB) != [],
         residues[index + 1].flags.contains(.phiPsiStrand)
      {
        residues[index - 1].assignment = "S"
        residues[index].assignment = "S"
        residues[index + 1].assignment = "S"
      }
      
      if residues[index].flags.contains(.paraStrandDoubleHB),
         !residues[index].flags.contains(.phiPsiNotStrand)
      {
        residues[index].assignment = "S"
      }
      
      if residues[index - 1].flags.contains(.paraStrandDoubleHB),
         residues[index].flags.contains(.paraStrandSkip),
         !residues[index].flags.contains(.phiPsiNotStrand),
         residues[index + 1].flags.intersection(.paraStrandHB) != []
      {
        residues[index].assignment = "S"
      }
      
      if residues[index - 1].flags.intersection(.paraStrandHB) != [],
         residues[index].flags.contains(.paraStrandSkip),
         !residues[index].flags.contains(.phiPsiNotStrand),
         residues[index + 1].flags.contains(.paraStrandDoubleHB)
      {
        residues[index].assignment = "S"
      }
      
      if residues[index - 1].flags.intersection(.paraStrandHB) != [],
         residues[index - 1].flags.contains(.phiPsiStrand),
         residues[index].flags.contains(.paraStrandSkip),
         residues[index].flags.contains(.phiPsiStrand),
         residues[index + 1].flags.intersection(.paraStrandHB) != [],
         residues[index + 1].flags.contains(.phiPsiStrand)
      {
        residues[index - 1].assignment = "S"
        residues[index].assignment = "S"
        residues[index + 1].assignment = "S"
      }
    }
  }
  
  private static func filterShortSegments(residues: inout [DssResidue])
  {
    let count: Int = residues.count
    var repeatFiltering: Bool = true
    
    while repeatFiltering
    {
      repeatFiltering = false
      
      for index in breakSize..<(count - breakSize)
      {
        guard residues[index].isReal else {continue}
        
        if residues[index].assignment == "S",
           residues[index + 1].assignment == "S",
           residues[index - 1].assignment != "S",
           residues[index + 2].assignment != "S"
        {
          residues[index].assignment = "L"
          residues[index + 1].assignment = "L"
          repeatFiltering = true
        }
        
        if residues[index].assignment == "H",
           residues[index + 1].assignment == "H",
           residues[index - 1].assignment != "H",
           residues[index + 2].assignment != "H"
        {
          residues[index].assignment = "L"
          residues[index + 1].assignment = "L"
          repeatFiltering = true
        }
        
        if residues[index].assignment == "S",
           residues[index - 1].assignment != "S",
           residues[index + 1].assignment != "S"
        {
          residues[index].assignment = "L"
          repeatFiltering = true
        }
        
        if residues[index].assignment == "H",
           residues[index - 1].assignment != "H",
           residues[index + 1].assignment != "H"
        {
          residues[index].assignment = "L"
          repeatFiltering = true
        }
        
        if residues[index].assignment == "S",
           residues[index - 1].assignment != "S" || residues[index + 1].assignment != "S",
           !strandHasPartner(at: index, in: residues)
        {
          residues[index].assignment = "L"
          repeatFiltering = true
        }
      }
    }
  }
  
  private static func strandHasPartner(at index: Int, in residues: [DssResidue]) -> Bool
  {
    let residue: DssResidue = residues[index]
    let assignment: Character = residue.assignment
    
    for partner in residue.acceptorPartners where residues[partner].assignment == assignment
    {
      return true
    }
    for partner in residue.donorPartners where residues[partner].assignment == assignment
    {
      return true
    }
    
    if residue.flags.contains(.antiStrandSkip) || residue.flags.contains(.paraStrandSkip)
    {
      if index + 1 < residues.count, residues[index + 1].assignment == assignment
      {
        for partner in residues[index + 1].acceptorPartners where residues[partner].assignment == assignment
        {
          return true
        }
      }
      if index > 0, residues[index - 1].assignment == assignment
      {
        for partner in residues[index - 1].donorPartners where residues[partner].assignment == assignment
        {
          return true
        }
      }
    }
    return false
  }
  
  private static func structureType(for code: Character) -> SKSecondaryStructureType
  {
    switch code
    {
    case "H", "h", "G", "g", "I", "i": return .helix
    case "S", "s", "E", "e", "B", "b": return .sheet
    default: return .coil
    }
  }
  
  private static func wrappedDelta(_ angle: Double, _ target: Double) -> Double
  {
    var delta: Double = abs(angle - target)
    if delta > 180.0 {delta = 360.0 - delta}
    return delta
  }
  
  private static func isProline(_ residue: DssResidue) -> Bool
  {
    return residue.residueName.uppercased() == "PRO"
  }
  
  private static func torsionAngle(_ p0: SIMD3<Double>, _ p1: SIMD3<Double>, _ p2: SIMD3<Double>, _ p3: SIMD3<Double>) -> Double
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
  
  private static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double
  {
    return length(a - b)
  }
}

public enum SKSecondaryStructureAssigner
{
  public static func assign(for chain: SKStrideBackboneChain,
                            method: SKSecondaryStructureAssignmentMethod = .stride) -> [SKSecondaryStructureType]
  {
    switch method
    {
    case .stride: return SKStrideSecondaryStructureAssigner.assign(for: chain)
    case .dss: return SKDssSecondaryStructureAssigner.assign(for: chain)
    case .dssp: return SKDsspSecondaryStructureAssigner.assign(for: chain)
    case .psea: return SKPSeaSecondaryStructureAssigner.assign(for: chain)
    case .sequoia: return SKSequoiaSecondaryStructureAssigner.assign(for: chain)
    case .segno: return SKSegnoSecondaryStructureAssigner.assign(for: chain)
    }
  }
}
