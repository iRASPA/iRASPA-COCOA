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

public class SKBondSetController: NSObject, BinaryDecodable, BinaryEncodable
{
  var versionNumber: Int = 1
  private static var classVersionNumber: UInt32 = 1
  
  public var arrangedObjects: [ SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom> ] = []
  
  public var selectedObjects: IndexSet
  
  public override init()
  {
    arrangedObjects = []
    selectedObjects = []
  }
  
  public convenience init(arrangedObjects: [SKBondNode])
  {
    self.init()
    self.bonds = arrangedObjects
    self.selectedObjects = []
  }
   
  public var internalBonds: [SKBondNode]
  {
    let copies: [SKBondNode] = self.arrangedObjects.flatMap{$0.copies}
    return copies.filter{$0.boundaryType == .internal}
  }
  
  public var externalBonds: [SKBondNode]
  {
    let copies: [SKBondNode] = self.arrangedObjects.flatMap{$0.copies}
    return copies.filter{$0.boundaryType == .external}
  }
  
  public var bonds: [SKBondNode]
  {
    get
    {
      return self.arrangedObjects.flatMap{$0.copies}
    }
    set(newBonds)
    {
      let asymmetricBonds: Set<SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>> = Set(newBonds.map{SKAsymmetricBond($0.atom1.asymmetricParentAtom, $0.atom2.asymmetricParentAtom)})
      
      self.arrangedObjects = asymmetricBonds.sorted{
          if $0.atom1.elementIdentifier == $1.atom1.elementIdentifier 
          {
            if $0.atom2.elementIdentifier == $1.atom2.elementIdentifier
            {
              if $0.atom1.tag == $1.atom1.tag
              {
                return $0.atom2.tag < $1.atom2.tag
              }
              else
              {
                return $0.atom1.tag < $1.atom1.tag
              }
            }
            else
            {
              return $0.atom2.elementIdentifier > $1.atom2.elementIdentifier
            }
          }
          else
          {
            return $0.atom1.elementIdentifier > $1.atom1.elementIdentifier
          }
      }
      
      var indexInArrangedObjects: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>: Int] = [:]
      for (index, asymmetricBond) in self.arrangedObjects.enumerated()
      {
        indexInArrangedObjects[asymmetricBond] = index
      }
      
      // partition the bonds
      for bond in newBonds
      {
        let asymmetricBond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom> = SKAsymmetricBond.init(bond.atom1.asymmetricParentAtom, bond.atom2.asymmetricParentAtom)
        if let index: Int = indexInArrangedObjects[asymmetricBond]
        {
          self.arrangedObjects[index].copies.append(bond)
        }
      }
    }
  }
  
  public func data() -> Data
  {
    return NSArchiver.archivedData(withRootObject: arrangedObjects)
  }
  
  public var invertedSelection: IndexSet
  {
    return IndexSet(integersIn: 0..<self.arrangedObjects.count).subtracting(self.selectedObjects)
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
  
  var readVersionNumber: UInt32 = 0
  var readBonds: [SKBondNode] = []
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    readVersionNumber = try decoder.decode(UInt32.self)
    if readVersionNumber > SKBondSetController.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.selectedObjects = []
    
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
        guard let bondType = SKBondNode.BoundaryType(rawValue: boundaryType) else {throw BinaryCodableError.invalidArchiveData}
        let bond: SKBondNode = SKBondNode(atom1: SKBondNode.uninitializedAtom, atom2: SKBondNode.uninitializedAtom, boundaryType: bondType)
        bond.atom1Tag = atom1Tag
        bond.atom2Tag = atom2Tag
        readBonds.append(bond)
      }
    }
    else
    {
      self.arrangedObjects = try decoder.decode([ SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom> ].self)
    }
  }
  
  public func completationHandlerForLegacyBinaryDecoders(handler: ()->())
  {
    if readVersionNumber == 0
    {
      handler()
    }
  }
  
  public func restoreBonds(atomTreeController: SKAtomTreeController)
  {
    if readVersionNumber == 0
    {
      // fill in atoms from stored atom-tags
      let asymmetricAtoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      let atomList: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
      
      for bond in readBonds
      {
        let atom1 = atomList[min(bond.atom1Tag, bond.atom2Tag)]
        let atom2 = atomList[max(bond.atom1Tag, bond.atom2Tag)]
        bond.atom1 = atom1
        bond.atom2 = atom2
      }
      
      self.bonds = readBonds
    }
    else
    {
      // restore references to asymmetricAtoms in the assymetricBonds
      let asymmetricAtoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      for i in 0..<self.arrangedObjects.count
      {
        self.arrangedObjects[i].atom1 = asymmetricAtoms[min(self.arrangedObjects[i].tag1,self.arrangedObjects[i].tag2)]
        self.arrangedObjects[i].atom2 = asymmetricAtoms[max(self.arrangedObjects[i].tag1,self.arrangedObjects[i].tag2)]
      }
      
      // restore the references to atom-copies in bond-copies
      let atomList: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
      for bond in self.bonds
      {
        bond.atom1 = atomList[min(bond.atom1Tag, bond.atom2Tag)]
        bond.atom2 = atomList[max(bond.atom1Tag, bond.atom2Tag)]
      }
    }
  }
}

