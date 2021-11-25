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

class MetalRASPADensityVolumeShader
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
                    withBytes: MetalRASPADensityVolumeShader.transferFunction,
                    bytesPerRow: 256 * MemoryLayout<Float>.size * 4)
    
    let transparentDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepthStateDescriptor.isDepthWriteEnabled = true
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepthStateDescriptor)
    
    let transparentPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    transparentPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    transparentPipelineDescriptor.vertexFunction = library.makeFunction(name: "RASPADensityVolumeVertexShader")!
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
    transparentPipelineDescriptor.fragmentFunction = library.makeFunction(name: "RASPADensityVolumeFragmentShader")!
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
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderRASPADensityVolumeSource & RKRenderObject
          {
            let size: Int32 = structure.dimensions.x * structure.dimensions.y * structure.dimensions.z
            if(size>0)
            {
              let data: Data = structure.data
              
              let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor()
              textureDescriptor.textureType = .type3D
              textureDescriptor.pixelFormat = .rgba32Float
              textureDescriptor.width = Int(structure.dimensions.x)
              textureDescriptor.height = Int(structure.dimensions.y)
              textureDescriptor.depth = Int(structure.dimensions.z)
              textureDescriptor.usage = .shaderRead
              textureDescriptor.storageMode = MTLStorageMode.managed
              guard let texture = device.makeTexture(descriptor: textureDescriptor) else {return}
              texture.label = "Energy/gradient 3D texture"
              textureData[i][j] = texture
              
              debugPrint("set Density texture \(data.count) \(structure.dimensions)")
              data.withUnsafeBytes { rawBufferPointer in
                  let rawPtr = rawBufferPointer.baseAddress!
                  texture.replace(region: MTLRegionMake3D(0, 0, 0, Int(structure.dimensions.x), Int(structure.dimensions.y), Int(structure.dimensions.z)),
                                  mipmapLevel: 0,
                                  slice: 0,
                                  withBytes: rawPtr,
                                  bytesPerRow: Int(structure.dimensions.x) * MemoryLayout<Float>.size * 4,
                                  bytesPerImage: Int(structure.dimensions.x) * Int(structure.dimensions.y) * MemoryLayout<Float>.size * 4)
              }
              
              
              switch(size)
              {
              case 128:
                break
              case 256:
                break
              default:
                break
              }
            }
            //let endTime: UInt64  = mach_absolute_time()
            
            //let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000001
            
            //LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal energy surface is \(time) milliseconds")
          }
        }
      }
    }
  }
  
  
  public func renderRASPADensityWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, depthTexture: MTLTexture!, size: CGSize)
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
          if let structure: RKRenderRASPADensityVolumeSource & RKRenderObject = structure as? RKRenderRASPADensityVolumeSource & RKRenderObject,
             let vertexBuffer = vertexBuffer,
             let indexBuffer = indexBuffer,
             let texture = textureData[i][j],
             let textureTransferFunction = textureTransferFunction,
             let depthTexture = depthTexture
          {
            if (structure.isVisible)
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
          if let structure = structure as? RKRenderRASPADensityVolumeSource & RKRenderObject
          {
            let size: Int32 = structure.dimensions.x * structure.dimensions.y * structure.dimensions.z
            let data: Data = structure.data
            
            let startTime: UInt64  = mach_absolute_time()
            let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor()
            textureDescriptor.textureType = .type3D
            textureDescriptor.pixelFormat = .rgba32Float
            textureDescriptor.width = Int(structure.dimensions.x)
            textureDescriptor.height = Int(structure.dimensions.y)
            textureDescriptor.depth = Int(structure.dimensions.z)
            textureDescriptor.usage = .shaderRead
            textureDescriptor.storageMode = MTLStorageMode.managed
            guard let texture = device.makeTexture(descriptor: textureDescriptor) else {return}
            texture.label = "Energy/gradient 3D texture"
            textureData[i][j] = texture
            
            debugPrint("set Density texture")
            data.withUnsafeBytes { rawBufferPointer in
                let rawPtr = rawBufferPointer.baseAddress!
                texture.replace(region: MTLRegionMake3D(0, 0, 0, Int(structure.dimensions.x), Int(structure.dimensions.y), Int(structure.dimensions.z)),
                                mipmapLevel: 0,
                                slice: 0,
                                withBytes: rawPtr,
                                bytesPerRow: Int(structure.dimensions.x) * MemoryLayout<Float>.size * 4,
                                bytesPerImage: Int(structure.dimensions.x) * Int(structure.dimensions.y) * MemoryLayout<Float>.size * 4)
            }
            
            
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
    SIMD4<Float>(0.55102, 0.210204, 0.210204, 0),
    SIMD4<Float>(0.602241, 0.220448, 0.220448, 0),
    SIMD4<Float>(0.653461, 0.230692, 0.230692, 0),
    SIMD4<Float>(0.704682, 0.240936, 0.240936, 0),
    SIMD4<Float>(0.755902, 0.25118, 0.25118, 0),
    SIMD4<Float>(0.807123, 0.261425, 0.261425, 0),
    SIMD4<Float>(0.858343, 0.271669, 0.271669, 0),
    SIMD4<Float>(0.909564, 0.281913, 0.281913, 0),
    SIMD4<Float>(0.960784, 0.292157, 0.292157, 0),
    SIMD4<Float>(0.984571, 0.312, 0.305143, 0),
    SIMD4<Float>(0.918743, 0.3632, 0.327086, 0),
    SIMD4<Float>(0.852914, 0.4144, 0.349029, 0),
    SIMD4<Float>(0.787086, 0.4656, 0.370971, 0),
    SIMD4<Float>(0.721257, 0.5168, 0.392914, 0),
    SIMD4<Float>(0.655429, 0.568, 0.414857, 0),
    SIMD4<Float>(0.5896, 0.6192, 0.4368, 0),
    SIMD4<Float>(0.523771, 0.6704, 0.458743, 0),
    SIMD4<Float>(0.457943, 0.7216, 0.480686, 0),
    SIMD4<Float>(0.392114, 0.7728, 0.502629, 0),
    SIMD4<Float>(0.326286, 0.824, 0.524571, 0),
    SIMD4<Float>(0.260457, 0.8752, 0.546514, 0),
    SIMD4<Float>(0.194629, 0.9264, 0.568457, 0),
    SIMD4<Float>(0.1288, 0.9776, 0.5904, 0),
    SIMD4<Float>(0.1, 0.99136, 0.59712, 0),
    SIMD4<Float>(0.1, 0.976, 0.592, 0),
    SIMD4<Float>(0.1, 0.96064, 0.58688, 0),
    SIMD4<Float>(0.1, 0.94528, 0.58176, 0),
    SIMD4<Float>(0.1, 0.92992, 0.57664, 0),
    SIMD4<Float>(0.1, 0.91456, 0.57152, 0),
    SIMD4<Float>(0.1, 0.8992, 0.5664, 0),
    SIMD4<Float>(0.1, 0.88384, 0.56128, 0),
    SIMD4<Float>(0.1, 0.86848, 0.55616, 0),
    SIMD4<Float>(0.1, 0.85312, 0.55104, 0),
    SIMD4<Float>(0.1, 0.83776, 0.54592, 0),
    SIMD4<Float>(0.1, 0.8224, 0.5408, 0),
    SIMD4<Float>(0.1, 0.80704, 0.53568, 0),
    SIMD4<Float>(0.1, 0.79168, 0.53056, 0),
    SIMD4<Float>(0.1, 0.77632, 0.52544, 0),
    SIMD4<Float>(0.1, 0.76096, 0.52032, 0),
    SIMD4<Float>(0.1, 0.7456, 0.5152, 0),
    SIMD4<Float>(0.1, 0.73024, 0.51008, 0),
    SIMD4<Float>(0.1, 0.71488, 0.50496, 0),
    SIMD4<Float>(0.1, 0.699893, 0.500267, 0),
    SIMD4<Float>(0.1, 0.69648, 0.5088, 0),
    SIMD4<Float>(0.1, 0.693067, 0.517333, 0),
    SIMD4<Float>(0.1, 0.689653, 0.525867, 0),
    SIMD4<Float>(0.1, 0.68624, 0.5344, 0),
    SIMD4<Float>(0.1, 0.682827, 0.542933, 0),
    SIMD4<Float>(0.1, 0.679413, 0.551467, 0),
    SIMD4<Float>(0.1, 0.676, 0.56, 0),
    SIMD4<Float>(0.1, 0.672587, 0.568533, 0),
    SIMD4<Float>(0.1, 0.669173, 0.577067, 0),
    SIMD4<Float>(0.1, 0.66576, 0.5856, 0),
    SIMD4<Float>(0.1, 0.662347, 0.594133, 0),
    SIMD4<Float>(0.1, 0.658933, 0.602667, 0),
    SIMD4<Float>(0.1, 0.65552, 0.6112, 0),
    SIMD4<Float>(0.1, 0.652107, 0.619733, 0),
    SIMD4<Float>(0.1, 0.648693, 0.628267, 0),
    SIMD4<Float>(0.1, 0.64528, 0.6368, 0.00416),
    SIMD4<Float>(0.1, 0.641867, 0.645333, 0.0144),
    SIMD4<Float>(0.1, 0.638453, 0.653867, 0.02464),
    SIMD4<Float>(0.1, 0.63504, 0.6624, 0.03488),
    SIMD4<Float>(0.1, 0.631627, 0.670933, 0.04512),
    SIMD4<Float>(0.1, 0.628213, 0.679467, 0.05536),
    SIMD4<Float>(0.1, 0.6248, 0.688, 0.0656),
    SIMD4<Float>(0.1, 0.621387, 0.696533, 0.07584),
    SIMD4<Float>(0.1, 0.617973, 0.705067, 0.08608),
    SIMD4<Float>(0.1, 0.61456, 0.7136, 0.09632),
    SIMD4<Float>(0.1, 0.611147, 0.722133, 0.10656),
    SIMD4<Float>(0.1, 0.607733, 0.730667, 0.1168),
    SIMD4<Float>(0.1, 0.60432, 0.7392, 0.12704),
    SIMD4<Float>(0.1, 0.600907, 0.747733, 0.13728),
    SIMD4<Float>(0.1, 0.597493, 0.756267, 0.14752),
    SIMD4<Float>(0.1, 0.59408, 0.7648, 0.15776),
    SIMD4<Float>(0.1, 0.590667, 0.773333, 0.168),
    SIMD4<Float>(0.1, 0.587253, 0.781867, 0.17824),
    SIMD4<Float>(0.1, 0.58384, 0.7904, 0.18848),
    SIMD4<Float>(0.1, 0.580427, 0.798933, 0.19872),
    SIMD4<Float>(0.1, 0.577013, 0.807467, 0.20896),
    SIMD4<Float>(0.1, 0.5736, 0.816, 0.2192),
    SIMD4<Float>(0.1, 0.570187, 0.824533, 0.22944),
    SIMD4<Float>(0.1, 0.566773, 0.833067, 0.23968),
    SIMD4<Float>(0.1, 0.56336, 0.8416, 0.24992),
    SIMD4<Float>(0.1, 0.559947, 0.850133, 0.26016),
    SIMD4<Float>(0.1, 0.556533, 0.858667, 0.2704),
    SIMD4<Float>(0.1, 0.55312, 0.8672, 0.28064),
    SIMD4<Float>(0.1, 0.549707, 0.875733, 0.29088),
    SIMD4<Float>(0.1, 0.546293, 0.884267, 0.30112),
    SIMD4<Float>(0.1, 0.54288, 0.8928, 0.31136),
    SIMD4<Float>(0.1, 0.539467, 0.901333, 0.3216),
    SIMD4<Float>(0.1, 0.536053, 0.909867, 0.33184),
    SIMD4<Float>(0.1, 0.53264, 0.9184, 0.34208),
    SIMD4<Float>(0.1, 0.529227, 0.926933, 0.35232),
    SIMD4<Float>(0.1, 0.525813, 0.935467, 0.36256),
    SIMD4<Float>(0.1, 0.5224, 0.944, 0.3728),
    SIMD4<Float>(0.1, 0.518987, 0.952533, 0.38304),
    SIMD4<Float>(0.1, 0.515573, 0.961067, 0.39328),
    SIMD4<Float>(0.1, 0.51216, 0.9696, 0.40352),
    SIMD4<Float>(0.1, 0.508747, 0.978133, 0.41376),
    SIMD4<Float>(0.1, 0.505333, 0.986667, 0.424),
    SIMD4<Float>(0.1, 0.50192, 0.9952, 0.43424),
    SIMD4<Float>(0.099552, 0.49776, 1, 0.44448),
    SIMD4<Float>(0.098528, 0.49264, 1, 0.45472),
    SIMD4<Float>(0.097504, 0.48752, 1, 0.46496),
    SIMD4<Float>(0.09648, 0.4824, 1, 0.4752),
    SIMD4<Float>(0.095456, 0.47728, 1, 0.48544),
    SIMD4<Float>(0.094432, 0.47216, 1, 0.49568),
    SIMD4<Float>(0.093408, 0.46704, 1, 0.50592),
    SIMD4<Float>(0.092384, 0.46192, 1, 0.51616),
    SIMD4<Float>(0.09136, 0.4568, 1, 0.5264),
    SIMD4<Float>(0.090336, 0.45168, 1, 0.53664),
    SIMD4<Float>(0.089312, 0.44656, 1, 0.54688),
    SIMD4<Float>(0.088288, 0.44144, 1, 0.55712),
    SIMD4<Float>(0.087264, 0.43632, 1, 0.56736),
    SIMD4<Float>(0.08624, 0.4312, 1, 0.5776),
    SIMD4<Float>(0.085216, 0.42608, 1, 0.58784),
    SIMD4<Float>(0.084192, 0.42096, 1, 0.59808),
    SIMD4<Float>(0.083168, 0.41584, 1, 0.60832),
    SIMD4<Float>(0.082144, 0.41072, 1, 0.61856),
    SIMD4<Float>(0.08112, 0.4056, 1, 0.6288),
    SIMD4<Float>(0.080096, 0.40048, 1, 0.63904),
    SIMD4<Float>(0.079072, 0.39536, 1, 0.64928),
    SIMD4<Float>(0.078048, 0.39024, 1, 0.65952),
    SIMD4<Float>(0.077024, 0.38512, 1, 0.66976),
    SIMD4<Float>(0.076, 0.38, 1, 0.68),
    SIMD4<Float>(0.074976, 0.37488, 1, 0.69024),
    SIMD4<Float>(0.073952, 0.36976, 1, 0.70048),
    SIMD4<Float>(0.072928, 0.36464, 1, 0.71072),
    SIMD4<Float>(0.071904, 0.35952, 1, 0.72096),
    SIMD4<Float>(0.07088, 0.3544, 1, 0.7312),
    SIMD4<Float>(0.069856, 0.34928, 1, 0.74144),
    SIMD4<Float>(0.068832, 0.34416, 1, 0.75168),
    SIMD4<Float>(0.067808, 0.33904, 1, 0.76192),
    SIMD4<Float>(0.066784, 0.33392, 1, 0.77216),
    SIMD4<Float>(0.06576, 0.3288, 1, 0.7824),
    SIMD4<Float>(0.064736, 0.32368, 1, 0.79264),
    SIMD4<Float>(0.063712, 0.31856, 1, 0.80288),
    SIMD4<Float>(0.062688, 0.31344, 1, 0.81312),
    SIMD4<Float>(0.061664, 0.30832, 1, 0.82336),
    SIMD4<Float>(0.06064, 0.3032, 1, 0.8336),
    SIMD4<Float>(0.059616, 0.29808, 1, 0.84384),
    SIMD4<Float>(0.058592, 0.29296, 1, 0.85408),
    SIMD4<Float>(0.057568, 0.28784, 1, 0.86432),
    SIMD4<Float>(0.056544, 0.28272, 1, 0.87456),
    SIMD4<Float>(0.05552, 0.2776, 1, 0.8848),
    SIMD4<Float>(0.054496, 0.27248, 1, 0.89504),
    SIMD4<Float>(0.053472, 0.26736, 1, 0.90528),
    SIMD4<Float>(0.052448, 0.26224, 1, 0.91552),
    SIMD4<Float>(0.051424, 0.25712, 1, 0.92576),
    SIMD4<Float>(0.0504, 0.252, 1, 0.936),
    SIMD4<Float>(0.049376, 0.24688, 1, 0.94624),
    SIMD4<Float>(0.048352, 0.24176, 1, 0.95648),
    SIMD4<Float>(0.047328, 0.23664, 1, 0.96672),
    SIMD4<Float>(0.046304, 0.23152, 1, 0.97696),
    SIMD4<Float>(0.04528, 0.2264, 1, 0.9872),
    SIMD4<Float>(0.044256, 0.22128, 1, 0.99744),
    SIMD4<Float>(0.043232, 0.21616, 1, 1),
    SIMD4<Float>(0.042208, 0.21104, 1, 1),
    SIMD4<Float>(0.041184, 0.20592, 1, 1),
    SIMD4<Float>(0.04016, 0.2008, 1, 1),
    SIMD4<Float>(0.039136, 0.19568, 1, 1),
    SIMD4<Float>(0.038112, 0.19056, 1, 1),
    SIMD4<Float>(0.037088, 0.18544, 1, 1),
    SIMD4<Float>(0.036064, 0.18032, 1, 1),
    SIMD4<Float>(0.03504, 0.1752, 1, 1),
    SIMD4<Float>(0.034016, 0.17008, 1, 1),
    SIMD4<Float>(0.032992, 0.16496, 1, 1),
    SIMD4<Float>(0.031968, 0.15984, 1, 1),
    SIMD4<Float>(0.030944, 0.15472, 1, 1),
    SIMD4<Float>(0.02992, 0.1496, 1, 1),
    SIMD4<Float>(0.028896, 0.14448, 1, 1),
    SIMD4<Float>(0.027872, 0.13936, 1, 1),
    SIMD4<Float>(0.026848, 0.13424, 1, 1),
    SIMD4<Float>(0.025824, 0.12912, 1, 1),
    SIMD4<Float>(0.0248, 0.124, 1, 1),
    SIMD4<Float>(0.023776, 0.11888, 1, 1),
    SIMD4<Float>(0.022752, 0.11376, 1, 1),
    SIMD4<Float>(0.021728, 0.10864, 1, 1),
    SIMD4<Float>(0.020704, 0.10352, 1, 1),
    SIMD4<Float>(0.01968, 0.0984, 1, 1),
    SIMD4<Float>(0.018656, 0.09328, 1, 1),
    SIMD4<Float>(0.017632, 0.08816, 1, 1),
    SIMD4<Float>(0.016608, 0.08304, 1, 1),
    SIMD4<Float>(0.015584, 0.07792, 1, 1),
    SIMD4<Float>(0.01456, 0.0728, 1, 1),
    SIMD4<Float>(0.013536, 0.06768, 1, 1),
    SIMD4<Float>(0.012512, 0.06256, 1, 1),
    SIMD4<Float>(0.011488, 0.05744, 1, 1),
    SIMD4<Float>(0.010464, 0.05232, 1, 1),
    SIMD4<Float>(0.00944, 0.0472, 1, 1),
    SIMD4<Float>(0.008416, 0.04208, 1, 1),
    SIMD4<Float>(0.007392, 0.03696, 1, 1),
    SIMD4<Float>(0.006368, 0.03184, 1, 1),
    SIMD4<Float>(0.005344, 0.02672, 1, 1),
    SIMD4<Float>(0.00432, 0.0216, 1, 1),
    SIMD4<Float>(0.003296, 0.01648, 1, 1),
    SIMD4<Float>(0.002272, 0.01136, 1, 1),
    SIMD4<Float>(0.001248, 0.00624, 1, 1),
    SIMD4<Float>(0.000224, 0.00112, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1),
    SIMD4<Float>(0, 0, 1, 1)
  ]
}

