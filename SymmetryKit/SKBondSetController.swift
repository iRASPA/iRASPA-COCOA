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
import BinaryCodable

public class SKBondSetController: NSObject, NSCoding, BinaryDecodable, BinaryEncodable
{
  var versionNumber: Int = 1
  private static var classVersionNumber: UInt32 = 1
  public var arrangedObjects: Set< SKBondNode > = Set()
  
  public var selectedObjects: Set< SKAsymmetricBond > = Set()
  
  public override init()
  {
    arrangedObjects = Set([])
  }
  
  public convenience init(arrangedObjects: Set<SKBondNode>)
  {
    self.init()
    self.arrangedObjects = arrangedObjects
  }
  
  deinit
  {
  }
  
  
  // MARK: -
  // MARK: NSCoding support
  
  
  public required init?(coder decoder: NSCoder)
  {
    self.versionNumber = (decoder.decodeObject() as? NSNumber)?.intValue ?? 0
    self.arrangedObjects = decoder.decodeObject() as? Set< SKBondNode> ?? []
  }
  
  public func encode(with coder: NSCoder)
  {
    coder.encode(NSNumber(integerLiteral: self.versionNumber))
    coder.encode(self.arrangedObjects)
  }
  
  public func data() -> Data
  {
    return NSArchiver.archivedData(withRootObject: arrangedObjects)
  }
  
  // using sets is relatively very fast
  public func removeArray(_ array: [SKBondNode])
  {
    let setvariable = Set(array)
    arrangedObjects.subtract(setvariable)
  }
  
  public func insertArray(_ array: [SKBondNode])
  {
    arrangedObjects.formUnion(Set(array))
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKBondSetController.classVersionNumber)
    encoder.encode(self.arrangedObjects)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: UInt32 = try decoder.decode(UInt32.self)
    if readVersionNumber > SKBondSetController.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    if readVersionNumber == 0
    {
      let _: UInt32 = try decoder.decode(UInt32.self)
      let length: Int = Int(try decoder.decode(Int.self))
      var atom1Tags: [Int] = []
      var atom2Tags: [Int] = []
      var bondBoundaryTypes: [Int] = []
      for _ in 0..<length
      {
        let a = try decoder.decode(Int.self)
        let b = try decoder.decode(Int.self)
        let c = try decoder.decode(Int.self)
        atom1Tags.append(a)
        atom2Tags.append(b)
        bondBoundaryTypes.append(c)
      }
      
      for ((atom1Tag, atom2Tag), boundaryType) in zip(zip(atom1Tags, atom2Tags), bondBoundaryTypes)
      {
        let bond: SKBondNode = SKBondNode(atom1: SKBondNode.uninitializedAtom, atom2: SKBondNode.uninitializedAtom, boundaryType: SKBondNode.BoundaryType(rawValue: boundaryType)!)
        bond.atom1Tag = atom1Tag
        bond.atom2Tag = atom2Tag
        self.arrangedObjects.insert(bond)
      }
    }
    else
    {
      self.arrangedObjects = try decoder.decode(Set< SKBondNode >.self)
    }
  }
}

