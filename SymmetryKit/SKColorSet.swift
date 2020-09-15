/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import BinaryCodable
import simd

public struct SKColorSet: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  public var displayName: String
  public var editable: Bool = false
  var colors: [String: NSColor] = [:]
  
  public init(name: String, from: SKColorSet, editable: Bool)
  {
    self.displayName = name
    self.editable = editable
    self.colors = from.colors
  }
  
  public init(colorScheme: SKColorSets.ColorScheme)
  {
    switch(colorScheme)
    {
    case .jmol:
      self.displayName = SKColorSets.ColorScheme.jmol.rawValue.capitalizeFirst
      self.editable = false
      self.colors = SKColorSet.jMol.mapValues{NSColor(colorCode: $0)}
    case .rasmol_modern:
      self.displayName = SKColorSets.ColorScheme.rasmol_modern.rawValue.capitalizeFirst
      self.editable = false
      self.colors = SKColorSet.rasmolModern.mapValues{NSColor(colorCode: $0)}
    case .rasmol:
      self.displayName = SKColorSets.ColorScheme.rasmol.rawValue.capitalizeFirst
      self.editable = false
      self.colors = SKColorSet.rasmol.mapValues{NSColor(colorCode: $0)}
    case .vesta:
      self.displayName = SKColorSets.ColorScheme.vesta.rawValue.capitalizeFirst
      self.editable = false
      self.colors = SKColorSet.vesta.mapValues{NSColor(colorCode: $0)}
    }
  }
  
  
  public subscript(index: String) -> NSColor?
  {
    get
    {
      return self.colors[index.capitalizeFirst]
    }
    
    set(newValue)
    {
      if let newValue = newValue
      {
        self.colors.updateValue(newValue, forKey: index.capitalizeFirst)
      }
      else
      {
        self.colors[index.capitalizeFirst] = newValue
      }
    }
    
  }
  
  public var count: Int
  {
    return self.colors.count
  }
  
  public func print()
  {
    debugPrint("standard colors:")
    for (key,value) in colors.enumerated()
    {
      debugPrint("key: \(key) value: \(value)")
    }
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKColorSet.classVersionNumber)
    encoder.encode(self.displayName)
    encoder.encode(self.editable)
    encoder.encode(self.colors)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKColorSet.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.editable = try decoder.decode(Bool.self)
    self.colors = try decoder.decode(Dictionary<String, NSColor>.self)
  }
  
  // order is: jmol, rasmol, rasmol-modern
  public static let jMol: [String : UInt32] =
    [
      "H"   : 0xFFFFFF, "He"  : 0xD9FFFF, "Li"  : 0xCC80FF, "Be"  : 0xC2FF00, "B"   : 0xFFB5B5, "C"   : 0x909090, "N"   : 0x3050F8, "O"   : 0xFF0D0D, "F"   : 0x90E050,
      "Ne"  : 0xB3E3F5, "Na"  : 0xAB5CF2, "Mg"  : 0x8AFF00, "Al"  : 0xBFA6A6, "Si"  : 0xF0C8A0, "P"   : 0xFF8000, "S"   : 0xFFFF30, "Cl"  : 0x1FF01F, "Ar"  : 0x80D1E3,
      "K"   : 0x8F40D4, "Ca"  : 0x3DFF00, "Sc"  : 0xE6E6E6, "Ti"  : 0xBFC2C7, "V"   : 0xA6A6AB, "Cr"  : 0x8A99C7, "Mn"  : 0x9C7AC7, "Fe"  : 0xE06633, "Co"  : 0xF090A0,
      "Ni"  : 0x50D050, "Cu"  : 0xC88033, "Zn"  : 0x7D80B0, "Ga"  : 0xC28F8F, "Ge"  : 0x668F8F, "As"  : 0xBD80E3, "Se"  : 0xFFA100, "Br"  : 0xA62929, "Kr"  : 0x5CB8D1,
      "Rb"  : 0x702EB0, "Sr"  : 0x00FF00, "Y"   : 0x94FFFF, "Zr"  : 0x94E0E0, "Nb"  : 0x73C2C9, "Mo"  : 0x54B5B5, "Tc"  : 0x3B9E9E, "Ru"  : 0x248F8F, "Rh"  : 0x0A7D8C,
      "Pd"  : 0x006985, "Ag"  : 0xC0C0C0, "Cd"  : 0xFFD98F, "In"  : 0xA67573, "Sn"  : 0x668080, "Sb"  : 0x9E63B5, "Te"  : 0xD47A00, "I"   : 0x940094, "Xe"  : 0x429EB0,
      "Cs"  : 0x57178F, "Ba"  : 0x00C900, "La"  : 0x70D4FF, "Ce"  : 0xFFFFC7, "Pr"  : 0xD9FFC7, "Nd"  : 0xC7FFC7, "Pm"  : 0xA3FFC7, "Sm"  : 0x8FFFC7, "Eu"  : 0x61FFC7,
      "Gd"  : 0x45FFC7, "Tb"  : 0x30FFC7, "Dy"  : 0x1FFFC7, "Ho"  : 0x00FF9C, "Er"  : 0x00E675, "Tm"  : 0x00D452, "Yb"  : 0x00BF38, "Lu"  : 0x00AB24, "Hf"  : 0x4DC2FF,
      "Ta"  : 0x4DA6FF, "W"   : 0x2194D6, "Re"  : 0x267DAB, "Os"  : 0x266696, "Ir"  : 0x175487, "Pt"  : 0xD0D0E0, "Au"  : 0xFFD123, "Hg"  : 0xB8B8D0, "Tl"  : 0xA6544D,
      "Pb"  : 0x575961, "Bi"  : 0x9E4FB5, "Po"  : 0xAB5C00, "At"  : 0x754F45, "Rn"  : 0x428296, "Fr"  : 0x420066, "Ra"  : 0x007D00, "Ac"  : 0x70ABFA, "Th"  : 0x00BAFF,
      "Pa"  : 0x00A1FF, "U"   : 0x008FFF, "Np"  : 0x0080FF, "Pu"  : 0x006BFF, "Am"  : 0x545CF2, "Cm"  : 0x785CE3, "Bk"  : 0x8A4FE3, "Cf"  : 0xA136D4, "Es"  : 0xB31FD4,
      "Fm"  : 0xB31FBA, "Md"  : 0xB30DA6, "No"  : 0xBD0D87, "Lr"  : 0xC70066, "Rf"  : 0xCC0059, "Db"  : 0xD1004F, "Sg"  : 0xD90045, "Bh"  : 0xE00038, "Hs"  : 0xE6002E,
      "Mt"  : 0xEB0026, "Ds"  : 0xEB0026, "Rg"  : 0xEB0026, "Cn"  : 0xEB0026, "Uut" : 0xEB0026, "Uuq" : 0xEB0026, "Uup" : 0xEB0026, "Uuh" : 0xEB0026, "Uus" : 0xEB0026,
      "Uuo" : 0xEB0026
  ]
  
  public static let rasmol: [String : UInt32] =
    [
      "H"   : 0xFFFFFF, "He"  : 0xFFC0CB, "Li"  : 0xB22222, "Be"  : 0xFF1493, "B"   : 0x00FF00, "C"   : 0xC8C8C8, "N"   : 0x8F8FFF, "O"   : 0xF00000, "F"   : 0xDAA520,
      "Ne"  : 0xFF1493, "Na"  : 0x0000FF, "Mg"  : 0x228B22, "Al"  : 0x808090, "Si"  : 0xDAA520, "P"   : 0xFFA500, "S"   : 0xFFC832, "Cl"  : 0x00FF00, "Ar"  : 0xFF1493,
      "K"   : 0xFF1493, "Ca"  : 0x808090, "Sc"  : 0xFF1493, "Ti"  : 0x808090, "V"   : 0xFF1493, "Cr"  : 0x808090, "Mn"  : 0x808090, "Fe"  : 0xFFA500, "Co"  : 0xFF1493,
      "Ni"  : 0xA52A2A, "Cu"  : 0xA52A2A, "Zn"  : 0xA52A2A, "Ga"  : 0xFF1493, "Ge"  : 0xFF1493, "As"  : 0xFF1493, "Se"  : 0xFF1493, "Br"  : 0xA52A2A, "Kr"  : 0xFF1493,
      "Rb"  : 0xFF1493, "Sr"  : 0xFF1493, "Y"   : 0xFF1493, "Zr"  : 0xFF1493, "Nb"  : 0xFF1493, "Mo"  : 0xFF1493, "Tc"  : 0xFF1493, "Ru"  : 0xFF1493, "Rh"  : 0xFF1493,
      "Pd"  : 0xFF1493, "Ag"  : 0x808090, "Cd"  : 0xFF1493, "In"  : 0xFF1493, "Sn"  : 0xFF1493, "Sb"  : 0xFF1493, "Te"  : 0xFF1493, "I"   : 0xA020F0, "Xe"  : 0xFF1493,
      "Cs"  : 0xFF1493, "Ba"  : 0xFFA500, "La"  : 0xFF1493, "Ce"  : 0xFF1493, "Pr"  : 0xFF1493, "Nd"  : 0xFF1493, "Pm"  : 0xFF1493, "Sm"  : 0xFF1493, "Eu"  : 0xFF1493,
      "Gd"  : 0xFF1493, "Tb"  : 0xFF1493, "Dy"  : 0xFF1493, "Ho"  : 0xFF1493, "Er"  : 0xFF1493, "Tm"  : 0xFF1493, "Yb"  : 0xFF1493, "Lu"  : 0xFF1493, "Hf"  : 0xFF1493,
      "Ta"  : 0xFF1493, "W"   : 0xFF1493, "Re"  : 0xFF1493, "Os"  : 0xFF1493, "Ir"  : 0xFF1493, "Pt"  : 0xFF1493, "Au"  : 0xDAA520, "Hg"  : 0xFF1493, "Tl"  : 0xFF1493,
      "Pb"  : 0xFF1493, "Bi"  : 0xFF1493, "Po"  : 0xFF1493, "At"  : 0xFF1493, "Rn"  : 0xFF1493, "Fr"  : 0xFF1493, "Ra"  : 0xFF1493, "Ac"  : 0xFF1493, "Th"  : 0xFF1493,
      "Pa"  : 0xFF1493, "U"   : 0xFF1493, "Np"  : 0xFF1493, "Pu"  : 0xFF1493, "Am"  : 0xFF1493, "Cm"  : 0xFF1493, "Bk"  : 0xFF1493, "Cf"  : 0xFF1493, "Es"  : 0xFF1493,
      "Fm"  : 0xFF1493, "Md"  : 0xFF1493, "No"  : 0xFF1493, "Lr"  : 0xFF1493, "Rf"  : 0xFF1493, "Db"  : 0xFF1493, "Sg"  : 0xFF1493, "Bh"  : 0xFF1493, "Hs"  : 0xFF1493,
      "Mt"  : 0xFF1493, "Ds"  : 0xFF1493, "Rg"  : 0xFF1493, "Cn"  : 0xFF1493, "Uut" : 0xFF1493, "Uuq" : 0xFF1493, "Uup" : 0xFF1493, "Uuh" : 0xFF1493, "Uus" : 0xFF1493,
      "Uuo" : 0xFF1493
  ]
  
  public static let rasmolModern: [String : UInt32] =
    [
      "H"   : 0xFFFFFF, "He"  : 0xFFC0CB, "Li"  : 0xB22121, "Be"  : 0xFA1691, "B"   : 0x00FF00, "C"   : 0xD3D3D3, "N"   : 0x87CEE6, "O"   : 0xFF0000, "F"   : 0xDAA520,
      "Ne"  : 0xFA1691, "Na"  : 0x0000FF, "Mg"  : 0x228B22, "Al"  : 0x696969, "Si"  : 0xDAA520, "P"   : 0xFFAA00, "S"   : 0xFFFF00, "Cl"  : 0x00FF00, "Ar"  : 0xFA1691,
      "K"   : 0xFA1691, "Ca"  : 0x696969, "Sc"  : 0xFA1691, "Ti"  : 0x696969, "V"   : 0xFA1691, "Cr"  : 0x696969, "Mn"  : 0x696969, "Fe"  : 0xFFAA00, "Co"  : 0xFA1691,
      "Ni"  : 0x802828, "Cu"  : 0x802828, "Zn"  : 0x802828, "Ga"  : 0xFA1691, "Ge"  : 0xFA1691, "As"  : 0xFA1691, "Se"  : 0xFA1691, "Br"  : 0x802828, "Kr"  : 0xFA1691,
      "Rb"  : 0xFA1691, "Sr"  : 0xFA1691, "Y"   : 0xFA1691, "Zr"  : 0xFA1691, "Nb"  : 0xFA1691, "Mo"  : 0xFA1691, "Tc"  : 0xFA1691, "Ru"  : 0xFA1691, "Rh"  : 0xFA1691,
      "Pd"  : 0xFA1691, "Ag"  : 0x696969, "Cd"  : 0xFA1691, "In"  : 0xFA1691, "Sn"  : 0xFA1691, "Sb"  : 0xFA1691, "Te"  : 0xFA1691, "I"   : 0xFA1691, "Xe"  : 0xFA1691,
      "Cs"  : 0xFA1691, "Ba"  : 0xFFAA00, "La"  : 0xFA1691, "Ce"  : 0xFA1691, "Pr"  : 0xFA1691, "Nd"  : 0xFA1691, "Pm"  : 0xFA1691, "Sm"  : 0xFA1691, "Eu"  : 0xFA1691,
      "Gd"  : 0xFA1691, "Tb"  : 0xFA1691, "Dy"  : 0xFA1691, "Ho"  : 0xFA1691, "Er"  : 0xFA1691, "Tm"  : 0xFA1691, "Yb"  : 0xFA1691, "Lu"  : 0xFA1691, "Hf"  : 0xFA1691,
      "Ta"  : 0xFA1691, "W"   : 0xFA1691, "Re"  : 0xFA1691, "Os"  : 0xFA1691, "Ir"  : 0xFA1691, "Pt"  : 0xFA1691, "Au"  : 0xDAA520, "Hg"  : 0xFA1691, "Tl"  : 0xFA1691,
      "Pb"  : 0xFA1691, "Bi"  : 0xFA1691, "Po"  : 0xFA1691, "At"  : 0xFA1691, "Rn"  : 0xFA1691, "Fr"  : 0xFA1691, "Ra"  : 0xFA1691, "Ac"  : 0xFA1691, "Th"  : 0xFA1691,
      "Pa"  : 0xFA1691, "U"   : 0xFA1691, "Np"  : 0xFA1691, "Pu"  : 0xFA1691, "Am"  : 0xFA1691, "Cm"  : 0xFA1691, "Bk"  : 0xFA1691, "Cf"  : 0xFA1691, "Es"  : 0xFA1691,
      "Fm"  : 0xFA1691, "Md"  : 0xFA1691, "No"  : 0xFA1691, "Lr"  : 0xFA1691, "Rf"  : 0xFA1691, "Db"  : 0xFA1691, "Sg"  : 0xFA1691, "Bh"  : 0xFA1691, "Hs"  : 0xFA1691,
      "Mt"  : 0xFA1691, "Ds"  : 0xFA1691, "Rg"  : 0xFA1691, "Cn"  : 0xFA1691, "Uut" : 0xFA1691, "Uuq" : 0xFA1691, "Uup" : 0xFA1691, "Uuh" : 0xFA1691, "Uus" : 0xFA1691,
      "Uuo" : 0xFA1691
  ]
  
  public static let vesta: [String : UInt32] =
    [
      "H"   : 0xFFCCCC, "He"  : 0xFCE9CF, "Li"  : 0x86E074, "Be"  : 0x5FD87B, "B"   : 0x20A20F, "C"   : 0x814929, "N"   : 0xB0BAE6, "O"   : 0xFF0300, "F"   : 0xB0BAE6,
      "Ne"  : 0xFF38B5, "Na"  : 0xFADD3D, "Mg"  : 0xFC7C16, "Al"  : 0x81B3D6, "Si"  : 0x1B3BFA, "P"   : 0xC19CC3, "S"   : 0xFFFA00, "Cl"  : 0x32FC03, "Ar"  : 0xCFFEC5,
      "K"   : 0xA122F7, "Ca"  : 0x5B96BE, "Sc"  : 0xB663AC, "Ti"  : 0x78CAFF, "V"   : 0xE51A00, "Cr"  : 0x00009E, "Mn"  : 0xA9099E, "Fe"  : 0xB57200, "Co"  : 0x0000AF,
      "Ni"  : 0xB8BCBE, "Cu"  : 0x2247DD, "Zn"  : 0x8F9082, "Ga"  : 0x9FE474, "Ge"  : 0x7E6FA6, "As"  : 0x75D057, "Se"  : 0x9AEF10, "Br"  : 0x7F3103, "Kr"  : 0xFAC1F3,
      "Rb"  : 0xFF0099, "Sr"  : 0x00FF27, "Y"   : 0x67988E, "Zr"  : 0x00FF00, "Nb"  : 0x4CB376, "Mo"  : 0xB486B0, "Tc"  : 0xCDAFCB, "Ru"  : 0xCFB8AE, "Rh"  : 0xCED2AB,
      "Pd"  : 0xC2C4b9, "Ag"  : 0xB8BCBE, "Cd"  : 0xF31FDC, "In"  : 0xD781BB, "Sn"  : 0x9B8FBA, "Sb"  : 0xD88350, "Te"  : 0xADA252, "I"   : 0x8F1F8B, "Xe"  : 0x9BA1F8,
      "Cs"  : 0x0FFFB9, "Ba"  : 0x1AF02D, "La"  : 0x5AC449, "Ce"  : 0xD1FD06, "Pr"  : 0xFDE206, "Nd"  : 0xFC8E07, "Pm"  : 0x0000F5, "Sm"  : 0xFD067D, "Eu"  : 0xFB08D5,
      "Gd"  : 0xC004FF, "Tb"  : 0x7104FE, "Dy"  : 0x3106FD, "Ho"  : 0x0742FB, "Er"  : 0x49733B, "Tm"  : 0x0000E0, "Yb"  : 0x27FDF4, "Lu"  : 0x26FDB5, "Hf"  : 0xB4B459,
      "Ta"  : 0xB79B56, "W"   : 0x8E8A80, "Re"  : 0xB3b18E, "Os"  : 0xC9B179, "Ir"  : 0xC9CF73, "Pt"  : 0xCCC6BF, "Au"  : 0xFEB338, "Hg"  : 0xD3B8CC, "Tl"  : 0x96896D,
      "Pb"  : 0x53535B, "Bi"  : 0xD230F8, "Po"  : 0x0000FF, "At"  : 0x0000FF, "Rn"  : 0xFFFF00, "Fr"  : 0x000000, "Ra"  : 0x6eAA59, "Ac"  : 0x649E73, "Th"  : 0x26FE78,
      "Pa"  : 0x29FB35, "U"   : 0x7aA2AA, "Np"  : 0x4C4C4C, "Pu"  : 0x4C4C4C, "Am"  : 0x4C4C4C, "Cm"  : 0x4C4C4C, "Bk"  : 0x4C4C4C, "Cf"  : 0x4C4C4C, "Es"  : 0x4C4C4C,
      "Fm"  : 0x4C4C4C, "Md"  : 0x4C4C4C, "No"  : 0x4C4C4C, "Lr"  : 0x4C4C4C, "Rf"  : 0x4C4C4C, "Db"  : 0x4C4C4C, "Sg"  : 0x4C4C4C, "Bh"  : 0x4C4C4C, "Hs"  : 0x4C4C4C,
      "Mt"  : 0x4C4C4C, "Ds"  : 0x4C4C4C, "Rg"  : 0x4C4C4C, "Cn"  : 0x4C4C4C, "Uut" : 0x4C4C4C, "Uuq" : 0x4C4C4C, "Uup" : 0x4C4C4C, "Uuh" : 0x4C4C4C, "Uus" : 0x4C4C4C,
      "Uuo" : 0x4C4C4C
  ]
}

