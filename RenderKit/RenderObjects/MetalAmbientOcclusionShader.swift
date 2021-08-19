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
import SymmetryKit
import simd

class MetalAmbientOcclusionShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  public let cachedAmbientOcclusionTextures: NSCache<AnyObject, AnyObject> = NSCache()
  
  var shadowMapFrameUniformBuffer: MTLBuffer! = nil
  var shadowMapPipeLine: MTLRenderPipelineState! = nil
  var ambientOcclusionPipeLine: MTLRenderPipelineState! = nil
  public var textures: [[MTLTexture]] = []
  var depthTexture: MTLTexture! = nil
  var depthState: MTLDepthStencilState! = nil
  var quadSamplerState:  MTLSamplerState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor()
    
    if let sampler = pSamplerDescriptor
    {
      sampler.minFilter             = MTLSamplerMinMagFilter.linear
      sampler.magFilter             = MTLSamplerMinMagFilter.linear
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
    }
    else
    {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    quadSamplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let shadowMapPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    shadowMapPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    shadowMapPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    shadowMapPipeLineDescriptor.colorAttachments[0] = nil
    shadowMapPipeLineDescriptor.vertexFunction = library.makeFunction(name: "AtomShadowMapVertexShader")!
    shadowMapPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "AtomShadowMapFragmentShader")!
    shadowMapPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.shadowMapPipeLine = try device.makeRenderPipelineState(descriptor: shadowMapPipeLineDescriptor)
      
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    
    
    let ambientOcclusionPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ambientOcclusionPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    ambientOcclusionPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.r16Float
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].isBlendingEnabled = true
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].writeMask = MTLColorWriteMask.red
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.one
    ambientOcclusionPipeLineDescriptor.vertexFunction = library.makeFunction(name: "AmbientOcclusionVertexShader")!
    ambientOcclusionPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "AmbientOcclusionFragmentShader")!
    ambientOcclusionPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.ambientOcclusionPipeLine = try device.makeRenderPipelineState(descriptor: ambientOcclusionPipeLineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }

  }
  
  public func adjustAmbientOcclusionTextureSize()
  {
    let maxSize: Int = 16384
    
    
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        for structure in structures
        {
          if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource
          {
            let numberOfAtoms: Int = structure.renderAtoms.count
          
            switch(numberOfAtoms)
            {
            case 0...64:
              structure.atomAmbientOcclusionTextureSize = min(256,Int(maxSize))
            case 65...256:
              structure.atomAmbientOcclusionTextureSize = min(512,Int(maxSize))
            case 257...1024:
              structure.atomAmbientOcclusionTextureSize = min(1024,Int(maxSize))
            case 1025...65536:
              structure.atomAmbientOcclusionTextureSize = min(2048,Int(maxSize))
            case 65537...524288:
              structure.atomAmbientOcclusionTextureSize = min(4096,Int(maxSize))
            default:
              structure.atomAmbientOcclusionTextureSize = min(8192,Int(maxSize))
            }
          
          
            structure.atomAmbientOcclusionPatchNumber = Int(sqrt(Double(numberOfAtoms)))+1
            structure.atomAmbientOcclusionPatchSize = structure.atomAmbientOcclusionTextureSize/structure.atomAmbientOcclusionPatchNumber
          
          }
        }
      }
    }
  }
  
  public func buildAmbientOcclusionTextures(device: MTLDevice)
  {
    adjustAmbientOcclusionTextureSize()
    
    self.textures = []
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        var localTextures: [MTLTexture] = []
        let structures: [RKRenderStructure] = self.renderStructures[i]
        for structure in structures
        {
          let textureSize: Int = (structure as? RKRenderAtomSource)?.atomAmbientOcclusionTextureSize ?? 1
          let ambientOcclusionTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r16Float, width: textureSize, height: textureSize,   mipmapped: false)
          ambientOcclusionTextureDescriptor.textureType = MTLTextureType.type2D
          ambientOcclusionTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
          ambientOcclusionTextureDescriptor.storageMode = MTLStorageMode.managed
          localTextures.append(device.makeTexture(descriptor: ambientOcclusionTextureDescriptor)!)
        }
        self.textures.append(localTextures)
      }
    }
  }
  
  public func updateAmbientOcclusionTextures(device: MTLDevice, _ commandQueue: MTLCommandQueue, quality: RKRenderQuality,
                                             atomShader: MetalAtomShader, atomOrthographicImposterShader: MetalAtomOrthographicImposterShader)
  {
    if let crystalProjectData: RKRenderDataSource = renderDataSource
    {
      var structureAmbientOcclusionUniformBuffers: MTLBuffer! = nil
      
      // create the depth-buffer (will be discarded after the computation)
      let shadowMapDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float, width: 2048, height: 2048, mipmapped: false)
      shadowMapDepthTextureDescriptor.textureType = MTLTextureType.type2D
      shadowMapDepthTextureDescriptor.storageMode = MTLStorageMode.private
      shadowMapDepthTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      //let shadowMapDepthTexture: MTLTexture = device.newTextureWithDescriptor(shadowMapDepthTextureDescriptor)
      depthTexture = device.makeTexture(descriptor: shadowMapDepthTextureDescriptor)
      
      let shadowMapPassDescriptor = MTLRenderPassDescriptor()
      let shadowMapPassDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = shadowMapPassDescriptor.depthAttachment
      shadowMapPassDepthAttachment.texture = depthTexture
      shadowMapPassDepthAttachment.loadAction = MTLLoadAction.clear
      shadowMapPassDepthAttachment.clearDepth = 1.0
      shadowMapPassDepthAttachment.storeAction = MTLStoreAction.store
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: structure.cell.boundingBox.center, withTranslation:  SIMD3<Double>(0.0, 0.0, 0.0))
          
          var structureUniforms: [RKStructureUniforms] = [RKStructureUniforms](repeating: RKStructureUniforms(), count: max(structures.count,1))
          
          for (k,structure) in structures.enumerated()
          {
            structureUniforms[k] = RKStructureUniforms(sceneIdentifier: i, movieIdentifier: k, structure: structure, inverseModelMatrix: modelMatrix.inverse)
          }
          
          structureAmbientOcclusionUniformBuffers = device.makeBuffer(bytes: structureUniforms, length: MemoryLayout<RKStructureUniforms>.stride * max(structures.count,1), options:.storageModeManaged)
          
          
          
          if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
             structure.atomAmbientOcclusion && structure.isVisible
          {
            let textureSize: Int = structure.atomAmbientOcclusionTextureSize
            
            
            if let cachedVersion: Data = cachedAmbientOcclusionTextures.object(forKey: structure) as? Data
            {
              let region: MTLRegion = MTLRegionMake2D(0, 0, textureSize, textureSize)
              let ambientOcclusiontexture: MTLTexture = self.textures[i][j]
              
              cachedVersion.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> () in
                ambientOcclusiontexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: ptr.baseAddress!, bytesPerRow: 2 * region.size.width, bytesPerImage: 2 * region.size.width * region.size.height)
              }
            }
            else
            {
              let ambientOcclusionPassDescriptor = MTLRenderPassDescriptor()
              let ambientOcclusionPassColorAttachment: MTLRenderPassColorAttachmentDescriptor = ambientOcclusionPassDescriptor.colorAttachments[0]
              ambientOcclusionPassColorAttachment.texture = textures[i][j]
              ambientOcclusionPassColorAttachment.loadAction = MTLLoadAction.clear
              ambientOcclusionPassColorAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
              ambientOcclusionPassColorAttachment.storeAction = MTLStoreAction.store
              
              let ambientOcclusionBlendPassDescriptor = MTLRenderPassDescriptor()
              let ambientOcclusionBlendPassColorAttachment: MTLRenderPassColorAttachmentDescriptor = ambientOcclusionBlendPassDescriptor.colorAttachments[0]
              ambientOcclusionBlendPassColorAttachment.texture = textures[i][j]
              ambientOcclusionBlendPassColorAttachment.loadAction = MTLLoadAction.load
              ambientOcclusionPassColorAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
              ambientOcclusionBlendPassColorAttachment.storeAction = MTLStoreAction.store
              
              var directions: [simd_quatd] = []
              var weights: [Float] = []
              
              if quality == .picture
              {
                directions = simd_quatd.Data1992
                weights = simd_quatd.Weights1992.map{Float(4.0*$0/1992.0)}
              }
              else
              {
                // use the same direction for the vertices and cells of a hecatonicosachoron
                directions = simd_quatd.Data300 + simd_quatd.Data60
                weights = Array<Float>(repeating: 4.0*0.93426/360.0, count: 300) + Array<Float>(repeating: 4.0*1.32870/360.0, count: 60)
              }
              
              
              // create the uniform-buffer for all 343-random orientations
              var shadowMapFrameUniformsArray: [RKShadowUniforms] = [RKShadowUniforms](repeating: RKShadowUniforms(), count: directions.count)
              
              if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
              {
                let ambientOcclusionBlendCommandEncoder: MTLRenderCommandEncoder
                ambientOcclusionBlendCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: ambientOcclusionPassDescriptor)!
                ambientOcclusionBlendCommandEncoder.endEncoding()
                commandBuffer.commit()
              }
              
              let boundingBox: SKBoundingBox = crystalProjectData.renderBoundingBox
              let largestRadius: Double = boundingBox.boundingSphereRadius
              let centerOfScene = boundingBox.minimum + (boundingBox.maximum - boundingBox.minimum) * 0.5
              let eye = SIMD3<Double>(x: centerOfScene.x, y: centerOfScene.y, z: centerOfScene.z + largestRadius)
              
              let boundingBoxAspectRatio: Double = fabs(boundingBox.maximum.x - boundingBox.minimum.x) / abs(boundingBox.maximum.y - boundingBox.minimum.y)
              
              let left,right,top,bottom: Double
              if (boundingBoxAspectRatio < 1.0)
              {
                left =  -largestRadius/boundingBoxAspectRatio;
                right = largestRadius/boundingBoxAspectRatio;
                top = largestRadius/boundingBoxAspectRatio;
                bottom = -largestRadius/boundingBoxAspectRatio;
                
              }
              else
              {
                left = -largestRadius;
                right = largestRadius;
                top = largestRadius;
                bottom = -largestRadius;
              }
              
              let near: Double = 1.0
              let far: Double = 1000.0
              
              
              // the fixed set of directions are randomly, but deterministically, distorted to remove artifacts
              srand48(0)
              
              for k in 0..<directions.count
              {
                let smallChangeQ: simd_quatd = simd_quatd.smallRandomQuaternion(angleRange: 0.5*10.0*Double.pi/180.0)
                let q: simd_quatd = smallChangeQ * directions[k]
                
                let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: q), aroundPoint: centerOfScene)
                let viewMatrix: double4x4 = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: SIMD3<Double>(x: 0, y: 1, z:0))
                let projectionMatrix: double4x4 = double4x4.glFrustumfOrthographic(left, right: right, bottom: bottom, top: top, near: near, far: far)
                
                let shadowMapFrameUniforms: RKShadowUniforms = RKShadowUniforms(projectionMatrix: projectionMatrix, viewMatrix:  viewMatrix, modelMatrix: modelMatrix)
                shadowMapFrameUniformsArray[k] = shadowMapFrameUniforms
              }
              shadowMapFrameUniformBuffer = device.makeBuffer(bytes: &shadowMapFrameUniformsArray, length:MemoryLayout<RKShadowUniforms>.stride * shadowMapFrameUniformsArray.count, options:.storageModeManaged)
              
              
              if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
              {
                // generate shadow-map
                for k in 0..<directions.count
                {
                  let shadowMapCommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowMapPassDescriptor)!
                  shadowMapCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(2048), height: Double(2048), znear: 0.0, zfar: 1.0))
                  shadowMapCommandEncoder.setDepthStencilState(self.depthState)
                  shadowMapCommandEncoder.setCullMode(MTLCullMode.back)
                  shadowMapCommandEncoder.setFrontFacing(MTLWinding.clockwise)
                  shadowMapCommandEncoder.setRenderPipelineState(self.shadowMapPipeLine)
                  
                  
                  for (l, structure) in structures.enumerated()
                  {
                    
                    if structure.isVisible
                    {
                      shadowMapCommandEncoder.setVertexBuffer(atomOrthographicImposterShader.vertexBuffer, offset: 0, index: 0)
                      shadowMapCommandEncoder.setVertexBuffer(atomShader.instanceBuffer[i][l], offset: 0, index: 1)
                      shadowMapCommandEncoder.setVertexBuffer(self.shadowMapFrameUniformBuffer, offset: k*MemoryLayout<RKShadowUniforms>.stride, index: 2)
                      shadowMapCommandEncoder.setVertexBuffer(structureAmbientOcclusionUniformBuffers, offset: l*MemoryLayout<RKStructureUniforms>.stride, index: 3)
                      shadowMapCommandEncoder.setFragmentBuffer(self.shadowMapFrameUniformBuffer, offset: k*MemoryLayout<RKShadowUniforms>.stride, index: 0)
                      
                      if let buffer: MTLBuffer = atomShader.instanceBuffer[i][l]
                      {
                        let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
                        shadowMapCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomOrthographicImposterShader.indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomOrthographicImposterShader.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
                      }
                    }
                  }
                  
                  shadowMapCommandEncoder.endEncoding()
                  
                  
                  
                  let ambientOcclusionBlendCommandEncoder: MTLRenderCommandEncoder
                  ambientOcclusionBlendCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: ambientOcclusionBlendPassDescriptor)!
                  
                  ambientOcclusionBlendCommandEncoder.setFragmentBytes(&weights[k], length: MemoryLayout<Float>.stride, index: 2)
                  
                  ambientOcclusionBlendCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(textureSize), height: Double(textureSize), znear: 0.0, zfar: 1.0))
                  ambientOcclusionBlendCommandEncoder.setRenderPipelineState(self.ambientOcclusionPipeLine)
                  
                  ambientOcclusionBlendCommandEncoder.setVertexBuffer(atomOrthographicImposterShader.vertexBuffer, offset: 0, index: 0)
                  ambientOcclusionBlendCommandEncoder.setVertexBuffer(atomShader.instanceBuffer[i][j], offset: 0, index: 1)
                  ambientOcclusionBlendCommandEncoder.setVertexBuffer(shadowMapFrameUniformBuffer, offset: k*MemoryLayout<RKShadowUniforms>.stride, index: 2)
                  ambientOcclusionBlendCommandEncoder.setVertexBuffer(structureAmbientOcclusionUniformBuffers, offset: j*MemoryLayout<RKStructureUniforms>.stride, index: 3)
                  
                  
                  ambientOcclusionBlendCommandEncoder.setFragmentBuffer(shadowMapFrameUniformBuffer, offset: k*MemoryLayout<RKShadowUniforms>.stride, index: 0)
                  ambientOcclusionBlendCommandEncoder.setFragmentBuffer(structureAmbientOcclusionUniformBuffers, offset: j*MemoryLayout<RKStructureUniforms>.stride, index: 1)
                  ambientOcclusionBlendCommandEncoder.setFragmentTexture(depthTexture, index: 0)
                  ambientOcclusionBlendCommandEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
                  
                  if let buffer: MTLBuffer = atomShader.instanceBuffer[i][j]
                  {
                    let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                    ambientOcclusionBlendCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomOrthographicImposterShader.indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomOrthographicImposterShader.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
                  }
                  
                  ambientOcclusionBlendCommandEncoder.endEncoding()
                }
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
              }
              
              
              let dataLength: Int = textureSize * textureSize * 2
              let textureBuffer: MTLBuffer = device.makeBuffer(length: dataLength, options: MTLResourceOptions())!
              
              // storing in NSCache
              if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
              {
                let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
                blitEncoder.synchronize(resource: self.textures[i][j])
                blitEncoder.copy(from: self.textures[i][j], sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0,0, 0), sourceSize: MTLSizeMake(textureSize, textureSize, 1), to: textureBuffer, destinationOffset: 0, destinationBytesPerRow: textureSize * 2, destinationBytesPerImage: 0)
                blitEncoder.endEncoding()
                
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
              }
              
              // store ambient-occlusion texture for reuse (i.e. it is too expensive to recompute everytime a user switches projects)
              let ambientOcclusionTextureData: Data = Data(bytes: textureBuffer.contents().assumingMemoryBound(to: UInt8.self), count: dataLength)
              self.cachedAmbientOcclusionTextures.setObject(ambientOcclusionTextureData as AnyObject, forKey: structure)
            }
          }
        }
      }
    }
  }
}
