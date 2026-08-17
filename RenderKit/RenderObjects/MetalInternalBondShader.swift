/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

class MetalInternalBondShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var imposterPipeLine: MTLRenderPipelineState! = nil
  var perPixelImposterPipeLine: MTLRenderPipelineState! = nil
  var instanceBufferAllBonds: [[MTLBuffer?]] = []
  var instanceBufferSingleBonds: [[MTLBuffer?]] = []
  var instanceBufferDoubleBonds: [[MTLBuffer?]] = []
  var instanceBufferPartialDoubleBonds: [[MTLBuffer?]] = []
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
    
    // imposter pipeline: the hull vertices are generated from the vertex-id, so no vertex descriptor is needed
    let imposterPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    imposterPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    imposterPipelineDescriptor.vertexFunction = library.makeFunction(name: "BondCylinderImposterVertexShader")!
    imposterPipelineDescriptor.sampleCount = maximumNumberOfSamples
    imposterPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    imposterPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    imposterPipelineDescriptor.fragmentFunction = library.makeFunction(name: "BondCylinderImposterFragmentShader")!
    do
    {
      self.imposterPipeLine = try device.makeRenderPipelineState(descriptor: imposterPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    // "fast" per-pixel quality mode: identical shading, but interpolated at the pixel
    // center so the fragment shader runs once per pixel even under MSAA
    imposterPipelineDescriptor.fragmentFunction = library.makeFunction(name: "BondCylinderImposterPerPixelFragmentShader")!
    do
    {
      self.perPixelImposterPipeLine = try device.makeRenderPipelineState(descriptor: imposterPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
  }
  
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBufferAllBonds = []
      instanceBufferSingleBonds = []
      instanceBufferDoubleBonds = []
      instanceBufferPartialDoubleBonds = []
      instanceBufferTripleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = renderStructures[i]
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
            let allBonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderInternalBonds ?? []
            let singleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.single.rawValue)}
            let doubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.double.rawValue)}
            let partialDoubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.partial_double.rawValue)}
            let tripleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.triple.rawValue)}
            
            let bufferAllBonds: MTLBuffer? = allBonds.isEmpty ? nil : device.makeBuffer(bytes: allBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * allBonds.count, options:RKMetal.hostStorage)
            let bufferSingleBonds: MTLBuffer? = singleBonds.isEmpty ? nil : device.makeBuffer(bytes: singleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * singleBonds.count, options:RKMetal.hostStorage)
            let bufferDoubleBonds: MTLBuffer? = doubleBonds.isEmpty ? nil : device.makeBuffer(bytes: doubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * doubleBonds.count, options:RKMetal.hostStorage)
            let bufferPartialDoubleBonds: MTLBuffer? = partialDoubleBonds.isEmpty ? nil : device.makeBuffer(bytes: partialDoubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * partialDoubleBonds.count, options:RKMetal.hostStorage)
            let bufferTripleBonds: MTLBuffer? = tripleBonds.isEmpty ? nil : device.makeBuffer(bytes: tripleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * tripleBonds.count, options:RKMetal.hostStorage)
            
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
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    // draw internal bonds
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderBondSource}.reduce(false, {$0 || $1.drawBonds}))
    {
      commandEncoder.setRenderPipelineState(RKMetal.perSampleImposterShading ? imposterPipeLine : perPixelImposterPipeLine)
      // the imposter hull is generated in the vertex shader with view-dependent winding
      commandEncoder.setCullMode(MTLCullMode.none)
      
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      var index: Int = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
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
            
              MetalInternalBondShader.drawBonds(commandEncoder, imposterVertexCount: 18, instanceCount: instanceCount)
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
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              MetalInternalBondShader.drawBonds(commandEncoder, imposterVertexCount: 18, instanceCount: instanceCount)
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
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              MetalInternalBondShader.drawBonds(commandEncoder, imposterVertexCount: 36, instanceCount: instanceCount)
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
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferPartialDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              MetalInternalBondShader.drawBonds(commandEncoder, imposterVertexCount: 18, instanceCount: instanceCount)
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
             let buffer: MTLBuffer = self.metalBuffer(instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (!structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            
              MetalInternalBondShader.drawBonds(commandEncoder, imposterVertexCount: 54, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.setCullMode(MTLCullMode.back)
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
  
  // imposters use 18 hull-vertices per (sub-)cylinder, generated in the vertex shader
  static func drawBonds(_ commandEncoder: MTLRenderCommandEncoder, imposterVertexCount: Int, instanceCount: Int)
  {
    commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: imposterVertexCount, instanceCount: instanceCount)
  }
}
