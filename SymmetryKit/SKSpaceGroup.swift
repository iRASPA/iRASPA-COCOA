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
import simd
import MathKit


// Spacegroup determination
// ======================================================================================
//
// Assumption
// ----------
// The configuration in question is originally described using some basis B with basis vectors a, b, and c. The atoms of the configuration are
// described by triplets of fractional coordinates with respect to the basis B. This basis B is purely descriptive and does not follow the 
// crystallographic conventions; in particular, there may exist additional translational symmetries.
//
//
// Step 1
// ------
// In order to reach a standard description of the structure, a primitive cell must be obtained as a first step. Since we cannot assume that 
// the initial cell constants reflect the lattice symmetry as for a conventional unit cell, we cannot use standard crystallographic methods
// (e.g. cell reduction) for this purpose. Instead, the full translational symmetry has to be obtained from the translations of the configuration.
// If one uses a non- primitive cell [e.g. exhibiting trivial symmetries such as  (x +1/2, y, z]), it is not guaranteed that all symmetries
// will be found, one might end up with only a subgroup of the space group (R. Hundt, "Determination of symmetries and idealized cell parameters
// for simulated structures", J. Appl. Cryst., 32, 413-416, 1999)
//
// Step 2
// ------
// The symmetry elements of the lattice are determined.
//
// Step 3
// ------
// The symmetry elements of the actual configuration are determined by eleminating lattice symmetries that do not hold for the atomic positions.





extension String
{
  func replace(_ string:String, replacement:String) -> String
  {
    return self.replacingOccurrences(of: string, with: replacement, options: NSString.CompareOptions.literal, range: nil)
  }
  
  func removeWhitespace() -> String
  {
    return self.replace(" ", replacement: "")
  }
}








public struct SKSpacegroup
{
  public var spaceGroupSetting: SKSpaceGroupSetting
  var angleTolerance: Double = -1.0
  
  
  public enum Centring: Int
  {
    case none = 0
    case primitive = 1 // primitive (multiplicity: 1)
    case body = 2      // body centred (multiplicity: 2)
    case a_face = 3    // A-face centred (multiplicity: 2)
    case b_face = 4    // B-face centred (multiplicity: 2)
    case c_face = 5    // C-face centred (multiplicity: 2)
    case face = 6      // All-face centred (multiplicity: 4)
    case base = 7      // I,A,B,C
    case r = 8         // Rhombohedrally centred (hexagonal axes, multiplicity: 3) or Primitive (rhombohedral axes, multiplicity: 1)
    case h = 9         // Hexagonally centred (multiplicity: 3)
    case d = 10        // Rhombohedrally centred (multiplicity: 3)
  }
  
  enum monoclinicConvention: Int
  {
    case b = 0           // a(b)c
    case b_minus = 1     // c(-b)a
    case c = 2           // ab(c)
    case c_minus = 3     // ba(-c)
    case a = 4           // (a)bc
    case a_minus = 5     // (-a)cb
  }
  
  enum monoclinicCellConvention: Int
  {
    case cell_1 = 0
    case cell_2 = 1
    case cell_3 = 2
  }

  enum orthorhombicConvention: Int
  {
    case abc = 0          // abc
    case ba_c = 1         // ba-c
    case cab = 2          // cab
    case _cba = 3         // -cba
    case bca = 4          // bca
    case a_cb = 5         // a-cb
  }
  
  
  enum originConvention: Int
  {
    case first = 0
    case second = 1
  }

  enum axesConvention: Int
  {
    case hexagonal = 0
    case rhombohedral = 1
  }
  
  public init?(Hall: String)
  {
    var spacesGroupFiltered = SKSpacegroup.spaceGroupData.filter{$0.Hall.removeWhitespace() == Hall.removeWhitespace()}
    
    switch(spacesGroupFiltered.count)
    {
    case 0:
      break
    case 1:
      spaceGroupSetting = spacesGroupFiltered[0]
      return
    default:
      spaceGroupSetting = spacesGroupFiltered[0]
      return
    }
    
    spacesGroupFiltered = SKSpacegroup.spaceGroupData.filter{"\'"+$0.Hall.removeWhitespace()+"\'" == Hall.removeWhitespace()}
    
    switch(spacesGroupFiltered.count)
    {
    case 0:
      break
    case 1:
      spaceGroupSetting = spacesGroupFiltered[0]
      return
    default:
      spaceGroupSetting = spacesGroupFiltered[0]
      return
    }
    return nil
  }
  
  public init?(H_M: String)
  {
    var spacesGroupFiltered: [SKSpaceGroupSetting] = []
    
    spacesGroupFiltered = SKSpacegroup.spaceGroupData.filter{$0.HM.removeWhitespace() == H_M.removeWhitespace()}
   
    guard (spacesGroupFiltered.count == 0) else
    {
      self.spaceGroupSetting = spacesGroupFiltered[0]
      return
    }
    
    
    spacesGroupFiltered = SKSpacegroup.spaceGroupData.filter{($0.HM.removeWhitespace()+":"+String(UnicodeScalar($0.ext))).lowercased() == H_M.removeWhitespace().lowercased()}
    guard (spacesGroupFiltered.count == 0) else
    {
      self.spaceGroupSetting = spacesGroupFiltered[0]
      return
    }
    
    switch(spacesGroupFiltered.count)
    {
    case 0:
      break
    case 1:
      self.spaceGroupSetting = spacesGroupFiltered[0]
      return
    default:
      break
    }

    
    let spacesGroupFiltered2 = SKSpacegroup.spaceGroupData.filter{"\'"+$0.HM.removeWhitespace()+"\'" == H_M.removeWhitespace()}
    
    switch(spacesGroupFiltered2.count)
    {
    case 0:
      break
    case 1:
      self.spaceGroupSetting = spacesGroupFiltered2[0]
      return
    default:
      break
    }
    return nil
  }
  
  public init()
  {
    self.init(Hall: "\' P 1\'")!
  }
  
  public init(HallNumber: Int)
  {
    assert(HallNumber >= 0 && HallNumber <= 530)
    self.spaceGroupSetting = SKSpacegroup.spaceGroupData[HallNumber]
  }
  
  public init?(number: Int)
  {
    assert(number >= 0 && number <= 230)
    if let HallNumber: Int = SKSpacegroup.spaceGroupHallData[number]?.first
    {
      self.spaceGroupSetting = SKSpacegroup.spaceGroupData[HallNumber]
      return
    }
    return nil
  }
  
  public var number: Int
  {
    get
    {
      return Int(self.spaceGroupSetting.spaceGroupNumber)
    }
  }
  
  
  public var searchGenerators: [SKSeitzMatrix]
  {
    let symmetryOperationsSet: SKSymmetryOperationSet = SKSymmetryOperationSet(spaceGroupSetting: self.spaceGroupSetting, centroSymmetric: false)
    
    let holedry: SKPointGroup.Holohedry = self.spaceGroupSetting.pointGroup.holohedry
    

    if let generatorSet: (required: [SKRotationMatrix], optional: [SKRotationMatrix]) = SKRotationMatrix.generators[holedry]
    {
      var generatorList: [SKSeitzMatrix] = []
        
      for generator in generatorSet.required
      {
        let requiredRotationMatrices: [SKSeitzMatrix] = symmetryOperationsSet.operations.filter{$0.rotation.proper == generator}
        if requiredRotationMatrices.isEmpty
        {
          continue
        }
        generatorList.append(requiredRotationMatrices.first!)
        
        for generator in generatorSet.optional
        {
          let foundRotationMatrices: [SKSeitzMatrix] = symmetryOperationsSet.operations.filter{$0.rotation.proper == generator}
          if !foundRotationMatrices.isEmpty
          {
            generatorList.append(foundRotationMatrices.first!)
          }
        }
        
        if generatorList.isEmpty
        {
          continue
        }
        
        
        let centroSymmetric: Bool = SKPointGroup.pointGroupData[spaceGroupSetting.pointGroupNumber].centrosymmetric
        
        if centroSymmetric
        {
          let symmetryOperationsSet: SKSymmetryOperationSet = SKSymmetryOperationSet(spaceGroupSetting: self.spaceGroupSetting, centroSymmetric: true)
          let inversionMatrices: [SKSeitzMatrix] = symmetryOperationsSet.operations.filter{$0.rotation == SKRotationMatrix.inversionIdentity}
          if !inversionMatrices.isEmpty
          {
            generatorList.append(inversionMatrices.first!)
          }
        }
      
        return generatorList
      }
    }
    
    return []
  }
  
