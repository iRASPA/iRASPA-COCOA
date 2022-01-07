/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import Cocoa
import RenderKit
import SymmetryKit
import BinaryCodable
import simd

public class Object: NSObject, RKRenderObject, BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  
  public enum ObjectType : Int
  {
    case none = -1
    case object = 0
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
    case volumetricData = 16
    case RASPAVolumetricData = 17
    case VTKVolumetricData = 18
    case VASPVolumetricData = 19
    case GaussianCubeVolumetricData = 20
  }
  
  public var allObjects: [Object]
  {
    return [self]
  }
  
  public var selectedRenderFrames: [RKRenderObject]
  {
    return [self]
  }
  
  public var allRenderFrames: [RKRenderObject]
  {
    return [self]
  }
  
  public var materialType: ObjectType
  {
    return .object
  }
  
  public init(copy object: Object)
  {
    super.init()
  }
  
  public init(clone object: Object)
  {
    super.init()
  }
  
  public required init(from object: Object)
  {
    super.init()
        
    self.displayName = object.displayName
    self.isVisible = object.isVisible
    
    self.cell = SKCell(cell: object.cell)
    self.periodic = object.periodic
    self.origin = object.origin
    self.scaling = object.scaling
    self.orientation = object.orientation
    self.rotationDelta = object.rotationDelta
    
    self.drawUnitCell = object.drawUnitCell
    self.unitCellScaleFactor = object.unitCellScaleFactor
    self.unitCellDiffuseColor = object.unitCellDiffuseColor
    self.unitCellDiffuseIntensity = object.unitCellDiffuseIntensity
    
    self.renderLocalAxis = RKLocalAxes(axes: object.renderLocalAxis)
    
    self.authorFirstName = object.authorFirstName
    self.authorMiddleName = object.authorMiddleName
    self.authorLastName = object.authorLastName
    self.authorOrchidID = object.authorOrchidID
    self.authorResearcherID = object.authorResearcherID
    self.authorAffiliationUniversityName = object.authorAffiliationUniversityName
    self.authorAffiliationFacultyName = object.authorAffiliationFacultyName
    self.authorAffiliationInstituteName = object.authorAffiliationInstituteName
    self.authorAffiliationCityName = object.authorAffiliationCityName
    self.authorAffiliationCountryName = object.authorAffiliationCountryName
    self.creationDate = object.creationDate
  }
  
  // MARK: protocol RKRenderStructure implementation
  // =====================================================================
  public var displayName: String = "uninitialized"
  public var isVisible: Bool = true
   
  public var origin: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
  public var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  
  public var periodic: Bool = true
  public var cell: SKCell = SKCell()
  
  public var scaling: SIMD3<Double> = SIMD3<Double>(x: 1.0, y: 1.0, z: 1.0)
  
  public var rotationDelta: Double = 5.0
  
  
  public func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>()
  }
  
  public func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>()
  }
  
  // MARK: -
  // MARK: cell property-wrapper
  
  public var boundingBox: SKBoundingBox
  {
    return SKBoundingBox()
  }
  
  public var transformedBoundingBox: SKBoundingBox
  {
    let currentBoundingBox: SKBoundingBox = self.cell.boundingBox
    
    let transformation = double4x4.init(transformation: double4x4(self.orientation), aroundPoint: currentBoundingBox.center)
    let transformedBoundingBox: SKBoundingBox = currentBoundingBox.adjustForTransformation(transformation)
    
    return transformedBoundingBox
  }
  
  public func reComputeBoundingBox()
  {
    let boundingBox: SKBoundingBox = self.boundingBox
    
    // store in the cell datastructure
    self.cell.boundingBox = boundingBox
  }
  
  public var unitCell: double3x3
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.unitCell
  }
  
  public var cellLengthA: Double?
  {
    get
    {
      debugPrint("reading \(displayName) \(cell.a)")
      return cell.a
    }
    set(newValue)
    {
      cell.a = newValue ?? 0.0
    }
  }
  
  public var cellLengthB: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.b
  }
  
  public var cellLengthC: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.c
  }
  
  public var cellAngleAlpha: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.alpha
  }
  
  public var cellAngleBeta: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.beta
  }
  
  public var cellAngleGamma: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.gamma
  }
  
  public var cellVolume: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.volume
  }
  
  public var cellPerpendicularWidthsX: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.perpendicularWidths.x
  }
  
  public var cellPerpendicularWidthsY: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.perpendicularWidths.y
  }
  
  public var cellPerpendicularWidthsZ: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.perpendicularWidths.z
  }
  
  // MARK: protocol RKRenderUnitCellSource implementation
  // =====================================================================
  
  public var drawUnitCell: Bool = false
  public var unitCellScaleFactor: Double = 1.0
  public var unitCellDiffuseColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var unitCellDiffuseIntensity: Double = 1.0
  
  public var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    return []
  }

  public var renderUnitCellCylinders:[RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  
  // MARK: protocol RKRenderStructure implementation
  // =====================================================================
  
  public var renderLocalAxis: RKLocalAxes = RKLocalAxes()
  
  
  // MARK: Basic Info implementation
  // =====================================================================
  public var authorFirstName: String = ""
  public var authorMiddleName: String = ""
  public var authorLastName: String = ""
  public var authorOrchidID: String = ""
  public var authorResearcherID: String = ""
  public var authorAffiliationUniversityName: String = ""
  public var authorAffiliationFacultyName: String = ""
  public var authorAffiliationInstituteName: String = ""
  public var authorAffiliationCityName: String = ""
  public var authorAffiliationCountryName: String = Locale.current.localizedString(forRegionCode: Locale.current.regionCode ?? "NL") ?? "Netherlands"
  public var creationDate: Date = Date()
  
  override init()
  {
    super.init()
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    let calendar = Calendar.current
    
    encoder.encode(Object.classVersionNumber)
    
    encoder.encode(self.displayName)
    encoder.encode(self.isVisible)
    
    encoder.encode(self.cell)
    encoder.encode(self.periodic)
    encoder.encode(self.origin)
    encoder.encode(self.scaling)
    encoder.encode(self.orientation)
    encoder.encode(self.rotationDelta)
    
    encoder.encode(self.drawUnitCell)
    encoder.encode(self.unitCellScaleFactor)
    encoder.encode(self.unitCellDiffuseColor)
    encoder.encode(self.unitCellDiffuseIntensity)
    
    encoder.encode(self.renderLocalAxis)
    
    // Info
    encoder.encode(self.authorFirstName)
    encoder.encode(self.authorMiddleName)
    encoder.encode(self.authorLastName)
    encoder.encode(self.authorOrchidID)
    encoder.encode(self.authorResearcherID)
    encoder.encode(self.authorAffiliationUniversityName)
    encoder.encode(self.authorAffiliationFacultyName)
    encoder.encode(self.authorAffiliationInstituteName)
    encoder.encode(self.authorAffiliationCityName)
    encoder.encode(self.authorAffiliationCountryName)
    
    // Creation
    encoder.encode(UInt16(calendar.component(.day, from: self.creationDate)))
    encoder.encode(UInt16(calendar.component(.month, from: self.creationDate)))
    encoder.encode(UInt32(calendar.component(.year, from: self.creationDate)))
    
    encoder.encode(Int(0x6f6b6181))
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let calendar = Calendar.current
    var components = DateComponents()
    components.era = 1
    components.quarter = 0
    components.hour = 0
    components.minute = 0
    components.second = 0
    
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Object.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.isVisible = try decoder.decode(Bool.self)
    
    self.cell = try decoder.decode(SKCell.self)
    self.periodic = try decoder.decode(Bool.self)
    self.origin = try decoder.decode(SIMD3<Double>.self)
    self.scaling = try decoder.decode(SIMD3<Double>.self)
    self.orientation = try decoder.decode(simd_quatd.self)
    self.rotationDelta = try decoder.decode(Double.self)
    
    self.drawUnitCell = try decoder.decode(Bool.self)
    self.unitCellScaleFactor = try decoder.decode(Double.self)
    self.unitCellDiffuseColor = try decoder.decode(NSColor.self)
    self.unitCellDiffuseIntensity = try decoder.decode(Double.self)
  
    self.renderLocalAxis = try decoder.decode(RKLocalAxes.self)
    
    // Info
    self.authorFirstName = try decoder.decode(String.self)
    self.authorMiddleName = try decoder.decode(String.self)
    self.authorLastName = try decoder.decode(String.self)
    self.authorOrchidID = try decoder.decode(String.self)
    self.authorResearcherID = try decoder.decode(String.self)
    self.authorAffiliationUniversityName = try decoder.decode(String.self)
    self.authorAffiliationFacultyName = try decoder.decode(String.self)
    self.authorAffiliationInstituteName = try decoder.decode(String.self)
    self.authorAffiliationCityName = try decoder.decode(String.self)
    self.authorAffiliationCountryName = try decoder.decode(String.self)
    
    // Creation
    components.day = Int(try decoder.decode(UInt16.self))
    components.month = Int(try decoder.decode(UInt16.self))
    components.year = Int(try decoder.decode(UInt32.self))
    self.creationDate = calendar.date(from: components) ?? Date()
    
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6181)
    {
      throw BinaryDecodableError.invalidMagicNumber
    }
  }
}
