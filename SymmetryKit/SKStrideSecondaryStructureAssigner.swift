/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 STRIDE algorithm adapted from Frishman & Argos, Proteins 23:566-579 (1995).
 Original STRIDE implementation (C) 1992-1994 Dmitrij Frishman, MIT License.
 *************************************************************************************************************/

import Foundation
import simd

public enum SKSecondaryStructureType: Sendable
{
  case coil
  case helix
  case sheet
}

public struct SKStrideBackboneResidue: Sendable
{
  public var residueName: String
  public var nitrogen: SIMD3<Double>?
  public var alphaCarbon: SIMD3<Double>?
  public var carbonylCarbon: SIMD3<Double>?
  public var carbonylOxygen: SIMD3<Double>?
  
  public init(residueName: String,
              nitrogen: SIMD3<Double>?,
              alphaCarbon: SIMD3<Double>?,
              carbonylCarbon: SIMD3<Double>?,
              carbonylOxygen: SIMD3<Double>?)
  {
    self.residueName = residueName
    self.nitrogen = nitrogen
    self.alphaCarbon = alphaCarbon
    self.carbonylCarbon = carbonylCarbon
    self.carbonylOxygen = carbonylOxygen
  }
}

public struct SKStrideBackboneChain: Sendable
{
  public var chainIdentifier: Character
  public var residues: [SKStrideBackboneResidue]
  
  public init(chainIdentifier: Character, residues: [SKStrideBackboneResidue])
  {
    self.chainIdentifier = chainIdentifier
    self.residues = residues
  }
}

public enum SKStrideSecondaryStructureAssigner
{
  private struct BackboneResidueState
  {
    var nitrogen: SIMD3<Double>?
    var alphaCarbon: SIMD3<Double>?
    var carbonylCarbon: SIMD3<Double>?
    var carbonylOxygen: SIMD3<Double>?
    var hydrogen: SIMD3<Double>?
    var phiDegrees: Double = 360.0
    var psiDegrees: Double = 360.0
    var assignmentCode: Character = "C"
  }
  
  private struct HydrogenBond
  {
    var donorIndex: Int
    var acceptorIndex: Int
    var energy: Double
    var isPolarInteraction: Bool
    var isBakerHydrogenBond: Bool
  }
  
  private static let undefinedAngle: Double = 360.0
  private static let distanceCutoff: Double = 6.0
  private static let gridMinimumDistance: Double = 3.0
  private static let polarEnergyThreshold: Double = -10.0
  private static let helixScoreThreshold: Double = -230.0
  private static let helixBoundaryProbability: Double = 0.12
  private static let helixTrailingProbability: Double = 0.06
  private static let sheetScoreThreshold: Double = -240.0
  private static let helixTorsionWeight: Double = 1.0
  private static let sheetTorsionWeight: Double = 0.2
  private static let sheetTorsionOffset: Double = -0.2
  private static let minimumSegmentLength: Int = 3
  private static let helixTorsionFallback: Double = 0.15
  private static let sheetTorsionFallback: Double = 0.08
  private static let bakerHydrogenBondEnergy: Double = -450.0
  private static let helixBakerScoreThreshold: Double = -150.0
  private static let sheetBridgeProbability: Double = 0.05
  
  public static func assign(for chain: SKStrideBackboneChain) -> [SKSecondaryStructureType]
  {
    let residues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard residues.count >= 2 else {return []}
    
    var states: [BackboneResidueState] = buildStates(for: residues)
    computeBackboneAngles(states: &states)
    placeBackboneHydrogens(states: &states, residueNames: residues.map{$0.residueName})
    
    let hydrogenBonds: [HydrogenBond] = findMainChainHydrogenBonds(states: states)
    assignHelices(states: &states, hydrogenBonds: hydrogenBonds)
    assignSheets(states: &states, hydrogenBonds: hydrogenBonds)
    filterShortSegments(states: &states)
    
    return states.map{structureType(for: $0.assignmentCode)}
  }
  
