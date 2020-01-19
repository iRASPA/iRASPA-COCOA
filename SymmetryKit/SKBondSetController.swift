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

public class SKBondSetController: NSObject, NSCoding, BinaryDecodable
{
  var versionNumber: Int = 1
  private static var classVersionNumber: Int32 = 1
  public var arrangedObjects: Set< SKBondNode > = Set()
  
  public override init()
  {
    arrangedObjects = Set([])
  }
  
  public convenience init(arrangedObjects: Set<SKBondNode>)
  {
    self.init()
    self.arrangedObjects = arrangedObjects
  }
  
  deinit
  {
  }
  
  
  // MARK: -
  // MARK: NSCoding support
  
  
  public required init?(coder decoder: NSCoder)
  {
    self.versionNumber = (decoder.decodeObject() as? NSNumber)?.intValue ?? 0
    self.arrangedObjects = decoder.decodeObject() as? Set< SKBondNode> ?? []
  }
  
  public func encode(with coder: NSCoder)
  {
    coder.encode(NSNumber(integerLiteral: self.versionNumber))
    coder.encode(self.arrangedObjects)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: UInt32 = try decoder.decode(UInt32.self)
    if readVersionNumber > SKBondSetController.classVersionNumber
    {
      //throw BinaryDecodableError.invalidArchiveVersion
    }
    
    let size: Int = try Int(decoder.decode(UInt32.self))
    for _ in 0..<size
    {
      let _: UInt32 = try decoder.decode(UInt32.self)
      let _: UInt32 = try decoder.decode(UInt32.self)
      let _: UInt32 = try decoder.decode(UInt32.self)
    }
  }
  
  /*
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
  }*/
  
  public func data() -> Data
  {
    return NSArchiver.archivedData(withRootObject: arrangedObjects)
  }
  
  // using sets is relatively very fast
  public func removeArray(_ array: [SKBondNode])
  {
    let setvariable = Set(array)
    arrangedObjects.subtract(setvariable)
  }
  
  public func insertArray(_ array: [SKBondNode])
  {
    arrangedObjects.formUnion(Set(array))
  }
}

