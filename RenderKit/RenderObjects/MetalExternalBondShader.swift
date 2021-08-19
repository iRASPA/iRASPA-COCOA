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

class MetalExternalBondShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var stencilPipeLine: MTLRenderPipelineState! = nil
  var instanceBufferAllBonds: [[MTLBuffer?]] = []
  var indexBufferSingleBonds: MTLBuffer! = nil
  var vertexBufferSingleBonds: MTLBuffer! = nil
  var instanceBufferSingleBonds: [[MTLBuffer?]] = []
  var indexBufferDoubleBonds: MTLBuffer! = nil
  var vertexBufferDoubleBonds: MTLBuffer! = nil
  var instanceBufferDoubleBonds: [[MTLBuffer?]] = []
  var indexBufferPartialDoubleBonds: MTLBuffer! = nil
  var vertexBufferPartialDoubleBonds: MTLBuffer! = nil
  var instanceBufferPartialDoubleBonds: [[MTLBuffer?]] = []
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
    let cylinderSingleBond: MetalCappedSingleBondCylinderGeometry = MetalCappedSingleBondCylinderGeometry()
    vertexBufferSingleBonds = device.makeBuffer(bytes: cylinderSingleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderSingleBond.vertices.count, options:.storageModeManaged)
    indexBufferSingleBonds = device.makeBuffer(bytes: cylinderSingleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderSingleBond.indices.count, options:.storageModeManaged)
    
    let cylinderDoubleBond: MetalCappedDoubleBondCylinderGeometry = MetalCappedDoubleBondCylinderGeometry()
    vertexBufferDoubleBonds = device.makeBuffer(bytes: cylinderDoubleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderDoubleBond.vertices.count, options:.storageModeManaged)
    indexBufferDoubleBonds = device.makeBuffer(bytes: cylinderDoubleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderDoubleBond.indices.count, options:.storageModeManaged)
    
    let cylinderPartialDoubleBond: MetalCappedSingleBondCylinderGeometry = MetalCappedSingleBondCylinderGeometry()
    vertexBufferPartialDoubleBonds = device.makeBuffer(bytes: cylinderPartialDoubleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderPartialDoubleBond.vertices.count, options:.storageModeManaged)
    indexBufferPartialDoubleBonds = device.makeBuffer(bytes: cylinderPartialDoubleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderPartialDoubleBond.indices.count, options:.storageModeManaged)
    
    let cylinderTripleBond: MetalCappedTripleBondCylinderGeometry = MetalCappedTripleBondCylinderGeometry()
    vertexBufferTripleBonds = device.makeBuffer(bytes: cylinderTripleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderTripleBond.vertices.count, options:.storageModeManaged)
    indexBufferTripleBonds = device.makeBuffer(bytes: cylinderTripleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderTripleBond.indices.count, options:.storageModeManaged)
    
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBufferAllBonds = []
      instanceBufferSingleBonds = []
      instanceBufferDoubleBonds = []
      instanceBufferPartialDoubleBonds = []
      instanceBufferTripleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstanceAllBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceSingleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceDoubleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstancePartialDoubleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceTripleBonds: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstanceSingleBonds.append(nil)
          sceneInstanceDoubleBonds.append(nil)
          sceneInstancePartialDoubleBonds.append(nil)
          sceneInstanceTripleBonds.append(nil)
        }
        else
        {
          for structure in structures
          {
            let allBonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderExternalBonds ?? []
            let singleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.single.rawValue)}
            let doubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.double.rawValue)}
            let partialDoubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.partial_double.rawValue)}
            let tripleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.triple.rawValue)}
            
            let bufferAllBonds: MTLBuffer? = allBonds.isEmpty ? nil : device.makeBuffer(bytes: allBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * allBonds.count, options:.storageModeManaged)
            let bufferSingleBonds: MTLBuffer? = singleBonds.isEmpty ? nil : device.makeBuffer(bytes: singleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * singleBonds.count, options:.storageModeManaged)
            let bufferDoubleBonds: MTLBuffer? = doubleBonds.isEmpty ? nil : device.makeBuffer(bytes: doubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * doubleBonds.count, options:.storageModeManaged)
            let bufferPartialDoubleBonds: MTLBuffer? = partialDoubleBonds.isEmpty ? nil : device.makeBuffer(bytes: partialDoubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * partialDoubleBonds.count, options:.storageModeManaged)
            let bufferTripleBonds: MTLBuffer? = tripleBonds.isEmpty ? nil : device.makeBuffer(bytes: tripleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * tripleBonds.count, options:.storageModeManaged)
            
            sceneInstanceAllBonds.append(bufferAllBonds)
            sceneInstanceSingleBonds.append(bufferSingleBonds)
            sceneInstanceDoubleBonds.append(bufferDoubleBonds)
            sceneInstancePartialDoubleBonds.append(bufferPartialDoubleBonds)
            sceneInstanceTripleBonds.append(bufferTripleBonds)
          }
        }
        instanceBufferAllBonds.append(sceneInstanceAllBonds)
        instanceBufferSingleBonds.append(sceneInstanceSingleBonds)
        instanceBufferDoubleBonds.append(sceneInstanceDoubleBonds)
        instanceBufferPartialDoubleBonds.append(sceneInstancePartialDoubleBonds)
        instanceBufferTripleBonds.append(sceneInstanceTripleBonds)
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
        
        // draw everything as single bonds in 'unity'-mode
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferAllBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isUnity && structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
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
      
      // draw single bonds
      index = 0
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
            if (!structure.isUnity && structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
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
      
      // draw double bonds
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
            if (!structure.isUnity && structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
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
      
      // draw partial bonds
      index = 0
      commandEncoder.setVertexBuffer(vertexBufferSingleBonds, offset: 0, index: 0)
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferPartialDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferPartialDoubleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferPartialDoubleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      // draw triple bonds
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
            if (!structure.isUnity && structure.isVisible && structure.drawBonds && structure.hasExternalBonds && instanceCount > 0)
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
      // draw caps for all single bonds in 'unity'-mode
      var index: Int = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferAllBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isUnity && structure.isVisible && structure.drawBonds &&  instanceCount > 0)
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
      
      // draw caps on single bonds
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.isVisible && structure.drawBonds &&  instanceCount > 0)
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
      
      // draw caps on double bonds
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
            if (!structure.isUnity && structure.isVisible && structure.drawBonds &&  instanceCount > 0)
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
      
      // draw caps on partial double bonds
      index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferPartialDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.isVisible && structure.drawBonds &&  instanceCount > 0)
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
      
      // draw caps on triple bonds
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
            if (!structure.isUnity && structure.isVisible && structure.drawBonds &&  instanceCount > 0)
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
