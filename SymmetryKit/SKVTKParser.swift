/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
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
import simd
import MathKit
import LogViewKit

public final class SKVTKParser: SKParser, ProgressReporting
{
  weak var windowController: NSWindowController? = nil
  var cellFormulaUnitsZ: Int = 0
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var displayName: String = ""
  var dimensions: SIMD3<Int32> = SIMD3<Int32>(0,0,0)
  var aspectRatio: SIMD3<Double> = SIMD3<Double>(1.0,1.0,1.0)
  var origin: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
  var numberOfValues: Int = 0
  
  var isBinaryData: Bool = false
  var data: Data
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  public init(displayName: String, data: Data, windowController: NSWindowController?) throws
  {
    self.displayName = displayName
    self.windowController = windowController
    
    self.data = data
    
    guard let string: String = String(data: data, encoding: .macOSRoman) else
    {
      throw SKParserError.failedDecoding
    }
    
    self.scanner = Scanner(string: string)
  
    self.scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
    
    let mutableletterSet: CharacterSet = CharacterSet(charactersIn: "\"#$\'_;[]")
    letterSet = mutableletterSet as CharacterSet
    nonLetterSet = letterSet.inverted
    
    whiteSpacesAndNewlines = CharacterSet.whitespacesAndNewlines
    keywordSet = CharacterSet.whitespacesAndNewlines.inverted
    
    newLineChararterSet = CharacterSet.newlines
    
    // report progress in steps of 10% (updating faster makes Progress/updating slow)
    progress = Progress()
    progress.totalUnitCount = 10
    
    // work is defined in terms of the number of lines to parse
    totalProgressCount = scanner.string.components(separatedBy: newLineChararterSet).count
    percentageFinishedStep = 10.0/Double(max(totalProgressCount - 1,1))
    
  }
  
  public override func startParsing() throws
  {
    var scannedLine: NSString? = ""
    
    let structure: SKStructure = SKStructure()
    structure.kind = .VTKDensityVolume
    
    // skip "# vtk DataFile Version 1.0" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if(scannedLine?.lowercased != "# vtk DataFile Version 1.0".lowercased())
    {
      LogQueue.shared.error(destination: self.windowController, message: "File not a VTK file \"\(self.displayName)\"")
      return
    }
   
    
    // skip comment line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    // PARSE CELL_PARAMETERS COMMAND if possible: CELL_PARAMETERS 13.270000 13.270000 15.050000 90.000000 90.000000 120.000000
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 4, words[0].uppercased() == "CELL_PARAMETERS"
    {
      structure.kind = .RASPADensityVolume
      guard let a: Double = Double(words[1]), let b: Double = Double(words[2]), let c: Double = Double(words[3]) else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structued points")
        return
      }
      
      structure.cell = SKCell(a: a, b: b, c: c, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
      
      if words.count >= 7,
         let alpha: Double = Double(words[4]), let beta: Double = Double(words[5]), let gamma: Double = Double(words[6])
      {
        structure.cell = SKCell(a: a, b: b, c: c, alpha: alpha*Double.pi/180.0, beta: beta*Double.pi/180.0, gamma: gamma*Double.pi/180.0)
      }
      else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structued points")
        return
      }
    }
    
