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

extension Array
{
  public var lastIndex: Element
    {
      return self[self.count - 1]
  }
  
  public var indexPathByRemovingLastIndex: Array<Element>
  {
    var temp: Array<Element> = self
    temp.removeLast()
    return temp
  }
  
}

extension Collection {
  /// Finds such index N that predicate is true for all elements up to
  /// but not including the index N, and is false for all elements
  /// starting with index N.
  /// Behavior is undefined if there is no such N.
  public func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
    var low = startIndex
    var high = endIndex
    while low != high {
      let mid = index(low, offsetBy: distance(from: low, to: high)/2)
      if predicate(self[mid]) {
        low = index(after: mid)
      } else {
        high = mid
      }
    }
    return low
  }
}

// Swift 2 Array Extension
// http://iphonedev.tv/blog/2015/9/22/how-to-remove-an-array-of-objects-from-a-swift-2-array-removeobjectsinarray
extension Array where Element: Equatable
{
  public mutating func removeObject(_ object: Element)
  {
    if let index = self.firstIndex(of: object)
    {
      self.remove(at: index)
    }
  }
  
  public mutating func removeObjectsInArray(_ array: [Element])
  {
    for object in array
    {
      self.removeObject(object)
    }
  }
  
  public mutating func insertItems(_ items: [Element], atIndexes indexes: IndexSet)
  {
    var currentIndex = indexes.first
    if items.count != indexes.count
    {
      fatalError("inconsistent number of items")
    }
    for item in items
    {
      insert(item, at: currentIndex!)
      currentIndex = indexes.integerGreaterThan(currentIndex!)
    }
  }
  
    
  public mutating func removeObjectsAtIndexes(_ indexes: IndexSet)
  {
    (indexes as NSIndexSet).enumerate(options: .reverse, using: { (index: Int, _) in
      self.remove(at: index)
      return

      })
  }
}

extension Array
{
  public subscript(index: IndexSet) -> Array
  {
    var newArray: Array<Element> = []
    for i in index
    {
      newArray.append(self[i])
    }
    return newArray
  }
}

 

extension Array
{
  public mutating func moveObjects(at indexes: IndexSet, to idx: Int)
  {
    var removedObjects = [Element]()
    for index in indexes.lazy.reversed()
    {
      let obj = self[index]
      removedObjects.append(obj)
      self.remove(at: index)
    }
    for removedObject in removedObjects
    {
      insert(removedObject, at: idx)
    }
  }
}
extension Array {
    mutating func move(from start: Index, to end: Index)
    {
      guard (0..<count) ~= start, (0...count) ~= end else { return }
      if start == end { return }
      let targetIndex = start < end ? end - 1 : end
      insert(remove(at: start), at: targetIndex)
    }
    
    mutating func move(with indexes: IndexSet, to toIndex: Index) {
      let movingData = indexes.map{ self[$0] }
      let targetIndex = toIndex - indexes.filter{ $0 < toIndex }.count
      for (i, e) in indexes.enumerated() {
        remove(at: e - i)
      }
      insert(contentsOf: movingData, at: targetIndex)
    }
}
  

