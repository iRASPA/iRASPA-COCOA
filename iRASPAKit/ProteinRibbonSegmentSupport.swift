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
import RenderKit

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
  
  public struct RibbonVisibilityMasks
  {
    public var residues: [Bool] = []
    public var segments: [Bool] = []
  }
  
  /// Both masks from a single tree walk. An empty tag list yields an empty mask, so a caller that
  /// only drives one of the two pays for one walk and nothing more.
  public static func visibilityMasks(residueAlphaCarbonTags: [Int],
                                     segmentAlphaCarbonTags: [Int],
                                     in controller: SKAtomTreeController) -> RibbonVisibilityMasks
  {
    guard !residueAlphaCarbonTags.isEmpty || !segmentAlphaCarbonTags.isEmpty else {return RibbonVisibilityMasks()}
    
    let nodesByTag: [Int: SKAtomTreeNode] = leafNodesByTag(in: controller)
    
    func mask(forTags tags: [Int], enclosing: (SKAtomTreeNode) -> SKAtomTreeNode?) -> [Bool]
    {
      return tags.map
      { tag in
        guard tag >= 0, let leaf: SKAtomTreeNode = nodesByTag[tag],
              let node: SKAtomTreeNode = enclosing(leaf) else {return true}
        return isRibbonHierarchyNodeVisible(node)
      }
    }
    
    var masks: RibbonVisibilityMasks = RibbonVisibilityMasks()
    masks.residues = mask(forTags: residueAlphaCarbonTags, enclosing: enclosingResidueGroupNode)
    masks.segments = mask(forTags: segmentAlphaCarbonTags, enclosing: enclosingSecondaryStructureSegmentNode)
    return masks
  }
  
  /// Mask for an already-resolved node list, used when the ribbon mesh carries no Cα tags and the
  /// draw ranges line up with the tree groups by count alone.
  public static func visibilityMask(forNodes nodes: [SKAtomTreeNode]) -> [Bool]
  {
    return nodes.map {isRibbonHierarchyNodeVisible($0)}
  }
}

/// Which ribbon pieces the atom tree currently hides. Resolving this means walking the tree, so it is
/// cached against the atom visibility generation rather than recomputed for every draw call. Shared by
/// `Protein` and `ProteinCrystal`, which drive identical ribbon visibility.
public final class ProteinRibbonVisibilityCache
{
  private var generation: Int = -1
  private var residueDrawRangeCount: Int = 0
  private var segmentDrawRangeCount: Int = 0
  private var residueVisibility: [Bool] = []
  private var segmentVisibility: [Bool] = []
  private var cachedUsesResidueVisibility: Bool = false
  private var cachedUsesSegmentVisibility: Bool = false
  private var cachedEncodingDrawRanges: [RKRibbonChainDrawRange] = []
  
  public init()
  {
  }
  
  /// Call whenever the ribbon mesh is replaced: the draw ranges and Cα tags it is keyed on change.
  public func invalidate()
  {
    generation = -1
  }
  
  public func usesResidueVisibility(mesh: RKRibbonMesh, controller: SKAtomTreeController) -> Bool
  {
    refreshIfNeeded(mesh: mesh, controller: controller)
    return cachedUsesResidueVisibility
  }
  
  public func usesSegmentVisibility(mesh: RKRibbonMesh, controller: SKAtomTreeController) -> Bool
  {
    refreshIfNeeded(mesh: mesh, controller: controller)
    return cachedUsesSegmentVisibility
  }
  
  public func isResidueDrawRangeVisible(at index: Int, mesh: RKRibbonMesh, controller: SKAtomTreeController) -> Bool
  {
    refreshIfNeeded(mesh: mesh, controller: controller)
    guard cachedUsesResidueVisibility else {return true}
    guard index >= 0 && index < residueVisibility.count else {return true}
    return residueVisibility[index]
  }
  
