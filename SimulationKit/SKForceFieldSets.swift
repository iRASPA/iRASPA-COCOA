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
import SymmetryKit

public final class SKForceFieldSets: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  
  private let numberOfPredefinedSets: Int = 2
  private var forceFieldSets: [SKForceFieldSet] = []
  
  public enum ForceFieldOrder: Int
  {
    case elementOnly = 0
    case forceFieldFirst = 1
    case forceFieldOnly = 2
  }
  
  public static let defaultDisplayName: String = SKForceFieldSet.defaultDisplayName
  public static let aluminosilicateDisplayName: String = SKForceFieldSet.aluminosilicateDisplayName
  
  public static func suggestedDisplayName(for materialType: SKStructure.MaterialType) -> String
  {
    return materialType.usesAluminosilicateForceField ? aluminosilicateDisplayName : defaultDisplayName
  }
  
  public static func suggestedDisplayName(forMaterialTypeName name: String) -> String
  {
    let materialType: SKStructure.MaterialType = SKStructure.MaterialType.fromDisplayName(name) ?? .unspecified
    return suggestedDisplayName(for: materialType)
  }
  
  public init()
  {
    forceFieldSets = [SKForceFieldSet(), SKForceFieldSet.aluminosilicate()]
  }
  
  /// The set that should be applied for `displayName`. Built-in non-editable tables
  /// (Aluminosilicate) always come from code so a document saved while Default still
  /// carried TraPPE-zeo Si/O cannot make the two sets identical.
  public func resolvedSet(named displayName: String) -> SKForceFieldSet
  {
    ensurePredefinedSets()
    if displayName == SKForceFieldSet.aluminosilicateDisplayName
    {
      return SKForceFieldSet.aluminosilicate()
    }
    if let set = forceFieldSets.first(where: {$0.displayName == displayName})
    {
      return set
    }
    return SKForceFieldSet.predefined(named: displayName)
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
      return self.forceFieldSets.first(where: {$0.displayName == displayName})
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
    ensurePredefinedSets()
  }
  
  private func ensurePredefinedSets()
  {
    if let index: Int = forceFieldSets.firstIndex(where: {$0.displayName == SKForceFieldSets.aluminosilicateDisplayName})
    {
      forceFieldSets[index] = SKForceFieldSet.aluminosilicate()
    }
    else
    {
      let insertIndex: Int = forceFieldSets.firstIndex(where: {$0.displayName == SKForceFieldSets.defaultDisplayName}).map {$0 + 1} ?? forceFieldSets.count
      forceFieldSets.insert(SKForceFieldSet.aluminosilicate(), at: min(insertIndex, forceFieldSets.count))
    }
    restoreDefaultFrameworkTypesIfTraPPE()
  }
  
  /// Default briefly used TraPPE-zeo Si/O while the Aluminosilicate set was added. Documents
  /// saved then have the same Lennard-Jones table in both sets, so switching force field does
  /// not change surface areas. Restore DREIDING O/Si/Al on Default when that fingerprint is present.
  private func restoreDefaultFrameworkTypesIfTraPPE()
  {
    guard let defaultSet: SKForceFieldSet = forceFieldSets.first(where: {$0.displayName == SKForceFieldSets.defaultDisplayName}),
          let oxygen: SKForceFieldType = defaultSet["O"] else { return }
    let looksLikeTraPPEOxygen: Bool = abs(oxygen.potentialParameters.x - 53.0) < 1.0e-6 && abs(oxygen.potentialParameters.y - 3.30) < 1.0e-6
    guard looksLikeTraPPEOxygen else { return }
    
    for symbol in ["O", "Si", "Al"]
    {
      guard let canonical: SKForceFieldType = SKForceFieldSet.defaultType(symbol: symbol),
            let index: Int = defaultSet.atomTypeList.firstIndex(where: {$0.forceFieldStringIdentifier == symbol}) else { continue }
      defaultSet.atomTypeList[index] = canonical
    }
  }
}
