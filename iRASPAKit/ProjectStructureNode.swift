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
import simd
import BinaryCodable
import SimulationKit
import RenderKit
import SymmetryKit

public final class ProjectStructureNode: ProjectNode, RKRenderDataSource, RKRenderCameraSource
{
  private var versionNumber: Int = 2
  private static var classVersionNumber: Int = 2
  
  public var sceneList: SceneList = SceneList()
  public var renderLights: [RKRenderLight] = [RKRenderLight(),RKRenderLight(),RKRenderLight(),RKRenderLight()]
  
  public var showBoundingBox: Bool = false
  
  public var structures: [Structure]
  {
    return sceneList.scenes.filter{$0.movies.count > 0}.flatMap{$0.movies.filter{$0.frames.count > 0}.map{$0.structureViewerStructures[0]}}
  }
  
  
  public var measurementTreeNodes: [(structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)] = []
  
  public var renderBackgroundType = RKBackgroundType.color
  public var renderBackgroundColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var renderBackgroundImage: CGImage? = nil
  public var renderBackgroundImageName: String = ""
  public var renderBackgroundCachedImage: CGImage? = nil
  public var backgroundLinearGradientFromColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var backgroundLinearGradientToColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var backgroundRadialGradientFromColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var backgroundRadialGradientToColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var backgroundLinearGradientAngle: Double = 45.0
  public var backgroundRadialGradientRoundness: Double = 0.4
  
  public var renderImagePhysicalSizeInInches: Double = 6.5
  public var renderImageNumberOfPixels: Int = 1600
  public var renderAspectRatio: Double = 1.0
  public var imageDPI: DPI = .dpi_300
  public var imageUnits: Units = .cm
  public var imageDimensions: Dimensions = .pixels
  public var renderImageQuality : RKImageQuality = .rgb_8_bits
  
  public var numberOfFramesPerSecond: Int = 15
  
  public var renderCamera: RKCamera?
  
  public var ImageDotsPerInchValue: Double
  {
    get
    {
      switch(imageDPI)
      {
        case .dpi_72:
          return 72.0
         case .dpi_75:
          return 75.0
        case .dpi_150:
          return 150.0
        case .dpi_300:
          return 300.0
        case .dpi_600:
          return 600.0
        case .dpi_1200:
          return 1200.0
      }
    }
  }
  

  
  
  public enum DPI: Int
  {
    case dpi_72 = 0
    case dpi_75 = 1
    case dpi_150 = 2
    case dpi_300 = 3
    case dpi_600 = 4
    case dpi_1200 = 5
  }
  
  public enum Dimensions: Int
  {
    case physical = 0
    case pixels = 1
  }
  
  public enum Units: Int
  {
    case inch = 0
    case cm = 1
  }

  
  public init(name: String, sceneList: SceneList)
  {
    self.sceneList = sceneList
    super.init(name: name)
  }
  
  
 
  // MARK: -
  // MARK: legacy decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let readVersionNumber: Int = try container.decode(Int.self)
    if readVersionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    self.sceneList = try container.decode(SceneList.self)
    
    
    self.renderBackgroundType = RKBackgroundType(rawValue: try container.decode(Int.self))!
    self.renderBackgroundColor = NSColor(float4: try container.decode(SIMD4<Float>.self))
    
