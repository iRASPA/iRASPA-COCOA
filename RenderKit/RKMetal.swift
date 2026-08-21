/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

import Metal
import CoreGraphics

enum RKMetal
{
  // Shade the ray-traced imposters per-sample under MSAA, anti-aliasing their
  // silhouettes, clipping and depth. Set to false for a "fast" quality mode that
  // shades once per pixel and writes silhouette coverage as alpha; those pipelines
  // enable alpha-to-coverage so the MSAA depth still has a fractional rim.
  static var perSampleImposterShading: Bool = true

  /// Format of the on-screen drawable and of the selection-glow chain that feeds it. A float format
  /// is what makes extended dynamic range possible at all: a normalized format cannot hold a value
  /// above 1.0, so the compositor would never be handed one however much headroom the display has.
  /// Picture and movie exports keep their own 8- and 16-bit normalized formats and are untouched.
  static let extendedDynamicRangePixelFormat: MTLPixelFormat = MTLPixelFormat.rgba16Float

  /// The colour space the drawable is presented in. This one keeps the sRGB transfer curve and only
  /// lets values run past 1.0, so every pixel already inside [0,1] is encoded exactly as it was
  /// before EDR was switched on and the image is unchanged; only what exceeds standard white is new.
  /// The linear variants would instead reinterpret every existing pixel and shift the whole look.
  static var extendedDynamicRangeColorSpace: CGColorSpace?
  {
    return CGColorSpace(name: CGColorSpace.extendedSRGB)
  }

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
