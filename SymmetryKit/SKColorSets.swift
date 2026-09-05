/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
import BinaryCodable
import simd
import MathKit

public final class SKColorSets: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
 
  public let numberOfPredefinedSets: Int = 9
  private var colorSets: [SKColorSet] = []
  
  public enum ColorScheme: String, CaseIterable
  {
    case jmol = "Jmol"
    case rasmol_modern = "Rasmol modern"
    case rasmol = "Rasmol"
    case vesta = "Vesta"
    case crystalMaker = "CrystalMaker"
    case mercury = "Mercury"
    case pubChem = "PubChem"
    case pymol = "PyMOL"
    case vmdCpk = "VMD CPK"
  }
  
  public enum ColorOrder: Int
  {
    case elementOnly = 0
    case forceFieldFirst = 1
    case forceFieldOnly = 2
  }
  
  public init()
  {
    self.colorSets = ColorScheme.allCases.map { SKColorSet(colorScheme: $0) }
  }
  
  public subscript(index: Int) -> SKColorSet
  {
    get
    {
      ensurePredefinedSets()
      return self.colorSets[index % self.colorSets.count]
    }
    
    set(newValue)
    {
      ensurePredefinedSets()
      self.colorSets[index % self.colorSets.count] = newValue
    }
  }
  
  public subscript(displayName: String) -> SKColorSet?
  {
    get
    {
      ensurePredefinedSets()
      if let index: Int = self.colorSets.firstIndex(where: {$0.displayName == displayName})
      {
        return self.colorSets[index]
      }
      return nil
    }
    
    set(newValue)
    {
      ensurePredefinedSets()
      if let index: Int = self.colorSets.firstIndex(where: {$0.displayName == displayName}),
         let newValue = newValue
      {
        self.colorSets[index] = newValue
      }
    }
  }
  
  public func insert(key: String, element: Int)
  {
    ensurePredefinedSets()
    for i in 0..<colorSets.count
    {
      let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[element].chemicalSymbol.capitalizeFirst
      colorSets[i][key.capitalizeFirst] = colorSets[i][chemicalElement] ?? NSColor.black
    }
  }
  
  public func remove(key: String)
  {
    ensurePredefinedSets()
    for i in 0..<colorSets.count
    {
      self.colorSets[i][key.capitalizeFirst] = nil
    }
  }
  
  public func append(_ set: SKColorSet)
  {
    self.colorSets.append(set)
  }
  
  public var count: Int
  {
    ensurePredefinedSets()
    return self.colorSets.count
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    ensurePredefinedSets()
    encoder.encode(SKColorSets.classVersionNumber)
    encoder.encode(self.colorSets)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKColorSets.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.colorSets = try decoder.decode([SKColorSet].self)
    ensurePredefinedSets()
  }
  
  private func firstIndex(named name: String) -> Int?
  {
    return colorSets.firstIndex { $0.displayName.caseInsensitiveCompare(name) == .orderedSame }
  }
  
  /// Documents saved before CrystalMaker / Mercury / PubChem / PyMOL / VMD CPK
  /// only store the original four palettes. Insert any missing built-in after
  /// the preceding predefined set so existing files pick up the new schemes.
  private func ensurePredefinedSets()
  {
    for scheme in ColorScheme.allCases
    {
      guard firstIndex(named: scheme.rawValue) == nil else { continue }
      let afterPrevious: Int? = ColorScheme.allCases.prefix { $0 != scheme }
        .compactMap { firstIndex(named: $0.rawValue) }
        .map { $0 + 1 }
        .max()
      let insertIndex: Int = afterPrevious ?? colorSets.count
      colorSets.insert(SKColorSet(colorScheme: scheme), at: min(insertIndex, colorSets.count))
    }
  }
}