  private static func buildStates(for residues: [SKStrideBackboneResidue]) -> [BackboneResidueState]
  {
    return residues.map
    { residue in
      var state: BackboneResidueState = BackboneResidueState()
      state.nitrogen = residue.nitrogen
      state.alphaCarbon = residue.alphaCarbon
      state.carbonylCarbon = residue.carbonylCarbon
      state.carbonylOxygen = residue.carbonylOxygen
      return state
    }
  }
  
  private static func computeBackboneAngles(states: inout [BackboneResidueState])
  {
    let count: Int = states.count
    for index in 0..<count
    {
      if index > 0,
         let previousCarbon: SIMD3<Double> = states[index - 1].carbonylCarbon,
         let nitrogen: SIMD3<Double> = states[index].nitrogen,
         let alphaCarbon: SIMD3<Double> = states[index].alphaCarbon,
         let carbonylCarbon: SIMD3<Double> = states[index].carbonylCarbon
      {
        states[index].phiDegrees = torsionAngle(previousCarbon, nitrogen, alphaCarbon, carbonylCarbon)
      }
      
      if index + 1 < count,
         let nitrogen: SIMD3<Double> = states[index].nitrogen,
         let alphaCarbon: SIMD3<Double> = states[index].alphaCarbon,
         let carbonylCarbon: SIMD3<Double> = states[index].carbonylCarbon,
         let nextNitrogen: SIMD3<Double> = states[index + 1].nitrogen
      {
        states[index].psiDegrees = torsionAngle(nitrogen, alphaCarbon, carbonylCarbon, nextNitrogen)
      }
    }
    
    for index in 0..<count
    {
      if index > 0 && states[index].psiDegrees >= undefinedAngle
      {
        states[index].psiDegrees = states[index - 1].psiDegrees
      }
      if index + 1 < count && states[index].phiDegrees >= undefinedAngle
      {
        states[index].phiDegrees = states[index + 1].phiDegrees
      }
    }
  }
  
  private static func placeBackboneHydrogens(states: inout [BackboneResidueState], residueNames: [String])
  {
    for index in 1..<states.count
    {
      if residueNames[index].uppercased() == "PRO" {continue}
      guard let nitrogen: SIMD3<Double> = states[index].nitrogen,
            let alphaCarbon: SIMD3<Double> = states[index].alphaCarbon,
            let previousCarbon: SIMD3<Double> = states[index - 1].carbonylCarbon else {continue}
      
      var direction: SIMD3<Double> = -(previousCarbon - nitrogen) / length(previousCarbon - nitrogen)
      direction += -(alphaCarbon - nitrogen) / length(alphaCarbon - nitrogen)
      let directionLength: Double = length(direction)
      guard directionLength > 1.0e-12 else {continue}
      states[index].hydrogen = nitrogen + (direction / directionLength)
    }
  }
  
