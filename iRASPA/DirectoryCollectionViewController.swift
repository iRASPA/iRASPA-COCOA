/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa
import iRASPAKit
import SymmetryKit

class DirectoryCollectionViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, ProjectConsumer
{
  var projectTreeNodes: [ProjectTreeNode] = []
  
  @IBOutlet var collectionView: NSCollectionView?
  @IBOutlet var textLabel: NSTextField?
  
  @objc dynamic var predicate: NSPredicate = NSPredicate(format: "heliumVoidFraction >= 0.0")
  {
    didSet
    {
      if let proxyProject = proxyProject
      {
        projectTreeNodes = proxyProject.flattenedLeafNodes().filter{$0.matchesFilter}.filter{predicate.evaluate(with: $0.representedObject)}
        self.textLabel?.stringValue = String(projectTreeNodes.count) + " items"
      }
      else
      {
        projectTreeNodes = []
        self.textLabel?.stringValue = ""
      }
      self.collectionView?.reloadData()
    }
  }
  
  func reloadData()
  {
    if let proxyProject = proxyProject
    {
      projectTreeNodes = proxyProject.flattenedLeafNodes().filter{$0.matchesFilter}.filter{predicate.evaluate(with: $0.representedObject)}
      self.textLabel?.stringValue = String(projectTreeNodes.count) + " items"
    }
    else
    {
      projectTreeNodes = []
      self.textLabel?.stringValue = ""
    }
    self.collectionView?.reloadData()
    
  }
  
  weak var proxyProject: ProjectTreeNode?
  {
    didSet
    {
      if let proxyProject = proxyProject
      {
        projectTreeNodes = proxyProject.flattenedLeafNodes().filter{$0.matchesFilter}.filter{predicate.evaluate(with: $0.representedObject)}
        self.textLabel?.stringValue = String(projectTreeNodes.count) + " items"
      }
      else
      {
        projectTreeNodes = []
        self.textLabel?.stringValue = ""
      }
      self.collectionView?.reloadData()
    }
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    let flowLayout = NSCollectionViewFlowLayout()
    flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
    flowLayout.sectionInset = NSEdgeInsets(top: 20.0, left: 20.0, bottom: 30.0, right: 20.0)
    flowLayout.minimumInteritemSpacing = 10.0
    flowLayout.minimumLineSpacing = 20.0
    if #available(OSX 10.12, *) {
      flowLayout.sectionHeadersPinToVisibleBounds = true
    } else {
      // Fallback on earlier versions
    }
    collectionView?.collectionViewLayout = flowLayout
    view.wantsLayer = true
    
    self.collectionView?.registerForDraggedTypes([NSPasteboardTypeProjectTreeNode])
    
    
    
    // Enable dragging items from our CollectionView to other applications.
    self.collectionView?.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
    
    // Enable dragging items within and into our CollectionView.
    self.collectionView?.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    self.reloadData()
  }
  
  public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int
  {
    return self.projectTreeNodes.count
  }
  
  public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem
  {
    let item: NSCollectionViewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProjectCollectionViewItem"), for: indexPath)
    item.textField?.stringValue = projectTreeNodes[indexPath.last!].displayName
    item.textField?.textColor = NSColor.black
    item.representedObject = projectTreeNodes[indexPath.last!]
    item.imageView?.image = NSImage(named: "MOF")
    return item
  }
  
  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>)
  {
    print(indexPaths)
    
    /*
    collectionView.performBatchUpdates({ () -> Void in
      let fromIndexPath = indexPaths.first!
      let toIndexPath = NSIndexPath(forItem: self.projectTreeNodes.count - 1, inSection: 0)
      
      self.collectionView?.moveItem(at: fromIndexPath, to: toIndexPath as IndexPath)
    }, completionHandler: nil)*/
  }
  
  public func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool
  {
    return true
  }
}
