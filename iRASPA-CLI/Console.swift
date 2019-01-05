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


class Console
{
  var executableName: String
  var arguments: [String] = []
  var unparsedArguments: [String] = []
  
  var options: [OptionType] 
  
  private let shortOptionPrefix = "-"
  private let longOptionPrefix = "--"
  private let argumentStopper = "--"
  private let argumentAttacher: Character = "="
  
  
  /** A ParseError is thrown if the `parse()` method fails. */
  public enum ParseError: Error, CustomStringConvertible
  {
    /** Thrown if an unrecognized argument is passed to `parse()` in strict mode */
    case invalidArgument(String)
    
    /** Thrown if the value for an Option is invalid (e.g. a string is passed to an IntOption) */
    case invalidValueForOption(OptionType, [String])
    
    /** Thrown if an Option with required: true is missing */
    case missingRequiredOptions([OptionType])
    
    public var description: String
    {
      switch self {
      case let .invalidArgument(arg):
        return "Invalid argument: \(arg)"
      case let .invalidValueForOption(opt, vals):
        let vs = vals.joined(separator: ", ")
        return "Invalid value(s) for option \(opt.description): \(vs)"
      case let .missingRequiredOptions(opts):
        return "Missing required options: \(opts.map { return $0.description })"
      }
    }
  }
  
  
  init(arguments: [String], options: [OptionType])
  {
    let url: URL = URL(fileURLWithPath: arguments[0])
    self.executableName = url.lastPathComponent
    self.arguments = arguments.isEmpty ? [] : Array(arguments[1...])
    self.options = options
    setlocale(LC_ALL, "")
  }
  
  private struct StderrOutputStream: TextOutputStream
  {
    static let stream = StderrOutputStream()
    func write(_ s: String)
    {
      fputs(s, stderr)
    }
  }
  
  public func printUsage()
  {
    var out: StderrOutputStream = StderrOutputStream.stream
    print("Usage: \(executableName) [options] [file ...]", terminator: "\n", to: &out)
    
    for opt in options
    {
      print("  " + opt.flags(shortOptionPrefix: shortOptionPrefix, longOptionPrefix: longOptionPrefix), terminator: "\n", to: &out)
      print("      " + opt.description, terminator: "\n", to: &out)
    }
  }
  
  public func parse() throws
  {
    
    var strays: [String] = self.arguments
    
    for (index, argument) in strays.enumerated()
    {
      if argument == argumentStopper
      {
        break
      }
      
      if !argument.hasPrefix(shortOptionPrefix)
      {
        continue
      }
      
      let skipChars: Int = argument.hasPrefix(longOptionPrefix) ?
        longOptionPrefix.count : shortOptionPrefix.count
      let flagWithArg = argument[argument.index(argument.startIndex, offsetBy: skipChars)...]
      
      /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
      if flagWithArg.isEmpty
      {
        continue
      }
      
      // Remove attached argument from flag
      let splitFlag = flagWithArg.split(separator: argumentAttacher)
      let flag = String(splitFlag[0])
      let attachedArg: String? = splitFlag.count == 2 ? String(splitFlag[1]) : nil
      
      var flagMatched = false
      for k in 0..<options.count where options[k] == flag
      {
        let vals: [String] = self.getFlagValues(index, attachedArg)
        
        guard options[k].setValue(vals) else
        {
          throw ParseError.invalidValueForOption(options[k], vals)
        }
        
        
        var claimedIdx = index + options[k].claimedValues
        if attachedArg != nil
        {
          claimedIdx -= 1
        }
        for i in index...claimedIdx
        {
          strays[i] = ""
        }
        
        flagMatched = true
        break
      }
    
    
    // Flags that do not take any arguments can be concatenated
    let flagLength = flag.count
    if !flagMatched && !argument.hasPrefix(longOptionPrefix)
    {
      let flagCharactersEnumerator = flag.enumerated()
      for (i, c) in flagCharactersEnumerator
      {
        for k in 0..<options.count where options[k] == String(c)
        {
          /* Values are allowed at the end of the concatenated flags, e.g.
           * -xvf <file1> <file2>
           */
          let vals = (i == flagLength - 1) ? self.getFlagValues(index, attachedArg) : []
          
          guard options[k].setValue(vals) else
          {
            throw ParseError.invalidValueForOption(options[k], vals)
          }
          
          var claimedIdx = index + options[k].claimedValues
          if attachedArg != nil { claimedIdx -= 1 }
          for i in index...claimedIdx
          {
            strays[i] = ""
          }
          
          flagMatched = true
          break
        }
      }
    }
    
    }
    
    self.unparsedArguments = strays.filter { $0 != "" }
  }
  
  enum OutputType
  {
    case error
    case standard
  }
  
  
  func writeMessage(_ message: String, to: OutputType = .standard)
  {
    switch to {
    case .standard:
      // 1
      print("\u{001B}[;m\(message)")
    case .error:
      // 2
      fputs("\u{001B}[0;31m\(message)\n", stderr)
    }
  }
  
  
  // Returns all argument values from flagIndex to the next flag or the end of the argument array.
  private func getFlagValues(_ flagIndex: Int, _ attachedArg: String? = nil) -> [String]
  {
    var args: [String] = []
    var skipFlagChecks = false
    
    if let a = attachedArg
    {
      args.append(a)
    }
    
    for i in flagIndex + 1 ..< self.arguments.count
    {
      if !skipFlagChecks
      {
        if self.arguments[i] == argumentStopper
        {
          skipFlagChecks = true
          continue
        }
        
        if self.arguments[i].hasPrefix(shortOptionPrefix) && Int(self.arguments[i]) == nil &&
          Double(self.arguments[i]) == nil
        {
          break
        }
      }
      
      args.append(self.arguments[i])
    }
    
    return args
  }
}