  private static func findMainChainHydrogenBonds(states: [BackboneResidueState]) -> [HydrogenBond]
  {
    var bonds: [HydrogenBond] = []
    let count: Int = states.count
    
    for donorIndex in 0..<count
    {
      guard let hydrogen: SIMD3<Double> = states[donorIndex].hydrogen,
            let donorNitrogen: SIMD3<Double> = states[donorIndex].nitrogen,
            let donorPreviousCarbon: SIMD3<Double> = donorIndex > 0 ? states[donorIndex - 1].carbonylCarbon : nil else {continue}
      
      for acceptorIndex in 0..<count
      {
        if abs(donorIndex - acceptorIndex) < 2 {continue}
        guard let acceptorOxygen: SIMD3<Double> = states[acceptorIndex].carbonylOxygen,
              let acceptorCarbon: SIMD3<Double> = states[acceptorIndex].carbonylCarbon,
              let acceptorAlphaCarbon: SIMD3<Double> = states[acceptorIndex].alphaCarbon else {continue}
        
        if distance(hydrogen, acceptorOxygen) > distanceCutoff {continue}
        
        let components: (energy: Double, tangential: Double, planar: Double) = gridHydrogenBondEnergy(acceptorOxygen: acceptorOxygen,
                                                                                                       acceptorCarbon: acceptorCarbon,
                                                                                                       acceptorAlphaCarbon: acceptorAlphaCarbon,
                                                                                                       hydrogen: hydrogen,
                                                                                                       donorNitrogen: donorNitrogen)
        let isPolar: Bool = components.energy < polarEnergyThreshold &&
          abs(components.tangential) > 1.0e-6 &&
          abs(components.planar) > 1.0e-6
        
        let isGeometric: Bool = distance(hydrogen, acceptorOxygen) <= 2.5 &&
          angle(donorNitrogen, hydrogen, acceptorOxygen) >= 90.0 &&
          angle(acceptorCarbon, acceptorOxygen, hydrogen) >= 90.0 &&
          angle(acceptorOxygen, donorNitrogen, donorPreviousCarbon) >= 90.0 &&
          angle(acceptorOxygen, donorNitrogen, donorPreviousCarbon) <= 180.0
        
        if isPolar || isGeometric
        {
          bonds.append(HydrogenBond(donorIndex: donorIndex,
                                    acceptorIndex: acceptorIndex,
                                    energy: components.energy,
                                    isPolarInteraction: isPolar,
                                    isBakerHydrogenBond: isGeometric))
        }
      }
    }
    return bonds
  }
  
  private static func assignHelices(states: inout [BackboneResidueState], hydrogenBonds: [HydrogenBond])
  {
    let count: Int = states.count
    guard count >= 6 else {return}
    
    var helixScore: [Double] = [Double](repeating: 0.0, count: count)
    for startIndex in 0..<(count - 5)
    {
      guard hasValidHelixAngles(states: states, startIndex: startIndex) else {continue}
      
      let torsionConfidence: Double = 0.5 * (helixProbability(states[startIndex]) + helixProbability(states[startIndex + 4]))
      if let bondEnergy: Double = helixBondEnergy(donorIndex: startIndex + 4,
                                                  acceptorIndex: startIndex,
                                                  torsionConfidence: torsionConfidence,
                                                  hydrogenBonds: hydrogenBonds)
      {
        helixScore[startIndex] = bondEnergy
      }
    }
    
    for startIndex in 0..<(count - 5)
    {
      if helixScore[startIndex] < helixScoreThreshold && helixScore[startIndex + 1] < helixScoreThreshold
      {
        for offset in 1...4
        {
          states[startIndex + offset].assignmentCode = "H"
        }
        if helixProbability(states[startIndex]) > helixBoundaryProbability
        {
          states[startIndex].assignmentCode = "H"
        }
        if startIndex + 5 < count && helixProbability(states[startIndex + 5]) > helixTrailingProbability
        {
          states[startIndex + 5].assignmentCode = "H"
        }
      }
      else if helixScore[startIndex] < helixBakerScoreThreshold &&
              helixScore[startIndex + 1] < helixBakerScoreThreshold
      {
        for offset in 1...4
        {
          states[startIndex + offset].assignmentCode = "H"
        }
      }
    }
  }
  
