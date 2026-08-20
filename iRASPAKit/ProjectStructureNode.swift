/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
import simd
import BinaryCodable
import SimulationKit
import RenderKit
import SymmetryKit
import MathKit

public final class ProjectStructureNode: ProjectNode, RKRenderDataSource, RKRenderCameraSource, NSSecureCoding
{
  private static var classVersionNumber: Int = 13
  
  public enum MovieType: Int
  {
    case frames = 0
    case rotationY = 1
    case rotationXYlemniscate = 2
  }
  
  public var sceneList: SceneList = SceneList()
  public var renderLights: [RKRenderLight] = RKRenderLight.defaultRig()

  /// The named style `renderLights` currently amounts to, kept in step by `recheckLightStyle`.
  public var renderLightStyle: RKLightStyle = .default
  
  public var showBoundingBox: Bool = false
  
  
  public override var infoPanelString: String
  {
    let numberOfAtomString: String = " (\(self.sceneList.totalNumberOfAtoms) atoms)"
    return self.displayName + numberOfAtomString
  }
  
  public var allIRASPAStructures: [iRASPAObject]
  {
    return sceneList.scenes.filter{$0.movies.count > 0}.flatMap{$0.movies.filter{$0.frames.count > 0}.flatMap{$0.allIRASPObjects}}
  }
  
  public var allObjects: [Object]
  {
    return sceneList.scenes.filter{$0.movies.count > 0}.flatMap{$0.movies.filter{$0.frames.count > 0}.flatMap{$0.allObjects}}
  }
  
  
  public var measurementTreeNodes: [(structure: RKRenderObject, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)] = []
  
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

  /// How exported pictures and movies are rendered. These sit with the other export settings rather
  /// than in the application preferences, because unlike the interactive sample counts, which say
  /// what this machine can keep up with, they are choices about the output.
  public var renderPictureRayTracing: Bool = false
  public var renderPictureSampleCount: Int = 1024
  public var renderPictureMaximumBounces: Int = 2

  /// How far occlusion leans towards darkening the direct lighting terms as well as the ambient one,
  /// where 0 is physically correct and 1 reproduces the older "Fancy" look. Applies to both the
  /// rasterizer and the path tracer, and to both interactive frames and exports: it is purely a look,
  /// with no bearing on render cost, so there is no reason for it to differ between them.
  public var renderAmbientOcclusionStrength: Double = 0.0

  /// Whether the rasterizer traces the scene to find out which lights actually reach each surface, so
  /// that geometry standing in the way casts a shadow. On by default, which is what makes the rasterized
  /// and path-traced views of a scene agree without having to be asked. It costs nothing under the
  /// legacy camera light, since a light on the view axis casts no shadow and the pass is skipped.
  ///
  /// An export honours this wherever it is opened, however slowly the machine traces: a picture is what
  /// the document says it is. Whether the render view spends a frame's worth of rays on the same thing
  /// is `RKRenderSettings.interactiveShadows`, which belongs to the machine.
  public var renderShadows: Bool = true

  /// Light arriving from the environment as a whole, which is why it sits beside the lights rather than
  /// inside one of them: a rig is free to turn every lamp off without the scene going black. Acts as a
  /// multiplier on each material's own ambient, which the representation style owns.
  public var renderSceneAmbientIntensity: Double = 1.0
  public var renderSceneAmbientColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

  public var numberOfFramesPerSecond: Int = 15
  
  public var movieType: MovieType = .rotationY
  
  public var renderCamera: RKCamera?
  
  public var renderAxes: RKGlobalAxes = RKGlobalAxes()
  
  public var ImageDotsPerInchValue: Double
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
    let frames: [Object] = self.sceneList.scenes.flatMap{$0.movies}.filter{$0.isVisible}.compactMap{($0.selectedFrame ?? $0.frames.first)?.object}
      
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
  
  public func renderStructuresForScene(_ i: Int) -> [RKRenderObject]
  {
    if (i>=0 && i<self.sceneList.scenes.count)
    {
      return self.sceneList.scenes[i].movies.flatMap{$0.selectedRenderFrames}
    }
    return []
  }
  
