/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation
import SymmetryKit

public enum ProteinRibbonSecondaryStructureMethod: String, CaseIterable, Sendable
{
  case stride = "STRIDE"
  case dss = "DSS"
  case dssp = "DSSP"
  case psea = "P-SEA"
  case sequoia = "Sequoia"
  case segno = "SEGNO"
  
  public var displayName: String
  {
    return self.rawValue
  }
  
  public var assignmentMethod: SKSecondaryStructureAssignmentMethod
  {
    switch self
    {
    case .stride: return .stride
    case .dss: return .dss
    case .dssp: return .dssp
    case .psea: return .psea
    case .sequoia: return .sequoia
    case .segno: return .segno
    }
  }
}
