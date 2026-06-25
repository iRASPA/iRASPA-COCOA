/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
  
  private var draggedNodes: [iRASPAObject] = []
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
    //self.framesTableView?.registerForDraggedTypes([NSPasteboard.PasteboardType.filePromise])
    
    self.framesTableView?.setDraggingSourceOperationMask(.every, forLocal: true)
    self.framesTableView?.setDraggingSourceOperationMask(.every, forLocal: false)
    
    // Draw selection in FrameTableRowView; AppKit source-list highlighting no longer works
    // reliably with layer-backed row views on recent macOS releases.
    self.framesTableView?.selectionHighlightStyle = .none
    self.framesTableView?.allowsEmptySelection = false
    self.framesTableView?.applySourceListChrome()
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
    self.framesTableView?.window?.makeFirstResponder(self.framesTableView)
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
    let storedObserveNotifications: Bool = self.observeNotifications
    self.observeNotifications = false
    
    if let tableView = self.framesTableView
    {
      let allowsEmptySelection = tableView.allowsEmptySelection
      tableView.allowsEmptySelection = true
      tableView.reloadData()
      tableView.allowsEmptySelection = allowsEmptySelection
    }
    
    reloadSelection()
    setDetailViewController()
    self.observeNotifications = storedObserveNotifications
  }
  
  private func primarySelectedRow(movie: Movie, tableView: NSTableView) -> Int?
  {
    let selectedRowIndexes = tableView.selectedRowIndexes
    
    if let selectedFrame = movie.selectedFrame,
       let row = movie.frames.firstIndex(of: selectedFrame),
       selectedRowIndexes.contains(row)
    {
      return row
    }
    
    let anchorRow = tableView.selectedRow
    if anchorRow >= 0, selectedRowIndexes.contains(anchorRow)
    {
      return anchorRow
    }
    
    return selectedRowIndexes.first
  }
  
  private func ensureFrameSelectionConsistency(movie: Movie, tableView: NSTableView)
  {
    let selectedRowIndexes = tableView.selectedRowIndexes
    
    movie.selectedFrames = Set(selectedRowIndexes.compactMap { row -> iRASPAObject? in
      guard row >= 0, row < movie.frames.count else { return nil }
      return movie.frames[row]
    })
    
    if let selectedFrame = movie.selectedFrame,
       let row = movie.frames.firstIndex(of: selectedFrame),
       selectedRowIndexes.contains(row)
    {
      return
    }
    
    let anchorRow = tableView.selectedRow
    if anchorRow >= 0, selectedRowIndexes.contains(anchorRow)
    {
      movie.selectedFrame = movie.frames[anchorRow]
    }
    else if let row = selectedRowIndexes.first, row < movie.frames.count
    {
      movie.selectedFrame = movie.frames[row]
    }
    else if let frame = movie.frames.first
    {
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
    }
  }
  
  private func ensureFrameListSelection(movie: Movie)
  {
    if movie.selectedFrame == nil, let frame = movie.frames.first
    {
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
    }
    else if let selectedFrame = movie.selectedFrame
    {
      movie.selectedFrames.insert(selectedFrame)
    }
  }
  
  private func restoreFrameTableSelection(movie: Movie, tableView: NSTableView)
  {
    var indexSet = IndexSet()
    for frame in movie.selectedFrames
    {
      if let row = movie.frames.firstIndex(of: frame)
      {
        indexSet.insert(row)
      }
    }
    
    if indexSet.isEmpty, let selectedFrame = movie.selectedFrame,
       let row = movie.frames.firstIndex(of: selectedFrame)
    {
      indexSet.insert(row)
    }
    
    tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
    
    if let selectedFrame = movie.selectedFrame,
       let row = movie.frames.firstIndex(of: selectedFrame)
    {
      tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: true)
    }
  }
  
  private func syncFrameListCellBackgroundStyles()
  {
    self.framesTableView?.enumerateAvailableRowViews({ (rowView, row) in
      (rowView as? SourceListStyledTableRowView)?.refreshCellBackgroundStyles()
    })
    
    DispatchQueue.main.async { [weak self] in
      self?.framesTableView?.enumerateAvailableRowViews({ (rowView, row) in
        (rowView as? SourceListStyledTableRowView)?.refreshCellBackgroundStyles()
      })
    }
  }
  
  private func syncFrameRowViewHighlight(_ rowView: FrameTableRowView, row: Int, movie: Movie, tableView: NSTableView)
  {
    guard row >= 0, row < movie.frames.count else
    {
      rowView.isSelected = false
      rowView.secondaryHighlighted = false
      rowView.needsDisplay = true
      return
    }
    
    let frame = movie.frames[row]
    let isInTableSelection = tableView.selectedRowIndexes.contains(row)
    let isInModelSelection = movie.selectedFrames.contains(frame)
    
    rowView.isSelected = isInTableSelection || isInModelSelection
    rowView.secondaryHighlighted = (row == primarySelectedRow(movie: movie, tableView: tableView))
    rowView.needsDisplay = true
  }
  
  private func syncFrameRowViewHighlights()
  {
    guard let tableView = self.framesTableView,
          let movie = self.proxyProject?.representedObject.loadedProjectStructureNode?.sceneList.selectedScene?.selectedMovie else { return }
    
    tableView.enumerateAvailableRowViews({ (rowView, row) in
      if let rowView = rowView as? FrameTableRowView
      {
        self.syncFrameRowViewHighlight(rowView, row: row, movie: movie, tableView: tableView)
      }
    })
  }
  
  // MARK: adding/removing 
  // =====================================================================
  
  func removeFrame(_ frame: iRASPAObject, atIndex index: Int)
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
  
  func addFrame(_ frame: iRASPAObject, atIndex index: Int)
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
       let view: FrameTableCellView = self.framesTableView?.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "frameName"), owner: self) as? FrameTableCellView,
       row < movie.frames.count
    {
      let frame = movie.frames[row]
      view.textField?.stringValue = frame.object.displayName
      (view.textField as? TableListNameTextField)?.endRenaming()
      (view.imageView as? TableImageViewIcon)?.image = frame.infoPanelIcon
      
      let isSelectedInTable = tableView.selectedRowIndexes.contains(row)
      let isSelectedInModel = movie.selectedFrames.contains(frame)
      if isSelectedInTable || isSelectedInModel
      {
        view.backgroundStyle = .emphasized
      }
      view.syncSelectionAppearance(for: view.backgroundStyle)
      
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
      if let selectedMovie: Movie = self.proxyProject?.representedObject.loadedProjectStructureNode?.sceneList.selectedScene?.selectedMovie
      {
        syncFrameRowViewHighlight(rowView, row: row, movie: selectedMovie, tableView: tableView)
      }
      else
      {
        rowView.isSelected = false
        rowView.secondaryHighlighted = false
        rowView.needsDisplay = true
      }
      return rowView
    }
    return nil
  }
  
  func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int)
  {
    if let rowView = rowView as? FrameTableRowView,
       let selectedMovie: Movie = self.proxyProject?.representedObject.loadedProjectStructureNode?.sceneList.selectedScene?.selectedMovie
    {
      syncFrameRowViewHighlight(rowView, row: row, movie: selectedMovie, tableView: tableView)
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
         let textField = view.textField as? TableListNameTextField
      {
        textField.beginRenaming()
        view.window?.makeFirstResponder(textField)
      }
    }
  }
  
  func setFrameDisplayName(_ frame: iRASPAObject, to newValue: String)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let oldName: String = frame.object.displayName
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setFrameDisplayName(frame, to: oldName)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change frame name", comment: "Change frame name"))
      }
      
      frame.object.displayName = newValue
      
      // reload item in the outlineView
      if let row: Int = selectedMovie.frames.firstIndex(of: frame)
      {
        self.framesTableView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        self.syncFrameListCellBackgroundStyles()
      }
      
      project.isEdited = true
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeFrameDisplayName(_ sender: NSTextField)
  {
    defer { (sender as? TableListNameTextField)?.endRenaming() }
    
    if let row: Int = self.framesTableView?.row(for: sender), row >= 0,
       let proxyProject = self.proxyProject, proxyProject.isEditable,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let newValue: String = sender.stringValue
      
      let frame = selectedMovie.frames[row]
      if frame.object.displayName != newValue
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
  
  func insertSelectedFrames(_ frames: [iRASPAObject], at indexSet: IndexSet,  newSelectedFrame: iRASPAObject?, newSelection: Set<iRASPAObject>)
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let currentSelectedFrame: iRASPAObject? = selectedMovie.selectedFrame
      let currentSelection: Set<iRASPAObject> = selectedMovie.selectedFrames
      
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
  
  func deleteSelectedFrames(_ frames: [iRASPAObject], from indexSet: IndexSet, newSelectedFrame: iRASPAObject?, newSelection: Set<iRASPAObject>)
  {
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedScene: Scene = project.sceneList.selectedScene,
       let selectedMovie: Movie = selectedScene.selectedMovie
    {
      let currentSelectedFrame: iRASPAObject? = selectedMovie.selectedFrame
      let currentSelection: Set<iRASPAObject> = selectedMovie.selectedFrames
      
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
      let selectedFrames: [iRASPAObject] = indexSet.map{selectedMovie.frames[$0]}
      
      var newSelectedFrame: iRASPAObject? = nil
      var newSelection: Set<iRASPAObject> = []
      
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
      let frames: [iRASPAObject] = selectionMovie.allIRASPObjects
      let arrangedObjects: [Any] = frames.isEmpty ? [[]] : frames
      
      if let selectedFrame: iRASPAObject = selectionMovie.selectedFrame,
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
       let selectedFrame: iRASPAObject = selectedMovie.selectedFrame,
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
    
    if let proxyProject = self.proxyProject,
       let project = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedMovie: Movie = project.sceneList.selectedScene?.selectedMovie,
       let tableView = self.framesTableView
    {
      ensureFrameListSelection(movie: selectedMovie)
      restoreFrameTableSelection(movie: selectedMovie, tableView: tableView)
      ensureFrameSelectionConsistency(movie: selectedMovie, tableView: tableView)
      
      if let selectedFrame = selectedMovie.selectedFrame
      {
        self.windowController?.infoPanel?.showInfoItem(item: MaterialsInfoPanelItemView(image: selectedFrame.infoPanelIcon, message: selectedFrame.infoPanelString))
      }
      
      syncFrameRowViewHighlights()
      syncFrameListCellBackgroundStyles()
    }
    
    self.observeNotifications = storedObserveNotifications
  }
  
  func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    if let projectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
    {
      if proposedSelectionIndexes.isEmpty && !movie.frames.isEmpty
      {
        return tableView.selectedRowIndexes
      }
      
      if self.observeNotifications
      {
        movie.selectedFrames = []
        
        for row in proposedSelectionIndexes
        {
          if row >= 0, row < movie.frames.count
          {
            movie.selectedFrames.insert(movie.frames[row])
          }
        }
        
        let oldSelectedRow = movie.selectedFrame.flatMap { movie.frames.firstIndex(of: $0) } ?? -1
        if proposedSelectionIndexes.count == 1 || (oldSelectedRow >= 0 && !proposedSelectionIndexes.contains(oldSelectedRow))
        {
          let row = proposedSelectionIndexes.count == 1 ? proposedSelectionIndexes.first! : tableView.selectedRow
          if row >= 0, row < movie.frames.count, proposedSelectionIndexes.contains(row)
          {
            movie.selectedFrame = movie.frames[row]
            movie.selectedFrames.insert(movie.frames[row])
          }
        }
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
         let selectedMovie: Movie = project.sceneList.selectedScene?.selectedMovie,
         let tableView = self.framesTableView
      {
        if tableView.selectedRow < 0 || tableView.selectedRowIndexes.isEmpty,
           !selectedMovie.frames.isEmpty
        {
          ensureFrameListSelection(movie: selectedMovie)
          reloadSelection()
          return
        }
        
        let oldSelectedRow: Int = selectedMovie.selectedFrame != nil ? selectedMovie.frames.firstIndex(of: selectedMovie.selectedFrame!) ?? -1 : -1
        let selectedRow = tableView.selectedRow
        let selectedRows = tableView.selectedRowIndexes
        if selectedRow >= 0
        {
          if ((selectedRows.count == 1) || (!selectedRows.contains(oldSelectedRow)))
          {
            selectedMovie.selectedFrame = selectedMovie.frames[selectedRow]
            selectedMovie.selectedFrames.insert(selectedMovie.frames[selectedRow])
            
            self.windowController?.infoPanel?.showInfoItem(item: MaterialsInfoPanelItemView(image: selectedMovie.selectedFrame?.infoPanelIcon, message: selectedMovie.selectedFrame?.infoPanelString))
          
            project.sceneList.synchronizeAllMovieFrames(to: selectedRow)
          }
          else
          {
            tableView.selectRowIndexes(IndexSet(integer: oldSelectedRow), byExtendingSelection: true)
          }
          
          ensureFrameSelectionConsistency(movie: selectedMovie, tableView: tableView)
          syncFrameRowViewHighlights()
          syncFrameListCellBackgroundStyles()
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
      if let selectedFrame: iRASPAObject = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let crystal = Crystal(name: "New crystal")
      crystal.reComputeBoundingBox()
      let frame: iRASPAObject = iRASPAObject(crystal: crystal)
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
      if let selectedFrame: iRASPAObject = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let molecularCrystal = MolecularCrystal(name: "New molecular crystal")
      molecularCrystal.reComputeBoundingBox()
      let frame: iRASPAObject = iRASPAObject(molecularCrystal: molecularCrystal)
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
      if let selectedFrame: iRASPAObject = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let molecule = Molecule(name: "New molecule")
      molecule.reComputeBoundingBox()
      let frame: iRASPAObject = iRASPAObject(molecule: molecule)
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
      if let selectedFrame: iRASPAObject = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let protein = Protein(name: "New protein")
      protein.reComputeBoundingBox()
      let frame: iRASPAObject = iRASPAObject(protein: protein)
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
      if let selectedFrame: iRASPAObject = movie.selectedFrame,
        let index = movie.frames.firstIndex(of: selectedFrame)
      {
        insertionIndex = index + 1
      }
      
      self.framesTableView?.beginUpdates()
      let proteinCrystal = ProteinCrystal(name: "New protein crystal")
      proteinCrystal.reComputeBoundingBox()
      let frame: iRASPAObject = iRASPAObject(proteinCrystal: proteinCrystal)
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
      self.draggedNodes = (movie.frames as NSArray).objects(at: rowIndexes).compactMap{$0 as? iRASPAObject}
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
      for frame: iRASPAObject in self.draggedNodes
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
    info.enumerateDraggingItems(options: .concurrent, for: self.framesTableView, classes: [iRASPAObject.self], searchOptions: [:], using: { (draggingItem , idx, stop)  in
      if let frame  = draggingItem.item as? iRASPAObject
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
      
      let renderStructures: [RKRenderObject] = project.renderStructures
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
        let displayName: String = node.object.displayName
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let url: URL = dropDestination.appendingPathComponent(displayName).appendingPathExtension(pathExtension)
        do
        {
          try compressedData.write(to: url, options: Data.WritingOptions.atomic)
        }
        catch
        {
          
        }
      }
    }
    return self.draggedNodes.map{$0.object.displayName}
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
      
      if let selectedFrames: [iRASPAObject] = parentProject.sceneList.selectedScene?.selectedMovies.flatMap({$0.selectedFrames})
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
    if let pasteboardItems: [Any]  = pasteboard.readObjects(forClasses: [iRASPAObject.self], options: nil)
    {
      self.framesTableView?.beginUpdates()
      for pasteboardItem in pasteboardItems
      {
        if let frame  = pasteboardItem as? iRASPAObject
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
      
        let renderStructures: [RKRenderObject] = project.renderStructures
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
