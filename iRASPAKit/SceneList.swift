/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import RenderKit
import SimulationKit
import MathKit
import simd


// A scene contains a list of Movies: FKArrayController<Scene>
public final class SceneList: Decodable, AtomVisualAppearanceViewer, BondVisualAppearanceViewer, UnitCellVisualAppearanceViewer, CellViewer, InfoViewer, AdsorptionSurfaceVisualAppearanceViewer, PrimitiveVisualAppearanceViewer, BinaryDecodable, BinaryEncodable
{  
  private var versionNumber: Int = 1
  private static var classVersionNumber: Int = 1
  //public var numberOfFramesPerSecond: Int = 15
  public var displayName : String = ""
  public var scenes: [Scene] = []
  
  public var filteredAndSortedObjects: [Scene] = [Scene]()
  
  public weak var selectedScene: Scene? = nil
  
  public var filterPredicate: (Scene) -> Bool = {_ in return true}
  var sortDescriptors: [NSSortDescriptor] = []
  
  public init()
  {
    scenes = []
  }
  
  public convenience init(name: String, scenes: [Scene])
  {
    self.init()
    self.displayName = name
    self.scenes = scenes
  }
  
  public convenience init(scenes: [Scene])
  {
    self.init()
    self.scenes = scenes
  }
  
  public var renderCanDrawAdsorptionSurface: Bool
  {
    return self.scenes.reduce(into: false, {$0 = $0 || $1.renderCanDrawAdsorptionSurface})
  }
  
  deinit
  {
    //Swift.print("Deallocing FKArrayController \(T.self)")
  }
  
  public var allAdsorptionSurfaceStructures: [SKRenderAdsorptionSurfaceStructure]
  {
    return self.scenes.flatMap{$0.movies.flatMap{$0.structureViewerStructures.map{$0 as SKRenderAdsorptionSurfaceStructure}}}
  }

  
  // MARK: -
  // MARK: Decodable support
  
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let versionNumber: Int = try container.decode(Int.self)
    if versionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    let _ = try container.decode(Int.self) // numberOfFramesPerSecond
    
