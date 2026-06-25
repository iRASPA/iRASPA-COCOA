/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation

public extension SKSpacegroup
{
  /// Returns true when both operation lists describe the same symmetry set (order independent).
  public static func symmetryOperationsMatch(_ lhs: [SKSeitzIntegerMatrix], _ rhs: [SKSeitzIntegerMatrix]) -> Bool
  {
    guard lhs.count == rhs.count else
    {
      return false
    }
    return Set(lhs) == Set(rhs)
  }
  
  /// Identifies the Hall setting whose database operations match the CIF symmetry operations.
  public static func identifyHallNumber(fromCIFSymmetryOperations operations: [SKSeitzIntegerMatrix], candidateHallNumbers: [Int]) -> Int?
  {
    guard !operations.isEmpty else
    {
      return nil
    }
    
    var matches: [Int] = []
    matches.reserveCapacity(4)
    
    for hallNumber in candidateHallNumbers
    {
      guard hallNumber >= 1 && hallNumber <= 530 else
      {
        continue
      }
      let databaseOperations: [SKSeitzIntegerMatrix] = SKSpacegroup(HallNumber: hallNumber).spaceGroupSetting.fullSeitzMatrices.operations
      if symmetryOperationsMatch(operations, databaseOperations)
      {
        matches.append(hallNumber)
      }
    }
    
    guard !matches.isEmpty else
    {
      return nil
    }
    
    if matches.count == 1
    {
      return matches[0]
    }
    
    // Prefer the reference setting when multiple Hall symbols share the same operation set.
    let referenceMatches: [Int] = matches.filter { SKSpacegroup.spaceGroupData[$0].standard }
    if referenceMatches.count == 1
    {
      return referenceMatches[0]
    }
    if !referenceMatches.isEmpty
    {
      return referenceMatches[0]
    }
    
    return matches[0]
  }
  
  /// Candidate Hall numbers for CIF symmetry-operation matching.
  public static func candidateHallNumbers(spaceGroupITNumber: Int, declaredHallNumber: Int?, declaredHMSymbol: String?) -> [Int]
  {
    if let declaredHallNumber = declaredHallNumber, declaredHallNumber >= 1 && declaredHallNumber <= 530
    {
      let spaceGroupNumber: Int = SKSpacegroup.spaceGroupData[declaredHallNumber].spaceGroupNumber
      if let hallsForNumber: [Int] = SKSpacegroup.spaceGroupHallData[spaceGroupNumber]
      {
        return hallsForNumber
      }
      return [declaredHallNumber]
    }
    
    if spaceGroupITNumber > 0, let hallsForNumber: [Int] = SKSpacegroup.spaceGroupHallData[spaceGroupITNumber]
    {
      return hallsForNumber
    }
    
    if let declaredHMSymbol = declaredHMSymbol
    {
      let halls: [Int] = SKSpacegroup.spaceGroupData
        .filter { $0.HM.removeWhitespace() == declaredHMSymbol.removeWhitespace() }
        .map { $0.number }
      if !halls.isEmpty
      {
        return halls
      }
    }
    
    return Array(1...530)
  }
}
