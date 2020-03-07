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
import BinaryCodable

public final class SKForceFieldSets: BinaryDecodable, BinaryEncodable
{
  private var versionNumber: Int = 1
  private static var classVersionNumber: Int = 1
  private let numberOfPredefinedSets: Int = 1
  private var forceFieldSets: [SKForceFieldSet] = []
  
  public enum ForceFieldOrder: Int
  {
    case elementOnly = 0
    case forceFieldFirst = 1
    case forceFieldOnly = 2
  }
  
  public init()
  {
    forceFieldSets = [SKForceFieldSet()]
  }
  
  public subscript(index: Int) -> SKForceFieldSet
  {
    get
    {
      return self.forceFieldSets[index % self.forceFieldSets.count]
    }
    
    set(newValue)
    {
      self.forceFieldSets[index % self.forceFieldSets.count] = newValue
    }
  }
  
  
  public func contains(uniqueIdentifier: String) -> Bool
  {
    for i in 0..<forceFieldSets.count
    {
      if forceFieldSets[i].atomTypeList.contains(where: {$0.forceFieldStringIdentifier == uniqueIdentifier})
      {
        return true
      }
    }
    return false
  }
  
  public subscript(displayName: String) -> SKForceFieldSet?
  {
    get
    {
      let index: Int = self.forceFieldSets.firstIndex(where: {$0.displayName == displayName}) ?? 0
      return self.forceFieldSets[index]
    }
    
    set(newValue)
    {
      if let index: Int = self.forceFieldSets.firstIndex(where: {$0.displayName == displayName}),
         let newValue = newValue
      {
        self.forceFieldSets[index] = newValue
      }
    }
  }
  
  public func append(_ forceFieldSet: SKForceFieldSet)
  {
    self.forceFieldSets.append(forceFieldSet)
  }
  
  public var count: Int
  {
    return self.forceFieldSets.count
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKForceFieldSets.classVersionNumber)
    encoder.encode(forceFieldSets)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKForceFieldSets.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.forceFieldSets = try decoder.decode([SKForceFieldSet].self)
  }
}
