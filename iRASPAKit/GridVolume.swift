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

import Cocoa
import RenderKit
import SymmetryKit
import BinaryCodable
import simd


public class GridVolume: Object, RKRenderDensityVolumeSource, RKRenderUnitCellSource
{  
  private static var classVersionNumber: Int = 1
  
  public override var materialType: Object.ObjectType
  {
    return .gridVolume
  }
  
  public var dimensions: SIMD3<Int32> = SIMD3<Int32>()
  public var spacing: SIMD3<Double> = SIMD3<Double>()
  var aspectRatio: SIMD3<Double> = SIMD3<Double>()
  var range: (Double, Double) = (0.0,0.0)
  public var data: Data = Data()
  
  public override init()
  {
    super.init()
  }
  
  public init(copy gridVolume: GridVolume)
  {
    super.init(copy: gridVolume)
  }
  
  public init(clone gridVolume: GridVolume)
  {
    super.init(clone: gridVolume)
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
  }
  
 
  
  public override var boundingBox: SKBoundingBox
  {
    let minimumReplica = cell.minimumReplica
    let maximumReplica = cell.maximumReplica
    
    let c0: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),  y: Double(minimumReplica.y),  z: Double(minimumReplica.z)))
    let c1: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(minimumReplica.z)))
    let c2: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(minimumReplica.z)))
    let c3: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(minimumReplica.z)))
    let c4: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1)))
    let c5: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1)))
    let c6: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1)))
    let c7: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1)))
    
    let minimum = SIMD3<Double>(x: min(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                                y: min(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                                z: min(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))

    let maximum = SIMD3<Double>(x: max(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                                y: max(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                                z: max(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  // MARK: protocol RKRenderUnitCellSource implementation
  // =====================================================================
  
  public override var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms]()
    
    let boundingBoxWidths: SIMD3<Double> = self.cell.boundingBox.widths
    
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
    {
      for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
      {
        for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
        {
          let cartesianPosition: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
          let spherePosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: 1.0)
          
          let ambient: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          let diffuse: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          let specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          
          data.append(RKInPerInstanceAttributesAtoms(position: spherePosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(scale), tag: UInt32(0)))
        }
      }
    }
    
    return data
  }

  public override var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    
    let color1: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let color2: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    let boundingBoxWidths: SIMD3<Double> = self.cell.boundingBox.widths
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
    {
      for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
      {
        for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
        {
          
          if(k1 <= self.cell.maximumReplica[0])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
            let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1+1), y: Double(k2), z: Double(k3)))
            cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
              position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
              color1: SIMD4<Float>(color: color1),
              color2: SIMD4<Float>(color: color2),
              scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
          }
          
          if(k2 <= self.cell.maximumReplica[1])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
            let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2+1), z: Double(k3)))
            cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
              position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
              color1: SIMD4<Float>(color: color1),
              color2: SIMD4<Float>(color: color2),
              scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
          }
          
          if(k3 <= self.cell.maximumReplica[2])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
            let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3+1)))
            cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
              position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
              color1: SIMD4<Float>(color: color1),
              color2: SIMD4<Float>(color: color2),
              scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
          }
        }
      }
    }
    
    return data
  }
   
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(GridVolume.classVersionNumber)
   
    encoder.encode(dimensions)
    encoder.encode(spacing)
    encoder.encode(range.0)
    encoder.encode(range.1)
    encoder.encode(data)
    
    encoder.encode(Int(0x6f6b6195))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > GridVolume.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    dimensions = try decoder.decode(SIMD3<Int32>.self)
    spacing = try decoder.decode(SIMD3<Double>.self)
    let range_low = try decoder.decode(Double.self)
    let range_high = try decoder.decode(Double.self)
    self.range = (range_low, range_high)
    data = try decoder.decode(Data.self)
    
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6195)
    {
      throw BinaryDecodableError.invalidMagicNumber
    }
    
    try super.init(fromBinary: decoder)
  }
}