  public var renderStructures: [RKRenderObject]
  {
    let structures = self.sceneList.scenes.flatMap{$0.movies}.flatMap{$0.selectedRenderFrames}
    
    return structures
  }
  
  public func setPreviewDefaults(camera: RKCamera, size: CGSize)
  {
    // Critical: set the selection, otherwise no frames will be drawn
    setInitialSelectionIfNeeded()
    
    self.renderAxes.position = .none
      
    renderBackgroundType = .color
    renderBackgroundColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    renderBackgroundCachedImage = drawGradientCGImage()
    camera.resetPercentage = 0.95
    camera.resetForNewBoundingBox(renderBoundingBox)
      
    camera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
    camera.resetCameraDistance()
    
    let defaultColorSet: SKColorSet = SKColorSet(colorScheme: SKColorSets.ColorScheme.jmol)
    
    for iRASPAstructure in allIRASPAStructures
    {
      if iRASPAstructure.type == .protein || iRASPAstructure.type == .proteinCrystal || iRASPAstructure.type == .proteinCrystalSolvent
      {
        guard let structure: Structure = iRASPAstructure.object as? Structure else {continue}
        structure.setRepresentationStyle(style: .licorice)
        structure.setBondScaleFactor(0.1)
        structure.setRepresentationColorScheme(colorSet: defaultColorSet)
      }
    }
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
        //let position = structure.CartesianPosition(for: atomInfo.copy.position + structure.cell.contentShift, replicaPosition: atomInfo.replicaPosition)
        let position = structure.absoluteCartesianModelPosition(for: atomInfo.copy.position, replicaPosition: atomInfo.replicaPosition)
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(position.x), y: Float(position.y), z: Float(position.z), w: Float(w))
      