  public func listOfSymmetricPositions(_ pos: SIMD3<Double>) -> [SIMD3<Double>]
  {
    let seitzMatrices = self.spaceGroupSetting.fullSeitzMatrices
    let m: Int = seitzMatrices.operations.count
    
    var positions: [SIMD3<Double>] = [SIMD3<Double>](repeating: SIMD3<Double>(), count: m)
    
    for (i, seitzMatrix) in seitzMatrices.operations.enumerated()
    {
      positions[i] = seitzMatrix * SIMD3<Double>(x: pos.x, y: pos.y, z: pos.z)
    }
    return positions
  }
  
  
   
  
  public static func listOfTranslationVectors(_ setting: SKSpaceGroupSetting) -> [SIMD3<Int32>]
  {
    let index = setting.Hall.index(setting.Hall.startIndex, offsetBy: 1)
   
    switch(setting.Hall[index])
    {
    case "A":
      return [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,6,6)]
    case "B":
      return [SIMD3<Int32>(0,0,0),SIMD3<Int32>(6,0,6)]
    case "C":
      return [SIMD3<Int32>(0,0,0),SIMD3<Int32>(6,6,0)]
    case "I":
      return [SIMD3<Int32>(0,0,0),SIMD3<Int32>(6,6,6)]
    case "P":
      return [SIMD3<Int32>(0,0,0)]
    case "R":
      return [SIMD3<Int32>(0,0,0),SIMD3<Int32>(8,4,4),SIMD3<Int32>(4,8,8)]
    case "F":
      return [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,6,6),SIMD3<Int32>(6,0,6),SIMD3<Int32>(6,6,0)]
    default:
      return [SIMD3<Int32>(0,0,0)]
    }
  }
  
  
  
  // Table 2 from R. W. Grosse-Kunstleve, Acta Cryst. (1999). A55, 383-395
  public static let changeOfMonoclinicCentering: [SKChangeOfBasis] =
  [
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)])), //  1 : I
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>(-1, 0,-1), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 1, 0, 0)])), //  2 : R3
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>(-1, 0,-1)])), //  3 : R3.R3
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 0,-1, 0), SIMD3<Int32>( 1, 0, 0)])), //  4 : R2
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>(-1, 0,-1), SIMD3<Int32>( 0,-1, 0), SIMD3<Int32>( 0, 0, 1)])), //  5 : R2.R3
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0,-1, 0), SIMD3<Int32>(-1, 0,-1)])), //  6 : R2.R3.R3

  ]
  
  
  // Table 2 from R. W. Grosse-Kunstleve, Acta Cryst. (1999). A55, 383-395
  public static let changeOfOrthorhombicCentering: [SKChangeOfBasis] =
  [
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)])), // 1 : I
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 1, 0, 0)])), // 2 : R3
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0)])), // 3 : R3.R3
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 0,-1)])), // 4 : R2
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 0,-1), SIMD3<Int32>( 0, 1, 0)])), // 5 : R2.R3
    SKChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0,-1), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 1, 0, 0)]))  // 6 : R2.R3.R3
  ]
  
  public static var HallSymbols: [String]
  {
    return SKSpacegroup.spaceGroupData.compactMap{String($0.number) + " " + $0.Hall}
  }
  
  public static var numbers: [String]
  {
    return Array(0...230).map{String(describing: $0)}
  }
  
  
  public static func spacegroupQualifiers(number: Int) -> [String]
  {
    return SKSpacegroup.spaceGroupData.filter{$0.spaceGroupNumber == number}.map{(($0.ext > 0) ? (String(describing: $0.ext) + ":") : "") + $0.qualifier}
  }
  
  // Note the starting space in the Hall-symbol. This is so Hall[1] is the cell type.
  // Generated using cctbx, run as: 'cctbx_build/bin/cctbx.python script.py'
  //
  // from cctbx import sgtbx
  // import sm_dict
  // def encode_xyz(xyz):
  //   return "".join(chr(sm_dict.keys.index(t)+ord('0')) for t in xyz.split(","))
  // for s in sgtbx.space_group_symbol_iterator():
  //   ext_ = s.extension()
  //   ext = ("'%s'" % ext_ if (ext_ and ext_ != '\0') else "0")
  //   qualif = '"%s"' % s.qualifier()
  //   hm = '"%s",' % s.hermann_mauguin()
  //   hall = '"%s"' % s.hall().replace('"', r'\"')
  //   sm = '""'.join(encode_xyz(m.as_xyz())
  //   for m in sgtbx.space_group(s.hall()).smx()
  //     if not m.is_unit_mx())
  //       print '{ %3d, %3s, %6s, %-13s %-17s,\n  "%s" },' % (
  //       s.number(), ext, qualif, hm, hall, sm)
  static let spaceGroupData: [SKSpaceGroupSetting] =
  [
     SKSpaceGroupSetting.spaceGroupHall0,
     SKSpaceGroupSetting.spaceGroupHall1,
     SKSpaceGroupSetting.spaceGroupHall2,
     SKSpaceGroupSetting.spaceGroupHall3,
     SKSpaceGroupSetting.spaceGroupHall4,
     SKSpaceGroupSetting.spaceGroupHall5,
     SKSpaceGroupSetting.spaceGroupHall6,
     SKSpaceGroupSetting.spaceGroupHall7,
     SKSpaceGroupSetting.spaceGroupHall8,
     SKSpaceGroupSetting.spaceGroupHall9,
     SKSpaceGroupSetting.spaceGroupHall10,
     SKSpaceGroupSetting.spaceGroupHall11,
     SKSpaceGroupSetting.spaceGroupHall12,
     SKSpaceGroupSetting.spaceGroupHall13,
     SKSpaceGroupSetting.spaceGroupHall14,
     SKSpaceGroupSetting.spaceGroupHall15,
     SKSpaceGroupSetting.spaceGroupHall16,
     SKSpaceGroupSetting.spaceGroupHall17,
     SKSpaceGroupSetting.spaceGroupHall18,
     SKSpaceGroupSetting.spaceGroupHall19,
     SKSpaceGroupSetting.spaceGroupHall20,
     SKSpaceGroupSetting.spaceGroupHall21,
     SKSpaceGroupSetting.spaceGroupHall22,
     SKSpaceGroupSetting.spaceGroupHall23,
     SKSpaceGroupSetting.spaceGroupHall24,
     SKSpaceGroupSetting.spaceGroupHall25,
     SKSpaceGroupSetting.spaceGroupHall26,
     SKSpaceGroupSetting.spaceGroupHall27,
     SKSpaceGroupSetting.spaceGroupHall28,
     SKSpaceGroupSetting.spaceGroupHall29,
     SKSpaceGroupSetting.spaceGroupHall30,
     SKSpaceGroupSetting.spaceGroupHall31,
     SKSpaceGroupSetting.spaceGroupHall32,
     SKSpaceGroupSetting.spaceGroupHall33,
     SKSpaceGroupSetting.spaceGroupHall34,
     SKSpaceGroupSetting.spaceGroupHall35,
     SKSpaceGroupSetting.spaceGroupHall36,
     SKSpaceGroupSetting.spaceGroupHall37,
     SKSpaceGroupSetting.spaceGroupHall38,
     SKSpaceGroupSetting.spaceGroupHall39,
     SKSpaceGroupSetting.spaceGroupHall40,
     SKSpaceGroupSetting.spaceGroupHall41,
     SKSpaceGroupSetting.spaceGroupHall42,
     SKSpaceGroupSetting.spaceGroupHall43,
     SKSpaceGroupSetting.spaceGroupHall44,
     SKSpaceGroupSetting.spaceGroupHall45,
     SKSpaceGroupSetting.spaceGroupHall46,
     SKSpaceGroupSetting.spaceGroupHall47,
     SKSpaceGroupSetting.spaceGroupHall48,
     SKSpaceGroupSetting.spaceGroupHall49,
     SKSpaceGroupSetting.spaceGroupHall50,
     SKSpaceGroupSetting.spaceGroupHall51,
     SKSpaceGroupSetting.spaceGroupHall52,
     SKSpaceGroupSetting.spaceGroupHall53,
     SKSpaceGroupSetting.spaceGroupHall54,
     SKSpaceGroupSetting.spaceGroupHall55,
     SKSpaceGroupSetting.spaceGroupHall56,
     SKSpaceGroupSetting.spaceGroupHall57,
     SKSpaceGroupSetting.spaceGroupHall58,
     SKSpaceGroupSetting.spaceGroupHall59,
     SKSpaceGroupSetting.spaceGroupHall60,
     SKSpaceGroupSetting.spaceGroupHall61,
     SKSpaceGroupSetting.spaceGroupHall62,
     SKSpaceGroupSetting.spaceGroupHall63,
     SKSpaceGroupSetting.spaceGroupHall64,
     SKSpaceGroupSetting.spaceGroupHall65,
     SKSpaceGroupSetting.spaceGroupHall66,
     SKSpaceGroupSetting.spaceGroupHall67,
     SKSpaceGroupSetting.spaceGroupHall68,
     SKSpaceGroupSetting.spaceGroupHall69,
     SKSpaceGroupSetting.spaceGroupHall70,
     SKSpaceGroupSetting.spaceGroupHall71,
     SKSpaceGroupSetting.spaceGroupHall72,
     SKSpaceGroupSetting.spaceGroupHall73,
     SKSpaceGroupSetting.spaceGroupHall74,
     SKSpaceGroupSetting.spaceGroupHall75,
     SKSpaceGroupSetting.spaceGroupHall76,
     SKSpaceGroupSetting.spaceGroupHall77,
     SKSpaceGroupSetting.spaceGroupHall78,
     SKSpaceGroupSetting.spaceGroupHall79,
     SKSpaceGroupSetting.spaceGroupHall80,
     SKSpaceGroupSetting.spaceGroupHall81,
     SKSpaceGroupSetting.spaceGroupHall82,
     SKSpaceGroupSetting.spaceGroupHall83,
     SKSpaceGroupSetting.spaceGroupHall84,
     SKSpaceGroupSetting.spaceGroupHall85,
     SKSpaceGroupSetting.spaceGroupHall86,
     SKSpaceGroupSetting.spaceGroupHall87,
     SKSpaceGroupSetting.spaceGroupHall88,
     SKSpaceGroupSetting.spaceGroupHall89,
     SKSpaceGroupSetting.spaceGroupHall90,
     SKSpaceGroupSetting.spaceGroupHall91,
     SKSpaceGroupSetting.spaceGroupHall92,
     SKSpaceGroupSetting.spaceGroupHall93,
     SKSpaceGroupSetting.spaceGroupHall94,
     SKSpaceGroupSetting.spaceGroupHall95,
     SKSpaceGroupSetting.spaceGroupHall96,
     SKSpaceGroupSetting.spaceGroupHall97,
     SKSpaceGroupSetting.spaceGroupHall98,
     SKSpaceGroupSetting.spaceGroupHall99,
     SKSpaceGroupSetting.spaceGroupHall100,
     SKSpaceGroupSetting.spaceGroupHall101,
     SKSpaceGroupSetting.spaceGroupHall102,
     SKSpaceGroupSetting.spaceGroupHall103,
     SKSpaceGroupSetting.spaceGroupHall104,
     SKSpaceGroupSetting.spaceGroupHall105,
     SKSpaceGroupSetting.spaceGroupHall106,
     SKSpaceGroupSetting.spaceGroupHall107,
     SKSpaceGroupSetting.spaceGroupHall108,
     SKSpaceGroupSetting.spaceGroupHall109,
     SKSpaceGroupSetting.spaceGroupHall110,
     SKSpaceGroupSetting.spaceGroupHall111,
     SKSpaceGroupSetting.spaceGroupHall112,
     SKSpaceGroupSetting.spaceGroupHall113,
     SKSpaceGroupSetting.spaceGroupHall114,
     SKSpaceGroupSetting.spaceGroupHall115,
     SKSpaceGroupSetting.spaceGroupHall116,
     SKSpaceGroupSetting.spaceGroupHall117,
     SKSpaceGroupSetting.spaceGroupHall118,
     SKSpaceGroupSetting.spaceGroupHall119,
     SKSpaceGroupSetting.spaceGroupHall120,
     SKSpaceGroupSetting.spaceGroupHall121,
     SKSpaceGroupSetting.spaceGroupHall122,
     SKSpaceGroupSetting.spaceGroupHall123,
     SKSpaceGroupSetting.spaceGroupHall124,
     SKSpaceGroupSetting.spaceGroupHall125,
     SKSpaceGroupSetting.spaceGroupHall126,
     SKSpaceGroupSetting.spaceGroupHall127,
     SKSpaceGroupSetting.spaceGroupHall128,
     SKSpaceGroupSetting.spaceGroupHall129,
     SKSpaceGroupSetting.spaceGroupHall130,
     SKSpaceGroupSetting.spaceGroupHall131,
     SKSpaceGroupSetting.spaceGroupHall132,
     SKSpaceGroupSetting.spaceGroupHall133,
     SKSpaceGroupSetting.spaceGroupHall134,
     SKSpaceGroupSetting.spaceGroupHall135,
     SKSpaceGroupSetting.spaceGroupHall136,
     SKSpaceGroupSetting.spaceGroupHall137,
     SKSpaceGroupSetting.spaceGroupHall138,
     SKSpaceGroupSetting.spaceGroupHall139,
     SKSpaceGroupSetting.spaceGroupHall140,
     SKSpaceGroupSetting.spaceGroupHall141,
     SKSpaceGroupSetting.spaceGroupHall142,
     SKSpaceGroupSetting.spaceGroupHall143,
     SKSpaceGroupSetting.spaceGroupHall144,
     SKSpaceGroupSetting.spaceGroupHall145,
     SKSpaceGroupSetting.spaceGroupHall146,
     SKSpaceGroupSetting.spaceGroupHall147,
     SKSpaceGroupSetting.spaceGroupHall148,
     SKSpaceGroupSetting.spaceGroupHall149,
     SKSpaceGroupSetting.spaceGroupHall150,
     SKSpaceGroupSetting.spaceGroupHall151,
     SKSpaceGroupSetting.spaceGroupHall152,
     SKSpaceGroupSetting.spaceGroupHall153,
     SKSpaceGroupSetting.spaceGroupHall154,
     SKSpaceGroupSetting.spaceGroupHall155,
     SKSpaceGroupSetting.spaceGroupHall156,
     SKSpaceGroupSetting.spaceGroupHall157,
     SKSpaceGroupSetting.spaceGroupHall158,
     SKSpaceGroupSetting.spaceGroupHall159,
     SKSpaceGroupSetting.spaceGroupHall160,
     SKSpaceGroupSetting.spaceGroupHall161,
     SKSpaceGroupSetting.spaceGroupHall162,
     SKSpaceGroupSetting.spaceGroupHall163,
     SKSpaceGroupSetting.spaceGroupHall164,
     SKSpaceGroupSetting.spaceGroupHall165,
     SKSpaceGroupSetting.spaceGroupHall166,
     SKSpaceGroupSetting.spaceGroupHall167,
     SKSpaceGroupSetting.spaceGroupHall168,
     SKSpaceGroupSetting.spaceGroupHall169,
     SKSpaceGroupSetting.spaceGroupHall170,
     SKSpaceGroupSetting.spaceGroupHall171,
     SKSpaceGroupSetting.spaceGroupHall172,
     SKSpaceGroupSetting.spaceGroupHall173,
     SKSpaceGroupSetting.spaceGroupHall174,
     SKSpaceGroupSetting.spaceGroupHall175,
     SKSpaceGroupSetting.spaceGroupHall176,
     SKSpaceGroupSetting.spaceGroupHall177,
     SKSpaceGroupSetting.spaceGroupHall178,
     SKSpaceGroupSetting.spaceGroupHall179,
     SKSpaceGroupSetting.spaceGroupHall180,
     SKSpaceGroupSetting.spaceGroupHall181,
     SKSpaceGroupSetting.spaceGroupHall182,
     SKSpaceGroupSetting.spaceGroupHall183,
     SKSpaceGroupSetting.spaceGroupHall184,
     SKSpaceGroupSetting.spaceGroupHall185,
     SKSpaceGroupSetting.spaceGroupHall186,
     SKSpaceGroupSetting.spaceGroupHall187,
     SKSpaceGroupSetting.spaceGroupHall188,
     SKSpaceGroupSetting.spaceGroupHall189,
     SKSpaceGroupSetting.spaceGroupHall190,
     SKSpaceGroupSetting.spaceGroupHall191,
     SKSpaceGroupSetting.spaceGroupHall192,
     SKSpaceGroupSetting.spaceGroupHall193,
     SKSpaceGroupSetting.spaceGroupHall194,
     SKSpaceGroupSetting.spaceGroupHall195,
     SKSpaceGroupSetting.spaceGroupHall196,
     SKSpaceGroupSetting.spaceGroupHall197,
     SKSpaceGroupSetting.spaceGroupHall198,
     SKSpaceGroupSetting.spaceGroupHall199,
     SKSpaceGroupSetting.spaceGroupHall200,
     SKSpaceGroupSetting.spaceGroupHall201,
     SKSpaceGroupSetting.spaceGroupHall202,
     SKSpaceGroupSetting.spaceGroupHall203,
     SKSpaceGroupSetting.spaceGroupHall204,
     SKSpaceGroupSetting.spaceGroupHall205,
     SKSpaceGroupSetting.spaceGroupHall206,
     SKSpaceGroupSetting.spaceGroupHall207,
     SKSpaceGroupSetting.spaceGroupHall208,
     SKSpaceGroupSetting.spaceGroupHall209,
     SKSpaceGroupSetting.spaceGroupHall210,
     SKSpaceGroupSetting.spaceGroupHall211,
     SKSpaceGroupSetting.spaceGroupHall212,
     SKSpaceGroupSetting.spaceGroupHall213,
     SKSpaceGroupSetting.spaceGroupHall214,
     SKSpaceGroupSetting.spaceGroupHall215,
     SKSpaceGroupSetting.spaceGroupHall216,
     SKSpaceGroupSetting.spaceGroupHall217,
     SKSpaceGroupSetting.spaceGroupHall218,
     SKSpaceGroupSetting.spaceGroupHall219,
     SKSpaceGroupSetting.spaceGroupHall220,
     SKSpaceGroupSetting.spaceGroupHall221,
     SKSpaceGroupSetting.spaceGroupHall222,
     SKSpaceGroupSetting.spaceGroupHall223,
     SKSpaceGroupSetting.spaceGroupHall224,
     SKSpaceGroupSetting.spaceGroupHall225,
     SKSpaceGroupSetting.spaceGroupHall226,
     SKSpaceGroupSetting.spaceGroupHall227,
     SKSpaceGroupSetting.spaceGroupHall228,
     SKSpaceGroupSetting.spaceGroupHall229,
     SKSpaceGroupSetting.spaceGroupHall230,
     SKSpaceGroupSetting.spaceGroupHall231,
     SKSpaceGroupSetting.spaceGroupHall232,
     SKSpaceGroupSetting.spaceGroupHall233,
     SKSpaceGroupSetting.spaceGroupHall234,
     SKSpaceGroupSetting.spaceGroupHall235,
     SKSpaceGroupSetting.spaceGroupHall236,
     SKSpaceGroupSetting.spaceGroupHall237,
     SKSpaceGroupSetting.spaceGroupHall238,
     SKSpaceGroupSetting.spaceGroupHall239,
     SKSpaceGroupSetting.spaceGroupHall240,
     SKSpaceGroupSetting.spaceGroupHall241,
     SKSpaceGroupSetting.spaceGroupHall242,
     SKSpaceGroupSetting.spaceGroupHall243,
     SKSpaceGroupSetting.spaceGroupHall244,
     SKSpaceGroupSetting.spaceGroupHall245,
     SKSpaceGroupSetting.spaceGroupHall246,
     SKSpaceGroupSetting.spaceGroupHall247,
     SKSpaceGroupSetting.spaceGroupHall248,
     SKSpaceGroupSetting.spaceGroupHall249,
     SKSpaceGroupSetting.spaceGroupHall250,
     SKSpaceGroupSetting.spaceGroupHall251,
     SKSpaceGroupSetting.spaceGroupHall252,
     SKSpaceGroupSetting.spaceGroupHall253,
     SKSpaceGroupSetting.spaceGroupHall254,
     SKSpaceGroupSetting.spaceGroupHall255,
     SKSpaceGroupSetting.spaceGroupHall256,
     SKSpaceGroupSetting.spaceGroupHall257,
     SKSpaceGroupSetting.spaceGroupHall258,
     SKSpaceGroupSetting.spaceGroupHall259,
     SKSpaceGroupSetting.spaceGroupHall260,
     SKSpaceGroupSetting.spaceGroupHall261,
     SKSpaceGroupSetting.spaceGroupHall262,
     SKSpaceGroupSetting.spaceGroupHall263,
     SKSpaceGroupSetting.spaceGroupHall264,
     SKSpaceGroupSetting.spaceGroupHall265,
     SKSpaceGroupSetting.spaceGroupHall266,
     SKSpaceGroupSetting.spaceGroupHall267,
     SKSpaceGroupSetting.spaceGroupHall268,
     SKSpaceGroupSetting.spaceGroupHall269,
     SKSpaceGroupSetting.spaceGroupHall270,
     SKSpaceGroupSetting.spaceGroupHall271,
     SKSpaceGroupSetting.spaceGroupHall272,
     SKSpaceGroupSetting.spaceGroupHall273,
     SKSpaceGroupSetting.spaceGroupHall274,
     SKSpaceGroupSetting.spaceGroupHall275,
     SKSpaceGroupSetting.spaceGroupHall276,
     SKSpaceGroupSetting.spaceGroupHall277,
     SKSpaceGroupSetting.spaceGroupHall278,
     SKSpaceGroupSetting.spaceGroupHall279,
     SKSpaceGroupSetting.spaceGroupHall280,
     SKSpaceGroupSetting.spaceGroupHall281,
     SKSpaceGroupSetting.spaceGroupHall282,
     SKSpaceGroupSetting.spaceGroupHall283,
     SKSpaceGroupSetting.spaceGroupHall284,
     SKSpaceGroupSetting.spaceGroupHall285,
     SKSpaceGroupSetting.spaceGroupHall286,
     SKSpaceGroupSetting.spaceGroupHall287,
     SKSpaceGroupSetting.spaceGroupHall288,
     SKSpaceGroupSetting.spaceGroupHall289,
     SKSpaceGroupSetting.spaceGroupHall290,
     SKSpaceGroupSetting.spaceGroupHall291,
     SKSpaceGroupSetting.spaceGroupHall292,
     SKSpaceGroupSetting.spaceGroupHall293,
     SKSpaceGroupSetting.spaceGroupHall294,
     SKSpaceGroupSetting.spaceGroupHall295,
     SKSpaceGroupSetting.spaceGroupHall296,
     SKSpaceGroupSetting.spaceGroupHall297,
     SKSpaceGroupSetting.spaceGroupHall298,
     SKSpaceGroupSetting.spaceGroupHall299,
     SKSpaceGroupSetting.spaceGroupHall300,
     SKSpaceGroupSetting.spaceGroupHall301,
     SKSpaceGroupSetting.spaceGroupHall302,
     SKSpaceGroupSetting.spaceGroupHall303,
     SKSpaceGroupSetting.spaceGroupHall304,
     SKSpaceGroupSetting.spaceGroupHall305,
     SKSpaceGroupSetting.spaceGroupHall306,
     SKSpaceGroupSetting.spaceGroupHall307,
     SKSpaceGroupSetting.spaceGroupHall308,
     SKSpaceGroupSetting.spaceGroupHall309,
     SKSpaceGroupSetting.spaceGroupHall310,
     SKSpaceGroupSetting.spaceGroupHall311,
     SKSpaceGroupSetting.spaceGroupHall312,
     SKSpaceGroupSetting.spaceGroupHall313,
     SKSpaceGroupSetting.spaceGroupHall314,
     SKSpaceGroupSetting.spaceGroupHall315,
     SKSpaceGroupSetting.spaceGroupHall316,
     SKSpaceGroupSetting.spaceGroupHall317,
     SKSpaceGroupSetting.spaceGroupHall318,
     SKSpaceGroupSetting.spaceGroupHall319,
     SKSpaceGroupSetting.spaceGroupHall320,
     SKSpaceGroupSetting.spaceGroupHall321,
     SKSpaceGroupSetting.spaceGroupHall322,
     SKSpaceGroupSetting.spaceGroupHall323,
     SKSpaceGroupSetting.spaceGroupHall324,
     SKSpaceGroupSetting.spaceGroupHall325,
     SKSpaceGroupSetting.spaceGroupHall326,
     SKSpaceGroupSetting.spaceGroupHall327,
     SKSpaceGroupSetting.spaceGroupHall328,
     SKSpaceGroupSetting.spaceGroupHall329,
     SKSpaceGroupSetting.spaceGroupHall330,
     SKSpaceGroupSetting.spaceGroupHall331,
     SKSpaceGroupSetting.spaceGroupHall332,
     SKSpaceGroupSetting.spaceGroupHall333,
     SKSpaceGroupSetting.spaceGroupHall334,
     SKSpaceGroupSetting.spaceGroupHall335,
     SKSpaceGroupSetting.spaceGroupHall336,
     SKSpaceGroupSetting.spaceGroupHall337,
     SKSpaceGroupSetting.spaceGroupHall338,
     SKSpaceGroupSetting.spaceGroupHall339,
     SKSpaceGroupSetting.spaceGroupHall340,
     SKSpaceGroupSetting.spaceGroupHall341,
     SKSpaceGroupSetting.spaceGroupHall342,
     SKSpaceGroupSetting.spaceGroupHall343,
     SKSpaceGroupSetting.spaceGroupHall344,
     SKSpaceGroupSetting.spaceGroupHall345,
     SKSpaceGroupSetting.spaceGroupHall346,
     SKSpaceGroupSetting.spaceGroupHall347,
     SKSpaceGroupSetting.spaceGroupHall348,
     SKSpaceGroupSetting.spaceGroupHall349,
     SKSpaceGroupSetting.spaceGroupHall350,
     SKSpaceGroupSetting.spaceGroupHall351,
     SKSpaceGroupSetting.spaceGroupHall352,
     SKSpaceGroupSetting.spaceGroupHall353,
     SKSpaceGroupSetting.spaceGroupHall354,
     SKSpaceGroupSetting.spaceGroupHall355,
     SKSpaceGroupSetting.spaceGroupHall356,
     SKSpaceGroupSetting.spaceGroupHall357,
     SKSpaceGroupSetting.spaceGroupHall358,
     SKSpaceGroupSetting.spaceGroupHall359,
     SKSpaceGroupSetting.spaceGroupHall360,
     SKSpaceGroupSetting.spaceGroupHall361,
     SKSpaceGroupSetting.spaceGroupHall362,
     SKSpaceGroupSetting.spaceGroupHall363,
     SKSpaceGroupSetting.spaceGroupHall364,
     SKSpaceGroupSetting.spaceGroupHall365,
     SKSpaceGroupSetting.spaceGroupHall366,
     SKSpaceGroupSetting.spaceGroupHall367,
     SKSpaceGroupSetting.spaceGroupHall368,
     SKSpaceGroupSetting.spaceGroupHall369,
     SKSpaceGroupSetting.spaceGroupHall370,
     SKSpaceGroupSetting.spaceGroupHall371,
     SKSpaceGroupSetting.spaceGroupHall372,
     SKSpaceGroupSetting.spaceGroupHall373,
     SKSpaceGroupSetting.spaceGroupHall374,
     SKSpaceGroupSetting.spaceGroupHall375,
     SKSpaceGroupSetting.spaceGroupHall376,
     SKSpaceGroupSetting.spaceGroupHall377,
     SKSpaceGroupSetting.spaceGroupHall378,
     SKSpaceGroupSetting.spaceGroupHall379,
     SKSpaceGroupSetting.spaceGroupHall380,
     SKSpaceGroupSetting.spaceGroupHall381,
     SKSpaceGroupSetting.spaceGroupHall382,
     SKSpaceGroupSetting.spaceGroupHall383,
     SKSpaceGroupSetting.spaceGroupHall384,
     SKSpaceGroupSetting.spaceGroupHall385,
     SKSpaceGroupSetting.spaceGroupHall386,
     SKSpaceGroupSetting.spaceGroupHall387,
     SKSpaceGroupSetting.spaceGroupHall388,
     SKSpaceGroupSetting.spaceGroupHall389,
     SKSpaceGroupSetting.spaceGroupHall390,
     SKSpaceGroupSetting.spaceGroupHall391,
     SKSpaceGroupSetting.spaceGroupHall392,
     SKSpaceGroupSetting.spaceGroupHall393,
     SKSpaceGroupSetting.spaceGroupHall394,
     SKSpaceGroupSetting.spaceGroupHall395,
     SKSpaceGroupSetting.spaceGroupHall396,
     SKSpaceGroupSetting.spaceGroupHall397,
     SKSpaceGroupSetting.spaceGroupHall398,
     SKSpaceGroupSetting.spaceGroupHall399,
     SKSpaceGroupSetting.spaceGroupHall400,
     SKSpaceGroupSetting.spaceGroupHall401,
     SKSpaceGroupSetting.spaceGroupHall402,
     SKSpaceGroupSetting.spaceGroupHall403,
     SKSpaceGroupSetting.spaceGroupHall404,
     SKSpaceGroupSetting.spaceGroupHall405,
     SKSpaceGroupSetting.spaceGroupHall406,
     SKSpaceGroupSetting.spaceGroupHall407,
     SKSpaceGroupSetting.spaceGroupHall408,
     SKSpaceGroupSetting.spaceGroupHall409,
     SKSpaceGroupSetting.spaceGroupHall410,
     SKSpaceGroupSetting.spaceGroupHall411,
     SKSpaceGroupSetting.spaceGroupHall412,
     SKSpaceGroupSetting.spaceGroupHall413,
     SKSpaceGroupSetting.spaceGroupHall414,
     SKSpaceGroupSetting.spaceGroupHall415,
     SKSpaceGroupSetting.spaceGroupHall416,
     SKSpaceGroupSetting.spaceGroupHall417,
     SKSpaceGroupSetting.spaceGroupHall418,
     SKSpaceGroupSetting.spaceGroupHall419,
     SKSpaceGroupSetting.spaceGroupHall420,
     SKSpaceGroupSetting.spaceGroupHall421,
     SKSpaceGroupSetting.spaceGroupHall422,
     SKSpaceGroupSetting.spaceGroupHall423,
     SKSpaceGroupSetting.spaceGroupHall424,
     SKSpaceGroupSetting.spaceGroupHall425,
     SKSpaceGroupSetting.spaceGroupHall426,
     SKSpaceGroupSetting.spaceGroupHall427,
     SKSpaceGroupSetting.spaceGroupHall428,
     SKSpaceGroupSetting.spaceGroupHall429,
     SKSpaceGroupSetting.spaceGroupHall430,
     SKSpaceGroupSetting.spaceGroupHall431,
     SKSpaceGroupSetting.spaceGroupHall432,
     SKSpaceGroupSetting.spaceGroupHall433,
     SKSpaceGroupSetting.spaceGroupHall434,
     SKSpaceGroupSetting.spaceGroupHall435,
     SKSpaceGroupSetting.spaceGroupHall436,
     SKSpaceGroupSetting.spaceGroupHall437,
     SKSpaceGroupSetting.spaceGroupHall438,
     SKSpaceGroupSetting.spaceGroupHall439,
     SKSpaceGroupSetting.spaceGroupHall440,
     SKSpaceGroupSetting.spaceGroupHall441,
     SKSpaceGroupSetting.spaceGroupHall442,
     SKSpaceGroupSetting.spaceGroupHall443,
     SKSpaceGroupSetting.spaceGroupHall444,
     SKSpaceGroupSetting.spaceGroupHall445,
     SKSpaceGroupSetting.spaceGroupHall446,
     SKSpaceGroupSetting.spaceGroupHall447,
     SKSpaceGroupSetting.spaceGroupHall448,
     SKSpaceGroupSetting.spaceGroupHall449,
     SKSpaceGroupSetting.spaceGroupHall450,
     SKSpaceGroupSetting.spaceGroupHall451,
     SKSpaceGroupSetting.spaceGroupHall452,
     SKSpaceGroupSetting.spaceGroupHall453,
     SKSpaceGroupSetting.spaceGroupHall454,
     SKSpaceGroupSetting.spaceGroupHall455,
     SKSpaceGroupSetting.spaceGroupHall456,
     SKSpaceGroupSetting.spaceGroupHall457,
     SKSpaceGroupSetting.spaceGroupHall458,
     SKSpaceGroupSetting.spaceGroupHall459,
     SKSpaceGroupSetting.spaceGroupHall460,
     SKSpaceGroupSetting.spaceGroupHall461,
     SKSpaceGroupSetting.spaceGroupHall462,
     SKSpaceGroupSetting.spaceGroupHall463,
     SKSpaceGroupSetting.spaceGroupHall464,
     SKSpaceGroupSetting.spaceGroupHall465,
     SKSpaceGroupSetting.spaceGroupHall466,
     SKSpaceGroupSetting.spaceGroupHall467,
     SKSpaceGroupSetting.spaceGroupHall468,
     SKSpaceGroupSetting.spaceGroupHall469,
     SKSpaceGroupSetting.spaceGroupHall470,
     SKSpaceGroupSetting.spaceGroupHall471,
     SKSpaceGroupSetting.spaceGroupHall472,
     SKSpaceGroupSetting.spaceGroupHall473,
     SKSpaceGroupSetting.spaceGroupHall474,
     SKSpaceGroupSetting.spaceGroupHall475,
     SKSpaceGroupSetting.spaceGroupHall476,
     SKSpaceGroupSetting.spaceGroupHall477,
     SKSpaceGroupSetting.spaceGroupHall478,
     SKSpaceGroupSetting.spaceGroupHall479,
     SKSpaceGroupSetting.spaceGroupHall480,
     SKSpaceGroupSetting.spaceGroupHall481,
     SKSpaceGroupSetting.spaceGroupHall482,
     SKSpaceGroupSetting.spaceGroupHall483,
     SKSpaceGroupSetting.spaceGroupHall484,
     SKSpaceGroupSetting.spaceGroupHall485,
     SKSpaceGroupSetting.spaceGroupHall486,
     SKSpaceGroupSetting.spaceGroupHall487,
     SKSpaceGroupSetting.spaceGroupHall488,
     SKSpaceGroupSetting.spaceGroupHall489,
     SKSpaceGroupSetting.spaceGroupHall490,
     SKSpaceGroupSetting.spaceGroupHall491,
     SKSpaceGroupSetting.spaceGroupHall492,
     SKSpaceGroupSetting.spaceGroupHall493,
     SKSpaceGroupSetting.spaceGroupHall494,
     SKSpaceGroupSetting.spaceGroupHall495,
     SKSpaceGroupSetting.spaceGroupHall496,
     SKSpaceGroupSetting.spaceGroupHall497,
     SKSpaceGroupSetting.spaceGroupHall498,
     SKSpaceGroupSetting.spaceGroupHall499,
     SKSpaceGroupSetting.spaceGroupHall500,
     SKSpaceGroupSetting.spaceGroupHall501,
     SKSpaceGroupSetting.spaceGroupHall502,
     SKSpaceGroupSetting.spaceGroupHall503,
     SKSpaceGroupSetting.spaceGroupHall504,
     SKSpaceGroupSetting.spaceGroupHall505,
     SKSpaceGroupSetting.spaceGroupHall506,
     SKSpaceGroupSetting.spaceGroupHall507,
     SKSpaceGroupSetting.spaceGroupHall508,
     SKSpaceGroupSetting.spaceGroupHall509,
     SKSpaceGroupSetting.spaceGroupHall510,
     SKSpaceGroupSetting.spaceGroupHall511,
     SKSpaceGroupSetting.spaceGroupHall512,
     SKSpaceGroupSetting.spaceGroupHall513,
     SKSpaceGroupSetting.spaceGroupHall514,
     SKSpaceGroupSetting.spaceGroupHall515,
     SKSpaceGroupSetting.spaceGroupHall516,
     SKSpaceGroupSetting.spaceGroupHall517,
     SKSpaceGroupSetting.spaceGroupHall518,
     SKSpaceGroupSetting.spaceGroupHall519,
     SKSpaceGroupSetting.spaceGroupHall520,
     SKSpaceGroupSetting.spaceGroupHall521,
     SKSpaceGroupSetting.spaceGroupHall522,
     SKSpaceGroupSetting.spaceGroupHall523,
     SKSpaceGroupSetting.spaceGroupHall524,
     SKSpaceGroupSetting.spaceGroupHall525,
     SKSpaceGroupSetting.spaceGroupHall526,
     SKSpaceGroupSetting.spaceGroupHall527,
     SKSpaceGroupSetting.spaceGroupHall528,
     SKSpaceGroupSetting.spaceGroupHall529,
     SKSpaceGroupSetting.spaceGroupHall530
  ]
  
  public static func BaseHallSymbolForSpaceGroupNumber(_ number: Int) -> Int
  {
    return SKSpacegroup.spaceGroupData.filter{$0.spaceGroupNumber == number}.first?.number ?? 0
  }
  
  public static func HallSymbolForConventionalSpaceGroupNumber(_ number: Int) -> Int
  {
    return spaceGroupHallData[number]?.first ?? 0
  }
  
  public static func SpaceGroupNumberForHallNumber(_ number: Int) -> Int
  {
    return SKSpacegroup.spaceGroupData[number].spaceGroupNumber
  }
  
  
  
  public static func SpaceGroupQualifierForHallNumber(_ HallNumber: Int) -> Int
  {
    let spaceGroupNumber: Int = SKSpacegroup.spaceGroupData[HallNumber].spaceGroupNumber
    return HallNumber - (SKSpacegroup.spaceGroupData.filter{$0.spaceGroupNumber == spaceGroupNumber}.first?.number ?? 0)
  }
  
  public static func SchoenfliesString(HallNumber: Int) -> String
  {
    return spaceGroupData[HallNumber].schoenflies
  }
  
  public static func PointGroupString(HallNumber: Int) -> String
  {
    return spaceGroupData[HallNumber].pointGroup.symbol
  }
  
  public static func CentrosymmetricString(HallNumber: Int) -> String
  {
    return spaceGroupData[HallNumber].pointGroup.centrosymmetric ? "yes" : "no"
  }
  
  public static func EnantionmorphicString(HallNumber: Int) -> String
  {
    return spaceGroupData[HallNumber].pointGroup.enantiomorphic ? "yes" : "no"
  }
  
  public static func SymmorphicityString(HallNumber: Int) -> String
  {
    switch(spaceGroupData[HallNumber].symmorphicity)
    {
    case .asymmorphic:
      return "asymmorphic"
    case .symmorphic:
      return "symmorphic"
    case .hemisymmorphic:
      return "hemisymmorphic"
    }
  }
  
  public static func hasInversion(HallNumber: Int) -> Bool
  {
    return spaceGroupData[HallNumber].pointGroup.centrosymmetric
  }
  
  public static func hasInversionString(HallNumber: Int) -> String
  {
    return spaceGroupData[HallNumber].pointGroup.centrosymmetric ? "yes" : "no"
  }
  
  public static func InversionCenterString(HallNumber: Int) -> String
  {
    let vector: SIMD3<Int32> = spaceGroupData[HallNumber].inversionCenter
    let gcdx: Int32 = Int32.greatestCommonDivisor(a: vector.x,b: 12)
    let gcdy: Int32 = Int32.greatestCommonDivisor(a: vector.y,b: 12)
    let gcdz: Int32 = Int32.greatestCommonDivisor(a: vector.z,b: 12)
    let x: String = vector.x == 0 ? "0" : "\(vector.x/gcdx)/\(12/gcdx)"
    let y: String = vector.y == 0 ? "0" : "\(vector.y/gcdy)/\(12/gcdy)"
    let z: String = vector.z == 0 ? "0" : "\(vector.z/gcdz)/\(12/gcdz)"
    return  "(" + x + "," + y + "," + z + ")"
  }
  
  public static func NumberOfElementsString(HallNumber: Int) -> String
  {
    return String(describing: spaceGroupData[HallNumber].order)
  }
  
  public static func LaueGroupString(HallNumber: Int) -> String
  {
    switch(spaceGroupData[HallNumber].pointGroup.laue)
    {
    case .none:
      return "none"
    case .laue_1:
      return "1"
    case .laue_2m:
      return "2m"
    case .laue_mmm:
      return "mmm"
    case .laue_4m:
      return "4m"
    case .laue_4mmm:
      return "4mmm"
    case .laue_3:
      return "3"
    case .laue_3m:
      return "3m"
    case .laue_6m:
      return "6m"
    case .laue_6mmm:
      return "6mmm"
    case .laue_m3:
      return "m3"
    case .laue_m3m:
      return "m3m"
    }
  }
  
  public static func HolohedryString(HallNumber: Int) -> String
  {
    switch(spaceGroupData[HallNumber].pointGroup.holohedry)
    {
    case .none:
      return "none"
    case .triclinic:
      return "triclinic"
    case .monoclinic:
      return "monoclinic"
    case .orthorhombic:
      return "orthorhombic"
    case .tetragonal:
      return "tetragonal"
    case .trigonal:
      return "trigonal"
    case .hexagonal:
      return "hexagonal"
    case .cubic:
      return "cubic"
    }

  }

  public static func CentringString(HallNumber: Int) -> String
  {
    switch(spaceGroupData[HallNumber].centring)
    {
    case .none:
      return "none"
    case .primitive: // primitive (multiplicity: 1)
      return "primitive"
    case .body:      // body centred (multiplicity: 2)
      return "body"
    case .a_face:    // A-face centred (multiplicity: 2)
      return "a-face"
    case .b_face:    // B-face centred (multiplicity: 2)
      return "b-face"
    case .c_face:    // C-face centred (multiplicity: 2)
      return "c-face"
    case .face:      // All-face centred (multiplicity: 4)
      return "face"
    case .base:      // I,A,B,C
      return "base"
    case .r:         // Rhombohedrally centred (hexagonal axes, multiplicity: 3) or Primitive (rhombohedral axes, multiplicity: 1)
      return "R"
    case .h:         // Hexagonally centred (multiplicity: 3)
      return "H"
    case .d:        // Rhombohedrally centred (multiplicity: 3)
      return "D"
    }

  }
  
  
  public static func LatticeTranslationStrings(HallNumber: Int) -> [String]
  {
    var latticeTranslationStrings: [String] = ["","","",""]
    for i in 0..<spaceGroupData[HallNumber].latticeTranslations.count
    {
      let vector: SIMD3<Int32> = spaceGroupData[HallNumber].latticeTranslations[i]
      let gcdx: Int32 = Int32.greatestCommonDivisor(a: vector.x,b: 12)
      let gcdy: Int32 = Int32.greatestCommonDivisor(a: vector.y,b: 12)
      let gcdz: Int32 = Int32.greatestCommonDivisor(a: vector.z,b: 12)
      let x: String = vector.x == 0 ? "0" : "\(vector.x/gcdx)/\(12/gcdx)"
      let y: String = vector.y == 0 ? "0" : "\(vector.y/gcdy)/\(12/gcdy)"
      let z: String = vector.z == 0 ? "0" : "\(vector.z/gcdz)/\(12/gcdz)"
      latticeTranslationStrings[i] = "(" + x + "," + y + "," + z + ")"
    }
    return latticeTranslationStrings
  }
  
  
 
  static let spaceGroupHallData: [Int: [Int]] =
  [
    0: [0],
    1: [1],
    2: [2],
    3: [3, 4, 5],
    4: [6, 7, 8],
    5: [9, 10, 11, 12, 13, 14, 15, 16, 17],
    6: [18, 19, 20],
    7: [21, 22, 23, 24, 25, 26, 27, 28, 29],
    8: [30, 31, 32, 33, 34, 35, 36, 37, 38],
    9: [39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56],
    10: [57, 58, 59],
    11: [60, 61, 62],
    12: [63, 64, 65, 66, 67, 68, 69, 70, 71],
    13: [72, 73, 74, 75, 76, 77, 78, 79, 80],
    14: [81, 82, 83, 84, 85, 86, 87, 88, 89],
    15: [90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107],
    16: [108],
    17: [109, 110, 111],
    18: [112, 113, 114],
    19: [115],
    20: [116, 117, 118],
    21: [119, 120, 121],
    22: [122],
    23: [123],
    24: [124],
    25: [125, 126, 127],
    26: [128, 129, 130, 131, 132, 133],
    27: [134, 135, 136],
    28: [137, 138, 139, 140, 141, 142],
    29: [143, 144, 145, 146, 147, 148],
    30: [149, 150, 151, 152, 153, 154],
    31: [155, 156, 157, 158, 159, 160],
    32: [161, 162, 163],
    33: [164, 165, 166, 167, 168, 169],
    34: [170, 171, 172],
    35: [173, 174, 175],
    36: [176, 177, 178, 179, 180, 181],
    37: [182, 183, 184],
    38: [185, 186, 187, 188, 189, 190],
    39: [191, 192, 193, 194, 195, 196],
    40: [197, 198, 199, 200, 201, 202],
    41: [203, 204, 205, 206, 207, 208],
    42: [209, 210, 211],
    43: [212, 213, 214],
    44: [215, 216, 217],
    45: [218, 219, 220],
    46: [221, 222, 223, 224, 225, 226],
    47: [227],
    48: [229, 228], // second origin as default
    49: [230, 231, 232],
    50: [234, 233, 236, 235, 238, 237], // second origin as default
    51: [239, 240, 241, 242, 243, 244],
    52: [245, 246, 247, 248, 249, 250],
    53: [251, 252, 253, 254, 255, 256],
    54: [257, 258, 259, 260, 261, 262],
    55: [263, 264, 265],
    56: [266, 267, 268],
    57: [269, 270, 271, 272, 273, 274],
    58: [275, 276, 277],
    59: [279, 278, 281, 280, 283, 282], // second origin as default
    60: [284, 285, 286, 287, 288, 289],
    61: [290, 291],
    62: [292, 293, 294, 295, 296, 297],
    63: [298, 299, 300, 301, 302, 303],
    64: [304, 305, 306, 307, 308, 309],
    65: [310, 311, 312],
    66: [313, 314, 315],
    67: [316, 317, 318, 319, 320, 321],
    68: [323, 322, 325, 324, 327, 326, 329, 328, 331, 330, 333, 332], // second origin as default
    69: [334],
    70: [336, 335], // second origin as default
    71: [337],
    72: [338, 339, 340],
    73: [341, 342],
    74: [343, 344, 345, 346, 347, 348],
    75: [349],
    76: [350],
    77: [351],
    78: [352],
    79: [353],
    80: [354],
    81: [355],
    82: [356],
    83: [357],
    84: [358],
    85: [360, 359], // second origin as default
    86: [362, 361], // second origin as default
    87: [363],
    88: [365, 364], // second origin as default
    89: [366],
    90: [367],
    91: [368],
    92: [369],
    93: [370],
    94: [371],
    95: [372],
    96: [373],
    97: [374],
    98: [375],
    99: [376],
    100: [377],
    101: [378],
    102: [379],
    103: [380],
    104: [381],
    105: [382],
    106: [383],
    107: [384],
    108: [385],
    109: [386],
    110: [387],
    111: [388],
    112: [389],
    113: [390],
    114: [391],
    115: [392],
    116: [393],
    117: [394],
    118: [395],
    119: [396],
    120: [397],
    121: [398],
    122: [399],
    123: [400],
    124: [401],
    125: [403, 402], // second origin as default
    126: [405, 404], // second origin as default
    127: [406],
    128: [407],
    129: [409, 408], // second origin as default
    130: [411, 410], // second origin as default
    131: [412],
    132: [413],
    133: [415, 414], // second origin as default
    134: [417, 416], // second origin as default
    135: [418],
    136: [419],
    137: [421, 420], // second origin as default
    138: [423, 422], // second origin as default
    139: [424],
    140: [425],
    141: [427, 426], // second origin as default
    142: [429, 428], // second origin as default
    143: [430],
    144: [431],
    145: [432],
    146: [433, 434],
    147: [435],
    148: [436, 437],
    149: [438],
    150: [439],
    151: [440],
    152: [441],
    153: [442],
    154: [443],
    155: [444, 445],
    156: [446],
    157: [447],
    158: [448],
    159: [449],
    160: [450, 451],
    161: [452, 453],
    162: [454],
    163: [455],
    164: [456],
    165: [457],
    166: [458, 459],
    167: [460, 461],
    168: [462],
    169: [463],
    170: [464],
    171: [465],
    172: [466],
    173: [467],
    174: [468],
    175: [469],
    176: [470],
    177: [471],
    178: [472],
    179: [473],
    180: [474],
    181: [475],
    182: [476],
    183: [477],
    184: [478],
    185: [479],
    186: [480],
    187: [481],
    188: [482],
    189: [483],
    190: [484],
    191: [485],
    192: [486],
    193: [487],
    194: [488],
    195: [489],
    196: [490],
    197: [491],
    198: [492],
    199: [493],
    200: [494],
    201: [496, 495], // second origin as default
    202: [497],
    203: [499, 498], // second origin as default
    204: [500],
    205: [501],
    206: [502],
    207: [503],
    208: [504],
    209: [505],
    210: [506],
    211: [507],
    212: [508],
    213: [509],
    214: [510],
    215: [511],
    216: [512],
    217: [513],
    218: [514],
    219: [515],
    220: [516],
    221: [517],
    222: [519, 518], // second origin as default
    223: [520],
    224: [522, 521], // second origin as default
    225: [523],
    226: [524],
    227: [526, 525],  // second origin as default
    228: [527, 528],
    229: [529],
    230: [530]
  ]