    self.displayName = try container.decode(String.self)
    self.scenes  = try container.decode([Scene].self)
  }
  
  
  public var selectedFrames: [Movie : Set<iRASPAStructure>]
  {
    get
    {
      var selection: [Movie : Set<iRASPAStructure>] = [:]
      
      for movie in self.scenes.flatMap({$0.movies})
      {
        selection[movie] = movie.selectedFrames
      }
      
      return selection
    }
    set(newValue)
    {
      self.scenes.flatMap{$0.movies}.forEach({$0.selectedFrames = []})
      for (movie, selection) in newValue
      {
        movie.selectedFrames = selection
      }
    }
  }
  
  // used to store the selection in undo/redo
  public var selectedMovies: [Scene: Set<Movie>]
  {
    get
    {
      var selection: [Scene : Set<Movie>] = [:]
      
      for scene in self.scenes
      {
        selection[scene] = scene.selectedMovies
      }
      
      return selection
    }
    set(newValue)
    {
      self.scenes.forEach({$0.selectedMovies = []})
      for (scene, selection) in newValue
      {
        scene.selectedMovies = selection
      }
    }
  }
  
  public var selection: (selectedScene: Scene?, selectedMovie: [Scene : Movie?], selectedFrame: [Movie : iRASPAStructure?], selectedMovies: [Scene : Set<Movie>], selectedFrames: [Movie : Set<iRASPAStructure>])
  {
    get
    {
      let movies: [Movie] = self.scenes.flatMap{$0.movies}
      let savedSelectedScene: Scene? = self.selectedScene
      
      let savedSelectedMovie: [Scene : Movie?] = self.scenes.reduce(into: [Scene : Movie?]()) {$0[$1] = $1.selectedMovie}
      let savedSelectedFrame: [Movie : iRASPAStructure?] = movies.reduce(into: [Movie : iRASPAStructure?]()) {$0[$1] = $1.selectedFrame}
    
      let savedSelectedMovies: [Scene : Set<Movie>]  = self.scenes.reduce(into: [Scene : Set<Movie>]()) {$0[$1] = $1.selectedMovies}
      let savedSelectedFrames: [Movie : Set<iRASPAStructure>] = movies.reduce(into: [Movie : Set<iRASPAStructure>]()) {$0[$1] = $1.selectedFrames}
      
      return (selectedScene: savedSelectedScene, selectedMovie: savedSelectedMovie, selectedFrame: savedSelectedFrame, selectedMovies: savedSelectedMovies, selectedFrames: savedSelectedFrames)
    }
    set(newValue)
    {
      self.selectedScene = newValue.selectedScene
      
      self.scenes.forEach{$0.selectedMovie = nil; $0.selectedMovies = []}
      self.scenes.flatMap{$0.movies}.forEach{$0.selectedFrame = nil; $0.selectedFrames = []}
      
      newValue.selectedMovie.forEach{$0.selectedMovie = $1}
      newValue.selectedFrame.forEach{$0.selectedFrame = $1}
      
      newValue.selectedMovies.forEach{$0.selectedMovies = $1}
      newValue.selectedFrames.forEach{$0.selectedFrames = $1}
    }
  }
  
  
  
  
  // used in movie-playing
  public func setAllMovieFramesToBeginning()
  {
    for scene in self.scenes
    {
      scene.movies.forEach { (movie) in
        movie.selectedFrame = movie.frames.first
        if let selectedFrame = movie.selectedFrame
        {
          movie.selectedFrames = [selectedFrame]
        }
      }
    }
  }
  
  // used in movie-playing
  public func setAllMovieFramesToEnd()
  {
    for scene in self.scenes
    {
      scene.movies.forEach { (movie) in
        movie.selectedFrame = movie.frames.last
        if let selectedFrame = movie.selectedFrame
        {
          movie.selectedFrames = [selectedFrame]
        }
      }
    }
  }
  
  public func advanceAllMovieFrames()
  {
    for scene in self.scenes
    {
      for movie in scene.movies
      {
        if let selectedFrame = movie.selectedFrame,
           let selectedIndex = movie.frames.index(of: selectedFrame),
           selectedIndex + 1 < movie.frames.count
        {
          let advancedSelectedFrame = movie.frames[selectedIndex + 1]
          movie.selectedFrame = advancedSelectedFrame
          movie.selectedFrames = [advancedSelectedFrame]
        }
      }
      
    }
  }
  
  public func synchronizeAllMovieFrames(to selectedFrameIndex: Int)
  {
    for scene in self.scenes
    {
      for movie in scene.movies
      {
        let frame = movie.frames[min(selectedFrameIndex, movie.frames.count-1)]
        movie.selectedFrame = frame
        movie.selectedFrames = [frame]
      }
    }
  }
  
  // used in 'makeMovie' (RenderTabViewController)
  public var maximumNumberOfFrames: Int?
  {
    return (self.scenes.flatMap{$0.movies.map{$0.frames.count}}).max()
  }
  
  
  public func indexPath(_ movie: Movie) -> IndexPath?
  {
    let count: Int = self.scenes.count
    for i: Int in 0..<count
    {
      if let index: Int = scenes[i].movies.index(of: movie)
      {
        return [i,index]
      }
    }
    return nil
  }
  
  
  public func rowForSectionTuple(_ sceneIndex: Int, movieIndex: Int) -> Int
  {
    var count: Int  = 0
    
    for i in 0..<sceneIndex
    {
      count += self.scenes[i].movies.count
    }
    count += movieIndex
    return count
  }
  
  public static func ==(lhs: SceneList, rhs: SceneList) -> Bool
  {
    return lhs === rhs
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SceneList.classVersionNumber)
    encoder.encode(self.displayName)
    encoder.encode(self.scenes)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SceneList.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.scenes = try decoder.decode([Scene].self)
  }
  
}




// MARK: -
// MARK: StructureViewer protocol implementation

extension SceneList: StructureViewer
{
  /// Returns all the structures in the sceneList
  public var structureViewerStructures: [Structure]
  {
    return self.scenes.flatMap{$0.structureViewerStructures}
  }
  
  public var selectedRenderFrames: [RKRenderStructure]
  {
    return self.scenes.flatMap{$0.selectedRenderFrames}
  }

  public var allFrames: [RKRenderStructure]
  {
    return self.scenes.flatMap{$0.allFrames}
  }
  
  
  
}




