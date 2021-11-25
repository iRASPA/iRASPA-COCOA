//
//  CopyingProtocol.swift
//  MathKit
//
//  Created by David Dubbeldam on 14/01/2020.
//  Copyright © 2020 David Dubbeldam. All rights reserved.
//

import Foundation

public protocol Copying
{
  init(copy: Self)
}

public extension Copying
{
  func copy() -> Self
  {
    return Self.init(copy: self)
  }
}

public extension Array where Element: Copying
{
  func copy() -> Array
  {
    return self.map{$0.copy()}
  }
}

public protocol Cloning: Copying
{
  init(clone: Self)
}

public extension Cloning
{
  func clone() -> Self
  {
    return Self.init(clone: self)
  }
}

public extension Array where Element: Cloning
{
  func clone() -> Array
  {
    return self.map{$0.clone()}
  }
}

