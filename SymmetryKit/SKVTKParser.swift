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
  var data: [Int16] = []
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  public init(displayName: String, string: String, windowController: NSWindowController?)
  {
    self.displayName = displayName
    self.windowController = windowController
    
    
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
    totalProgressCount = string.components(separatedBy: newLineChararterSet).count
    percentageFinishedStep = 10.0/Double(max(totalProgressCount - 1,1))
  }
  
  public override func startParsing() throws
  {
    var scannedLine: NSString?
    
    // skip "# vtk DataFile Version 1.0" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    
    // skip comment line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    
    // "ASCII" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if (scannedLine?.uppercased != "ASCII")
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no ASCII data")
      return
    }
    
    // "DATASET STRUCTURED_POINTS" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 2,
       words[0].uppercased() == "DATASET", words[1].uppercased() == "STRUCTURED_POINTS"
    {
      
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structued points")
      return
    }
    
    // "DIMENSIONS 150 150 150" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 4,
       (words[0].uppercased() == "DIMENSIONS"), let x: Int32 = Int32(words[1]), let y: Int32 = Int32(words[2]), let z: Int32 = Int32(words[3])
    {
      dimensions = SIMD3<Int32>(x, y, z)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
      return
    }
    
    // "ASPECT_RATIO 1.000000 0.577350 0.756091" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 4,
       (words[0].uppercased() == "ASPECT_RATIO"), let x: Double = Double(words[1]), let y: Double = Double(words[2]), let z: Double = Double(words[3])
    {
      aspectRatio = SIMD3<Double>(x, y, z)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
      return
    }
    
    // "ORIGIN 0.0 0.0 0.0" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 4,
       (words[0].uppercased() == "ORIGIN"), let x: Double = Double(words[1]), let y: Double = Double(words[2]), let z: Double = Double(words[3])
    {
      origin = SIMD3<Double>(x, y, z)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
      return
    }
    
    // skip empty line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    
    // "POINT_DATA 3375000" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 2,
       (words[0].uppercased() == "POINT_DATA"), let v: Int = Int(words[1])
    {
      numberOfValues = v
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": data must be structured points")
      return
    }
    
    // skip "SCALARS scalars unsigned_short" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    
    // skip "LOOKUP_TABLE default" line
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VTK file \"\(self.displayName)\": contains no data")
      return
    }
    
    data.reserveCapacity(numberOfValues)
    
    for index in 0..<numberOfValues
    {
      if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
          let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
          words.count >= 1, let value: Int16 = Int16(words[0])
      {
        data[index] = value
      }
    }
  }
}
