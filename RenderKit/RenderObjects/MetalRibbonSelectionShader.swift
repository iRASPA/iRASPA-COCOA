/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import Metal

class MetalRibbonSelectionShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var glowPipeline: MTLRenderPipelineState! = nil
  var worleyPipeline: MTLRenderPipelineState! = nil
  var stripedPipeline: MTLRenderPipelineState! = nil
  var glowDepthState: MTLDepthStencilState! = nil
  var overlayDepthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor, maximumNumberOfSamples: Int)
  {
    let glowDepthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    glowDepthStateDesc.depthCompareFunction = .lessEqual
    glowDepthStateDesc.isDepthWriteEnabled = true
    glowDepthState = device.makeDepthStencilState(descriptor: glowDepthStateDesc)
    
    let overlayDepthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    overlayDepthStateDesc.depthCompareFunction = .lessEqual
    overlayDepthStateDesc.isDepthWriteEnabled = false
    overlayDepthState = device.makeDepthStencilState(descriptor: overlayDepthStateDesc)
    
    let glowPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    glowPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    glowPipelineDescriptor.vertexFunction = library.makeFunction(name: "RibbonSelectionGlowVertexShader")!
    glowPipelineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonSelectionGlowFragmentShader")!
    glowPipelineDescriptor.sampleCount = maximumNumberOfSamples
    glowPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
    glowPipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
    glowPipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      glowPipeline = try device.makeRenderPipelineState(descriptor: glowPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon-selection-glow render pipeline state \(error)")
    }
    
    let overlayPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    overlayPipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
    overlayPipelineDescriptor.sampleCount = maximumNumberOfSamples
    overlayPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
    overlayPipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
    overlayPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    overlayPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
    overlayPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
    overlayPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
    overlayPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
    overlayPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    overlayPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    overlayPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    overlayPipelineDescriptor.vertexFunction = library.makeFunction(name: "RibbonSelectionWorleyVertexShader")!
    overlayPipelineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonSelectionWorleyFragmentShader")!
    do
    {
      worleyPipeline = try device.makeRenderPipelineState(descriptor: overlayPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon-selection-worley render pipeline state \(error)")
    }
    
    overlayPipelineDescriptor.vertexFunction = library.makeFunction(name: "RibbonSelectionStripedVertexShader")!
    overlayPipelineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonSelectionStripedFragmentShader")!
    do
    {
      stripedPipeline = try device.makeRenderPipelineState(descriptor: overlayPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon-selection-striped render pipeline state \(error)")
    }
  }
  
  public func renderOverlayWithEncoder(_ commandEncoder: MTLRenderCommandEncoder,
                                       ribbonShader: MetalRibbonShader,
                                       frameUniformBuffer: MTLBuffer,
                                       structureUniformBuffers: MTLBuffer?,
                                       lightUniformBuffers: MTLBuffer?,
                                       size: CGSize)
  {
    guard renderDataSource != nil else {return}
    
    commandEncoder.setCullMode(.none)
    commandEncoder.setDepthStencilState(overlayDepthState)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
    
    var structureIndex: Int = 0
    for sceneIndex in 0..<renderStructures.count
    {
      let structures: [RKRenderObject] = renderStructures[sceneIndex]
      for (movieIndex, structure) in structures.enumerated()
      {
        if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
           let atomSource: RKRenderAtomSource = structure as? RKRenderAtomSource,
           let ribbonVertexBuffer: MTLBuffer = metalBuffer(ribbonShader.vertexBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex),
           let ribbonIndexBuffer: MTLBuffer = metalBuffer(ribbonShader.indexBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex),
           ribbonSource.drawRibbon,
           ribbonSource.isVisible,
           ribbonSource.ribbonNumberOfIndices > 0
        {
          let segmentIndices: Set<Int> = ribbonSource.renderSelectedRibbonSegmentDrawRangeIndices
          let residueIndices: Set<Int> = ribbonSource.renderSelectedRibbonResidueDrawRangeIndices
          if !segmentIndices.isEmpty || !residueIndices.isEmpty
          {
            let pipeline: MTLRenderPipelineState?
            switch atomSource.atomSelectionStyle
            {
            case .striped:
              pipeline = stripedPipeline
            case .glow:
              pipeline = nil
            default:
              pipeline = worleyPipeline
            }
            
            if let pipeline: MTLRenderPipelineState = pipeline
            {
              commandEncoder.setRenderPipelineState(pipeline)
              commandEncoder.setVertexBufferOffset(structureIndex * MemoryLayout<RKStructureUniforms>.stride, index: 2)
              commandEncoder.setFragmentBufferOffset(structureIndex * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              drawSelectedRanges(commandEncoder: commandEncoder,
                                 ribbonSource: ribbonSource,
                                 ribbonVertexBuffer: ribbonVertexBuffer,
                                 ribbonIndexBuffer: ribbonIndexBuffer,
                                 segmentIndices: segmentIndices,
                                 residueIndices: residueIndices)
            }
          }
        }
        structureIndex = structureIndex + 1
      }
    }
  }
  
  public func renderGlowWithEncoder(_ commandEncoder: MTLRenderCommandEncoder,
                                    ribbonShader: MetalRibbonShader,
                                    frameUniformBuffer: MTLBuffer,
                                    structureUniformBuffers: MTLBuffer?,
                                    lightUniformBuffers: MTLBuffer?,
                                    size: CGSize)
  {
    guard renderDataSource != nil else {return}
    
    commandEncoder.setDepthStencilState(glowDepthState)
    commandEncoder.setCullMode(.none)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
    
    var structureIndex: Int = 0
    for sceneIndex in 0..<renderStructures.count
    {
      let structures: [RKRenderObject] = renderStructures[sceneIndex]
      for (movieIndex, structure) in structures.enumerated()
      {
        if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
           let atomSource: RKRenderAtomSource = structure as? RKRenderAtomSource,
           let ribbonVertexBuffer: MTLBuffer = metalBuffer(ribbonShader.vertexBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex),
           let ribbonIndexBuffer: MTLBuffer = metalBuffer(ribbonShader.indexBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex),
           ribbonSource.drawRibbon,
           ribbonSource.isVisible,
           ribbonSource.ribbonNumberOfIndices > 0,
           atomSource.atomSelectionStyle == .glow
        {
          let segmentIndices: Set<Int> = ribbonSource.renderSelectedRibbonSegmentDrawRangeIndices
          let residueIndices: Set<Int> = ribbonSource.renderSelectedRibbonResidueDrawRangeIndices
          if !segmentIndices.isEmpty || !residueIndices.isEmpty
          {
            commandEncoder.setRenderPipelineState(glowPipeline)
            commandEncoder.setVertexBufferOffset(structureIndex * MemoryLayout<RKStructureUniforms>.stride, index: 2)
            commandEncoder.setFragmentBufferOffset(structureIndex * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            drawSelectedRanges(commandEncoder: commandEncoder,
                               ribbonSource: ribbonSource,
                               ribbonVertexBuffer: ribbonVertexBuffer,
                               ribbonIndexBuffer: ribbonIndexBuffer,
                               segmentIndices: segmentIndices,
                               residueIndices: residueIndices)
          }
        }
        structureIndex = structureIndex + 1
      }
    }
  }
  
  private func drawSelectedRanges(commandEncoder: MTLRenderCommandEncoder,
                                  ribbonSource: RKRenderRibbonSource,
                                  ribbonVertexBuffer: MTLBuffer,
                                  ribbonIndexBuffer: MTLBuffer,
                                  segmentIndices: Set<Int>,
                                  residueIndices: Set<Int>)
  {
    commandEncoder.setVertexBuffer(ribbonVertexBuffer, offset: 0, index: 0)
    
    for segmentIndex in segmentIndices.sorted()
    {
      guard segmentIndex >= 0 && segmentIndex < ribbonSource.ribbonSegmentDrawRanges.count else {continue}
      if ribbonSource.ribbonUsesSegmentVisibility && !ribbonSource.isRibbonSegmentDrawRangeVisible(at: segmentIndex) {continue}
      let drawRange: RKRibbonChainDrawRange = ribbonSource.ribbonSegmentDrawRanges[segmentIndex]
      guard drawRange.indexCount > 0 else {continue}
      commandEncoder.drawIndexedPrimitives(type: .triangle,
                                           indexCount: drawRange.indexCount,
                                           indexType: .uint32,
                                           indexBuffer: ribbonIndexBuffer,
                                           indexBufferOffset: drawRange.indexStart * MemoryLayout<UInt32>.stride)
    }
    
    for residueIndex in residueIndices.sorted()
    {
      guard residueIndex >= 0 && residueIndex < ribbonSource.ribbonResidueDrawRanges.count else {continue}
      if ribbonSource.ribbonUsesResidueVisibility && !ribbonSource.isRibbonResidueDrawRangeVisible(at: residueIndex) {continue}
      let drawRange: RKRibbonChainDrawRange = ribbonSource.ribbonResidueDrawRanges[residueIndex]
      guard drawRange.indexCount > 0 else {continue}
      commandEncoder.drawIndexedPrimitives(type: .triangle,
                                           indexCount: drawRange.indexCount,
                                           indexType: .uint32,
                                           indexBuffer: ribbonIndexBuffer,
                                           indexBufferOffset: drawRange.indexStart * MemoryLayout<UInt32>.stride)
    }
  }
  
  private func metalBuffer(_ buffer: [[MTLBuffer?]], sceneIndex: Int, movieIndex: Int) -> MTLBuffer?
  {
    if sceneIndex < buffer.count, movieIndex < buffer[sceneIndex].count
    {
      return buffer[sceneIndex][movieIndex]
    }
    return nil
  }
}
