//
//  OrderedDictionary.swift
//  SwiftDataStructures
//
//  Created by Tim Ekl on 6/2/14.
//  Copyright (c) 2014 Tim Ekl. Available under MIT License. See LICENSE.md.
//

import Foundation

extension String
{
  public var capitalizeFirst:String
  {
    var result = self.lowercased()
    
    if self.isEmpty
    {
      return result
    }
    
    result.replaceSubrange(startIndex...startIndex, with: String(self[startIndex]).uppercased())
    return result
  }
}

public struct OrderedDictionary<Tk: Hashable, Tv>
{
  public var keys: Array<Tk> = []
  public var values: Dictionary<Tk,Tv> = [:]
  
  public var count: Int
  {
    assert(keys.count == values.count, "Keys and values array out of sync")
    return self.keys.count;
  }
  
  // Explicitly define an empty initializer to prevent the default memberwise initializer from being generated
  public init() {}
  
  public subscript(index: Int) -> Tv?
  {
    get
    {
      let key = self.keys[index]
      return self.values[key]
    }
    set(newValue)
    {
      let key = self.keys[index]
      if (newValue != nil)
      {
        self.values[key] = newValue
      }
      else
      {
        self.values.removeValue(forKey: key)
        self.keys.remove(at: index)
      }
    }
  }
  
  public subscript(key key: Tk) -> Tv?
  {
    get
    {
      return self.values[key]
    }
    set(newValue)
    {
      if newValue == nil
      {
        self.values.removeValue(forKey: key)
        self.keys = self.keys.filter {$0 != key}
      }
      else
      {
        let oldValue = self.values.updateValue(newValue!, forKey: key)
        if oldValue == nil
        {
          self.keys.append(key)
        }
      }
    }
  }
  
  @discardableResult public mutating func updateValue(_ value: Tv, forKey key: Tk) -> Tv?
  {
    if let oldValue: Tv = self[key: key]
    {
      self[key: key] = value
      return oldValue
    }
    self[key: key] = value
    return nil
  }
  
  public var description: String
  {
    var result = "{\n"
    for i in 0..<self.count
    {
      result += "[\(i)]: \(self.keys[i]) => \(String(describing: self[i]))\n"
    }
    result += "}"
    return result
  }
}
