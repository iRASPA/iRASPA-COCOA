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
import BinaryCodable

public class ProjectNode: Decodable, CustomStringConvertible, BinaryDecodable, BinaryEncodable
{
  private var versionNumber: Int = 1
  private static var classVersionNumber: Int = 1
  public var displayName: String = "Default"
  
  // each project has its own undo-manager
  public lazy var undoManager: UndoManager = UndoManager()
  public var fileName: String = UUID().uuidString
  
  /// A Boolean value indicating whether the project has changes that have not been saved
  ///
  /// - returns: true if the project is edited, otherwise false
  public var isEdited: Bool = false
  
  public var description: String
  {
    return self.displayName
  }

  public init(name: String)
  {
    self.displayName = name
  }
  
  // MARK: -
  // MARK: Legacy Decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let versionNumber: Int = try container.decode(Int.self)
    if versionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    self.displayName  = try container.decode(String.self)
    self.fileName = try container.decode(String.self)
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(ProjectNode.classVersionNumber)
    encoder.encode(self.displayName)
    encoder.encode(self.isEdited)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  required public init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > ProjectNode.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    self.displayName  = try decoder.decode(String.self)
    self.isEdited  = try decoder.decode(Bool.self)
    self.fileName = ""
  }
}

