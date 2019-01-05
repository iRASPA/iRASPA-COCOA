//
//  MetalMeasurementShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalMeasurementShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  var numberOfDrawnMeasurementAtoms: Int = 0
  var renderMeasurementStructure: [RKRenderStructure] = []
  
  var pipeLine: MTLRenderPipelineState! = nil
  var instanceBuffer: MTLBuffer? = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    if let project: RKRenderDataSource = renderDataSource
    {
      let atomData: [RKInPerInstanceAttributesAtoms] = project.renderMeasurementPoints
      
      self.numberOfDrawnMeasurementAtoms = atomData.count
      self.renderMeasurementStructure = project.renderMeasurementStructure
      
      if self.numberOfDrawnMeasurementAtoms > 0
      {
        self.instanceBuffer = device.makeBuffer(bytes: atomData, length: atomData.count * MemoryLayout<RKInPerInstanceAttributesAtoms>.stride, options: .storageModeManaged)
      }
    }
  }
}
