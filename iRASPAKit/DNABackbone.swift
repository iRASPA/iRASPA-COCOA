/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 DNA backbone trace follows PyMOL cartoon_nucleic_acid_mode 4 (O5' / phosphate / O3' centerline, C2'/C3' orientation).
 *************************************************************************************************************/

import Foundation
import SymmetryKit

public enum DNABackboneAtomRole
{
  case phosphate
  case o5Prime
  case c5Prime
  case c4Prime
  case o4Prime
  case c1Prime
  case c2Prime
  case c3Prime
  case o3Prime
}

public func dnaBackboneAtomRole(for atom: SKAsymmetricAtom) -> DNABackboneAtomRole?
{
  guard SKNucleotide.isNucleotideResidueName(atom.residueName) else {return nil}
  return dnaBackboneAtomRoleForName(atom.displayName)
}

private func dnaBackboneAtomRoleForName(_ atomName: String) -> DNABackboneAtomRole?
{
  let name: String = SKNucleotide.normalizedAtomName(atomName)
  switch name
  {
  case "P": return .phosphate
  case "O5'": return .o5Prime
  case "C5'": return .c5Prime
  case "C4'": return .c4Prime
  case "O4'": return .o4Prime
  case "C1'": return .c1Prime
  case "C2'": return .c2Prime
  case "C3'": return .c3Prime
  case "O3'": return .o3Prime
  default: return nil
  }
}

public struct DNABackboneResidue
{
  public var residueName: String
  public var residueSequenceNumber: Int
  public var codeForInsertionOfResidues: Character
  public var phosphate: SKAsymmetricAtom?
  public var o5Prime: SKAsymmetricAtom?
  public var c5Prime: SKAsymmetricAtom?
  public var c4Prime: SKAsymmetricAtom?
  public var o4Prime: SKAsymmetricAtom?
  public var c1Prime: SKAsymmetricAtom?
  public var c2Prime: SKAsymmetricAtom?
  public var c3Prime: SKAsymmetricAtom?
  public var o3Prime: SKAsymmetricAtom?

  public init(residueName: String,
              residueSequenceNumber: Int,
              codeForInsertionOfResidues: Character,
              phosphate: SKAsymmetricAtom?,
              o5Prime: SKAsymmetricAtom?,
              c5Prime: SKAsymmetricAtom?,
              c4Prime: SKAsymmetricAtom?,
              o4Prime: SKAsymmetricAtom?,
              c1Prime: SKAsymmetricAtom?,
              c2Prime: SKAsymmetricAtom?,
              c3Prime: SKAsymmetricAtom?,
              o3Prime: SKAsymmetricAtom?)
  {
    self.residueName = residueName
    self.residueSequenceNumber = residueSequenceNumber
    self.codeForInsertionOfResidues = codeForInsertionOfResidues
    self.phosphate = phosphate
    self.o5Prime = o5Prime
    self.c5Prime = c5Prime
    self.c4Prime = c4Prime
    self.o4Prime = o4Prime
    self.c1Prime = c1Prime
    self.c2Prime = c2Prime
    self.c3Prime = c3Prime
    self.o3Prime = o3Prime
  }

  public func ribbonCenterAtom() -> SKAsymmetricAtom?
  {
    if let phosphate: SKAsymmetricAtom = phosphate {return phosphate}
    if let c1Prime: SKAsymmetricAtom = c1Prime {return c1Prime}
    return c4Prime
  }

  public var backboneAtoms: [SKAsymmetricAtom]
  {
    return [phosphate, o5Prime, c5Prime, c4Prime, o4Prime, c1Prime, c3Prime, o3Prime].compactMap{$0}
  }
}

public struct DNABackboneChain
{
  public var chainIdentifier: Character
  public var residues: [DNABackboneResidue]

  public init(chainIdentifier: Character, residues: [DNABackboneResidue])
  {
    self.chainIdentifier = chainIdentifier
    self.residues = residues
  }
}

public struct DNABackbone
{
  public var chains: [DNABackboneChain] = []

  public init(chains: [DNABackboneChain] = [])
  {
    self.chains = chains
  }

  public var nucleotideResidueCount: Int
  {
    return chains.reduce(0) { partial, chain in
      partial + chain.residues.reduce(0) { $0 + ($1.ribbonCenterAtom() == nil ? 0 : 1) }
    }
  }

