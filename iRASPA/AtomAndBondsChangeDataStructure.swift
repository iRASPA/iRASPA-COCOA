//
//  AtomsChangeDataStructure.swift
//  iRASPA
//
//  Created by David Dubbeldam on 13/01/2020.
//  Copyright © 2020 David Dubbeldam. All rights reserved.
//

import Foundation
import SymmetryKit
import iRASPAKit

struct AtomAndBondsChangeDataStructure
{
  var structure: Structure
  var atoms: [SKAtomTreeNode]
  var indexPaths: [IndexPath]
  var selectedBonds: [SKAsymmetricBond<SKAsymmetricAtom,SKAsymmetricAtom>]
  var indexSet: IndexSet
  
  func reversed() -> AtomAndBondsChangeDataStructure
  {
    return AtomAndBondsChangeDataStructure(structure: structure, atoms: atoms.reversed(), indexPaths: indexPaths.reversed(), selectedBonds: selectedBonds, indexSet: indexSet)
  }
}
