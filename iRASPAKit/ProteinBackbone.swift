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
import SymmetryKit

public struct ProteinBackboneResidue
{
  public var residueName: String
  public var residueSequenceNumber: Int
  public var codeForInsertionOfResidues: Character
  public var nitrogen: SKAsymmetricAtom?
  public var alphaCarbon: SKAsymmetricAtom?
  public var carbonylCarbon: SKAsymmetricAtom?
  public var carbonylOxygen: SKAsymmetricAtom?
  
  public var backboneAtoms: [SKAsymmetricAtom]
  {
    return [nitrogen, alphaCarbon, carbonylCarbon, carbonylOxygen].compactMap{$0}
  }
  
  public init(residueName: String, residueSequenceNumber: Int, codeForInsertionOfResidues: Character, nitrogen: SKAsymmetricAtom?, alphaCarbon: SKAsymmetricAtom?, carbonylCarbon: SKAsymmetricAtom?, carbonylOxygen: SKAsymmetricAtom?)
  {
    self.residueName = residueName
    self.residueSequenceNumber = residueSequenceNumber
    self.codeForInsertionOfResidues = codeForInsertionOfResidues
    self.nitrogen = nitrogen
    self.alphaCarbon = alphaCarbon
    self.carbonylCarbon = carbonylCarbon
    self.carbonylOxygen = carbonylOxygen
  }
}

public struct ProteinBackboneChain
{
  public var chainIdentifier: Character
  public var residues: [ProteinBackboneResidue]
  
  public init(chainIdentifier: Character, residues: [ProteinBackboneResidue])
  {
    self.chainIdentifier = chainIdentifier
    self.residues = residues
  }
}

public struct ProteinBackbone
{
  public var chains: [ProteinBackboneChain] = []
  
  public init(chains: [ProteinBackboneChain] = [])
  {
    self.chains = chains
  }
  
  public var alphaCarbonResidueCount: Int
  {
    return chains.reduce(0) { partial, chain in
      partial + chain.residues.reduce(0) { $0 + ($1.alphaCarbon == nil ? 0 : 1) }
    }
  }
  
  public static func build(from atoms: [SKAsymmetricAtom]) -> ProteinBackbone
  {
    struct ResidueKey: Hashable
    {
      let chainIdentifier: Character
      let residueSequenceNumber: Int
      let codeForInsertionOfResidues: Character
    }
    
    struct MutableResidue
    {
      var residueName: String
      var nitrogen: SKAsymmetricAtom?
      var alphaCarbon: SKAsymmetricAtom?
      var carbonylCarbon: SKAsymmetricAtom?
      var carbonylOxygen: SKAsymmetricAtom?
    }
    
    var chainOrder: [Character] = []
    var residuesByChain: [Character: [ResidueKey: MutableResidue]] = [:]
    var residueOrderByChain: [Character: [ResidueKey]] = [:]
    
    for atom in atoms
    {
      guard let role: SKElement.SKBackboneAtomRole = atom.backboneAtomRole else {continue}
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
        residuesByChain[atom.chainIdentifier]![key] = MutableResidue(residueName: atom.residueName)
      }
      
      var residue: MutableResidue = residuesByChain[atom.chainIdentifier]![key]!
      switch role
      {
      case .nitrogen:
        residue.nitrogen = atom
      case .alphaCarbon:
        residue.alphaCarbon = atom
      case .carbonylCarbon:
        residue.carbonylCarbon = atom
      case .carbonylOxygen:
        let atomName: String = atom.displayName.uppercased().trimmingCharacters(in: .whitespaces)
        if let existing: SKAsymmetricAtom = residue.carbonylOxygen
        {
          let existingName: String = existing.displayName.uppercased().trimmingCharacters(in: .whitespaces)
          if existingName != "O" || atomName != "OXT"
          {
            residue.carbonylOxygen = atom
          }
        }
        else
        {
          residue.carbonylOxygen = atom
        }
      }
      residuesByChain[atom.chainIdentifier]![key] = residue
    }
    
    var backbone: ProteinBackbone = ProteinBackbone()
    for chainId in chainOrder
    {
      guard let residueMap: [ResidueKey: MutableResidue] = residuesByChain[chainId],
            let residueKeys: [ResidueKey] = residueOrderByChain[chainId] else {continue}
      
      let sortedKeys: [ResidueKey] = residueKeys.sorted
      {
        if $0.residueSequenceNumber != $1.residueSequenceNumber
        {
          return $0.residueSequenceNumber < $1.residueSequenceNumber
        }
        return $0.codeForInsertionOfResidues < $1.codeForInsertionOfResidues
      }
      
      let residues: [ProteinBackboneResidue] = sortedKeys.compactMap
      { key in
        guard let mutableResidue: MutableResidue = residueMap[key] else {return nil}
        return ProteinBackboneResidue(residueName: mutableResidue.residueName,
                                      residueSequenceNumber: key.residueSequenceNumber,
                                      codeForInsertionOfResidues: key.codeForInsertionOfResidues,
                                      nitrogen: mutableResidue.nitrogen,
                                      alphaCarbon: mutableResidue.alphaCarbon,
                                      carbonylCarbon: mutableResidue.carbonylCarbon,
                                      carbonylOxygen: mutableResidue.carbonylOxygen)
      }
      backbone.chains.append(ProteinBackboneChain(chainIdentifier: chainId, residues: residues))
    }
    
    return backbone
  }
}
