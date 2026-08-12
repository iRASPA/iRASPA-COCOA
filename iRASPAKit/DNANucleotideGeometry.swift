/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import simd
import SymmetryKit

/// Ribose ring, base ring and glycosidic anchor of a single nucleotide, addressed by its PDB residue key.
public struct DNANucleotideResidueGeometry
{
  public var chainIdentifier: Character = " "
  public var residueSequenceNumber: Int = 0
  public var codeForInsertionOfResidues: Character = " "
  public var residueName: String = ""
  public var globalResidueIndex: Int = -1
  
  public var baseKind: SKNucleotideBaseKind = .unknown
  public var c1Prime: SKAsymmetricAtom?
  public var phosphate: SKAsymmetricAtom?
  public var baseAnchor: SKAsymmetricAtom?
  public var riboseRingAtoms: [SKAsymmetricAtom] = []
  public var baseRingAtoms: [SKAsymmetricAtom] = []
  
  public init()
  {
  }
  
  public func riboseRingPositions(contentShift: SIMD3<Double>) -> [SIMD3<Double>]
  {
    return riboseRingAtoms.map{$0.position + contentShift}
  }
  
  public func baseRingPositions(contentShift: SIMD3<Double>) -> [SIMD3<Double>]
  {
    return baseRingAtoms.map{$0.position + contentShift}
  }
  
  public func c1PrimePosition(contentShift: SIMD3<Double>) -> SIMD3<Double>?
  {
    return c1Prime.map{$0.position + contentShift}
  }
  
  public func baseAnchorPosition(contentShift: SIMD3<Double>) -> SIMD3<Double>?
  {
    return baseAnchor.map{$0.position + contentShift}
  }
  
  public func phosphatePosition(contentShift: SIMD3<Double>) -> SIMD3<Double>?
  {
    return phosphate.map{$0.position + contentShift}
  }
}

/// Two residues of different chains joined by a Watson-Crick pair (indices into `DNANucleotideGeometry.residues`).
public struct DNANucleotideBasePair
{
  public var residueGeometryIndexA: Int = -1
  public var residueGeometryIndexB: Int = -1
  
  public init(residueGeometryIndexA: Int, residueGeometryIndexB: Int)
  {
    self.residueGeometryIndexA = residueGeometryIndexA
    self.residueGeometryIndexB = residueGeometryIndexB
  }
}

public struct DNANucleotideGeometry
{
  public var residues: [DNANucleotideResidueGeometry] = []
  
  public init(residues: [DNANucleotideResidueGeometry] = [])
  {
    self.residues = residues
  }
  
  private struct ResidueKey: Hashable, Comparable
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
  
  public static func build(from atoms: [SKAsymmetricAtom]) -> DNANucleotideGeometry
  {
    var residueNames: [ResidueKey: String] = [:]
    var atomsByName: [ResidueKey: [String: SKAsymmetricAtom]] = [:]
    
    for atom in atoms
    {
      guard SKNucleotide.isNucleotideResidueName(atom.residueName) else {continue}
      let key: ResidueKey = ResidueKey(chainIdentifier: atom.chainIdentifier,
                                       residueSequenceNumber: atom.residueSequenceNumber,
                                       codeForInsertionOfResidues: atom.codeForInsertionOfResidues)
      if residueNames[key] == nil || residueNames[key]!.isEmpty
      {
        residueNames[key] = atom.residueName
      }
      atomsByName[key, default: [:]][SKNucleotide.normalizedAtomName(atom.displayName)] = atom
    }
    
    var geometry: DNANucleotideGeometry = DNANucleotideGeometry()
    geometry.residues.reserveCapacity(atomsByName.count)
    
    var globalIndex: Int = 0
    for key in atomsByName.keys.sorted()
    {
      guard let namedAtoms: [String: SKAsymmetricAtom] = atomsByName[key] else {continue}
      
      var residue: DNANucleotideResidueGeometry = DNANucleotideResidueGeometry()
      residue.chainIdentifier = key.chainIdentifier
      residue.residueSequenceNumber = key.residueSequenceNumber
      residue.codeForInsertionOfResidues = key.codeForInsertionOfResidues
      residue.residueName = residueNames[key] ?? ""
      residue.globalResidueIndex = globalIndex
      globalIndex += 1
      residue.baseKind = SKNucleotideBase.baseKindFromResidueName(residue.residueName)
      residue.c1Prime = atomNamed(namedAtoms, name: "C1'")
      residue.phosphate = atomNamed(namedAtoms, name: "P")
      if let anchorName: String = SKNucleotideBase.baseAnchorAtomName(residue.baseKind)
      {
        residue.baseAnchor = atomNamed(namedAtoms, name: anchorName)
      }
      residue.riboseRingAtoms = collectRingAtoms(namedAtoms, names: SKNucleotideBase.riboseRingAtomNames())
      residue.baseRingAtoms = collectRingAtoms(namedAtoms, names: SKNucleotideBase.baseRingAtomNames(residue.baseKind))
      geometry.residues.append(residue)
    }
    return geometry
  }
  
