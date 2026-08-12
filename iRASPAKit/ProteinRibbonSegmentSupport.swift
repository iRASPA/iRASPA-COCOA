/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd
import MathKit
import SymmetryKit

/// Contiguous secondary-structure segment along one chain (N→C), aligned with the atom-tree and ribbon mesh.
public struct ProteinRibbonResidueSegment: Sendable
{
  public let chainIdentifier: Character
  public let structureType: ProteinRibbonSecondaryStructure
  public let firstResidueIndex: Int
  public let lastResidueIndex: Int
  
  public init(chainIdentifier: Character,
              structureType: ProteinRibbonSecondaryStructure,
              firstResidueIndex: Int,
              lastResidueIndex: Int)
  {
    self.chainIdentifier = chainIdentifier
    self.structureType = structureType
    self.firstResidueIndex = firstResidueIndex
    self.lastResidueIndex = lastResidueIndex
  }
}

public enum ProteinRibbonSegmentSupport
{
  public static func residueSegments(for chain: ProteinBackboneChain,
                                       contentShift: SIMD3<Double>,
                                       secondaryStructureMethod: ProteinRibbonSecondaryStructureMethod = .stride) -> [ProteinRibbonResidueSegment]
  {
    let residues: [ProteinBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard !residues.isEmpty else {return []}
    
    let assignment: [ProteinRibbonSecondaryStructure] = ProteinRibbonSecondaryStructureAssigner.assign(for: chain,
                                                                                                       contentShift: contentShift,
                                                                                                       method: secondaryStructureMethod)
    guard !assignment.isEmpty else {return []}
    return residueSegments(from: assignment, chainIdentifier: chain.chainIdentifier)
  }
  
  public static func residueSegments(from assignment: [ProteinRibbonSecondaryStructure],
                                       chainIdentifier: Character) -> [ProteinRibbonResidueSegment]
  {
    guard !assignment.isEmpty else {return []}
    
    var segments: [ProteinRibbonResidueSegment] = []
    var currentType: ProteinRibbonSecondaryStructure = assignment[0]
    var runStart: Int = 0
    
    func appendRun(runEnd: Int)
    {
      guard runEnd >= runStart else {return}
      segments.append(ProteinRibbonResidueSegment(chainIdentifier: chainIdentifier,
                                                    structureType: currentType,
                                                    firstResidueIndex: runStart,
                                                    lastResidueIndex: runEnd))
    }
    
    for index in 1..<assignment.count
    {
      if assignment[index] != currentType
      {
        appendRun(runEnd: index - 1)
        currentType = assignment[index]
        runStart = index
      }
    }
    appendRun(runEnd: assignment.count - 1)
    return segments
  }
  
  public static func residueSegments(for backbone: ProteinBackbone,
                                       contentShift: SIMD3<Double>,
                                       secondaryStructureMethod: ProteinRibbonSecondaryStructureMethod = .stride) -> [ProteinRibbonResidueSegment]
  {
    return backbone.chains.flatMap{residueSegments(for: $0,
                                                  contentShift: contentShift,
                                                  secondaryStructureMethod: secondaryStructureMethod)}
  }
  
  public static func isChainGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .chain
  }
  
  public static func isSecondaryStructureSegmentNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .secondaryStructureSegment
  }
  
  public static func isHetatmGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .hetatm
  }
  
  public static func isResidueGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .residue
  }
  
  public static func isDNAHelixGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    return node.groupKind == .dnaHelix
  }
  
  public static func isProteinHierarchyGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    if isChainGroupNode(node) || isSecondaryStructureSegmentNode(node) {return true}
    // A residue of the polymer is swept into the ribbon; one under HETATM has only its atoms.
    guard let parentNode: SKAtomTreeNode = node.parentNode else {return false}
    return isResidueGroupNode(node) && isSecondaryStructureSegmentNode(parentNode)
  }
  
  /// Chain / helix / polymer residue groups that expose separate Atoms (A) and Ribbon (R) visibility.
  public static func isRibbonHierarchyGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    if isProteinHierarchyGroupNode(node) {return true}
    if isChainGroupNode(node) || isDNAHelixGroupNode(node) {return true}
    guard let parentNode: SKAtomTreeNode = node.parentNode else {return false}
    return isResidueGroupNode(node) && isDNAHelixGroupNode(parentNode)
  }
  
  public static func orderedSegmentTreeNodes(in controller: SKAtomTreeController) -> [SKAtomTreeNode]
  {
    var segmentNodes: [SKAtomTreeNode] = []
    for rootNode in controller.rootNodes where rootNode.isGroup
    {
      if isChainGroupNode(rootNode)
      {
        for childNode in rootNode.childNodes where isSecondaryStructureSegmentNode(childNode)
        {
          segmentNodes.append(childNode)
        }
      }
      else if isSecondaryStructureSegmentNode(rootNode)
      {
        segmentNodes.append(rootNode)
      }
    }
    return segmentNodes
  }
  
  public static func segmentTreeNodesAlignWithDrawRanges(_ controller: SKAtomTreeController, drawRangeCount: Int) -> Bool
  {
    let segmentNodes: [SKAtomTreeNode] = orderedSegmentTreeNodes(in: controller)
    return !segmentNodes.isEmpty && segmentNodes.count == drawRangeCount
  }
  
  public static func orderedResidueTreeNodes(in controller: SKAtomTreeController) -> [SKAtomTreeNode]
  {
    var residueNodes: [SKAtomTreeNode] = []
    for segmentNode in orderedSegmentTreeNodes(in: controller)
    {
      for childNode in segmentNode.childNodes where isResidueGroupNode(childNode)
      {
        residueNodes.append(childNode)
      }
    }
    return residueNodes
  }
  
  public static func residueTreeNodesAlignWithDrawRanges(_ controller: SKAtomTreeController, drawRangeCount: Int) -> Bool
  {
    let residueNodes: [SKAtomTreeNode] = orderedResidueTreeNodes(in: controller)
    return !residueNodes.isEmpty && residueNodes.count == drawRangeCount
  }
  
  /// The ribbon of a group and nothing else. Nesting is read back through `isRibbonResidueVisible`.
  public static func setGroupRibbonVisibility(_ node: SKAtomTreeNode, isVisible: Bool)
  {
    node.representedObject.isVisible = isVisible
  }
  
  /// The atoms under a group; switching the group is switching all of them.
  public static func setGroupAtomsVisibility(_ node: SKAtomTreeNode, isVisible: Bool)
  {
    for leaf in node.descendantLeafNodes()
    {
      leaf.representedObject.isVisible = isVisible
    }
  }
  
  /// A group outside the protein hierarchy has no ribbon and draws a single box.
  public static func setGroupVisibility(_ node: SKAtomTreeNode, isVisible: Bool)
  {
    node.representedObject.isVisible = isVisible
    for descendant in node.descendantNodes()
    {
      descendant.representedObject.isVisible = isVisible
    }
    setGroupAtomsVisibility(node, isVisible: isVisible)
  }
  
  /// Aggregate of descendant leaf visibility: true / false / nil (mixed).
  public static func groupAtomsVisibilityState(_ node: SKAtomTreeNode) -> Bool?
  {
    var sawVisible = false
    var sawHidden = false
    for leaf in node.descendantLeafNodes()
    {
      if leaf.representedObject.isVisible
      {
        sawVisible = true
      }
      else
      {
        sawHidden = true
      }
      if sawVisible && sawHidden {return nil}
    }
    return sawVisible || !sawHidden
  }
  
  public static func isRibbonSegmentVisible(_ node: SKAtomTreeNode) -> Bool
  {
    return isRibbonHierarchyNodeVisible(node)
  }
  
  public static func isRibbonResidueVisible(_ node: SKAtomTreeNode) -> Bool
  {
    return isRibbonHierarchyNodeVisible(node)
  }
  
  /// Node and outline ancestors must be visible. The controller hidden root is ignored.
  private static func isRibbonHierarchyNodeVisible(_ node: SKAtomTreeNode) -> Bool
  {
    var current: SKAtomTreeNode? = node
    while let treeNode: SKAtomTreeNode = current
    {
      if treeNode.parentNode == nil
      {
        break
      }
      if !treeNode.representedObject.isVisible
      {
        return false
      }
      current = treeNode.parentNode
    }
    return true
  }
  
  /// Pick buffer object type written by `RibbonPickingFragmentShader`.
  public static let ribbonPickObjectType: Int32 = 3
  
  public static func treeNodeForSegment(at segmentIndex: Int, in controller: SKAtomTreeController) -> SKAtomTreeNode?
  {
    let segmentNodes: [SKAtomTreeNode] = orderedSegmentTreeNodes(in: controller)
    guard segmentIndex >= 0 && segmentIndex < segmentNodes.count else {return nil}
    return segmentNodes[segmentIndex]
  }
  
  public static func treeNodeForResidue(at residueIndex: Int, in controller: SKAtomTreeController) -> SKAtomTreeNode?
  {
    let residueNodes: [SKAtomTreeNode] = orderedResidueTreeNodes(in: controller)
    guard residueIndex >= 0 && residueIndex < residueNodes.count else {return nil}
    return residueNodes[residueIndex]
  }
  
  public static func treeNodeForRibbonPick(segmentIndex: Int,
                                           residueIndex: Int,
                                           selectSegment: Bool,
                                           in controller: SKAtomTreeController) -> SKAtomTreeNode?
  {
    if selectSegment
    {
      return treeNodeForSegment(at: segmentIndex, in: controller)
    }
    return treeNodeForResidue(at: residueIndex, in: controller)
  }
  
  /// Residue group nodes whose Cα position falls inside the screen frustum (for drag selection).
  public static func filterResidueTreeNodes(in controller: SKAtomTreeController,
                                            backbone: ProteinBackbone,
                                            contentShift: SIMD3<Double>,
                                            orientation: simd_quatd,
                                            boundingBoxCenter: SIMD3<Double>,
                                            origin: SIMD3<Double>,
                                            filter: (SIMD3<Double>) -> Bool) -> Set<SKAtomTreeNode>
  {
    let residueNodes: [SKAtomTreeNode] = orderedResidueTreeNodes(in: controller)
    let alphaCarbons: [SKAsymmetricAtom] = backboneAlphaCarbonAtoms(for: backbone)
    guard residueNodes.count == alphaCarbons.count else {return []}
    
    let rotationMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: orientation), aroundPoint: boundingBoxCenter)
    var selectedNodes: Set<SKAtomTreeNode> = []
    
    for (index, residueNode) in residueNodes.enumerated()
    {
      guard isRibbonResidueVisible(residueNode) else {continue}
      
      let alphaCarbon: SKAsymmetricAtom = alphaCarbons[index]
      var isInside: Bool = false
      for copy in alphaCarbon.copies where copy.type == .copy
      {
        let position: SIMD3<Double> = copy.position + contentShift
        let transformed: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: position.x, y: position.y, z: position.z, w: 1.0)
        let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(transformed.x, transformed.y, transformed.z) + origin
        if filter(absoluteCartesianPosition)
        {
          isInside = true
          break
        }
      }
      
      if isInside
      {
        selectedNodes.insert(residueNode)
      }
    }
    
    return selectedNodes
  }
  
  /// Secondary-structure segment nodes with at least one visible residue Cα inside the frustum.
  public static func filterSegmentTreeNodes(in controller: SKAtomTreeController,
                                            backbone: ProteinBackbone,
                                            contentShift: SIMD3<Double>,
                                            orientation: simd_quatd,
                                            boundingBoxCenter: SIMD3<Double>,
                                            origin: SIMD3<Double>,
                                            filter: (SIMD3<Double>) -> Bool) -> Set<SKAtomTreeNode>
  {
    let selectedResidues: Set<SKAtomTreeNode> = filterResidueTreeNodes(in: controller,
                                                                       backbone: backbone,
                                                                       contentShift: contentShift,
                                                                       orientation: orientation,
                                                                       boundingBoxCenter: boundingBoxCenter,
                                                                       origin: origin,
                                                                       filter: filter)
    var selectedSegments: Set<SKAtomTreeNode> = []
    for residueNode in selectedResidues
    {
      if let segmentNode: SKAtomTreeNode = residueNode.parentNode,
         isSecondaryStructureSegmentNode(segmentNode)
      {
        selectedSegments.insert(segmentNode)
      }
    }
    return selectedSegments
  }
  
  private static func backboneAlphaCarbonAtoms(for backbone: ProteinBackbone) -> [SKAsymmetricAtom]
  {
    var alphaCarbons: [SKAsymmetricAtom] = []
    for chain in backbone.chains
    {
      for residue in chain.residues
      {
        if let alphaCarbon: SKAsymmetricAtom = residue.alphaCarbon
        {
          alphaCarbons.append(alphaCarbon)
        }
      }
    }
    return alphaCarbons
  }
  
  public static func selectedSegmentDrawRangeIndices(in controller: SKAtomTreeController) -> Set<Int>
  {
    let segmentNodes: [SKAtomTreeNode] = orderedSegmentTreeNodes(in: controller)
    var indices: Set<Int> = []
    
    for selectedNode in controller.selectedTreeNodes
    {
      if isChainGroupNode(selectedNode)
      {
        for childNode in selectedNode.childNodes where isSecondaryStructureSegmentNode(childNode)
        {
          if let index: Int = segmentNodes.firstIndex(of: childNode)
          {
            indices.insert(index)
          }
        }
      }
      else if isSecondaryStructureSegmentNode(selectedNode)
      {
        if let index: Int = segmentNodes.firstIndex(of: selectedNode)
        {
          indices.insert(index)
        }
      }
    }
    return indices
  }
  
  public static func selectedResidueDrawRangeIndices(in controller: SKAtomTreeController) -> Set<Int>
  {
    let residueNodes: [SKAtomTreeNode] = orderedResidueTreeNodes(in: controller)
    var indices: Set<Int> = []
    
    for selectedNode in controller.selectedTreeNodes
    {
      if isResidueGroupNode(selectedNode)
      {
        if let index: Int = residueNodes.firstIndex(of: selectedNode)
        {
          indices.insert(index)
        }
      }
      else if selectedNode.isLeaf
      {
        if let residueNode: SKAtomTreeNode = enclosingResidueGroupNode(for: selectedNode),
           let index: Int = residueNodes.firstIndex(of: residueNode)
        {
          indices.insert(index)
        }
      }
    }
    return indices
  }
  
  public static func residueGroupNodes(in segmentNode: SKAtomTreeNode) -> [SKAtomTreeNode]
  {
    guard isSecondaryStructureSegmentNode(segmentNode) else {return []}
    return segmentNode.childNodes.filter { isResidueGroupNode($0) }
  }
  
  public static func isSecondaryStructureSegmentSelected(_ segmentNode: SKAtomTreeNode,
                                                         in selectedNodes: Set<SKAtomTreeNode>) -> Bool
  {
    guard isSecondaryStructureSegmentNode(segmentNode) else {return false}
    if selectedNodes.contains(segmentNode)
    {
      return true
    }
    return !Set(residueGroupNodes(in: segmentNode)).isDisjoint(with: selectedNodes)
  }
  
  public static func enclosingResidueGroupNode(for leafNode: SKAtomTreeNode) -> SKAtomTreeNode?
  {
    var node: SKAtomTreeNode? = leafNode.parentNode
    while let current: SKAtomTreeNode = node
    {
      if isResidueGroupNode(current)
      {
        return current
      }
      node = current.parentNode
    }
    return nil
  }
  
  public static func enclosingSecondaryStructureSegmentNode(for node: SKAtomTreeNode) -> SKAtomTreeNode?
  {
    var candidate: SKAtomTreeNode? = node
    while let current: SKAtomTreeNode = candidate
    {
      if isSecondaryStructureSegmentNode(current)
      {
        return current
      }
      candidate = current.parentNode
    }
    return nil
  }
  
  private static func leafNodesByTag(in controller: SKAtomTreeController) -> [Int: SKAtomTreeNode]
  {
    var nodesByTag: [Int: SKAtomTreeNode] = [:]
    for leaf in controller.flattenedLeafNodes()
    {
      nodesByTag[leaf.representedObject.tag] = leaf
    }
    return nodesByTag
  }
  
  /// Resolves residue group nodes for Cα tags stored on the ribbon mesh (1:1 with residue draw ranges).
  public static func residueTreeNodes(forAtomTags alphaCarbonTags: [Int],
                                      in controller: SKAtomTreeController) -> [SKAtomTreeNode?]
  {
    let nodesByTag: [Int: SKAtomTreeNode] = leafNodesByTag(in: controller)
    return alphaCarbonTags.map
    { tag in
      guard tag >= 0, let leaf: SKAtomTreeNode = nodesByTag[tag] else {return nil}
      return enclosingResidueGroupNode(for: leaf)
    }
  }
  
  /// Resolves secondary-structure segment nodes for Cα tags stored on the ribbon mesh.
  public static func segmentTreeNodes(forAtomTags alphaCarbonTags: [Int],
                                      in controller: SKAtomTreeController) -> [SKAtomTreeNode?]
  {
    let nodesByTag: [Int: SKAtomTreeNode] = leafNodesByTag(in: controller)
    return alphaCarbonTags.map
    { tag in
      guard tag >= 0, let leaf: SKAtomTreeNode = nodesByTag[tag] else {return nil}
      return enclosingSecondaryStructureSegmentNode(for: leaf)
    }
  }
  
  public static func residueTreeNode(forAtomTag tag: Int,
                                     in controller: SKAtomTreeController) -> SKAtomTreeNode?
  {
    guard tag >= 0 else {return nil}
    for leaf in controller.flattenedLeafNodes()
    {
      if leaf.representedObject.tag == tag
      {
        return enclosingResidueGroupNode(for: leaf)
      }
    }
    return nil
  }
  
  public static func segmentTreeNode(forAtomTag tag: Int,
                                     in controller: SKAtomTreeController) -> SKAtomTreeNode?
  {
    guard tag >= 0 else {return nil}
    for leaf in controller.flattenedLeafNodes()
    {
      if leaf.representedObject.tag == tag
      {
        return enclosingSecondaryStructureSegmentNode(for: leaf)
      }
    }
    return nil
  }
  
  public static func residueVisibilityMask(forAtomTags alphaCarbonTags: [Int],
                                           in controller: SKAtomTreeController) -> [Bool]
  {
    return residueTreeNodes(forAtomTags: alphaCarbonTags, in: controller).map
    { node in
      guard let residueNode: SKAtomTreeNode = node else {return true}
      return isRibbonResidueVisible(residueNode)
    }
  }
  
  public static func segmentVisibilityMask(forAtomTags alphaCarbonTags: [Int],
                                           in controller: SKAtomTreeController) -> [Bool]
  {
    return segmentTreeNodes(forAtomTags: alphaCarbonTags, in: controller).map
    { node in
      guard let segmentNode: SKAtomTreeNode = node else {return true}
      return isRibbonSegmentVisible(segmentNode)
    }
  }
}
