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
import MetalKit
import MathKit

public class MetalBackgroundShader
{
  var renderDataSource: RKRenderDataSource? = nil
  
  var pipeLine: MTLRenderPipelineState! = nil
  var texture: MTLTexture! = nil
  var renderPassDescriptor: MTLRenderPassDescriptor! = nil
  
  var sceneRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  var sceneRenderVolumeRenderedSurfacesPassDescriptor: MTLRenderPassDescriptor! = nil
  var sceneRenderTransparentPassDescriptor: MTLRenderPassDescriptor! = nil
  var sceneTexture: MTLTexture! = nil
  var sceneDepthTexture: MTLTexture! = nil
  var sceneResolveTexture: MTLTexture! = nil
  var sceneResolvedDepthTexture: MTLTexture! = nil
  
  public var vertexBuffer: MTLBuffer! = nil
  public var indexBuffer: MTLBuffer! = nil
  public var samplerState: MTLSamplerState! = nil

  /// iOS/tvOS GPUs reject MSAA resolve of `depth32Float_stencil8`; Mac supports it.
  private var supportsHardwareDepthResolve: Bool
  {
    #if os(iOS) || os(tvOS)
    return false
    #else
    return true
    #endif
  }

  private var depthResolvePipeLine: MTLRenderPipelineState! = nil
  private var depthResolveDepthState: MTLDepthStencilState! = nil
  private var depthResolvePassDescriptor: MTLRenderPassDescriptor! = nil
  
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
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "backgroundQuadVertex")!
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "backgroundQuadFragment")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }

    if !supportsHardwareDepthResolve
    {
      let resolveDescriptor = MTLRenderPipelineDescriptor()
      resolveDescriptor.colorAttachments[0].pixelFormat = .invalid
      resolveDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
      resolveDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
      resolveDescriptor.sampleCount = 1
      resolveDescriptor.vertexFunction = library.makeFunction(name: "backgroundQuadVertex")
      resolveDescriptor.fragmentFunction = library.makeFunction(name: "depthMSAAResolveFragment")
      resolveDescriptor.vertexDescriptor = vertexDescriptor
      do
      {
        self.depthResolvePipeLine = try device.makeRenderPipelineState(descriptor: resolveDescriptor)
      }
      catch
      {
        fatalError("Error occurred when creating depth-resolve pipeline state \(error)")
      }

      let depthStateDescriptor = MTLDepthStencilDescriptor()
      depthStateDescriptor.depthCompareFunction = .always
      depthStateDescriptor.isDepthWriteEnabled = true
      self.depthResolveDepthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length:MemoryLayout<RKVertex>.stride * quad.vertices.count, options:RKMetal.hostStorage)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length:MemoryLayout<UInt16>.stride * quad.indices.count, options:RKMetal.hostStorage)
  }
  
  
  public func renderBackgroundWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    commandEncoder.label = "Background command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setRenderPipelineState(self.pipeLine)
    commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
    commandEncoder.setFragmentTexture(self.texture, index: 0)
    commandEncoder.setFragmentSamplerState(samplerState, index: 0)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
  }
  
  
  public func buildPermanentTextures(device: MTLDevice)
  {
    let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: 1024, height: 1024, mipmapped: false)
    textureDescriptor.textureType = MTLTextureType.type2D
    textureDescriptor.storageMode = MTLStorageMode.private
    texture = device.makeTexture(descriptor: textureDescriptor)
    texture.label = "background texture"
    
    let textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
    texture = try! textureLoader.newTexture(cgImage: defaultBackGround, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
  }
  
  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int)
  {
    let sceneTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    sceneTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    sceneTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    sceneTextureDescriptor.sampleCount = maximumNumberOfSamples
    sceneTextureDescriptor.storageMode = MTLStorageMode.private
    sceneTexture = device.makeTexture(descriptor: sceneTextureDescriptor)
    sceneTexture.label = "scene multisampled texture"
    
    let sceneResolveTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    sceneResolveTextureDescriptor.textureType = MTLTextureType.type2D
    sceneResolveTextureDescriptor.storageMode = MTLStorageMode.private
    sceneResolveTexture = device.makeTexture(descriptor: sceneResolveTextureDescriptor)
    sceneResolveTexture.label = "scene resolved texture"
    
    let sceneDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float_stencil8, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    sceneDepthTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    sceneDepthTextureDescriptor.sampleCount = maximumNumberOfSamples
    sceneDepthTextureDescriptor.storageMode = MTLStorageMode.private
    // On iOS the MSAA depth is sampled by the manual resolve pass.
    sceneDepthTextureDescriptor.usage = supportsHardwareDepthResolve
      ? MTLTextureUsage.renderTarget
      : [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
    sceneDepthTexture = device.makeTexture(descriptor: sceneDepthTextureDescriptor)
    sceneDepthTexture.label = "scene multisampled depth texture"
    
    let sceneResolveDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float_stencil8, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    sceneResolveDepthTextureDescriptor.textureType = MTLTextureType.type2D
    sceneResolveDepthTextureDescriptor.storageMode = MTLStorageMode.private
    sceneResolveDepthTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    sceneResolvedDepthTexture = device.makeTexture(descriptor: sceneResolveDepthTextureDescriptor)
    sceneResolvedDepthTexture.label = "scene multisampled resolved depth texture"
    
    
    // Opaque scene descriptor
    // =================================================================================================================
    sceneRenderPassDescriptor = MTLRenderPassDescriptor()
    let sceneMSAAcolorAttachment: MTLRenderPassColorAttachmentDescriptor = sceneRenderPassDescriptor.colorAttachments[0]
    sceneMSAAcolorAttachment.texture = sceneTexture
    sceneMSAAcolorAttachment.loadAction = MTLLoadAction.load
    sceneMSAAcolorAttachment.storeAction =  MTLStoreAction.store
    
    let sceneMSAAdepthAttachment: MTLRenderPassDepthAttachmentDescriptor = sceneRenderPassDescriptor.depthAttachment
    sceneMSAAdepthAttachment.texture = sceneDepthTexture
    sceneMSAAdepthAttachment.loadAction = MTLLoadAction.clear
    sceneMSAAdepthAttachment.clearDepth = 1.0
    if supportsHardwareDepthResolve
    {
      sceneMSAAdepthAttachment.storeAction = .storeAndMultisampleResolve
      sceneMSAAdepthAttachment.resolveTexture = sceneResolvedDepthTexture
    }
    else
    {
      // Keep color MSAA; store MSAA depth and resolve it manually afterwards.
      sceneMSAAdepthAttachment.storeAction = .store
      sceneMSAAdepthAttachment.resolveTexture = nil
    }
    
    let sceneMSAAstencilAttachment: MTLRenderPassStencilAttachmentDescriptor = sceneRenderPassDescriptor.stencilAttachment
    sceneMSAAstencilAttachment.texture = sceneDepthTexture
    sceneMSAAstencilAttachment.loadAction = MTLLoadAction.clear
    sceneMSAAstencilAttachment.storeAction = MTLStoreAction.dontCare
    sceneMSAAstencilAttachment.clearStencil = 0
    
    // Volume-rendered surfaces scene descriptor
    // =================================================================================================================
    sceneRenderVolumeRenderedSurfacesPassDescriptor = MTLRenderPassDescriptor()
    let sceneVolumeRenderedSurfacesColorAttachment: MTLRenderPassColorAttachmentDescriptor = sceneRenderVolumeRenderedSurfacesPassDescriptor.colorAttachments[0]
    sceneVolumeRenderedSurfacesColorAttachment.texture = sceneTexture
    sceneVolumeRenderedSurfacesColorAttachment.loadAction = MTLLoadAction.load
    sceneVolumeRenderedSurfacesColorAttachment.storeAction = MTLStoreAction.store
    
    let sceneVolumeRenderedSurfacesDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = sceneRenderVolumeRenderedSurfacesPassDescriptor.depthAttachment
    sceneVolumeRenderedSurfacesDepthAttachment.texture = sceneDepthTexture
    sceneVolumeRenderedSurfacesDepthAttachment.loadAction = MTLLoadAction.load
    if supportsHardwareDepthResolve
    {
      sceneVolumeRenderedSurfacesDepthAttachment.storeAction = .storeAndMultisampleResolve
      sceneVolumeRenderedSurfacesDepthAttachment.resolveTexture = sceneResolvedDepthTexture
    }
    else
    {
      sceneVolumeRenderedSurfacesDepthAttachment.storeAction = .store
      sceneVolumeRenderedSurfacesDepthAttachment.resolveTexture = nil
    }
    
    let sceneVolumeRenderedSurfaceStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = sceneRenderVolumeRenderedSurfacesPassDescriptor.stencilAttachment
    sceneVolumeRenderedSurfaceStencilAttachment.texture = sceneDepthTexture
    sceneVolumeRenderedSurfaceStencilAttachment.loadAction = MTLLoadAction.dontCare
    sceneVolumeRenderedSurfaceStencilAttachment.storeAction = MTLStoreAction.dontCare
    sceneVolumeRenderedSurfaceStencilAttachment.clearStencil = 0
    
    
    // Transparent scene descriptor
    // =================================================================================================================
    sceneRenderTransparentPassDescriptor = MTLRenderPassDescriptor()
    let sceneTransparentMSAAcolorAttachment: MTLRenderPassColorAttachmentDescriptor = sceneRenderTransparentPassDescriptor.colorAttachments[0]
    sceneTransparentMSAAcolorAttachment.texture = sceneTexture
    sceneTransparentMSAAcolorAttachment.loadAction = MTLLoadAction.load
    sceneTransparentMSAAcolorAttachment.resolveTexture = sceneResolveTexture
    sceneTransparentMSAAcolorAttachment.storeAction = MTLStoreAction.multisampleResolve
    
    let sceneTransparentMSAAdepthAttachment: MTLRenderPassDepthAttachmentDescriptor = sceneRenderTransparentPassDescriptor.depthAttachment
    sceneTransparentMSAAdepthAttachment.texture = sceneDepthTexture
    sceneTransparentMSAAdepthAttachment.loadAction = MTLLoadAction.load
    sceneTransparentMSAAdepthAttachment.storeAction = MTLStoreAction.dontCare
    
    let sceneTransparentMSAAstencilAttachment: MTLRenderPassStencilAttachmentDescriptor = sceneRenderTransparentPassDescriptor.stencilAttachment
    sceneTransparentMSAAstencilAttachment.texture = sceneDepthTexture
    sceneTransparentMSAAstencilAttachment.loadAction = MTLLoadAction.dontCare
    sceneTransparentMSAAstencilAttachment.storeAction = MTLStoreAction.dontCare
    sceneMSAAstencilAttachment.clearStencil = 0

    if !supportsHardwareDepthResolve
    {
      let resolvePass = MTLRenderPassDescriptor()
      resolvePass.depthAttachment.texture = sceneResolvedDepthTexture
      resolvePass.depthAttachment.loadAction = .dontCare
      resolvePass.depthAttachment.storeAction = .store
      resolvePass.depthAttachment.clearDepth = 1.0
      resolvePass.stencilAttachment.texture = sceneResolvedDepthTexture
      resolvePass.stencilAttachment.loadAction = .dontCare
      resolvePass.stencilAttachment.storeAction = .dontCare
      depthResolvePassDescriptor = resolvePass
    }
  }

  /// Copies MSAA depth sample 0 into `sceneResolvedDepthTexture` when the GPU
  /// cannot hardware-resolve `depth32Float_stencil8` (iOS/tvOS). Color MSAA is unchanged.
  public func encodeManualDepthResolveIfNeeded(_ commandBuffer: MTLCommandBuffer, size: CGSize)
  {
    guard !supportsHardwareDepthResolve,
          let depthResolvePipeLine,
          let depthResolveDepthState,
          let depthResolvePassDescriptor,
          let sceneDepthTexture,
          let vertexBuffer,
          let indexBuffer else { return }

    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthResolvePassDescriptor) else { return }
    encoder.label = "Manual MSAA depth resolve"
    encoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    encoder.setRenderPipelineState(depthResolvePipeLine)
    encoder.setDepthStencilState(depthResolveDepthState)
    encoder.setFragmentTexture(sceneDepthTexture, index: 0)
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    encoder.endEncoding()
  }
  
  func reloadBackgroundImage(device: MTLDevice)
  {
    if let crystalProjectData: RKRenderDataSource = renderDataSource
    {
      let textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
      switch(crystalProjectData.renderBackgroundType)
      {
      case .color:
        if let cgImageRef: CGImage = crystalProjectData.renderBackgroundCachedImage
        {
          self.texture = try! textureLoader.newTexture(cgImage: cgImageRef, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        else
        {
          self.texture = try! textureLoader.newTexture(cgImage: defaultBackGround, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        break
      case .linearGradient:
        if let cgImageRef: CGImage = crystalProjectData.renderBackgroundCachedImage
        {
          self.texture = try! textureLoader.newTexture(cgImage: cgImageRef, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        else
        {
          self.texture = try! textureLoader.newTexture(cgImage: defaultBackGround, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        break
      case .radialGradient:
        if let cgImageRef: CGImage = crystalProjectData.renderBackgroundCachedImage
        {
          self.texture = try! textureLoader.newTexture(cgImage: cgImageRef, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        else
        {
          self.texture = try! textureLoader.newTexture(cgImage: defaultBackGround, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        break
      case .image:
        if let cgImageRef: CGImage = crystalProjectData.renderBackgroundCachedImage
        {
          self.texture = try! textureLoader.newTexture(cgImage: cgImageRef, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        else
        {
          self.texture = try! textureLoader.newTexture(cgImage: defaultBackGround, options: [MTKTextureLoader.Option.textureUsage:MTLTextureUsage.shaderRead.rawValue as NSObject])
        }
        break
      }
    }
    
  }
  
  var defaultBackGround: CGImage
  {
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
    let context: CGContext = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 1024 * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    
    context.setFillColor(NSColor.white.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    
    let image: CGImage = context.makeImage()!
    
    return image
  }
  
  var transparentBackGround: CGImage
  {
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
    let context: CGContext = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 1024 * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    
    context.setFillColor(NSColor(white: 1.0, alpha: 0.99).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    
    let image: CGImage = context.makeImage()!
    
    return image
  }
  
}
