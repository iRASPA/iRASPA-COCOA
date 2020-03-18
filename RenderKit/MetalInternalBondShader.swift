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
import SymmetryKit

class MetalInternalBondShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var instanceBufferAllBonds: [[MTLBuffer?]] = []
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
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "BondCylinderVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "BondCylinderFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
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
      instanceBufferAllBonds = []
      instanceBufferSingleBonds = []
      instanceBufferDoubleBonds = []
      instanceBufferTripleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstanceAllBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceSingleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceDoubleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceTripleBonds: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstanceSingleBonds.append(nil)
          sceneInstanceDoubleBonds.append(nil)
          sceneInstanceTripleBonds.append(nil)
        }
        else
        {
          for structure in structures
          {
            let allBonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderInternalBonds ?? []
            let singleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.single.rawValue)}
            let doubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.double.rawValue)}
            let tripleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.triple.rawValue)}
            
            let bufferAllBonds: MTLBuffer? = allBonds.isEmpty ? nil : device.makeBuffer(bytes: allBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * allBonds.count, options:.storageModeManaged)
            let bufferSingleBonds: MTLBuffer? = singleBonds.isEmpty ? nil : device.makeBuffer(bytes: singleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * singleBonds.count, options:.storageModeManaged)
            let bufferDoubleBonds: MTLBuffer? = doubleBonds.isEmpty ? nil : device.makeBuffer(bytes: doubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * doubleBonds.count, options:.storageModeManaged)
            let bufferTripleBonds: MTLBuffer? = tripleBonds.isEmpty ? nil : device.makeBuffer(bytes: tripleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * tripleBonds.count, options:.storageModeManaged)
            
            sceneInstanceAllBonds.append(bufferAllBonds)
            sceneInstanceSingleBonds.append(bufferSingleBonds)
            sceneInstanceDoubleBonds.append(bufferDoubleBonds)
            sceneInstanceTripleBonds.append(bufferTripleBonds)
          }
        }
        instanceBufferAllBonds.append(sceneInstanceAllBonds)
        instanceBufferSingleBonds.append(sceneInstanceSingleBonds)
        instanceBufferDoubleBonds.append(sceneInstanceDoubleBonds)
        instanceBufferTripleBonds.append(sceneInstanceTripleBonds)
      }
      
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    // draw internal bonds
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderBondSource}.reduce(false, {$0 || $1.drawBonds}))
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
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferAllBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
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
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
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
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
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
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
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
