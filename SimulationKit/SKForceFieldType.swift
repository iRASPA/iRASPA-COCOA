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
import MathKit
import simd

// Note that this is 'value'-type
public struct SKForceFieldType: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 2

  public var forceFieldStringIdentifier: String = ""
  public var editable: Bool = true
  public var atomicNumber: Int = 6
  public var sortIndex: Int
  public var potentialParameters: SIMD2<Double> = SIMD2<Double>(0.0,0.0)
  public var mass: Double = 0.0
  public var userDefinedRadius: Double = 0.0
  public var isVisible: Bool = true
  
  public init(forceFieldStringIdentifier: String, atomicNumber: Int, sortIndex: Int, potentialParameters: SIMD2<Double>, mass: Double, userDefinedRadius: Double)
  {
    self.forceFieldStringIdentifier = forceFieldStringIdentifier
    self.atomicNumber = atomicNumber
    self.sortIndex = sortIndex
    self.potentialParameters = potentialParameters
    self.mass = mass
    self.userDefinedRadius = userDefinedRadius
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKForceFieldType.classVersionNumber)
    
    encoder.encode(self.editable)
    encoder.encode(self.atomicNumber)
    encoder.encode(self.forceFieldStringIdentifier)
    encoder.encode(self.potentialParameters)
    encoder.encode(self.mass)
    encoder.encode(self.userDefinedRadius)
    encoder.encode(self.isVisible)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKForceFieldType.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.editable = try decoder.decode(Bool.self)
    let atomicNumber  = try decoder.decode(Int.self)
    self.atomicNumber = atomicNumber
    self.sortIndex = atomicNumber
    self.forceFieldStringIdentifier  = try decoder.decode(String.self)
    
    self.potentialParameters  = try decoder.decode(SIMD2<Double>.self)
    self.mass = try decoder.decode(Double.self)
    self.userDefinedRadius = try decoder.decode(Double.self)
    
    self.isVisible = true
    if readVersionNumber >= 2 // introduced in version 2
    {
      isVisible = try decoder.decode(Bool.self)
    }
  }
  
}