    // "ASCII" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 1
    {
      if words[0].uppercased() == "ASCII"
      {
        isBinaryData = false
      }
      else if words[0].uppercased() == "BINARY"
      {
        isBinaryData = true
      }
      else
      {
        LogQueue.shared.warning(destination: self.windowController, message: "Unclear whether ASCI or BINARY data")
      }
    }
    
    
    // "DATASET STRUCTURED_POINTS" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 2, words[0].uppercased() == "DATASET"
    {
      if words[1].uppercased() == "STRUCTURED_POINTS"
      {
      
      }
      else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structued points")
        return
      }
    }
    
    // Read all header data upto "POINT_DATA"
    var headerData: [String] = []
    repeat
    {
      if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
      {
        LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no header data")
        return
      }
      headerData.append(String(scannedLine ?? ""))
    }
    while (scannedLine != nil && !scannedLine!.uppercased.starts(with: "POINT_DATA"))
            
                
    //parse header
    for header in headerData
    {
      let words: [String] = header.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty})
      
      if words.count >= 4, (words[0].uppercased() == "DIMENSIONS")
      {
        if let x: Int32 = Int32(words[1]), let y: Int32 = Int32(words[2]), let z: Int32 = Int32(words[3])
        {
          structure.dimensions = SIMD3<Int32>(x, y, z)
        }
        else
        {
          LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
          return
        }
      }
      
      // "ORIGIN 0.0 0.0 0.0" line
      if words.count >= 4, (words[0].uppercased() == "ORIGIN")
      {
        if let x: Double = Double(words[1]), let y: Double = Double(words[2]), let z: Double = Double(words[3])
        {
        origin = SIMD3<Double>(x, y, z)
        }
        else
        {
          LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
          return
        }
      }
      
      // "SPACING 0.088467 0.088467 0.100333" line
      if words.count >= 4, (words[0].uppercased() == "SPACING")
      {
        if let x: Double = Double(words[1]), let y: Double = Double(words[2]), let z: Double = Double(words[3])
        {
          structure.spacing = SIMD3<Double>(x, y, z)
        }
        else
        {
          LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
          return
        }
      }
      
      // "POINT_DATA 3375000" line
      if words.count >= 2, (words[0].uppercased() == "POINT_DATA")
      {
        if let v: Int = Int(words[1])
        {
          numberOfValues = v
        }
        else
        {
          LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
          return
        }
      }
    }
    
    // "SCALARS scalars unsigned_short" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    // "POINT_DATA 3375000" line
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 2, words[0].uppercased() == "SCALARS"
    {
      if words[2].lowercased() == "unsigned_char"
      {
        structure.dataType = SKStructure.DataType.Uint8
      }
      else if words[2].lowercased() == "char"
      {
        structure.dataType = SKStructure.DataType.Int8
      }
      else if words[2].lowercased() == "unsigned_short"
      {
        structure.dataType = SKStructure.DataType.Uint16
      }
      else if words[2].lowercased() == "short"
      {
        structure.dataType = SKStructure.DataType.Int16
      }
      else if words[2].lowercased() == "unsigned_int"
      {
        structure.dataType = SKStructure.DataType.Uint32
      }
      else if words[2].lowercased() == "int"
      {
        structure.dataType = SKStructure.DataType.Int32
      }
      else if words[2].lowercased() == "unsigned_long"
      {
        structure.dataType = SKStructure.DataType.Uint32
      }
      else if words[2].lowercased() == "long"
      {
        structure.dataType = SKStructure.DataType.Int32
      }
      else if words[2].lowercased() == "float"
      {
        structure.dataType = SKStructure.DataType.Float
      }
      else if words[2].lowercased() == "double"
      {
        structure.dataType = SKStructure.DataType.Double
      }
      else
      {
        LogQueue.shared.warning(destination: self.windowController, message: "Unknown datatype")
      }
    }
    
    // skip "LOOKUP_TABLE default" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    
    if(isBinaryData)
    {
      let startIndex = self.data.index(self.data.startIndex, offsetBy: self.scanner.scanLocation)
      structure.gridData = data[startIndex..<self.data.endIndex]
    }
    else
    {
      switch(structure.dataType)
      {
      case .Uint8:
        var data = Array<UInt8>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: UInt8 = UInt8(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Int8:
        var data = Array<Int8>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: Int8 = Int8(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Uint16:
        var data = Array<UInt16>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: UInt16 = UInt16(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Int16:
        var data = Array<Int16>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: Int16 = Int16(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Uint32:
        var data = Array<UInt32>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: UInt32 = UInt32(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Int32:
        var data = Array<Int32>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: Int32 = Int32(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Uint64:
        var data = Array<UInt64>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: UInt64 = UInt64(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Int64:
        var data = Array<Int64>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: Int64 = Int64(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Float:
        var data = Array<Float>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: Float = Float(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      case .Double:
        var data = Array<Double>(repeating: 0, count: numberOfValues)
        for index in 0..<numberOfValues
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let value: Double = Double(words[0])
            {
              data[index] = value
            }
          }
        }
        structure.gridData = data.withUnsafeBufferPointer({Data(buffer: $0)})
      }
    }
    
    self.scene = [[structure]]
  }
  
}
