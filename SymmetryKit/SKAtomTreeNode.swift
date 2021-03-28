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
import MathKit
import simd

public let NSPasteboardTypeAtomTreeNode: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType(rawValue: "nl.darkwing.iraspa.atom")

public final class SKAtomTreeNode:  NSObject, NSPasteboardReading, NSPasteboardWriting, BinaryDecodable, BinaryEncodable, Copying
{
  private static var classVersionNumber: Int = 1

  public var displayName: String = "Empty"
  
  /// The parent of a AtomTreeNode
  ///
  /// The parent of a node should always exists except for the single root-node which should be hidden and inaccesible from a tree-controller.
  /// The (hidden) root-node and just created nodes are the only nodes with a non-existing parent
  public weak var parentNode: SKAtomTreeNode? = nil
  
  /// The children of a AtomTreeNode
  ///
  /// An array of tree-nodes. A "leaf"-node has no children (an empty childrens-array).
  public var childNodes: [SKAtomTreeNode] = [SKAtomTreeNode]()
  
  
  public var filteredAndSortedNodes: [SKAtomTreeNode] = [SKAtomTreeNode]()
  
  // must be true to allow insert/deletions in the table with animations
  public var matchesFilter: Bool = true
  
  public var isImplicitelySelected: Bool = false // used at run-time for AtomTableRowView-implicit selection
  
  public var isGroup: Bool = false
  
  public var isEditable: Bool = true
  
  /// The object the tree node represents.
  ///
  public var representedObject: SKAsymmetricAtom
  
  public convenience init(representedObject modelObject: SKAsymmetricAtom, isGroup: Bool = false)
  {
    self.init(name: modelObject.displayName, representedObject: modelObject, isGroup: isGroup)
  }
  
  public init(name: String, representedObject: SKAsymmetricAtom, isGroup: Bool = false)
  {
    self.displayName = name
    self.representedObject = representedObject
    self.isGroup = isGroup
    super.init()
  }
  
  public required init(treeNode: SKAtomTreeNode)
  {
    self.displayName = treeNode.displayName
    self.representedObject = treeNode.representedObject
    self.isGroup = treeNode.isGroup
    self.childNodes = treeNode.childNodes
    
    super.init()
    
    // let the children now point to 'self' as the parent
    for child in childNodes
    {
      child.parentNode = self
    }
  }
  
  required public init(original: SKAtomTreeNode)
  {
    self.displayName = original.displayName
    self.representedObject = original.representedObject.copy()
    self.isGroup = original.isGroup
    self.isEditable = original.isEditable
    self.childNodes = []
  }
  
  // MARK: -
  // MARK: NSPasteboardWriting support
  
  // 1) an object added to the pasteboard will first be sent an 'writableTypesForPasteboard' message
  // 2) the object will then receive an 'pasteboardPropertyListForType' for each of these types
  
  // kPasteboardTypeFilePromiseContent
  // kPasteboardTypeFileURLPromise
  
  
  
