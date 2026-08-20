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
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import MathKit

class MetalPickingShader
{
  /// Set to `false` to skip ribbon geometry in the picking pass entirely.
  public static var ribbonPickingEnabled: Bool = true
  
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var renderPassDescriptor: MTLRenderPassDescriptor! = nil
  var texture: MTLTexture! = nil
  var depthTexture: MTLTexture! = nil
  var depthState: MTLDepthStencilState! = nil
  var samplerState: MTLSamplerState! = nil
  
  var atomOrthographicPipeLine: MTLRenderPipelineState! = nil
  var atomPerspectivePipeLine: MTLRenderPipelineState! = nil
  var internalBondImposterPipeLine: MTLRenderPipelineState! = nil
  var externalBondImposterPipeLine: MTLRenderPipelineState! = nil
  var polygonalPrismPrimitivePipeLine: MTLRenderPipelineState! = nil
  var ribbonPipeLine: MTLRenderPipelineState! = nil
 
  
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
    samplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let atomOrthographicPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    atomOrthographicPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    atomOrthographicPipelineDescriptor.vertexFunction = library.makeFunction(name: "AtomSpherePickingVertexShader")!
    atomOrthographicPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    atomOrthographicPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    atomOrthographicPipelineDescriptor.fragmentFunction = library.makeFunction(name: "AtomSpherePickingFragmentShader")!
    atomOrthographicPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.atomOrthographicPipeLine = try device.makeRenderPipelineState(descriptor: atomOrthographicPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating atom-picking render pipeline state \(error)")
    }
    
    let atomPerspectivePipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    atomPerspectivePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    atomPerspectivePipelineDescriptor.vertexFunction = library.makeFunction(name: "AtomSpherePickingPerspectiveVertexShader")!
    atomPerspectivePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    atomPerspectivePipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    atomPerspectivePipelineDescriptor.fragmentFunction = library.makeFunction(name: "AtomSpherePickingPerspectiveFragmentShader")!
    atomPerspectivePipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.atomPerspectivePipeLine = try device.makeRenderPipelineState(descriptor: atomPerspectivePipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating atom-perspective-picking render pipeline state \(error)")
    }
    
    // imposter pipeline: the hull vertices are generated from the vertex-id, so no vertex descriptor is needed
    let internalBondImposterPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    internalBondImposterPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    internalBondImposterPipelineDescriptor.vertexFunction = library.makeFunction(name: "PickingInternalBondCylinderImposterVertexShader")!
    internalBondImposterPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    internalBondImposterPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    internalBondImposterPipelineDescriptor.fragmentFunction = library.makeFunction(name: "PickingInternalBondCylinderImposterFragmentShader")!
    
    do
    {
      self.internalBondImposterPipeLine = try device.makeRenderPipelineState(descriptor: internalBondImposterPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating bond-imposter-picking render pipeline state \(error)")
    }
    
    // imposter pipeline: the hull vertices are generated from the vertex-id, so no vertex descriptor is needed
    let externalBondImposterPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    externalBondImposterPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    externalBondImposterPipelineDescriptor.vertexFunction = library.makeFunction(name: "PickingExternalBondCylinderImposterVertexShader")!
    externalBondImposterPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    externalBondImposterPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    externalBondImposterPipelineDescriptor.fragmentFunction = library.makeFunction(name: "PickingExternalBondCylinderImposterFragmentShader")!
    
    do
    {
      self.externalBondImposterPipeLine = try device.makeRenderPipelineState(descriptor: externalBondImposterPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating bond-imposter-picking render pipeline state \(error)")
    }
    
    let polygonalPrismPrimitivePipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    polygonalPrismPrimitivePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    polygonalPrismPrimitivePipelineDescriptor.vertexFunction = library.makeFunction(name: "PickingPolygonalPrismVertexShader")!
    polygonalPrismPrimitivePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    polygonalPrismPrimitivePipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    polygonalPrismPrimitivePipelineDescriptor.fragmentFunction = library.makeFunction(name: "PickingPolygonalPrismFragmentShader")!
    polygonalPrismPrimitivePipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.polygonalPrismPrimitivePipeLine = try device.makeRenderPipelineState(descriptor: polygonalPrismPrimitivePipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating polygonal-prism-primitive render pipeline state \(error)")
    }
    
    let ribbonPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ribbonPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    ribbonPipelineDescriptor.vertexFunction = library.makeFunction(name: "RibbonPickingVertexShader")!
    ribbonPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    ribbonPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonPipelineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonPickingFragmentShader")!
    ribbonPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.ribbonPipeLine = try device.makeRenderPipelineState(descriptor: ribbonPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon-picking render pipeline state \(error)")
    }
  }
  
  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int)
  {
    let pickingTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba32Uint, width: max(16, Int(size.width)), height: max(16,Int(size.height)), mipmapped: false)
    pickingTextureDescriptor.textureType = MTLTextureType.type2D
    pickingTextureDescriptor.storageMode = RKMetal.hostStorageMode
    pickingTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    texture = device.makeTexture(descriptor: pickingTextureDescriptor)
    texture.label = "picking texture"
    
