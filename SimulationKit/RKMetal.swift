/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

import Foundation
import Metal

enum RKMetal
{
  static var hostStorage: MTLResourceOptions
  {
    #if os(macOS)
    return MTLResourceOptions.storageModeManaged
    #else
    return MTLResourceOptions.storageModeShared
  #endif
  }

  static func loadDefaultLibrary(device: MTLDevice, bundle: Bundle) -> MTLLibrary
  {
    if let url = bundle.url(forResource: "default", withExtension: "metallib"),
       let library = try? device.makeLibrary(URL: url)
    {
      return library
    }
    if let file = bundle.path(forResource: "default", ofType: "metallib"),
       let library = try? device.makeLibrary(filepath: file)
    {
      return library
    }
    fatalError("SimulationKit default.metallib was not found in \(bundle.bundlePath)")
  }

  static func makePrivate3DTexture(device: MTLDevice, size: Int, pixelFormat: MTLPixelFormat, usage: MTLTextureUsage) -> MTLTexture?
  {
    let descriptor = MTLTextureDescriptor()
    descriptor.textureType = .type3D
    descriptor.width = size
    descriptor.height = size
    descriptor.depth = size
    descriptor.mipmapLevelCount = 1
    descriptor.pixelFormat = pixelFormat
    descriptor.storageMode = .private
    descriptor.usage = usage
    return device.makeTexture(descriptor: descriptor)
  }
}