    if let data = try container.decodeIfPresent(Data.self)
    {
      if let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)
      {
        if let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        {
          self.renderBackgroundImage = image
        }
      }
    }
    self.backgroundLinearGradientFromColor = NSColor(float4: try container.decode(SIMD4<Float>.self))
    self.backgroundLinearGradientToColor = NSColor(float4: try container.decode(SIMD4<Float>.self))
    self.backgroundRadialGradientFromColor = NSColor(float4: try container.decode(SIMD4<Float>.self))
    self.backgroundRadialGradientToColor = NSColor(float4: try container.decode(SIMD4<Float>.self))
    self.backgroundLinearGradientAngle = try container.decode(Double.self)
    self.backgroundRadialGradientRoundness = try container.decode(Double.self)
    
    self.renderImagePhysicalSizeInInches = try container.decode(Double.self)
    self.renderImageNumberOfPixels = try container.decode(Int.self)
    
    self.imageDPI = try DPI(rawValue: container.decode(Int.self))!
    self.imageUnits = try Units(rawValue: container.decode(Int.self))!
    self.imageDimensions = try Dimensions(rawValue: container.decode(Int.self))!
    self.renderImageQuality = try RKImageQuality(rawValue: container.decode(Int.self))!
    
    if readVersionNumber >= 2 // introduced in version 2
    {
      self.showBoundingBox = try container.decode(Bool.self)
    }
    
    let superDecoder = try container.superDecoder()
    try super.init(from: superDecoder)
    
    self.renderBackgroundCachedImage = self.drawGradientCGImage()
  }
  
  deinit
  {
    //debugPrint("DELETING ProjectStructureNode")
  }
  
  public func setInitialSelectionIfNeeded()
  {
    if sceneList.selectedScene == nil,
       let selectedScene = sceneList.scenes.first
    {
      sceneList.selectedScene = selectedScene
      
      if selectedScene.selectedMovie == nil,
        let selectedMovie = selectedScene.movies.first
      {
        selectedScene.selectedMovie = selectedMovie
        selectedScene.selectedMovies.insert(selectedMovie)
      }
    }
    
    for scene in sceneList.scenes
    {
      for movie in scene.movies
      {
        if movie.selectedFrame == nil
        {
          movie.selectedFrame = movie.frames.first
          
        }
        if let selectedFrame = movie.selectedFrame
        {
          movie.selectedFrames.insert(selectedFrame)
        }
      }
    }
  }
  
  
  public var renderBoundingBox: SKBoundingBox
  {
    get
    {
      let frames: [Structure] = self.sceneList.scenes.flatMap{$0.movies}.filter{$0.isVisible}.compactMap{($0.selectedFrame ?? $0.frames.first)?.structure}
      
      if(frames.isEmpty)
      {
        return SKBoundingBox(minimum: SIMD3<Double>(x:0, y:0, z:0), maximum: SIMD3<Double>(x:0.0, y:0.0, z:0.0))
      }
      
      var minimum: SIMD3<Double> = SIMD3<Double>(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
      var maximum: SIMD3<Double> = SIMD3<Double>(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
      
      for frame in frames
      {
        // for rendering the bounding-box is in the global coordinate space (adding the frame origin)
        let currentBoundingBox: SKBoundingBox = frame.transformedBoundingBox + frame.origin
        
        let transformedBoundingBox: SKBoundingBox = currentBoundingBox

        minimum.x = min(minimum.x, transformedBoundingBox.minimum.x)
        minimum.y = min(minimum.y, transformedBoundingBox.minimum.y)
        minimum.z = min(minimum.z, transformedBoundingBox.minimum.z)
        maximum.x = max(maximum.x, transformedBoundingBox.maximum.x)
        maximum.y = max(maximum.y, transformedBoundingBox.maximum.y)
        maximum.z = max(maximum.z, transformedBoundingBox.maximum.z)
      }
      
      return SKBoundingBox(minimum: minimum, maximum: maximum)
    }
  }
  
    
  public func drawGradientCGImage() -> CGImage
  {
    if let renderBackgroundImage = renderBackgroundImage,
       renderBackgroundType == RKBackgroundType.image
    {
      return renderBackgroundImage
    }
        
    
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
    let context: CGContext = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 1024 * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    
    
    let graphicsContext: NSGraphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    
    NSGraphicsContext.current = graphicsContext
    
    if (renderBackgroundType == RKBackgroundType.color)
    {
      graphicsContext.cgContext.setFillColor(renderBackgroundColor.cgColor)
      graphicsContext.cgContext.fill(NSMakeRect(0, 0, 1024, 1024))
    }
    else if (renderBackgroundType == RKBackgroundType.linearGradient)
    {
      let gradient: NSGradient = NSGradient(starting: backgroundLinearGradientFromColor, ending: backgroundLinearGradientToColor)!
      gradient.draw(in: NSMakeRect(0, 0, 1024, 1024), angle: CGFloat(backgroundLinearGradientAngle))
    }
    else if (renderBackgroundType == RKBackgroundType.radialGradient)
    {
      graphicsContext.cgContext.scaleBy(x: CGFloat(1.0), y: CGFloat(max(backgroundRadialGradientRoundness,0.0001)))
      let backgroundRadialStartCenter: NSPoint = NSMakePoint(1024/2, CGFloat(1024.0/max(backgroundRadialGradientRoundness,0.0001)))
      let backgroundRadialStartRadius: Double = 1024.0/2
      let backgroundRadialToCenter: NSPoint = NSMakePoint(1024/2, -1024/2)
      let backgroundRadialToRadius: Double = 1024.0/2
      
      let gradient: NSGradient = NSGradient(starting: backgroundRadialGradientFromColor, ending: backgroundRadialGradientToColor)!
      gradient.draw(fromCenter: backgroundRadialStartCenter, radius: CGFloat(backgroundRadialStartRadius), toCenter: backgroundRadialToCenter, radius: CGFloat(backgroundRadialToRadius), options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation])
    }
    else if (renderBackgroundType == RKBackgroundType.image)
    {
      graphicsContext.cgContext.setFillColor(NSColor.white.cgColor)
      graphicsContext.cgContext.fill(NSMakeRect(0, 0, 1024, 1024))
    }
    
    
    let image: CGImage = context.makeImage()!
    
    NSGraphicsContext.restoreGraphicsState()
    
    return image
  }
  
  public func checkValidatyOfMeasurementPoints()
  {
    let validity = self.measurementTreeNodes.map { (measurementPoint) -> Bool in
      return (measurementPoint.structure.cell.minimumReplicaX <= measurementPoint.replicaPosition.x) &&
             (measurementPoint.structure.cell.maximumReplicaX >= measurementPoint.replicaPosition.x) &&
             (measurementPoint.structure.cell.minimumReplicaY <= measurementPoint.replicaPosition.y) &&
             (measurementPoint.structure.cell.maximumReplicaY >= measurementPoint.replicaPosition.y) &&
             (measurementPoint.structure.cell.minimumReplicaZ <= measurementPoint.replicaPosition.z) &&
             (measurementPoint.structure.cell.maximumReplicaZ >= measurementPoint.replicaPosition.z)
    }
    if validity.contains(false)
    {
      self.measurementTreeNodes = []
    }
  }
  

  // MARK: -
  // MARK: RKRenderDataSource protocol implementation

  
  public var numberOfScenes: Int
  {
    return self.sceneList.scenes.count
  }
  
  public func numberOfMovies(sceneIndex: Int) -> Int
  {
    return self.sceneList.scenes[sceneIndex].movies.flatMap{$0.selectedFrames}.count
  }
  
  public func renderStructuresForScene(_ i: Int) -> [RKRenderStructure]
  {
    let structures = self.sceneList.scenes[i].movies.flatMap{$0.selectedRenderFrames}
    
    return structures
  }
  
  public var renderStructures: [RKRenderStructure]
  {
    let structures = self.sceneList.scenes.flatMap{$0.movies}.flatMap{$0.selectedRenderFrames}
    
    return structures
  }
  
  
  
  public var renderMeasurementPoints: [RKInPerInstanceAttributesAtoms]
  {
    let structure = self.renderStructures
    return self.measurementTreeNodes.compactMap({ (atomInfo) -> RKInPerInstanceAttributesAtoms? in
      
      if !structure.contains(where: { return $0 === atomInfo.structure })
      {
        return nil
      }
     
      let w: Double = (atomInfo.copy.asymmetricParentAtom.isVisible && atomInfo.copy.asymmetricParentAtom.isVisibleEnabled) ? 1.0 : -1.0
      
      if let structure: RKRenderAtomSource = atomInfo.structure as? RKRenderAtomSource
      {
        let position = structure.CartesianPosition(for: atomInfo.copy.position + structure.cell.contentShift, replicaPosition: atomInfo.replicaPosition)
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(position.x), y: Float(position.y), z: Float(position.z), w: Float(w))
      
        let radius: Double = atomInfo.copy.asymmetricParentAtom.drawRadius
        let ambient: NSColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let diffuse: NSColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let specular: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      
        return RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius))
      }
      return nil
    })
  }
  
  public var renderMeasurementStructure: [RKRenderStructure]
  {
    return self.measurementTreeNodes.map{$0.structure}
  }
  
  //FIX 26-11-2018
  public var hasSelectedObjects: Bool
  {
    let structures = self.sceneList.scenes.flatMap{$0.movies}.flatMap{$0.frames}
    for structure in structures
    {
      if structure.hasSelectedObjects
      {
        return true
      }
    }
    return false
  }
  
  public var renderBoundingBoxSpheres: [RKInPerInstanceAttributesAtoms]
  {
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms]()
    
    let boundingBoxWidths: SIMD3<Double> = self.renderBoundingBox.widths
    
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for corner in self.renderBoundingBox.corners
    {
        let spherePosition: SIMD4<Float> = SIMD4<Float>(x: Float(corner.x), y: Float(corner.y), z: Float(corner.z), w: 1.0)
          
        let ambient: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let diffuse: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          
        data.append(RKInPerInstanceAttributesAtoms(position: spherePosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(scale)))
    }
    
    return data
  }
  
  public var renderBoundingBoxCylinders: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    
    let color1: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let color2: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    let boundingBox: SKBoundingBox = self.renderBoundingBox
    let boundingBoxWidths: SIMD3<Double> = boundingBox.widths
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for side in boundingBox.sides
    {
    
      let position1 = SIMD4<Float>(x: Float(side.0.x), y: Float(side.0.y), z: Float(side.0.z), w: 1.0)
      let position2 = SIMD4<Float>(x: Float(side.1.x), y: Float(side.1.y), z: Float(side.1.z), w: 1.0)
      
      data.append(RKInPerInstanceAttributesBonds(
        position1: position1,
        position2: position2,
        color1: SIMD4<Float>(color: color1),
        color2: SIMD4<Float>(color: color2),
        scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0)))
    }
    
    
    return data
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(ProjectStructureNode.classVersionNumber)
    
    encoder.encode(self.showBoundingBox)
    encoder.encode(self.renderBackgroundType.rawValue)
    
    if let renderBackgroundImage = renderBackgroundImage
    {
      let bitmapImageRep = NSBitmapImageRep(cgImage: renderBackgroundImage)
      if let pngData: Data = bitmapImageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
      {
        encoder.encode(pngData)
      }
    }
    else
    {
      encoder.encode(Data())
    }
    
    encoder.encode(self.renderBackgroundImageName)
    encoder.encode(self.renderBackgroundColor)
    encoder.encode(self.backgroundLinearGradientFromColor)
    encoder.encode(self.backgroundLinearGradientToColor)
    encoder.encode(self.backgroundRadialGradientFromColor)
    encoder.encode(self.backgroundRadialGradientToColor)
    encoder.encode(self.backgroundLinearGradientAngle)
    encoder.encode(self.backgroundRadialGradientRoundness)
    
    
    encoder.encode(self.renderImagePhysicalSizeInInches)
    encoder.encode(self.renderImageNumberOfPixels)
    encoder.encode(self.renderAspectRatio)
    encoder.encode(self.imageDPI.rawValue)
    encoder.encode(self.imageUnits.rawValue)
    encoder.encode(self.imageDimensions.rawValue)
    encoder.encode(self.renderImageQuality.rawValue)
    
    encoder.encode(self.numberOfFramesPerSecond)
    
    encoder.encode(self.renderCamera ?? RKCamera())
    
    encoder.encode(self.sceneList)
    
    super.binaryEncode(to: encoder)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    //self.init(name: "test", sceneList: SceneList.init(scenes: []))
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > ProjectStructureNode.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    showBoundingBox = try decoder.decode(Bool.self)
    renderBackgroundType = RKBackgroundType(rawValue: try decoder.decode(Int.self))!
    
    // read picture from PNG-data
    let dataLength: UInt32 = try decoder.decode(UInt32.self)
    if(dataLength != UInt32(0xffffffff))
    {
      //var data: [UInt8] = Array<UInt8>(repeating: 0, count: Int(dataLength))
      var imageData: Data = Data(count: Int(dataLength))
      
      try imageData.withUnsafeMutableBytes { (rawPtr: UnsafeMutableRawBufferPointer) in
        try decoder.read(Int(dataLength), into: rawPtr.baseAddress!)
      }
      if let dataProvider: CGDataProvider = CGDataProvider(data: imageData as CFData)
      {
        if let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        {
          debugPrint("picture read")
          self.renderBackgroundImage = image
          self.renderBackgroundCachedImage = image
        }
      }
    }
    
    self.renderBackgroundImageName = try decoder.decode(String.self)
    self.renderBackgroundColor = try decoder.decode(NSColor.self)
    self.backgroundLinearGradientFromColor = try decoder.decode(NSColor.self)
    self.backgroundLinearGradientToColor = try decoder.decode(NSColor.self)
    self.backgroundRadialGradientFromColor = try decoder.decode(NSColor.self)
    self.backgroundRadialGradientToColor = try decoder.decode(NSColor.self)
    self.backgroundLinearGradientAngle = try decoder.decode(Double.self)
    self.backgroundRadialGradientRoundness = try decoder.decode(Double.self)
    
    self.renderImagePhysicalSizeInInches = try decoder.decode(Double.self)
    self.renderImageNumberOfPixels = try decoder.decode(Int.self)
    self.renderAspectRatio = try decoder.decode(Double.self)
    self.imageDPI = try DPI(rawValue: decoder.decode(Int.self))!
    self.imageUnits = try Units(rawValue: decoder.decode(Int.self))!
    self.imageDimensions = try Dimensions(rawValue: decoder.decode(Int.self))!
    self.renderImageQuality = try RKImageQuality(rawValue: decoder.decode(Int.self))!
    
    self.numberOfFramesPerSecond = try decoder.decode(Int.self)
    
    self.renderCamera = try decoder.decode(RKCamera.self)
    self.sceneList = try decoder.decode(SceneList.self)
    
    try super.init(fromBinary: decoder)
  }
  
}