/*
  public static func asymmetricUnitCellStringFull(number: Int) -> String
  {
    switch(number)
    {
    case   1: return "0<=x<1; 0<=y<1; 0<=z<1"
    case   2: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case   3: return "0<=x<=1/2; 0<=y<1; 0<=z<1"
    case   4: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case   5: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case   6: return "0<=x<1; 0<=y<1/2; 0<=z<1"
    case   7: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case   8: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case   9: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  10: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  11: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  12: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  13: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case  14: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  15: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case  16: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  17: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  18: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case  19: return "0<=x<1; 0<=y<1; 0<=z<=1/2"
    case  20: return "0<=x<=1/2; 0<=y<1; 0<=z<1"
    case  21: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case  22: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case  23: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case  24: return "0<=x<1/2; 0<=y<1; 0<=z<1"
    case  25: return "0<=x<1; 0<=y<1/2; 0<=z<1"
    case  26: return "0<=x<1; 0<=y<1/2; 0<=z<1"
    case  27: return "0<=x<1; 0<=y<1/2; 0<=z<1"
    case  28: return "0<=x<1; 0<=y<1/2; 0<=z<1"
    case  29: return "0<=x<=1/2; 0<=y<1; 0<=z<1"
    case  30: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  31: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  32: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  33: return "0<=x<1; 0<=y<1/2; 0<=z<=1/2"
    case  34: return "0<=x<1/2; 0<=y<1; 0<=z<=1/2"
    case  35: return "0<=x<1; 0<=y<1/2; 0<=z<=1/2"
    case  36: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  37: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  38: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  39: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  40: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  41: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  42: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  43: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  44: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  45: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  46: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  47: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  48: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  49: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  50: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  51: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  52: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  53: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  54: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case  55: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  56: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  57: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case  58: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/2"
    case  59: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case  60: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  61: return "0<=x<1; 0<=y<=1/2; 1/4<=z<=3/4"
    case  62: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  63: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  64: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  65: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  66: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case  67: return "0<=x<1/2; 0<=y<=1/2; 0<=z<=1/2"
    case  68: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case  69: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case  70: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  71: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  72: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case  73: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  74: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  75: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case  76: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  77: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  78: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  79: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  80: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case  81: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  82: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  83: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  84: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case  85: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  86: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  87: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  88: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  89: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  90: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  91: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case  92: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case  93: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case  94: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case  95: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  96: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case  97: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case  98: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case  99: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 100: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 101: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 102: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 103: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 104: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 105: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 106: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 107: return "1/4<=x<=3/4; 0<=y<=1/4; 0<=z<1"
    case 108: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 109: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 110: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 111: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 112: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 113: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 114: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 115: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 116: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 117: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 118: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 119: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 120: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 121: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 122: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 123: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 124: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 125: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 126: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/2"
    case 127: return "0<=x<=1/2; 0<=y<1; 0<=z<=1/2"
    case 128: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 129: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 130: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case 131: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/2"
    case 132: return "0<=x<1; 0<=y<1/2; 0<=z<=1/2"
    case 133: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 134: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 135: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case 136: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 137: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case 138: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 139: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 140: return "0<=x<1; 0<=y<=1/2; 1/4<=z<=3/4"
    case 141: return "0<=x<=1/2; 0<=y<1; 1/4<=z<=3/4"
    case 142: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case 143: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case 144: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 145: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 146: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case 147: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 148: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case 149: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 150: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case 151: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case 152: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 153: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 154: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 155: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 156: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 157: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 158: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/2"
    case 159: return "0<=x<1; 0<=y<1/2; 0<=z<=1/2"
    case 160: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 161: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 162: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 163: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case 164: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 165: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 166: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 167: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 168: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case 169: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case 170: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 171: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case 172: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 173: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 174: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 175: return "0<=x<=1/4; 0<=y<1; 0<=z<=1/2"
    case 176: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 177: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 178: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 179: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 180: return "0<=x<1/2; 0<=y<1/2; 0<=z<=1/2"
    case 181: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 182: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 183: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 184: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 185: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 186: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 187: return "0<=x<1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 188: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 189: return "0<=x<=1/2; 0<=y<1/2; 0<=z<=1/2"
    case 190: return "0<=x<=1/2; 0<=y<1/2; 0<=z<=1/2"
    case 191: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 192: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 193: return "0<=x<1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 194: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 195: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 196: return "0<=x<=1/2; 0<=y<1/2; 1/4<=z<=3/4"
    case 197: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 198: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 199: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 200: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 201: return "0<=x<=1/2; 0<=y<1/2; 1/4<=z<=3/4"
    case 202: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 203: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 204: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 205: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 206: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 207: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 208: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 209: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 210: return "0<=x<1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 211: return "0<=x<=1/4; 0<=y<1/2; 0<=z<=1/2"
    case 212: return "0<=x<1/2; 0<=y<=1/8; 0<=z<1"
    case 213: return "0<=x<1/2; 0<=y<=1/8; 0<=z<1"
    case 214: return "0<=x<=1/4; 0<=y<1/4; 0<=z<1"
    case 215: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 216: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 217: return "0<=x<=1/2; 0<=y<1/2; 0<=z<=1/2"
    case 218: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 219: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 220: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 221: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 222: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 223: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 224: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 225: return "0<=x<=1/2; 0<=y<1/2; 1/4<=z<=3/4"
    case 226: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 227: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 228: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 229: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 230: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 231: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 232: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 233: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 234: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 235: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 236: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 237: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 238: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 239: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 240: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 241: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 242: return "0<=x<=1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 243: return "0<=x<=1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 244: return "0<=x<=1/4; 0<=y<1; 0<=z<=1/2"
    case 245: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 246: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 247: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 248: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 249: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 250: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 251: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 252: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 253: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 254: return "0<=x<=1/4; 0<=y<1; 0<=z<=1/2"
    case 255: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 256: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 257: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 258: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 259: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 260: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 261: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 262: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 263: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 264: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 265: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 266: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 267: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 268: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 269: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 270: return "0<=x<=1/4; 0<=y<1; 1/4<=z<=3/4"
    case 271: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case 272: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 273: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 274: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 275: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 276: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 277: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 278: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 279: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 280: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 281: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 282: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 283: return "0<=x<=1/4; 0<=y<1; 1/4<=z<=3/4"
    case 284: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 285: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 286: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 287: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 288: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 289: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 290: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 291: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 292: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 293: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case 294: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 295: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 296: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 297: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 298: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 299: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 300: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 301: return "0<=x<=1/4; 0<=y<1/2; 0<=z<=1/2"
    case 302: return "0<=x<1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 303: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 304: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 305: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 306: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 307: return "0<=x<=1/4; 0<=y<1/2; 0<=z<=1/2"
    case 308: return "0<=x<1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 309: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 310: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 311: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 312: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<=1/2"
    case 313: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 314: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 315: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 316: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 317: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 318: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 319: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 320: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<=1/2"
    case 321: return "0<=x<=1/4; 0<=y<=1/2; 1/4<=z<=3/4"
    case 322: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 323: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 324: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 325: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 326: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 327: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 328: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 329: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 330: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 331: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 332: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 333: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 334: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 335: return "0<=x<=1/4; 0<=y<=1/8; 0<=z<1"
    case 336: return "0<=x<=1/8; 1/8<=y<=3/8; 0<=z<1"
    case 337: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 338: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 339: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 340: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 341: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 342: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 343: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 344: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 345: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 346: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<=1/2"
    case 347: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<=1/2"
    case 348: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 349: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 350: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 351: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 352: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 353: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 354: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 355: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 356: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 357: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 358: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 359: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 360: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 361: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 362: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 363: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 364: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 365: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 366: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 367: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 368: return "0<=x<=1/2; 0<=y<=1/2; -1/8<=z<=3/8"
    case 369: return "0<=x<=1/2; 0<=y<1/2; 0<=z<=1/2"
    case 370: return "0<=x<=1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 371: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 372: return "0<=x<=1/2; 0<=y<=1/2; 1/8<=z<=5/8"
    case 373: return "0<=x<=1/2; 0<=y<1/2; 0<=z<=1/2"
    case 374: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/4"
    case 375: return "0<=x<=1/4; -1/4<=y<=1/4; 0<=z<=1/2"
    case 376: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 377: return "0<=x<3/4; 0<=y<=1/4; 0<=z<1"
    case 378: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 379: return "0<=x<3/4; 1/4<=y<=1/2; 0<=z<1"
    case 380: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1/2"
    case 381: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1/2"
    case 382: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1/2"
    case 383: return "0<=x<1; 0<=y<=1/4; 0<=z<1/2"
    case 384: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 385: return "0<=x<3/4; 0<=y<=1/4; 0<=z<1/2"
    case 386: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 387: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 388: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 389: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1/2"
    case 390: return "0<=x<3/4; 0<=y<=1/4; 0<=z<1"
    case 391: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 392: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 393: return "0<=x<=1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 394: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case 395: return "0<=x<=1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 396: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/4"
    case 397: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/4"
    case 398: return "0<=x<3/4; 1/4<=y<=1/2; 0<=z<=1/2"
    case 399: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 400: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 401: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/4"
    case 402: return "0<=x<3/4; 0<=y<=1/4; 0<=z<=1/2"
    case 403: return "0<=x<=1/4; 1/4<=y<1; 0<=z<=1/2"
    case 404: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 405: return "0<=x<=1/4; 1/4<=y<=3/4; 1/4<=z<=3/4"
    case 406: return "0<=x<3/4; 0<=y<=1/4; 0<=z<=1/2"
    case 407: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/4"
    case 408: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 409: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 410: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 411: return "0<=x<=1/4; 1/4<=y<=3/4; 1/4<=z<=3/4"
    case 412: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/4"
    case 413: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 414: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 415: return "0<=x<=1/4; 1/4<=y<=3/4; 1/4<=z<=3/4"
    case 416: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case 417: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case 418: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/4"
    case 419: return "0<=x<3/4; 1/4<=y<=1/2; 0<=z<=1/2"
    case 420: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 421: return "0<=x<=1/4; 1/4<=y<=3/4; 1/4<=z<=3/4"
    case 422: return "0<=x<3/4; 0<=y<=1/4; 1/4<=z<=3/4"
    case 423: return "0<x<=3/4; 0<=y<=1/4; 0<=z<=1/2"
    case 424: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 425: return "0<=x<3/4; 0<=y<=1/4; 0<=z<=1/4"
    case 426: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 427: return "0<=x<=1/4; 0<=y<=1/4; -1/8<=z<=3/8"
    case 428: return "0<=x<=1/4; 0<=y<=1/4; 1/4<=z<=3/4"
    case 429: return "0<=x<=1/4; 0<=y<=1/4; 1/8<=z<=5/8"
    case 430: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<1"
    case 431: return "0<=x<1; 0<=y<1; 0<=z<1/3"
    case 432: return "0<=x<1; 0<=y<1; 0<=z<1/3"
    case 433: return "0<=x<=1/3; 0<=y<=1/3; 0<=z<1"
    case 434: return "0<=x<1; 0<=y<1; 0<=z<1"
    case 435: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 436: return "0<=x<=1/3; -1/6<=y<=0; 0<=z<1"
    case 437: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 438: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<=1/2"
    case 439: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 440: return "0<=x<1; 0<=y<1; 0<=z<=1/6"
    case 441: return "0<=x<=1/2; 0<=y<1; 0<=z<=1/3"
    case 442: return "0<=x<1; 0<=y<1; 0<=z<=1/6"
    case 443: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/3"
    case 444: return "0<=x<=1/3; 0<=y<=1/3; 0<=z<=1/2"
    case 445: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 446: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<1"
    case 447: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 448: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<1/2"
    case 449: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 450: return "0<=x<=5/12; 0<=y<1/4; 0<=z<1"
    case 451: return "0<=x<1; 0<=y<1; 0<=z<1"
    case 452: return "0<=x<=1/3; 0<=y<1/3; 0<=z<1/2"
    case 453: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case 454: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/2"
    case 455: return "0<=x<=2/3; 0<=y<=1/3; 1/4<=z<=3/4"
    case 456: return "0<=x<=1/2; -1/3<=y<=0; 0<=z<1"
    case 457: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1/2"
    case 458: return "0<=x<=1/3; 0<=y<=1/6; 0<=z<1"
    case 459: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 460: return "0<=x<=1/3; -1/6<=y<=0; 1/12<=z<=7/12"
    case 461: return "0<=x<=1/4; -1/4<=y<=1/4; 0<=z<3/4"
    case 462: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 463: return "0<=x<1; 0<=y<1; 0<=z<1/6"
    case 464: return "0<=x<1; 0<=y<1; 0<=z<1/6"
    case 465: return "0<=x<1; 0<=y<=1/2; 0<=z<1/3"
    case 466: return "0<=x<1; 0<=y<=1/2; 0<=z<1/3"
    case 467: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 468: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<=1/2"
    case 469: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/2"
    case 470: return "0<=x<=2/3; 0<=y<=1/3; 1/4<=z<=3/4"
    case 471: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/2"
    case 472: return "0<=x<1; 0<=y<=1/2; -1/12<=z<=1/12"
    case 473: return "0<=x<=1/2; 0<=y<1; 1/12<=z<=1/4"
    case 474: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/6"
    case 475: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/6"
    case 476: return "0<=x<=2/3; 0<=y<=1/3; 1/4<=z<=3/4"
    case 477: return "0<=x<=1/2; -1/3<=y<=0; 0<=z<1"
    case 478: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1/2"
    case 479: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1/2"
    case 480: return "0<=x<=1/2; -1/3<=y<=0; 0<=z<1"
    case 481: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<=1/2"
    case 482: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<=1/4"
    case 483: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/2"
    case 484: return "0<=x<=2/3; 0<=y<=1/3; 1/4<=z<=3/4"
    case 485: return "0<=x<=1/2; -1/3<=y<=0; 0<=z<=1/2"
    case 486: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/4"
    case 487: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/4"
    case 488: return "0<=x<=1/2; -1/3<=y<=0; 1/4<=z<=3/4"
    case 489: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 490: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 491: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 492: return "-1/4<=x<1/4; 0<=y<1/2; 0<=z<=3/4"
    case 493: return "0<=x<=1/4; 0<=y<1/2; 0<z<3/4"
    case 494: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 495: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 496: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 497: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 498: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1"
    case 499: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1"
    case 500: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 501: return "0<=x<=1/2; 0<=y<=1/4; -1/4<=z<1/4"
    case 502: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1/2"
    case 503: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 504: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 505: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 506: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1"
    case 507: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 508: return "1/8<=x<=3/8; 1/8<=y<=3/8; 0<=z<1"
    case 509: return "1/8<=x<=3/8; 1/8<=y<=3/8; 0<=z<1"
    case 510: return "-1/8<=x<=1/8; 0<=y<=1/8; 0<z<7/8"
    case 511: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case 512: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 513: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 514: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 515: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1/2"
    case 516: return "-1/8<=x<=1/8; 0<=y<=1/8; 0<z<7/8"
    case 517: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 518: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 519: return "0<=x<=1/4; 0<=y<=1/4; 1/4<=z<=3/4"
    case 520: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 521: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 522: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 523: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 524: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/4"
    case 525: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1"
    case 526: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1"
    case 527: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1/2"
    case 528: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1/2"
    case 529: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 530: return "0<=x<=1/8; -1/8<=y<=0; 1/8<z<7/8"
    default:
      return "unknown"
    }
  }
*/
  
  // tested and compared to full list
  public static func asymmetricUnitCellString(number: Int) -> String
  {
    switch(number)
    {
    case  1, 434, 451: return "0<=x<1; 0<=y<1; 0<=z<1"
    case  2, 4, 5, 7, 8, 18, 21, 22, 23: return "0<=x<1; 0<=y<=1/2; 0<=z<1"
    case  3, 20, 29: return "0<=x<=1/2; 0<=y<1; 0<=z<1"
    case  6, 25, 26, 27, 28: return "0<=x<1; 0<=y<1/2; 0<=z<1"
    case  9, 10, 11, 37, 38, 53, 54, 133, 136, 147, 153, 154, 160, 172: return "0<=x<=1/2; 0<=y<1/2; 0<=z<1"
    case 12, 14, 16, 17, 30, 31, 32, 39, 40, 41, 42, 43, 44, 60, 76, 77, 78, 79, 81, 82, 83, 85, 86, 87, 88, 111, 112, 113, 115, 138, 139, 144, 145, 149, 152, 156, 157, 161, 162, 164, 165, 166, 167, 170, 171: return "0<=x<1; 0<=y<=1/4; 0<=z<1"
    case  13, 15, 75, 84, 130, 135, 146, 151: return "0<=x<1/2; 0<=y<=1/2; 0<=z<1"
    case  19: return "0<=x<1; 0<=y<1; 0<=z<=1/2"
    case  24: return "0<=x<1/2; 0<=y<1; 0<=z<1"
    case  33, 35, 132, 159: return "0<=x<1; 0<=y<1/2; 0<=z<=1/2"
    case  34: return "0<=x<1/2; 0<=y<1; 0<=z<=1/2"
    case  36, 52, 56, 62, 73, 74, 89, 137, 142, 143, 150, 163, 168: return "0<=x<=1/4; 0<=y<1; 0<=z<1"
    case  45, 46, 47, 48, 49, 50, 51, 55, 148, 169, 453: return "0<=x<1/2; 0<=y<1/2; 0<=z<1"
    case  57, 59, 72, 80, 108, 109, 110, 114, 125, 128, 129, 134, 155, 349, 350, 351, 352, 355, 376, 378, 388, 437, 445, 459, 489, 511: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1"
    case  58, 126, 131, 158: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/2"
    case  61, 140: return "0<=x<1; 0<=y<=1/2; 1/4<=z<=3/4"
    case  63, 64, 65, 70, 71, 90, 95, 104, 105, 116, 117, 119, 120, 123, 173, 176, 177, 182, 185, 191, 215, 218, 228, 232, 233, 235, 236, 240, 248, 249, 252, 253, 256, 258, 261, 264, 274, 276, 277, 278, 284, 285, 353, 356, 359, 361, 384, 408, 416: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<1"
    case  66, 68, 174, 179, 188, 216, 241, 255, 263, 275, 280, 371, 391, 394: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/2"
    case  67, 187: return "0<=x<1/2; 0<=y<=1/2; 0<=z<=1/2"
    case  69, 121, 124, 186, 192, 231, 237, 238, 239, 251, 257, 260, 265, 271: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<1"
    case  91, 93, 181, 184, 195, 197, 202, 203, 207, 208, 220, 226, 246, 262, 268, 272, 287, 289, 291, 293: return "0<=x<=1/4; 0<=y<1/2; 0<=z<1"
    case  92, 94, 103, 221, 222, 229, 234, 247, 250, 266, 279, 295, 296, 354, 360, 362, 409, 417: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<1"
    case  96, 97, 98, 99, 100, 101, 102, 106, 118, 178, 183, 194, 198, 199, 204, 205, 206, 219, 223, 245, 259, 267, 273, 286, 288, 290, 292: return "0<=x<1/2; 0<=y<=1/4; 0<=z<1"
    case 107: return "1/4<=x<=3/4; 0<=y<=1/4; 0<=z<1"
    case 122, 209, 300, 303, 304, 305, 306, 309, 314, 315, 316, 317, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 339, 340, 341, 342, 343, 344, 364, 365, 386, 387, 399, 490, 491, 495, 496, 504, 512, 513, 514, 521, 522: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1"
    case 127: return "0<=x<=1/2; 0<=y<1; 0<=z<=1/2"
    case 141: return "0<=x<=1/2; 0<=y<1; 1/4<=z<=3/4"
    case 175, 244, 254: return "0<=x<=1/4; 0<=y<1; 0<=z<=1/2"
    case 180: return "0<=x<1/2; 0<=y<1/2; 0<=z<=1/2"
    case 189, 190, 217, 369, 373: return "0<=x<=1/2; 0<=y<1/2; 0<=z<=1/2"
    case 193: return "0<=x<1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 196, 201, 225: return "0<=x<=1/2; 0<=y<1/2; 1/4<=z<=3/4"
    case 200, 224, 269, 281, 294, 297: return "0<=x<1; 0<=y<=1/4; 1/4<=z<=3/4"
    case 210, 302, 308: return "0<=x<1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 211, 301, 307: return "0<=x<=1/4; 0<=y<1/2; 0<=z<=1/2"
    case 212, 213: return "0<=x<1/2; 0<=y<=1/8; 0<=z<1"
    case 214: return "0<=x<=1/4; 0<=y<1/4; 0<=z<1"
    case 227, 230, 282, 357, 358, 366, 367, 392, 400, 413, 494, 503, 517: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/2"
    case 242, 243, 370, 393, 395: return "0<=x<=1/2; 0<=y<=1/2; 1/4<=z<=3/4"
    case 270, 283: return "0<=x<=1/4; 0<=y<1; 1/4<=z<=3/4"
    case 298, 299, 318, 345, 348, 410: return "0<=x<=1/2; 0<=y<=1/4; 1/4<=z<=3/4"
    case 310, 311, 313, 319, 337, 338, 363, 404, 414, 420, 424: return "0<=x<=1/2; 0<=y<=1/4; 0<=z<=1/2"
    case 312, 320: return "0<=x<=1/4; 0<=y<=1/2; 0<=z<=1/2"
    case 321: return "0<=x<=1/4; 0<=y<=1/2; 1/4<=z<=3/4"
    case 334, 426, 497, 500, 505, 507, 518, 520, 523, 529: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/2"
    case 335: return "0<=x<=1/4; 0<=y<=1/8; 0<=z<1"
    case 336: return "0<=x<=1/8; 1/8<=y<=3/8; 0<=z<1"
    case 346, 347: return "0<=x<=1/4; 1/4<=y<=3/4; 0<=z<=1/2"
    case 368: return "0<=x<=1/2; 0<=y<=1/2; -1/8<=z<=3/8"
    case 372: return "0<=x<=1/2; 0<=y<=1/2; 1/8<=z<=5/8"
    case 374, 396, 401, 407, 412: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<=1/4"
    case 375: return "0<=x<=1/4; -1/4<=y<=1/4; 0<=z<=1/2"
    case 377, 390: return "0<=x<3/4; 0<=y<=1/4; 0<=z<1"
    case 379: return "0<=x<3/4; 1/4<=y<=1/2; 0<=z<1"
    case 380, 381, 382, 389: return "0<=x<=1/2; 0<=y<=1/2; 0<=z<1/2"
    case 383: return "0<=x<1; 0<=y<=1/4; 0<=z<1/2"
    case 385: return "0<=x<3/4; 0<=y<=1/4; 0<=z<1/2"
    case 397, 418: return "0<=x<1; 0<=y<=1/4; 0<=z<=1/4"
    case 398, 419: return "0<=x<3/4; 1/4<=y<=1/2; 0<=z<=1/2"
    case 402, 406: return "0<=x<3/4; 0<=y<=1/4; 0<=z<=1/2"
    case 403: return "0<=x<=1/4; 1/4<=y<1; 0<=z<=1/2"
    case 405, 411, 415, 421: return "0<=x<=1/4; 1/4<=y<=3/4; 1/4<=z<=3/4"
    case 422: return "0<=x<3/4; 0<=y<=1/4; 1/4<=z<=3/4"
    case 423: return "0<x<=3/4; 0<=y<=1/4; 0<=z<=1/2"
    case 425: return "0<=x<3/4; 0<=y<=1/4; 0<=z<=1/4"
    case 427: return "0<=x<=1/4; 0<=y<=1/4; -1/8<=z<=3/8"
    case 428, 519: return "0<=x<=1/4; 0<=y<=1/4; 1/4<=z<=3/4"
    case 429: return "0<=x<=1/4; 0<=y<=1/4; 1/8<=z<=5/8"
    case 430, 446: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<1"
    case 431, 432: return "0<=x<1; 0<=y<1; 0<=z<1/3"
    case 433: return "0<=x<=1/3; 0<=y<=1/3; 0<=z<1"
    case 435, 439, 447, 449, 462, 467: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1"
    case 436: return "0<=x<=1/3; -1/6<=y<=0; 0<=z<1"
    case 438, 468, 481: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<=1/2"
    case 440, 442: return "0<=x<1; 0<=y<1; 0<=z<=1/6"
    case 441: return "0<=x<=1/2; 0<=y<1; 0<=z<=1/3"
    case 443: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/3"
    case 444: return "0<=x<=1/3; 0<=y<=1/3; 0<=z<=1/2"
    case 448: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<1/2"
    case 450: return "0<=x<=5/12; 0<=y<1/4; 0<=z<1"
    case 452: return "0<=x<=1/3; 0<=y<1/3; 0<=z<1/2"
    case 454, 469, 471, 483: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/2"
    case 455, 470, 476, 484: return "0<=x<=2/3; 0<=y<=1/3; 1/4<=z<=3/4"
    case 456, 477, 480: return "0<=x<=1/2; -1/3<=y<=0; 0<=z<1"
    case 457, 478, 479: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<1/2"
    case 458: return "0<=x<=1/3; 0<=y<=1/6; 0<=z<1"
    case 460: return "0<=x<=1/3; -1/6<=y<=0; 1/12<=z<=7/12"
    case 461: return "0<=x<=1/4; -1/4<=y<=1/4; 0<=z<3/4"
    case 463, 464: return "0<=x<1; 0<=y<1; 0<=z<1/6"
    case 465, 466: return "0<=x<1; 0<=y<=1/2; 0<=z<1/3"
    case 472: return "0<=x<1; 0<=y<=1/2; -1/12<=z<=1/12"
    case 473: return "0<=x<=1/2; 0<=y<1; 1/12<=z<=1/4"
    case 474, 475: return "0<=x<1; 0<=y<=1/2; 0<=z<=1/6"
    case 482: return "0<=x<=2/3; 0<=y<=2/3; 0<=z<=1/4"
    case 485: return "0<=x<=1/2; -1/3<=y<=0; 0<=z<=1/2"
    case 486, 487: return "0<=x<=2/3; 0<=y<=1/3; 0<=z<=1/4"
    case 488: return "0<=x<=1/2; -1/3<=y<=0; 1/4<=z<=3/4"
    case 492: return "-1/4<=x<1/4; 0<=y<1/2; 0<=z<=3/4"
    case 493: return "0<=x<=1/4; 0<=y<1/2; 0<z<3/4"
    case 498, 499, 506, 525, 526: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1"
    case 501: return "0<=x<=1/2; 0<=y<=1/4; -1/4<=z<1/4"
    case 502, 515: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<1/2"
    case 508, 509: return "1/8<=x<=3/8; 1/8<=y<=3/8; 0<=z<1"
    case 510, 516: return "-1/8<=x<=1/8; 0<=y<=1/8; 0<z<7/8"
    case 524: return "0<=x<=1/4; 0<=y<=1/4; 0<=z<=1/4"
    case 527, 528: return "0<=x<=1/8; 0<=y<=1/8; 0<=z<1/2"
    case 530: return "0<=x<=1/8; -1/8<=y<=0; 1/8<z<7/8"
    default:
      return "unknown"
    }
  }
  
  
  
  
  
  public static func isInsideAsymmetricUnitBrick(number: Int, point: SIMD3<Double>) -> Bool
  {
    let p: SIMD3<Double> = fract(point)
    
    switch(number)
    {
    case  1, 434, 451: return (0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<1.0)
    case  2, 4, 5, 7, 8, 18, 21, 22, 23: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  3, 20, 29: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<1.0)
    case  6, 25, 26, 27, 28: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  9, 10, 11, 37, 38, 53, 54, 133, 136, 147, 153, 154, 160, 172: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case 12, 14, 16, 17, 30, 31, 32, 39, 40, 41, 42, 43, 44, 60, 76, 77, 78, 79, 81, 82, 83, 85, 86, 87, 88, 111, 112, 113, 115, 138, 139, 144, 145, 149, 152, 156, 157, 161, 162, 164, 165, 166, 167, 170, 171: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case  13, 15, 75, 84, 130, 135, 146, 151: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  19: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case  24: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<1.0)
    case  33, 35, 132, 159: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case  34: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case  36, 52, 56, 62, 73, 74, 89, 137, 142, 143, 150, 163, 168: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<1.0)
    case  45, 46, 47, 48, 49, 50, 51, 55, 148, 169, 453: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  57, 59, 72, 80, 108, 109, 110, 114, 125, 128, 129, 134, 155, 349, 350, 351, 352, 355, 376, 378, 388, 437, 445, 459, 489, 511: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  58, 126, 131, 158: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case  61, 140: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case  63, 64, 65, 70, 71, 90, 95, 104, 105, 116, 117, 119, 120, 123, 173, 176, 177, 182, 185, 191, 215, 218, 228, 232, 233, 235, 236, 240, 248, 249, 252, 253, 256, 258, 261, 264, 274, 276, 277, 278, 284, 285, 353, 356, 359, 361, 384, 408, 416: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case  66, 68, 174, 179, 188, 216, 241, 255, 263, 275, 280, 371, 391, 394: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case  67, 187: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case  69, 121, 124, 186, 192, 231, 237, 238, 239, 251, 257, 260, 265, 271: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  91, 93, 181, 184, 195, 197, 202, 203, 207, 208, 220, 226, 246, 262, 268, 272, 287, 289, 291, 293: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case  92, 94, 103, 221, 222, 229, 234, 247, 250, 266, 279, 295, 296, 354, 360, 362, 409, 417: return (0.0<=p.x) && (p.x<=1.0/4.0) && (1.0/4.0<=p.y) && (p.y<=3.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case  96, 97, 98, 99, 100, 101, 102, 106, 118, 178, 183, 194, 198, 199, 204, 205, 206, 219, 223, 245, 259, 267, 273, 286, 288, 290, 292: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case 107: return (1.0/4.0<=p.x) && (p.x<=3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case 122, 209, 300, 303, 304, 305, 306, 309, 314, 315, 316, 317, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 339, 340, 341, 342, 343, 344, 364, 365, 386, 387, 399, 490, 491, 495, 496, 504, 512, 513, 514, 521, 522: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case 127: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 141: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 175, 244, 254: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 180: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 189, 190, 217, 369, 373: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 193: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 196, 201, 225: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 200, 224, 269, 281, 294, 297: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 210, 302, 308: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 211, 301, 307: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 212, 213: return (0.0<=p.x) && (p.x<1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/8.0) && (0.0<=p.z) && (p.z<1.0)
    case 214: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case 227, 230, 282, 357, 358, 366, 367, 392, 400, 413, 494, 503, 517: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 242, 243, 370, 393, 395: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 270, 283: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 298, 299, 318, 345, 348, 410: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 310, 311, 313, 319, 337, 338, 363, 404, 414, 420, 424: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 312, 320: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 321: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 334, 426, 497, 500, 505, 507, 518, 520, 523, 529: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 335: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/8.0) && (0.0<=p.z) && (p.z<1.0)
    case 336: return (0.0<=p.x) && (p.x<=1.0/8.0) && (1.0/8.0<=p.y) && (p.y<=3.0/8.0) && (0.0<=p.z) && (p.z<1.0)
    case 346, 347: return (0.0<=p.x) && (p.x<=1.0/4.0) && (1.0/4.0<=p.y) && (p.y<=3.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 368: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (((0.0<=p.z) && (p.z<=3.0/8.0)) || ((7.0/8.0<=p.z) && (p.z<=1.0)))
    case 372: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (1.0/8.0<=p.z) && (p.z<=5.0/8.0)
    case 374, 396, 401, 407, 412: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/4.0)
    case 375: return (0.0<=p.x) && (p.x<=1.0/4.0) && (((0.0<=p.y) && (p.y<=1.0/4.0)) || ((3.0/4.0<=p.y) && (p.y<=1.0))) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 377, 390: return (0.0<=p.x) && (p.x<3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case 379: return (0.0<=p.x) && (p.x<3.0/4.0) && (1.0/4.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0)
    case 380, 381, 382, 389: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 383: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 385: return (0.0<=p.x) && (p.x<3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 397, 418: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/4.0)
    case 398, 419: return (0.0<=p.x) && (p.x<3.0/4.0) && (1.0/4.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 402, 406: return (0.0<=p.x) && (p.x<3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 403: return (0.0<=p.x) && (p.x<=1.0/4.0) && (1.0/4.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 405, 411, 415, 421: return (0.0<=p.x) && (p.x<=1.0/4.0) && (1.0/4.0<=p.y) && (p.y<=3.0/4.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 422: return (0.0<=p.x) && (p.x<3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 423: return (0.0<p.x) && (p.x<=3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 425: return (0.0<=p.x) && (p.x<3.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/4.0)
    case 427: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (((0.0<=p.z) && (p.z<=3.0/8.0)) || ((7.0/8.0<=p.z) && (p.z<=1.0)))
    case 428, 519: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 429: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (1.0/8.0<=p.z) && (p.z<=5.0/8.0)
    case 430, 446: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=2.0/3.0) && (0.0<=p.z) && (p.z<1.0)
    case 431, 432: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<1.0/3.0)
    case 433: return (0.0<=p.x) && (p.x<=1.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (0.0<=p.z) && (p.z<1.0)
    case 435, 439, 447, 449, 462, 467: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (0.0<=p.z) && (p.z<1.0)
    case 436: return (0.0<=p.x) && (p.x<=1.0/3.0) && (5.0/6.0<=p.y) && (p.y<=1.0) && (0.0<=p.z) && (p.z<1.0)
    case 438, 468, 481: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=2.0/3.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 440, 442: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/6.0)
    case 441: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<=1.0/3.0)
    case 443: return (0.0<=p.x) && (p.x<1.0) && (0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/3.0)
    case 444: return (0.0<=p.x) && (p.x<=1.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 448: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=2.0/3.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 450: return (0.0<=p.x) && (p.x<=5.0/12.0) && (0.0<=p.y) && (p.y<1.0/4.0) && (0.0<=p.z) && (p.z<1.0)
    case 452: return (0.0<=p.x) && (p.x<=1.0/3.0) && (0.0<=p.y) && (p.y<1.0/3.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 454, 469, 471, 483: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 455, 470, 476, 484: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 456, 477, 480: return (0.0<=p.x) && (p.x<=1.0/2.0) && (2.0/3.0<=p.y) && (p.y<=1.0) && (0.0<=p.z) && (p.z<1.0)
    case 457, 478, 479: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 458: return (0.0<=p.x) && (p.x<=1.0/3.0) && (0.0<=p.y) && (p.y<=1.0/6.0) && (0.0<=p.z) && (p.z<1.0)
    case 460: return (0.0<=p.x) && (p.x<=1.0/3.0) && (5.0/6.0<=p.y) && (p.y<=1.0) && (1.0/12.0<=p.z) && (p.z<=7.0/12.0)
    case 461: return (0.0<=p.x) && (p.x<=1.0/4.0) && (((0.0<=p.y) && (p.y<=1.0/4.0)) || ((3.0/4.0<=p.y) && (p.y<=1.0))) && (0.0<=p.z) && (p.z<3.0/4.0)
    case 463, 464: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<1.0) && (0.0<=p.z) && (p.z<1.0/6.0)
    case 465, 466: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<1.0/3.0)
    case 472: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (((0.0<=p.z) && (p.z<=1.0/12.0)) || ((11.0/12.0<=p.z) && (p.z<=1.0)))
    case 473: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<1.0) && (1.0/12.0<=p.z) && (p.z<=1.0/4.0)
    case 474, 475: return (0.0<=p.x) && (p.x<1.0) && (0.0<=p.y) && (p.y<=1.0/2.0) && (0.0<=p.z) && (p.z<=1.0/6.0)
    case 482: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=2.0/3.0) && (0.0<=p.z) && (p.z<=1.0/4.0)
    case 485: return (0.0<=p.x) && (p.x<=1.0/2.0) && (2.0/3.0<=p.y) && (p.y<=1.0) && (0.0<=p.z) && (p.z<=1.0/2.0)
    case 486, 487: return (0.0<=p.x) && (p.x<=2.0/3.0) && (0.0<=p.y) && (p.y<=1.0/3.0) && (0.0<=p.z) && (p.z<=1.0/4.0)
    case 488: return (0.0<=p.x) && (p.x<=1.0/2.0) && (2.0/3.0<=p.y) && (p.y<=1.0) && (1.0/4.0<=p.z) && (p.z<=3.0/4.0)
    case 492: return (((0.0<=p.x) && (p.x<1.0/4.0)) || ((3.0/4.0<=p.x) && (p.x<1.0))) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<=p.z) && (p.z<=3.0/4.0)
    case 493: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<1.0/2.0) && (0.0<p.z) && (p.z<3.0/4.0)
    case 498, 499, 506, 525, 526: return (0.0<=p.x) && (p.x<=1.0/8.0) && (0.0<=p.y) && (p.y<=1.0/8.0) && (0.0<=p.z) && (p.z<1.0)
    case 501: return (0.0<=p.x) && (p.x<=1.0/2.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (((0.0<=p.z) && (p.z<1.0/4.0)) || ((3.0/4.0<=p.z) && (p.z<1.0)))
    case 502, 515: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 508, 509: return (1.0/8.0<=p.x) && (p.x<=3.0/8.0) && (1.0/8.0<=p.y) && (p.y<=3.0/8.0) && (0.0<=p.z) && (p.z<1.0)
    case 510, 516: return (((0.0<=p.x) && (p.x<=1.0/8.0)) || ((7.0/8.0<=p.x) && (p.x<=1.0))) && (0.0<=p.y) && (p.y<=1.0/8.0) && (0.0<p.z) && (p.z<7.0/8.0)
    case 524: return (0.0<=p.x) && (p.x<=1.0/4.0) && (0.0<=p.y) && (p.y<=1.0/4.0) && (0.0<=p.z) && (p.z<=1.0/4.0)
    case 527, 528: return (0.0<=p.x) && (p.x<=1.0/8.0) && (0.0<=p.y) && (p.y<=1.0/8.0) && (0.0<=p.z) && (p.z<1.0/2.0)
    case 530: return (0.0<=p.x) && (p.x<=1.0/8.0) && (7.0/8.0<=p.y) && (p.y<=1.0) && (1.0/8.0<p.z) && (p.z<7.0/8.0)
    default:
      return false
    }
  }
  
  
  
 
  
  
  
  
  
 
}













