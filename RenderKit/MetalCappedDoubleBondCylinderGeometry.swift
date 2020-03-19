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
import Metal
import simd

public class MetalCappedDoubleBondCylinderGeometry
{
  var slices: Int
  public var numberOfIndices: Int
  public var numberOfVertexes: Int
  
  public var vertices: [RKVertex]
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(r: 0.8, s: 21)
  }
  
  public init(r: Double, s: Int)
  {
    slices = s
    numberOfVertexes = 2*(4 * slices + 2)
    numberOfIndices = 2*(12 * slices)
    
    let bondCylinder: MetalCappedSingleBondCylinderGeometry = MetalCappedSingleBondCylinderGeometry(r: 0.8, s: 21)
    
    vertices = bondCylinder.vertices.map({RKVertex(position: $0.position + SIMD4<Float>(-1.0,0.0,0.0,0.0), normal: $0.normal, st: $0.st)}) +
               bondCylinder.vertices.map({RKVertex(position: $0.position + SIMD4<Float>(1.0,0.0,0.0,0.0), normal: $0.normal, st: $0.st)})
    
    indices = bondCylinder.indices + bondCylinder.indices.map({$0+UInt16(4 * s + 2)})
  }
}
