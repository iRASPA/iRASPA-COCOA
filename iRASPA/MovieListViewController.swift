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
import iRASPAKit
import OperationKit
import SymmetryKit
import LogViewKit


/// StructureListViewController controls a tableView with scenes.
///
/// Note: representedObject is a SceneList
class MovieListViewController: NSViewController, NSMenuItemValidation, NSOutlineViewDataSource, NSOutlineViewDelegate, WindowControllerConsumer, ProjectConsumer, Reloadable, SelectionIndex
{
  @IBOutlet private weak var movieOutlineView: MovieListOutlineView?
  
  weak var windowController: iRASPAWindowController?
  
  var observeNotifications: Bool = true
  var filterContent: Bool = false
  
  private var draggedNodes: [Movie] = []
  
  @IBOutlet private var addContextMenu: NSMenu?
  
  let movieSingleFrameIcon: NSImage = NSImage(named: "MovieSingleFrameIcon")!
  let movieMultipleFramesIcon: NSImage = NSImage(named: "MovieMultipleFramesIcon")!
  let unknownIcon: NSImage = NSImage(named: "UnknownIcon")!
  
  lazy var structureQueue: FKOperationQueue = {
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

  // register before 'viewDidLoad' to allow setting of the project before the viewcontroller is fully initialized with a view
  // called when present in a storyboard
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)

  }
  
  deinit
  {
    //Swift.print("deinit: StructureListViewController")
  }
  
  
  // MARK: NSViewController lifecycle
  // =====================================================================
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    self.movieOutlineView?.stronglyReferencesItems = false
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    self.movieOutlineView?.registerForDraggedTypes([NSPasteboardTypeProjectTreeNode,
                                                         NSPasteboardTypeMovie,
                                                         NSPasteboardTypeFrame])
    self.movieOutlineView?.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    self.movieOutlineView?.registerForDraggedTypes([NSPasteboard.PasteboardType.filePromise])
    
    self.movieOutlineView?.setDraggingSourceOperationMask(.every, forLocal: true)
    self.movieOutlineView?.setDraggingSourceOperationMask(.every, forLocal: false)
  }
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    
    self.movieOutlineView?.doubleAction = #selector(MovieListViewController.movieSceneListViewDoubleClick)
    
  }
  
  
  override func viewWillAppear()
  {
    super.viewWillAppear()
    
    self.movieOutlineView?.reloadItem(nil)
    NSAnimationContext.beginGrouping()
    NSAnimationContext.current.duration=0
    self.movieOutlineView?.expandItem(nil, expandChildren: true)
    NSAnimationContext.endGrouping()
    
    self.reloadData()
    
    self.setDetailViewController()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    // for a NSOutlineView in SourceList-style, a reloadData must be done when on-screen
    // resulting artificts from not doing this: lost selection when resigning first-responder (e.g. import file)
    self.reloadData()
    
  }
  
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
  }
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?

  // MARK: Reloading data
  // =====================================================================
  
  
  
  // reload the structureViewOutlineView and the selection
  func reloadData()
  {
    self.observeNotifications = false
    if let _: ProjectTreeNode = self.proxyProject
    {
      self.movieOutlineView?.reloadItem(nil)
      NSAnimationContext.beginGrouping()
      NSAnimationContext.current.duration=0
      self.movieOutlineView?.expandItem(nil, expandChildren: true)
      NSAnimationContext.endGrouping()
      
      self.movieOutlineView?.reloadData()
      self.reloadSelection()
    }
    self.observeNotifications = true
    
    setDetailViewController()
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
  
  
  func insertSelectedMovies(_ movies: [Movie], at indexPaths: [IndexPath], newSelectedScene: Scene?, newSelectedMovie: Movie?, newSelection: [Scene: Set<Movie>])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let currentSelectedScene: Scene? = project.sceneList.selectedScene
      let currentSelectedMovie: Movie? = project.sceneList.selectedScene?.selectedMovie
      let currentSelection: [Scene: Set<Movie>] = project.sceneList.selectedMovies
      
      self.movieOutlineView?.beginUpdates()
      for index in 0..<movies.count
      {
        let sceneIndex: Int = indexPaths[index][0]
        let movieIndex: Int = indexPaths[index][1]
        let scene: Scene = project.sceneList.scenes[sceneIndex]
        scene.movies.insert(movies[index], at: movieIndex)
        scene.selectedMovies.insert(movies[index])
        self.movieOutlineView?.insertItems(at: IndexSet(integer: movieIndex), inParent: scene, withAnimation: .slideRight)
      }
      self.movieOutlineView?.endUpdates()
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.deleteSelectedMovies(movies.reversed(), from: indexPaths.reversed(), newSelectedScene: currentSelectedScene, newSelectedMovie: currentSelectedMovie, newSelection: currentSelection)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Insert Selection", comment: ""))
      }
      
      project.sceneList.selectedScene = newSelectedScene
      newSelectedScene?.selectedMovie = newSelectedMovie
      project.sceneList.selectedMovies = newSelection
      
      self.reloadSelection()
      
      self.setDetailViewController()
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func deleteSelectedMovies(_ movies: [Movie], from indexPaths: [IndexPath], newSelectedScene: Scene?, newSelectedMovie: Movie?, newSelection: [Scene: Set<Movie>])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let currentSelectedScene: Scene? = project.sceneList.selectedScene
      let currentSelectedMovie: Movie? = project.sceneList.selectedScene?.selectedMovie
      let currentSelection: [Scene: Set<Movie>] = project.sceneList.selectedMovies
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.insertSelectedMovies(movies.reversed(), at: indexPaths.reversed(), newSelectedScene: currentSelectedScene, newSelectedMovie: currentSelectedMovie, newSelection: currentSelection)})
      
      self.movieOutlineView?.beginUpdates()
      for index in 0..<movies.count
      {
        let sceneIndex: Int = indexPaths[index][0]
        let movieIndex: Int = indexPaths[index][1]
        let scene: Scene = project.sceneList.scenes[sceneIndex]
        scene.movies.remove(at: movieIndex)
        self.movieOutlineView?.removeItems(at: IndexSet(integer: movieIndex), inParent: scene, withAnimation: .slideLeft)
        
        scene.selectedMovies.remove(movies[index])
        if scene.selectedMovie === movies[index]
        {
          scene.selectedMovie = nil
        }
      }
      
      // also remove scene if the removal of the node would make it empty
      for scene in project.sceneList.scenes
      {
        if let index: Int = project.sceneList.scenes.firstIndex(of: scene)
        {
          if scene.movies.isEmpty
          {
            // Put the undo for the removal on the stack. The redo is 'moveMovieNode' itself
            project.undoManager.registerUndo(withTarget: self, handler: {target in
              
              project.sceneList.scenes.insert(scene, at: index)
              target.movieOutlineView?.insertItems(at: IndexSet(integer: index), inParent: nil, withAnimation: .slideRight)
              target.movieOutlineView?.expandItem(nil, expandChildren: true)
            })
            
            project.sceneList.scenes.remove(at: index)
            self.movieOutlineView?.removeItems(at: IndexSet(integer: index), inParent: nil, withAnimation: .slideLeft)
          }
        }
      }
      self.movieOutlineView?.endUpdates()

      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Delete Selection", comment: ""))
      }
    
      project.sceneList.selectedScene = newSelectedScene
      newSelectedScene?.selectedMovie = newSelectedMovie
      project.sceneList.selectedMovies = newSelection
      
      if let currentSelectedScene = currentSelectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: currentSelectedScene.allRenderFrames)
      }
      if let newSelectedScene = newSelectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: newSelectedScene.allRenderFrames)
      }
      
      self.reloadSelection()

      self.setDetailViewController()
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func deleteSelection()
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      if let indexes: IndexSet = self.movieOutlineView?.selectedRowIndexes
      {
        var movies: [Movie] = []
        var indexPaths: [IndexPath] = []
        if (indexes.count > 0)
        {
          // enumerate reverse; start with last index (because then all other indices are still valid after remove)
          (indexes as NSIndexSet).enumerate(options: .reverse, using: {(index, stop) -> Void in
            if let node: Movie = self.movieOutlineView?.item(atRow: index) as? Movie,
              let indexPath: IndexPath = project.sceneList.indexPath(node)
            {
              movies.append(node)
              indexPaths.append(indexPath)
            }
          })
        }
        
        let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
        let notSelectedIndices: IndexSet = IndexSet(integersIn: 0..<numberOfRows).symmetricDifference(indexes)
        let notselectedMovies: [Movie] = notSelectedIndices.compactMap{self.movieOutlineView?.item(atRow: $0) as? Movie}
        
        var newSelectedScene: Scene? = nil
        var newSelectedMovie: Movie? = nil
        var newSelection: [Scene: Set<Movie>] = [:]
        if let movie: Movie = notselectedMovies.first,
           let indexPath: IndexPath = project.sceneList.indexPath(movie),
           let sceneIndex: Int = indexPath.first
        {
          let scene: Scene = project.sceneList.scenes[sceneIndex]
          newSelectedScene = scene
          newSelectedMovie = movie
          newSelection = [scene: [movie]]
        }
        
        self.deleteSelectedMovies(movies, from: indexPaths, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
      }
    }
  }
  
  // Used only by 'addMovieNode' (so will never change the selection).
  func removeMovieNode(_ node: AnyObject, fromItem: AnyObject?, atIndex childIndex: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.addMovieNode(node, inItem: fromItem, atIndex: childIndex)})
    
      (fromItem as! Scene).movies.remove(at: childIndex)
      self.movieOutlineView?.removeItems(at: IndexSet(integer: childIndex), inParent: fromItem, withAnimation: .slideLeft)
    }
  }
  
  
  // Used by 'paste' and 'drop'
  func addMovieNode(_ node: AnyObject, inItem: AnyObject?, atIndex childIndex: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let movie: Movie = node as? Movie
    {
      // make sure the movie has a selected-frame
      // (otherwise it does not show up in the RenderView)
      if movie.selectedFrame == nil
      {
        if let selectedFrame = movie.frames.first
        {
          movie.selectedFrame = selectedFrame
          movie.selectedFrames.insert(selectedFrame)
        }
      }
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.removeMovieNode(node, fromItem: inItem, atIndex: childIndex)})
      
      // insert new node
      (inItem as? Scene)?.movies.insert(movie, at: childIndex)
      self.movieOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: inItem, withAnimation: .slideRight)
    }
  }

  func removeMovieNode(_ movie: Movie, fromItem: Scene?, atIndex childIndex: Int, newSelectedScene: Scene?, newSelectedMovie: Movie?, newSelection: [Scene: Set<Movie>])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let currentSelectedScene: Scene? = project.sceneList.selectedScene
      let currentSelectedMovie: Movie? = project.sceneList.selectedScene?.selectedMovie
      let currentSelection: [Scene: Set<Movie>] = project.sceneList.selectedMovies
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.addMovieNode(movie, inItem: fromItem, atIndex: childIndex, newSelectedScene: currentSelectedScene, newSelectedMovie: currentSelectedMovie, newSelection: currentSelection)})
      
      fromItem?.movies.remove(at: childIndex)
      self.movieOutlineView?.removeItems(at: IndexSet(integer: childIndex), inParent: fromItem, withAnimation: .slideLeft)
      
      project.sceneList.selectedScene = newSelectedScene
      newSelectedScene?.selectedMovie = newSelectedMovie
      project.sceneList.selectedMovies = newSelection
      self.reloadSelection()
      
      self.setDetailViewController()
      
      if let currentSelectedScene = currentSelectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: currentSelectedScene.allRenderFrames)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
    }
  }
  
  func addMovieNode(_ movie: Movie, inItem: Scene?, atIndex childIndex: Int, newSelectedScene: Scene?, newSelectedMovie: Movie?, newSelection: [Scene: Set<Movie>])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let currentSelectedScene: Scene? = project.sceneList.selectedScene
      let currentSelectedMovie: Movie? = project.sceneList.selectedScene?.selectedMovie
      let currentSelection: [Scene: Set<Movie>] = project.sceneList.selectedMovies
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.removeMovieNode(movie, fromItem: inItem, atIndex: childIndex, newSelectedScene: currentSelectedScene, newSelectedMovie: currentSelectedMovie, newSelection: currentSelection)})
     
      if(!project.undoManager.isUndoing)
      {
        project.undoManager.setActionName(NSLocalizedString("Add Movies", comment: ""))
      }
      
      // make sure the movie has a selected-frame
      // (otherwise it does not show up in the RenderView)
      if movie.selectedFrame == nil
      {
        if let selectedFrame = movie.frames.first
        {
          movie.selectedFrame = selectedFrame
          movie.selectedFrames.insert(selectedFrame)
        }
      }
      
      
      // insert new node
      inItem?.movies.insert(movie, at: childIndex)
      self.movieOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: inItem, withAnimation: .slideRight)

      project.sceneList.selectedScene = newSelectedScene
      newSelectedScene?.selectedMovie = newSelectedMovie
      project.sceneList.selectedMovies = newSelection
      self.reloadSelection()
      
      self.setDetailViewController()
      
      if let currentSelectedScene = currentSelectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: currentSelectedScene.allRenderFrames)
      }
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  

  func removeSceneNode(_ scene: Scene, atIndex childIndex: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.addSceneNode(scene, atIndex: childIndex)})
      
      project.sceneList.scenes.remove(at: childIndex)
      self.movieOutlineView?.removeItems(at: IndexSet(integer: childIndex), inParent: nil, withAnimation: .slideLeft)
      
      
    }
  }
  
  func addSceneNode(_ scene: Scene, atIndex childIndex: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.removeSceneNode(scene, atIndex: childIndex)})

      if(!project.undoManager.isUndoing)
      {
        project.undoManager.setActionName(NSLocalizedString("Add Scenes", comment: ""))
      }
      
      // insert new node
      self.movieOutlineView?.beginUpdates()
      project.sceneList.scenes.insert(scene, at: childIndex)
      self.movieOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: nil, withAnimation: .slideRight)
      self.movieOutlineView?.expandItem(nil, expandChildren: true)
      self.movieOutlineView?.endUpdates()
      
      if let currentSelectedScene = project.sceneList.selectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: currentSelectedScene.allRenderFrames)
      }
    }
  }

  @IBAction func addCrystal(_ sender: AnyObject)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
    
      let scene: Scene = Scene()
      scene.displayName = "New scene"
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
           let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
           let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
        }
      }
      
      let crystal: Crystal = Crystal(name: "frame")
      crystal.reComputeBoundingBox()
      let frame = iRASPAStructure(crystal: crystal)
      let movie: Movie = Movie(name: "New movie", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }

  @IBAction func addMolecularCrystal(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New scene"
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
        }
      }
      
      let molecularCrystal: MolecularCrystal = MolecularCrystal(name: "frame")
      molecularCrystal.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(molecularCrystal: molecularCrystal)
      let movie: Movie = Movie(name: "New movie", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }

  @IBAction func addMolecule(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New scene"
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
        }
      }
      
      let molecule: Molecule = Molecule(name: "frame")
      molecule.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(molecule: molecule)
      let movie: Movie = Movie(name: "New movie", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }


  @IBAction func addProtein(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New scene"
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
        }
      }
      
      let protein: Protein = Protein(name: "frame")
      protein.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(protein: protein)
      let movie: Movie = Movie(name: "New movie", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }

  @IBAction func addProteinCrystal(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New scene"
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
        }
      }
      
      let proteinCrystal: ProteinCrystal = ProteinCrystal(name: "frame")
      proteinCrystal.reComputeBoundingBox()
      let frame: iRASPAStructure = iRASPAStructure(proteinCrystal: proteinCrystal)
      let movie: Movie = Movie(name: "New movie", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }
  
  @IBAction func addCrystalEllipsoidPrimitive(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New crystal ellipsoid"
      let ellipsoidPrimitive: CrystalEllipsoidPrimitive = CrystalEllipsoidPrimitive(name: "Ellipsoid")
      ellipsoidPrimitive.cell = SKCell()
      
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
          if let previousCell = movie.frames.first?.structure.cell
          {
            ellipsoidPrimitive.cell = previousCell
          }
        }
      }
      
      
      let frame: iRASPAStructure = iRASPAStructure(crystalEllipsoidPrimitive: ellipsoidPrimitive)
      let movie: Movie = Movie(name: "New crystal ellipsoid", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }
  
  @IBAction func addCrystalPolygonalPrismPrimitive(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New crystal polygonal prism"
      let polygonalPrimitive: CrystalPolygonalPrismPrimitive = CrystalPolygonalPrismPrimitive(name: "Polygonal prism")
      polygonalPrimitive.primitiveNumberOfSides = 4
      polygonalPrimitive.cell = SKCell()
      
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
          if let previousCell = movie.frames.first?.structure.cell
          {
            polygonalPrimitive.cell = previousCell
          }
        }
      }
      
      let frame: iRASPAStructure = iRASPAStructure(crystalPolygonalPrismPrimitive: polygonalPrimitive)
      let movie: Movie = Movie(name: "New crystal polygonal prism", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }

  @IBAction func addCrystalCylinderPrimitive(_ sender: NSMenuItem)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let selectedRow=self.movieOutlineView?.selectedRow
    {
      var index: Int = selectedRow
      var toItem: Scene? = nil
      
      let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
      
      let scene: Scene = Scene()
      scene.displayName = "New crystal cylinder"
      let cylinderPrimitive: CrystalCylinderPrimitive = CrystalCylinderPrimitive(name: "Cylinder")
      cylinderPrimitive.primitiveNumberOfSides = 41
      cylinderPrimitive.cell = SKCell()
      
      if index < 0
      {
        index=0
        self.addSceneNode(scene, atIndex: 0)
        toItem=scene
      }
      else
      {
        if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
          let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
          let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          toItem = scene
          index = childIndex + 1
          if let previousCell = movie.frames.first?.structure.cell
          {
            cylinderPrimitive.cell = previousCell
          }
        }
      }
      
      
      let frame: iRASPAStructure = iRASPAStructure(crystalCylinderPrimitive: cylinderPrimitive)
      let movie: Movie = Movie(name: "New crystal cylinder", structure: frame)
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let newSelectedScene: Scene?
      let newSelectedMovie: Movie?
      let newSelection: [Scene: Set<Movie>]
      if numberOfRows <= 0
      {
        newSelectedScene = scene
        newSelectedMovie = movie
        newSelection = [scene: [movie]]
      }
      else
      {
        newSelectedScene = project.sceneList.selectedScene
        newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
        newSelection = project.sceneList.selectedMovies
      }
      
      self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
    }
  }
  
  
  @IBAction func addEllipsoidPrimitive(_ sender: NSMenuItem)
   {
     if let proxyProject = self.proxyProject, proxyProject.isEditable,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedRow=self.movieOutlineView?.selectedRow
     {
       var index: Int = selectedRow
       var toItem: Scene? = nil
       
       let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
       
       let scene: Scene = Scene()
       scene.displayName = "New ellipsoid"
       let ellipsoidPrimitive: EllipsoidPrimitive = EllipsoidPrimitive(name: "Ellipsoid")
       
       if index < 0
       {
         index=0
         self.addSceneNode(scene, atIndex: 0)
         toItem=scene
       }
       else
       {
         if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
           let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
           let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
         {
           toItem = scene
           index = childIndex + 1
           if let previousCell = movie.frames.first?.structure.cell
           {
             ellipsoidPrimitive.cell = previousCell
           }
         }
       }
       
       
       let frame: iRASPAStructure = iRASPAStructure(ellipsoidPrimitive: ellipsoidPrimitive)
       let movie: Movie = Movie(name: "New Ellipsoid", structure: frame)
       movie.selectedFrame = frame
       movie.selectedFrames.insert(frame)
       
       let newSelectedScene: Scene?
       let newSelectedMovie: Movie?
       let newSelection: [Scene: Set<Movie>]
       if numberOfRows <= 0
       {
         newSelectedScene = scene
         newSelectedMovie = movie
         newSelection = [scene: [movie]]
       }
       else
       {
         newSelectedScene = project.sceneList.selectedScene
         newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
         newSelection = project.sceneList.selectedMovies
       }
       
       self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
     }
   }
   
   @IBAction func addPolygonalPrismPrimitive(_ sender: NSMenuItem)
   {
     if let proxyProject = self.proxyProject, proxyProject.isEditable,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedRow=self.movieOutlineView?.selectedRow
     {
       var index: Int = selectedRow
       var toItem: Scene? = nil
       
       let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
       
       let scene: Scene = Scene()
       scene.displayName = "New polygonal prism"
       let polygonalPrimitive: PolygonalPrismPrimitive = PolygonalPrismPrimitive(name: "Polygonal prism")
       polygonalPrimitive.primitiveNumberOfSides = 4
       
       if index < 0
       {
         index=0
         self.addSceneNode(scene, atIndex: 0)
         toItem=scene
       }
       else
       {
         if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
           let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
           let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
         {
           toItem = scene
           index = childIndex + 1
           if let previousCell = movie.frames.first?.structure.cell
           {
             polygonalPrimitive.cell = previousCell
           }
         }
       }
       
       let frame: iRASPAStructure = iRASPAStructure(polygonalPrismPrimitive: polygonalPrimitive)
       let movie: Movie = Movie(name: "New polygonal prism", structure: frame)
       movie.selectedFrame = frame
       movie.selectedFrames.insert(frame)
       
       let newSelectedScene: Scene?
       let newSelectedMovie: Movie?
       let newSelection: [Scene: Set<Movie>]
       if numberOfRows <= 0
       {
         newSelectedScene = scene
         newSelectedMovie = movie
         newSelection = [scene: [movie]]
       }
       else
       {
         newSelectedScene = project.sceneList.selectedScene
         newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
         newSelection = project.sceneList.selectedMovies
       }
       
       self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
     }
   }

   @IBAction func addCylinderPrimitive(_ sender: NSMenuItem)
   {
     if let proxyProject = self.proxyProject, proxyProject.isEditable,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let selectedRow=self.movieOutlineView?.selectedRow
     {
       var index: Int = selectedRow
       var toItem: Scene? = nil
       
       let numberOfRows: Int = self.movieOutlineView?.numberOfRows ?? 0
       
       let scene: Scene = Scene()
       scene.displayName = "New cylinder"
       let cylinderPrimitive: CylinderPrimitive = CylinderPrimitive(name: "Cylinder")
       cylinderPrimitive.primitiveNumberOfSides = 41
       
       if index < 0
       {
         index=0
         self.addSceneNode(scene, atIndex: 0)
         toItem=scene
       }
       else
       {
         if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
           let scene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
           let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
         {
           toItem = scene
           index = childIndex + 1
           if let previousCell = movie.frames.first?.structure.cell
           {
             cylinderPrimitive.cell = previousCell
           }
         }
       }
       
       
       let frame: iRASPAStructure = iRASPAStructure(cylinderPrimitive: cylinderPrimitive)
       let movie: Movie = Movie(name: "New cylinder", structure: frame)
       movie.selectedFrame = frame
       movie.selectedFrames.insert(frame)
       
       let newSelectedScene: Scene?
       let newSelectedMovie: Movie?
       let newSelection: [Scene: Set<Movie>]
       if numberOfRows <= 0
       {
         newSelectedScene = scene
         newSelectedMovie = movie
         newSelection = [scene: [movie]]
       }
       else
       {
         newSelectedScene = project.sceneList.selectedScene
         newSelectedMovie = project.sceneList.selectedScene?.selectedMovie
         newSelection = project.sceneList.selectedMovies
       }
       
       self.addMovieNode(movie, inItem: toItem, atIndex: index, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
     }
   }
   
  
  
  // MARK: NSOutlineView required datasource methods
  // =====================================================================
  
  
  // Returns the number of child items encompassed by a given item
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      if (item == nil)
      {
        return project.sceneList.scenes.count
      }
      else
      {
        
        if let scene = item as? Scene
        {
          return scene.movies.count
        }
      }
    }
    return 0
  }
  
  
  
  // Returns the child item at the specified index of a given item
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      // return root-items
      if (item == nil),
         index < project.sceneList.scenes.count
      {
        return project.sceneList.scenes[index]
      }
      else
      {
        if let scene = item as? Scene,
           index < scene.movies.count
        {
          return scene.movies[index]
        }
      }
    }
    return 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat
  {
    if item is Scene
    {
      return 22.0
    }
    return 18.0
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
  {
    // the top-level items are of type Dictionary<String, String>
    return item is Scene
  }
  
  
  
  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool
  {
    return false
  }
  
  
  // Returns a Boolean value that indicates whether the a given item is expandable
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
  {
    return item is Scene
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if tableColumn == nil
    {
      if let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sceneView"), owner: self) as? NSTableCellView
      {
        view.textField!.stringValue = (item as? Scene)?.displayName.uppercased() ?? "unknown"
        view.imageView?.isHidden = true
        return view
      }
    }
    else
    {
      switch(tableColumn!.identifier)
      {
      case NSUserInterfaceItemIdentifier(rawValue: "movieNameColumn"):
        // only Movie (Scene are group-items and handled as nil)
        switch(item)
        {
        case is Scene:
          if let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "movieView"), owner: self) as? NSTableCellView
          {
            view.textField!.stringValue = (item as? Scene)?.displayName.uppercased() ?? ""
            return view
          }
        case let movie as Movie:
          if let view: MovieTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "movieView"), owner: self) as? MovieTableCellView
          {
            view.textField?.stringValue = movie.displayName
            view.progressIndicator?.isHidden = !movie.isLoading
            view.cancelButton?.isHidden = !movie.isLoading
          
            if let button: NSButton = view.viewWithTag(10) as? NSButton
            {
              button.state =  movie.isVisible ? NSControl.StateValue.on : NSControl.StateValue.off
            }
            
            view.imageView?.image = movie.infoPanelIcon
            
            return view
          }
        default:
          break
        }
        
        break
      default:
        break
      }
    }
    return nil
  }
  
  // MARK: Row-views
  // =====================================================================
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: StructureTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "structureTableRowView"), owner: self) as? StructureTableRowView,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      rowView.secondaryHighlighted = false
      rowView.isSelected = false
      
      rowView.isGroupRowStyle = item is Scene
      
      if let movie = item as? Movie
      {
        if movie === project.sceneList.selectedScene?.selectedMovie
        {
          rowView.secondaryHighlighted = true
          rowView.isSelected = true
        }
        
        let selectedMovies: [Movie] = project.sceneList.scenes.flatMap{$0.selectedMovies}
        if  selectedMovies.contains(movie)
        {
          rowView.isSelected = true
        }
      }
    
      return rowView
    }
    
    return nil
  }
  
  // Note: after a 'reloadData' of the table the row-views are dropped, and recreated in the next iteration of the run-loop
  // They will show up first as "rowViewForItem" and next as "didAddRowView"
  func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int)
  {
    if let rowView = rowView as? StructureTableRowView
    {
      rowView.secondaryHighlighted = false
      rowView.isSelected = false
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        let selectedMovies: [Movie] = project.sceneList.scenes.flatMap{$0.selectedMovies}
        
        if let _: Scene = self.movieOutlineView?.item(atRow: row) as? Scene
        {
          rowView.isGroupRowStyle = true
        }
        else
        {
          rowView.isGroupRowStyle = false
        }
        
        if let movie: Movie = self.movieOutlineView?.item(atRow: row) as? Movie,
           selectedMovies.contains(movie)
        {
          rowView.isSelected = true
        }
        
        if let selectedMovie: Movie = project.sceneList.selectedScene?.selectedMovie,
           let selectedRow = self.movieOutlineView?.row(forItem: selectedMovie)
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
  
  func outlineView(_ outlineView: NSOutlineView, didRemove rowView: NSTableRowView, forRow row: Int)
  {
    if (row<0)
    {
      (rowView as? StructureTableRowView)?.isSelected = false
      (rowView as? StructureTableRowView)?.secondaryHighlighted = false
    }
  }
  
  
  // MARK: NSOutlineView rename on double-click
  // =====================================================================
  
  @objc func movieSceneListViewDoubleClick(_ sender: AnyObject)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable,
       let clickedRow: Int = self.movieOutlineView?.clickedRow, clickedRow >= 0
    {
      if let view: NSTableCellView = self.movieOutlineView?.view(atColumn: 0, row: clickedRow, makeIfNecessary: true) as? NSTableCellView,
         let textField: NSTextField = view.textField,
         textField.acceptsFirstResponder
      {
        view.window?.makeFirstResponder(textField)
      }
    }
  }


  
  func setMovieDisplayName(_ movie: Movie, to newValue: String)
  {
    if let project = self.proxyProject?.representedObject
    {
      let oldName: String = movie.displayName
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setMovieDisplayName(movie, to: oldName)})
    
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Movie Name", comment: ""))
      }
    
      movie.displayName = newValue
    
      // reload item in the outlineView
      if let row: Int = self.movieOutlineView?.row(forItem: movie), row >= 0
      {
        self.movieOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
      }

      project.isEdited = true
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeMovieDisplayName(_ sender: NSTextField)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable
    {
      let newValue: String = sender.stringValue
    
      if let row: Int = self.movieOutlineView?.row(for: sender), row >= 0
      {
        if let movie: Movie = self.movieOutlineView?.item(atRow: row) as? Movie,
            movie.displayName != newValue
        {
          self.setMovieDisplayName(movie, to: newValue)
        }
      }
    }
  }
  
  
  func setSceneDisplayName(_ scene: Scene, to newValue: String)
  {
    if let project = self.proxyProject?.representedObject
    {
      let oldName: String = scene.displayName
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setSceneDisplayName(scene, to: oldName)})
    
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Scene Name", comment: ""))
      }
    
      scene.displayName = newValue
    
      // reload item in the outlineView
      self.reloadData()
    
      project.isEdited = true
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeSceneDisplayName(_ sender: NSTextField)
  {
    if let proxyProject = self.proxyProject, proxyProject.isEditable
    {
      let newValue: String = sender.stringValue
    
      if let row: Int = self.movieOutlineView?.row(for: sender), row >= 0
      {
        if let scene: Scene = self.movieOutlineView?.item(atRow: row) as? Scene,
           scene.displayName != newValue
        {
          self.setSceneDisplayName(scene, to: newValue)
        }
      }
    }
  }


  // MARK: NSOutlineView required delegate methods for drag&drop
  // =====================================================================
  
  
  // enable the outlineView to be an NSDraggingSource that supports dragging multiple items.
  // Returns a custom object that implements NSPasteboardWriting protocol (or simply use NSPasteboardItem).
  // so here we return ProjectTreeNode which means ProjectTreeNode is put on the pastboard
  
  func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting?
  {
    switch(item)
    {
      case let movie as Movie:
        return movie
       case let scene as Scene:
        return scene
      default:
        break
    }
    return nil
  }
  
  
  
  // Required: Implement this method know when the given dragging session is about to begin and potentially modify the dragging session.
  // draggedItems: A array of items to be dragged, excluding items for which outlineView:pasteboardWriterForItem: returns nil.
  func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any])
  {
    // store the dragged-node locally as an array of movies
    self.draggedNodes = draggedItems.compactMap{$0 as? Movie}
    
    let location: NSPoint = session.draggingLocation
    let numberOfDragItems: Int = self.draggedNodes.count
    session.enumerateDraggingItems(options: [], for: nil, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (draggingItem, index, stop) in
      
      let frame = draggingItem.draggingFrame
      let size: NSSize = frame.size
      let height: CGFloat = outlineView.rowHeight
      draggingItem.draggingFrame = NSMakeRect(location.x - 0.5 * size.width, location.y - height * CGFloat(index) + (CGFloat(numberOfDragItems) - 1.5) * height, size.width , size.height)
    })
  }
  
  
  // Optional: You can implement this optional delegate method to know when the dragging source operation ended at a specific location,
  //           such as the trash (by checking for an operation of NSDragOperationDelete).
  func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation)
  {
    
  }
  
  // Optional: Based on the mouse position, the outline view will suggest a proposed drop location. The data source may “retarget” a drop if desired by calling
  // setDropItem:dropChildIndex: and returning something other than NSDragOperationNone. You may choose to retarget for various reasons (for example, for
  // better visual feedback when inserting into a sorted position).
  func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation
  {
    if let editable: Bool = proxyProject?.isEditable, !editable
    {
      return []
    }
  
    if let draggingSource = info.draggingSource as? NSOutlineView, outlineView === draggingSource
    {
      if (item == nil)
      {
        // retarget the drop item to be "on" the entire outlineview
        //self.structuresOutlineView?.setDropItem(nil, dropChildIndex: NSOutlineViewDropOnItemIndex)
        return .generic
      }
      
      // can not copy 'on' but only 'above' an item
      if (index == NSOutlineViewDropOnItemIndex)
      {
        return NSDragOperation()
        //return .move
      }
      else
      {
        
        return .move
      }
    }
    else
    {
      if iRASPAWindowController.dragAndDropConcurrentQueue.operationCount > 0
      {
        return []
      }
      
      // not within the same table -> 'copy'
      //info.animatesToDestination = true
      // can not copy 'on' but only 'above' an item
      if (index == NSOutlineViewDropOnItemIndex)
      {
        return []
      }
      info.animatesToDestination = true
      return .copy
    }
  }
  
  

  
  func moveMovieNode(_ movie: Movie, toItem: Scene?, childIndex: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let indexPath: IndexPath = project.sceneList.indexPath(movie)
    {
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      
      NSAnimationContext.runAnimationGroup({ context in
      project.undoManager.beginUndoGrouping()
      movieOutlineView?.beginUpdates()
      
      // keep the selected node selected
      let selectedObject: Movie? = project.sceneList.selectedScene?.selectedMovie
      let selectedObjects: [Scene : Set< Movie >] = project.sceneList.selectedMovies
      
      let scene: Scene = project.sceneList.scenes[indexPath[0]]
      let lastIndex: Int = indexPath[1]
      
      project.undoManager.setActionName(NSLocalizedString("Reorder Movies", comment: ""))
      project.undoManager.registerUndo(withTarget: self, handler: {$0.moveMovieNode(movie, toItem: scene, childIndex : lastIndex)})
      
      // remove old node and remove it from the selection of the parent scene
      scene.selectedMovies.remove(movie)
      scene.movies.remove(at: lastIndex)
      self.movieOutlineView?.removeItems(at: IndexSet(integer: lastIndex), inParent: scene, withAnimation: [])
      
      // insert new node and add it to its selection
      toItem?.selectedMovies.insert(movie)
      toItem?.movies.insert(movie, at: childIndex)
      self.movieOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: toItem, withAnimation: .effectGap)
      
      /*
      if project.sceneList.selectedObjects.contains(movie)
      {
        if let indexValue = self.structuresOutlineView?.row(forItem: movie)
        {
          self.structuresOutlineView?.selectRowIndexes(NSIndexSet(index: indexValue) as IndexSet, byExtendingSelection: true)
        }
      }*/

      
      // also remove scene if the removal of the node would make it empty
      for scene in project.sceneList.scenes
      {
        if let index: Int = project.sceneList.scenes.firstIndex(of: scene)
        {
          if scene.allIRASPAStructures.isEmpty
          {
            // Put the undo for the removal on the stack. The redo is 'moveMovieNode' itself
            project.undoManager.registerUndo(withTarget: self, handler: {target in
              project.sceneList.scenes.insert(scene, at: index)
              target.movieOutlineView?.insertItems(at: IndexSet(integer: index), inParent: nil, withAnimation: .slideRight)
              target.movieOutlineView?.expandItem(scene)
              target.movieOutlineView?.reloadItem(scene)
            })
            
            project.sceneList.scenes.remove(at: index)
            self.movieOutlineView?.removeItems(at: IndexSet(integer: index), inParent: nil, withAnimation: .slideLeft)
          }
        }
      }
     
      // the movie has been moved, so reconstruct 'project.sceneList.selectedScene?.selectedMovie'
      if let selectedObject = selectedObject,
         let selectedMovieIndexPath: IndexPath = project.sceneList.indexPath(selectedObject)
      {
        project.sceneList.selectedScene?.selectedMovie = nil
        let scene: Scene = project.sceneList.scenes[selectedMovieIndexPath[0]]
        project.sceneList.selectedScene = scene
        project.sceneList.selectedScene?.selectedMovie = selectedObject
      }
        
      project.sceneList.selectedMovies = selectedObjects
      reloadSelection()
      
      movieOutlineView?.endUpdates()
      project.undoManager.endUndoGrouping()
        
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: toItem!.allRenderFrames)
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: scene.allRenderFrames)
        
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        
      }, completionHandler: {
        // reload after animation to remedy drawing artifacts in the outlineView
        self.reloadData()
        
        // change to update
        self.setDetailViewController()
      })
      
      self.observeNotifications = observeNotificationsStored
    }
  }

  
  // The data source should incorporate the data from the dragging pasteboard in the implementation of this method. You can get the data for the drop operation
  // from info using the draggingPasteboard method.
  func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool
  {
    if let draggingSource = info.draggingSource as? NSOutlineView, outlineView === draggingSource
    {
      return internalDrop(info: info, item: item, childindex: index)
    }
    else
    {
      return externalDrop(info: info, outlineView: outlineView, item: item, childindex: index)
    }
  }
  
  
  func internalDrop(info: NSDraggingInfo, item: Any?, childindex index: Int) -> Bool
  {
    var childIndex: Int = index
    
    var newItem: Scene? = item as? Scene
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      NSAnimationContext.runAnimationGroup({context in
        self.movieOutlineView?.beginUpdates()
        if (newItem == nil)
        {
          let scene: Scene = Scene()
          scene.displayName = "New scene"
          if childIndex == 0
          {
            project.sceneList.scenes.insert(scene, at: childIndex)
            self.movieOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: nil, withAnimation: .slideRight)
            self.movieOutlineView?.expandItem(scene)
            self.movieOutlineView?.reloadItem(scene)
          }
          else
          {
            childIndex = project.sceneList.scenes.count
            project.sceneList.scenes.insert(scene, at: childIndex)
            self.movieOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: nil, withAnimation: .slideRight)
            self.movieOutlineView?.expandItem(scene)
            self.movieOutlineView?.reloadItem(scene)
          }
          newItem = scene
          childIndex = 0
        }
        
        // drag/drop occured within the same outlineView -> reordering
        for node: Movie in self.draggedNodes
        {
          // Moving it from within the same parent! Account for the remove, if it is past the oldIndex
          
          if let indexPath: IndexPath = project.sceneList.indexPath(node)
          {
            let parent: Scene = project.sceneList.scenes[indexPath[0]]
            
            // Moving it from within the same parent -> account for the remove, if it is past the oldIndex
            if (newItem as AnyObject? === parent as AnyObject?)
            {
              let oldIndex = indexPath[1]
              if (childIndex > oldIndex)
              {
                childIndex = childIndex - 1 // account for the remove
              }
            }
            
            self.moveMovieNode(node, toItem: newItem, childIndex: childIndex)
            childIndex = childIndex + 1
          }
        }
        self.movieOutlineView?.endUpdates()
      }, completionHandler: {
        self.setDetailViewController()
        
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      })
      return true
    }
    return false
  }
  
  func externalDrop(info: NSDraggingInfo, outlineView: NSOutlineView, item: Any?, childindex index: Int) -> Bool
  {
    var childIndex: Int = index
    
    var newItem: Scene? = item as? Scene
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let newSelectedScene: Scene? = project.sceneList.selectedScene
      let newSelectedMovie: Movie? = project.sceneList.selectedScene?.selectedMovie
      let newSelection: [Scene: Set<Movie>] = project.sceneList.selectedMovies
     
      
      if (newItem == nil)
      {
        let scene: Scene = Scene()
        scene.displayName = "New scene"
        if childIndex == 0
        {
          self.addSceneNode(scene, atIndex: childIndex)
        }
        else
        {
          childIndex = project.sceneList.scenes.count
          self.addSceneNode(scene, atIndex: childIndex)
        }
        newItem = scene
        childIndex = 0
      }
      
      var insertionIndex: Int = 0
      
      // First place holders are inserted
      // Note that undo works for these inserted objects, so only the content should be modified, but the objects themselves should never be replaced.
      
      self.movieOutlineView?.beginUpdates()
      info.enumerateDraggingItems(options: .concurrent, for: outlineView, classes: [Movie.self], searchOptions: [:], using: { (draggingItem , idx, stop)  in
        if let movie  = draggingItem.item as? Movie
        {
          self.addMovieNode(movie, inItem: newItem, atIndex: childIndex, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
          childIndex += 1
          insertionIndex += 1
        
          // set the draggingframe for all pasteboard-items
          if let height: CGFloat = self.movieOutlineView?.rowHeight,
             let row: Int = self.movieOutlineView?.row(forItem: movie), row>=0,
             let frame: NSRect = self.movieOutlineView?.frameOfCell(atColumn: 0, row: row),
             frame.width > 0, height > 0
          {
            // frameOfCell(atColumn:row:) not working in NSOutlineview 'Sourcelist'-style
            draggingItem.draggingFrame = NSMakeRect(frame.origin.x, frame.origin.y + height * CGFloat(insertionIndex - 1), frame.width, height)
          }
        }
      })
      self.movieOutlineView?.endUpdates()
      
      self.setDetailViewController()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      return true
    }
    return false
  }
  
  // NOTE: only used for drag&drop (not copy&paste) and not called when the item is an NSPasteboardItemDataProvider
  func outlineView(_ outlineView: NSOutlineView, namesOfPromisedFilesDroppedAtDestination dropDestination: URL, forDraggedItems items: [Any]) -> [String]
  {
    for node in self.draggedNodes
    {
      if let data: Data = node.pasteboardPropertyList(forType: NSPasteboardTypeProjectTreeNode) as? Data,
         let compressedData: Data = data.compress(withAlgorithm: .lzma)
      {
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let url: URL = dropDestination.appendingPathComponent(node.displayName).appendingPathExtension(pathExtension)
        do
        {
          try compressedData.write(to: url, options: .atomic)
        }
        catch
        {
          
        }
      }
    }
    return self.draggedNodes.map{$0.displayName}
  }
  
  
  // can not combine (yet) with lazy drag/drop
  /*
  func outlineView(_ outlineView: NSOutlineView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo)
  {
    return
    if let tableColumn: NSTableColumn = outlineView.outlineTableColumn,
      let tableCellView: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "movieView"), owner: self) as? NSTableCellView
    {
      // Calculate a base frame for new cells
      var cellFrame: NSRect = NSMakeRect(0, 0, tableColumn.width, outlineView.rowHeight)
      
      // Subtract out the intercellSpacing from the width only. The rowHeight is sans-spacing
      cellFrame.size.width -= outlineView.intercellSpacing.width
      
      
      // When enumerating dragging items in an NSDraggingInfo object, item is not the original pasteboardWriter. 
      // It is an instance of one of the classes provided to the enumeration method.
      // Enumerate through each dragging item. Any changes made to the properties of the draggingItem are reflected in the drag and are 
      // automatically removed when the drag exits. Classes in the provided array must implement the NSPasteboardReading protocol. 
      // Cocoa classes that implement this protocol include NSImage, NSString, NSURL, NSColor, NSAttributedString, and NSPasteboardItem. 
      // For every item on the pasteboard, each class in the provided array will be queried for the types it can read using -
      // readableTypesForPasteboard:. An instance will be created of the first class found in the provided array whose readable 
      // types match a conforming type contained in that pasteboard item.
      draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent, for: outlineView, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (draggingItem , idx, stop)  in
        draggingItem.draggingFrame = cellFrame
        draggingItem.imageComponentsProvider = { [weak self, weak draggingInfo, weak tableCellView] in
          
          tableCellView?.frame = cellFrame
          if let draggingSource = draggingInfo?.draggingSource() as? NSOutlineView
          {
            tableCellView?.textField?.stringValue = draggingSource === self?.structuresOutlineView ? "Move to here" : "Copy into table"
          }
          if let fontSize: CGFloat = tableCellView?.textField?.font?.pointSize
          {
            tableCellView?.textField?.font = NSFont.boldSystemFont(ofSize: fontSize)
          }
          return tableCellView?.draggingImageComponents ?? []
        }
      })
    }
  }*/

  @IBAction func cancelImport(sender: NSButton)
  {
    if let superview = sender.superview,
      let row: Int = self.movieOutlineView?.row(for: superview), row >= 0
    {
      if let movie: Movie = self.movieOutlineView?.item(atRow: row) as? Movie
      {
        movie.importOperation?.cancel()
        
        self.movieOutlineView?.beginUpdates()

        if let fromScene: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
           let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie)
        {
          fromScene.movies.removeObject(movie)
          self.movieOutlineView?.removeItems(at: IndexSet(integer: childIndex), inParent: fromScene, withAnimation: .slideLeft)
        }
        self.movieOutlineView?.endUpdates()
      }
    }
  }
  
  // MARK: Set and update detail views
  // =====================================================================
  
  /// Sets the arrangedObjects of the detail-view pagecontrollers.
  ///
  /// Note: used to set the movies as the arrangedObjects in detail-view pagecontrollers.
  func setDetailViewController()
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let movies: [Movie] = project.sceneList.scenes.flatMap{$0.movies}
      let selectedArrangedObjects: [Movie] = project.sceneList.scenes.flatMap{$0.selectedMovies}
      let arrangedObjects: [Any] = movies.isEmpty ? [[]] : movies
      
      if let selectedScene: Scene = project.sceneList.selectedScene,
         let selectedMovie: Movie = selectedScene.selectedMovie,
         let selectionIndex = movies.firstIndex(of: selectedMovie)
      {
        windowController?.setPageControllerObjects(arrangedObjects: arrangedObjects,  selectedArrangedObjects:selectedArrangedObjects, selectedIndex: selectionIndex)
      }
      else
      {
        windowController?.setPageControllerObjects(arrangedObjects: [[]],  selectedArrangedObjects:[[]], selectedIndex: 0)
      }
    
      if let selectedScene: Scene = project.sceneList.selectedScene,
         let sceneIndex: Int = project.sceneList.scenes.firstIndex(of: selectedScene),
         let selectedMovie: Movie = selectedScene.selectedMovie,
         let movieIndex = selectedScene.movies.firstIndex(of: selectedMovie)
      {
        let frames: [iRASPAStructure] = movies.compactMap{$0.selectedFrame}
        let arrangedObjects: [Any] = frames.isEmpty ? [[]] : frames
               
        let selectionIndex: Int = project.sceneList.rowForSectionTuple(sceneIndex, movieIndex: movieIndex)
        windowController?.setPageControllerFrameObject(arrangedObjects: arrangedObjects, selectedIndex: selectionIndex)
      }
      else
      {
        windowController?.setPageControllerFrameObject(arrangedObjects: [[]], selectedIndex: 0)
      }
    }
  }
  
  /// Updates the selectedArrangedObjects and index of the detail-view pagecontrollers.
  ///
  /// Note: used to set the selection and index of the detail-view pagecontrollers.
  func updateDetailViewController()
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let selectedMovies: [Movie] = project.sceneList.scenes.flatMap{$0.selectedMovies}
      let selectedArrangedObjects = selectedMovies
      let movies: [Movie] = project.sceneList.scenes.flatMap{$0.movies}
      
      if let selectedMovie: Movie = project.sceneList.selectedScene?.selectedMovie,
         let selectionIndex: Int = movies.firstIndex(of: selectedMovie)
      {
        windowController?.setPageControllerSelection(selectedArrangedObjects: selectedArrangedObjects, selectedIndex: selectionIndex)
      }
      
      
      if let selectedScene: Scene = project.sceneList.selectedScene,
         let sceneIndex: Int = project.sceneList.scenes.firstIndex(of: selectedScene),
         let selectedMovie: Movie = selectedScene.selectedMovie,
         let movieIndex = selectedScene.movies.firstIndex(of: selectedMovie)
      {
        let selectionIndex: Int = project.sceneList.rowForSectionTuple(sceneIndex, movieIndex: movieIndex)
       
        windowController?.setPageControllerFrameSelection(selectedIndex: selectionIndex)
      }
    }
  }
  
  /// Sets the selection index.
  ///
  /// Note: used when swiping in the detail-views
  ///
  /// - parameter index: The frame index.
  func setSelectionIndex(index: Int)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let movies: [Movie] = project.sceneList.scenes.flatMap{$0.movies}
      let movie: Movie = movies[index]
      if let indexPath: IndexPath = project.sceneList.indexPath(movie)
      {
        // clear old selection
        project.sceneList.selectedScene?.selectedMovie = nil
        project.sceneList.selectedScene?.selectedMovies = []
        
        // set new selection
        let selectedScene: Scene = project.sceneList.scenes[indexPath[0]]
        let selectedMovie: Movie = selectedScene.movies[indexPath[1]]
        
        project.sceneList.selectedScene = selectedScene
        
        selectedScene.selectedMovies = [selectedMovie]
        selectedScene.selectedMovie = selectedMovie
        
        self.observeNotifications = false
        self.reloadSelection()
        self.observeNotifications = true
        
        // set the other detail view-controllers to the same index
        updateDetailViewController()
      }
    }
  }

  

  // MARK: Selection handling
  // =====================================================================
  
  
  func reloadSelection()
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let observeNotificationsStored: Bool = self.observeNotifications
      
      // avoid sending notification due to selection change
      self.observeNotifications = false
      
      let selectedNodes: Set< Movie > = Set(project.sceneList.scenes.flatMap{$0.selectedMovies})
      
     
      self.movieOutlineView?.deselectAll(nil)
      
      var indexSet: IndexSet = IndexSet()
      for node in selectedNodes
      {
        if let row: Int = self.movieOutlineView?.row(forItem: node) , row >= 0
        {
          indexSet.insert(row)
        }
      }
      self.movieOutlineView?.selectRowIndexes(indexSet, byExtendingSelection: false)
      
     
      if let selectedItem: Movie = project.sceneList.selectedScene?.selectedMovie
      {
        self.windowController?.infoPanel?.showInfoItem(item: MaterialsInfoPanelItemView(image: selectedItem.infoPanelIcon, message: selectedItem.infoPanelString))
        
        if let selectedRow: Int = self.movieOutlineView?.row(forItem: selectedItem)
        {
          self.movieOutlineView?.selectRowIndexes(NSIndexSet(index: selectedRow) as IndexSet, byExtendingSelection: true)
          self.movieOutlineView?.enumerateAvailableRowViews({ (rowView, row) in
        
            if (row == selectedRow)
            {
              (rowView as? StructureTableRowView)?.secondaryHighlighted = true
              (rowView as? StructureTableRowView)?.isSelected = true
            }
            else
            {
              (rowView as? StructureTableRowView)?.secondaryHighlighted = false
            }
          })
        }
      }
      
      self.observeNotifications = observeNotificationsStored
    }
    
    
  }
  
  
  /*
  // save and restore the selected project and the selection for undo/redo
  // idea: selection as dictionary <Int, MovieSet>
  func setCurrentMovieAndSelection(newSelectedMovie: Movie?, newSelection: [Scene : Set< Movie >], oldselectedMovie: Movie?, oldSelection: [Scene : Set< Movie >])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      // save off the current selectedNode and current selection for undo/redo
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setCurrentMovieAndSelection(newSelectedMovie: oldselectedMovie, newSelection: oldSelection, oldselectedMovie: newSelectedMovie, oldSelection: newSelection)})
      
      if let newSelectedMovie: Movie = newSelectedMovie,
         let indexPath: IndexPath = project.sceneList.indexPath(newSelectedMovie)
      {
        let scene: Scene = project.sceneList.scenes[indexPath[0]]
        project.sceneList.selectedScene = scene
        scene.selectedMovie = newSelectedMovie
      }
      else
      {
        project.sceneList.selectedScene = nil
      }
      
      project.sceneList.selectedMovies = newSelection
      
      self.reloadSelection()
    }
  }*/
  
  /*
  func setCurrentMovieAndSelection(newSelectedScene: Scene?, newSelectedMovie: Movie?, newSelection: [Scene : Set< Movie >], oldselectedScene: Scene?, oldselectedMovie: Movie?, oldSelection: [Scene : Set< Movie >])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      // save off the current selectedNode and current selection for undo/redo
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setCurrentMovieAndSelection(newSelectedScene: oldselectedScene, newSelectedMovie: oldselectedMovie, newSelection: oldSelection, oldselectedScene: newSelectedScene, oldselectedMovie: newSelectedMovie, oldSelection: newSelection)})
      
      if let newSelectedMovie: Movie = newSelectedMovie
      {
        project.sceneList.selectedScene = newSelectedScene
        newSelectedScene?.selectedMovie = newSelectedMovie
      }
      else
      {
        project.sceneList.selectedScene = nil
      }
      
      project.sceneList.selectedMovies = newSelection
      
      self.reloadSelection()
    }
  }*/
  
  // only set selectedMovies, not selectedMovie (that is handled in 'outlineViewSelectionDidChange')
  func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let allowedSelection: NSMutableIndexSet = NSMutableIndexSet()
      var selectedScenes: [Scene] = []
      var selectedMovies: [Movie] = []
      
       for row in proposedSelectionIndexes
       {
        if let item: Any = outlineView.item(atRow: row)
        {
          switch(item)
          {
          case let scene as Scene:
            selectedScenes.append(scene)
          case let movie as Movie:
            allowedSelection.add(row)
            selectedMovies.append(movie)
            break
          default:
            break
          }
        }
      }
      
      if (!selectedScenes.isEmpty)
      {
        // return the value of the table view’s existing selection to avoid changing the selection
        if let rowIndexes =  self.movieOutlineView?.selectedRowIndexes
        {
          return rowIndexes
        }
      }
      
      if (self.observeNotifications)
      {
        for scene in project.sceneList.scenes
        {
          scene.selectedMovies = []
        }
        
        for movie in selectedMovies
        {
          if let indexPath: IndexPath = project.sceneList.indexPath(movie)
          {
            let scene: Scene = project.sceneList.scenes[indexPath[0]]
            scene.selectedMovies.insert(movie)
          }
        }
      }
      
      return allowedSelection as IndexSet
    }
    
    return proposedSelectionIndexes
  }
  

  func outlineViewSelectionDidChange(_ aNotification: Notification)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
           let undoManager = undoManager
    {
      if (self.observeNotifications && !undoManager.isUndoing && !undoManager.isRedoing)
      {
        // get selected rows and the main selected row (the last selected one)
        // Note: using the arrow-keys continues from the main selected row
        
        // case selectedRows.count == 1: a new single item is selected
        // case !selectedRows.contains(oldSelectedRow): the old selected row (-1 for no previous selection) is not in the current selection
        
        if let oldSelectedRow: Int = self.movieOutlineView?.row(forItem: project.sceneList.selectedScene?.selectedMovie),
           let selectedRows: IndexSet = self.movieOutlineView?.selectedRowIndexes,
           let selectedRow: Int = self.movieOutlineView?.selectedRow, selectedRow >= 0
        {
          if((selectedRows.count == 1) || (!selectedRows.contains(oldSelectedRow)))
          {
            self.movieOutlineView?.enumerateAvailableRowViews({ (rowView, row) in
              if (row == selectedRow)
              {
                (rowView as? StructureTableRowView)?.secondaryHighlighted = true
                (rowView as? StructureTableRowView)?.isSelected = true
              
                // needed to force a draw of the secondary-highlight
                rowView.needsDisplay = true
              }
              else
              {
                (rowView as? StructureTableRowView)?.secondaryHighlighted = false
                rowView.needsDisplay = true
              }
            })
          
            // set the selected scene and movie
            if let movie = self.movieOutlineView?.item(atRow: selectedRow) as? Movie,
               let scene = self.movieOutlineView?.parent(forItem: movie) as? Scene
            {
              project.sceneList.selectedScene = scene
              scene.selectedMovie = movie
              
              self.windowController?.infoPanel?.showInfoItem(item: MaterialsInfoPanelItemView(image: movie.infoPanelIcon, message: movie.infoPanelString))
            }
          }
          else
          {
            // since extending the selection changes the 'selectedRow' (the last selected item), set it back
            // this will NOT change the selection, but only update the 'selectedRow'
            // This is important when changing the selection afterwards with the 'up/down' keys, it will start from the 'selectedRow'.
            self.movieOutlineView?.selectRowIndexes(IndexSet(integer: oldSelectedRow), byExtendingSelection: true)
          }
        }
        
        self.updateDetailViewController()
      }
      
    }
  }
  
  
  

  // MARK: Visibility check-boxes
  // =====================================================================
  
  
  @IBAction func toggleMovieVisibility(_ sender: NSButton)
  {
    if let _ = self.proxyProject
    {
      if let row: Int = self.movieOutlineView?.row(for: sender.superview!), row >= 0
      {
        if let movie: Movie = self.movieOutlineView?.item(atRow: row) as? Movie
        {
          movie.isVisible = (sender.state == NSControl.StateValue.on)
        
          if let scene: Scene = movieOutlineView?.parent(forItem: movie) as? Scene
          {
         self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: scene.allRenderFrames)
          }
          self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
          
          //self.proxyProject?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
          self.windowController?.detailTabViewController?.renderViewController?.redraw()
        }
      }
    }
  }

  // MARK: plus/minus buttons
  // =====================================================================
  
  @IBAction func deleteSelectedStructures(_ sender: NSButton)
  {
    if let project = self.proxyProject, project.isEditable
    {
      self.deleteSelection()
    }
  }
  
  
  // MARK: Menu validation
  // =====================================================================
  
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if (menuItem.action == #selector(copy(_:)))
    {
      return (self.movieOutlineView?.selectedRowIndexes.count ?? 0) > 0
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
      // NSPasteboard.general.canReadObject(forClasses: [ProjectTreeNode.self], options: [:])
    }
    
    if (menuItem.action == #selector(cut(_:)))
    {
      return (self.movieOutlineView?.selectedRowIndexes.count ?? 0) > 0
    }
    
    return true
  }
  
  // MARK: Import/Export
  // =====================================================================
  
  
  func importStructureFiles(_ URLs: [URL], asSeparateProjects: Bool)
  {
    
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
    
      let selectedMovies: [Movie] = parentProject.sceneList.scenes.flatMap{$0.selectedMovies}
      pasteboard.writeObjects(selectedMovies)
    }
  }
  
  @objc func paste(_ sender: AnyObject)
  {
    let index: Int = self.movieOutlineView?.selectedRow ?? 0
    
    let pasteboard = NSPasteboard.general
    if let proxyProject: ProjectTreeNode = self.proxyProject,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let movie: Movie = self.movieOutlineView?.item(atRow: index) as? Movie,
       let childIndex: Int = self.movieOutlineView?.childIndex(forItem: movie),
       let newItem: Scene = self.movieOutlineView?.parent(forItem: movie) as? Scene,
       let pasteboardItems: [Any]  = pasteboard.readObjects(forClasses: [Movie.self], options: nil)
    {
      let newSelectedScene: Scene? = project.sceneList.selectedScene
      let newSelectedMovie: Movie? = project.sceneList.selectedScene?.selectedMovie
      let newSelection: [Scene: Set<Movie>] = project.sceneList.selectedMovies
      
      var insertionIndex = childIndex + 1
      
      self.movieOutlineView?.beginUpdates()
      for pasteboardItem in pasteboardItems
      {
        if let movie  = pasteboardItem as? Movie
        {
          self.addMovieNode(movie, inItem: newItem, atIndex: insertionIndex, newSelectedScene: newSelectedScene, newSelectedMovie: newSelectedMovie, newSelection: newSelection)
          insertionIndex += 1
        }
      }
      self.movieOutlineView?.endUpdates()
      
      self.setDetailViewController()
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
    }
  }

  @objc func cut(_ sender: AnyObject)
  {
    copy(sender)
    self.deleteSelection()
  }
}
