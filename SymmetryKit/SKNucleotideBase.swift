/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation

public enum SKNucleotideBaseKind
{
  case unknown
  case adenine
  case cytosine
  case guanine
  case thymine
  case uracil
}

/// Ribbon vertex pad.x codes for PyMOL-style nucleic acid coloring.
public let kNucleicBackboneStructureType: Float = 3.0
public let kNucleicAdenineStructureType: Float = 4.0
public let kNucleicCytosineStructureType: Float = 5.0
public let kNucleicGuanineStructureType: Float = 6.0
public let kNucleicThymineStructureType: Float = 7.0

public enum SKNucleotideBase
{
  public static func baseKindFromResidueName(_ residueName: String) -> SKNucleotideBaseKind
  {
    let name: String = residueName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    switch name
    {
    case "A", "DA", "ADE", "RA", "A5", "RA5":
      return .adenine
    case "C", "DC", "CYT", "RC", "C5", "RC5":
      return .cytosine
    case "G", "DG", "GUA", "RG", "G5", "RG5":
      return .guanine
    case "T", "DT", "THY":
      return .thymine
    case "U", "RU", "URI", "U5", "RU5":
      return .uracil
    default:
      guard name.count >= 2, let last = name.last else {return .unknown}
      return baseKindFromChar(last)
    }
  }

  /// Maps base kind to ribbon shader structure type (backbone uses yellow regardless of base).
  public static func vertexStructureTypeCode(_ baseKind: SKNucleotideBaseKind, backbone: Bool = false) -> Float
  {
    if backbone {return kNucleicBackboneStructureType}
    switch baseKind
    {
    case .adenine: return kNucleicAdenineStructureType
    case .cytosine: return kNucleicCytosineStructureType
    case .guanine: return kNucleicGuanineStructureType
    case .thymine, .uracil: return kNucleicThymineStructureType
    case .unknown: return kNucleicBackboneStructureType
    }
  }

  public static func areWatsonCrickComplementary(_ a: SKNucleotideBaseKind, _ b: SKNucleotideBaseKind) -> Bool
  {
    if a == .unknown || b == .unknown {return false}
    if a == b {return false}
    return complements(a, b)
  }

  public static func areWatsonCrickComplementary(residueNameA: String, residueNameB: String) -> Bool
  {
    return areWatsonCrickComplementary(baseKindFromResidueName(residueNameA),
                                       baseKindFromResidueName(residueNameB))
  }

  /// PyMOL ring_finder 1: ribose ring atom names in bond order.
  public static func riboseRingAtomNames() -> [String]
  {
    return ["C1'", "C2'", "C3'", "C4'", "O4'"]
  }

  /// Base ring atom names in bond order (pyrimidine 6-ring or purine 9-ring subset present in PDB).
  public static func baseRingAtomNames(_ baseKind: SKNucleotideBaseKind) -> [String]
  {
    switch baseKind
    {
    case .cytosine, .thymine, .uracil:
      return ["N1", "C2", "N3", "C4", "C5", "C6"]
    case .adenine, .guanine:
      return ["N9", "C4", "N3", "C2", "N1", "C6", "C5", "N7", "C8"]
    case .unknown:
      return []
    }
  }

  /// Glycosidic anchor: N1 (pyrimidine) or N9 (purine).
  public static func baseAnchorAtomName(_ baseKind: SKNucleotideBaseKind) -> String?
  {
    switch baseKind
    {
    case .cytosine, .thymine, .uracil:
      return "N1"
    case .adenine, .guanine:
      return "N9"
    case .unknown:
      return nil
    }
  }

  private static func baseKindFromChar(_ base: Character) -> SKNucleotideBaseKind
  {
    switch base
    {
    case "A": return .adenine
    case "C": return .cytosine
    case "G": return .guanine
    case "T": return .thymine
    case "U": return .uracil
    default: return .unknown
    }
  }

  private static func complements(_ x: SKNucleotideBaseKind, _ y: SKNucleotideBaseKind) -> Bool
  {
    return (x == .adenine && (y == .thymine || y == .uracil)) ||
           (y == .adenine && (x == .thymine || x == .uracil)) ||
           (x == .guanine && y == .cytosine) ||
           (y == .guanine && x == .cytosine)
  }
}