        let radius: Double = atomInfo.copy.asymmetricParentAtom.drawRadius
        let ambient: NSColor = NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let diffuse: NSColor = NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      
        return RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(0))
      }
      return nil
    })
  }
  
  public var renderMeasurementStructure: [RKRenderObject]
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
          
      data.append(RKInPerInstanceAttributesAtoms(position: spherePosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(scale), tag: UInt32(0)))
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
        scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
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

    encoder.encode(self.renderPictureRayTracing)
    encoder.encode(self.renderPictureSampleCount)
    encoder.encode(self.renderPictureMaximumBounces)
    encoder.encode(self.renderAmbientOcclusionStrength)
    encoder.encode(self.renderShadows)

    encoder.encode(self.numberOfFramesPerSecond)
    encoder.encode(self.movieType.rawValue)
    
    encoder.encode(self.renderCamera ?? RKCamera())
    
    encoder.encode(self.renderAxes)
    
    encoder.encode(self.renderLights.count)
    for light in self.renderLights
    {
      encoder.encode(light)
    }
    encoder.encode(self.renderLightStyle.rawValue)
    encoder.encode(self.renderSceneAmbientIntensity)
    encoder.encode(self.renderSceneAmbientColor)
    
    encoder.encode(self.sceneList)
    
    encoder.encode(Int(0x6f6b6180))
    
    super.binaryEncode(to: encoder)
  }
  
  /// Replaces the lights with those of a named style. Selecting `custom` keeps the current lights, since
  /// custom describes what is already there.
  public func setLightStyle(_ style: RKLightStyle)
  {
    if let rig: [RKRenderLight] = RKRenderLight.rig(for: style)
    {
      self.renderLights = rig
      self.renderAmbientOcclusionStrength = style.ambientOcclusionStrength
      self.renderSceneAmbientIntensity = style.sceneAmbientIntensity
      self.renderSceneAmbientColor = style.sceneAmbientColor
    }
    self.renderLightStyle = style
  }

  /// Called after any light, the scene ambient or the occlusion strength is edited, so the style name
  /// follows the lighting rather than going stale.
  public func recheckLightStyle()
  {
    self.renderLightStyle = RKRenderLight.style(matching: self.renderLights,
                                                sceneAmbientIntensity: self.renderSceneAmbientIntensity,
                                                sceneAmbientColor: self.renderSceneAmbientColor,
                                                ambientOcclusionStrength: self.renderAmbientOcclusionStrength)
  }

  // MARK: -
  // MARK: Binary Decodable support

  /// Up to version 9 each light carried its own ambient and the shaders added those together, so the level
  /// a document was saved with is recovered by adding them up here. Only lights that were switched on
  /// counted towards it. The colour is taken from the first light that contributed rather than blended,
  /// since the inspector only ever offered one ambient colour at a time in practice.
  ///
  /// Only ever called with lights that came out of a document. The rigs built in code no longer carry
  /// ambient at all, so handing one of those in would report darkness.
  private static func sceneAmbientGatheredFromLights(_ lights: [RKRenderLight]) -> (intensity: Double, color: NSColor)
  {
    var intensity: Double = 0.0
    var color: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    var haveColor: Bool = false

    for light in lights where light.isEnabled && light.ambientIntensity > 0.0
    {
      intensity += light.ambientIntensity
      if !haveColor
      {
        color = light.ambient
        haveColor = true
      }
    }

    // the sum could run past white, which the shaders allowed and a single slider cannot express
    return (min(intensity, 1.0), color)
  }

  /// Version 7 stored four lights as key, fill, rim and bounce. Those became eight photographic roles in
  /// a different order, so the stored lights are moved to the slots they were written as. A light keeps
  /// all of its own state, and slot order does not affect rendering, so a document looks the same after
  /// the move. Bounce has no counterpart among the new roles and is only carried over, into the butterfly
  /// slot, when it was switched on, so that a document relying on it still renders as it did.
  private static func lightsUpgradedFromVersion7(_ lights: [RKRenderLight]) -> [RKRenderLight]
  {
    var upgraded: [RKRenderLight] = RKRenderLight.standardRig()

    // whatever the old rig lit the scene with is complete in itself, so the new camera light stays off
    upgraded[0].isEnabled = false

    let slots: [Int] = [1, 2, 4, 7] // key, fill, rim/kicker, and bounce landing on butterfly
    for (index, slot) in slots.enumerated() where index < lights.count
    {
      if index < 3 || lights[index].isEnabled
      {
        upgraded[slot] = lights[index]
      }
    }
    return upgraded
  }

  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    //self.init(name: "test", sceneList: SceneList.init(scenes: []))
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > ProjectStructureNode.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.showBoundingBox = try decoder.decode(Bool.self)
    guard let renderBackgroundType = RKBackgroundType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.renderBackgroundType = renderBackgroundType
    
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
    guard let imageDPI = try DPI(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.imageDPI = imageDPI
    guard let imageUnits = try Units(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.imageUnits = imageUnits
    guard let imageDimensions = try Dimensions(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.imageDimensions = imageDimensions
    guard let renderImageQuality = try RKImageQuality(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.renderImageQuality = renderImageQuality

    if readVersionNumber >= 6 // introduced in version 6
    {
      self.renderPictureRayTracing = try decoder.decode(Bool.self)
      self.renderPictureSampleCount = try decoder.decode(Int.self)
      self.renderPictureMaximumBounces = try decoder.decode(Int.self)
      self.renderAmbientOcclusionStrength = try decoder.decode(Double.self)
    }

    if readVersionNumber >= 13 // introduced in version 13
    {
      self.renderShadows = try decoder.decode(Bool.self)
    }

    self.numberOfFramesPerSecond = try decoder.decode(Int.self)
    if readVersionNumber >= 5 // introduced in version 5
    {
      guard let movieType = try MovieType(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.movieType = movieType
    }
    
    self.renderCamera = try decoder.decode(RKCamera.self)
    
    if readVersionNumber >= 3 // introduced in version 3
    {
      self.renderAxes = try decoder.decode(RKGlobalAxes.self)
    }
    
    var storedLights: [RKRenderLight]? = nil
    if readVersionNumber >= 7 // introduced in version 7
    {
      // the count is stored rather than assumed, so the number of roles can change without a version bump
      let numberOfLights: Int = try decoder.decode(Int.self)
      var lights: [RKRenderLight] = []
      for _ in 0..<numberOfLights
      {
        lights.append(try decoder.decode(RKRenderLight.self))
      }

      if readVersionNumber == 7
      {
        lights = ProjectStructureNode.lightsUpgradedFromVersion7(lights)
      }

      if !lights.isEmpty
      {
        // the shaders read a fixed number of slots, so a short list is padded from the rig rather than
        // leaving the remainder to whatever a default light happens to be
        var rig: [RKRenderLight] = RKRenderLight.standardRig()
        for (index, light) in lights.enumerated() where index < rig.count
        {
          rig[index] = light
        }
        self.renderLights = rig
        storedLights = rig
      }
    }

    var storedLightStyle: Int? = nil
    if readVersionNumber >= 9 // introduced in version 9
    {
      storedLightStyle = try decoder.decode(Int.self)
    }

    if readVersionNumber >= 10 // introduced in version 10
    {
      self.renderSceneAmbientIntensity = try decoder.decode(Double.self)
      self.renderSceneAmbientColor = try decoder.decode(NSColor.self)
    }
    else if let stored: [RKRenderLight] = storedLights
    {
      // ambient used to belong to each light and be summed over them, so it is gathered off the lights the
      // document actually holds and it keeps the ambient level it was saved with
      let gathered = ProjectStructureNode.sceneAmbientGatheredFromLights(stored)
      self.renderSceneAmbientIntensity = gathered.intensity
      self.renderSceneAmbientColor = gathered.color
    }
    // a document from before the lights were stored has none to gather from, and what it was given instead
    // was a light carrying a full ambient, so the neutral default above is what it rendered with. Reading
    // the current default rig here would report no ambient at all and take the Fancy style, which is lit by
    // ambient alone, to black.

    if let style: Int = storedLightStyle
    {
      self.renderLightStyle = RKLightStyle(rawValue: style) ?? .custom
    }
    else
    {
      // an older document never named its lighting, so the name is worked out from the lighting itself,
      // which is why this waits until the ambient above has been settled
      self.renderLightStyle = RKRenderLight.style(matching: self.renderLights,
                                                  sceneAmbientIntensity: self.renderSceneAmbientIntensity,
                                                  sceneAmbientColor: self.renderSceneAmbientColor,
                                                  ambientOcclusionStrength: self.renderAmbientOcclusionStrength)
    }

    if readVersionNumber == 11
    {
      // Version 11 held one setting for the whole scene. It moved onto the structures, which each
      // carry their own now, so the value is read past and dropped.
      _ = try decoder.decode(Int.self)
    }
    
    self.sceneList = try decoder.decode(SceneList.self)
    
    if readVersionNumber >= 4 // introduced in version 4
    {
      let magicNumber = try decoder.decode(Int.self)
      if magicNumber != Int(0x6f6b6180)
      {
        debugPrint("ProjectStructureNode Inconsistency error (bug)")
      }
    }
    
    try super.init(fromBinary: decoder)
    
    // render the bacground from color, gradient, or picture into the cached image that is used for rendering
    //renderBackgroundCachedImage = drawGradientCGImage()
  }
  
  // MARK: -
  // MARK: NSSecureCoding support
  
  /// The NSSecureCoding protocol is convenient to send ProjectStructureNode Objects over XPC.
  /// XPC is used for picture and movie creation for example.
  
  public static var supportsSecureCoding: Bool = true
  
  public func encode(with coder: NSCoder)
  {
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(self)
    let data: Data = Data(binaryEncoder.data)
    coder.encode(data, forKey: "data")
    
    // save the selection
    let indexPaths: [IndexPath] = self.sceneList.selectionIndexPaths
    let binarySelectionEncoder: BinaryEncoder = BinaryEncoder()
    binarySelectionEncoder.encode(indexPaths)
    let selectionData: Data = Data(binarySelectionEncoder.data)
    coder.encode(selectionData, forKey: "selection")
  }
  
  public convenience required init?(coder decoder: NSCoder)
  {
    guard let data: Data = decoder.decodeObject(of: NSData.self, forKey: "data") as Data?  else {return nil}
    let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
    do
    {
      try self.init(fromBinary: binaryDecoder)
    }
    catch
    {
      return nil
    }
    
    // restore selection    
    guard let selectionData: Data = decoder.decodeObject(of: NSData.self, forKey: "selection") as Data? else {return nil}
    let binarySelectionDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](selectionData))
    let indexPaths: [IndexPath] = (try? binarySelectionDecoder.decode([IndexPath].self)) ?? []
    self.sceneList.selectionIndexPaths = indexPaths
  }
}
