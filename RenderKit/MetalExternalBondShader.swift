/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

class MetalExternalBondShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var stencilPipeLine: MTLRenderPipelineState! = nil
  var indexBufferSingleBonds: MTLBuffer! = nil
  var vertexBufferSingleBonds: MTLBuffer! = nil
  var instanceBufferSingleBonds: [[MTLBuffer?]] = []
  var indexBufferDoubleBonds: MTLBuffer! = nil
  var vertexBufferDoubleBonds: MTLBuffer! = nil
  var instanceBufferDoubleBonds: [[MTLBuffer?]] = []
  var indexBufferTripleBonds: MTLBuffer! = nil
  var vertexBufferTripleBonds: MTLBuffer! = nil
  var instanceBufferTripleBonds: [[MTLBuffer?]] = []
  var samplerState: MTLSamplerState! = nil
  var depthState: MTLDepthStencilState! = nil
  var depthStencilStateWriteFalse: MTLDepthStencilState! = nil
  var stencilDescriptorWriteFalse: MTLDepthStencilState! = nil
  var depthStencilStateWriteTrue: MTLDepthStencilState! = nil
  
  var boxPipeLine: MTLRenderPipelineState! = nil
  var boxIndexBuffer: MTLBuffer! = nil
  var boxVertexBuffer: MTLBuffer! = nil
  
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
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
    
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
    let stencilDescriptorWriteFalse: MTLStencilDescriptor = MTLStencilDescriptor()
    stencilDescriptorWriteFalse.stencilFailureOperation = MTLStencilOperation.keep
    stencilDescriptorWriteFalse.depthFailureOperation = MTLStencilOperation.invert
    stencilDescriptorWriteFalse.depthStencilPassOperation = MTLStencilOperation.invert
    stencilDescriptorWriteFalse.stencilCompareFunction = MTLCompareFunction.always
    stencilDescriptorWriteFalse.writeMask = 0x1
    
    let depthStencilStateDescWriteFalse: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilStateDescWriteFalse.frontFaceStencil = stencilDescriptorWriteFalse
    depthStencilStateDescWriteFalse.backFaceStencil = stencilDescriptorWriteFalse
    depthStencilStateDescWriteFalse.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStencilStateDescWriteFalse.isDepthWriteEnabled = false
    self.depthStencilStateWriteFalse = device.makeDepthStencilState(descriptor: depthStencilStateDescWriteFalse)
    
    let stencilDescriptorWriteTrue: MTLStencilDescriptor = MTLStencilDescriptor()
    stencilDescriptorWriteTrue.stencilFailureOperation = MTLStencilOperation.keep
    stencilDescriptorWriteTrue.depthFailureOperation = MTLStencilOperation.zero
    stencilDescriptorWriteTrue.depthStencilPassOperation = MTLStencilOperation.zero
    stencilDescriptorWriteTrue.stencilCompareFunction = MTLCompareFunction.equal
    stencilDescriptorWriteTrue.readMask = 0x1
    
    let depthStencilStateDescWriteTrue: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilStateDescWriteTrue.frontFaceStencil = stencilDescriptorWriteTrue
    depthStencilStateDescWriteTrue.backFaceStencil = stencilDescriptorWriteTrue
    depthStencilStateDescWriteTrue.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStencilStateDescWriteTrue.isDepthWriteEnabled = true
    self.depthStencilStateWriteTrue = device.makeDepthStencilState(descriptor: depthStencilStateDescWriteTrue)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "ExternalBondCylinderVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "ExternalBondCylinderFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    
    let stencilPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    stencilPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    stencilPipelineDescriptor.colorAttachments[0].writeMask = MTLColorWriteMask()
    stencilPipelineDescriptor.vertexFunction = library.makeFunction(name: "StencilExternalBondCylinderVertexShader")!
    stencilPipelineDescriptor.sampleCount = maximumNumberOfSamples
    stencilPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    stencilPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    stencilPipelineDescriptor.fragmentFunction = library.makeFunction(name: "StencilExternalBondCylinderFragmentShader")!
    stencilPipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.stencilPipeLine = try device.makeRenderPipelineState(descriptor: stencilPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    let boxPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    boxPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    boxPipelineDescriptor.vertexFunction = library.makeFunction(name: "boxVertexShader")!
    boxPipelineDescriptor.sampleCount = maximumNumberOfSamples
    boxPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    boxPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    boxPipelineDescriptor.fragmentFunction = library.makeFunction(name: "boxFragmentShader")!
    boxPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.boxPipeLine = try device.makeRenderPipelineState(descriptor: boxPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let cylinderSingleBond: MetalCappedBondCylinderGeometry = MetalCappedBondCylinderGeometry()
    vertexBufferSingleBonds = device.makeBuffer(bytes: cylinderSingleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderSingleBond.vertices.count, options:.storageModeManaged)
    indexBufferSingleBonds = device.makeBuffer(bytes: cylinderSingleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderSingleBond.indices.count, options:.storageModeManaged)
    
    let cylinderDoubleBond: MetalCappedDoubleBondCylinderGeometry = MetalCappedDoubleBondCylinderGeometry()
    vertexBufferDoubleBonds = device.makeBuffer(bytes: cylinderDoubleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderDoubleBond.vertices.count, options:.storageModeManaged)
    indexBufferDoubleBonds = device.makeBuffer(bytes: cylinderDoubleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderDoubleBond.indices.count, options:.storageModeManaged)
    
    let cylinderTripleBond: MetalCappedTripleBondCylinderGeometry = MetalCappedTripleBondCylinderGeometry()
    vertexBufferTripleBonds = device.makeBuffer(bytes: cylinderTripleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderTripleBond.vertices.count, options:.storageModeManaged)
    indexBufferTripleBonds = device.makeBuffer(bytes: cylinderTripleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderTripleBond.indices.count, options:.storageModeManaged)
    
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBufferSingleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstance.append(nil)
        }
        else
        {
          for structure in structures
          {
            let bonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderExternalBonds(type: .single) ?? []
            
            let buffer: MTLBuffer? = bonds.isEmpty ? nil : device.makeBuffer(bytes: bonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * bonds.count, options:.storageModeManaged)
            sceneInstance.append(buffer)
          }
        }
        instanceBufferSingleBonds.append(sceneInstance)
      }
      
      instanceBufferDoubleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstance.append(nil)
        }
        else
        {
          for structure in structures
          {
            let bonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderExternalBonds(type: .double) ?? []
            
            let buffer: MTLBuffer? = bonds.isEmpty ? nil : device.makeBuffer(bytes: bonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * bonds.count, options:.storageModeManaged)
            sceneInstance.append(buffer)
          }
        }
        instanceBufferDoubleBonds.append(sceneInstance)
      }
      
      instanceBufferTripleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstance.append(nil)
        }
        else
        {
          for structure in structures
          {
            let bonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderExternalBonds(type: .triple) ?? []
            
            let buffer: MTLBuffer? = bonds.isEmpty ? nil : device.makeBuffer(bytes: bonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * bonds.count, options:.storageModeManaged)
            sceneInstance.append(buffer)
          }
        }
        instanceBufferTripleBonds.append(sceneInstance)
      }
    }
    
    let box: MetalBoxGeometry = MetalBoxGeometry()
    boxVertexBuffer = device.makeBuffer(bytes: box.vertices, length:MemoryLayout<RKVertex>.stride * box.vertices.count, options:.storageModeManaged)
    boxIndexBuffer = device.makeBuffer(bytes: box.indices, length:MemoryLayout<UInt16>.stride * box.indices.count, options:.storageModeManaged)
    
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    // draw "external" bonds (bonds extending out of the box, and must be clipped)
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderBondSource}.reduce(false, {$0 || ($1.drawBonds && $1.hasExternalBonds)}))
    {
      commandEncoder.setRenderPipelineState(pipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      var index: Int = 0
      commandEncoder.setVertexBuffer(vertexBufferSingleBonds, offset: 0, index: 0)
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferSingleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferSingleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      commandEncoder.setVertexBuffer(vertexBufferDoubleBonds, offset: 0, index: 0)
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferDoubleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferDoubleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      commandEncoder.setVertexBuffer(vertexBufferTripleBonds, offset: 0, index: 0)
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferTripleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferTripleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
    }
    
    // draw caps ond the bonds
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderBondSource}.reduce(false, {$0 || ($1.drawBonds && $1.hasExternalBonds)}))
    {
      var index: Int = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isVisible && structure.drawBonds &&  instanceCount > 0)
            {
              commandEncoder.setRenderPipelineState(stencilPipeLine)
              commandEncoder.setVertexBuffer(vertexBufferSingleBonds, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
              commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
              commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
              commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
              commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
              commandEncoder.setDepthStencilState(self.depthStencilStateWriteFalse)
              commandEncoder.setStencilReferenceValue(UInt32(1))
              commandEncoder.setCullMode(MTLCullMode.none)
              //commandEncoder.setFragmentSamplerState(quadSamplerState, atIndex: 0)
            
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferSingleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferSingleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            
            
              commandEncoder.setRenderPipelineState(boxPipeLine)
              commandEncoder.setVertexBuffer(boxVertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
              commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
              commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
              commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
            
              commandEncoder.setDepthStencilState(self.depthStencilStateWriteTrue)
              commandEncoder.setStencilReferenceValue(UInt32(1))
              commandEncoder.setCullMode(MTLCullMode.back)
            
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 2)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: boxIndexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: boxIndexBuffer, indexBufferOffset: 0)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isVisible && structure.drawBonds &&  instanceCount > 0)
            {
              commandEncoder.setRenderPipelineState(stencilPipeLine)
              commandEncoder.setVertexBuffer(vertexBufferDoubleBonds, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
              commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
              commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
              commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
              commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
              commandEncoder.setDepthStencilState(self.depthStencilStateWriteFalse)
              commandEncoder.setStencilReferenceValue(UInt32(1))
              commandEncoder.setCullMode(MTLCullMode.none)
              //commandEncoder.setFragmentSamplerState(quadSamplerState, atIndex: 0)
            
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferDoubleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferDoubleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            
            
              commandEncoder.setRenderPipelineState(boxPipeLine)
              commandEncoder.setVertexBuffer(boxVertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
              commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
              commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
              commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
            
              commandEncoder.setDepthStencilState(self.depthStencilStateWriteTrue)
              commandEncoder.setStencilReferenceValue(UInt32(1))
              commandEncoder.setCullMode(MTLCullMode.back)
            
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 2)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: boxIndexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: boxIndexBuffer, indexBufferOffset: 0)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isVisible && structure.drawBonds &&  instanceCount > 0)
            {
              commandEncoder.setRenderPipelineState(stencilPipeLine)
              commandEncoder.setVertexBuffer(vertexBufferTripleBonds, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
              commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
              commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
              commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
              commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
              commandEncoder.setDepthStencilState(self.depthStencilStateWriteFalse)
              commandEncoder.setStencilReferenceValue(UInt32(1))
              commandEncoder.setCullMode(MTLCullMode.none)
              //commandEncoder.setFragmentSamplerState(quadSamplerState, atIndex: 0)
            
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferTripleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferTripleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            
            
              commandEncoder.setRenderPipelineState(boxPipeLine)
              commandEncoder.setVertexBuffer(boxVertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
              commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
              commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
              commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
            
              commandEncoder.setDepthStencilState(self.depthStencilStateWriteTrue)
              commandEncoder.setStencilReferenceValue(UInt32(1))
              commandEncoder.setCullMode(MTLCullMode.back)
            
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 2)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: boxIndexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: boxIndexBuffer, indexBufferOffset: 0)
            }
          }
          index = index + 1
        }
      }
    }
    
    commandEncoder.setDepthStencilState(self.depthState)
    commandEncoder.setStencilReferenceValue(UInt32(1))
    commandEncoder.setCullMode(MTLCullMode.back)
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
