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
import simd
import BinaryCodable

public final class SKBondNode: Hashable, Equatable, CustomStringConvertible, BinaryEncodable, BinaryDecodable
{
  public enum BoundaryType: Int
  {
    case `internal` = 0
    case external = 1
  }
  
  public var atom1Tag: Int = 0
  public var atom2Tag: Int = 0
  
  public unowned var atom1: SKAtomCopy
  public unowned var atom2: SKAtomCopy
  public var boundaryType: BoundaryType = BoundaryType.internal
  
  public var asymmetricIndex: Int = 0
  public var bondOrder: Int = 0
  
  /// NOTE: the bond-orde is defined that the tag of atom1 is lower than the tag of atom2
  public init(atom1: SKAtomCopy, atom2: SKAtomCopy, boundaryType type: BoundaryType)
  {
    if atom1.asymmetricParentAtom.elementIdentifier < atom2.asymmetricParentAtom.elementIdentifier
    {
      self.atom1 = atom1
      self.atom2 = atom2
    }
    else if atom1.asymmetricParentAtom.elementIdentifier > atom2.asymmetricParentAtom.elementIdentifier
    {
      self.atom1 = atom2
      self.atom2 = atom1
    }
    else
    {
      if atom1.tag < atom2.tag
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
    self.boundaryType = type
  }
  
  // MARK: -
  // MARK: Hashable protocol
  
  public func hash(into hasher: inout Hasher)
  {
    (ObjectIdentifier(atom1).hashValue^ObjectIdentifier(atom2).hashValue).hash(into: &hasher)
  }
  
  // MARK: -
  // MARK: CustomStringConvertible protocol
  
  public var description: String
  {
    return "atom 1 \(self.atom1)" + ", atom 2 \(self.atom2)"
  }
  
  
  public func isInternalBond() -> Bool
  {
    return self.boundaryType == BoundaryType.internal
  }
  
  public func isExternalBond() -> Bool
  {
    return self.boundaryType == BoundaryType.external
  }
  
  public var distanceVector: SIMD3<Double>
  {
    return atom2.position - atom1.position
  }
  
  public func displayName() -> String
  {
    return "bond"
  }
  
  public func otherAtom(_ atom: SKAtomCopy) -> SKAtomCopy
  {
    if atom1 === atom
    {
      return atom2
    }
    else if atom2 === atom
    {
      return atom1
    }
    fatalError()
  }
  
  // MARK: -
  // MARK: Equatable protocol
  
  public static func ==(lhs: SKBondNode, rhs: SKBondNode) -> Bool
  {
    return (lhs.atom1 === rhs.atom1 && lhs.atom2 === rhs.atom2) || (lhs.atom1 === rhs.atom2 && lhs.atom2 === rhs.atom1)
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.atom1.tag)
    encoder.encode(self.atom2.tag)
    encoder.encode(self.boundaryType.rawValue)
  }
   
 
  
  // MARK: -
  // MARK: Binary Decodable support
  
  internal static let uninitializedAsymmetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "uninitialized", elementId: 0, uniqueForceFieldName: "", position: SIMD3<Double>(0.0,0.0,0.0), charge: 0, color: NSColor.black, drawRadius: 0.0, bondDistanceCriteria: 0.0)
  internal static let uninitializedAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: uninitializedAsymmetricAtom, position: SIMD3<Double>(0.0,0.0,0.0))
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    // to be filled in later from the tag-information
    self.atom1 = SKBondNode.uninitializedAtom
    self.atom2 = SKBondNode.uninitializedAtom
    
    self.atom1Tag = try decoder.decode(Int.self)
    self.atom2Tag = try decoder.decode(Int.self)
    guard let boundaryType = BoundaryType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.boundaryType = boundaryType
  }
}

