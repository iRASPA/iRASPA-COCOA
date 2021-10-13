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
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var transparentPipeLine: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer? = nil
  var indexBuffer: MTLBuffer? = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  var depthState: MTLDepthStencilState! = nil
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
        let structures: [RKRenderStructure] = self.renderStructures[i]
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
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
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
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
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
    SIMD4<Float>(0.5, 0.2, 0.2, 0),
    SIMD4<Float>(0.521254, 0.204251, 0.204251, 0),
    SIMD4<Float>(0.54259, 0.208518, 0.208518, 0),
    SIMD4<Float>(0.563927, 0.212785, 0.212785, 0),
    SIMD4<Float>(0.585264, 0.217053, 0.217053, 0),
    SIMD4<Float>(0.606601, 0.22132, 0.22132, 0),
    SIMD4<Float>(0.627938, 0.225588, 0.225588, 0),
    SIMD4<Float>(0.649275, 0.229855, 0.229855, 0),
    SIMD4<Float>(0.670612, 0.234122, 0.234122, 0),
    SIMD4<Float>(0.691949, 0.23839, 0.23839, 0),
    SIMD4<Float>(0.713286, 0.242657, 0.242657, 0),
    SIMD4<Float>(0.734622, 0.246924, 0.246924, 0),
    SIMD4<Float>(0.755959, 0.251192, 0.251192, 0),
    SIMD4<Float>(0.777296, 0.255459, 0.255459, 0),
    SIMD4<Float>(0.798633, 0.259727, 0.259727, 0),
    SIMD4<Float>(0.81997, 0.263994, 0.263994, 0),
    SIMD4<Float>(0.841307, 0.268261, 0.268261, 0),
    SIMD4<Float>(0.862644, 0.272529, 0.272529, 0),
    SIMD4<Float>(0.883981, 0.276796, 0.276796, 0),
    SIMD4<Float>(0.905318, 0.281064, 0.281064, 0),
    SIMD4<Float>(0.926654, 0.285331, 0.285331, 0),
    SIMD4<Float>(0.947991, 0.289598, 0.289598, 0),
    SIMD4<Float>(0.969328, 0.293866, 0.293866, 0),
    SIMD4<Float>(0.990665, 0.298133, 0.298133, 0),
    SIMD4<Float>(1, 0.303927, 0.3, 0),
    SIMD4<Float>(1, 0.310909, 0.3, 0),
    SIMD4<Float>(1, 0.317891, 0.3, 0),
    SIMD4<Float>(1, 0.324873, 0.3, 0),
    SIMD4<Float>(1, 0.331855, 0.3, 0),
    SIMD4<Float>(1, 0.338836, 0.3, 0),
    SIMD4<Float>(1, 0.345818, 0.3, 0),
    SIMD4<Float>(1, 0.3528, 0.3, 0),
    SIMD4<Float>(1, 0.359782, 0.3, 0),
    SIMD4<Float>(1, 0.366764, 0.3, 0),
    SIMD4<Float>(1, 0.373745, 0.3, 0),
    SIMD4<Float>(1, 0.380727, 0.3, 0),
    SIMD4<Float>(1, 0.387709, 0.3, 0),
    SIMD4<Float>(1, 0.394691, 0.3, 0),
    SIMD4<Float>(1, 0.401673, 0.3, 0),
    SIMD4<Float>(1, 0.408655, 0.3, 0),
    SIMD4<Float>(1, 0.415636, 0.3, 0.0288),
    SIMD4<Float>(1, 0.422618, 0.3, 0.05952),
    SIMD4<Float>(1, 0.4296, 0.3, 0.09024),
    SIMD4<Float>(1, 0.436582, 0.3, 0.12096),
    SIMD4<Float>(1, 0.443564, 0.3, 0.15168),
    SIMD4<Float>(1, 0.450545, 0.3, 0.1824),
    SIMD4<Float>(1, 0.457527, 0.3, 0.21312),
    SIMD4<Float>(1, 0.464509, 0.3, 0.24384),
    SIMD4<Float>(1, 0.471491, 0.3, 0.27456),
    SIMD4<Float>(1, 0.478473, 0.3, 0.30528),
    SIMD4<Float>(1, 0.485455, 0.3, 0.336),
    SIMD4<Float>(1, 0.492436, 0.3, 0.36672),
    SIMD4<Float>(1, 0.499418, 0.3, 0.39744),
    SIMD4<Float>(1, 0.5064, 0.3, 0.42816),
    SIMD4<Float>(1, 0.513382, 0.3, 0.45888),
    SIMD4<Float>(1, 0.520364, 0.3, 0.4896),
    SIMD4<Float>(1, 0.527345, 0.3, 0.52032),
    SIMD4<Float>(1, 0.534327, 0.3, 0.55104),
    SIMD4<Float>(1, 0.541309, 0.3, 0.58176),
    SIMD4<Float>(1, 0.548291, 0.3, 0.6),
    SIMD4<Float>(1, 0.555273, 0.3, 0.6),
    SIMD4<Float>(1, 0.562255, 0.3, 0.6),
    SIMD4<Float>(1, 0.569236, 0.3, 0.6),
    SIMD4<Float>(1, 0.576218, 0.3, 0.6),
    SIMD4<Float>(1, 0.5832, 0.3, 0.6),
    SIMD4<Float>(1, 0.590182, 0.3, 0.6),
    SIMD4<Float>(1, 0.597164, 0.3, 0.6),
    SIMD4<Float>(1, 0.605527, 0.295855, 0.6),
    SIMD4<Float>(1, 0.614836, 0.288873, 0.6),
    SIMD4<Float>(1, 0.624145, 0.281891, 0.6),
    SIMD4<Float>(1, 0.633455, 0.274909, 0.6),
    SIMD4<Float>(1, 0.642764, 0.267927, 0.6),
    SIMD4<Float>(1, 0.652073, 0.260945, 0.6),
    SIMD4<Float>(1, 0.661382, 0.253964, 0.6),
    SIMD4<Float>(1, 0.670691, 0.246982, 0.6),
    SIMD4<Float>(1, 0.68, 0.24, 0.6),
    SIMD4<Float>(1, 0.689309, 0.233018, 0.6),
    SIMD4<Float>(1, 0.698618, 0.226036, 0.6),
    SIMD4<Float>(1, 0.707927, 0.219055, 0.6),
    SIMD4<Float>(1, 0.717236, 0.212073, 0.60672),
    SIMD4<Float>(1, 0.726545, 0.205091, 0.6144),
    SIMD4<Float>(1, 0.735855, 0.198109, 0.62208),
    SIMD4<Float>(1, 0.745164, 0.191127, 0.62976),
    SIMD4<Float>(1, 0.754473, 0.184145, 0.63744),
    SIMD4<Float>(1, 0.763782, 0.177164, 0.64512),
    SIMD4<Float>(1, 0.773091, 0.170182, 0.6528),
    SIMD4<Float>(1, 0.7824, 0.1632, 0.66048),
    SIMD4<Float>(1, 0.791709, 0.156218, 0.66816),
    SIMD4<Float>(1, 0.801018, 0.149236, 0.67584),
    SIMD4<Float>(1, 0.810327, 0.142255, 0.68352),
    SIMD4<Float>(1, 0.819636, 0.135273, 0.6912),
    SIMD4<Float>(1, 0.828945, 0.128291, 0.69888),
    SIMD4<Float>(1, 0.838255, 0.121309, 0.70656),
    SIMD4<Float>(1, 0.847564, 0.114327, 0.71424),
    SIMD4<Float>(1, 0.856873, 0.107345, 0.72192),
    SIMD4<Float>(1, 0.866182, 0.100364, 0.7296),
    SIMD4<Float>(1, 0.875491, 0.0933818, 0.73728),
    SIMD4<Float>(1, 0.8848, 0.0864, 0.74496),
    SIMD4<Float>(1, 0.894109, 0.0794182, 0.75264),
    SIMD4<Float>(1, 0.903418, 0.0724364, 0.76032),
    SIMD4<Float>(1, 0.912727, 0.0654545, 0.768),
    SIMD4<Float>(1, 0.922036, 0.0584727, 0.77568),
    SIMD4<Float>(1, 0.931345, 0.0514909, 0.78336),
    SIMD4<Float>(1, 0.940655, 0.0445091, 0.79104),
    SIMD4<Float>(1, 0.949964, 0.0375273, 0.79872),
    SIMD4<Float>(1, 0.959273, 0.0305455, 0.8064),
    SIMD4<Float>(1, 0.968582, 0.0235636, 0.81408),
    SIMD4<Float>(1, 0.977891, 0.0165818, 0.82176),
    SIMD4<Float>(1, 0.9872, 0.0096, 0.82944),
    SIMD4<Float>(1, 0.996509, 0.00261818, 0.83712),
    SIMD4<Float>(0.904, 1, 0.096, 0.8448),
    SIMD4<Float>(0.7504, 1, 0.2496, 0.85248),
    SIMD4<Float>(0.5968, 1, 0.4032, 0.86016),
    SIMD4<Float>(0.4432, 1, 0.5568, 0.86784),
    SIMD4<Float>(0.3816, 0.9448, 0.5816, 0.87552),
    SIMD4<Float>(0.356, 0.868, 0.556, 0.8832),
    SIMD4<Float>(0.3304, 0.7912, 0.5304, 0.89088),
    SIMD4<Float>(0.3048, 0.7144, 0.5048, 0.89856),
    SIMD4<Float>(0.3, 0.698829, 0.502927, 0.900693),
    SIMD4<Float>(0.3, 0.697389, 0.506529, 0.901547),
    SIMD4<Float>(0.3, 0.695948, 0.510131, 0.9024),
    SIMD4<Float>(0.3, 0.694507, 0.513733, 0.903253),
    SIMD4<Float>(0.3, 0.693066, 0.517335, 0.904107),
    SIMD4<Float>(0.3, 0.691625, 0.520937, 0.90496),
    SIMD4<Float>(0.3, 0.690185, 0.524538, 0.905813),
    SIMD4<Float>(0.3, 0.688744, 0.52814, 0.906667),
    SIMD4<Float>(0.3, 0.687303, 0.531742, 0.90752),
    SIMD4<Float>(0.3, 0.685862, 0.535344, 0.908373),
    SIMD4<Float>(0.3, 0.684421, 0.538946, 0.909227),
    SIMD4<Float>(0.3, 0.682981, 0.542548, 0.91008),
    SIMD4<Float>(0.3, 0.68154, 0.54615, 0.910933),
    SIMD4<Float>(0.3, 0.680099, 0.549752, 0.911787),
    SIMD4<Float>(0.3, 0.678658, 0.553354, 0.91264),
    SIMD4<Float>(0.3, 0.677217, 0.556956, 0.913493),
    SIMD4<Float>(0.3, 0.675777, 0.560558, 0.914347),
    SIMD4<Float>(0.3, 0.674336, 0.56416, 0.9152),
    SIMD4<Float>(0.3, 0.672895, 0.567762, 0.916053),
    SIMD4<Float>(0.3, 0.671454, 0.571364, 0.916907),
    SIMD4<Float>(0.3, 0.670014, 0.574966, 0.91776),
    SIMD4<Float>(0.3, 0.668573, 0.578568, 0.918613),
    SIMD4<Float>(0.3, 0.667132, 0.58217, 0.919467),
    SIMD4<Float>(0.3, 0.665691, 0.585772, 0.92032),
    SIMD4<Float>(0.3, 0.66425, 0.589374, 0.921173),
    SIMD4<Float>(0.3, 0.66281, 0.592976, 0.922027),
    SIMD4<Float>(0.3, 0.661369, 0.596578, 0.92288),
    SIMD4<Float>(0.3, 0.659928, 0.60018, 0.923733),
    SIMD4<Float>(0.3, 0.658487, 0.603782, 0.924587),
    SIMD4<Float>(0.3, 0.657046, 0.607384, 0.92544),
    SIMD4<Float>(0.3, 0.655606, 0.610986, 0.926293),
    SIMD4<Float>(0.3, 0.654165, 0.614588, 0.927147),
    SIMD4<Float>(0.3, 0.652724, 0.61819, 0.928),
    SIMD4<Float>(0.3, 0.651283, 0.621792, 0.928853),
    SIMD4<Float>(0.3, 0.649842, 0.625394, 0.929707),
    SIMD4<Float>(0.3, 0.648402, 0.628996, 0.93056),
    SIMD4<Float>(0.3, 0.646961, 0.632598, 0.931413),
    SIMD4<Float>(0.3, 0.64552, 0.6362, 0.932267),
    SIMD4<Float>(0.3, 0.644079, 0.639802, 0.93312),
    SIMD4<Float>(0.3, 0.642638, 0.643404, 0.933973),
    SIMD4<Float>(0.3, 0.641198, 0.647006, 0.934827),
    SIMD4<Float>(0.3, 0.639757, 0.650608, 0.93568),
    SIMD4<Float>(0.3, 0.638316, 0.65421, 0.936533),
    SIMD4<Float>(0.3, 0.636875, 0.657812, 0.937387),
    SIMD4<Float>(0.3, 0.635434, 0.661414, 0.93824),
    SIMD4<Float>(0.3, 0.633994, 0.665016, 0.939093),
    SIMD4<Float>(0.3, 0.632553, 0.668618, 0.939947),
    SIMD4<Float>(0.3, 0.631112, 0.67222, 0.9408),
    SIMD4<Float>(0.3, 0.629671, 0.675822, 0.941653),
    SIMD4<Float>(0.3, 0.628231, 0.679424, 0.942507),
    SIMD4<Float>(0.3, 0.62679, 0.683026, 0.94336),
    SIMD4<Float>(0.3, 0.625349, 0.686628, 0.944213),
    SIMD4<Float>(0.3, 0.623908, 0.69023, 0.945067),
    SIMD4<Float>(0.3, 0.622467, 0.693832, 0.94592),
    SIMD4<Float>(0.3, 0.621027, 0.697434, 0.946773),
    SIMD4<Float>(0.3, 0.619586, 0.701036, 0.947627),
    SIMD4<Float>(0.3, 0.618145, 0.704638, 0.94848),
    SIMD4<Float>(0.3, 0.616704, 0.70824, 0.949333),
    SIMD4<Float>(0.3, 0.615263, 0.711842, 0.950187),
    SIMD4<Float>(0.3, 0.613823, 0.715443, 0.95104),
    SIMD4<Float>(0.3, 0.612382, 0.719045, 0.951893),
    SIMD4<Float>(0.3, 0.610941, 0.722647, 0.952747),
    SIMD4<Float>(0.3, 0.6095, 0.726249, 0.9536),
    SIMD4<Float>(0.3, 0.608059, 0.729851, 0.954453),
    SIMD4<Float>(0.3, 0.606619, 0.733453, 0.955307),
    SIMD4<Float>(0.3, 0.605178, 0.737055, 0.95616),
    SIMD4<Float>(0.3, 0.603737, 0.740657, 0.957013),
    SIMD4<Float>(0.3, 0.602296, 0.744259, 0.957867),
    SIMD4<Float>(0.3, 0.600855, 0.747861, 0.95872),
    SIMD4<Float>(0.3, 0.599415, 0.751463, 0.959573),
    SIMD4<Float>(0.3, 0.597974, 0.755065, 0.960427),
    SIMD4<Float>(0.3, 0.596533, 0.758667, 0.96128),
    SIMD4<Float>(0.3, 0.595092, 0.762269, 0.962133),
    SIMD4<Float>(0.3, 0.593652, 0.765871, 0.962987),
    SIMD4<Float>(0.3, 0.592211, 0.769473, 0.96384),
    SIMD4<Float>(0.3, 0.59077, 0.773075, 0.964693),
    SIMD4<Float>(0.3, 0.589329, 0.776677, 0.965547),
    SIMD4<Float>(0.3, 0.587888, 0.780279, 0.9664),
    SIMD4<Float>(0.3, 0.586448, 0.783881, 0.967253),
    SIMD4<Float>(0.3, 0.585007, 0.787483, 0.968107),
    SIMD4<Float>(0.3, 0.583566, 0.791085, 0.96896),
    SIMD4<Float>(0.3, 0.582125, 0.794687, 0.969813),
    SIMD4<Float>(0.3, 0.580684, 0.798289, 0.970667),
    SIMD4<Float>(0.3, 0.579244, 0.801891, 0.97152),
    SIMD4<Float>(0.3, 0.577803, 0.805493, 0.972373),
    SIMD4<Float>(0.3, 0.576362, 0.809095, 0.973227),
    SIMD4<Float>(0.3, 0.574921, 0.812697, 0.97408),
    SIMD4<Float>(0.3, 0.57348, 0.816299, 0.974933),
    SIMD4<Float>(0.3, 0.57204, 0.819901, 0.975787),
    SIMD4<Float>(0.3, 0.570599, 0.823503, 0.97664),
    SIMD4<Float>(0.3, 0.569158, 0.827105, 0.977493),
    SIMD4<Float>(0.3, 0.567717, 0.830707, 0.978347),
    SIMD4<Float>(0.3, 0.566276, 0.834309, 0.9792),
    SIMD4<Float>(0.3, 0.564836, 0.837911, 0.980053),
    SIMD4<Float>(0.3, 0.563395, 0.841513, 0.980907),
    SIMD4<Float>(0.3, 0.561954, 0.845115, 0.98176),
    SIMD4<Float>(0.3, 0.560513, 0.848717, 0.982613),
    SIMD4<Float>(0.3, 0.559072, 0.852319, 0.983467),
    SIMD4<Float>(0.3, 0.557632, 0.855921, 0.98432),
    SIMD4<Float>(0.3, 0.556191, 0.859523, 0.985173),
    SIMD4<Float>(0.3, 0.55475, 0.863125, 0.986027),
    SIMD4<Float>(0.3, 0.553309, 0.866727, 0.98688),
    SIMD4<Float>(0.3, 0.551869, 0.870329, 0.987733),
    SIMD4<Float>(0.3, 0.550428, 0.873931, 0.988587),
    SIMD4<Float>(0.3, 0.548987, 0.877533, 0.98944),
    SIMD4<Float>(0.3, 0.547546, 0.881135, 0.990293),
    SIMD4<Float>(0.3, 0.546105, 0.884737, 0.991147),
    SIMD4<Float>(0.3, 0.544665, 0.888339, 0.992),
    SIMD4<Float>(0.3, 0.543224, 0.891941, 0.992853),
    SIMD4<Float>(0.3, 0.541783, 0.895543, 0.993707),
    SIMD4<Float>(0.3, 0.540342, 0.899145, 0.99456),
    SIMD4<Float>(0.3, 0.538901, 0.902747, 0.995413),
    SIMD4<Float>(0.3, 0.537461, 0.906348, 0.996267),
    SIMD4<Float>(0.3, 0.53602, 0.90995, 0.99712),
    SIMD4<Float>(0.3, 0.534579, 0.913552, 0.997973),
    SIMD4<Float>(0.3, 0.533138, 0.917154, 0.998827),
    SIMD4<Float>(0.3, 0.531697, 0.920756, 0.99968),
    SIMD4<Float>(0.3, 0.530257, 0.924358, 0.968),
    SIMD4<Float>(0.3, 0.528816, 0.92796, 0.9168),
    SIMD4<Float>(0.3, 0.527375, 0.931562, 0.8656),
    SIMD4<Float>(0.3, 0.525934, 0.935164, 0.8144),
    SIMD4<Float>(0.3, 0.524493, 0.938766, 0.7632),
    SIMD4<Float>(0.3, 0.523053, 0.942368, 0.712),
    SIMD4<Float>(0.3, 0.521612, 0.94597, 0.6608),
    SIMD4<Float>(0.3, 0.520171, 0.949572, 0.6096),
    SIMD4<Float>(0.3, 0.51873, 0.953174, 0.5584),
    SIMD4<Float>(0.3, 0.51729, 0.956776, 0.5072),
    SIMD4<Float>(0.3, 0.515849, 0.960378, 0.456),
    SIMD4<Float>(0.3, 0.514408, 0.96398, 0.4048),
    SIMD4<Float>(0.3, 0.512967, 0.967582, 0.3536),
    SIMD4<Float>(0.3, 0.511526, 0.971184, 0.3024),
    SIMD4<Float>(0.3, 0.510086, 0.974786, 0.2512),
    SIMD4<Float>(0.3, 0.508645, 0.978388, 0.2),
    SIMD4<Float>(0.3, 0.507204, 0.98199, 0.1488),
    SIMD4<Float>(0.3, 0.505763, 0.985592, 0.0976),
    SIMD4<Float>(0.3, 0.504322, 0.989194, 0.0464),
    SIMD4<Float>(0.3, 0.502882, 0.992796, 0),
    SIMD4<Float>(0.3, 0.501441, 0.996398, 0)
  ]
}

