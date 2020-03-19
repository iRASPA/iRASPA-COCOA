/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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

class MetalInternalBondSelectionShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var instanceBufferAllBonds: [[MTLBuffer?]] = [[]]
  var instanceBufferSingleBonds: [[MTLBuffer?]] = [[]]
  var instanceBufferDoubleBonds: [[MTLBuffer?]] = [[]]
  var instanceBufferPartialDoubleBonds: [[MTLBuffer?]] = [[]]
  var instanceBufferTripleBonds: [[MTLBuffer?]] = [[]]
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBufferAllBonds = []
      instanceBufferSingleBonds = []
      instanceBufferDoubleBonds = []
      instanceBufferPartialDoubleBonds = []
      instanceBufferTripleBonds = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstanceAllBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceSingleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceDoubleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstancePartialDoubleBonds: [MTLBuffer?] = [MTLBuffer?]()
        var sceneInstanceTripleBonds: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstanceSingleBonds.append(nil)
          sceneInstanceDoubleBonds.append(nil)
          sceneInstancePartialDoubleBonds.append(nil)
          sceneInstanceTripleBonds.append(nil)
        }
        else
        {
          for structure in structures
          {
            let allBonds: [RKInPerInstanceAttributesBonds] = (structure as? RKRenderBondSource)?.renderSelectedInternalBonds ?? []
            let singleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.single.rawValue)}
            let doubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.double.rawValue)}
            let partialDoubleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.partial_double.rawValue)}
            let tripleBonds: [RKInPerInstanceAttributesBonds] = allBonds.filter{$0.type == UInt32(SKAsymmetricBond.SKBondType.triple.rawValue)}
            
            let bufferAllBonds: MTLBuffer? = allBonds.isEmpty ? nil : device.makeBuffer(bytes: allBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * allBonds.count, options:.storageModeManaged)
            let bufferSingleBonds: MTLBuffer? = singleBonds.isEmpty ? nil : device.makeBuffer(bytes: singleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * singleBonds.count, options:.storageModeManaged)
            let bufferDoubleBonds: MTLBuffer? = doubleBonds.isEmpty ? nil : device.makeBuffer(bytes: doubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * doubleBonds.count, options:.storageModeManaged)
            let bufferPartialDoubleBonds: MTLBuffer? = partialDoubleBonds.isEmpty ? nil : device.makeBuffer(bytes: partialDoubleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * partialDoubleBonds.count, options:.storageModeManaged)
            let bufferTripleBonds: MTLBuffer? = tripleBonds.isEmpty ? nil : device.makeBuffer(bytes: tripleBonds, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * tripleBonds.count, options:.storageModeManaged)
            
            sceneInstanceAllBonds.append(bufferAllBonds)
            sceneInstanceSingleBonds.append(bufferSingleBonds)
            sceneInstanceDoubleBonds.append(bufferDoubleBonds)
            sceneInstancePartialDoubleBonds.append(bufferPartialDoubleBonds)
            sceneInstanceTripleBonds.append(bufferTripleBonds)
          }
        }
        instanceBufferAllBonds.append(sceneInstanceAllBonds)
        instanceBufferSingleBonds.append(sceneInstanceSingleBonds)
        instanceBufferDoubleBonds.append(sceneInstanceDoubleBonds)
        instanceBufferPartialDoubleBonds.append(sceneInstancePartialDoubleBonds)
        instanceBufferTripleBonds.append(sceneInstanceTripleBonds)
      }
    }

  }
  
}
