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

struct AtomsChangeDataStructure
{
  var structure: Structure
  var atoms: [SKAtomTreeNode]
  var selectedBonds: [SKBondNode]
  var indexPaths: [IndexPath]
  
  func reversed() -> AtomsChangeDataStructure
  {
    return AtomsChangeDataStructure(structure: structure, atoms: atoms.reversed(), selectedBonds: selectedBonds, indexPaths: indexPaths.reversed())
  }
}
