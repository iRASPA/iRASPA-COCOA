/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import SymmetryKit
import MathKit

/// Builds a hierarchical atom tree for proteins: chain → secondary-structure segment → residue → atom.
/// PDB HETATM records (waters, ions, ligands — not polymer MODRES) collect under a "HETATM" group per chain.
/// The chain level is left out when the protein has only one chain, and atoms without a residue identity
/// collect under a single "Other" group. Rendering still uses `atomTreeController.flattenedLeafNodes()`.
public enum ProteinAtomTreeBuilder
{
  private struct ResidueKey: Hashable, Comparable
  {
    let chainIdentifier: Character
    let residueSequenceNumber: Int
    let codeForInsertionOfResidues: Character
    
    static func < (lhs: ResidueKey, rhs: ResidueKey) -> Bool
    {
      if lhs.chainIdentifier != rhs.chainIdentifier
      {
        return lhs.chainIdentifier < rhs.chainIdentifier
      }
      if lhs.residueSequenceNumber != rhs.residueSequenceNumber
      {
        return lhs.residueSequenceNumber < rhs.residueSequenceNumber
      }
      return lhs.codeForInsertionOfResidues < rhs.codeForInsertionOfResidues
    }
  }
  
  private struct ResidueBucket
  {
    var residueName: String
    var atoms: [SKAsymmetricAtom]
  }
  
  private struct SecondaryStructureSegment
  {
    let structureType: ProteinRibbonSecondaryStructure
    let chainIdentifier: Character
    let residueKeys: [ResidueKey]
  }
  
  /// Reorganizes a flat or legacy protein atom tree into the chain-ordered segment hierarchy when needed.
  /// Returns `true` when the tree was rebuilt. Preserves group visibility across rebuilds by display-name path.
  public static func applyHierarchyIfNeeded(to controller: SKAtomTreeController,
                                            secondaryStructureMethod: ProteinRibbonSecondaryStructureMethod = .stride) -> Bool
  {
    let atoms: [SKAsymmetricAtom] = controller.flattenedLeafNodes().map{$0.representedObject}
    guard !atoms.isEmpty else {return false}
    guard !ProteinBackbone.build(from: atoms).chains.isEmpty else {return false}
    
    let rebuilt: [SKAtomTreeNode] = build(from: atoms, secondaryStructureMethod: secondaryStructureMethod)
    
    if hasChainOrderedSegmentHierarchy(controller.rootNodes),
       haveSameShape(controller.rootNodes, rebuilt)
    {
      return false
    }
    
    let hiddenGroupPaths: Set<String> = collectHiddenGroupPaths(controller.rootNodes, prefix: "")
    controller.rootNodes = rebuilt
    if !hiddenGroupPaths.isEmpty
    {
      applyHiddenGroupPaths(controller.rootNodes, prefix: "", hiddenPaths: hiddenGroupPaths)
    }
    controller.tag()
    return true
  }
  
  private static func collectHiddenGroupPaths(_ nodes: [SKAtomTreeNode], prefix: String) -> Set<String>
  {
    var hiddenPaths: Set<String> = []
    for node in nodes where node.isGroup
    {
      let path: String = prefix + "/" + node.displayName
      if !node.representedObject.isVisible
      {
        hiddenPaths.insert(path)
      }
      hiddenPaths.formUnion(collectHiddenGroupPaths(node.childNodes, prefix: path))
    }
    return hiddenPaths
  }
  
  private static func applyHiddenGroupPaths(_ nodes: [SKAtomTreeNode], prefix: String, hiddenPaths: Set<String>)
  {
    for node in nodes where node.isGroup
    {
      let path: String = prefix + "/" + node.displayName
      if hiddenPaths.contains(path)
      {
        node.representedObject.isVisible = false
      }
      applyHiddenGroupPaths(node.childNodes, prefix: path, hiddenPaths: hiddenPaths)
    }
  }
  
  private static func haveSameShape(_ left: [SKAtomTreeNode], _ right: [SKAtomTreeNode]) -> Bool
  {
    guard left.count == right.count else {return false}
    for index in 0..<left.count
    {
      let leftNode: SKAtomTreeNode = left[index]
      let rightNode: SKAtomTreeNode = right[index]
      if leftNode.groupKind != rightNode.groupKind {return false}
      if leftNode.isGroup
      {
        if leftNode.displayName != rightNode.displayName {return false}
        if !haveSameShape(leftNode.childNodes, rightNode.childNodes) {return false}
      }
      else if leftNode.representedObject !== rightNode.representedObject
      {
        return false
      }
    }
    return true
  }
  
