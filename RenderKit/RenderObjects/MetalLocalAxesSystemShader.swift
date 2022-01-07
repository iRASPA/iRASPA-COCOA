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
import SymmetryKit
import simd

class MetalLocalAxesShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var indexBuffer: [[MTLBuffer?]] = [[]]
  var vertexBuffer: [[MTLBuffer?]] = [[]]
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "LocalAxesSystemVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "LocalAxesSystemFragmentShader")!
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
    if let _: RKRenderDataSource = renderDataSource
    {
      vertexBuffer = []
      indexBuffer = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = renderStructures[i]
        var vertexBufferArray: [MTLBuffer?] = [MTLBuffer?]()
        var indexBufferArray: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          vertexBufferArray.append(nil)
          indexBufferArray.append(nil)
        }
        else
        {
          for structure in structures
          {
            let boundingBox: SKBoundingBox = structure.cell.boundingBox
            
            let axesGeometry: MetalAxesSystemDefaultGeometry
            if let structure = structure as? RKRenderLocalAxesSource
            {
              var length: Double = structure.renderLocalAxis.length
              let width: Double = structure.renderLocalAxis.width
              
              switch(structure.renderLocalAxis.scalingType)
              {
              case RKLocalAxes.ScalingType.absolute:
                break
              case RKLocalAxes.ScalingType.relative:
                length = boundingBox.shortestEdge * length / 100.0
              }
              
              switch(structure.renderLocalAxis.style)
              {
              case RKLocalAxes.Style.default:
                axesGeometry = MetalAxesSystemDefaultGeometry(center: RKGlobalAxes.CenterType.cube, centerRadius: width, centerColor: SIMD4<Float>(1.0,1.0,1.0,1.0), arrowHeight: length, arrowRadius: width, arrowColorX: SIMD4<Float>(1.0,0.4,0.7,1.0), arrowColorY: SIMD4<Float>(0.7,1.0,0.4,1.0), arrowColorZ: SIMD4<Float>(0.4,0.7,1.0,1.0), tipHeight: 1.0, tipRadius: 0.0, tipColorX: SIMD4<Float>(1.0,0.4,0.7,1.0), tipColorY: SIMD4<Float>(0.7,1.0,0.4,1.0), tipColorZ: SIMD4<Float>(0.4,0.7,1.0,1.0), tipVisibility: false, aspectRatio: 1.0, sectorCount: 4)
              case RKLocalAxes.Style.defaultRGB:
                axesGeometry = MetalAxesSystemDefaultGeometry(center: RKGlobalAxes.CenterType.cube, centerRadius: width, centerColor: SIMD4<Float>(1.0,1.0,1.0,1.0), arrowHeight: length, arrowRadius: width, arrowColorX: SIMD4<Float>(1.0,0.0,0.0,1.0), arrowColorY: SIMD4<Float>(0.0,1.0,0.0,1.0), arrowColorZ: SIMD4<Float>(0.0,0.0,1.0,1.0), tipHeight: 1.0, tipRadius: 0.0, tipColorX: SIMD4<Float>(1.0,0.0,0.0,1.0), tipColorY: SIMD4<Float>(0.0,1.0,0.0,1.0), tipColorZ: SIMD4<Float>(0.0,0.0,1.0,1.0), tipVisibility: false, aspectRatio: 1.0, sectorCount: 4)
              case RKLocalAxes.Style.cylinder:
                axesGeometry = MetalAxesSystemDefaultGeometry(center: RKGlobalAxes.CenterType.cube, centerRadius: width, centerColor: SIMD4<Float>(1.0,1.0,1.0,1.0), arrowHeight: length, arrowRadius: width, arrowColorX: SIMD4<Float>(1.0,0.4,0.7,1.0), arrowColorY: SIMD4<Float>(0.7,1.0,0.4,1.0), arrowColorZ: SIMD4<Float>(0.4,0.7,1.0,1.0), tipHeight: 1.0, tipRadius: 0.0, tipColorX: SIMD4<Float>(1.0,0.4,0.7,1.0), tipColorY: SIMD4<Float>(0.7,1.0,0.4,1.0), tipColorZ: SIMD4<Float>(0.4,0.7,1.0,1.0), tipVisibility: false, aspectRatio: 1.0, sectorCount: 41)
              case RKLocalAxes.Style.cylinderRGB:
                axesGeometry = MetalAxesSystemDefaultGeometry(center: RKGlobalAxes.CenterType.cube, centerRadius: width, centerColor: SIMD4<Float>(1.0,1.0,1.0,1.0), arrowHeight: length, arrowRadius: width, arrowColorX: SIMD4<Float>(1.0,0.0,0.0,1.0), arrowColorY: SIMD4<Float>(0.0,1.0,0.0,1.0), arrowColorZ: SIMD4<Float>(0.0,0.0,1.0,1.0), tipHeight: 1.0, tipRadius: 0.0, tipColorX: SIMD4<Float>(1.0,0.0,0.0,1.0), tipColorY: SIMD4<Float>(0.0,1.0,0.0,1.0), tipColorZ: SIMD4<Float>(0.0,0.0,1.0,1.0), tipVisibility: false, aspectRatio: 1.0, sectorCount: 41)
              }
              vertexBufferArray.append(device.makeBuffer(bytes: axesGeometry.vertices, length:MemoryLayout<RKPrimitiveVertex>.stride * axesGeometry.vertices.count, options:.storageModeManaged))
              indexBufferArray.append(device.makeBuffer(bytes: axesGeometry.indices, length:MemoryLayout<UInt16>.stride * axesGeometry.indices.count, options:.storageModeManaged))
            }
          }
          vertexBuffer.append(vertexBufferArray)
          indexBuffer.append(indexBufferArray)
        }
      }
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    
      commandEncoder.setRenderPipelineState(pipeLine)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      
      var index: Int = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let vertexBuffer = self.metalBuffer(vertexBuffer, sceneIndex: i, movieIndex: j),
             let indexBuffer = self.metalBuffer(indexBuffer, sceneIndex: i, movieIndex: j)
          {
            if (structure.isVisible)
            {
              if let structure = structure as? RKRenderLocalAxesSource,
                 structure.renderLocalAxis.position != RKLocalAxes.Position.none
              {
                commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 2)
                commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
                commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
              }
            }
          }
          index = index + 1
        }
      }
      
  }
  
  func metalBuffer(_ buffer: [[MTLBuffer?]], sceneIndex: Int, movieIndex: Int) -> MTLBuffer?
  {
    if sceneIndex < buffer.count
    {
      if movieIndex < buffer[sceneIndex].count
      {
        return buffer[sceneIndex][movieIndex]
      }
    }
    return nil
  }
}
