/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import Cocoa
import simd

public class MetalCubeGeometry
{
  public let numberOfIndices: Int = 34
  public let numberOfVertexes: Int = 24
  
  public var indices: [UInt16] =
    [
      0,  1,  2,  3,  3,      // Face 0 - triangle strip ( v0,  v1,  v2,  v3)
      4,  4,  5,  6,  7,  7,  // Face 1 - triangle strip ( v4,  v5,  v6,  v7)
      8,  8,  9, 10, 11, 11,  // Face 2 - triangle strip ( v8,  v9, v10, v11)
      12, 12, 13, 14, 15, 15, // Face 3 - triangle strip (v12, v13, v14, v15)
      16, 16, 17, 18, 19, 19, // Face 4 - triangle strip (v16, v17, v18, v19)
      20, 20, 21, 22, 23      // Face 5 - triangle strip (v20, v21, v22, v23)
  ]
  
  public var vertices: [RKVertex] =
    [
      // face 0 (front)
      RKVertex(position: float4(x: -1.0 , y: -1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: 1.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: 1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: 1.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: -1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: 1.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: 1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: 1.0, w: 0.0), st: float2()),
      
      // face 1 (right)
      RKVertex(position: float4(x: 1.0 , y: -1.0, z: 1.0, w: 0.0), normal: float4(x: 1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: 1.0, z: 1.0, w: 0.0), normal: float4(x: 1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: -1.0, z: -1.0, w: 0.0), normal: float4(x: 1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: 1.0, z: -1.0, w: 0.0), normal: float4(x: 1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      
      // face 2 (back)
      RKVertex(position: float4(x: 1.0 , y: -1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: -1.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: 1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: -1.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: -1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: -1.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: 1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: 0.0, z: -1.0, w: 0.0), st: float2()),
      
      // face 3 (left)
      RKVertex(position: float4(x: -1.0 , y: -1.0, z: -1.0, w: 0.0), normal: float4(x: -1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: 1.0, z: -1.0, w: 0.0), normal: float4(x: -1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: -1.0, z: 1.0, w: 0.0), normal: float4(x: -1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: 1.0, z: 1.0, w: 0.0), normal: float4(x: -1.0 , y: 0.0, z: 0.0, w: 0.0), st: float2()),
      
      // face 4 (bottom)
      RKVertex(position: float4(x: -1.0 , y: -1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: -1.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: -1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: -1.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: -1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: -1.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: -1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: -1.0, z: 0.0, w: 0.0), st: float2()),
      
      // face 5 (top)
      RKVertex(position: float4(x: -1.0 , y: 1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: 1.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: -1.0 , y: 1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: 1.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: 1.0, z: 1.0, w: 0.0), normal: float4(x: 0.0 , y: 1.0, z: 0.0, w: 0.0), st: float2()),
      RKVertex(position: float4(x: 1.0 , y: 1.0, z: -1.0, w: 0.0), normal: float4(x: 0.0 , y: 1.0, z: 0.0, w: 0.0), st: float2())
  ]
  
  
  public init()
  {
  }
}
