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

import Cocoa
import RenderKit
import SymmetryKit
import iRASPAKit
import OperationKit

/// FrameListViewController controls a tableView with the frames.
///
/// Note: representedObject is a Movie (an array of type [iRASPAStructure])
class FrameListViewController: NSViewController, NSMenuItemValidation, WindowControllerConsumer, ProjectConsumer, NSTableViewDataSource, NSTableViewDelegate, Reloadable, SelectionIndex
{
  @IBOutlet private weak var framesTableView: FrameListTableView?
  
  weak var windowController: iRASPAWindowController?
  
  var observeNotifications: Bool = true
  var filterContent: Bool = false
  
  private var draggedNodes: [iRASPAStructure] = []
  private var draggedIndexSet: IndexSet = IndexSet()
  
  @IBOutlet private var addContextMenu: NSMenu?
  
  let crystalIcon: NSImage = NSImage(named: "CrystalIcon")!
  let molecularIcon: NSImage = NSImage(named: "MolecularIcon")!
  let molecularCrystalIcon: NSImage = NSImage(named: "MolecularCrystalIcon")!
  let proteinIcon: NSImage = NSImage(named: "ProteinIcon")!
  let proteinCrystalIcon: NSImage = NSImage(named: "ProteinCrystalIcon")!
  let ellipsoidIcon: NSImage = NSImage(named: "EllipsoidIcon")!
  let ellipsoidCrystalIcon: NSImage = NSImage(named: "EllipsoidCrystalIcon")!
  let cylinderIcon: NSImage = NSImage(named: "CylinderIcon")!
  let cylinderCrystalIcon: NSImage = NSImage(named: "CylinderCrystalIcon")!
  let prismIcon: NSImage = NSImage(named: "PrismIcon")!
  let prismCrystalIcon: NSImage = NSImage(named: "PrismCrystalIcon")!
  let unknownIcon: NSImage = NSImage(named: "UnknownIcon")!
  
