/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation

extension SKStructure
{
  /// Chemical class shown as Cell → Structural Properties → Material Type.
  /// Distinct from `Kind` (crystal / molecule / protein).
  public enum MaterialType: Int, CaseIterable
  {
    case unspecified = 0
    case silica = 1
    case aluminosilicate = 2
    case aluminophosphate = 3
    case metallophosphate = 4
    case silicoaluminophosphate = 5
    case zeolite = 6
    case mof = 7
    case cof = 8
    case zif = 9
    case molecule = 10
    case protein = 11
    case dnaRna = 12
    case molecularCrystal = 13
    case carbon = 14
    case oxide = 15
    case hof = 16
    case paf = 17
    case pim = 18
    case polymer = 19
    case ionicLiquid = 20
    case clay = 21
    case perovskite = 22
    case alloy = 23
    case glass = 24
    
    public var displayName: String
    {
      switch self
      {
      case .unspecified: return "Unspecified"
      case .molecule: return "Molecule"
      case .protein: return "Protein"
      case .dnaRna: return "DNA/RNA"
      case .molecularCrystal: return "Molecular crystal"
      case .silica: return "Silica"
      case .aluminosilicate: return "Aluminosilicate"
      case .aluminophosphate: return "Aluminophosphate"
      case .metallophosphate: return "Metallophosphate"
      case .silicoaluminophosphate: return "Silicoaluminophosphate"
      case .zeolite: return "Zeolite"
      case .mof: return "MOF"
      case .zif: return "ZIF"
      case .cof: return "COF"
      case .carbon: return "Carbon"
      case .oxide: return "Oxide"
      case .hof: return "HOF"
      case .paf: return "PAF"
      case .pim: return "PIM"
      case .polymer: return "Polymer"
      case .ionicLiquid: return "Ionic liquid"
      case .clay: return "Clay"
      case .perovskite: return "Perovskite"
      case .alloy: return "Alloy"
      case .glass: return "Glass"
      }
    }
    
    /// Combo-box order: kind-based types, porous oxides, frameworks, then manual refinements.
    public static var allDisplayNames: [String]
    {
      return [
        unspecified, molecule, protein, dnaRna, molecularCrystal,
        silica, aluminosilicate, aluminophosphate, metallophosphate, silicoaluminophosphate, zeolite,
        mof, zif, cof,
        carbon, oxide,
        hof, paf, pim, polymer, ionicLiquid, clay, perovskite, alloy, glass
      ].map(\.displayName)
    }
    
    /// Resolves a combo-box / project string, including the historical typo
    /// `Silicialuminophosphate`.
    public static func fromDisplayName(_ name: String) -> MaterialType?
    {
      let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.caseInsensitiveCompare("Silicialuminophosphate") == .orderedSame
      {
        return .silicoaluminophosphate
      }
      return allCases.first { $0.displayName.caseInsensitiveCompare(trimmed) == .orderedSame }
    }
    
    /// Zeolite-family types share the Calero/Auerbach aluminosilicate force field.
    public var usesAluminosilicateForceField: Bool
    {
      switch self
      {
      case .zeolite, .silica, .aluminosilicate, .aluminophosphate, .metallophosphate, .silicoaluminophosphate:
        return true
      default:
        return false
      }
    }
    
    /// Classification from Kind plus atom atomic numbers, with optional CIF / file-name hints.
    /// HOF, PAF, PIM, polymer, ionic liquid, clay, perovskite, alloy, and glass are
    /// not inferred — the user can select them in the combo box.
    public static func infer(elementIdentifiers: [Int], kind: Kind, names: [String] = []) -> MaterialType
    {
      switch kind
      {
      case .protein, .proteinCrystal:
        return .protein
      case .dna, .dnaCrystal:
        return .dnaRna
      case .molecule:
        return .molecule
      case .molecularCrystal, .molecularCrystalSolvent:
        return .molecularCrystal
      default:
        break
      }
      
      if isMesoporousSilicaName(names) && isAllSilicaComposition(elementIdentifiers)
      {
        return .silica
      }
      
      let composition = inferComposition(elementIdentifiers)
      if composition != .unspecified
      {
        return composition
      }
      return inferFromNames(names) ?? .unspecified
    }
  }
}

extension SKStructure
{
  /// Sets `materialType` from `kind`, `atoms`, and `displayName`.
  /// Call after a parser has finished filling a frame.
  /// `extraNames` is for CIF `_chemical_name_*` (and similar) hints.
  /// `kind` overrides `self.kind` for classification only (XYZ lattices use
  /// `.molecularCrystal` as object type but still infer composition as a crystal).
  public func applyInferredMaterialType(extraNames: [String] = [], kind: Kind? = nil)
  {
    var names: [String] = extraNames
    if let displayName, !displayName.isEmpty
    {
      names.append(displayName)
    }
    materialType = MaterialType.infer(
      elementIdentifiers: atoms.map(\.elementIdentifier),
      kind: kind ?? self.kind,
      names: names
    )
  }
}

extension SKStructure.MaterialType
{
  /// H, noble gases.
  private static let ignoredAtomicNumbers: Set<Int> = [1, 2, 10, 18, 36, 54, 86]
  /// Alkali and alkaline-earth extra-framework cations (Be is a T-atom, not listed).
  private static let extraFrameworkAtomicNumbers: Set<Int> = [3, 11, 12, 19, 20, 37, 38, 55, 56]
  private static let halogenAtomicNumbers: Set<Int> = [9, 17, 35, 53, 85]
  /// Typical ZIF nodes: Ni, Co, Zn, Cd.
  private static let zifMetalAtomicNumbers: Set<Int> = [27, 28, 30, 48]
  /// Not counted as MOF/ZIF framework metals.
  private static let nonmetalAtomicNumbers: Set<Int> = [
    1, 2, 5, 6, 7, 8, 9, 10, 14, 15, 16, 17, 18, 33, 34, 35, 36, 52, 53, 54, 85, 86
  ]
  
