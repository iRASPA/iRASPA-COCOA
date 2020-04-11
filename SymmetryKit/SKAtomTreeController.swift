/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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
import BinaryCodable
import simd

public class SKAtomTreeController: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1

  private var hiddenRootNode: SKAtomTreeNode
  
  // there is a general selection, and a specific single selected tree-node
  public weak var selectedTreeNode: SKAtomTreeNode? = nil
  public var selectedTreeNodes: Set< SKAtomTreeNode > = Set()
  
  public var filterPredicate: (SKAtomTreeNode) -> Bool = {_ in return true}
  
  
  public var rootNodes: [SKAtomTreeNode]
  {
    get
    {
      return hiddenRootNode.childNodes
    }
    set(newValue)
    {
      hiddenRootNode.childNodes = newValue
      for child in hiddenRootNode.childNodes
      {
        child.parentNode = hiddenRootNode
      }
    }
  }
  
  
  public var filteredRootNodes: [SKAtomTreeNode]
  {
    get{return hiddenRootNode.filteredAndSortedNodes}
  }
  
  public init()
  {
    let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
    self.hiddenRootNode = SKAtomTreeNode(representedObject: atom)
    for child in hiddenRootNode.childNodes
    {
      child.parentNode = hiddenRootNode
    }
  }
  
  public init(rootNode: SKAtomTreeNode)
  {
    hiddenRootNode = rootNode
    for child in hiddenRootNode.childNodes
    {
      child.parentNode = hiddenRootNode
    }
  }
  
  public init(nodes: [SKAtomTreeNode])
  {
    let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
    self.hiddenRootNode = SKAtomTreeNode(representedObject: atom)
    hiddenRootNode.childNodes = []
    
    for node in nodes
    {
      node.append(inParent: self.hiddenRootNode)
    }
  }
  
  public func parentItem(_ node: SKAtomTreeNode) -> SKAtomTreeNode?
  {
    if(node.parentNode == hiddenRootNode)
    {
      return nil
    }
    else
    {
      return node.parentNode
    }
    
  }
  
  public func parentNodeForParentItem(_ node: SKAtomTreeNode?) -> SKAtomTreeNode
  {
    return node ?? hiddenRootNode
  }
  
  public func isRootNode(_ node: SKAtomTreeNode) -> Bool
  {
    if (node.parentNode == hiddenRootNode)
    {
      return true
    }
    else
    {
      return false
    }
  }
  
  
  public func nodeIsChildOfItem(_ node: SKAtomTreeNode, item: SKAtomTreeNode?) -> Bool
  {
    let itemNode: SKAtomTreeNode = item ?? hiddenRootNode
    return node.parentNode == itemNode
  }
  
  
  public func filteredChildIndexOfItem(_ parentItem: SKAtomTreeNode?, index: Int) -> Int
  {
    let parentNode: SKAtomTreeNode = parentItem ?? hiddenRootNode
    
    if index < parentNode.filteredAndSortedNodes.count
    {
      let node: SKAtomTreeNode = parentNode.filteredAndSortedNodes[index]
      
      return parentNode.childNodes.firstIndex(of: node)!
    }
    else // return last index to add a new item
    {
      return parentNode.childNodes.count
    }
  }
  
  public func isSameNode(_ item: SKAtomTreeNode?, index: Int, node: SKAtomTreeNode) -> Bool
  {
    let treeNode: SKAtomTreeNode = item ?? hiddenRootNode
    
    if(index<0)
    {
      return false
    }
    
    return  (treeNode.childNodes[max(0, min(index, treeNode.childNodes.count - 1))] == node) ||
      (treeNode.childNodes[max(0, min(index - 1, treeNode.childNodes.count - 1))] == node)
  }
  
  
  
  public func isDescendantOfNode(_ item: SKAtomTreeNode?, parentNode: SKAtomTreeNode) -> Bool
  {
    var treeNode: SKAtomTreeNode? = item ?? hiddenRootNode
    
    while(treeNode != nil)
    {
      if (treeNode! == parentNode)
      {
        return true
      }
      else
      {
        treeNode=treeNode?.parentNode
      }
    }
    return false
  }
  
  public func insertNode(_ node: SKAtomTreeNode, inItem parent: SKAtomTreeNode?, atIndex index: Int)
  {
    if (parent == nil)
    {
      node.insert(inParent: hiddenRootNode, atIndex: index)
      hiddenRootNode.updateFilteredChildren(filterPredicate)
    }
    else
    {
      node.insert(inParent: parent!, atIndex: index)
      parent!.updateFilteredChildren(filterPredicate)
    }
    
    
  }
  
  public func removeNode(_ node: SKAtomTreeNode)
  {
    if let parentNode: SKAtomTreeNode = node.parentNode
    {
      node.removeFromParent()
      
      parentNode.updateFilteredChildren(filterPredicate)
    }
  }
  
  public func childrenForItem(_ item: SKAtomTreeNode?)-> [SKAtomTreeNode]
  {
    if(item==nil)
    {
      return hiddenRootNode.childNodes
    }
    else
    {
      return item!.childNodes
    }
  }
  
  public func nodeAtIndexPath(_ indexPath: IndexPath) -> SKAtomTreeNode?
  {
    return self.hiddenRootNode.descendantNodeAtIndexPath(indexPath)
  }
  
  public func flattenedNodes() -> [SKAtomTreeNode]
  {
    return self.hiddenRootNode.descendantNodes()
  }
  
  public func flattenedLeafNodes() -> [SKAtomTreeNode]
  {
    return self.hiddenRootNode.descendantLeafNodes()
  }
  
  public func flattenedGroupNodes() -> [SKAtomTreeNode]
  {
    return self.hiddenRootNode.descendantGroupNodes()
  }
  
  
  public func insertNode(_ node: SKAtomTreeNode!, atArrangedObjectIndexPath indexPath: IndexPath)
  {
    let index: Int = indexPath.last ?? 0
    let parent: SKAtomTreeNode = hiddenRootNode.descendantNodeAtIndexPath(indexPath.dropLast())!
    
    node.insert(inParent: parent, atIndex: index)
  }
  
  public func appendNode(_ node: SKAtomTreeNode!, atArrangedObjectIndexPath indexPath: IndexPath)
  {
    let parent: SKAtomTreeNode = hiddenRootNode.descendantNodeAtIndexPath(indexPath)!
    
    node.append(inParent: parent)
  }
  
  public func removeNodeAtArrangedObjectIndexPath(_ indexPath: IndexPath)
  {
    let node: SKAtomTreeNode = hiddenRootNode.descendantNodeAtIndexPath(indexPath)!
    self.removeNode(node)
  }
  
  
  public func moveNode(_ atIndexPath: IndexPath,toIndexPath indexPath: IndexPath)
  {
    let node: SKAtomTreeNode = self.hiddenRootNode.descendantNodeAtIndexPath(atIndexPath)!
    self.removeNodeAtArrangedObjectIndexPath(atIndexPath)
    self.insertNode(node, atArrangedObjectIndexPath: indexPath)
    
  }
  
  public func tag()
  {
    // probably can be done a lot faster by using the tree-structure and recursion
    let asymmetricAtomNodes: [SKAtomTreeNode] = self.flattenedNodes()
    for asymmetricAtomNode in asymmetricAtomNodes
    {
      let isVisibleEnabled = asymmetricAtomNode.areAllAncestorsVisible
      asymmetricAtomNode.representedObject.isVisibleEnabled = isVisibleEnabled
    }
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for i in 0..<asymmetricAtoms.count
    {
      asymmetricAtoms[i].tag = i
    }
    
    let atomList: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
    for i in 0..<atomList.count
    {
      atomList[i].tag = i
    }
  }
  
  // MARK: Selection
  // =====================================================================
  
  public func clearSelection()
  {
    self.selectedTreeNodes = Set()
  }
  
  
  
  public func removeSelection()
  {
    
    for node in selectedNodes
    {
      //node.selected = false
      node.removeFromParent()
    }
    self.selectedTreeNodes = Set()
  }
  
  public func setSelectedNodes(_ objects: [SKAtomTreeNode])
  {
    self.selectedTreeNodes = Set()
    for node in objects
    {
      //node.selected = true
      self.selectedTreeNodes.insert(node)
    }
  }
  
  
  public func addSelectionNode(_ node: SKAtomTreeNode)
  {
    //node.selected = true
    self.selectedTreeNodes.insert(node)
  }
  
  public func addSelectionNodes(_ nodes: [SKAtomTreeNode])
  {
    for node in nodes
    {
      //node.selected = true
      self.selectedTreeNodes.insert(node)
    }
  }
  
  public func removeSelectionNode(_ node: SKAtomTreeNode)
  {
    //node.selected = false
    self.selectedTreeNodes.remove(node)
  }
  
  public func toggleSelectionNode(_ node: SKAtomTreeNode)
  {
    if (self.selectedTreeNodes.contains(node))
    {
      //node.selected = false
      self.selectedTreeNodes.remove(node)
    }
    else
    {
      //node.selected = true
      self.selectedTreeNodes.insert(node)
    }
  }
  
  
  public func addSelectionIndexPaths(_ indexPaths: [SKAtomTreeNode]) -> Bool
  {
    return true
  }
  
  /// Removes the objects at the specified indexPaths from the receiver’s current selection
  ///
  /// Note: an error occurs if the indexPath is not valid
  ///
  /// - parameter indexPaths: Index patsh specifying the selected nodes.
  /// - returns: true if the selection was changed.
  public func removeSelectionIndexPaths(_ indexPaths: [SKAtomTreeNode]) -> Bool
  {
    return true
  }
  
  /*
   /// Returns an array containing the currently selected objects.
   ///
   /// - returns: An array containing the currently selected objects in the tree controller content.
   public var selectedObjects: [T]!
   {
   get
   {
   return Array(selectedTreeNodes).map{$0.representedObject}
   }
   }
   */
  
  /// Returns an array of the receiver’s selected tree nodes.
  ///
  /// - returns: An array containing the receiver’s selected tree nodes.
  public var selectedNodes: [SKAtomTreeNode]!
  {
    get
    {
      return Array(selectedTreeNodes)
    }
    
  }
  
  public var invertedSelection: Set<SKAtomTreeNode>
  {
    return Set(self.flattenedLeafNodes()).subtracting(self.selectedTreeNodes)
  }
  
  public var allSelectedNodes: [SKAtomTreeNode]!
  {
    get
    {
      var selectedNodes: Set<SKAtomTreeNode> = selectedTreeNodes
      for node in selectedTreeNodes
      {
        if (!node.childNodes.isEmpty)
        {
          selectedNodes.formUnion(node.descendantNodes())
        }
      }
      return Array(selectedNodes)
    }
    
  }
  
  
  /// Returns an array containing the index paths of the currently selected objects.
  ///
  /// - returns: An array containing IndexPath objects for each of the selected objects in the tree controller’s content.
  public var selectionIndexPaths: [IndexPath]!
  {
    get
    {
      return Array(selectedTreeNodes).map{$0.indexPath}
    }
  }
  
  // Will create an IndexPath after the selection, or as for the top of the children of a group node
  public func indexPathForInsertion() -> IndexPath
  {
    // if the selection is empty, insert in the root as the last element
    if (selectedTreeNodes.isEmpty)
    {
      return [self.rootNodes.count]
    }
    else if (selectedTreeNodes.count == 1)
    {
      if (selectedNodes[0].isLeaf)
      {
        if (selectedNodes[0].parentNode == nil)
        {
          return [self.rootNodes.count]
        }
        else
        {
          return selectedNodes[0].adjacentIndexPath()
        }
      }
      else
      {
        return selectedNodes[0].indexPath+[0]
      }
    }
    else
    {
      return selectedNodes.last!.adjacentIndexPath()
    }
  }
  
  public func updateFilteredNode(_ node: SKAtomTreeNode)
  {
    node.updateFilteredChildren(filterPredicate)
  }
  
  public func updateFilteredItem(_ item: AnyObject?)
  {
    let itemNode: SKAtomTreeNode = item==nil ? hiddenRootNode : item as! SKAtomTreeNode
    itemNode.updateFilteredChildren(filterPredicate)
  }
  
  public func updateFilteredNodes()
  {
    self.hiddenRootNode.updateFilteredChildrenRecursively(filterPredicate)
  }
  
  public func setFilteredNodesAsMatching()
  {
    self.hiddenRootNode.setFilteredNodesAsMatching()
  }
  
  public func contains(_ item: SKAtomTreeNode) -> Bool
  {
    return item.isDescendantOfNode(hiddenRootNode)
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKAtomTreeController.classVersionNumber)
    encoder.encode(self.hiddenRootNode)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKAtomTreeController.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.hiddenRootNode = try decoder.decode(SKAtomTreeNode.self)
  }
}

