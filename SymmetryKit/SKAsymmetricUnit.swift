//
//  SKAsymmetricUnit.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 22/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation

public struct SKAsymmetricUnit
{
  let a: (Int, Int)
  let b: (Int, Int)
  let c: (Int, Int)
  
  public init(a: (Int, Int), b: (Int,Int), c: (Int, Int))
  {
    self.a = a
    self.b = b
    self.c = c
  }
}
