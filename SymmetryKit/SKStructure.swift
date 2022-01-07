/*******************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

public class SKStructure
{
  public enum Kind: Int
  {
    case unknown = 0
    case structure = 1
    case crystal = 2
    case molecularCrystal = 3
    case molecule = 4
    case protein = 5
    case proteinCrystal = 6
    
    case proteinCrystalSolvent = 7
    case crystalSolvent = 8
    case molecularCrystalSolvent = 9
    
    case crystalEllipsoidPrimitive = 10
    case crystalCylinderPrimitive = 11
    case crystalPolygonalPrismPrimitive = 12
    
    case ellipsoidPrimitive = 13
    case cylinderPrimitive = 14
    case polygonalPrismPrimitive = 15
    
    case gridVolume = 16
    case RASPADensityVolume = 17
    case VTKDensityVolume = 18
    case VASPDensityVolume = 19
    case GaussianCubeVolume = 20
  }
  
  public enum VASPType: Int
  {
    case CHGCAR = 0
    case LOCPOT = 1
    case ELFCAR = 2
  }
  
  public var kind: Kind = .crystal
  public var atoms: [SKAsymmetricAtom] = []
  public var unknownAtoms: Set<String> = []
  
  public var displayName: String?
  
  public var cell: SKCell?
  public var spaceGroupHallNumber: Int?
  public var drawUnitCell: Bool? = true
  public var periodic: Bool? = true
  
  public var gridData: Data = Data()
  public var dimensions: SIMD3<Int32> = SIMD3<Int32>()
  public var spacing: SIMD3<Double> = SIMD3<Double>()
  public var range: (Double,Double) = (0.0,0.0)
  public var average: Double = 0.0
  public var variance: Double = 0.0
  
  public var VASPType: VASPType = .CHGCAR
  
  public enum DataType: Int
  {
    case Uint8 = 0
    case Int8 = 1
    case Uint16 = 2
    case Int16 = 3
    case Uint32 = 4
    case Int32 = 5
    case Uint64 = 6
    case Int64 = 7
    case Float = 8
    case Double = 9
  }
  public var dataType: DataType = DataType.Double
  
  public var creationDate: String?
  public var creationMethod: String?
  public var chemicalFormulaSum: String?
  public var chemicalFormulaStructural: String?
  public var cellFormulaUnitsZ: Int?
  
  public var numberOfChannels: Int?
  public var numberOfPockets: Int?
  public var dimensionality: Int?
  public var Di: Double?
  public var Df: Double?
  public var Dif: Double?
  
  init()
  {
    
  }
}
