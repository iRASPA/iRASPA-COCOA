//
//  Array.swift
//  MathKit
//
//  Created by David Dubbeldam on 31/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

// https://stackoverflow.com/questions/26173565/removeobjectsatindexes-for-swift-arrays
extension Array
{
  public mutating func remove(at indexes : IndexSet)
  {
    guard var i = indexes.first, i < count else { return }
    var j = index(after: i)
    var k = indexes.integerGreaterThan(i) ?? endIndex
    while j != endIndex
    {
      if k != j { swapAt(i, j); formIndex(after: &i) }
      else { k = indexes.integerGreaterThan(k) ?? endIndex }
      formIndex(after: &j)
    }
    removeSubrange(i...)
  }
}

public protocol Copying {
    init(original: Self)
}

public extension Copying {
    func copy() -> Self {
        return Self.init(original: self)
    }
}

public extension Array where Element: Copying
{
    func clone() -> Array {
        var copiedArray = Array<Element>()
        for element in self {
            copiedArray.append(element.copy())
        }
        return copiedArray
    }
}