  private static func assignSheets(states: inout [BackboneResidueState], hydrogenBonds: [HydrogenBond])
  {
    let count: Int = states.count
    for bond in hydrogenBonds where bond.isPolarInteraction || bond.isBakerHydrogenBond
    {
      let donorIndex: Int = bond.donorIndex
      let acceptorIndex: Int = bond.acceptorIndex
      if abs(donorIndex - acceptorIndex) < 3 {continue}
      if states[acceptorIndex].assignmentCode == "H" || states[donorIndex].assignmentCode == "H" {continue}
      
      let torsionConfidence: Double = 0.5 * (sheetProbability(states[donorIndex]) + sheetProbability(states[acceptorIndex]))
      guard torsionConfidence >= sheetTorsionFallback else {continue}
      
      let bondEnergy: Double = bond.isPolarInteraction ? bond.energy : bakerHydrogenBondEnergy
      let score: Double = bondEnergy * (1.0 + sheetTorsionOffset + sheetTorsionWeight * torsionConfidence)
      if score >= sheetScoreThreshold {continue}
      
      if states[acceptorIndex].assignmentCode == "C"
      {
        states[acceptorIndex].assignmentCode = "E"
      }
      if states[donorIndex].assignmentCode == "C"
      {
        states[donorIndex].assignmentCode = "E"
      }
    }
    
    for index in 1..<(count - 1)
    {
      if states[index].assignmentCode == "C" &&
         states[index - 1].assignmentCode == "E" &&
         states[index + 1].assignmentCode == "E" &&
         sheetProbability(states[index]) > sheetBridgeProbability
      {
        states[index].assignmentCode = "E"
      }
    }
  }
  
  private static func hasValidHelixAngles(states: [BackboneResidueState], startIndex: Int) -> Bool
  {
    for offset in 0...4
    {
      let index: Int = startIndex + offset
      if states[index].phiDegrees >= undefinedAngle || states[index].psiDegrees >= undefinedAngle
      {
        return false
      }
    }
    return true
  }
  
  private static func helixBondEnergy(donorIndex: Int,
                                      acceptorIndex: Int,
                                      torsionConfidence: Double,
                                      hydrogenBonds: [HydrogenBond]) -> Double?
  {
    guard torsionConfidence >= helixTorsionFallback else {return nil}
    
    for bond in hydrogenBonds
    {
      guard bond.donorIndex == donorIndex && bond.acceptorIndex == acceptorIndex else {continue}
      if bond.isPolarInteraction
      {
        return bond.energy * helixTorsionWeight * torsionConfidence
      }
      if bond.isBakerHydrogenBond
      {
        return bakerHydrogenBondEnergy * helixTorsionWeight * torsionConfidence
      }
    }
    return nil
  }
  
  private static func helixProbability(_ state: BackboneResidueState) -> Double
  {
    return SKStrideRamachandranMaps.probability(map: SKStrideRamachandranMaps.helixProbabilityMap,
                                                phiDegrees: state.phiDegrees,
                                                psiDegrees: state.psiDegrees)
  }
  
  private static func sheetProbability(_ state: BackboneResidueState) -> Double
  {
    return SKStrideRamachandranMaps.probability(map: SKStrideRamachandranMaps.sheetProbabilityMap,
                                                phiDegrees: state.phiDegrees,
                                                psiDegrees: state.psiDegrees)
  }
  
  private static func structureType(for code: Character) -> SKSecondaryStructureType
  {
    switch code
    {
    case "H", "G", "I":
      return .helix
    case "E", "B", "b":
      return .sheet
    default:
      return .coil
    }
  }
  
  private static func filterShortSegments(states: inout [BackboneResidueState])
  {
    var index: Int = 0
    while index < states.count
    {
      let code: Character = states[index].assignmentCode
      var end: Int = index + 1
      while end < states.count && states[end].assignmentCode == code
      {
        end += 1
      }
      if code != "C" && end - index < minimumSegmentLength
      {
        for position in index..<end
        {
          states[position].assignmentCode = "C"
        }
      }
      index = end
    }
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
    if length0 < 1.0e-12 || length1 < 1.0e-12 {return undefinedAngle}
    normal0 /= length0
    normal1 /= length1
    
    var scalar: Double = dot(normal0, normal1)
    scalar = min(max(scalar, -1.0 + 1.0e-6), 1.0 - 1.0e-6)
    let absoluteAngle: Double = acos(scalar) * 180.0 / Double.pi
    let tripleScalar: Double = dot(bond0, normal1)
    return tripleScalar > 0.0 ? absoluteAngle : -absoluteAngle
  }
  
