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

class MetalInternalBondSelectionWorleyNoise3DShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var vertexBufferSingleBonds: MTLBuffer! = nil
  var indexBufferSingleBonds: MTLBuffer! = nil
  var vertexBufferDoubleBonds: MTLBuffer! = nil
  var indexBufferDoubleBonds: MTLBuffer! = nil
  var vertexBufferPartialDoubleBonds: MTLBuffer! = nil
  var indexBufferPartialDoubleBonds: MTLBuffer! = nil
  var vertexBufferTripleBonds: MTLBuffer! = nil
  var indexBufferTripleBonds: MTLBuffer! = nil
  var pipeLine: MTLRenderPipelineState! = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let transparentDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepthStateDescriptor.isDepthWriteEnabled = false
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepthStateDescriptor)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "internalBondSelectionWorleyNoise3DCylinderVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "internalBondSelectionWorleyNoise3DCylinderFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
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
    
    let cylinderPartialDoubleBond: MetalCappedDoubleBondCylinderGeometry = MetalCappedDoubleBondCylinderGeometry()
    vertexBufferPartialDoubleBonds = device.makeBuffer(bytes: cylinderPartialDoubleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderPartialDoubleBond.vertices.count, options:.storageModeManaged)
    indexBufferDoubleBonds = device.makeBuffer(bytes: cylinderPartialDoubleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderPartialDoubleBond.indices.count, options:.storageModeManaged)
    
    let cylinderTripleBond: MetalCappedTripleBondCylinderGeometry = MetalCappedTripleBondCylinderGeometry()
    vertexBufferTripleBonds = device.makeBuffer(bytes: cylinderTripleBond.vertices, length:MemoryLayout<RKVertex>.stride * cylinderTripleBond.vertices.count, options:.storageModeManaged)
    indexBufferTripleBonds = device.makeBuffer(bytes: cylinderTripleBond.indices, length:MemoryLayout<UInt16>.stride * cylinderTripleBond.indices.count, options:.storageModeManaged)
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, instanceRenderer: MetalInternalBondSelectionShader, bondShader: MetalInternalBondShader, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    // draw internal bonds
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderBondSource}.reduce(false, {$0 || $1.drawBonds}))
    {
      commandEncoder.setRenderPipelineState(pipeLine)
      
      commandEncoder.setDepthStencilState(self.transparentDepthState)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      
      var index: Int = 0
      commandEncoder.setVertexBuffer(vertexBufferSingleBonds, offset: 0, index: 0)
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferAllBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .WorleyNoise3D && structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferSingleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferSingleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      index = 0
      commandEncoder.setVertexBuffer(vertexBufferSingleBonds, offset: 0, index: 0)
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .WorleyNoise3D && !structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
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
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .WorleyNoise3D && !structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
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
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .WorleyNoise3D && !structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferTripleBonds.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBufferTripleBonds, indexBufferOffset: 0, instanceCount: instanceCount)
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
}

