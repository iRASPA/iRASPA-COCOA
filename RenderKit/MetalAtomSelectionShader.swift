//
//  MetalAtomSelectionShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 18/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalAtomSelectionShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  
  var instanceBuffer: [[MTLBuffer?]] = [[]]
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBuffer = []
      
      for i in 0..<self.renderStructures.count
      {
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        let structures: [RKRenderStructure] = renderStructures[i]
        
        for structure in structures
        {
          let atomPositions: [RKInPerInstanceAttributesAtoms] = structure.renderSelectedAtoms
          let buffer: MTLBuffer? = atomPositions.isEmpty ? nil : device.makeBuffer(bytes: atomPositions, length: MemoryLayout<RKInPerInstanceAttributesAtoms>.stride * atomPositions.count, options:.storageModeManaged)
          sceneInstance.append(buffer)
        }
        instanceBuffer.append(sceneInstance)
      }
    }
  }
  
}