  private static func gridHydrogenBondEnergy(acceptorOxygen: SIMD3<Double>,
                                             acceptorCarbon: SIMD3<Double>,
                                             acceptorAlphaCarbon: SIMD3<Double>,
                                             hydrogen: SIMD3<Double>,
                                             donorNitrogen: SIMD3<Double>) -> (energy: Double, tangential: Double, planar: Double)
  {
    let acceptorHydrogenDistance: Double = max(distance(acceptorOxygen, hydrogen), gridMinimumDistance)
    let radialEnergy: Double = gridConstantsC / pow(acceptorHydrogenDistance, 8.0) - gridConstantsD / pow(acceptorHydrogenDistance, 6.0)
    
    let projectedHydrogen: SIMD3<Double> = projectOntoPlane(point: hydrogen,
                                                              planePoint0: acceptorOxygen,
                                                              planePoint1: acceptorCarbon,
                                                              planePoint2: acceptorAlphaCarbon)
    let ti: Double = abs(180.0 - angle(projectedHydrogen, acceptorOxygen, acceptorCarbon))
    let to: Double = angle(hydrogen, acceptorOxygen, projectedHydrogen)
    let planarAngle: Double = angle(donorNitrogen, hydrogen, acceptorOxygen)
    
    let tangentialComponent: Double
    if ti < 90.0
    {
      tangentialComponent = cos(to * Double.pi / 180.0) * (0.9 + 0.1 * sin(2.0 * ti * Double.pi / 180.0))
    }
    else if ti < 110.0
    {
      tangentialComponent = gridK1 * cos(to * Double.pi / 180.0) * pow(gridK2 - pow(cos(ti * Double.pi / 180.0), 2.0), 3.0)
    }
    else
    {
      tangentialComponent = 0.0
    }
    
    let planarComponent: Double = (planarAngle > 90.0 && planarAngle < 270.0) ? pow(cos(planarAngle * Double.pi / 180.0), 2.0) : 0.0
    let energy: Double = 1000.0 * radialEnergy * tangentialComponent * planarComponent
    return (energy, tangentialComponent, planarComponent)
  }
  
  private static let gridMinimumRadius: Double = 3.0
  private static let gridEnergyMinimum: Double = -2.8
  private static let gridConstantsC: Double = -3.0 * (-2.8) * pow(3.0, 8.0)
  private static let gridConstantsD: Double = -4.0 * (-2.8) * pow(3.0, 6.0)
  private static let gridK1: Double = 0.9 / pow(cos(110.0 * Double.pi / 180.0), 6.0)
  private static let gridK2: Double = pow(cos(110.0 * Double.pi / 180.0), 2.0)
  
  private static func projectOntoPlane(point: SIMD3<Double>,
                                       planePoint0: SIMD3<Double>,
                                       planePoint1: SIMD3<Double>,
                                       planePoint2: SIMD3<Double>) -> SIMD3<Double>
  {
    let normal: SIMD3<Double> = normalize(cross(planePoint1 - planePoint0, planePoint2 - planePoint1))
    let vector: SIMD3<Double> = point - planePoint0
    return point - dot(vector, normal) * normal
  }
  
  private static func angle(_ p0: SIMD3<Double>, _ p1: SIMD3<Double>, _ p2: SIMD3<Double>) -> Double
  {
    let vector0: SIMD3<Double> = p0 - p1
    let vector1: SIMD3<Double> = p2 - p1
    let length0: Double = length(vector0)
    let length1: Double = length(vector1)
    if length0 < 1.0e-12 || length1 < 1.0e-12 {return 0.0}
    var scalar: Double = dot(vector0, vector1) / (length0 * length1)
    scalar = min(max(scalar, -1.0 + 1.0e-6), 1.0 - 1.0e-6)
    return acos(scalar) * 180.0 / Double.pi
  }
  
  private static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double
  {
    return length(a - b)
  }
}
