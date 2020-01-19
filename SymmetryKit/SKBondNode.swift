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
import simd

public struct SKAsymmetricBond<A: SKAsymmetricAtom, B: SKAsymmetricAtom>: Hashable
{
  let atom1: SKAsymmetricAtom
  let atom2: SKAsymmetricAtom
  
  public func hash(into hasher: inout Hasher)
  {
    hasher.combine(atom1)
    hasher.combine(atom2)
  }
  
  public init(_ atom1: SKAsymmetricAtom, _ atom2: SKAsymmetricAtom)
  {
    self.atom1 = atom1
    self.atom2 = atom2
  }
  
  public static func ==<A, B> (lhs: SKAsymmetricBond<A, B>, rhs: SKAsymmetricBond<A, B>) -> Bool
  {
    return lhs.atom1 === rhs.atom1 && lhs.atom2 === rhs.atom2
  }
  
}

public final class SKBondNode: Hashable, Equatable, CustomStringConvertible
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
  
  public init(atom1: SKAtomCopy, atom2: SKAtomCopy)
  {
    if atom1.asymmetricParentAtom.elementIdentifier < atom2.asymmetricParentAtom.elementIdentifier
    {
      self.atom1 = atom1
      self.atom2 = atom2
    }
    else
    {
      self.atom1 = atom2
      self.atom2 = atom1
    }
    self.boundaryType = BoundaryType.internal
    
    self.atom1.bonds.insert(self)
    self.atom2.bonds.insert(self)
  }
  
  public init(atom1: SKAtomCopy, atom2: SKAtomCopy, boundaryType type: BoundaryType)
  {
    if atom1.asymmetricParentAtom.elementIdentifier > atom2.asymmetricParentAtom.elementIdentifier
    {
      self.atom1 = atom1
      self.atom2 = atom2
    }
    else
    {
      self.atom1 = atom2
      self.atom2 = atom1
    }
    self.boundaryType = type
    
    self.atom1.bonds.insert(self)
    self.atom2.bonds.insert(self)
  }
  
  private init(atom1t: SKAtomCopy, atom2t: SKAtomCopy, boundaryType type: BoundaryType)
  {
    if atom1t.asymmetricParentAtom.elementIdentifier > atom2t.asymmetricParentAtom.elementIdentifier
    {
      self.atom1 = atom1t
      self.atom2 = atom2t
    }
    else
    {
      self.atom1 = atom2t
      self.atom2 = atom1t
    }
    self.boundaryType = type
  }
  
  deinit
  {
  }
  
  
  // MARK: -
  // MARK: Hashable protocol
  
  public func hash(into hasher: inout Hasher)
  {
    ObjectIdentifier(self).hash(into: &hasher)
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
  
  // MARK: -
  // MARK: Equatable protocol
  
  public static func ==(lhs: SKBondNode, rhs: SKBondNode) -> Bool
  {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
}

