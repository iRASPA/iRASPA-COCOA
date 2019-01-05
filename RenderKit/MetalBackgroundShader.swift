//
//  MetalBackgroundShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation
import MetalKit

public class MetalBackgroundShader
{
  var renderDataSource: RKRenderDataSource? = nil
  
  var pipeLine: MTLRenderPipelineState! = nil
  var texture: MTLTexture! = nil
  var renderPassDescriptor: MTLRenderPassDescriptor! = nil
  
  var sceneRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  var sceneTexture: MTLTexture! = nil
  var sceneDepthTexture: MTLTexture! = nil
  var sceneResolveTexture: MTLTexture! = nil
  
  public var vertexBuffer: MTLBuffer! = nil
  public var indexBuffer: MTLBuffer! = nil
  public var samplerState: MTLSamplerState! = nil
  
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
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length:MemoryLayout<RKVertex>.stride * quad.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length:MemoryLayout<UInt16>.stride * quad.indices.count, options:.storageModeManaged)
  }
  
  
  public func renderBackgroundWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    //let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.label = "Background command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setRenderPipelineState(self.pipeLine)
    commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
    commandEncoder.setFragmentTexture(self.texture, index: 0)
    commandEncoder.setFragmentSamplerState(samplerState, index: 0)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
    //commandEncoder.endEncoding()
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
    let sceneTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
    sceneTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    sceneTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    sceneTextureDescriptor.sampleCount = maximumNumberOfSamples
    sceneTextureDescriptor.storageMode = MTLStorageMode.private
    sceneTexture = device.makeTexture(descriptor: sceneTextureDescriptor)
    sceneTexture.label = "scene multisampled texture"
    
    let sceneResolveTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
    sceneResolveTextureDescriptor.textureType = MTLTextureType.type2D
    sceneResolveTextureDescriptor.storageMode = MTLStorageMode.private
    sceneResolveTexture = device.makeTexture(descriptor: sceneResolveTextureDescriptor)
    sceneResolveTexture.label = "scene resolved texture"
    
    
    let sceneDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float_stencil8, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
    sceneDepthTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    sceneDepthTextureDescriptor.sampleCount = maximumNumberOfSamples
    sceneDepthTextureDescriptor.storageMode = MTLStorageMode.private
    sceneDepthTextureDescriptor.usage = MTLTextureUsage.renderTarget
    sceneDepthTexture = device.makeTexture(descriptor: sceneDepthTextureDescriptor)
    sceneDepthTexture.label = "scene multisampled depth texture"
    
    sceneRenderPassDescriptor = MTLRenderPassDescriptor()
    let sceneMSAAcolorAttachment: MTLRenderPassColorAttachmentDescriptor = sceneRenderPassDescriptor.colorAttachments[0]
    sceneMSAAcolorAttachment.texture = sceneTexture
    sceneMSAAcolorAttachment.loadAction = MTLLoadAction.load
    sceneMSAAcolorAttachment.resolveTexture = sceneResolveTexture
    sceneMSAAcolorAttachment.storeAction = MTLStoreAction.multisampleResolve
    
    
    let sceneMSAAdepthAttachment: MTLRenderPassDepthAttachmentDescriptor = sceneRenderPassDescriptor.depthAttachment
    sceneMSAAdepthAttachment.texture = sceneDepthTexture
    sceneMSAAdepthAttachment.loadAction = MTLLoadAction.clear
    sceneMSAAdepthAttachment.storeAction = MTLStoreAction.store
    sceneMSAAdepthAttachment.clearDepth = 1.0
    
    let sceneMSAAstencilAttachment: MTLRenderPassStencilAttachmentDescriptor = sceneRenderPassDescriptor.stencilAttachment
    sceneMSAAstencilAttachment.texture = sceneDepthTexture
    sceneMSAAstencilAttachment.loadAction = MTLLoadAction.clear
    sceneMSAAstencilAttachment.storeAction = MTLStoreAction.dontCare
    sceneMSAAstencilAttachment.clearStencil = 0
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
    
    let graphicsContext: NSGraphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    
    NSGraphicsContext.current = graphicsContext
    //NSGraphicsContext.setCurrent(graphicsContext)
    
    graphicsContext.cgContext.setFillColor(NSColor.white.cgColor)
    //CGContextSetRGBFillColor(graphicsContext.CGContext, 0.227,0.251,0.337,0.8)
    graphicsContext.cgContext.fill(NSMakeRect(0, 0, 1024, 1024))
    
    let image: CGImage = context.makeImage()!
    
    NSGraphicsContext.restoreGraphicsState()
    
    return image
  }
  
}
