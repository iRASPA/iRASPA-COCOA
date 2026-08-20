/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation

public enum SKNucleotide
{
  private static let residueNames: Set<String> = [
    "A", "C", "G", "T", "U",
    "DA", "DC", "DG", "DT",
    "ADE", "CYT", "GUA", "THY", "URI",
    "RA", "RC", "RG", "RU",
    "A5", "C5", "G5", "U5",
    "RA5", "RC5", "RG5", "RU5"
  ]

  public static func isNucleotideResidueName(_ residueName: String) -> Bool
  {
    return residueNames.contains(residueName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
  }

  public static func normalizedAtomName(_ atomName: String) -> String
  {
    return atomName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "*", with: "'")
  }
}