  private static func hasChainOrderedSegmentHierarchy(_ rootNodes: [SKAtomTreeNode]) -> Bool
  {
    for rootNode in rootNodes where rootNode.isGroup
    {
      if isChainNode(rootNode)
      {
        for childNode in rootNode.childNodes where childNode.isGroup
        {
          if hasResidueChild(childNode)
          {
            return true
          }
        }
      }
      else if hasResidueChild(rootNode)
      {
        return true
      }
    }
    return false
  }
  
  private static func hasResidueChild(_ node: SKAtomTreeNode) -> Bool
  {
    return node.childNodes.contains(where: {ProteinRibbonSegmentSupport.isResidueGroupNode($0)})
  }
  
  private static func isChainNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .chain
  }
  
  public static func build(from atoms: [SKAsymmetricAtom],
                           secondaryStructureMethod: ProteinRibbonSecondaryStructureMethod = .stride) -> [SKAtomTreeNode]
  {
    let backbone: ProteinBackbone = ProteinBackbone.build(from: atoms)
    let secondaryStructureByResidue: [ResidueKey: ProteinRibbonSecondaryStructure] = assignSecondaryStructure(for: backbone,
                                                                                                              secondaryStructureMethod: secondaryStructureMethod)
    
    var residuesByKey: [ResidueKey: ResidueBucket] = [:]
    
    for atom in atoms
    {
      guard hasResidueIdentity(atom) else {continue}
      let key: ResidueKey = residueKey(for: atom)
      if residuesByKey[key] == nil
      {
        residuesByKey[key] = ResidueBucket(residueName: atom.residueName, atoms: [])
      }
      residuesByKey[key]!.atoms.append(atom)
    }
    
    var polymerResiduesByKey: [ResidueKey: ResidueBucket] = [:]
    var hetatmKeysByChain: [Character: [ResidueKey]] = [:]
    for (key, bucket) in residuesByKey
    {
      if residueIsHetatmListing(bucket)
      {
        hetatmKeysByChain[key.chainIdentifier, default: []].append(key)
      }
      else
      {
        polymerResiduesByKey[key] = bucket
      }
    }
    for chainIdentifier in hetatmKeysByChain.keys
    {
      hetatmKeysByChain[chainIdentifier]?.sort()
    }
    
    let segmentsByChain: [Character: [SecondaryStructureSegment]] = buildSegmentsByChain(for: backbone,
                                                                                          residuesByKey: polymerResiduesByKey,
                                                                                          secondaryStructureByResidue: secondaryStructureByResidue)
    
    var chainOrder: [Character] = []
    var seenChains: Set<Character> = []
    for chain in backbone.chains
    {
      chainOrder.append(chain.chainIdentifier)
      seenChains.insert(chain.chainIdentifier)
    }
    // Polymer residues can exist on chains the ribbon backbone never saw (incomplete
    // residues without Cα). Keep those chains so hierarchy rebuild never drops atoms —
    // dropped atoms leave stale bond tags and crash on archive copy/decode.
    for chainIdentifier in Set(polymerResiduesByKey.keys.map{$0.chainIdentifier}).sorted()
    {
      if seenChains.insert(chainIdentifier).inserted
      {
        chainOrder.append(chainIdentifier)
      }
    }
    for chainIdentifier in hetatmKeysByChain.keys.sorted()
    {
      if seenChains.insert(chainIdentifier).inserted
      {
        chainOrder.append(chainIdentifier)
      }
    }
    
    let useChainLevel: Bool = chainOrder.count > 1
    
    var rootNodes: [SKAtomTreeNode] = []
    var placedAtomIDs: Set<ObjectIdentifier> = []
    for chainIdentifier in chainOrder
    {
      let segments: [SecondaryStructureSegment] = segmentsByChain[chainIdentifier] ?? []
      let hetatmKeys: [ResidueKey] = hetatmKeysByChain[chainIdentifier] ?? []
      let hasSegments: Bool = !segments.isEmpty
      let hasHetatm: Bool = !hetatmKeys.isEmpty
      guard hasSegments || hasHetatm else {continue}
      
      let chainNode: SKAtomTreeNode? = useChainLevel ? makeGroupNode(displayName: chainDisplayName(for: chainIdentifier), groupKind: .chain) : nil
      if let chainNode: SKAtomTreeNode = chainNode
      {
        rootNodes.append(chainNode)
      }
      
      if hasSegments
      {
        for segment in segments
        {
          let segmentNode: SKAtomTreeNode = makeSegmentNode(for: segment, residuesByKey: polymerResiduesByKey)
          recordPlacedAtoms(in: segmentNode, into: &placedAtomIDs)
          if let chainNode: SKAtomTreeNode = chainNode
          {
            segmentNode.append(inParent: chainNode)
          }
          else
          {
            rootNodes.append(segmentNode)
          }
        }
      }
      
      if hasHetatm
      {
        let hetatmNode: SKAtomTreeNode = makeHetatmGroupNode(keys: hetatmKeys, residuesByKey: residuesByKey)
        recordPlacedAtoms(in: hetatmNode, into: &placedAtomIDs)
        if let chainNode: SKAtomTreeNode = chainNode
        {
          hetatmNode.append(inParent: chainNode)
        }
        else
        {
          rootNodes.append(hetatmNode)
        }
      }
    }
    
    var leftoverAtoms: [SKAsymmetricAtom] = []
    for atom in atoms where !placedAtomIDs.contains(ObjectIdentifier(atom))
    {
      leftoverAtoms.append(atom)
    }
    
    if !leftoverAtoms.isEmpty
    {
      let otherNode: SKAtomTreeNode = makeGroupNode(displayName: "Other", groupKind: .other)
      for atom in leftoverAtoms.sorted(by: atomSortOrder)
      {
        SKAtomTreeNode(representedObject: atom).append(inParent: otherNode)
      }
      rootNodes.append(otherNode)
    }
    
    return rootNodes
  }
  
  private static func recordPlacedAtoms(in node: SKAtomTreeNode, into placedAtomIDs: inout Set<ObjectIdentifier>)
  {
    if !node.isGroup
    {
      placedAtomIDs.insert(ObjectIdentifier(node.representedObject))
      return
    }
    for child in node.childNodes
    {
      recordPlacedAtoms(in: child, into: &placedAtomIDs)
    }
  }
  
  /// PDB marks every HETATM as solvent. Polymer MODRES written as HETATM (SET, etc.) still carry the
  /// peptide backbone and stay with the chain segments; waters, ions, and ligands go under HETATM.
  /// Water/solvent-agent residue names are also accepted so a lost `solvent` flag cannot drop them into coils.
  private static func residueIsHetatmListing(_ bucket: ResidueBucket) -> Bool
  {
    guard !bucket.atoms.isEmpty else {return false}
    
    let residueName: String = bucket.residueName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    let namedSolventResidue: Bool = Self.isWaterResidue(residueName) || Self.isSolventAgentResidue(residueName)
    let allAtomsSolvent: Bool = bucket.atoms.allSatisfy{$0.solvent}
    guard allAtomsSolvent || namedSolventResidue else {return false}
    
    var hasNitrogen: Bool = false
    var hasAlphaCarbon: Bool = false
    var hasCarbonyl: Bool = false
    for atom in bucket.atoms
    {
      let atomName: String = atom.displayName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
      if atomName == "N" {hasNitrogen = true}
      else if atomName == "CA" {hasAlphaCarbon = true}
      else if atomName == "C" {hasCarbonyl = true}
    }
    // Polymer MODRES written as HETATM still carry the peptide triad.
    if hasNitrogen && hasAlphaCarbon && hasCarbonyl {return false}
    return true
  }
  
  private static func isWaterResidue(_ residueName: String) -> Bool
  {
    return SKElement.isWaterResidueName(residueName)
  }
  
  private static func isSolventAgentResidue(_ residueName: String) -> Bool
  {
    return SKElement.isSolventAgentResidueName(residueName)
  }
  
  private static func buildSegmentsByChain(for backbone: ProteinBackbone,
                                           residuesByKey: [ResidueKey: ResidueBucket],
                                           secondaryStructureByResidue: [ResidueKey: ProteinRibbonSecondaryStructure]) -> [Character: [SecondaryStructureSegment]]
  {
    var segmentsByChain: [Character: [SecondaryStructureSegment]] = [:]
    var assignedKeys: Set<ResidueKey> = []
    
    for chain in backbone.chains
    {
      let residuesWithAlphaCarbon: [ProteinBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
      let assignment: [ProteinRibbonSecondaryStructure] = residuesWithAlphaCarbon.map
      {
        let key: ResidueKey = residueKey(for: chain.chainIdentifier, residue: $0)
        return secondaryStructureByResidue[key, default: .coil]
      }
      let runs: [ProteinRibbonResidueSegment] = ProteinRibbonSegmentSupport.residueSegments(from: assignment,
                                                                                            chainIdentifier: chain.chainIdentifier)
      var chainSegments: [SecondaryStructureSegment] = []
      
      for run in runs
      {
        var keys: [ResidueKey] = []
        for index in run.firstResidueIndex...run.lastResidueIndex where index < residuesWithAlphaCarbon.count
        {
          let residue: ProteinBackboneResidue = residuesWithAlphaCarbon[index]
          let key: ResidueKey = residueKey(for: chain.chainIdentifier, residue: residue)
          guard residuesByKey[key] != nil else {continue}
          keys.append(key)
        }
        guard !keys.isEmpty else {continue}
        chainSegments.append(SecondaryStructureSegment(structureType: run.structureType,
                                                       chainIdentifier: run.chainIdentifier,
                                                       residueKeys: keys))
        assignedKeys.formUnion(keys)
      }
      
      if !chainSegments.isEmpty
      {
        segmentsByChain[chain.chainIdentifier] = chainSegments
      }
    }
    
    // Residues the ribbon never sweeps still belong in the tree, but only polymer ones: HETATM
    // waters and ligands are listed under a separate HETATM group per chain instead of as lone coils.
    let unassignedKeys: [ResidueKey] = residuesByKey.keys.filter{!assignedKeys.contains($0)}.sorted()
    for key in unassignedKeys
    {
      let structureType: ProteinRibbonSecondaryStructure = secondaryStructureByResidue[key, default: .coil]
      let segment: SecondaryStructureSegment = SecondaryStructureSegment(structureType: structureType,
                                                                           chainIdentifier: key.chainIdentifier,
                                                                           residueKeys: [key])
      segmentsByChain[key.chainIdentifier, default: []].append(segment)
    }
    
    return segmentsByChain
  }
  
  private static func makeHetatmGroupNode(keys: [ResidueKey],
                                          residuesByKey: [ResidueKey: ResidueBucket]) -> SKAtomTreeNode
  {
    let hetatmNode: SKAtomTreeNode = makeGroupNode(displayName: "HETATM", groupKind: .hetatm)
    for key in keys
    {
      guard let bucket: ResidueBucket = residuesByKey[key] else {continue}
      makeResidueNode(for: key, bucket: bucket).append(inParent: hetatmNode)
    }
    return hetatmNode
  }
  
  private static func makeResidueNode(for key: ResidueKey, bucket: ResidueBucket) -> SKAtomTreeNode
  {
    let residueNode: SKAtomTreeNode = makeGroupNode(displayName: residueDisplayName(for: key, bucket: bucket),
                                                    groupKind: .residue)
    for atom in bucket.atoms.sorted(by: atomSortOrder)
    {
      SKAtomTreeNode(representedObject: atom).append(inParent: residueNode)
    }
    return residueNode
  }
  
  private static func makeSegmentNode(for segment: SecondaryStructureSegment,
                                      residuesByKey: [ResidueKey: ResidueBucket]) -> SKAtomTreeNode
  {
    let segmentNode: SKAtomTreeNode = makeGroupNode(displayName: segmentDisplayName(for: segment, residuesByKey: residuesByKey),
                                                    groupKind: .secondaryStructureSegment)
    for key in segment.residueKeys
    {
      guard let bucket: ResidueBucket = residuesByKey[key] else {continue}
      makeResidueNode(for: key, bucket: bucket).append(inParent: segmentNode)
    }
    return segmentNode
  }
  
  private static func chainDisplayName(for chainIdentifier: Character) -> String
  {
    if chainIdentifier != Character(" ")
    {
      return "Chain \(chainIdentifier)"
    }
    return "Chain"
  }
  
  private static func segmentDisplayName(for segment: SecondaryStructureSegment,
                                         residuesByKey: [ResidueKey: ResidueBucket]) -> String
  {
    let typeLabel: String
    switch segment.structureType
    {
    case .helix: typeLabel = "Alpha-helix"
    case .sheet: typeLabel = "Beta-sheet"
    case .coil: typeLabel = "Coil"
    }
    
    guard let firstKey: ResidueKey = segment.residueKeys.first,
          let lastKey: ResidueKey = segment.residueKeys.last else
    {
      return typeLabel
    }
    
    let firstName: String = trimmedResidueName(residuesByKey[firstKey]?.residueName)
    let lastName: String = trimmedResidueName(residuesByKey[lastKey]?.residueName)
    let rangeLabel: String = residueRangeLabel(firstKey: firstKey,
                                               lastKey: lastKey,
                                               firstName: firstName,
                                               lastName: lastName)
    return "\(typeLabel) (\(rangeLabel))"
  }
  
  private static func residueRangeLabel(firstKey: ResidueKey,
                                        lastKey: ResidueKey,
                                        firstName: String,
                                        lastName: String) -> String
  {
    let firstNumberLabel: String = residueNumberLabel(for: firstKey)
    let lastNumberLabel: String = residueNumberLabel(for: lastKey)
    if firstKey == lastKey
    {
      return "\(firstName) \(firstNumberLabel)"
    }
    return "\(firstName) \(firstNumberLabel)–\(lastName) \(lastNumberLabel)"
  }
  
  private static func residueNumberLabel(for key: ResidueKey) -> String
  {
    if key.codeForInsertionOfResidues != Character(" ")
    {
      return "\(key.residueSequenceNumber)\(key.codeForInsertionOfResidues)"
    }
    return String(key.residueSequenceNumber)
  }
  
  private static func trimmedResidueName(_ residueName: String?) -> String
  {
    let trimmedName: String = residueName?.trimmingCharacters(in: .whitespaces) ?? ""
    return trimmedName.isEmpty ? "RES" : trimmedName
  }
  
  private static func assignSecondaryStructure(for backbone: ProteinBackbone,
                                                 secondaryStructureMethod: ProteinRibbonSecondaryStructureMethod) -> [ResidueKey: ProteinRibbonSecondaryStructure]
  {
    var assignmentByResidue: [ResidueKey: ProteinRibbonSecondaryStructure] = [:]
    for chain in backbone.chains
    {
      let residuesWithAlphaCarbon: [ProteinBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
      let assignment: [ProteinRibbonSecondaryStructure] = ProteinRibbonSecondaryStructureAssigner.assign(for: chain,
                                                                                                         contentShift: .zero,
                                                                                                         method: secondaryStructureMethod)
      for (index, residue) in residuesWithAlphaCarbon.enumerated() where index < assignment.count
      {
        let key: ResidueKey = residueKey(for: chain.chainIdentifier, residue: residue)
        assignmentByResidue[key] = assignment[index]
      }
    }
    return assignmentByResidue
  }
  
  private static func hasResidueIdentity(_ atom: SKAsymmetricAtom) -> Bool
  {
    return !atom.residueName.trimmingCharacters(in: .whitespaces).isEmpty || atom.residueSequenceNumber != 0
  }
  
  private static func residueKey(for atom: SKAsymmetricAtom) -> ResidueKey
  {
    return ResidueKey(chainIdentifier: atom.chainIdentifier,
                      residueSequenceNumber: atom.residueSequenceNumber,
                      codeForInsertionOfResidues: atom.codeForInsertionOfResidues)
  }
  
  private static func residueKey(for chainIdentifier: Character, residue: ProteinBackboneResidue) -> ResidueKey
  {
    return ResidueKey(chainIdentifier: chainIdentifier,
                      residueSequenceNumber: residue.residueSequenceNumber,
                      codeForInsertionOfResidues: residue.codeForInsertionOfResidues)
  }
  
  private static func residueDisplayName(for key: ResidueKey, bucket: ResidueBucket) -> String
  {
    let trimmedName: String = bucket.residueName.trimmingCharacters(in: .whitespaces)
    let namePart: String = trimmedName.isEmpty ? "RES" : trimmedName
    var label: String = "\(namePart) \(key.residueSequenceNumber)"
    if key.codeForInsertionOfResidues != Character(" ")
    {
      label += String(key.codeForInsertionOfResidues)
    }
    return label
  }
  
  private static func makeGroupNode(displayName: String, groupKind: SKAtomTreeGroupKind) -> SKAtomTreeNode
  {
    let containerAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName,
                                                           elementId: 0,
                                                           uniqueForceFieldName: "C",
                                                           position: SIMD3<Double>(0.0, 0.0, 0.0),
                                                           charge: 0.0,
                                                           color: NSColor.black,
                                                           drawRadius: 0.0,
                                                           bondDistanceCriteria: 0.0,
                                                           occupancy: 1.0)
    containerAtom.symmetryType = .container
    return SKAtomTreeNode(name: displayName, representedObject: containerAtom, isGroup: true, groupKind: groupKind)
  }
  
  private static func atomSortOrder(_ lhs: SKAsymmetricAtom, _ rhs: SKAsymmetricAtom) -> Bool
  {
    let leftName: String = lhs.displayName.uppercased()
    let rightName: String = rhs.displayName.uppercased()
    if leftName != rightName
    {
      return leftName < rightName
    }
    return lhs.elementIdentifier < rhs.elementIdentifier
  }
}
