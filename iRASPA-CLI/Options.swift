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

// Boolean option (no arguments): the presence of the flag is true, otherwise false

public enum OptionType: Equatable   //: CustomStringConvertible
{
  case bool(value: Bool, shortOption: String?, longOption: String?, description: String)
  case int(value: Int, shortOption: String?, longOption: String?, description: String)
  case double(value: Double, shortOption: String?, longOption: String?, description: String)
  case string(value: String, shortOption: String?, longOption: String?, description: String)
  
  /*
  public var description: String
  {
    return ""
  }*/
  
  mutating func setValue(_ values: [String]) -> Bool
  {
    switch (self)
    {
    case .bool(let option):
      self = OptionType.bool(value: true, shortOption: option.shortOption, longOption: option.longOption, description: option.description)
      return true
    case .int(let option):
      if let value = values.first,
         let intValue = Int(value)
      {
        self = OptionType.int(value: intValue, shortOption: option.shortOption, longOption: option.longOption, description: option.description)
        return true
      }
      return false
    case .double(let option):
      if let value = values.first,
        let doubleValue = Double(value)
      {
        self = OptionType.double(value: doubleValue, shortOption: option.shortOption, longOption: option.longOption, description: option.description)
        return true
      }
      return false
    case .string(let option):
      if let stringValue = values.first
      {
        self = OptionType.string(value: stringValue, shortOption: option.shortOption, longOption: option.longOption, description: option.description)
        return true
      }
      return false
    }
  }
  
  public var claimedValues: Int
  {
    return 0
  }
  
  private func formatFlag(shortFlag: String?, longFlag: String?, shortOptionPrefix: String, longOptionPrefix: String) -> String
  {
    switch (shortFlag, longFlag)
    {
    case let (sf?, lf?):
      return "\(shortOptionPrefix)\(sf), \(longOptionPrefix)\(lf)"
    case (nil, let lf?):
      return "\(longOptionPrefix)\(lf)"
    case (let sf?, nil):
      return "\(shortOptionPrefix)\(sf)"
    default:
      return ""
    }
  }
  
  public func flags(shortOptionPrefix: String, longOptionPrefix: String) -> String
  {
    switch (self)
    {
    case .bool(let option):
      return formatFlag(shortFlag: option.shortOption, longFlag: option.longOption, shortOptionPrefix: shortOptionPrefix, longOptionPrefix: longOptionPrefix)
    case .int(let option):
      return formatFlag(shortFlag: option.shortOption, longFlag: option.longOption, shortOptionPrefix: shortOptionPrefix, longOptionPrefix: longOptionPrefix)
    case .double(let option):
      return formatFlag(shortFlag: option.shortOption, longFlag: option.longOption, shortOptionPrefix: shortOptionPrefix, longOptionPrefix: longOptionPrefix)
    case .string(let option):
      return formatFlag(shortFlag: option.shortOption, longFlag: option.longOption, shortOptionPrefix: shortOptionPrefix, longOptionPrefix: longOptionPrefix)
    }
  }
  
  public var description: String
  {
    switch (self)
    {
    case .bool(let option):
      return option.description
    case .int(let option):
      return option.description
    case .double(let option):
      return option.description
    case .string(let option):
      return option.description
    }
  }
  
  
  public static func ==(lhs: OptionType, rhs: OptionType) -> Bool
  {
      switch (lhs, rhs)
      {
      case (.bool(let lhsNum), .bool(let rhsNum)):
        return lhsNum.shortOption == rhsNum.shortOption || lhsNum.longOption == rhsNum.longOption
      default:
        return false
    }
  }
  
  public static func ==(lhs: OptionType, rhs: String) -> Bool
  {
    switch (lhs, rhs)
    {
    case (.bool(let lhsNum), rhs):
      return lhsNum.shortOption == rhs || lhsNum.longOption == rhs
    default:
      return false
    }
  }
  
  public static func ==(lhs: String, rhs: OptionType) -> Bool
  {
    switch (lhs, rhs)
    {
    case (lhs, .bool(let rhsNum)):
      return lhs == rhsNum.shortOption || lhs == rhsNum.longOption
    default:
      return false
    }
  }  
}



