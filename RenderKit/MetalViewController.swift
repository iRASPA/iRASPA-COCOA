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

import Cocoa
import MetalKit
import SimulationKit
import SymmetryKit
import AVFoundation
import CoreMedia
import CoreVideo

public class MetalViewController: NSViewController, RenderViewController
{
  var device: MTLDevice? = nil
  var commandQueue: MTLCommandQueue! = nil
  var defaultLibrary: MTLLibrary! = nil
  var maximumNumberOfSamples: Int = 4
  
  public weak var renderDataSource: RKRenderDataSource? = nil
  {
    didSet
    {
      if let metalView = self.view as? MetalView
      {
        metalView.renderDataSource = renderDataSource
        metalView.renderer.renderDataSource = renderDataSource
      }
    }
  }
  
  public weak var renderCameraSource: RKRenderCameraSource? = nil
  {
    didSet
    {
      if let metalView = self.view as? MetalView
      {
        metalView.renderCameraSource = renderCameraSource
        metalView.renderer.renderCameraSource = renderCameraSource
      }
    }
  }
  
  override public init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  convenience  init()
  {
    self.init(nibName: nil, bundle: Bundle(for: MetalViewController.self))
  }
  
  // called when present in a NIB-file
  public required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
  }
  
  deinit
  {
    //Swift.print("deinit: MetalViewController")
  }
  
  public override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // the metal default library is not in mainBundle, but in the local framework bundle
    let bundle: Bundle = Bundle(for: MetalView.self)
    
    if let newDevice = MTLCreateSystemDefaultDevice(),
       let file: String = bundle.path(forResource: "default", ofType: "metallib"),
       let library: MTLLibrary = try? newDevice.makeLibrary(filepath: file),
       let newCommandQueue = newDevice.makeCommandQueue()
    {
      device = newDevice
      commandQueue = newCommandQueue
    
      (view as? MetalView)?.setup(device: newDevice, defaultLibrary: library, commandQueue: commandQueue)
    }
  }
  
  public override func viewWillAppear()
  {
    super.viewWillAppear()
  }
  
  public override func viewDidAppear()
  {
    super.viewDidAppear()
  }

  public var viewBounds: CGSize
  {
    let size: CGSize =  (self.view as? MetalView)?.drawableSize ?? CGSize(width: 800.0, height: 600.0)
    return size
  }
  
  public func reloadData()
  {
    (self.view as? MetalView)?.reloadData()
  }
  
  public func reloadData(ambientOcclusionQuality: RKRenderQuality)
  {
    (self.view as? MetalView)?.reloadData(ambientOcclusionQuality: ambientOcclusionQuality)
  }
  
  public func reloadRenderData()
  {
    (self.view as? MetalView)?.reloadRenderData()
  }
  
  public func reloadBoundingBoxData()
  {
    (self.view as? MetalView)?.reloadBoundingBoxData()
  }
  
  public func reloadRenderDataSelectedAtoms()
  {
    (self.view as? MetalView)?.reloadRenderDataSelectedAtoms()
  }
  
  public func reloadRenderMeasurePointsData()
  {
    (self.view as? MetalView)?.reloadRenderMeasurePointsData()
  }
  
    
  public var renderQuality: RKRenderQuality
  {
    get
    {
      return (self.view as? MetalView)?.renderer.renderQuality ?? .high
    }
    set(newValue)
    {
      (self.view as? MetalView)?.renderer.renderQuality = newValue
    }
  }
  
  public func redraw()
  {
    self.view.layer?.setNeedsDisplay()
  }
  
  public func pickPoint(_ point: NSPoint) ->  [Int32]
  {
    return (self.view as? MetalView)?.pickPoint(point) ?? []
  }
  
  public func pickDepth(_ point: NSPoint) ->  Float?
  {
    return (self.view as? MetalView)?.pickDepth(point)
  }
  
  public func makePicture(size: NSSize, imageQuality: RKImageQuality) -> Data
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource
    {
      // create Ambient Occlusion in higher quality
      self.invalidateCachedAmbientOcclusionTexture(crystalProjectData.renderStructures)
      
      if let data: Data = (self.view as? MetalView)?.drawSceneToTexture(size: size, imageQuality: imageQuality)
      {
        let cgImage: CGImage
        switch(imageQuality)
        {
        case .rgb_16_bits, .cmyk_16_bits:
          let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Little.rawValue | CGImageAlphaInfo.last.rawValue)
          let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
          let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
          let bitsPerComponent: Int = 8 * 2
          let bitsPerPixel: Int = 32 * 2
          let bytesPerRow: Int = 4 * Int(size.width) * 2
          cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
        case .rgb_8_bits, .cmyk_8_bits:
          let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.first.rawValue)
          let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
          let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
          let bitsPerComponent: Int = 8
          let bitsPerPixel: Int = 32
          let bytesPerRow: Int = 4 * Int(size.width)
          cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
        }
        
        
        let imageRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = NSMakeSize(CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72), CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72.0 * Double(size.height) / Double(size.width)))
        
        switch(imageQuality)
        {
        case .rgb_8_bits, .rgb_16_bits:
          return imageRep.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.lzw, factor: 1.0)!
        case .cmyk_8_bits, .cmyk_16_bits:
          let imageRepCMYK: NSBitmapImageRep = imageRep.converting(to: NSColorSpace.genericCMYK, renderingIntent: NSColorRenderingIntent.perceptual)!
          imageRepCMYK.size = NSMakeSize(CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72), CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72))
          return imageRepCMYK.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.lzw, factor: 1.0)!
        }
      }
    }
    return Data()
  }

  public func makeCVPicture(_ pixelBuffer: CVPixelBuffer)
  {
    if let _: RKRenderDataSource = self.renderDataSource
    {
      
      let width: Int = CVPixelBufferGetWidth(pixelBuffer)
      let height: Int = CVPixelBufferGetHeight(pixelBuffer)
      
      (self.view as? MetalView)?.makeCVPicture(pixelBuffer, width: width, height: height)
    }
  }
  
  public func updateStructureUniforms()
  {
    (self.view as? MetalView)?.buildStructureUniforms()
  }
  
  public func updateIsosurfaceUniforms()
  {
    (self.view as? MetalView)?.updateIsosurfaceUniforms()
  }
  
  public func updateLightUniforms()
  {
    (self.view as? MetalView)?.updateLightUniforms()
  }

  public func updateVertexArrays()
  {
    (self.view as? MetalView)?.buildVertexBuffers()
  }
  
  public func updateAmbientOcclusion()
  {
    (self.view as? MetalView)?.updateAmbientOcclusionTextures()
  }
  
  public func updateAdsorptionSurface(completionHandler: @escaping ()->())
  {
    (self.view as? MetalView)?.updateAdsorptionSurface(completionHandler: completionHandler)
  }
  
  public func invalidateCachedAmbientOcclusionTextures()
  {
    (self.view as? MetalView)?.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeAllObjects()
  }
  
  public func invalidateCachedAmbientOcclusionTexture(_ structures: [RKRenderStructure])
  {
    for  structure in structures
    {
      (self.view as? MetalView)?.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeObject(forKey: structure)
    }
  }
  
  public func invalidateIsosurfaces()
  {
    (self.view as? MetalView)?.renderer.isosurfaceShader.cachedAdsorptionSurfaces[128]?.removeAllObjects()
  }
  
  public func invalidateIsosurface(_ structures: [RKRenderStructure])
  {
    for  structure in structures
    {
      (self.view as? MetalView)?.renderer.isosurfaceShader.cachedAdsorptionSurfaces[128]?.removeObject(forKey: structure)
    }
  }
  
  public func computeVoidFractions(structures: [RKRenderStructure])
  {
    guard let device = device else {return }
    
    for structure in structures
    {
      if let structure = structure as? RKRenderAdsorptionSurfaceSource
      {
        var data: [Float] = []
        
        let cell: SKCell = structure.cell
        let positions: [SIMD3<Double>] = structure.atomUnitCellPositions
        let potentialParameters: [SIMD2<Double>] = structure.potentialParameters
        let probeParameters: SIMD2<Double> = SIMD2<Double>(10.9, 2.64)
        
        let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
        let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell: cell.unitCell, numberOfReplicas: numberOfReplicas)
        
        data = framework.ComputeEnergyGrid(128, sizeY: 128, sizeZ: 128, probeParameter: probeParameters)
        
        structure.minimumGridEnergyValue = data.min()
        
        var numberOfLowEnergyValues: Double = 0.0
        for value in data
        {
          numberOfLowEnergyValues += exp(-(1.0/298.0) * Double(value))  // K_B  chosen as 1.0 (energy units are Kelvin)
        }
        structure.structureHeliumVoidFraction = Double(numberOfLowEnergyValues)/Double(128*128*128)
      }
    }
  }
  
  public func computeNitrogenSurfaceArea(structures: [RKRenderStructure])
  {
    guard let device = device else {return }
    guard let commandQueue = commandQueue else {return }
    
    for structure in structures
    {
      if let structure = structure as? RKRenderAdsorptionSurfaceSource
      {
        var data: [Float] = []
        
        let cell: SKCell = structure.cell
        let positions: [SIMD3<Double>] = structure.atomUnitCellPositions
        let potentialParameters: [SIMD2<Double>] = structure.potentialParameters
        let probeParameters: SIMD2<Double> = structure.frameworkProbeParameters
        
        let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
        let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell: cell.unitCell, numberOfReplicas: numberOfReplicas)
        
        data = framework.ComputeEnergyGrid(128, sizeY: 128, sizeZ: 128, probeParameter: probeParameters)
        
        let marchingCubes = SKMetalMarchingCubes(device: device, commandQueue: commandQueue)
        marchingCubes.isoValue = Float(-probeParameters.x)
        
        var surfaceVertexBuffer: MTLBuffer? = nil
        var numberOfTriangles: Int  = 0
        
        marchingCubes.prepareHistoPyramids(data, isosurfaceVertexBuffer: &surfaceVertexBuffer, numberOfTriangles: &numberOfTriangles)
        
        if numberOfTriangles > 0,
          let ptr: UnsafeMutableRawPointer = surfaceVertexBuffer?.contents()
        {
          let float4Ptr = ptr.bindMemory(to: SIMD4<Float>.self, capacity: Int(numberOfTriangles) * 3 * 3 )
          
          var totalArea: Double = 0.0
          for i in stride(from: 0, through: (Int(numberOfTriangles) * 3 * 3 - 1), by: 9)
          {
            let unitCell: double3x3 = cell.unitCell
            let v1 = unitCell * SIMD3<Double>(Double(float4Ptr[i].x),Double(float4Ptr[i].y),Double(float4Ptr[i].z))
            let v2 = unitCell * SIMD3<Double>(Double(float4Ptr[i+3].x),Double(float4Ptr[i+3].y),Double(float4Ptr[i+3].z))
            let v3 = unitCell * SIMD3<Double>(Double(float4Ptr[i+6].x),Double(float4Ptr[i+6].y),Double(float4Ptr[i+6].z))
            
            let v4: SIMD3<Double> = cross((v2-v1), (v3-v1))
            let area: Double = 0.5 * simd.length(v4)
            if area.isFinite && fabs(area) < 1.0
            {
              totalArea += area
            }
            
            structure.structureNitrogenSurfaceArea = totalArea
          }
        }
        else
        {
          structure.structureNitrogenSurfaceArea = 0.0
        }
      }
    }
  }
  
  public func reloadBackgroundImage()
  {
    (self.view as? MetalView)?.reloadBackgroundImage()
  }
}
