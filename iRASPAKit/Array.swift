/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
    if let index = self.index(of: object)
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
  

