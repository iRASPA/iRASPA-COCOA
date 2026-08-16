/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

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