  private static func inferComposition(_ elementIdentifiers: [Int]) -> SKStructure.MaterialType
  {
    let present = Set(elementIdentifiers.filter { $0 > 0 && !ignoredAtomicNumbers.contains($0) })
    guard !present.isEmpty else { return .unspecified }
    
    let hasC = present.contains(6)
    let hasN = present.contains(7)
    let hasO = present.contains(8)
    let hasB = present.contains(5)
    let hasAl = present.contains(13)
    let hasSi = present.contains(14)
    let hasP = present.contains(15)
    let hasGe = present.contains(32)
    let hasGa = present.contains(31)
    let hasAs = present.contains(33)
    let hasBe = present.contains(4)
    
    let isZeoliteFamily = hasO && (
      hasSi ||
      (hasAl && hasP) ||
      (hasAl && hasSi) ||
      hasGe || hasGa || hasAs || hasBe ||
      (hasB && !hasC)
    )
    
    if isZeoliteFamily
    {
      if hasSi && hasAl && hasP
      {
        return .silicoaluminophosphate
      }
      if hasAl && hasP && !hasSi
      {
        if hasNonAlFrameworkMetal(present)
        {
          return .metallophosphate
        }
        return .aluminophosphate
      }
      if hasSi && hasAl && !hasP
      {
        return .aluminosilicate
      }
      if hasSi && hasO && !hasAl && !hasP
      {
        return .zeolite
      }
      if hasP && hasO && hasNonAlFrameworkMetal(present)
      {
        return .metallophosphate
      }
      return .zeolite
    }
    
    if hasC
    {
      let metals = frameworkMetals(present)
      if metals.isEmpty
      {
        if hasB || hasN
        {
          return .cof
        }
        if isCarbonMaterial(elementIdentifiers)
        {
          return .carbon
        }
        return .molecularCrystal
      }
      if !metals.isDisjoint(with: zifMetalAtomicNumbers) && hasN && !hasSi && !hasAl && !hasP
      {
        return .zif
      }
      return .mof
    }
    
    if hasO && !frameworkMetals(present).isEmpty
    {
      return .oxide
    }
    
    // Ice and other non-metal molecular solids (H₂O, …).
    if hasO
    {
      return .molecularCrystal
    }
    
    return .unspecified
  }
  
  /// Graphite, CNT, C60, graphene: carbon-dominated, little or no hydrogen.
  /// Benzene and other hydrocarbons (H comparable to C) are molecular crystals.
  private static func isCarbonMaterial(_ elementIdentifiers: [Int]) -> Bool
  {
    let heavy = elementIdentifiers.filter { $0 > 1 && !ignoredAtomicNumbers.contains($0) }
    let present = Set(heavy)
    let allowed: Set<Int> = [6, 8, 9, 17]
    guard present.contains(6), present.isSubset(of: allowed) else { return false }
    let nC = elementIdentifiers.filter { $0 == 6 }.count
    let nH = elementIdentifiers.filter { $0 == 1 }.count
    return nH == 0 || nC >= nH * 2
  }
  
  private static func frameworkMetals(_ present: Set<Int>) -> Set<Int>
  {
    return present.filter { !nonmetalAtomicNumbers.contains($0) }
  }
  
  private static func hasNonAlFrameworkMetal(_ present: Set<Int>) -> Bool
  {
    return present.contains
    {
      $0 != 13 &&
      !nonmetalAtomicNumbers.contains($0) &&
      !extraFrameworkAtomicNumbers.contains($0) &&
      !halogenAtomicNumbers.contains($0)
    }
  }
  
  private static func isAllSilicaComposition(_ elementIdentifiers: [Int]) -> Bool
  {
    let present = Set(elementIdentifiers.filter { $0 > 0 && !ignoredAtomicNumbers.contains($0) })
    return present.contains(14) && present.contains(8) && !present.contains(13) && !present.contains(15)
  }
  
  /// MCM-41, SBA-15 and related ordered mesoporous silicas — not IZA zeolites.
  private static func isMesoporousSilicaName(_ names: [String]) -> Bool
  {
    let joined = names.joined(separator: " ").uppercased()
    guard !joined.isEmpty else { return false }
    let tokens = ["MCM", "SBA", "FSM", "HMS", "KIT-6", "KIT6", "FDU", "TUD-1", "MESOPOROUS"]
    return tokens.contains { joined.contains($0) }
  }
  
  private static func inferFromNames(_ names: [String]) -> SKStructure.MaterialType?
  {
    let joined = names.joined(separator: " ").uppercased()
    guard !joined.isEmpty else { return nil }
    
    if isMesoporousSilicaName(names) { return .silica }
    if joined.contains("ZIF") { return .zif }
    if joined.contains("COF") { return .cof }
    if joined.contains("MOF") { return .mof }
    if joined.contains("SAPO") || joined.contains("SILICOALUMINOPHOSPHATE") { return .silicoaluminophosphate }
    if joined.contains("ALPO") || joined.contains("ALUMINOPHOSPHATE") { return .aluminophosphate }
    if joined.contains("ZEOLITE") { return .zeolite }
    return nil
  }
}
