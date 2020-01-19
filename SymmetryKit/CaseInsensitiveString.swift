/*******************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl   http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                          http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl                         http://homepage.tudelft.nl/v9k6y
 
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
 ******************************************************************************/

import Foundation

/// Wrapper by Werner Altewischer around String which uses case-insensitive implementations for Hashable
/// https://stackoverflow.com/questions/33182260/case-insensitive-dictionary-in-swift
public struct CaseInsensitiveString: Hashable, LosslessStringConvertible, ExpressibleByStringLiteral
{
  public typealias StringLiteralType = String
  
  private let value: String
  private let caseInsensitiveValue: String
  
  public init(stringLiteral: String)
  {
    self.value = stringLiteral
    self.caseInsensitiveValue = stringLiteral.lowercased()
  }
  
  public init?(_ description: String)
  {
    self.init(stringLiteral: description)
  }
  
  public func hash(into hasher: inout Hasher)
  {
    self.caseInsensitiveValue.hash(into: &hasher)
  }
  
  public func hasPrefix(_ prefix: String) -> Bool
  {
    return self.caseInsensitiveValue.hasPrefix(prefix.lowercased())
  }
  
  public static func == (lhs: CaseInsensitiveString, rhs: CaseInsensitiveString) -> Bool
  {
    return lhs.caseInsensitiveValue == rhs.caseInsensitiveValue
  }
  
  public var description: String
  {
    return value
  }
}
