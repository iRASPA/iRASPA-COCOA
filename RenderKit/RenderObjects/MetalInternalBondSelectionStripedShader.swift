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

class MetalInternalBondSelectionStripedShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var imposterPipeLine: MTLRenderPipelineState! = nil
  /// The same overlay with its depth evaluated per MSAA sample. Bound while the scene bonds shade
  /// per-sample, so the overlay and the bond it depth-tests against are measured at the same points;
  /// at mixed rates the test is off by the depth slope times the sample offset, which outgrows the
  /// overlay's clearance on the cylinder's flanks and flips there in screen-aligned bands; see
  /// BondSelectionImposterPerSampleFragmentShaderIn.
  var perSampleImposterPipeLine: MTLRenderPipelineState! = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let transparentDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepthStateDescriptor.isDepthWriteEnabled = false
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepthStateDescriptor)
    
    // imposter pipeline: the hull vertices are generated from the vertex-id, so no vertex descriptor is needed
    let imposterPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    imposterPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    imposterPipelineDescriptor.vertexFunction = library.makeFunction(name: "internalBondSelectionImposterVertexShader")!
    imposterPipelineDescriptor.sampleCount = maximumNumberOfSamples
    imposterPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    imposterPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    imposterPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    imposterPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    imposterPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    imposterPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    imposterPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    imposterPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    imposterPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    imposterPipelineDescriptor.fragmentFunction = library.makeFunction(name: "internalBondSelectionStripedImposterFragmentShader")!
    do
    {
      self.imposterPipeLine = try device.makeRenderPipelineState(descriptor: imposterPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }
    
    imposterPipelineDescriptor.fragmentFunction = library.makeFunction(name: "internalBondSelectionStripedImposterPerSampleFragmentShader")!
    do
    {
      self.perSampleImposterPipeLine = try device.makeRenderPipelineState(descriptor: imposterPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, instanceRenderer: MetalInternalBondSelectionShader, bondShader: MetalInternalBondShader, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    // draw internal bonds
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderBondSource}.reduce(false, {$0 || $1.drawBonds}))
    {
      // same rate as the scene bonds; see perSampleImposterPipeLine
      commandEncoder.setRenderPipelineState(RKMetal.perSampleImposterShading ? perSampleImposterPipeLine : imposterPipeLine)
      
      commandEncoder.setDepthStencilState(self.transparentDepthState)
      // the imposter hull is generated in the vertex shader with view-dependent winding
      // the imposter hull is generated in the vertex shader with view-dependent winding
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      
      var index: Int = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferAllBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .striped && structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
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
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferSingleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .striped && !structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
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
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferDoubleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .striped && !structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
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
            let buffer: MTLBuffer = self.metalBuffer(instanceRenderer.instanceBufferTripleBonds, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
            if (structure.bondSelectionStyle == .striped && !structure.isUnity && structure.drawBonds && structure.isVisible && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
            
              MetalInternalBondShader.drawBonds(commandEncoder, imposterVertexCount: 54, instanceCount: instanceCount)
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

