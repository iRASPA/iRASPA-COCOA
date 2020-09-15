/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd
import BinaryCodable

public struct SKAsymmetricBond<A: SKAsymmetricAtom, B: SKAsymmetricAtom>: Hashable, BinaryDecodable, BinaryEncodable
{
  public var atom1: SKAsymmetricAtom
  public var atom2: SKAsymmetricAtom
  public var tag1: Int = 0
  public var tag2: Int = 0
  public var copies: [SKBondNode] = []
  public var isVisible: Bool = true
  public var bondType: SKBondType = SKBondType.single
  
  public enum SKBondType: Int
  {
    case single = 0
    case double = 1
    case partial_double = 2
    case triple = 3
  }
  
  public func hash(into hasher: inout Hasher)
  {
    (ObjectIdentifier(atom1).hashValue^ObjectIdentifier(atom2).hashValue).hash(into: &hasher)
  }
  
  public init(_ atom1: SKAsymmetricAtom, _ atom2: SKAsymmetricAtom)
  {
    if (atom1.elementIdentifier > atom2.elementIdentifier)
    {
      self.atom1 = atom1
      self.atom2 = atom2
    }
    else if (atom1.elementIdentifier < atom2.elementIdentifier)
    {
      self.atom1 = atom2
      self.atom2 = atom1
    }
    else
    {
      if (atom1.tag < atom2.tag)
      {
        self.atom1 = atom1
        self.atom2 = atom2
      }
      else
      {
        self.atom1 = atom2
        self.atom2 = atom1
      }
    }
  }
  
  public static func ==<A, B> (lhs: SKAsymmetricBond<A, B>, rhs: SKAsymmetricBond<A, B>) -> Bool
  {
    return (lhs.atom1 === rhs.atom1 && lhs.atom2 === rhs.atom2) || (lhs.atom1 === rhs.atom2 && lhs.atom2 === rhs.atom1)
  }
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    self.atom1 = SKBondNode.uninitializedAsymmetricAtom
    self.atom2 = SKBondNode.uninitializedAsymmetricAtom
    self.tag1 = try decoder.decode(Int.self)
    self.tag2 = try decoder.decode(Int.self)
    self.copies = try decoder.decode([SKBondNode].self)
    guard let bondType = SKBondType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.bondType = bondType
    self.isVisible = try decoder.decode(Bool.self)
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.atom1.tag)
    encoder.encode(self.atom2.tag)
    encoder.encode(self.copies)
    encoder.encode(self.bondType.rawValue)
    encoder.encode(self.isVisible)
  }
}