  public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    switch(pasteboard.name)
    {
    case NSPasteboard.Name.dragPboard:
      return [NSPasteboard.PasteboardType(kPasteboardTypeFilePromiseContent),NSPasteboardTypeAtomTreeNode]
    case NSPasteboard.Name.generalPboard:
      return [NSPasteboardTypeAtomTreeNode, NSPasteboard.PasteboardType(String(kUTTypeFileURL))]
    default:
      return [NSPasteboardTypeAtomTreeNode]
    }
  }
  
  
  public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  {
    return NSPasteboard.WritingOptions.promised
  }
  
  
  
  public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
  {
    switch(type)
    {
    case NSPasteboardTypeAtomTreeNode:
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self)
      return Data(binaryEncoder.data)
    case NSPasteboard.PasteboardType(kPasteboardTypeFilePromiseContent):
      return NSPasteboardTypeAtomTreeNode.rawValue
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)): // for writing to NSSharingService (email-attachment)
      let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeAtomTreeNode.rawValue).pathExtension
      let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.displayName).appendingPathExtension(pathExtension)
      
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self)
      let data: Data = Data(binaryEncoder.data)
      
      try! data.write(to: url, options: .atomicWrite)
      return (url as NSPasteboardWriting).pasteboardPropertyList(forType: type)
    default:
      return nil
    }
  }
  
  
  // MARK: -
  // MARK: NSPasteboardReading support
  
  // 1) the pasteboard will try to find a class that can read pasteboard data, sending it an 'readableTypesForPasteboard' message
  // 2) once such a class had been found, it will sent the class an 'init' message
  
  
  public class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  {
    switch(type)
    {
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)):
      return NSURL.readingOptions(forType: type, pasteboard: pasteboard)
    default:
      return [.asData]
    }
  }
  
  
  public class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    return [NSPasteboardTypeAtomTreeNode]
  }
  
  
  public convenience required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
  {
    switch(type)
    {
    case NSPasteboardTypeAtomTreeNode:
      guard let data: Data = propertyList as? Data,
            let atom: SKAtomTreeNode = try? BinaryDecoder(data: [UInt8](data)).decode(SKAtomTreeNode.self) else {return nil}
      self.init(name: atom.displayName, representedObject: atom.representedObject)
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)):
      guard let url: URL = propertyList as? URL,
           let data: Data = try? Data(contentsOf: url),
           let atom: SKAtomTreeNode = try? BinaryDecoder(data: [UInt8](data)).decode(SKAtomTreeNode.self) else {return nil}
      self.init(name: atom.displayName, representedObject: atom.representedObject)
    default:
      return nil
    }
  }
  
  public var areAllAncestorsVisible: Bool
  {
    weak var treeNode: SKAtomTreeNode? = self.parentNode
    while(treeNode?.parentNode != nil)
    {
      if !(treeNode?.representedObject.isVisible)!
      {
        return false
      }
      treeNode = treeNode?.parentNode
    }
    return true
  }
  
  
  
  
  public var path: String
  {
    if (parentNode == nil)
    {
      return "Projects"
    }
    else
    {
      if let parentPath = self.parentNode?.path
      {
        let representedString = self.representedObject.description
        return parentPath + "/" + representedString
      }
      return ""
    }
  }
  
  
  /// Whether the node is a root-node or not
  ///
  /// - returns: true if the node is a root-node, otherwise false
  public func isRootNode() -> Bool
  {
    assert(self.parentNode != nil, "isRootNode: Should not ask information about the hidden root-node")
    
    if (self.parentNode?.parentNode == nil)
    {
      return true
    }
    else
    {
      return false
    }
  }
  
  /// Returns the position of the receiver relative to its root parent.
  ///
  /// Note: the Index path is empty for isolated tree nodes
  ///
  /// - returns: An index path that represents the receiver’s position relative to the tree’s root node.
  public var indexPath: IndexPath
  {
    get
    {
      if let parentNode = parentNode
      {
        let path: IndexPath = parentNode.indexPath
        let index: Int = parentNode.childNodes.firstIndex(of: self)!
        
        if (path.count > 0)
        {
          return path.appending(index)
        }
        else
        {
          return [index]
        }
      }
      else
      {
        return []
      }
    }
  }
  
  public var isLeaf: Bool
  {
    return !self.isGroup
  }
  
  /// Inserts the node into another (parent) node at a specified index
  ///
  /// - parameter inParent: The parent where the node will be inserted into.
  /// - parameter atIndex: The index of insertion
  public func insert(inParent parent: SKAtomTreeNode, atIndex index: Int)
  {
    assert(index<=parent.childNodes.count, "AtomTreeNode insert: \(index) not in range children \(parent.childNodes.count)")
    
    self.parentNode=parent
    parent.childNodes.insert(self, at: index)
    
  }
  
  /// Appends the node into another (parent) node
  ///
  /// - parameter inParent: The parent where the node will be inserted into.
  public func append(inParent parent: SKAtomTreeNode)
  {
    self.parentNode = parent
    parent.childNodes.insert(self, at: parent.childNodes.count)
    
  }
  
  /// Removes the node from its parent
  // Note: this takes 5 seconds for MIL-101 for removing a large set
  public func removeFromParent()
  {
    if let parentNode = parentNode,
      let index: Int = parentNode.childNodes.firstIndex(of: self)
    {
      parentNode.childNodes.remove(at: index)
      self.parentNode = nil
    }
    else
    {
      fatalError("AtomTreeNode removeFromParent: node not present in the children of the parent")
    }
  }
  
  
  
  /// Returns the receiver’s descendent at the specified index path.
  ///
  /// Note: an error occurs if the indexPath is not valid
  ///
  /// - parameter indexPath: An index path specifying a descendent of the receiver.
  /// - returns: The tree node at the specified index path.
  public func descendantNodeAtIndexPath(_ indexPath: IndexPath) -> SKAtomTreeNode?
  {
    let length: Int = indexPath.count
    var node: SKAtomTreeNode = self
    
    for i in 0..<length
    {
      let index: Int = indexPath[i]
      if(index>=node.childNodes.count)
      {
        return nil
      }
      
      node=node.childNodes[index]
    }
    
    return node
  }
  
  public func adjacentIndexPath() -> IndexPath
  {
    if (self.indexPath.isEmpty)
    {
      return [0]
    }
    else
    {
      return self.indexPath.dropLast() + [self.indexPath.last! + 1]
    }
  }
  
  
  public func sortWithSortDescriptors(_ sortDescriptors: [AnyObject], recursively: Bool)
  {
    
  }
  
  public func flattenedNodes() -> [SKAtomTreeNode]
  {
    return [self] + self.descendantNodes()
  }
  
  public func flattenedLeafNodes() -> [SKAtomTreeNode]
  {
    if self.isLeaf
    {
      return [self]
    }
    else
    {
      return self.descendantLeafNodes()
    }
  }
  
  public func flattenedGroupNodes() -> [SKAtomTreeNode]
  {
    if self.isLeaf
    {
      return []
    }
    else
    {
      return [self] + self.descendantGroupNodes()
    }
  }
  
  // includes hiddenRootNode
  public func ancestors() -> [SKAtomTreeNode]
  {
    var parents = [SKAtomTreeNode]()
    
    if let parentNode = parentNode
    {
      parents.append(parentNode)
      parents += parentNode.ancestors()
    }
    
    return parents
  }
  
  
  /// Returns an array of AtomTreeNodes descending from self using recursion.
  public func descendants() -> [SKAtomTreeNode]
  {
    var descendants=[SKAtomTreeNode]()
    
    for  child in self.childNodes
    {
      if (child.isLeaf)
      {
        descendants.append(child)
      }
      else
      {
        descendants+=child.descendants()
      }
    }
    
    return descendants
  }
  
  public func descendantNodes() -> [SKAtomTreeNode]
  {
    var descendants=[SKAtomTreeNode]()
    
    for  child in self.childNodes
    {
      descendants.append(child)
      if (!child.isLeaf)
      {
        descendants += child.descendantNodes()
      }
    }
    
    return descendants
  }
  
  public func descendantLeafNodes() -> [SKAtomTreeNode]
  {
    var descendants=[SKAtomTreeNode]()
    
    for  child in self.childNodes
    {
      if child.isLeaf
      {
        descendants.append(child)
      }
      if (!child.isLeaf)
      {
        descendants += child.descendantLeafNodes()
      }
    }
    
    return descendants
  }
  
  public func descendantGroupNodes() -> [SKAtomTreeNode]
  {
    var descendants=[SKAtomTreeNode]()
    
    for  child in self.childNodes
    {
      if (!child.isLeaf)
      {
        descendants.append(child)
        descendants += child.descendantGroupNodes()
      }
    }
    
    return descendants
  }
  
  public func flattenedObjects() -> [SKAsymmetricAtom]
  {
    return [representedObject] + self.descendantObjects()
  }
  
  
  public func descendantObjects() -> [SKAsymmetricAtom]
  {
    var descendants = [SKAsymmetricAtom]()
    
    for  child in self.childNodes
    {
      descendants.append(child.representedObject)
      if (!child.isLeaf)
      {
        descendants += child.descendantObjects()
      }
    }
    
    return descendants
  }
  
  
  public func isDescendantOfNode(_ parentNode: SKAtomTreeNode) -> Bool
  {
    var treeNode: SKAtomTreeNode? = self
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
  
  // MARK: -
  // MARK: Filtering support
  
  public func updateFilteredChildren(_ predicate: (SKAtomTreeNode) -> Bool)
  {
    for node in self.childNodes
    {
      node.matchesFilter = true
      node.matchesFilter = predicate(self)
    }
    
    self.filteredAndSortedNodes = self.childNodes.filter{$0.matchesFilter}
    
    // if we have filtered nodes, then all parents of this node needs to be included
    if (self.filteredAndSortedNodes.count > 0)
    {
      self.matchesFilter = true
    }
  }
  
  public func updateFilteredChildrenRecursively(_ predicate: (SKAtomTreeNode) -> Bool)
  {
    self.matchesFilter = false
    
    self.matchesFilter = predicate(self)
    
    for node in childNodes
    {
      node.updateFilteredChildrenRecursively(predicate)
    }
    
    // if we have filtered nodes, then all parents of this node needs to be included
    if (self.matchesFilter)
    {
      if let parentNode = parentNode
      {
        parentNode.matchesFilter = true
      }
    }
    
    filteredAndSortedNodes = childNodes.filter{$0.matchesFilter}
    
  }
  
  public func setFilteredNodesAsMatching()
  {
    self.matchesFilter = true
    filteredAndSortedNodes = childNodes
    for node in childNodes
    {
      node.setFilteredNodesAsMatching()
    }
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKAtomTreeNode.classVersionNumber)
    
    encoder.encode(self.displayName)
    encoder.encode(self.isGroup)
    encoder.encode(self.isEditable)
    
    encoder.encode(self.representedObject)
    encoder.encode(self.childNodes)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKAtomTreeNode.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.isGroup = try decoder.decode(Bool.self)
    self.isEditable = try decoder.decode(Bool.self)
    
    self.representedObject = try decoder.decode(SKAsymmetricAtom.self)
    self.childNodes = try decoder.decode([SKAtomTreeNode].self)
    
    super.init()
    
    // let the children now point to 'self' as the parent
    for child in childNodes
    {
      child.parentNode = self
    }
  }
  
}
