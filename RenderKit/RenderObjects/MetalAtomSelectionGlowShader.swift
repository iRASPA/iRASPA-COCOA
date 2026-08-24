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

// The glow effect itself is drawn by the imposter glow shaders; this class only owns
// the off-screen glow textures and render-pass descriptor those shaders render into.
class MetalAtomSelectionGlowShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var atomSelectionGlowRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  var atomSelectionGlowTexture: MTLTexture! = nil
  var atomSelectionGlowResolveTexture: MTLTexture! = nil

  /// The same glow pass, but depth-testing against what the path tracer drew rather than against the
  /// rasterizer's depth. See `tracedDepthWriteFragment` for why the two cannot be the same attachment.
  var atomSelectionGlowTracedRenderPassDescriptor: MTLRenderPassDescriptor! = nil

  /// Holds the tracer's composite depth for the glow pass to test against. A texture of its own rather
  /// than the scene's, which is still wanted unaltered by the compositing pass that reads it.
  ///
  /// Multisampled to match the pass it stands in, but the tracer records one depth per pixel, so every
  /// sample of a pixel receives the same one. That leaves a glow silhouette a pixel ragged where an
  /// atom in front of it cuts it off, which does not show through a blur several pixels wide.
  private var tracedDepthTexture: MTLTexture! = nil

  /// Fills `tracedDepthTexture` from the tracer's composite depth buffer.
  private var tracedDepthRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  private var tracedDepthPipeLine: MTLRenderPipelineState! = nil
  private var tracedDepthDepthState: MTLDepthStencilState! = nil
  private var vertexBuffer: MTLBuffer! = nil
  private var indexBuffer: MTLBuffer! = nil

  public func buildVertexBuffers(device: MTLDevice)
  {
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length: MemoryLayout<RKVertex>.stride * quad.vertices.count, options: RKMetal.hostStorage)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length: MemoryLayout<UInt16>.stride * quad.indices.count, options: RKMetal.hostStorage)
  }

  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor, maximumNumberOfSamples: Int)
  {
    // Multisampled, and with a stencil format, because it stands in for the scene's depth attachment
    // in a pass whose other attachments and whose glow imposter pipelines are all built that way.
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.invalid
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "texturedQuadVertex")
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "tracedDepthWriteFragment")
    pipelineDescriptor.vertexDescriptor = vertexDescriptor

    do
    {
      self.tracedDepthPipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating traced-depth pipeline state \(error)")
    }

    let depthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDescriptor.depthCompareFunction = MTLCompareFunction.always
    depthStateDescriptor.isDepthWriteEnabled = true
    self.tracedDepthDepthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)
  }

  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int, sceneDepthTexture: MTLTexture)
  {
    let atomSelectionGlowTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: RKMetal.extendedDynamicRangePixelFormat, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    atomSelectionGlowTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    atomSelectionGlowTextureDescriptor.sampleCount = maximumNumberOfSamples
    atomSelectionGlowTextureDescriptor.storageMode = MTLStorageMode.private
    atomSelectionGlowTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    atomSelectionGlowTexture = device.makeTexture(descriptor: atomSelectionGlowTextureDescriptor)
    atomSelectionGlowTexture.label = "glow atoms texture"
    
    let atomSelectionGlowResolveTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: RKMetal.extendedDynamicRangePixelFormat, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    atomSelectionGlowResolveTextureDescriptor.textureType = MTLTextureType.type2D
    atomSelectionGlowResolveTextureDescriptor.storageMode = MTLStorageMode.private
    atomSelectionGlowResolveTexture = device.makeTexture(descriptor: atomSelectionGlowResolveTextureDescriptor)
    atomSelectionGlowResolveTexture.label = "glow resolved texture"
    
    atomSelectionGlowRenderPassDescriptor = MTLRenderPassDescriptor()
    let glowAtomsColorAttachment: MTLRenderPassColorAttachmentDescriptor = atomSelectionGlowRenderPassDescriptor.colorAttachments[0]
    glowAtomsColorAttachment.texture = atomSelectionGlowTexture
    glowAtomsColorAttachment.loadAction = MTLLoadAction.clear
    glowAtomsColorAttachment.storeAction = MTLStoreAction.store
    glowAtomsColorAttachment.resolveTexture = atomSelectionGlowResolveTexture
    glowAtomsColorAttachment.storeAction = MTLStoreAction.multisampleResolve
    
    let glowAtomsDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = atomSelectionGlowRenderPassDescriptor.depthAttachment
    glowAtomsDepthAttachment.texture = sceneDepthTexture
    glowAtomsDepthAttachment.loadAction = MTLLoadAction.load
    glowAtomsDepthAttachment.storeAction = MTLStoreAction.dontCare
    
    let glowAtomsStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = atomSelectionGlowRenderPassDescriptor.stencilAttachment
    glowAtomsStencilAttachment.texture = sceneDepthTexture
    glowAtomsStencilAttachment.loadAction = MTLLoadAction.clear
    glowAtomsStencilAttachment.storeAction = MTLStoreAction.dontCare
    glowAtomsStencilAttachment.clearStencil = 0

    let tracedDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float_stencil8, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    tracedDepthTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    tracedDepthTextureDescriptor.sampleCount = maximumNumberOfSamples
    tracedDepthTextureDescriptor.storageMode = MTLStorageMode.private
    tracedDepthTextureDescriptor.usage = [MTLTextureUsage.renderTarget]
    tracedDepthTexture = device.makeTexture(descriptor: tracedDepthTextureDescriptor)
    tracedDepthTexture.label = "glow traced depth texture"

    tracedDepthRenderPassDescriptor = MTLRenderPassDescriptor()
    let tracedDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = tracedDepthRenderPassDescriptor.depthAttachment
    tracedDepthAttachment.texture = tracedDepthTexture
    tracedDepthAttachment.loadAction = MTLLoadAction.dontCare
    tracedDepthAttachment.storeAction = MTLStoreAction.store

    let tracedDepthStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = tracedDepthRenderPassDescriptor.stencilAttachment
    tracedDepthStencilAttachment.texture = tracedDepthTexture
    tracedDepthStencilAttachment.loadAction = MTLLoadAction.dontCare
    tracedDepthStencilAttachment.storeAction = MTLStoreAction.dontCare

    atomSelectionGlowTracedRenderPassDescriptor = MTLRenderPassDescriptor()
    let tracedGlowColorAttachment: MTLRenderPassColorAttachmentDescriptor = atomSelectionGlowTracedRenderPassDescriptor.colorAttachments[0]
    tracedGlowColorAttachment.texture = atomSelectionGlowTexture
    tracedGlowColorAttachment.loadAction = MTLLoadAction.clear
    tracedGlowColorAttachment.resolveTexture = atomSelectionGlowResolveTexture
    tracedGlowColorAttachment.storeAction = MTLStoreAction.multisampleResolve

    let tracedGlowDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = atomSelectionGlowTracedRenderPassDescriptor.depthAttachment
    tracedGlowDepthAttachment.texture = tracedDepthTexture
    tracedGlowDepthAttachment.loadAction = MTLLoadAction.load
    tracedGlowDepthAttachment.storeAction = MTLStoreAction.dontCare

    let tracedGlowStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = atomSelectionGlowTracedRenderPassDescriptor.stencilAttachment
    tracedGlowStencilAttachment.texture = tracedDepthTexture
    tracedGlowStencilAttachment.loadAction = MTLLoadAction.clear
    tracedGlowStencilAttachment.storeAction = MTLStoreAction.dontCare
    tracedGlowStencilAttachment.clearStencil = 0
  }

  /// Copies `tracedDepthBuffer` into the depth attachment the traced glow pass tests against. Has to
  /// precede that pass in the same command buffer.
  public func encodeTracedDepth(_ commandBuffer: MTLCommandBuffer, tracedDepthBuffer: MTLBuffer, size: CGSize)
  {
    guard let tracedDepthPipeLine,
          let tracedDepthDepthState,
          let tracedDepthRenderPassDescriptor,
          let vertexBuffer,
          let indexBuffer else {return}

    guard let encoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: tracedDepthRenderPassDescriptor) else {return}
    encoder.label = "Traced depth for the selection glow"
    encoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    encoder.setRenderPipelineState(tracedDepthPipeLine)
    encoder.setDepthStencilState(tracedDepthDepthState)
    var pixelSize: SIMD2<UInt32> = SIMD2<UInt32>(UInt32(max(Int(size.width),1)), UInt32(max(Int(size.height),1)))
    encoder.setFragmentBytes(&pixelSize, length: MemoryLayout<SIMD2<UInt32>>.stride, index: 0)
    encoder.setFragmentBuffer(tracedDepthBuffer, offset: 0, index: 1)
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    encoder.endEncoding()
  }
}