  /// Renumbers the residues in the order the ribbon stations count them, so that pick indices match the mesh.
  public static func assignGlobalResidueIndicesFromBackbone(_ geometry: inout DNANucleotideGeometry,
                                                            backbone: DNABackbone)
  {
    var globalIndex: Int = 0
    for chain in backbone.chains
    {
      for backboneResidue in chain.residues
      {
        guard backboneResidue.ribbonCenterAtom() != nil else {continue}
        for index in 0..<geometry.residues.count
        {
          if geometry.residues[index].chainIdentifier != chain.chainIdentifier {continue}
          if geometry.residues[index].residueSequenceNumber != backboneResidue.residueSequenceNumber {continue}
          if geometry.residues[index].codeForInsertionOfResidues != backboneResidue.codeForInsertionOfResidues {continue}
          geometry.residues[index].globalResidueIndex = globalIndex
          break
        }
        globalIndex += 1
      }
    }
  }
  
  /// Nearest complementary base on another chain, within the glycosidic-anchor distance of a Watson-Crick pair.
  public static func detectWatsonCrickPairs(_ geometry: DNANucleotideGeometry) -> [DNANucleotideBasePair]
  {
    var pairs: [DNANucleotideBasePair] = []
    let minPairDistance: Double = 7.0
    let maxPairDistance: Double = 16.5
    
    for indexA in 0..<geometry.residues.count
    {
      let residueA: DNANucleotideResidueGeometry = geometry.residues[indexA]
      guard let anchorAtomA: SKAsymmetricAtom = residueA.baseAnchor else {continue}
      let anchorA: SIMD3<Double> = anchorAtomA.position
      var bestPartner: Int? = nil
      var bestDistanceSquared: Double = maxPairDistance * maxPairDistance
      
      for indexB in (indexA + 1)..<geometry.residues.count
      {
        let residueB: DNANucleotideResidueGeometry = geometry.residues[indexB]
        if residueB.chainIdentifier == residueA.chainIdentifier {continue}
        guard let anchorAtomB: SKAsymmetricAtom = residueB.baseAnchor else {continue}
        guard SKNucleotideBase.areWatsonCrickComplementary(residueNameA: residueA.residueName,
                                                           residueNameB: residueB.residueName) else {continue}
        let delta: SIMD3<Double> = anchorAtomB.position - anchorA
        let distanceSquared: Double = length_squared(delta)
        let distance: Double = sqrt(distanceSquared)
        if distance < minPairDistance || distance > maxPairDistance {continue}
        if distanceSquared < bestDistanceSquared
        {
          bestDistanceSquared = distanceSquared
          bestPartner = indexB
        }
      }
      
      if let partner: Int = bestPartner
      {
        pairs.append(DNANucleotideBasePair(residueGeometryIndexA: indexA, residueGeometryIndexB: partner))
      }
    }
    return pairs
  }
  
  private static func atomNamed(_ namedAtoms: [String: SKAsymmetricAtom], name: String) -> SKAsymmetricAtom?
  {
    return namedAtoms[SKNucleotide.normalizedAtomName(name)]
  }
  
  private static func collectRingAtoms(_ namedAtoms: [String: SKAsymmetricAtom], names: [String]) -> [SKAsymmetricAtom]
  {
    return names.compactMap{atomNamed(namedAtoms, name: $0)}
  }
}