  lazy var frameQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "Structure queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = 8
    return queue
  }()
  
  lazy var copyAndPasteSerialQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "Structure queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  
  // called when present in a storyboard
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
  }
  
  deinit
  {
    //Swift.print("deinit: FrameListViewController")
  }
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    
    self.framesTableView?.doubleAction = #selector(FrameListViewController.frameTableViewDoubleClick)
  }
  
  
  // MARK: NSViewController lifecycle
  // =====================================================================
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    self.framesTableView?.registerForDraggedTypes([NSPasteboardTypeProjectTreeNode,
                                                   NSPasteboardTypeMovie,
                                                   NSPasteboardTypeFrame])
    self.framesTableView?.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    self.framesTableView?.registerForDraggedTypes([NSPasteboard.PasteboardType.filePromise])
    
    self.framesTableView?.setDraggingSourceOperationMask(.every, forLocal: true)
    self.framesTableView?.setDraggingSourceOperationMask(.every, forLocal: false)
  }

  
  override func viewWillAppear()
  {
    super.viewWillAppear()
    
    // reload the data again after the view did appear to have the correct background for the NSTableRowViews
    self.reloadData()
    
    //windowController?.masterViewControllerTabChanged(tab: 2)
    self.setDetailViewController()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    // for a NSTableView in SourceList-style, a reloadData must be done when on-screen
    // resulting artificts from not doing this: lost selection when resigning first-responder (e.g. import file)
    self.reloadData()
    
  }
  
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    // do not receive updates from detail-view page-controllers when not visible
  }
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
  
  // MARK: Reloading data
  // =====================================================================
  
  func reloadData()
  {
    self.framesTableView?.reloadData()
    self.reloadSelection()
    
    setDetailViewController()
  }
  
  // MARK: adding/removing 
  // =====================================================================
  
  func removeFrame(_ frame: iRASPAStructure, atIndex index: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = project.sceneList.selectedScene?.selectedMovie
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.addFrame(frame, atIndex: index)})
      
      let frame = movie.frames.remove(at: index)
      self.framesTableView?.removeRows(at: IndexSet(integer: index), withAnimation: .slideLeft)
      
      if movie.selectedFrame == frame
      {
        movie.selectedFrame = nil
      }
      movie.selectedFrames.remove(frame)
      
      self.reloadSelection()
     
      //self.windowController?.masterViewControllerTabChanged(tab: 2)
      self.setDetailViewController()
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func addFrame(_ frame: iRASPAStructure, atIndex index: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = project.sceneList.selectedScene?.selectedMovie
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.removeFrame(frame, atIndex: index)})
      
      if(!project.undoManager.isUndoing)
      {
        project.undoManager.setActionName(NSLocalizedString("Add frame(s)", comment: "Add frame"))
      }
      
      // insert new node
      self.framesTableView?.beginUpdates()
      movie.frames.insert(frame, at: index)
      self.framesTableView?.insertRows(at: IndexSet(integer: index), withAnimation: .slideRight)
      self.framesTableView?.endUpdates()
      
      if movie.selectedFrame == nil
      {
        movie.selectedFrame = frame
        movie.selectedFrames.insert(frame)
      }
      self.reloadSelection()
      
      //self.windowController?.masterViewControllerTabChanged(tab: 2)
      self.setDetailViewController()
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func moveFrame(fromIndex: Int, toIndex: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = project.sceneList.selectedScene?.selectedMovie
    {
      
      
      project.undoManager.setActionName(NSLocalizedString("Reorder frames", comment: "Reorder frames"))
      project.undoManager.registerUndo(withTarget: self, handler: {$0.moveFrame(fromIndex: toIndex, toIndex: fromIndex)})
      
      let frame = movie.frames[fromIndex]
      movie.frames.remove(at: fromIndex)
      self.framesTableView?.removeRows(at: IndexSet(integer: fromIndex), withAnimation: [])
      
      // insert new node
      movie.frames.insert(frame, at: toIndex)
      self.framesTableView?.insertRows(at: IndexSet(integer: toIndex), withAnimation: [.effectGap])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }


  // MARK: NSTableView required method
  // =====================================================================
  

  func numberOfRows(in aTableView: NSTableView) -> Int
  {
    if let movie: Movie = (self.proxyProject?.representedObject.loadedProjectStructureNode)?.sceneList.selectedScene?.selectedMovie
    {
      return movie.frames.count
    }
    return 0
  }

  
  
  func tableView(_ tableView: NSTableView, viewFor viewForTableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie,
       let view: NSTableCellView = self.framesTableView?.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "frameName"), owner: self) as? NSTableCellView,
       row < movie.frames.count
    {
      view.textField?.stringValue = movie.frames[row].structure.displayName
      
      view.imageView?.image = movie.frames[row].infoPanelIcon
      
      
      return view
    }
    return nil
  }
  
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
  {
    return 18.0
  }

  
  // MARK: Row-view
  // =====================================================================
  
  
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
  {
    if let rowView: FrameTableRowView = self.framesTableView?.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "frameTableRowView"), owner: self) as? FrameTableRowView
    {
      rowView.isSelected = false
      rowView.secondaryHighlighted = false
      
      // during undo/redo, the NSTableRowViews were deleted. They are remade when needed, and here we set the 'secondaryHighlighted' to correct value
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
         let selectedScene: Scene = project.sceneList.selectedScene,
         let selectedMovie: Movie = selectedScene.selectedMovie
      {
        if selectedMovie.selectedFrames.contains(selectedMovie.frames[row])
        {
          rowView.isSelected = true
        }
        
        if let selectedFrame = selectedMovie.selectedFrame,
           let selectedRow: Int = selectedMovie.frames.firstIndex(of: selectedFrame)
        {
          if (selectedRow == row)
          {
            rowView.isSelected = true
            rowView.secondaryHighlighted = true
          }
          else
          {
            rowView.isSelected = false
          }
        }
      }
     
      return rowView
    }
    return nil
  }
  
  func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int)
  {
    if let rowView = rowView as? FrameTableRowView
    {
      rowView.secondaryHighlighted = false
      rowView.isSelected = false
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
         let selectedScene: Scene = project.sceneList.selectedScene,
         let selectedMovie: Movie = selectedScene.selectedMovie
      {
        if selectedMovie.selectedFrames.contains(selectedMovie.frames[row])
        {
          rowView.isSelected = true
        }
        
        if let selectedFrame = selectedMovie.selectedFrame,
            let selectedRow: Int = selectedMovie.frames.firstIndex(of: selectedFrame)
        {
          if (row == selectedRow)
          {
            rowView.secondaryHighlighted = true
            rowView.isSelected = true
          }
        }
      }
      
    }
  }
  
  func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int)
  {
    if (row<0)
    {
      (rowView as? FrameTableRowView)?.isSelected = false
      (rowView as? FrameTableRowView)?.secondaryHighlighted = false
    }
  }
  
  // MARK: NSOutlineView rename on double-click
  // =====================================================================
  
  @objc func frameTableViewDoubleClick(_ sender: AnyObject)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
       let clickedRow: Int = self.framesTableView?.clickedRow, clickedRow >= 0
    {
      if let view: NSTableCellView = self.framesTableView?.view(atColumn: 0, row: clickedRow, makeIfNecessary: true) as? NSTableCellView,
         let textField: NSTextField = view.textField,
         textField.acceptsFirstResponder
      {
        view.window?.makeFirstResponder(textField)
      }
    }
  }
  
  func setFrameDisplayName(_ frame: iRASPAStructure, to newValue: String)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let oldName: String = frame.structure.displayName
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setFrameDisplayName(frame, to: oldName)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change frame name", comment: "Change frame name"))
      }
      
      frame.structure.displayName = newValue
      
      // reload item in the outlineView
      if let row: Int = selectedMovie.frames.firstIndex(of: frame)
      {
        self.framesTableView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
      }
      
      project.isEdited = true
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeFrameDisplayName(_ sender: NSTextField)
  {
    if let row: Int = self.framesTableView?.row(for: sender), row >= 0,
       let proxyProject = self.proxyProject, proxyProject.isEditable,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let newValue: String = sender.stringValue
      
      let frame = selectedMovie.frames[row]
      if frame.structure.displayName != newValue
      {
        self.setFrameDisplayName(frame, to: newValue)
      }
    }
  }
  
  
  // MARK: keyboard handling
  // =====================================================================
  
  
  override func keyDown(with theEvent: NSEvent)
  {
    self.interpretKeyEvents([theEvent])
  }
  
  override func deleteBackward(_ sender: Any?)
  {
    deleteSelection()
  }
  
  
  override func deleteForward(_ sender: Any?)
  {
    deleteSelection()
  }

  // MARK: Editing 
  // =====================================================================
  
  func insertSelectedFrames(_ frames: [iRASPAStructure], at indexSet: IndexSet,  newSelectedFrame: iRASPAStructure?, newSelection: Set<iRASPAStructure>)
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let currentSelectedFrame: iRASPAStructure? = selectedMovie.selectedFrame
      let currentSelection: Set<iRASPAStructure> = selectedMovie.selectedFrames
      
      self.framesTableView?.beginUpdates()
      
      for (i,index) in indexSet.enumerated()
      {
        selectedMovie.frames.insert(frames[i], at: index)
        self.framesTableView?.insertRows(at: IndexSet(integer: index), withAnimation: .slideRight)
      }
      
      self.framesTableView?.endUpdates()
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.deleteSelectedFrames(frames, from: indexSet, newSelectedFrame: currentSelectedFrame, newSelection: currentSelection)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Insert selection", comment: "Insert selection"))
      }
      
      selectedMovie.selectedFrame = newSelectedFrame
      selectedMovie.selectedFrames = newSelection
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), !renderStructures.isEmpty
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.reloadSelection()
      
      //self.windowController?.masterViewControllerTabChanged(tab: 2)
      self.setDetailViewController()
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func deleteSelectedFrames(_ frames: [iRASPAStructure], from indexSet: IndexSet, newSelectedFrame: iRASPAStructure?, newSelection: Set<iRASPAStructure>)
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let currentSelectedFrame: iRASPAStructure? = selectedMovie.selectedFrame
      let currentSelection: Set<iRASPAStructure> = selectedMovie.selectedFrames
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.insertSelectedFrames(frames, at: indexSet, newSelectedFrame: currentSelectedFrame, newSelection: currentSelection)})
      
      self.framesTableView?.beginUpdates()
      
      for index in indexSet.reversed()
      {
        selectedMovie.frames.remove(at: index)
        self.framesTableView?.removeRows(at: IndexSet(integer: index), withAnimation: .slideLeft)
      }
      
      self.framesTableView?.endUpdates()
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Delete selection", comment: "Delete selection"))
      }
      
      selectedMovie.selectedFrame = newSelectedFrame
      selectedMovie.selectedFrames = newSelection
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), !renderStructures.isEmpty
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.reloadSelection()
      
      //self.windowController?.masterViewControllerTabChanged(tab: 2)
      self.setDetailViewController()
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func deleteSelection()
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie,
       let indexSet: IndexSet = self.framesTableView?.selectedRowIndexes
    {
      let selectedFrames: [iRASPAStructure] = indexSet.map{selectedMovie.frames[$0]}
      
      var newSelectedFrame: iRASPAStructure? = nil
      var newSelection: Set<iRASPAStructure> = []
      
      if let first: Int = IndexSet(integersIn: 0..<selectedMovie.frames.count).subtracting(indexSet).first
      {
        newSelectedFrame = selectedMovie.frames[first]
        newSelection.insert(selectedMovie.frames[first])
      }
      
      self.deleteSelectedFrames(selectedFrames, from: indexSet, newSelectedFrame: newSelectedFrame, newSelection: newSelection)
    }
  }
  
  // MARK: Set and update detail views
  // =====================================================================
  
  func setDetailViewController()
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectionMovie: Movie = selectedScene.selectedMovie
    {
      let selectedArrangedObjects: [Any] = project.sceneList.selectedScene?.selectedMovie?.selectedFrames.compactMap{$0} ?? [[]]
      let frames: [iRASPAStructure] = selectionMovie.allIRASPAStructures
      let arrangedObjects: [Any] = frames.isEmpty ? [[]] : frames
      
      if let selectedFrame: iRASPAStructure = selectionMovie.selectedFrame,
         let selectionIndex: Int = selectionMovie.frames.firstIndex(of: selectedFrame)
      {
        self.windowController?.setPageControllerObjects(arrangedObjects: arrangedObjects, selectedArrangedObjects: selectedArrangedObjects, selectedIndex: selectionIndex)
      
        self.windowController?.setPageControllerFrameObject(arrangedObjects: arrangedObjects,  selectedIndex: selectionIndex)
      }
      else
      {
        self.windowController?.setPageControllerObjects(arrangedObjects: [[]], selectedArrangedObjects: [[]], selectedIndex: 0)
        
          self.windowController?.setPageControllerFrameObject(arrangedObjects: [[]],  selectedIndex: 0)
      }
    }
  }
  
  func updateDetailViewController()
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie,
       let selectedFrame: iRASPAStructure = selectedMovie.selectedFrame,
       let selectionIndex: Int = selectedMovie.frames.firstIndex(of: selectedFrame)
    {
      let selectedArrangedObjects: [Any] = project.sceneList.selectedScene?.selectedMovie?.selectedFrames.compactMap{$0} ?? [[]]
      
      self.windowController?.setPageControllerSelection(selectedArrangedObjects: selectedArrangedObjects, selectedIndex: selectionIndex)
      
      self.windowController?.setPageControllerFrameSelection(selectedIndex: selectionIndex)
    }
  }
  
  func setSelectionIndex(index: Int)
  {
    if let sceneList = (self.proxyProject?.representedObject.loadedProjectStructureNode)?.sceneList,
       let movie: Movie = sceneList.selectedScene?.selectedMovie
    {
      movie.selectedFrames = [movie.frames[index]]
      movie.selectedFrame = movie.frames[index]
      sceneList.synchronizeAllMovieFrames(to: index)
      self.reloadSelection()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
   
    self.windowController?.detailTabViewController?.renderViewController?.redraw()
    
    // set the other detail view-controllers to the same index
    updateDetailViewController()
  }
  
  // MARK: Selection handling
  // =====================================================================
  
  func reloadSelection()
  {
    let storedObserveNotifications: Bool = self.observeNotifications
    self.observeNotifications = false
    
    //self.framesTableView?.deselectAll(nil)
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let selectedFrames = selectedMovie.selectedFrames
      
      self.framesTableView?.deselectAll(nil)
      var selectedRowIndexes: IndexSet = IndexSet()
      for frame in selectedFrames
      {
        if let index: Int = selectedMovie.frames.firstIndex(of: frame)
        {
          selectedRowIndexes.insert(index)
        }
      }
      self.framesTableView?.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
      
      if let selectedFrame = selectedMovie.selectedFrame,
         let selectedRow: Int = selectedMovie.frames.firstIndex(of: selectedFrame)
      {
        self.windowController?.infoPanel?.showInfoItem(item: MaterialsInfoPanelItemView(image: selectedFrame.infoPanelIcon, message: selectedFrame.infoPanelString))
        
        self.framesTableView?.enumerateAvailableRowViews({ (rowView, row) in
          if (row == selectedRow)
          {
            (rowView as? FrameTableRowView)?.isSelected = true
            (rowView as? FrameTableRowView)?.secondaryHighlighted = true
            rowView.needsDisplay = true
          }
          else
          {
            (rowView as? FrameTableRowView)?.secondaryHighlighted = false
            rowView.needsDisplay = true
          }
        })
      }
    }
    
    self.observeNotifications = storedObserveNotifications
    
  }
  
  func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      movie.selectedFrames = []
      
      for row in proposedSelectionIndexes
      {
        let frame = movie.frames[row]
        movie.selectedFrames.insert(frame)
      }
    }
    return proposedSelectionIndexes
  }

  func tableViewSelectionDidChange(_ aNotification: Notification)
  {
    
    if (self.observeNotifications)
    {
      if let proxyProject = self.proxyProject,
         let project = proxyProject.representedObject.loadedProjectStructureNode,
         let selectedScene: Scene = project.sceneList.selectedScene,
         let selectedMovie: Movie = selectedScene.selectedMovie,
         let oldSelectedRow: Int = selectedMovie.selectedFrame != nil ? selectedMovie.frames.firstIndex(of: selectedMovie.selectedFrame!) : -1,
         let selectedRow: Int = self.framesTableView?.selectedRow, selectedRow >= 0,
         let selectedRows: IndexSet = self.framesTableView?.selectedRowIndexes
      {
        if ((selectedRows.count == 1) || (!selectedRows.contains(oldSelectedRow)))
        {
          selectedMovie.selectedFrame = selectedMovie.frames[selectedRow]
          selectedMovie.selectedFrames.insert(selectedMovie.frames[selectedRow])
          
          self.windowController?.infoPanel?.showInfoItem(item: MaterialsInfoPanelItemView(image: selectedMovie.selectedFrame?.infoPanelIcon, message: selectedMovie.selectedFrame?.infoPanelString))
        
          // set the other movies to the same movie-index
          project.sceneList.synchronizeAllMovieFrames(to: selectedRow)
        
          // highlight selected index
          self.framesTableView?.enumerateAvailableRowViews({ (rowView, row) in
            if (row == selectedRow)
            {
              (rowView as? FrameTableRowView)?.secondaryHighlighted = true
              (rowView as? FrameTableRowView)?.isSelected = true
              rowView.needsDisplay = true
            }
            else
            {
              (rowView as? FrameTableRowView)?.secondaryHighlighted = false
              rowView.needsDisplay = true
            }
          })
        }
        else
        {
          // since extending the selection changes the 'selectedRow' (the last selected item), set it back
          // this will NOT change the selection, but only update the 'selectedRow'
          // This is important when changing the selection afterwards with the 'up/down' keys, it will start from the 'selectedRow'.
          self.framesTableView?.selectRowIndexes(IndexSet(integer: oldSelectedRow), byExtendingSelection: true)
        }
      }
      
      //windowController?.masterViewControllerSelectionChanged(tab: 2)
      self.updateDetailViewController()
        
      if let proxyProject = self.proxyProject,
        let project = proxyProject.representedObject.loadedProjectStructureNode,
        let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), !renderStructures.isEmpty
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      //self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
     
    }
  }
  
  // MARK: Import/Export
  // =====================================================================
  
  
  func importStructureFiles(_ URLs: [URL], asSeparateProjects: Bool)
  {
    
  }

  // MARK: Menu validation
  // =====================================================================
  
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if (menuItem.action == #selector(copy(_:)))
    {
      return (self.framesTableView?.selectedRowIndexes.count ?? 0) > 0
    }
    
    if let proxyProject: ProjectTreeNode = self.proxyProject, !proxyProject.isEnabled
    {
      return false
    }
    
    if (menuItem.action == #selector(addCrystal(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(addMolecularCrystal(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(addMolecule(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(addProtein(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(addProteinCrystal(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(paste(_:)))
    {
      return iRASPAWindowController.copyAndPasteConcurrentQueue.operationCount == 0
    }
    
    if (menuItem.action == #selector(cut(_:)))
    {
      return (self.framesTableView?.selectedRowIndexes.count ?? 0) > 0
    }
    
    return true
  }
  
  // MARK: plus/minus buttons
  // =====================================================================
  
  @IBAction func deleteSelectedFrames(_ sender: NSButton)
  {
    if let project = self.proxyProject, project.isEditable
    {
      self.deleteSelection()
    }
  }
  
  
  
  @IBAction func addCrystal(_ sender: AnyObject)
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      var insertionIndex: Int = 0
      if let selectedFrame: iRASPAStructure = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let crystal = Crystal(name: "New crystal")
      crystal.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(crystal: crystal)
      self.addFrame(frame, atIndex: insertionIndex)
      self.framesTableView?.endUpdates()
    }
  }
  
  @IBAction func addMolecularCrystal(_ sender: NSMenuItem)
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      var insertionIndex: Int = 0
      if let selectedFrame: iRASPAStructure = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let molecularCrystal = MolecularCrystal(name: "New molecular crystal")
      molecularCrystal.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(molecularCrystal: molecularCrystal)
      self.addFrame(frame, atIndex: insertionIndex)
      self.framesTableView?.endUpdates()
    }
  }
  
  @IBAction func addMolecule(_ sender: NSMenuItem)
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      var insertionIndex: Int = 0
      if let selectedFrame: iRASPAStructure = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let molecule = Molecule(name: "New molecule")
      molecule.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(molecule: molecule)
      self.addFrame(frame, atIndex: insertionIndex)
      self.framesTableView?.endUpdates()
    }
  }
  
  @IBAction func addProtein(_ sender: NSMenuItem)
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      var insertionIndex: Int = 0
      if let selectedFrame: iRASPAStructure = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let protein = Protein(name: "New protein")
      protein.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(protein: protein)
      self.addFrame(frame, atIndex: insertionIndex)
      self.framesTableView?.endUpdates()
    }
  }
  
  @IBAction func addProteinCrystal(_ sender: NSMenuItem)
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      var insertionIndex: Int = 0
      if let selectedFrame: iRASPAStructure = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let proteinCrystal = ProteinCrystal(name: "New protein crystal")
      proteinCrystal.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(proteinCrystal: proteinCrystal)
      self.addFrame(frame, atIndex: insertionIndex)
      self.framesTableView?.endUpdates()
    }
  }
  
  // MARK: Drag & Drop
  // =====================================================================
  
  func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet)
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      // store the dragged-node locally as an array of movies
      self.draggedNodes = (movie.frames as NSArray).objects(at: rowIndexes).compactMap{$0 as? iRASPAStructure}
      self.draggedIndexSet = rowIndexes
      debugPrint("draggedNodes count: \(self.draggedNodes.count)")
    
      let location: NSPoint = session.draggingLocation
      let numberOfDragItems: Int = self.draggedNodes.count
      session.enumerateDraggingItems(options: [], for: nil, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (draggingItem, index, stop) in
      
        let frame = draggingItem.draggingFrame
        let size: NSSize = frame.size
        let height: CGFloat = tableView.rowHeight
        draggingItem.draggingFrame = NSMakeRect(location.x - 0.5 * size.width, location.y - height * CGFloat(index) + (CGFloat(numberOfDragItems) - 1.5) * height, size.width , size.height)
      })
    }
  }
  
  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting?
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      return movie.frames[row]
    }
    return nil
  }
  
  func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation
  {
    if dropOperation == .on
    {
      return []
    }
    return .move
  }
  
  func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool
  {
    if let draggingSource = info.draggingSource as? NSTableView, tableView === draggingSource
    {
      return internalDrop(info: info, row: row)
    }
    else
    {
      return externalDrop(info: info, tableView: tableView, row: row)
    }
  }

  func internalDrop(info: NSDraggingInfo, row: Int) -> Bool
  {
    debugPrint("internalDrop frame")
    
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      var childIndex: Int = row
      
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      
      // drag/drop occured within the same outlineView -> reordering
      self.framesTableView?.beginUpdates()
      for frame: iRASPAStructure in self.draggedNodes
      {
        // Moving it from within the same parent! Account for the remove, if it is past the oldIndex
        
        if let fromIndex = movie.frames.firstIndex(of: frame)
        {
          if (childIndex > fromIndex)
          {
            childIndex = childIndex - 1 // account for the remove
          }
          
          self.moveFrame(fromIndex: fromIndex, toIndex: childIndex)
          childIndex = childIndex + 1
        }

      }
      self.framesTableView?.endUpdates()
     
      self.observeNotifications = observeNotificationsStored
      
      self.reloadSelection()
    }
    debugPrint("drop done")
    
    return true
  }
  
  func externalDrop(info: NSDraggingInfo, tableView: NSTableView, row: Int) -> Bool
  {
    debugPrint("externalDrop frame")
    var childIndex: Int = row
    
    self.framesTableView?.beginUpdates()
    info.enumerateDraggingItems(options: .concurrent, for: self.framesTableView, classes: [iRASPAStructure.self], searchOptions: [:], using: { (draggingItem , idx, stop)  in
      if let frame  = draggingItem.item as? iRASPAStructure
      {
        debugPrint("external frame: \(frame)")
        self.addFrame(frame, atIndex: childIndex)
        childIndex += 1
        
        // set the draggingframe for all pasteboard-items
        if let height: CGFloat = self.framesTableView?.rowHeight,
           let frame: NSRect = self.framesTableView?.frameOfCell(atColumn: 0, row: childIndex),
           frame.width > 0, height > 0
        {
          // frameOfCell(atColumn:row:) not working in NSOutlineview 'Sourcelist'-style
          draggingItem.draggingFrame = NSMakeRect(frame.origin.x, frame.origin.y + height * CGFloat(childIndex - 1), frame.width, height)
        }
      }
    })
    self.framesTableView?.endUpdates()
    
    if let project = self.proxyProject?.representedObject.project as? ProjectStructureNode
    {
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      let renderStructures: [RKRenderStructure] = project.renderStructures
      if !renderStructures.isEmpty
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      }
    }
    return true
  }
  
  // NOTE: only used for drag&drop (not copy&paste) and not called when the item is an NSPasteboardItemDataProvider
  func tableView(_ tableView: NSTableView, namesOfPromisedFilesDroppedAtDestination dropDestination: URL, forDraggedRowsWith indexSet: IndexSet) -> [String]
  {
    for node in self.draggedNodes
    {
      if let data: Data = node.pasteboardPropertyList(forType: NSPasteboardTypeProjectTreeNode) as? Data,
         let compressedData: Data = data.compress(withAlgorithm: .lzma)
      {
        let displayName: String = node.structure.displayName
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let url: URL = dropDestination.appendingPathComponent(displayName).appendingPathExtension(pathExtension)
        do
        {
          try compressedData.write(to: url, options: .atomic)
        }
        catch
        {
          
        }
      }
    }
    return self.draggedNodes.map{$0.structure.displayName}
  }

  // MARK: Copy / Paste / Cut / Delete
  // =====================================================================
  
  // copy all selected 'movie'-elements as 'ProjectTreeNode' so that it can also be copied to the 'ProjectTreeController'
  @objc func copy(_ sender: AnyObject)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject,
       let parentProject: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      
      if let selectedFrames: [iRASPAStructure] = parentProject.sceneList.selectedScene?.selectedMovies.flatMap({$0.selectedFrames})
      {
        pasteboard.writeObjects(selectedFrames)
      }
    }
  }
  
  @objc func paste(_ sender: AnyObject)
  {
    var insertionIndex: Int = 0
    if let selectedRow = self.framesTableView?.selectedRow
    {
      insertionIndex = selectedRow + 1
    }
    
    let pasteboard = NSPasteboard.general
    if let pasteboardItems: [Any]  = pasteboard.readObjects(forClasses: [iRASPAStructure.self], options: nil)
    {
      self.framesTableView?.beginUpdates()
      for pasteboardItem in pasteboardItems
      {
        if let frame  = pasteboardItem as? iRASPAStructure
        {
          self.addFrame(frame, atIndex: insertionIndex)
          insertionIndex += 1
        }
      }
      self.framesTableView?.endUpdates()
      
      //self.windowController?.masterViewControllerTabChanged(tab: 2)
      self.setDetailViewController()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let project = self.proxyProject?.representedObject.project as? ProjectStructureNode
      {
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
        let renderStructures: [RKRenderStructure] = project.renderStructures
        if !renderStructures.isEmpty
        {
          self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
      }
    }
  }
  
  @objc func cut(_ sender: AnyObject)
  {
    copy(sender)
    self.deleteSelection()
  }
}