    let pickingDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float, width: max(16, Int(size.width)), height: max(16, Int(size.height)), mipmapped: false)
    pickingDepthTextureDescriptor.textureType = MTLTextureType.type2D
    pickingDepthTextureDescriptor.storageMode = MTLStorageMode.private
    pickingDepthTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    depthTexture = device.makeTexture(descriptor: pickingDepthTextureDescriptor)
    depthTexture.label = "picking depth texture"
    
    renderPassDescriptor = MTLRenderPassDescriptor()
    let colorAttachment: MTLRenderPassColorAttachmentDescriptor = renderPassDescriptor.colorAttachments[0]
    colorAttachment.texture = texture
    colorAttachment.loadAction = MTLLoadAction.clear
    colorAttachment.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    colorAttachment.storeAction = MTLStoreAction.store
    let depthAttachment: MTLRenderPassDepthAttachmentDescriptor = renderPassDescriptor.depthAttachment
    depthAttachment.texture = depthTexture
    depthAttachment.loadAction = MTLLoadAction.clear
    depthAttachment.clearDepth = 1.0
    depthAttachment.storeAction = MTLStoreAction.store
  }
  
  public func pickTextureAtPoint(device: MTLDevice, _ commandQueue: MTLCommandQueue, point: NSPoint) -> [Int32]
  {
    var data : [Int32] = [0,0,0,0]
    if NSMakeRect(0.0, 0.0, CGFloat(texture.width), CGFloat(texture.height)).contains(point)
    {
      if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer(),
        let textureBuffer: MTLBuffer = device.makeBuffer(bytes: data, length:MemoryLayout<Int32>.stride * 4, options: RKMetal.hostStorage),
        let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
      {
        blitEncoder.label = "Picking texture blit command encoder"
        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(round(point.x)), Int(round(point.y)), 0), sourceSize: MTLSizeMake(1, 1, 1), to: textureBuffer, destinationOffset: 0, destinationBytesPerRow: MemoryLayout<Int32>.stride * 4, destinationBytesPerImage: 0)
        RKMetal.synchronize(blitEncoder, resource: textureBuffer)
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        memcpy(&data, textureBuffer.contents(), textureBuffer.length)
      }
    }
    return data
  }
  
  public func pickDepthTextureAtPoint(device: MTLDevice, _ commandQueue: MTLCommandQueue, point: NSPoint) -> Float?
  {
    var depth: Float = 1.0
    var pick : [Int32] = [0,0,0,0]
    if NSMakeRect(0.0, 0.0, CGFloat(depthTexture.width), CGFloat(depthTexture.height)).contains(point)
    {
      if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer(),
        let textureBuffer: MTLBuffer = device.makeBuffer(bytes: pick, length: MemoryLayout<Int32>.stride * 4, options: RKMetal.hostStorage),
        let textureBufferDepth: MTLBuffer = device.makeBuffer(bytes: &depth, length:MemoryLayout<Float>.stride, options: RKMetal.hostStorage),
        let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
      {
        blitEncoder.label = "Picking texture blit command encoder"
        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(round(point.x)), Int(round(point.y)), 0), sourceSize: MTLSizeMake(1, 1, 1), to: textureBuffer, destinationOffset: 0, destinationBytesPerRow: MemoryLayout<Int32>.stride * 4, destinationBytesPerImage: 0)
        
        blitEncoder.label = "Picking texture blit command encoder"
        blitEncoder.copy(from: depthTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(round(point.x)), Int(round(point.y)), 0), sourceSize: MTLSizeMake(1, 1, 1), to: textureBufferDepth, destinationOffset: 0, destinationBytesPerRow: MemoryLayout<Float>.stride, destinationBytesPerImage: 0)
        
        RKMetal.synchronize(blitEncoder, resource: textureBuffer)
        RKMetal.synchronize(blitEncoder, resource: textureBufferDepth)
        
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        memcpy(&pick, textureBuffer.contents(), textureBuffer.length)
        
        if (pick[0] >= 1)
        {
          memcpy(&depth, textureBufferDepth.contents(), textureBufferDepth.length)
          return depth
        }
      }
    }
    return nil
  }
  
  public func renderPickingTextureWithEncoder(_ commandBuffer: MTLCommandBuffer,
                                              renderPassDescriptor: MTLRenderPassDescriptor,
                                              atomShader: MetalAtomShader,
                                              atomOrthographicImposterShader: MetalAtomOrthographicImposterShader,
                                              internalBondShader: MetalInternalBondShader,
                                              externalBondShader: MetalExternalBondShader,
                                              crystalEllipsoidPrimitiveShader: MetalCrystalEllipsoidShader,
                                              ellipsoidPrimitiveShader: MetalEllipsoidShader,
                                              crystalCylinderPrimitiveShader: MetalCrystalCylinderShader,
                                              cylinderPrimitiveShader: MetalCylinderShader,
                                              crystalPolygonalPrismPrimitiveShader: MetalCrystalPolygonalPrismShader,
                                              polygonalPrismPrimitiveShader: MetalPolygonalPrismShader,
                                              ribbonShader: MetalRibbonShader,
                                              frameUniformBuffer: MTLBuffer,
                                              structureUniformBuffers: MTLBuffer?,
                                              size: CGSize,
                                              renderQuality: RKRenderQuality,
                                              camera: RKCamera?,
                                              skipRibbonPicking: Bool = false)
  {
    _ = renderQuality
    if let _: RKRenderDataSource = renderDataSource
    {
      let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
      commandEncoder.label = "Picking command encoder"
      commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
      commandEncoder.setDepthStencilState(self.depthState)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setFrontFacing(MTLWinding.clockwise)
      
      let atomVertexBuffer: MTLBuffer
      let atomIndexBuffer: MTLBuffer
      let atomPipeline: MTLRenderPipelineState
      
      atomVertexBuffer = atomOrthographicImposterShader.vertexBuffer
      atomIndexBuffer = atomOrthographicImposterShader.indexBuffer
      if let camera, camera.frustrumType == .perspective
      {
        atomPipeline = atomPerspectivePipeLine
      }
      else
      {
        atomPipeline = atomOrthographicPipeLine
      }
      
      commandEncoder.setVertexBuffer(atomVertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
             let buffer: MTLBuffer = self.metalBuffer(atomShader.instanceBuffer, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawAtoms && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setRenderPipelineState(atomPipeline)
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomIndexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomIndexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          
          /*
           // forget why we do this
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(atomShader.instanceBuffer, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
               (!structure.drawAtoms && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setRenderPipelineState(atomPipeLine)
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomOrthographicImposterShader.indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomOrthographicImposterShader.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }*/
          index = index + 1
        }
      }
      
     
      commandEncoder.setRenderPipelineState(internalBondImposterPipeLine)
      // the imposter hull is generated in the vertex shader with view-dependent winding
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(internalBondShader.instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawBonds && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 18, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(internalBondShader.instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawBonds && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(internalBondShader.instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawBonds && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 54, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setRenderPipelineState(externalBondImposterPipeLine)
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(externalBondShader.instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawBonds && structure.isVisible &&  (instanceCount > 0) )
            {
              
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 18, instanceCount: instanceCount)
            }
          }
          
          index = index + 1
        }
      }
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(externalBondShader.instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawBonds && structure.isVisible &&  (instanceCount > 0) )
            {
              
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36, instanceCount: instanceCount)
            }
          }
          
          index = index + 1
        }
      }
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(externalBondShader.instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawBonds && structure.isVisible &&  (instanceCount > 0) )
            {
              
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 54, instanceCount: instanceCount)
            }
          }
          
          index = index + 1
        }
      }
      
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(polygonalPrismPrimitivePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderCrystalEllipsoidObjectsSource = structure as? RKRenderCrystalEllipsoidObjectsSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(crystalEllipsoidPrimitiveShader.instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = crystalEllipsoidPrimitiveShader.vertexBuffers,
            let indexBuffer: MTLBuffer = crystalEllipsoidPrimitiveShader.indexBuffers
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && numberOfAtoms > 0)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(polygonalPrismPrimitivePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderEllipsoidObjectsSource = structure as? RKRenderEllipsoidObjectsSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(ellipsoidPrimitiveShader.instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = ellipsoidPrimitiveShader.vertexBuffer,
            let indexBuffer: MTLBuffer = ellipsoidPrimitiveShader.indexBuffer
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && numberOfAtoms > 0)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(polygonalPrismPrimitivePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderCrystalCylinderObjectsSource = structure as? RKRenderCrystalCylinderObjectsSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(crystalCylinderPrimitiveShader.instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = self.metalBuffer(crystalCylinderPrimitiveShader.vertexBuffers, sceneIndex: i, movieIndex: j),
            let indexBuffer: MTLBuffer = self.metalBuffer(crystalCylinderPrimitiveShader.indexBuffers, sceneIndex: i, movieIndex: j)
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && numberOfAtoms > 0)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(polygonalPrismPrimitivePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderCylinderObjectsSource = structure as? RKRenderCylinderObjectsSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(cylinderPrimitiveShader.instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = self.metalBuffer(cylinderPrimitiveShader.vertexBuffers, sceneIndex: i, movieIndex: j),
            let indexBuffer: MTLBuffer = self.metalBuffer(cylinderPrimitiveShader.indexBuffers, sceneIndex: i, movieIndex: j)
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && numberOfAtoms > 0)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(polygonalPrismPrimitivePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderCrystalPolygonalPrismObjectsSource = structure as? RKRenderCrystalPolygonalPrismObjectsSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(crystalPolygonalPrismPrimitiveShader.instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = self.metalBuffer(crystalPolygonalPrismPrimitiveShader.vertexBuffers, sceneIndex: i, movieIndex: j),
            let indexBuffer: MTLBuffer = self.metalBuffer(crystalPolygonalPrismPrimitiveShader.indexBuffers, sceneIndex: i, movieIndex: j)
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && numberOfAtoms > 0)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(polygonalPrismPrimitivePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderPolygonalPrismObjectsSource = structure as? RKRenderPolygonalPrismObjectsSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(polygonalPrismPrimitiveShader.instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = self.metalBuffer(polygonalPrismPrimitiveShader.vertexBuffers, sceneIndex: i, movieIndex: j),
            let indexBuffer: MTLBuffer = self.metalBuffer(polygonalPrismPrimitiveShader.indexBuffers, sceneIndex: i, movieIndex: j)
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && numberOfAtoms > 0)
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setDepthStencilState(depthState)
      
      if Self.ribbonPickingEnabled && !skipRibbonPicking
      {
      commandEncoder.setRenderPipelineState(ribbonPipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
             let ribbonVertexBuffer: MTLBuffer = self.metalBuffer(ribbonShader.vertexBuffer, sceneIndex: i, movieIndex: j),
             let ribbonIndexBuffer: MTLBuffer = self.metalBuffer(ribbonShader.indexBuffer, sceneIndex: i, movieIndex: j),
             ribbonSource.drawRibbon,
             ribbonSource.isVisible,
             ribbonSource.ribbonNumberOfIndices > 0
          {
            commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
            commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
            let drawRanges: [RKRibbonChainDrawRange] = ribbonSource.ribbonDrawRangesForEncoding()
            commandEncoder.setVertexBuffer(ribbonVertexBuffer, offset: 0, index: 0)
            for drawRange in drawRanges
            {
              guard drawRange.indexCount > 0 else {continue}
              commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: drawRange.indexCount,
                                                   indexType: .uint32,
                                                   indexBuffer: ribbonIndexBuffer,
                                                   indexBufferOffset: drawRange.indexStart * MemoryLayout<UInt32>.stride)
            }
          }
          index = index + 1
        }
      }
      }
      
      commandEncoder.endEncoding()
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
}
