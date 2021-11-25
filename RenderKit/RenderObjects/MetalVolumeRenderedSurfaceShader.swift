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
import LogViewKit
import SymmetryKit
import SimulationKit
import simd

class MetalEnergyVolumeRenderedSurfaceShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var transparentPipeLine: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer? = nil
  var indexBuffer: MTLBuffer? = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  var textureData: [[MTLTexture?]] = []
  var samplerTextureData: MTLSamplerState! = nil
  var textureTransferFunction: MTLTexture? = nil
  var samplerTextureTransferData: MTLSamplerState! = nil
  
  
  let cachedEnergyGrids: [Int: NSCache<AnyObject, AnyObject>] = [32: NSCache(), 64: NSCache(), 128: NSCache(), 256: NSCache(), 512: NSCache()]
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor()
    
    if let sampler = pSamplerDescriptor
    {
      sampler.minFilter             = MTLSamplerMinMagFilter.linear
      sampler.magFilter             = MTLSamplerMinMagFilter.linear
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.repeat
      sampler.tAddressMode          = MTLSamplerAddressMode.repeat
      sampler.rAddressMode          = MTLSamplerAddressMode.repeat
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
      samplerTextureData = device.makeSamplerState(descriptor: sampler)
    }
    else
    {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    
    if let sampler = pSamplerDescriptor
    {
      sampler.minFilter             = MTLSamplerMinMagFilter.linear
      sampler.magFilter             = MTLSamplerMinMagFilter.linear
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
      samplerTextureTransferData = device.makeSamplerState(descriptor: sampler)
    }
    else
    {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    
    
    let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor()
    textureDescriptor.textureType = .type1D
    textureDescriptor.pixelFormat = .rgba32Float
    textureDescriptor.width = 256
    textureDescriptor.usage = .shaderRead
    textureDescriptor.storageMode = MTLStorageMode.managed
    guard let texture = device.makeTexture(descriptor: textureDescriptor) else {return}
    texture.label = "Volume rendering transfer function texture"
    textureTransferFunction = texture
    
    textureTransferFunction?.replace(region: MTLRegionMake1D(0, 256),
                    mipmapLevel: 0,
                    withBytes: MetalEnergyVolumeRenderedSurfaceShader.transferFunction,
                    bytesPerRow: 256 * MemoryLayout<Float>.size * 4)
    
    let transparentDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepthStateDescriptor.isDepthWriteEnabled = true
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepthStateDescriptor)
    
    let transparentPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    transparentPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    transparentPipelineDescriptor.vertexFunction = library.makeFunction(name: "VolumeRenderedSurfaceVertexShader")!
    transparentPipelineDescriptor.sampleCount = maximumNumberOfSamples
    transparentPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    transparentPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    transparentPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    transparentPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    transparentPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    transparentPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    transparentPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    transparentPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    transparentPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    transparentPipelineDescriptor.fragmentFunction = library.makeFunction(name: "VolumeRenderedSurfaceFragmentShader")!
    transparentPipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.transparentPipeLine = try device.makeRenderPipelineState(descriptor: transparentPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }

  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let unitCube: MetalUnitCubeGeometry = MetalUnitCubeGeometry()
    vertexBuffer = device.makeBuffer(bytes: unitCube.vertices, length:MemoryLayout<RKVertex>.stride * unitCube.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: unitCube.indices, length:MemoryLayout<UInt16>.stride * unitCube.indices.count, options:.storageModeManaged)
    
    self.textureData = []
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        var textures: [MTLTexture?] = []
        let structures: [RKRenderObject] = self.renderStructures[i]
        for _ in structures
        {
          textures.append(nil)
        }
        self.textureData.append(textures)
      }
    }
  }
  
  
  public func renderVolumeRenderedSurfacesWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, depthTexture: MTLTexture!, size: CGSize)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      commandEncoder.setRenderPipelineState(transparentPipeLine)
      commandEncoder.setCullMode(MTLCullMode.back)
      
      // for transparent surface:
      // disable depth-buffer updates (depth-buffer testing is still active)
      // the depth buffer maintains the relationship between opaque and transparent objects,
      // but does not prevent the transparent objects from occluding each other.
      commandEncoder.setDepthStencilState(self.transparentDepthState)
      
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(isosurfaceUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(isosurfaceUniformBuffers, offset: 0, index: 2)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderAdsorptionSurfaceSource = structure as? RKRenderAdsorptionSurfaceSource,
             let vertexBuffer = vertexBuffer,
             let indexBuffer = indexBuffer,
             let texture = textureData[i][j],
             let textureTransferFunction = textureTransferFunction,
             let depthTexture = depthTexture,
             structure.adsorptionSurfaceRenderingMethod == .volumeRendering
          {
            if (structure.isVisible && structure.drawAdsorptionSurface)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBufferOffset(index*MemoryLayout<RKStructureUniforms>.stride, index: 2)
              commandEncoder.setVertexBufferOffset(index*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index*MemoryLayout<RKStructureUniforms>.stride, index: 1)
              commandEncoder.setFragmentBufferOffset(index*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 2)
              commandEncoder.setFragmentTexture(texture, index: 0)
              commandEncoder.setFragmentTexture(textureTransferFunction, index: 1)
              commandEncoder.setFragmentTexture(depthTexture, index: 2)
              commandEncoder.setFragmentSamplerState(samplerTextureData, index: 0)
              commandEncoder.setFragmentSamplerState(samplerTextureTransferData, index: 1)
              
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 34, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            }
          }
          index = index + 1
        }
      }
    }
  }
  
  func metalBuffer(_ buffer: [[MTLBuffer?]], sceneIndex: Int, movieIndex: Int) -> MTLBuffer?
  {
    if sceneIndex < buffer.count
    {
      if movieIndex < buffer[sceneIndex].count
      {
        return buffer[sceneIndex][movieIndex]
      }
    }
    return nil
  }
  
  public func updateAdsorptionSurface(device: MTLDevice, commandQueue: MTLCommandQueue, windowController: NSWindowController?, completionHandler: @escaping () -> ())
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      var info: mach_timebase_info_data_t = mach_timebase_info_data_t()
      mach_timebase_info(&info)
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderAdsorptionSurfaceSource, structure.drawAdsorptionSurface
          {
            let size: Int = structure.adsorptionSurfaceSize
            var data: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0.0,0.0,0.0,0.0), count: size*size*size)
            
            if let cachedVersion: Data = cachedEnergyGrids[size]?.object(forKey: structure) as? Data
            {
              data = [SIMD4<Float>](repeating: SIMD4<Float>(0.0,0.0,0.0,0.0), count: cachedVersion.count / MemoryLayout<Float>.stride)
              let _ = data.withUnsafeMutableBytes { cachedVersion.copyBytes(to: $0, from: 0..<cachedVersion.count)
              }
              
              LogQueue.shared.verbose(destination: windowController, message: "Loading the \(structure.displayName)-Metal energy/gradient grid from cache")
            }
            else
            {
              let startTime: UInt64  = mach_absolute_time()
              
              let cell: SKCell = structure.cell
              let positions: [SIMD3<Double>] = structure.atomUnitCellPositions
              let potentialParameters: [SIMD2<Double>] = structure.potentialParameters
              let probeParameters: SIMD2<Double> = structure.adsorptionSurfaceProbeParameters
              let size: Int = structure.adsorptionSurfaceSize
              
              let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
              let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell: cell.unitCell, numberOfReplicas: numberOfReplicas)
              
              let energyData: [Float] = framework.ComputeEnergyGrid(size, sizeY: size, sizeZ: size, probeParameter: probeParameters)
              let minimumGridEnergyValue: Float = energyData.min() ?? 0.0
              
              let endTime: UInt64  = mach_absolute_time()
              
              let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000001
              LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal energy/gradient grid is \(time) milliseconds")
              
              let startTimeGradient: UInt64  = mach_absolute_time()
              for x in 0..<size
              {
                for y in 0..<size
                {
                  for z in 0..<size
                  {
                    let temp: Float = 1000.0*(1.0/300.0)*(energyData[x+size*y+z*size*size]-minimumGridEnergyValue);
                    var value: Float = 0.0;
                    if(temp>54000)
                    {
                      value = 1.0;
                    }
                    else
                    {
                      value=temp/65535.0;
                    }
                    let xi: Int = Int(Float(x) + 0.5)
                    let xf: Float = Float(x) + 0.5 - Float(xi)
                    let xd0: Float = energyData[((xi-1 + size) % size)+y*size+z*size*size]
                    let xd1: Float = energyData[(xi)+y*size+z*size*size]
                    let xd2: Float = energyData[((xi+1 + size) % size)+y*size+z*size*size]
                    let gx: Float = (xd1 - xd0) * (1.0 - xf) + (xd2 - xd1) * xf

                    let yi: Int = Int(Float(y) + 0.5)
                    let yf: Float = Float(y) + 0.5 - Float(yi)
                    let yd0: Float = energyData[x + ((yi-1+size) % size)*size+z*size*size]
                    let yd1: Float = energyData[x + (yi)*size+z*size*size]
                    let yd2: Float = energyData[x + ((yi+1+size) % size)*size+z*size*size]
                    let gy: Float = (yd1 - yd0) * (1.0 - yf) + (yd2 - yd1) * yf

                    let zi: Int = Int(Float(z) + 0.5)
                    let zf: Float = Float(z) + 0.5 - Float(zi)
                    let zd0: Float =  energyData[x+y*size+((zi-1+size) % size)*size*size]
                    let zd1: Float =  energyData[x+y*size+(zi)*size*size]
                    let zd2: Float =  energyData[x+y*size+((zi+1+size) % size)*size*size]
                    let gz: Float =  (zd1 - zd0) * (1.0 - zf) + (zd2 - zd1) * zf
                    
                    data[x+size*y+z*size*size] = SIMD4<Float>(value, gx, gy, gz)
                  }
                }
              }
              let endTimeGradient: UInt64  = mach_absolute_time()
              let gradientTime: Double = Double((endTimeGradient - startTimeGradient) * UInt64(info.numer)) / Double(info.denom) * 0.000001
              LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal gradient computation is \(gradientTime) milliseconds")
              
              if let cache: NSCache = cachedEnergyGrids[size]
              {
                let cachedData: Data = data.withUnsafeMutableBufferPointer{Data(buffer: $0)}
                cache.setObject(cachedData as AnyObject, forKey: structure)
              }
            }
            
            let startTime: UInt64  = mach_absolute_time()
            let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor()
            textureDescriptor.textureType = .type3D
            textureDescriptor.pixelFormat = .rgba32Float
            textureDescriptor.width = size
            textureDescriptor.height = size
            textureDescriptor.depth = size
            textureDescriptor.usage = .shaderRead
            textureDescriptor.storageMode = MTLStorageMode.managed
            guard let texture = device.makeTexture(descriptor: textureDescriptor) else {return}
            texture.label = "Energy/gradient 3D texture"
            textureData[i][j] = texture
            
            texture.replace(region: MTLRegionMake3D(0, 0, 0, size, size, size),
                            mipmapLevel: 0,
                            slice: 0,
                            withBytes: data,
                            bytesPerRow: size * MemoryLayout<Float>.size * 4,
                            bytesPerImage: size * size * MemoryLayout<Float>.size * 4)
            
            
            switch(size)
            {
            case 128:
              break
            case 256:
              break
            default:
              break
            }
            
            let endTime: UInt64  = mach_absolute_time()
            
            let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000001
            
            LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal energy surface is \(time) milliseconds")
          }
        }
      }
    }
  }
  
  static let transferFunction: [SIMD4<Float>] =
  [
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.0252),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.1148),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.2044),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.294),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.3836),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.4732),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.5628),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.6524),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.701029),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.703223),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.705417),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.707611),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.709806),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.712),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.714194),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.716389),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.718583),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.720777),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.722971),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.725166),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.72736),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.729554),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.731749),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.733943),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.736137),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.738331),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.740526),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.74272),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.744914),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.747109),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.749303),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.751497),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.753691),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.755886),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.75808),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.760274),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.762469),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.764663),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.766857),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.769051),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.771246),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.77344),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.775634),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.777829),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.780023),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.782217),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.784411),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.786606),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.7888),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.790994),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.793189),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.795383),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.797577),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.799771),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.801966),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.80416),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.806354),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.808549),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.810743),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.812937),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.815131),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.817326),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.81952),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.821714),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.823909),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.826103),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.828297),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.830491),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.832686),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.83488),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.837074),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.839269),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.841463),
    SIMD4<Float>(0.8, 0.7, 0.2, 0.843657),
    SIMD4<Float>(0.799556, 0.699822, 0.200711, 0.845851),
    SIMD4<Float>(0.792444, 0.696978, 0.212089, 0.848046),
    SIMD4<Float>(0.785333, 0.694133, 0.223467, 0.85024),
    SIMD4<Float>(0.778222, 0.691289, 0.234844, 0.852434),
    SIMD4<Float>(0.771111, 0.688444, 0.246222, 0.854629),
    SIMD4<Float>(0.764, 0.6856, 0.2576, 0.856823),
    SIMD4<Float>(0.756889, 0.682756, 0.268978, 0.859017),
    SIMD4<Float>(0.749778, 0.679911, 0.280356, 0.861211),
    SIMD4<Float>(0.742667, 0.677067, 0.291733, 0.863406),
    SIMD4<Float>(0.735556, 0.674222, 0.303111, 0.8656),
    SIMD4<Float>(0.728444, 0.671378, 0.314489, 0.867794),
    SIMD4<Float>(0.721333, 0.668533, 0.325867, 0.869989),
    SIMD4<Float>(0.714222, 0.665689, 0.337244, 0.872183),
    SIMD4<Float>(0.707111, 0.662844, 0.348622, 0.874377),
    SIMD4<Float>(0.7, 0.66, 0.36, 0.876571),
    SIMD4<Float>(0.692889, 0.657156, 0.371378, 0.878766),
    SIMD4<Float>(0.685778, 0.654311, 0.382756, 0.88096),
    SIMD4<Float>(0.678667, 0.651467, 0.394133, 0.883154),
    SIMD4<Float>(0.671556, 0.648622, 0.405511, 0.885349),
    SIMD4<Float>(0.664444, 0.645778, 0.416889, 0.887543),
    SIMD4<Float>(0.657333, 0.642933, 0.428267, 0.889737),
    SIMD4<Float>(0.650222, 0.640089, 0.439644, 0.891931),
    SIMD4<Float>(0.643111, 0.637244, 0.451022, 0.894126),
    SIMD4<Float>(0.636, 0.6344, 0.4624, 0.89632),
    SIMD4<Float>(0.628889, 0.631556, 0.473778, 0.898514),
    SIMD4<Float>(0.621778, 0.628711, 0.485156, 0.900709),
    SIMD4<Float>(0.614667, 0.625867, 0.496533, 0.902903),
    SIMD4<Float>(0.607556, 0.623022, 0.507911, 0.905097),
    SIMD4<Float>(0.600444, 0.620178, 0.519289, 0.907291),
    SIMD4<Float>(0.593333, 0.617333, 0.530667, 0.909486),
    SIMD4<Float>(0.586222, 0.614489, 0.542044, 0.91168),
    SIMD4<Float>(0.579111, 0.611644, 0.553422, 0.913874),
    SIMD4<Float>(0.572, 0.6088, 0.5648, 0.916069),
    SIMD4<Float>(0.564889, 0.605956, 0.576178, 0.918263),
    SIMD4<Float>(0.557778, 0.603111, 0.587556, 0.920457),
    SIMD4<Float>(0.550667, 0.600267, 0.598933, 0.922651),
    SIMD4<Float>(0.543556, 0.597422, 0.610311, 0.924846),
    SIMD4<Float>(0.536444, 0.594578, 0.621689, 0.92704),
    SIMD4<Float>(0.529333, 0.591733, 0.633067, 0.929234),
    SIMD4<Float>(0.522222, 0.588889, 0.644444, 0.931429),
    SIMD4<Float>(0.515111, 0.586044, 0.655822, 0.933623),
    SIMD4<Float>(0.508, 0.5832, 0.6672, 0.935817),
    SIMD4<Float>(0.500889, 0.580356, 0.678578, 0.938011),
    SIMD4<Float>(0.493778, 0.577511, 0.689956, 0.940206),
    SIMD4<Float>(0.486667, 0.574667, 0.701333, 0.9424),
    SIMD4<Float>(0.479556, 0.571822, 0.712711, 0.944594),
    SIMD4<Float>(0.472444, 0.568978, 0.724089, 0.946789),
    SIMD4<Float>(0.465333, 0.566133, 0.735467, 0.948983),
    SIMD4<Float>(0.458222, 0.563289, 0.746844, 0.951177),
    SIMD4<Float>(0.451111, 0.560444, 0.758222, 0.953371),
    SIMD4<Float>(0.444, 0.5576, 0.7696, 0.955566),
    SIMD4<Float>(0.436889, 0.554756, 0.780978, 0.95776),
    SIMD4<Float>(0.429778, 0.551911, 0.792356, 0.959954),
    SIMD4<Float>(0.422667, 0.549067, 0.803733, 0.962149),
    SIMD4<Float>(0.415556, 0.546222, 0.815111, 0.964343),
    SIMD4<Float>(0.408444, 0.543378, 0.826489, 0.966537),
    SIMD4<Float>(0.401333, 0.540533, 0.837867, 0.968731),
    SIMD4<Float>(0.394222, 0.537689, 0.849244, 0.970926),
    SIMD4<Float>(0.387111, 0.534844, 0.860622, 0.97312),
    SIMD4<Float>(0.38, 0.532, 0.872, 0.975314),
    SIMD4<Float>(0.372889, 0.529156, 0.883378, 0.977509),
    SIMD4<Float>(0.365778, 0.526311, 0.894756, 0.979703),
    SIMD4<Float>(0.358667, 0.523467, 0.906133, 0.981897),
    SIMD4<Float>(0.351556, 0.520622, 0.917511, 0.984091),
    SIMD4<Float>(0.344444, 0.517778, 0.928889, 0.986286),
    SIMD4<Float>(0.337333, 0.514933, 0.940267, 0.98848),
    SIMD4<Float>(0.330222, 0.512089, 0.951644, 0.990674),
    SIMD4<Float>(0.323111, 0.509244, 0.963022, 0.992869),
    SIMD4<Float>(0.316, 0.5064, 0.9744, 0.995063),
    SIMD4<Float>(0.308889, 0.503556, 0.985778, 0.997257),
    SIMD4<Float>(0.301778, 0.500711, 0.997156, 0.999451),
    SIMD4<Float>(0.3, 0.5, 1, 0.99232),
    SIMD4<Float>(0.3, 0.5, 1, 0.98208),
    SIMD4<Float>(0.3, 0.5, 1, 0.97184),
    SIMD4<Float>(0.3, 0.5, 1, 0.9616),
    SIMD4<Float>(0.3, 0.5, 1, 0.95136),
    SIMD4<Float>(0.3, 0.5, 1, 0.94112),
    SIMD4<Float>(0.3, 0.5, 1, 0.93088),
    SIMD4<Float>(0.3, 0.5, 1, 0.92064),
    SIMD4<Float>(0.3, 0.5, 1, 0.9104),
    SIMD4<Float>(0.3, 0.5, 1, 0.90016),
    SIMD4<Float>(0.3, 0.5, 1, 0.88992),
    SIMD4<Float>(0.3, 0.5, 1, 0.87968),
    SIMD4<Float>(0.3, 0.5, 1, 0.86944),
    SIMD4<Float>(0.3, 0.5, 1, 0.8592),
    SIMD4<Float>(0.3, 0.5, 1, 0.84896),
    SIMD4<Float>(0.3, 0.5, 1, 0.83872),
    SIMD4<Float>(0.3, 0.5, 1, 0.82848),
    SIMD4<Float>(0.3, 0.5, 1, 0.81824),
    SIMD4<Float>(0.3, 0.5, 1, 0.808),
    SIMD4<Float>(0.3, 0.5, 1, 0.79776),
    SIMD4<Float>(0.3, 0.5, 1, 0.78752),
    SIMD4<Float>(0.3, 0.5, 1, 0.77728),
    SIMD4<Float>(0.3, 0.5, 1, 0.76704),
    SIMD4<Float>(0.3, 0.5, 1, 0.7568),
    SIMD4<Float>(0.3, 0.5, 1, 0.74656),
    SIMD4<Float>(0.3, 0.5, 1, 0.73632),
    SIMD4<Float>(0.3, 0.5, 1, 0.72608),
    SIMD4<Float>(0.3, 0.5, 1, 0.71584),
    SIMD4<Float>(0.3, 0.5, 1, 0.7056),
    SIMD4<Float>(0.3, 0.5, 1, 0.69536),
    SIMD4<Float>(0.3, 0.5, 1, 0.68512),
    SIMD4<Float>(0.3, 0.5, 1, 0.67488),
    SIMD4<Float>(0.3, 0.5, 1, 0.66464),
    SIMD4<Float>(0.3, 0.5, 1, 0.6544),
    SIMD4<Float>(0.3, 0.5, 1, 0.64416),
    SIMD4<Float>(0.3, 0.5, 1, 0.63392),
    SIMD4<Float>(0.3, 0.5, 1, 0.62368),
    SIMD4<Float>(0.3, 0.5, 1, 0.61344),
    SIMD4<Float>(0.3, 0.5, 1, 0.6032),
    SIMD4<Float>(0.3, 0.5, 1, 0.59296),
    SIMD4<Float>(0.3, 0.5, 1, 0.58272),
    SIMD4<Float>(0.3, 0.5, 1, 0.57248),
    SIMD4<Float>(0.3, 0.5, 1, 0.56224),
    SIMD4<Float>(0.3, 0.5, 1, 0.552),
    SIMD4<Float>(0.3, 0.5, 1, 0.54176),
    SIMD4<Float>(0.3, 0.5, 1, 0.53152),
    SIMD4<Float>(0.3, 0.5, 1, 0.52128),
    SIMD4<Float>(0.3, 0.5, 1, 0.51104),
    SIMD4<Float>(0.3, 0.5, 1, 0.5008),
    SIMD4<Float>(0.3, 0.5, 1, 0.49056),
    SIMD4<Float>(0.3, 0.5, 1, 0.48032),
    SIMD4<Float>(0.3, 0.5, 1, 0.47008),
    SIMD4<Float>(0.3, 0.5, 1, 0.45984),
    SIMD4<Float>(0.3, 0.5, 1, 0.4496),
    SIMD4<Float>(0.3, 0.5, 1, 0.43936),
    SIMD4<Float>(0.3, 0.5, 1, 0.42912),
    SIMD4<Float>(0.3, 0.5, 1, 0.41888),
    SIMD4<Float>(0.3, 0.5, 1, 0.40864),
    SIMD4<Float>(0.3, 0.5, 1, 0.3984),
    SIMD4<Float>(0.3, 0.5, 1, 0.38816),
    SIMD4<Float>(0.3, 0.5, 1, 0.37792),
    SIMD4<Float>(0.3, 0.5, 1, 0.36768),
    SIMD4<Float>(0.3, 0.5, 1, 0.35744),
    SIMD4<Float>(0.3, 0.5, 1, 0.3472),
    SIMD4<Float>(0.3, 0.5, 1, 0.33696),
    SIMD4<Float>(0.3, 0.5, 1, 0.32672),
    SIMD4<Float>(0.3, 0.5, 1, 0.31648),
    SIMD4<Float>(0.3, 0.5, 1, 0.30624),
    SIMD4<Float>(0.3, 0.5, 1, 0.296),
    SIMD4<Float>(0.3, 0.5, 1, 0.28576),
    SIMD4<Float>(0.3, 0.5, 1, 0.27552),
    SIMD4<Float>(0.3, 0.5, 1, 0.26528),
    SIMD4<Float>(0.3, 0.5, 1, 0.25504),
    SIMD4<Float>(0.3, 0.5, 1, 0.2448),
    SIMD4<Float>(0.3, 0.5, 1, 0.23456),
    SIMD4<Float>(0.3, 0.5, 1, 0.22432),
    SIMD4<Float>(0.3, 0.5, 1, 0.21408),
    SIMD4<Float>(0.3, 0.5, 1, 0.20384),
    SIMD4<Float>(0.3, 0.5, 1, 0.1936),
    SIMD4<Float>(0.3, 0.5, 1, 0.18336),
    SIMD4<Float>(0.3, 0.5, 1, 0.17312),
    SIMD4<Float>(0.3, 0.5, 1, 0.16288),
    SIMD4<Float>(0.3, 0.5, 1, 0.15264),
    SIMD4<Float>(0.3, 0.5, 1, 0.1424),
    SIMD4<Float>(0.3, 0.5, 1, 0.13216),
    SIMD4<Float>(0.3, 0.5, 1, 0.12192),
    SIMD4<Float>(0.3, 0.5, 1, 0.11168),
    SIMD4<Float>(0.3, 0.5, 1, 0.10144),
    SIMD4<Float>(0.3, 0.5, 1, 0.0912),
    SIMD4<Float>(0.3, 0.5, 1, 0.08096),
    SIMD4<Float>(0.3, 0.5, 1, 0.07072),
    SIMD4<Float>(0.3, 0.5, 1, 0.06048),
    SIMD4<Float>(0.3, 0.5, 1, 0.05024),
    SIMD4<Float>(0.3, 0.5, 1, 0.04),
    SIMD4<Float>(0.3, 0.5, 1, 0.02976),
    SIMD4<Float>(0.3, 0.5, 1, 0.01952),
    SIMD4<Float>(0.3, 0.5, 1, 0.00928),
    SIMD4<Float>(0.3, 0.5, 1, 0),
    SIMD4<Float>(0.3, 0.5, 1, 0)
  ]
}

