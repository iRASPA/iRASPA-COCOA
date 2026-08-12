/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation
import SymmetryKit

/// Builds a hierarchical atom tree for DNA: chain → DNA helix → residue → atom.
public enum DNAAtomTreeBuilder
{
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

  private struct ResidueBucket
  {
    var residueName: String
    var atoms: [SKAsymmetricAtom]
  }

  public static func applyHierarchyIfNeeded(to controller: SKAtomTreeController) -> Bool
  {
    let atoms: [SKAsymmetricAtom] = controller.flattenedLeafNodes().map{$0.representedObject}
    guard !atoms.isEmpty else {return false}
    guard !DNABackbone.build(from: atoms).chains.isEmpty else {return false}
    guard !hasChainHelixHierarchy(controller.rootNodes) else {return false}
    controller.rootNodes = build(from: atoms)
    return true
  }

  private static func hasChainHelixHierarchy(_ rootNodes: [SKAtomTreeNode]) -> Bool
  {
    for rootNode in rootNodes where rootNode.isGroup
    {
      if isChainNode(rootNode)
      {
        for helixNode in rootNode.childNodes where helixNode.isGroup
        {
          if helixNode.childNodes.contains(where: {$0.isGroup})
          {
            return true
          }
        }
      }
      else if isHelixNode(rootNode)
      {
        if rootNode.childNodes.contains(where: {$0.isGroup})
        {
          return true
        }
      }
    }
    return false
  }

  private static func isChainNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .chain
  }

  private static func isHelixNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .dnaHelix
  }

  public static func build(from atoms: [SKAsymmetricAtom]) -> [SKAtomTreeNode]
  {
    let backbone: DNABackbone = DNABackbone.build(from: atoms)

    var residuesByKey: [ResidueKey: ResidueBucket] = [:]
    var orphanAtoms: [SKAsymmetricAtom] = []

    for atom in atoms
    {
      guard hasResidueIdentity(atom) else
      {
        orphanAtoms.append(atom)
        continue
      }
      let key: ResidueKey = residueKey(for: atom)
      if residuesByKey[key] == nil
      {
        residuesByKey[key] = ResidueBucket(residueName: atom.residueName, atoms: [])
      }
      residuesByKey[key]!.atoms.append(atom)
    }

    let useChainLevel: Bool = backbone.chains.count > 1
    var rootNodes: [SKAtomTreeNode] = []

    for chain in backbone.chains
    {
      guard !chain.residues.isEmpty else {continue}

      let chainNode: SKAtomTreeNode? = useChainLevel ? makeGroupNode(displayName: chainDisplayName(for: chain.chainIdentifier), groupKind: .chain) : nil
      if let chainNode: SKAtomTreeNode = chainNode
      {
        rootNodes.append(chainNode)
      }

      let helixNode: SKAtomTreeNode = makeGroupNode(displayName: helixDisplayName(for: chain, residuesByKey: residuesByKey), groupKind: .dnaHelix)
      for residue in chain.residues
      {
        let key: ResidueKey = residueKey(for: chain.chainIdentifier, residue: residue)
        guard let bucket: ResidueBucket = residuesByKey[key] else {continue}

        let residueNode: SKAtomTreeNode = makeGroupNode(displayName: residueDisplayName(for: key, bucket: bucket), groupKind: .residue)
        for atom in bucket.atoms.sorted(by: atomSortOrder)
        {
          SKAtomTreeNode(representedObject: atom).append(inParent: residueNode)
        }
        residueNode.append(inParent: helixNode)
      }

      if let chainNode: SKAtomTreeNode = chainNode
      {
        helixNode.append(inParent: chainNode)
      }
      else
      {
        rootNodes.append(helixNode)
      }
    }

    var assignedKeys: Set<ResidueKey> = []
    for chain in backbone.chains
    {
      for residue in chain.residues
      {
        assignedKeys.insert(residueKey(for: chain.chainIdentifier, residue: residue))
      }
    }

    let unassignedKeys: [ResidueKey] = residuesByKey.keys.filter
    { key in
      !assignedKeys.contains(key) && SKNucleotide.isNucleotideResidueName(residuesByKey[key]!.residueName)
    }.sorted()
    if !unassignedKeys.isEmpty
    {
      let otherNode: SKAtomTreeNode = makeGroupNode(displayName: "Other nucleotides", groupKind: .otherNucleotides)
      for key in unassignedKeys
      {
        let bucket: ResidueBucket = residuesByKey[key]!
        let residueNode: SKAtomTreeNode = makeGroupNode(displayName: residueDisplayName(for: key, bucket: bucket), groupKind: .residue)
        for atom in bucket.atoms.sorted(by: atomSortOrder)
        {
          SKAtomTreeNode(representedObject: atom).append(inParent: residueNode)
        }
        residueNode.append(inParent: otherNode)
      }
      rootNodes.append(otherNode)
    }

    if !orphanAtoms.isEmpty
    {
      let otherNode: SKAtomTreeNode = makeGroupNode(displayName: "Other", groupKind: .other)
      for atom in orphanAtoms.sorted(by: atomSortOrder)
      {
        SKAtomTreeNode(representedObject: atom).append(inParent: otherNode)
      }
      rootNodes.append(otherNode)
    }

    return rootNodes
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

  private static func residueKey(for chainIdentifier: Character, residue: DNABackboneResidue) -> ResidueKey
  {
    return ResidueKey(chainIdentifier: chainIdentifier,
                      residueSequenceNumber: residue.residueSequenceNumber,
                      codeForInsertionOfResidues: residue.codeForInsertionOfResidues)
  }

  private static func chainDisplayName(for chainIdentifier: Character) -> String
  {
    if chainIdentifier != Character(" ")
    {
      return "Chain \(chainIdentifier)"
    }
    return "Chain"
  }

  private static func helixDisplayName(for chain: DNABackboneChain, residuesByKey: [ResidueKey: ResidueBucket]) -> String
  {
    guard let firstResidue: DNABackboneResidue = chain.residues.first,
          let lastResidue: DNABackboneResidue = chain.residues.last else
    {
      return "DNA helix"
    }
    let firstKey: ResidueKey = residueKey(for: chain.chainIdentifier, residue: firstResidue)
    let lastKey: ResidueKey = residueKey(for: chain.chainIdentifier, residue: lastResidue)
    let firstName: String = trimmedResidueName(residuesByKey[firstKey]?.residueName)
    let lastName: String = trimmedResidueName(residuesByKey[lastKey]?.residueName)
    if firstKey == lastKey
    {
      return "DNA helix (\(firstName) \(firstKey.residueSequenceNumber))"
    }
    return "DNA helix (\(firstName) \(firstKey.residueSequenceNumber)–\(lastName) \(lastKey.residueSequenceNumber))"
  }

  private static func trimmedResidueName(_ residueName: String?) -> String
  {
    let trimmedName: String = residueName?.trimmingCharacters(in: .whitespaces) ?? ""
    return trimmedName.isEmpty ? "NUC" : trimmedName
  }

  private static func residueDisplayName(for key: ResidueKey, bucket: ResidueBucket) -> String
  {
    let namePart: String = trimmedResidueName(bucket.residueName)
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