  public func isSegmentDrawRangeVisible(at index: Int, mesh: RKRibbonMesh, controller: SKAtomTreeController) -> Bool
  {
    refreshIfNeeded(mesh: mesh, controller: controller)
    guard cachedUsesSegmentVisibility else {return true}
    guard index >= 0 && index < segmentVisibility.count else {return true}
    return segmentVisibility[index]
  }
  
  public func drawRangesForEncoding(mesh: RKRibbonMesh, controller: SKAtomTreeController) -> [RKRibbonChainDrawRange]
  {
    refreshIfNeeded(mesh: mesh, controller: controller)
    return cachedEncodingDrawRanges
  }
  
  private func refreshIfNeeded(mesh: RKRibbonMesh, controller: SKAtomTreeController)
  {
    let currentGeneration: Int = skAtomVisibilityGeneration()
    if generation == currentGeneration && residueDrawRangeCount == mesh.residueDrawRanges.count &&
       segmentDrawRangeCount == mesh.segmentDrawRanges.count
    {
      return
    }
    
    generation = currentGeneration
    residueDrawRangeCount = mesh.residueDrawRanges.count
    segmentDrawRangeCount = mesh.segmentDrawRanges.count
    
    // Mesh residue ranges are 1:1 with Cα tags; tree residue groups can outnumber them (HETATM,
    // single-sample residues skipped in the sweep). Prefer tags so R/A visibility works.
    let hasResidueTags: Bool = !mesh.residueAlphaCarbonTags.isEmpty
    let hasSegmentTags: Bool = !mesh.segmentAlphaCarbonTags.isEmpty
    cachedUsesResidueVisibility = hasResidueTags
      ? mesh.residueAlphaCarbonTags.count == residueDrawRangeCount
      : ProteinRibbonSegmentSupport.residueTreeNodesAlignWithDrawRanges(controller, drawRangeCount: residueDrawRangeCount)
    cachedUsesSegmentVisibility = hasSegmentTags
      ? mesh.segmentAlphaCarbonTags.count == segmentDrawRangeCount
      : ProteinRibbonSegmentSupport.segmentTreeNodesAlignWithDrawRanges(controller, drawRangeCount: segmentDrawRangeCount)
    
    let masks: ProteinRibbonSegmentSupport.RibbonVisibilityMasks =
      ProteinRibbonSegmentSupport.visibilityMasks(residueAlphaCarbonTags: cachedUsesResidueVisibility && hasResidueTags ? mesh.residueAlphaCarbonTags : [],
                                                  segmentAlphaCarbonTags: cachedUsesSegmentVisibility && hasSegmentTags ? mesh.segmentAlphaCarbonTags : [],
                                                  in: controller)
    residueVisibility = masks.residues
    segmentVisibility = masks.segments
    
    if cachedUsesResidueVisibility && !hasResidueTags
    {
      residueVisibility = ProteinRibbonSegmentSupport.visibilityMask(forNodes: ProteinRibbonSegmentSupport.orderedResidueTreeNodes(in: controller))
    }
    if cachedUsesSegmentVisibility && !hasSegmentTags
    {
      segmentVisibility = ProteinRibbonSegmentSupport.visibilityMask(forNodes: ProteinRibbonSegmentSupport.orderedSegmentTreeNodes(in: controller))
    }
    
    // Residue ranges win when they drive visibility, exactly as the per-frame path used to decide.
    cachedEncodingDrawRanges = mesh.chainDrawRanges
    if cachedUsesResidueVisibility && residueDrawRangeCount > 0
    {
      if residueVisibility.count == residueDrawRangeCount && !residueVisibility.allSatisfy({$0})
      {
        cachedEncodingDrawRanges = RKRibbonMesh.mergedVisibleDrawRanges(mesh.residueDrawRanges, visible: residueVisibility)
      }
    }
    else if cachedUsesSegmentVisibility && segmentDrawRangeCount > 0
    {
      if segmentVisibility.count == segmentDrawRangeCount && !segmentVisibility.allSatisfy({$0})
      {
        cachedEncodingDrawRanges = RKRibbonMesh.mergedVisibleDrawRanges(mesh.segmentDrawRanges, visible: segmentVisibility)
      }
    }
  }
}
