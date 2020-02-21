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
  public let atom1: SKAsymmetricAtom
  public let atom2: SKAsymmetricAtom
  
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