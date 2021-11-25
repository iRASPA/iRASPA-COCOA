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

public final class SKAtomCopy: BinaryDecodable, BinaryEncodable, Copying, Hashable
{
  private static var classVersionNumber: Int = 1
  
  public var position: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
  
  // list of bonds the atom is involved in
  //public var bonds: Set<SKBondNode> = []
  
  public var tag: Int = 0
  public var type: AtomCopyType = .copy
  
  public weak var asymmetricParentAtom: SKAsymmetricAtom!
  public var asymmetricIndex: Int = 0 // index for the renderer
  
  public var valence: Int = 0
  
  public func hash(into hasher: inout Hasher)
  {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  
  public enum AtomCopyType: Int
  {
    case copy = 2
    case duplicate = 3
  }
  
  public init(asymmetricParentAtom: SKAsymmetricAtom, position: SIMD3<Double>)
  {
    self.position = position
    self.asymmetricParentAtom = asymmetricParentAtom
  }
  
  required public init(copy: SKAtomCopy)
  {
    self.position = copy.position
    self.tag = copy.tag
    self.type = copy.type
    self.asymmetricIndex = copy.asymmetricIndex
  }
  
  public static func == (lhs: SKAtomCopy, rhs: SKAtomCopy) -> Bool
  {
    return fabs(lhs.position.x - rhs.position.x)<0.01 && fabs(lhs.position.y - rhs.position.y)<0.01 && fabs(lhs.position.z - rhs.position.z)<0.01
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKAtomCopy.classVersionNumber)
    encoder.encode(self.position)
    encoder.encode(self.type.rawValue)
    encoder.encode(self.tag)
    encoder.encode(self.asymmetricIndex)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKAtomCopy.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    self.position = try decoder.decode(SIMD3<Double>.self)
    guard let type = try AtomCopyType(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.type = type
    self.tag = try decoder.decode(Int.self)
    self.asymmetricIndex = try decoder.decode(Int.self)
  }
  
}
