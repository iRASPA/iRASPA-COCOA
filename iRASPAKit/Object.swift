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

public class Object: NSObject, RKRenderStructure, BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
 
  
  // MARK: protocol RKRenderStructure implementation
  // =====================================================================
  public var displayName: String = "uninitialized"
  public var isVisible: Bool = true
   
  public var origin: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
  public var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  
  public var periodic: Bool = true
  public var cell: SKCell = SKCell()
  
  public var scaling: SIMD3<Double> = SIMD3<Double>(x: 1.0, y: 1.0, z: 1.0)
  
  public var rotationDelta: Double = 5.0
  
  
  public func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>()
  }
  
  public func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>()
  }
  
  // MARK: protocol RKRenderUnitCellSource implementation
  // =====================================================================
  
  public var drawUnitCell: Bool = false
  public var unitCellScaleFactor: Double = 1.0
  public var unitCellDiffuseColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var unitCellDiffuseIntensity: Double = 1.0
  
  public var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    return []
  }

  public var renderUnitCellCylinders:[RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  
  // MARK: protocol RKRenderStructure implementation
  // =====================================================================
  
  public var renderLocalAxis: RKLocalAxes = RKLocalAxes()
  
  
  
  override init()
  {
    super.init()
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(Object.classVersionNumber)
    
    encoder.encode(self.displayName)
    encoder.encode(isVisible)
    
    encoder.encode(cell)
    encoder.encode(periodic)
    encoder.encode(origin)
    encoder.encode(scaling)
    encoder.encode(orientation)
    encoder.encode(rotationDelta)
    
    encoder.encode(self.drawUnitCell)
    encoder.encode(self.unitCellScaleFactor)
    encoder.encode(self.unitCellDiffuseColor)
    encoder.encode(self.unitCellDiffuseIntensity)
    
    encoder.encode(self.renderLocalAxis)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Object.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.isVisible = try decoder.decode(Bool.self)
    
    self.cell = try decoder.decode(SKCell.self)
    self.periodic = try decoder.decode(Bool.self)
    self.origin = try decoder.decode(SIMD3<Double>.self)
    self.scaling = try decoder.decode(SIMD3<Double>.self)
    self.orientation = try decoder.decode(simd_quatd.self)
    self.rotationDelta = try decoder.decode(Double.self)
    
    self.drawUnitCell = try decoder.decode(Bool.self)
    self.unitCellScaleFactor = try decoder.decode(Double.self)
    self.unitCellDiffuseColor = try decoder.decode(NSColor.self)
    self.unitCellDiffuseIntensity = try decoder.decode(Double.self)
  
    self.renderLocalAxis = try decoder.decode(RKLocalAxes.self)
  }
}
