/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

import Metal

enum RKMetal
{
  // Shade the ray-traced imposters per-sample under MSAA, anti-aliasing their
  // silhouettes, clipping and depth. Set to false for a "fast" quality mode that
  // shades once per pixel (MSAA then only smooths the hull edges, not the
  // ray-traced edges).
  static var perSampleImposterShading: Bool = true

  static var hostStorage: MTLResourceOptions
  {
    #if os(macOS)
    return MTLResourceOptions.storageModeManaged
    #else
    return MTLResourceOptions.storageModeShared
    #endif
  }

  static var hostStorageMode: MTLStorageMode
  {
    #if os(macOS)
    return MTLStorageMode.managed
    #else
    return MTLStorageMode.shared
    #endif
  }

  static var isManagedStorage: Bool
  {
    #if os(macOS)
    return true
    #else
    return false
    #endif
  }

  static func didModify(_ buffer: MTLBuffer?, range: Range<Int>)
  {
    #if os(macOS)
    buffer?.didModifyRange(range)
    #endif
  }

  static func synchronize(_ encoder: MTLBlitCommandEncoder, resource: MTLResource)
  {
    #if os(macOS)
    encoder.synchronize(resource: resource)
    #endif
  }
}
