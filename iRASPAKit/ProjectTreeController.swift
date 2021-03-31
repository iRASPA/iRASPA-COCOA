/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
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
import BinaryCodable
import CloudKit

public final class ProjectTreeController: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  private var hiddenRootNode: ProjectTreeNode
  
  // there is a general selection, and a specific single selected tree-node
  public weak var selectedTreeNode: ProjectTreeNode? = nil
  public var selectedTreeNodes: Set< ProjectTreeNode > = Set()
  {
    didSet
    {
      self.flattenedNodes().forEach({$0.isImplicitelySelected = false})
      self.allSelectedNodes.forEach({$0.isImplicitelySelected = true})
    }
  }
  
  public func updateImplicitlySelected()
  {
    self.flattenedNodes().forEach({$0.isImplicitelySelected = false})
    self.allSelectedNodes.forEach({$0.isImplicitelySelected = true})
  }
  
  public var filterPredicate: (ProjectTreeNode) -> Bool = {_ in return true}
  
  public var rootNodes: [ProjectTreeNode]
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
  
  public var selectedProjects: [iRASPAProject]
  {
    return selectedTreeNodes.map{$0.representedObject}
  }
  
  public var filteredRootNodes: [ProjectTreeNode]
  {
    get{return hiddenRootNode.filteredAndSortedNodes}
  }
  
  
  public init()
  {
    let recordID = CKRecord.ID(recordName: "hiddenRootNode")
    self.hiddenRootNode = ProjectTreeNode(displayName: "hiddenRootNode", recordID: recordID)
    hiddenRootNode.recordID = recordID
    
    let galleryRootNode = ProjectTreeNode(displayName: "GALLERY", representedObject: iRASPAProject(group: ProjectGroup(name: "GALLERY")))
    let projectRootNode = ProjectTreeNode(displayName: "LOCAL PROJECTS", representedObject: iRASPAProject(group: ProjectGroup(name: "LOCAL PROJECTS")))
    let cloudRootNode = ProjectTreeNode(displayName: "ICLOUD PUBLIC", representedObject: iRASPAProject(group: ProjectGroup(name: "ICLOUD PUBLIC")))
    
    galleryRootNode.isEditable = false
    projectRootNode.isEditable = false
    cloudRootNode.isEditable = false
    
    self.insertNode(galleryRootNode, inItem: nil, atIndex: 0)
    self.insertNode(projectRootNode, inItem: nil, atIndex: 1)
    self.insertNode(cloudRootNode, inItem: nil, atIndex: 2)
    
    
    let localGalleryNode: ProjectTreeNode = ProjectTreeNode(displayName: "Gallery", representedObject: iRASPAProject(group: ProjectGroup(name: "Gallery")))
    localGalleryNode.isEditable = false
    self.insertNode(localGalleryNode, inItem: galleryRootNode, atIndex: 0)
    
    let localMainNode: ProjectTreeNode = ProjectTreeNode(displayName: "Local projects", representedObject: iRASPAProject(group: ProjectGroup(name: "Local projects")))
    localMainNode.isEditable = false
    localMainNode.isDropEnabled = true
    localMainNode.isExpanded = true
    self.insertNode(localMainNode, inItem: projectRootNode, atIndex: 0)
        
    // updated 18-10-2017
    let cloudMainNode: ProjectTreeNode = ProjectTreeNode(displayName: "iCloud public", recordID: CKRecord.ID(recordName: "30089089-3163-633B-62B2-390C63E92789"), representedObject: iRASPAProject(group: ProjectGroup(name: "iCloud public")))
    self.insertNode(cloudMainNode, inItem: cloudRootNode, atIndex: 0)
    
    let cloudNodeCoREMOF: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF v1.0", recordID: CKRecord.ID(recordName: "982F3A9C-7B2D-809B-8F9D-852F2F7FB839"), representedObject: iRASPAProject(group: ProjectGroup(name: "CoRE MOF v1.0")))
    let cloudNodeCoREMOFDDEC: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF v1.0 DDEC", recordID: CKRecord.ID(recordName: "55DEA27F-47C8-81CA-CE43-956EAA1DCF2D"), representedObject: iRASPAProject(group: ProjectGroup(name: "CoRE MOF v1.0 DDEC")))
    let cloudNodeIZA: ProjectTreeNode = ProjectTreeNode(displayName: "IZA Zeolite Topologies", recordID: CKRecord.ID(recordName: "6383111E-4D0E-1675-82F2-E97FEB76FDE4"), representedObject: iRASPAProject(group: ProjectGroup(name: "IZA Zeolite Topologies")))
    self.insertNode(cloudNodeCoREMOF, inItem: cloudMainNode, atIndex: 0)
    self.insertNode(cloudNodeCoREMOFDDEC, inItem: cloudMainNode, atIndex: 1)
    self.insertNode(cloudNodeIZA, inItem: cloudMainNode, atIndex: 2)
    
    galleryRootNode.isExpanded = true
    projectRootNode.isExpanded = true
    cloudRootNode.isExpanded = true
    //projectLocalRootNode.isExpanded = true
    
    galleryRootNode.isEditable = false
    projectRootNode.isEditable = false
    cloudRootNode.isEditable = false
    //projectLocalRootNode.isEditable = false
    cloudMainNode.isEditable = false
    
    galleryRootNode.disallowDrag = true
    projectRootNode.disallowDrag = true
    cloudRootNode.disallowDrag = true
  }
  
  public init(rootNode: ProjectTreeNode)
  {
    hiddenRootNode = rootNode
    for child in hiddenRootNode.childNodes
    {
      child.parentNode = hiddenRootNode
    }
    hiddenRootNode.recordID = CKRecord.ID(recordName: "hiddenRootNode")
  }
  
  public init(nodes: [ProjectTreeNode])
  {
    let recordID = CKRecord.ID(recordName: "hiddenRootNode")
    self.hiddenRootNode = ProjectTreeNode.init(displayName: "hiddenRootNode", recordID: recordID)
    hiddenRootNode.recordID = recordID
    hiddenRootNode.childNodes = []
    
    for node in nodes
    {
      node.append(inParent: self.hiddenRootNode)
    }
  }
  
  public func parentItem(_ node: ProjectTreeNode) -> ProjectTreeNode?
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
  
  public func parentNodeForParentItem(_ node: ProjectTreeNode?) -> ProjectTreeNode
  {
    return node ?? hiddenRootNode
  }
  
  public func isRootNode(_ node: ProjectTreeNode) -> Bool
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
  
  
  public func nodeIsChildOfItem(_ node: ProjectTreeNode, item: ProjectTreeNode?) -> Bool
  {
    let itemNode: ProjectTreeNode = item ?? hiddenRootNode
    return node.parentNode == itemNode
  }
  
  
  public func filteredChildIndexOfItem(_ parentItem: ProjectTreeNode?, index: Int) -> Int
  {
    let parentNode: ProjectTreeNode = parentItem ?? hiddenRootNode
    
    if index == 0
    {
     // return index
    }
    
    if index < parentNode.filteredAndSortedNodes.count
    {
      let node: ProjectTreeNode = parentNode.filteredAndSortedNodes[index]
      
      return parentNode.childNodes.firstIndex(of: node)!
    }
    else // return last index to add a new item
    {
      return parentNode.childNodes.count
    }
  }
  
  public func isSameNode(_ item: ProjectTreeNode?, index: Int, node: ProjectTreeNode) -> Bool
  {
    let treeNode: ProjectTreeNode = item ?? hiddenRootNode
    
    if(index<0)
    {
      return false
    }
    
    return  (treeNode.childNodes[max(0, min(index, treeNode.childNodes.count - 1))] == node) ||
      (treeNode.childNodes[max(0, min(index - 1, treeNode.childNodes.count - 1))] == node)
  }
  
  
  
  public func isDescendantOfNode(_ item: ProjectTreeNode?, parentNode: ProjectTreeNode) -> Bool
  {
    var treeNode: ProjectTreeNode? = item ?? hiddenRootNode
    
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
  
  public func insertNode(_ node: ProjectTreeNode, inItem parent: ProjectTreeNode?, atIndex index: Int)
  {
    if (parent == nil)
    {
      node.insert(inParent: hiddenRootNode, atIndex: index)
      hiddenRootNode.updateFilteredChildren(filterPredicate)
    }
    else
    {
      node.insert(inParent: parent!, atIndex: index)
      node.isImplicitelySelected = parent!.isImplicitelySelected
      parent!.updateFilteredChildren(filterPredicate)
    }
    
    
  }
  
  public func removeNode(_ node: ProjectTreeNode)
  {
    if let parentNode: ProjectTreeNode = node.parentNode
    {
      node.removeFromParent()
      
      parentNode.updateFilteredChildren(filterPredicate)
    }
  }
  
  public func childrenForItem(_ item: ProjectTreeNode?)-> [ProjectTreeNode]
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
  
  public func nodeAtIndexPath(_ indexPath: IndexPath) -> ProjectTreeNode?
  {
    return self.hiddenRootNode.descendantNodeAtIndexPath(indexPath)
  }
  
  public func flattenedNodes() -> [ProjectTreeNode]
  {
    return self.hiddenRootNode.descendantNodes()
  }
  
  public func flattenedLeafNodes() -> [ProjectTreeNode]
  {
    return self.hiddenRootNode.descendantLeafNodes()
  }
  
  public func flattenedGroupNodes() -> [ProjectTreeNode]
  {
    return self.hiddenRootNode.descendantGroupNodes()
  }
  
  
  public func insertNode(_ node: ProjectTreeNode!, atArrangedObjectIndexPath indexPath: IndexPath)
  {
    let index: Int = indexPath.last ?? 0
    let parent: ProjectTreeNode = hiddenRootNode.descendantNodeAtIndexPath(indexPath.dropLast())!
    
    node.insert(inParent: parent, atIndex: index)
  }
  
  public func appendNode(_ node: ProjectTreeNode!, atArrangedObjectIndexPath indexPath: IndexPath)
  {
    let parent: ProjectTreeNode = hiddenRootNode.descendantNodeAtIndexPath(indexPath)!
    
    node.append(inParent: parent)
  }
  
  public func removeNodeAtArrangedObjectIndexPath(_ indexPath: IndexPath)
  {
    let node: ProjectTreeNode = hiddenRootNode.descendantNodeAtIndexPath(indexPath)!
    self.removeNode(node)
  }
  
  
  public func moveNode(_ atIndexPath: IndexPath,toIndexPath indexPath: IndexPath)
  {
    let node: ProjectTreeNode = self.hiddenRootNode.descendantNodeAtIndexPath(atIndexPath)!
    self.removeNodeAtArrangedObjectIndexPath(atIndexPath)
    self.insertNode(node, atArrangedObjectIndexPath: indexPath)
    
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
  
  public func setSelectedNodes(_ objects: [ProjectTreeNode])
  {
    self.selectedTreeNodes = Set()
    for node in objects
    {
      //node.selected = true
      self.selectedTreeNodes.insert(node)
    }
  }
  
  
  public func addSelectionNode(_ node: ProjectTreeNode)
  {
    //node.selected = true
    self.selectedTreeNodes.insert(node)
  }
  
  public func addSelectionNodes(_ nodes: [ProjectTreeNode])
  {
    for node in nodes
    {
      //node.selected = true
      self.selectedTreeNodes.insert(node)
    }
  }
  
  public func removeSelectionNode(_ node: ProjectTreeNode)
  {
    //node.selected = false
    self.selectedTreeNodes.remove(node)
  }
  
  public func toggleSelectionNode(_ node: ProjectTreeNode)
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
  
  
  public func addSelectionIndexPaths(_ indexPaths: [ProjectTreeNode]) -> Bool
  {
    return true
  }
  
  /// Removes the objects at the specified indexPaths from the receiver’s current selection
  ///
  /// Note: an error occurs if the indexPath is not valid
  ///
  /// - parameter indexPaths: Index patsh specifying the selected nodes.
  /// - returns: true if the selection was changed.
  public func removeSelectionIndexPaths(_ indexPaths: [ProjectTreeNode]) -> Bool
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
  public var selectedNodes: [ProjectTreeNode]!
  {
    get
    {
      return Array(selectedTreeNodes)
    }
  }
  
  private var allSelectedNodes: [ProjectTreeNode]!
  {
    get
    {
      var selectedNodes: Set<ProjectTreeNode> = selectedTreeNodes
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
  
  public func updateFilteredNode(_ node: ProjectTreeNode)
  {
    node.updateFilteredChildren(filterPredicate)
  }
  
  public func updateFilteredItem(_ item: AnyObject?)
  {
    let itemNode: ProjectTreeNode = item==nil ? hiddenRootNode : item as! ProjectTreeNode
    itemNode.updateFilteredChildren(filterPredicate)
  }
  
  public func selectedNodesTopLevelItems() -> [ProjectTreeNode]
  {
    return self.hiddenRootNode.findLocalRootsOfSelectedSubTrees(selection: self.selectedTreeNodes)
  }
  
  public func findLocalRootsOfSelectedSubTrees(selection: Set<ProjectTreeNode>) -> [ProjectTreeNode]
  {
    return self.hiddenRootNode.findLocalRootsOfSelectedSubTrees(selection: selection)
  }
  
  public func copyOfSelectionOfSubTree(of root: ProjectTreeNode, selection: Set<ProjectTreeNode>, recursive: Bool) -> ProjectTreeNode
  {
    return root.copyOfSelectionOfSubTree(selection: selection, recursive: recursive)
  }
  
  public func updateFilteredNodes()
  {
    self.hiddenRootNode.updateFilteredChildrenRecursively(filterPredicate)
  }
  
  public func setFilteredNodesAsMatching()
  {
    self.hiddenRootNode.setFilteredNodesAsMatching()
  }
  
  public func contains(_ item: ProjectTreeNode) -> Bool
  {
    return item.isDescendantOfNode(hiddenRootNode)
  }
  
  public func FindParent(recordID: CKRecord.ID) -> ProjectTreeNode?
  {
    if hiddenRootNode.recordID == recordID {return hiddenRootNode}
    return self.flattenedNodes().filter{$0.recordID == recordID}.first
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(ProjectTreeController.classVersionNumber)
    let projectLocalRootNode: ProjectTreeNode = rootNodes[1].childNodes[0]
    encoder.encode(projectLocalRootNode)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public convenience init(fromBinary decoder: BinaryDecoder) throws
  {
    self.init()
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > ProjectTreeController.classVersionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
   // let recordID = CKRecord.ID(recordName: "hiddenRootNode")
   // self.hiddenRootNode = ProjectTreeNode(displayName: "hiddenRootNode", recordID: recordID)
   // hiddenRootNode.recordID = recordID
    
    let node: ProjectTreeNode = try decoder.decode(ProjectTreeNode.self)
    let projectLocalRootNode: ProjectTreeNode = rootNodes[1].childNodes[0]
    projectLocalRootNode.childNodes = node.childNodes
    for child in projectLocalRootNode.childNodes
    {
      child.parentNode = projectLocalRootNode
    }
  }
  
}
