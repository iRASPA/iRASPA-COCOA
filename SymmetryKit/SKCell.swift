/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import BinaryCodable
import simd
import MathKit

public struct SKCell: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 2
  
  public var zValue: Int = 1
  public var inverseUnitCell: double3x3 = double3x3()
  
  public var fullCell: double3x3 = double3x3()
  public var inverseFullCell: double3x3 = double3x3()
  
  public var boundingBox: SKBoundingBox = SKBoundingBox()
  
  public var contentShift: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
  public var contentFlip: Bool3 = Bool3(false,false,false)
  
  public var precision: Double = 1e-2
  
  public var enclosingBoundingBox: SKBoundingBox
  {
    let c0: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(minimumReplica.x),  y: Double(minimumReplica.y),  z: Double(minimumReplica.z))
    let c1: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(minimumReplica.z))
    let c2: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(minimumReplica.z))
    let c3: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(minimumReplica.z))
    let c4: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1))
    let c5: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1))
    let c6: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1))
    let c7: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1))
    
    let minimum = SIMD3<Double>(x: min(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                          y: min(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                          z: min(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))
    
    let maximum = SIMD3<Double>(x: max(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                          y: max(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                          z: max(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  private var corners: [SIMD3<Double>]
  {
    return [SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0),
            SIMD3<Double>(x: 1.0, y: 0.0, z: 0.0),
            SIMD3<Double>(x: 1.0, y: 1.0, z: 0.0),
            SIMD3<Double>(x: 0.0, y: 1.0, z: 0.0),
            SIMD3<Double>(x: 0.0, y: 0.0, z: 1.0),
            SIMD3<Double>(x: 1.0, y: 0.0, z: 1.0),
            SIMD3<Double>(x: 1.0, y: 1.0, z: 1.0),
            SIMD3<Double>(x: 0.0, y: 1.0, z: 1.0)]
  }
  
  
  public var unitCell: double3x3
  {
    didSet
    {
      inverseUnitCell = unitCell.inverse
      fullCell = unitCell
      
      let dx: Double = Double(maximumReplica[0] - minimumReplica[0] + 1)
      let dy: Double = Double(maximumReplica[1] - minimumReplica[1] + 1)
      let dz: Double = Double(maximumReplica[2] - minimumReplica[2] + 1)
      
      fullCell[0][0] *= dx;  fullCell[1][0] *= dy;  fullCell[2][0] *= dz;
      fullCell[0][1] *= dx;  fullCell[1][1] *= dy;  fullCell[2][1] *= dz;
      fullCell[0][2] *= dx;  fullCell[1][2] *= dy;  fullCell[2][2] *= dz;
      
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  
  public  init()
  {
    self.init(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
  }
  
  public init(a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
  {
    let temp: Double = (cos(alpha) - cos(gamma) * cos(beta)) / sin(gamma)
    
    let v1: SIMD3<Double> = SIMD3<Double>(x: a, y: 0.0, z: 0.0)
    let v2: SIMD3<Double> = SIMD3<Double>(x: b * cos(gamma), y: b * sin(gamma), z: 0.0)
    let v3: SIMD3<Double> = SIMD3<Double>(x: c * cos(beta), y: c * temp, z: c * sqrt(1.0 - cos(beta)*cos(beta)-temp*temp))
    unitCell = double3x3([v1, v2, v3])
    inverseUnitCell = unitCell.inverse
    fullCell = unitCell
    
    let dx: Double = Double(maximumReplica.x - minimumReplica.x + 1)
    let dy: Double = Double(maximumReplica.y - minimumReplica.y + 1)
    let dz: Double = Double(maximumReplica.z - minimumReplica.z + 1)
    
    fullCell[0][0] *= dx;  fullCell[1][0] *= dy;  fullCell[2][0] *= dz;
    fullCell[0][1] *= dx;  fullCell[1][1] *= dy;  fullCell[2][1] *= dz;
    fullCell[0][2] *= dx;  fullCell[1][2] *= dy;  fullCell[2][2] *= dz;
    
    inverseFullCell = fullCell.inverse
    
    //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
  }
  
  public init(boundingBox: SKBoundingBox)
  {
    self.minimumReplica = SIMD3<Int32>(0,0,0)
    self.maximumReplica = SIMD3<Int32>(0,0,0)
    
    let v1: SIMD3<Double> = SIMD3<Double>(boundingBox.maximum.x-boundingBox.minimum.x, 0.0, 0.0)
    let v2: SIMD3<Double> = SIMD3<Double>(0.0, boundingBox.maximum.y-boundingBox.minimum.y, 0.0)
    let v3: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, boundingBox.maximum.z-boundingBox.minimum.z)
    
    unitCell = double3x3([v1, v2, v3])
    inverseUnitCell = unitCell.inverse
    fullCell = unitCell
    inverseFullCell = fullCell.inverse
  }
  
  
  public init(cell: SKCell)
  {
    self.unitCell = cell.unitCell
    self.inverseUnitCell = cell.inverseUnitCell
    self.fullCell = cell.fullCell
    self.inverseFullCell = cell.inverseFullCell
    self.boundingBox = cell.boundingBox
    self.contentShift = cell.contentShift
  }
  
  public init(unitCell: double3x3)
  {
    self.unitCell = unitCell
    self.inverseUnitCell = unitCell.inverse
    self.fullCell = unitCell
    self.inverseFullCell = unitCell.inverse
    self.boundingBox = self.enclosingBoundingBox
  }
  
  
  public var minimumReplica: SIMD3<Int32> = SIMD3<Int32>(0,0,0)
  {
    didSet
    {
      let dx: Double = Double(maximumReplica.x - minimumReplica.x + 1)
      
      fullCell[0][0] = unitCell[0][0] * dx;
      fullCell[0][1] = unitCell[0][1] * dx;
      fullCell[0][2] = unitCell[0][2] * dx;
      
      let dy: Double = Double(maximumReplica.y - minimumReplica.y + 1)
      
      fullCell[1][0] = unitCell[1][0] * dy;
      fullCell[1][1] = unitCell[1][1] * dy;
      fullCell[1][2] = unitCell[1][2] * dy;
      
      let dz: Double = Double(maximumReplica.z - minimumReplica.z + 1)
      
      fullCell[2][0] = unitCell[2][0] * dz;
      fullCell[2][1] = unitCell[2][1] * dz;
      fullCell[2][2] = unitCell[2][2] * dz;
      
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var maximumReplica: SIMD3<Int32> = SIMD3<Int32>(0,0,0)
  {
    didSet
    {
      let dx: Double = Double(maximumReplica.x - minimumReplica.x + 1)
      
      fullCell[0][0] = unitCell[0][0] * dx;
      fullCell[0][1] = unitCell[0][1] * dx;
      fullCell[0][2] = unitCell[0][2] * dx;
      
      let dy: Double = Double(maximumReplica.y - minimumReplica.y + 1)
      
      fullCell[1][0] = unitCell[1][0] * dy;
      fullCell[1][1] = unitCell[1][1] * dy;
      fullCell[1][2] = unitCell[1][2] * dy;
      
      let dz: Double = Double(maximumReplica.z - minimumReplica.z + 1)
      
      fullCell[2][0] = unitCell[2][0] * dz;
      fullCell[2][1] = unitCell[2][1] * dz;
      fullCell[2][2] = unitCell[2][2] * dz;
      
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  
  // assumes for-loop in order (outer to inner): (1) atoms, (2) x, (3) y, (4) z
  public func replicaFromIndex(_ index: Int) -> SIMD3<Int32>
  {
    let dx: Int = maximumReplicaX - minimumReplicaX + 1
    let dy: Int = maximumReplicaY - minimumReplicaY + 1
    let dz: Int = maximumReplicaZ - minimumReplicaZ + 1
    let n: Int = dx * dy * dz
    
    let k1 = ( (index % n) / (dz * dy) ) + minimumReplicaX
    let k2 = ( (index % n) / dz ) % dy + minimumReplicaY
    let k3 = (index % n) % dz + minimumReplicaZ
    
    return SIMD3<Int32>(x: Int32(k1), y: Int32(k2), z: Int32(k3))
  }
  
  public init(superCell: SKCell)
  {
    let v1: SIMD3<Double> = Double(superCell.maximumReplica.x - superCell.minimumReplica.x + 1) * superCell.unitCell[0]
    let v2: SIMD3<Double> = Double(superCell.maximumReplica.y - superCell.minimumReplica.y + 1) * superCell.unitCell[1]
    let v3: SIMD3<Double> = Double(superCell.maximumReplica.z - superCell.minimumReplica.z + 1) * superCell.unitCell[2]
    unitCell = double3x3([v1, v2, v3])
    inverseUnitCell = unitCell.inverse
    fullCell = unitCell
    inverseFullCell = fullCell.inverse
    
    minimumReplica = SIMD3<Int32>(0,0,0)
    maximumReplica = SIMD3<Int32>(0,0,0)
    
    //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
  }
  
  
  
  public var box: double3x3
  {
    get
    {
      return fullCell
    }
    set(newValue)
    {
      fullCell = newValue
      inverseFullCell = newValue.inverse
      
      let dx = maximumReplica[0] - minimumReplica[0] + 1
      let dy = maximumReplica[1] - minimumReplica[1] + 1
      let dz = maximumReplica[2] - minimumReplica[2] + 1
      
      unitCell[0][0] /= Double(dx);  unitCell[1][0] /= Double(dy);  unitCell[2][0] /= Double(dz);
      unitCell[0][1] /= Double(dx);  unitCell[1][1] /= Double(dy);  unitCell[2][1] /= Double(dz);
      unitCell[0][2] /= Double(dx);  unitCell[1][2] /= Double(dy);  unitCell[2][2] /= Double(dz);
      
      inverseUnitCell = unitCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var translationVectors: [SIMD3<Double>]
  {
    var vectors: [SIMD3<Double>] = []
    
    for k3 in minimumReplicaZ...maximumReplicaZ
    {
      for k2 in minimumReplicaY...maximumReplicaY
      {
        for k1 in minimumReplicaX...maximumReplicaX
        {
          vectors.append(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
        }
      }
    }
    
    return vectors
  }
  
  public var renderTranslationVectors: [SIMD4<Float>]
  {
    var vectors: [SIMD4<Float>] = []
    
    for k3 in minimumReplica.z...maximumReplica.z
    {
      for k2 in minimumReplica.y...maximumReplica.y
      {
        for k1 in minimumReplica.x...maximumReplica.x
        {
          vectors.append(SIMD4<Float>(x: Float(k1), y: Float(k2), z: Float(k3), w: 0.0))
        }
      }
    }
    
    return vectors
  }
  
  public var numberOfReplicas: SIMD3<Int32>
  {
    let dx = maximumReplica.x - minimumReplica.x + 1
    let dy = maximumReplica.y - minimumReplica.y + 1
    let dz = maximumReplica.z - minimumReplica.z + 1
      
    return SIMD3<Int32>(dx,dy,dz)
  }
  
  public var totalNumberOfReplicas: Int
  {
    let dx = maximumReplica.x - minimumReplica.x + 1
    let dy = maximumReplica.y - minimumReplica.y + 1
    let dz = maximumReplica.z - minimumReplica.z + 1
      
    return Int(dx * dy * dz)
  }
  
  public var minimumReplicaX: Int
  {
    get
    {
      return Int(minimumReplica.x)
    }
    set
    {
      minimumReplica.x = Int32(newValue)
      
      let dx = maximumReplica.x - minimumReplica.x + 1
      
      fullCell[0][0] = unitCell[0][0] * Double(dx)
      fullCell[0][1] = unitCell[0][1] * Double(dx)
      fullCell[0][2] = unitCell[0][2] * Double(dx)
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var minimumReplicaY: Int
  {
    get
    {
      return Int(minimumReplica.y)
    }
    set
    {
      minimumReplica.y = Int32(newValue)
      
      let dy = maximumReplica.y - minimumReplica.y + 1
      
      fullCell[1][0] = unitCell[1][0] * Double(dy)
      fullCell[1][1] = unitCell[1][1] * Double(dy)
      fullCell[1][2] = unitCell[1][2] * Double(dy)
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var minimumReplicaZ: Int
  {
    get
    {
      return Int(minimumReplica.z)
    }
    set
    {
      minimumReplica.z = Int32(newValue)
      
      let dz = maximumReplica.z - minimumReplica.z + 1
      
      fullCell[2][0] = unitCell[2][0] * Double(dz)
      fullCell[2][1] = unitCell[2][1] * Double(dz)
      fullCell[2][2] = unitCell[2][2] * Double(dz)
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var maximumReplicaX: Int
  {
    get
    {
      return Int(maximumReplica.x)
    }
    set(newValue)
    {
      maximumReplica.x = Int32(newValue)
      
      let dx = maximumReplica.x - minimumReplica.x + 1
      
      fullCell[0][0] = unitCell[0][0] * Double(dx)
      fullCell[0][1] = unitCell[0][1] * Double(dx)
      fullCell[0][2] = unitCell[0][2] * Double(dx)
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var maximumReplicaY: Int
  {
    get
    {
      return Int(maximumReplica.y)
    }
    set
    {
      maximumReplica[1] = Int32(newValue)
      
      let dy = maximumReplica.y - minimumReplica.y + 1
      
      fullCell[1][0] = unitCell[1][0] * Double(dy)
      fullCell[1][1] = unitCell[1][1] * Double(dy)
      fullCell[1][2] = unitCell[1][2] * Double(dy)
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  public var maximumReplicaZ: Int
  {
    get
    {
      return Int(maximumReplica.z)
    }
    set
    {
      maximumReplica.z = Int32(newValue)
      
      let dz = maximumReplica.z - minimumReplica.z + 1
      
      fullCell[2][0] = unitCell[2][0] * Double(dz);
      fullCell[2][1] = unitCell[2][1] * Double(dz);
      fullCell[2][2] = unitCell[2][2] * Double(dz);
      
      inverseFullCell = fullCell.inverse
      
      //boundingBox = RKBoundingBox(unitCell: unitCell, maximumReplicas: maximumReplica, minimumReplicas: minimumReplica)
    }
  }
  
  
  
  public var lengths: (a: Double, b: Double, c: Double)
  {
    let column1: SIMD3<Double> = unitCell[0]
    let column2: SIMD3<Double> = unitCell[1]
    let column3: SIMD3<Double> = unitCell[2]
    let length1: Double = length(column1)
    let length2: Double = length(column2)
    let length3: Double = length(column3)
    return (length1,length2, length3)
  }
  
  public var a: Double
  {
    get
    {
      return length(unitCell[0])
    }
    set(newValue)
    {
      let value: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
      self.latticeParameters = (newValue, value.b, value.c, value.alpha, value.beta, value.gamma)
    }
  }
  
  public var b: Double
  {
    get
    {
      return length(unitCell[1])
    }
    set(newValue)
    {
      let value: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
      self.latticeParameters = (value.a, newValue, value.c, value.alpha, value.beta, value.gamma)
    }
  }
  
  public var c: Double
  {
    get
    {
      return length(unitCell[2])
    }
    set(newValue)
    {
      let value: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
      self.latticeParameters = (value.a, value.b, newValue, value.alpha, value.beta, value.gamma)
    }
  }
  
  public var alpha: Double
  {
    get
    {
      let column2: SIMD3<Double> = unitCell[1]
      let column3: SIMD3<Double> = unitCell[2]
      let length2: Double = length(column2)
      let length3: Double = length(column3)
      
      return acos(dot(column2, column3) / (length2 * length3))
    }
    set(newValue)
    {
      let value: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
      self.latticeParameters = (value.a, value.b, value.c, newValue, value.beta, value.gamma)
    }
  }
  
  public var beta: Double
  {
    get
    {
      let column1: SIMD3<Double> = unitCell[0]
      let column3: SIMD3<Double> = unitCell[2]
      let length1: Double = length(column1)
      let length3: Double = length(column3)
      
      return acos(dot(column1, column3) / (length1 * length3))
    }
    set(newValue)
    {
      let value: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
      self.latticeParameters = (value.a, value.b, value.c, value.alpha, newValue, value.gamma)
    }
  }
  
  public var gamma: Double
  {
    get
    {
      let column1: SIMD3<Double> = unitCell[0]
      let column2: SIMD3<Double> = unitCell[1]
      let length1: Double = length(column1)
      let length2: Double = length(column2)
      
      return acos(dot(column1, column2) / (length1 * length2))
    }
    set(newValue)
    {
      let value: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
      self.latticeParameters = (value.a, value.b, value.c, value.alpha, value.beta, newValue)
    }
  }
  
  public var latticeParameters: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
  {
    get
    {
      let column1: SIMD3<Double> = unitCell[0]
      let column2: SIMD3<Double> = unitCell[1]
      let column3: SIMD3<Double> = unitCell[2]
      let length1: Double = length(column1)
      let length2: Double = length(column2)
      let length3: Double = length(column3)
    
      return (length1,length2,length3,
              acos(dot(column2, column3) / (length2 * length3)),
              acos(dot(column1, column3) / (length1 * length3)),
              acos(dot(column1, column2) / (length1 * length2)))
    }
    set(newValue)
    {
      let temp: Double = (cos(newValue.alpha) - cos(newValue.gamma) * cos(newValue.beta)) / sin(newValue.gamma)
      
      let v1: SIMD3<Double> = SIMD3<Double>(x: newValue.a, y: 0.0, z: 0.0)
      let v2: SIMD3<Double> = SIMD3<Double>(x: newValue.b * cos(newValue.gamma), y: newValue.b * sin(newValue.gamma), z: 0.0)
      let v3: SIMD3<Double> = SIMD3<Double>(x: newValue.c * cos(newValue.beta), y: newValue.c * temp, z: newValue.c * sqrt(1.0 - cos(newValue.beta)*cos(newValue.beta)-temp*temp))
      unitCell = double3x3([v1, v2, v3])
      inverseUnitCell = unitCell.inverse
      fullCell = unitCell
      
      let dx = maximumReplica.x - minimumReplica.x + 1
      let dy = maximumReplica.y - minimumReplica.y + 1
      let dz = maximumReplica.z - minimumReplica.z + 1
      
      fullCell[0][0] *= Double(dx);  fullCell[1][0] *= Double(dy);  fullCell[2][0] *= Double(dz);
      fullCell[0][1] *= Double(dx);  fullCell[1][1] *= Double(dy);  fullCell[2][1] *= Double(dz);
      fullCell[0][2] *= Double(dx);  fullCell[1][2] *= Double(dy);  fullCell[2][2] *= Double(dz);
      
      inverseFullCell = fullCell.inverse
      
      self.boundingBox = self.enclosingBoundingBox
    }
  }
  
  public var orthorhombic: Bool
  {
    let angles: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = self.latticeParameters
    
    return (fabs(angles.alpha - Double.pi / 2.0) < 0.001) && (fabs(angles.beta - Double.pi / 2.0) < 0.001) && (fabs(angles.gamma - Double.pi / 2.0) < 0.001)
  }
  
  public var volume: Double
  {
    let column1: SIMD3<Double> = unitCell[0]
    let column2: SIMD3<Double> = unitCell[1]
    let column3: SIMD3<Double> = unitCell[2]
    
    let v2: SIMD3<Double> = cross(column2, column3)
    
    return dot(column1,v2)
  }
  
  public var perpendicularWidths: SIMD3<Double>
  {
    let column1: SIMD3<Double> = unitCell[0]
    let column2: SIMD3<Double> = unitCell[1]
    let column3: SIMD3<Double> = unitCell[2]
    
    let v1: SIMD3<Double> = cross(column1, column2)
    let v2: SIMD3<Double> = cross(column2, column3)
    let v3: SIMD3<Double> = cross(column3, column1)
    
    let volume: Double = dot(column1,v2)
    
    return SIMD3<Double>(x: volume/length(v2), y: volume/length(v3), z: volume/length(v1))
  }
  
  public var properties: (volume: Double, perpendicularWidths: SIMD3<Double>, lengths: (a: Double, b: Double, c: Double), angles: (alpha: Double, beta: Double,gamma: Double))
  {
    let column1: SIMD3<Double> = unitCell[0]
    let column2: SIMD3<Double> = unitCell[1]
    let column3: SIMD3<Double> = unitCell[2]
    let a: Double = length(column1)
    let b: Double = length(column2)
    let c: Double = length(column3)
    let lengths: (Double, Double, Double) = (a,b,c)
    
    let v1: SIMD3<Double> = cross(column1, column2)
    let v2: SIMD3<Double> = cross(column2, column3)
    let v3: SIMD3<Double> = cross(column3, column1)
    
    
    let volume: Double = dot(column1,v2)
    
    let perpendicularWidths: SIMD3<Double> = SIMD3<Double>(x: volume/length(v2), y: volume/length(v3), z: volume/length(v1))
    
    let angles: (Double, Double, Double) = (acos(dot(column2, column3) / (b * c)),
                                            acos(dot(column1, column3) / (a * c)),
                                            acos(dot(column1, column2) / (a * b)))
    
    return (volume, perpendicularWidths, lengths, angles)
  }
  
  public func applyFullCellBoundaryCondition(_ dr: SIMD3<Double>) -> SIMD3<Double>
  {
    // convert from xyz to abc
    var s: SIMD3<Double> = inverseFullCell * dr
    
    // apply boundary condition
    s.x -= rint(s.x)
    s.y -= rint(s.y)
    s.z -= rint(s.z)
    
    // convert from abc to xyz and return value
    return fullCell * s
  }
  
  public func applyUnitCellBoundaryCondition(_ dr: SIMD3<Double>) -> SIMD3<Double>
  {
    // convert from xyz to abc
    var s: SIMD3<Double> = inverseUnitCell * dr
    
    // apply boundary condition
    s.x -= rint(s.x)
    s.y -= rint(s.y)
    s.z -= rint(s.z)
    
    // convert from abc to xyz and return value
    return unitCell * s
  }
  
  
  public func convertToCartesian(_ s: SIMD3<Double>) -> SIMD3<Double>
  {
    return unitCell * s
  }
  
  public func convertToFractional(_ s: SIMD3<Double>) -> SIMD3<Double>
  {
    return inverseUnitCell * s
  }
  
  public func convertToNormalizedFractional(_ r: SIMD3<Double>) -> SIMD3<Double>
  {
    var s: SIMD3<Double> = inverseUnitCell * r
    
    s.x -= rint(s.x)
    s.y -= rint(s.y)
    s.z -= rint(s.z)
    
    if(s.x<0.0)
    {
      s.x += 1.0
    }
    if(s.x>1.0)
    {
      s.x -= 1.0
    }
    
    if(s.y<0.0)
    {
      s.y += 1.0
    }
    if(s.y>1.0)
    {
      s.y -= 1.0
    }
    
    if(s.z<0.0)
    {
      s.z += 1.0
    }
    if(s.z>1.0)
    {
      s.z -= 1.0
    }
    return s
    
  }
  
  public func numberOfReplicas(forCutoff cutoff: Double) -> SIMD3<Int32>
  {
    let column1: SIMD3<Double> = unitCell[0]
    let column2: SIMD3<Double> = unitCell[1]
    let column3: SIMD3<Double> = unitCell[2]
    
    let v1: SIMD3<Double> = cross(column1, column2)
    let v2: SIMD3<Double> = cross(column2, column3)
    let v3: SIMD3<Double> = cross(column3, column1)
    
    let volume: Double = dot(column1,v2)
    
    let perpendicularWith: SIMD3<Double> = SIMD3<Double>(x: volume/length(v2), y: volume/length(v3), z: volume/length(v1))
    
    let replicas: SIMD3<Int32> = SIMD3<Int32>(Int32(ceil(2.0 * cutoff / (perpendicularWith.x + 0.000001))),
                              Int32(ceil(2.0 * cutoff / (perpendicularWith.y + 0.000001))),
                              Int32(ceil(2.0 * cutoff / (perpendicularWith.z + 0.000001))))
    
    
    return replicas
  }
  
  public static func average(_ cells: [SKCell]) -> SKCell
  {
    //let cell: RKCell = RKCell(a: 0.0, b: 0.0, c: 0.0, alpha: 0.0, beta: 0.0, gamma: 0.0)
    
    //return cells.reduce(cell, combine: +) / Double(cells.count)
    let cell: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    let avg: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = cells.reduce(cell){ $0 + $1.latticeParameters } / Double(cells.count)
    return SKCell(a: avg.a, b: avg.b, c: avg.c, alpha: avg.alpha, beta: avg.beta, gamma: avg.gamma)
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKCell.classVersionNumber)
    
    encoder.encode(unitCell)
    encoder.encode(minimumReplica)
    encoder.encode(maximumReplica)
    
    encoder.encode(unitCell)
    encoder.encode(inverseUnitCell)
    
    encoder.encode(fullCell)
    encoder.encode(inverseFullCell)
    
    encoder.encode(boundingBox)
    
    encoder.encode(contentShift)
    
    encoder.encode(precision)
    
    encoder.encode(contentFlip)
  }
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKCell.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    unitCell = try decoder.decode(double3x3.self)
    minimumReplica = try decoder.decode(SIMD3<Int32>.self)
    maximumReplica = try decoder.decode(SIMD3<Int32>.self)
    
    unitCell = try decoder.decode(double3x3.self)
    inverseUnitCell = try decoder.decode(double3x3.self)
    
    fullCell = try decoder.decode(double3x3.self)
    inverseFullCell = try decoder.decode(double3x3.self)
    
    boundingBox = try decoder.decode(SKBoundingBox.self)
    
    contentShift = try decoder.decode(SIMD3<Double>.self)
    
    precision = try decoder.decode(Double.self)
    
    if readVersionNumber >= 2 // introduced in version 2
    {
      contentFlip = try decoder.decode(Bool3.self)
    }
  }
  
}

public func +(left: SKCell, right: SKCell) -> SKCell
{
  let cell1: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = left.latticeParameters
  let cell2: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = right.latticeParameters
  
  return SKCell(a: cell1.a + cell2.a,
                b: cell1.b + cell2.b,
                c: cell1.c + cell2.c,
                alpha: cell1.alpha + cell2.alpha,
                beta: cell1.beta + cell2.beta,
                gamma: cell1.gamma + cell2.gamma)
}

public func /(left: SKCell, right: Double) -> SKCell
{
  let cell1: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) = left.latticeParameters
  return SKCell(a: cell1.a / right,
                b: cell1.b / right,
                c: cell1.c / right,
                alpha: cell1.alpha / right,
                beta: cell1.beta / right,
                gamma: cell1.gamma / right)
}

public func +(left: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double), right: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)) -> (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
{
  return (left.a + right.a, left.b + right.b, left.c + right.c, left.alpha + right.alpha, left.beta + right.beta, left.gamma + right.gamma)
}

public func /(left: (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double), right: Double) -> (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
{
  return (left.a / right, left.b / right, left.c / right, left.alpha / right, left.beta / right, left.gamma / right)
}

