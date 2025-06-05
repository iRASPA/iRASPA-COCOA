/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

public class SKBondSetController: NSObject, BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 3
  
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
        let asymmetricBond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom> = SKAsymmetricBond(bond.atom1.asymmetricParentAtom, bond.atom2.asymmetricParentAtom)
        if let index: Int = indexInArrangedObjects[asymmetricBond]
        {
          self.arrangedObjects[index].copies.append(bond)
        }
      }
    }
  }
  
  public func data() -> Data
  {
    //return NSArchiver.archivedData(withRootObject: arrangedObjects)
    return try! NSKeyedArchiver.archivedData(withRootObject: arrangedObjects, requiringSecureCoding: false)
  }
  
  public var invertedSelection: IndexSet
  {
    return IndexSet(integersIn: 0..<self.arrangedObjects.count).subtracting(self.selectedObjects)
  }
  
  /// Computes the new selection for a change in bonds
  ///
  /// - parameter atoms: the asymmetric atoms that change.
  /// - parameter bonds: the new bonds for these asymmetric atoms.
  /// - returns: the selection for the new bonds
  public func selectedAsymmetricBonds(atoms: [SKAsymmetricAtom], bonds newbonds: [SKBondNode]) -> IndexSet
  {
    // all bonds that do not contain atoms
    let filteredBonds: Set<SKAsymmetricBond> = Set(self.arrangedObjects.filter{!(atoms.contains($0.atom1) || atoms.contains($0.atom2))})
    
    let newAsymmetricBonds: Set<SKAsymmetricBond> = Set(newbonds.map{SKAsymmetricBond($0.atom1.asymmetricParentAtom, $0.atom2.asymmetricParentAtom)})
    
    let totalBonds: Set<SKAsymmetricBond> = filteredBonds.union(newAsymmetricBonds)
    
    let asymmetricBonds: [SKAsymmetricBond] = totalBonds.sorted{
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
    for (index, asymmetricBond) in asymmetricBonds.enumerated()
    {
      indexInArrangedObjects[asymmetricBond] = index
    }
    
    let selectedObjects = self.arrangedObjects[self.selectedObjects]
    
    var indexSet: IndexSet = []
    for object in selectedObjects
    {
      if let index = indexInArrangedObjects[object]
      {
        indexSet.insert(index)
      }
    }
    
    
    for newAsymmetricBond in newAsymmetricBonds
    {
      // check that the bond is new
      if !self.arrangedObjects.contains(newAsymmetricBond)
      {
        if let index = indexInArrangedObjects[newAsymmetricBond]
        {
          indexSet.insert(index)
        }
      }
    }
    
    return indexSet
  }
  
  public func tag()
  {
    for (i, asymmetricBond) in arrangedObjects.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        bond.asymmetricIndex = i
      }
    }
  }
  
  public func replaceBonds(atoms: [SKAsymmetricAtom], bonds newbonds: [SKBondNode])
  {
    let filteredBonds: [SKBondNode] = self.arrangedObjects.filter{!(atoms.contains($0.atom1) || atoms.contains($0.atom2))}.flatMap{$0.copies}
    
    self.bonds = filteredBonds + newbonds
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKBondSetController.classVersionNumber)
    encoder.encode(self.arrangedObjects)
    encoder.encode(Array(self.selectedObjects))
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKBondSetController.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.selectedObjects = []
    self.arrangedObjects = try decoder.decode([SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>].self)
    if readVersionNumber >= 3 // introduced in version 3
    {
      let selection: [Int] = try decoder.decode([Int].self)
      self.selectedObjects = IndexSet(selection)
    }
  }
  
  public func restoreBonds(atomTreeController: SKAtomTreeController)
  {
    // restore references to asymmetricAtoms in the asymmetricBonds
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