  public static func build(from atoms: [SKAsymmetricAtom]) -> DNABackbone
  {
    struct ResidueKey: Hashable, Comparable
    {
      let chainIdentifier: Character
      let residueSequenceNumber: Int
      let codeForInsertionOfResidues: Character

      static func < (lhs: ResidueKey, rhs: ResidueKey) -> Bool
      {
        if lhs.chainIdentifier != rhs.chainIdentifier {return lhs.chainIdentifier < rhs.chainIdentifier}
        if lhs.residueSequenceNumber != rhs.residueSequenceNumber {return lhs.residueSequenceNumber < rhs.residueSequenceNumber}
        return lhs.codeForInsertionOfResidues < rhs.codeForInsertionOfResidues
      }
    }

    struct MutableResidue
    {
      var residueName: String
      var phosphate: SKAsymmetricAtom?
      var o5Prime: SKAsymmetricAtom?
      var c5Prime: SKAsymmetricAtom?
      var c4Prime: SKAsymmetricAtom?
      var o4Prime: SKAsymmetricAtom?
      var c1Prime: SKAsymmetricAtom?
      var c2Prime: SKAsymmetricAtom?
      var c3Prime: SKAsymmetricAtom?
      var o3Prime: SKAsymmetricAtom?
    }

    func assignRole(_ residue: inout MutableResidue, role: DNABackboneAtomRole, atom: SKAsymmetricAtom)
    {
      switch role
      {
      case .phosphate: residue.phosphate = atom
      case .o5Prime: residue.o5Prime = atom
      case .c5Prime: residue.c5Prime = atom
      case .c4Prime: residue.c4Prime = atom
      case .o4Prime: residue.o4Prime = atom
      case .c1Prime: residue.c1Prime = atom
      case .c2Prime: residue.c2Prime = atom
      case .c3Prime: residue.c3Prime = atom
      case .o3Prime: residue.o3Prime = atom
      }
    }

    var chainOrder: [Character] = []
    var residuesByChain: [Character: [ResidueKey: MutableResidue]] = [:]
    var residueOrderByChain: [Character: [ResidueKey]] = [:]

    for atom in atoms
    {
      guard SKNucleotide.isNucleotideResidueName(atom.residueName) else {continue}
      guard let role: DNABackboneAtomRole = dnaBackboneAtomRole(for: atom) else {continue}
      atom.backBoneAtom = true

      let key: ResidueKey = ResidueKey(chainIdentifier: atom.chainIdentifier,
                                       residueSequenceNumber: atom.residueSequenceNumber,
                                       codeForInsertionOfResidues: atom.codeForInsertionOfResidues)

      if residuesByChain[atom.chainIdentifier] == nil
      {
        chainOrder.append(atom.chainIdentifier)
        residuesByChain[atom.chainIdentifier] = [:]
        residueOrderByChain[atom.chainIdentifier] = []
      }

      if residuesByChain[atom.chainIdentifier]![key] == nil
      {
        residueOrderByChain[atom.chainIdentifier]!.append(key)
        residuesByChain[atom.chainIdentifier]![key] = MutableResidue(residueName: atom.residueName,
                                                                   phosphate: nil,
                                                                   o5Prime: nil,
                                                                   c5Prime: nil,
                                                                   c4Prime: nil,
                                                                   o4Prime: nil,
                                                                   c1Prime: nil,
                                                                   c2Prime: nil,
                                                                   c3Prime: nil,
                                                                   o3Prime: nil)
      }

      var residue: MutableResidue = residuesByChain[atom.chainIdentifier]![key]!
      assignRole(&residue, role: role, atom: atom)
      residuesByChain[atom.chainIdentifier]![key] = residue
    }

    var backbone: DNABackbone = DNABackbone()
    for chainId in chainOrder
    {
      guard let residueMap: [ResidueKey: MutableResidue] = residuesByChain[chainId],
            let residueKeys: [ResidueKey] = residueOrderByChain[chainId] else {continue}

      let sortedKeys: [ResidueKey] = residueKeys.sorted()
      let residues: [DNABackboneResidue] = sortedKeys.compactMap
      { key in
        guard let mutableResidue: MutableResidue = residueMap[key] else {return nil}
        let residue: DNABackboneResidue = DNABackboneResidue(residueName: mutableResidue.residueName,
                                                             residueSequenceNumber: key.residueSequenceNumber,
                                                             codeForInsertionOfResidues: key.codeForInsertionOfResidues,
                                                             phosphate: mutableResidue.phosphate,
                                                             o5Prime: mutableResidue.o5Prime,
                                                             c5Prime: mutableResidue.c5Prime,
                                                             c4Prime: mutableResidue.c4Prime,
                                                             o4Prime: mutableResidue.o4Prime,
                                                             c1Prime: mutableResidue.c1Prime,
                                                             c2Prime: mutableResidue.c2Prime,
                                                             c3Prime: mutableResidue.c3Prime,
                                                             o3Prime: mutableResidue.o3Prime)
        return residue.ribbonCenterAtom() == nil ? nil : residue
      }
      if !residues.isEmpty
      {
        backbone.chains.append(DNABackboneChain(chainIdentifier: chainId, residues: residues))
      }
    }
    return backbone
  }

  public func toProteinBackbone() -> ProteinBackbone
  {
    var proteinChains: [ProteinBackboneChain] = []
    proteinChains.reserveCapacity(chains.count)
    for chain in chains
    {
      var proteinResidues: [ProteinBackboneResidue] = []
      proteinResidues.reserveCapacity(chain.residues.count)
      for residue in chain.residues
      {
        guard let centerAtom: SKAsymmetricAtom = residue.ribbonCenterAtom() else {continue}
        proteinResidues.append(ProteinBackboneResidue(residueName: residue.residueName,
                                                        residueSequenceNumber: residue.residueSequenceNumber,
                                                        codeForInsertionOfResidues: residue.codeForInsertionOfResidues,
                                                        nitrogen: residue.c2Prime ?? residue.o4Prime,
                                                        alphaCarbon: centerAtom,
                                                        carbonylCarbon: residue.c3Prime ?? residue.c5Prime,
                                                        carbonylOxygen: residue.c2Prime ?? residue.o3Prime))
      }
      if !proteinResidues.isEmpty
      {
        proteinChains.append(ProteinBackboneChain(chainIdentifier: chain.chainIdentifier, residues: proteinResidues))
      }
    }
    return ProteinBackbone(chains: proteinChains)
  }
}
