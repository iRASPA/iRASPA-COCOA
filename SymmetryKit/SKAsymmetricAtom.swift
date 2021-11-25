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
import BinaryCodable
import simd
import MathKit


public final class SKAsymmetricAtom: Hashable, Equatable, CustomStringConvertible, BinaryDecodable, BinaryEncodable, Copying
{
  private static var classVersionNumber: Int = 2

  public var displayName: String = "Default"
  public var asymmetricIndex2: Int = 0
  public var position: SIMD3<Double> = SIMD3<Double>(0,0,0)
  public var charge: Double = 0
  
  public var uniqueForceFieldName: String
  public var elementIdentifier: Int = 0
  public var color: NSColor = NSColor.blue
  public var drawRadius: Double = 1.0
  public var bondDistanceCriteria: Double = 1.0
  public var potentialParameters:  SIMD2<Double> =  SIMD2<Double>(0.0,0.0)
  
  public var tag: Int = 0
  public var symmetryType: AsymmetricAtomType = .asymmetric
  public var hybridization: Hybridization = .untyped
  
  // atom properties (bonds are visible depending on whether the atoms of the bonds are visible)
  public var isFixed: Bool3 = Bool3(false, false, false)
  public var isVisible: Bool = true
  public var isVisibleEnabled: Bool = true
  
  public var serialNumber: Int = 0
  public var remotenessIndicator: Character = " "         // character 'A','B','C','D',...
  public var branchDesignator: Character = " "            // character '1','2','3',...
  public var asymetricID: Int = 0                         // positive integer
  public var alternateLocationIndicator: Character = " "  // character ' ' or 'A','B',...
  public var residueName: String = ""                     // empty or 3 characters
  public var chainIdentifier: Character = " "             // empty or 'A','B','C',...
  public var residueSequenceNumber: Int = 0               // positive integer
  public var codeForInsertionOfResidues: Character = " "  // empty or 'A','B','C',...
  public var occupancy: Double = 1.0
  public var temperaturefactor: Double = 0.0
  public var segmentIdentifier: String = ""               // empty or 4 characters
  
  public var ligandAtom: Bool = false
  public var backBoneAtom: Bool = false
  public var fractional: Bool = false
  public var solvent: Bool = false
  
  // Dynamically updated data
  public var displacement: SIMD3<Double> = SIMD3<Double>()
  public var numberOfCopies: Int = 0
  public var numberOfDuplicates: Int = 0
  
  // the crystallographic copies of the atom
  public var copies: [SKAtomCopy] = []
  
  public enum AsymmetricAtomType: Int
  {
    case container = 0
    case asymmetric = 1
  }
  
  public enum Hybridization: Int
  {
    case untyped = 0
    case sp_linear = 1
    case sp2_trigonal = 2
    case sp3_tetrahedral = 3
    case square_planar = 4
    case trigonal_bipyramidal = 5
    case square_pyramidal = 6
    case octahedral = 7
  }
  
  public init(displayName: String, elementId: Int, uniqueForceFieldName: String, position: SIMD3<Double>, charge: Double, color: NSColor, drawRadius: Double, bondDistanceCriteria: Double, occupancy: Double)
  {
    self.elementIdentifier = elementId
    self.displayName = displayName
    self.uniqueForceFieldName = uniqueForceFieldName
    self.position = position
    self.charge = charge
    self.color = color
    self.drawRadius = drawRadius
    self.bondDistanceCriteria = bondDistanceCriteria
    self.occupancy = occupancy
    self.hybridization = .untyped
  }
  
  public init(atom: SKAsymmetricAtom)
  {
    self.displayName = atom.displayName
    self.position = atom.position
    self.charge = atom.charge
    
    self.uniqueForceFieldName = atom.uniqueForceFieldName
    self.elementIdentifier = atom.elementIdentifier
    self.color = atom.color
    self.drawRadius = atom.drawRadius
    self.bondDistanceCriteria = atom.bondDistanceCriteria
    self.potentialParameters = atom.potentialParameters
    
    self.tag = atom.tag
    self.symmetryType = .asymmetric
    self.hybridization = atom.hybridization
    
    // atom properties (bonds are visible depending on whether the atoms of the bonds are visible)
    self.isFixed = atom.isFixed
    self.isVisible = true
    self.isVisibleEnabled  = true
    self.fractional = atom.fractional
    
    self.serialNumber = atom.serialNumber
    self.remotenessIndicator = atom.remotenessIndicator
    self.branchDesignator = atom.branchDesignator
    self.asymetricID = atom.asymetricID
    self.alternateLocationIndicator = atom.alternateLocationIndicator
    self.residueName = atom.residueName
    self.chainIdentifier = atom.chainIdentifier
    self.residueSequenceNumber = atom.residueSequenceNumber
    self.codeForInsertionOfResidues = atom.codeForInsertionOfResidues
    self.occupancy = atom.occupancy
    self.temperaturefactor = atom.temperaturefactor
    self.segmentIdentifier = atom.segmentIdentifier
    
    self.ligandAtom = atom.ligandAtom
    self.backBoneAtom = atom.backBoneAtom
  }
  
  public init(modelAtom: SKAsymmetricAtom, color: NSColor, drawRadius: Double, bondDistanceCriteria: Double)
  {
    self.displayName = modelAtom.displayName
    self.position = modelAtom.position
    self.charge = modelAtom.charge
    self.fractional = modelAtom.fractional
    
    self.uniqueForceFieldName = modelAtom.uniqueForceFieldName
    self.elementIdentifier = modelAtom.elementIdentifier
    
    self.isFixed = modelAtom.isFixed
    
    self.serialNumber = modelAtom.serialNumber
    self.remotenessIndicator = modelAtom.remotenessIndicator
    self.branchDesignator = modelAtom.branchDesignator
    self.alternateLocationIndicator = modelAtom.alternateLocationIndicator
    self.residueName = modelAtom.residueName
    self.chainIdentifier = modelAtom.chainIdentifier
    self.residueSequenceNumber = modelAtom.residueSequenceNumber
    self.codeForInsertionOfResidues = modelAtom.codeForInsertionOfResidues
    self.occupancy = modelAtom.occupancy
    self.temperaturefactor = modelAtom.temperaturefactor
    self.segmentIdentifier = modelAtom.segmentIdentifier
    
    self.ligandAtom = modelAtom.ligandAtom
    self.backBoneAtom = modelAtom.backBoneAtom
    
    self.color = color
    self.drawRadius = drawRadius
    self.bondDistanceCriteria = bondDistanceCriteria
  }
  
  required public init(copy: SKAsymmetricAtom)
  {
    self.displayName = copy.displayName
    self.position = copy.position
    self.charge = copy.charge
    self.fractional = copy.fractional
    
    self.hybridization = copy.hybridization
    
    self.uniqueForceFieldName = copy.uniqueForceFieldName
    self.elementIdentifier = copy.elementIdentifier
    
    self.isFixed = copy.isFixed
    
    self.serialNumber = copy.serialNumber
    self.remotenessIndicator = copy.remotenessIndicator
    self.branchDesignator = copy.branchDesignator
    self.alternateLocationIndicator = copy.alternateLocationIndicator
    self.residueName = copy.residueName
    self.chainIdentifier = copy.chainIdentifier
    self.residueSequenceNumber = copy.residueSequenceNumber
    self.codeForInsertionOfResidues = copy.codeForInsertionOfResidues
    self.occupancy = copy.occupancy
    self.temperaturefactor = copy.temperaturefactor
    self.segmentIdentifier = copy.segmentIdentifier
    
    self.ligandAtom = copy.ligandAtom
    self.backBoneAtom = copy.backBoneAtom
    
    self.color = copy.color
    self.drawRadius = copy.drawRadius
    self.bondDistanceCriteria = copy.bondDistanceCriteria
  
    self.copies = copy.copies.copy()
    
    for copy in copies
    {
      copy.asymmetricParentAtom = self
    }
  }
  
  // used for copy and paste
  public init(cell: SKCell, atom: SKAsymmetricAtom, isFractional: Bool)
  {
    self.displayName = atom.displayName
    if(isFractional)
    {
      self.position = cell.convertToCartesian(atom.position)
    }
    else
    {
      self.position = atom.position
    }
    self.charge = atom.charge
    self.fractional = false
    
    self.uniqueForceFieldName = atom.uniqueForceFieldName
    self.elementIdentifier = atom.elementIdentifier
    
    self.hybridization = atom.hybridization
    
    self.isFixed = atom.isFixed
    
    self.serialNumber = atom.serialNumber
    self.remotenessIndicator = atom.remotenessIndicator
    self.branchDesignator = atom.branchDesignator
    self.alternateLocationIndicator = atom.alternateLocationIndicator
    self.residueName = atom.residueName
    self.chainIdentifier = atom.chainIdentifier
    self.residueSequenceNumber = atom.residueSequenceNumber
    self.codeForInsertionOfResidues = atom.codeForInsertionOfResidues
    self.occupancy = atom.occupancy
    self.temperaturefactor = atom.temperaturefactor
    self.segmentIdentifier = atom.segmentIdentifier
    
    self.ligandAtom = atom.ligandAtom
    self.backBoneAtom = atom.backBoneAtom
    
    self.color = atom.color
    self.drawRadius = atom.drawRadius
    self.bondDistanceCriteria = atom.bondDistanceCriteria
  }
  
  // MARK: -
  // MARK: Hashable protocol
  
  public func hash(into hasher: inout Hasher)
  {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  
  // MARK: -
  // MARK: CustomStringConvertible protocol
  
  public var description: String
  {
    return self.displayName
  }
  
  // MARK: -
  // MARK: Equatable protocol
  
  public static func ==(lhs: SKAsymmetricAtom, rhs: SKAsymmetricAtom) -> Bool
  {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKAsymmetricAtom.classVersionNumber)
    encoder.encode(asymmetricIndex2)
    encoder.encode(displayName)
    encoder.encode(position)
    encoder.encode(charge)
    encoder.encode(hybridization.rawValue)
    encoder.encode(uniqueForceFieldName)
    encoder.encode(elementIdentifier)
    encoder.encode(color)
    encoder.encode(drawRadius)
    
    encoder.encode(bondDistanceCriteria)
    encoder.encode(potentialParameters)
    encoder.encode(tag)
    encoder.encode(isFixed)
    encoder.encode(isVisible)
    encoder.encode(isVisibleEnabled)
    
    encoder.encode(serialNumber)
    encoder.encode(remotenessIndicator)
    encoder.encode(branchDesignator)
    encoder.encode(asymetricID)
    encoder.encode(alternateLocationIndicator)
    encoder.encode(residueName)
    encoder.encode(chainIdentifier)
    encoder.encode(residueSequenceNumber)
    encoder.encode(codeForInsertionOfResidues)
    encoder.encode(occupancy)
    encoder.encode(temperaturefactor)
    encoder.encode(segmentIdentifier)
    
    encoder.encode(ligandAtom)
    encoder.encode(backBoneAtom)
    encoder.encode(fractional)
    encoder.encode(solvent)
      
    encoder.encode(copies)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKAsymmetricAtom.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    asymmetricIndex2 = try decoder.decode(Int.self)
    displayName = try decoder.decode(String.self)
    position = try decoder.decode(SIMD3<Double>.self)
    charge = try decoder.decode(Double.self)
    if readVersionNumber >= 2 // introduced in version 2
    {
      guard let hybridization = try SKAsymmetricAtom.Hybridization(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.hybridization = hybridization
    }
    uniqueForceFieldName = try decoder.decode(String.self)
    elementIdentifier = try decoder.decode(Int.self)
    color = try decoder.decode(NSColor.self)
    drawRadius = try decoder.decode(Double.self)
    
    bondDistanceCriteria = try decoder.decode(Double.self)
    potentialParameters = try decoder.decode(SIMD2<Double>.self)
    tag = try decoder.decode(Int.self)
    isFixed = try decoder.decode(Bool3.self)
    isVisible = try decoder.decode(Bool.self)
    isVisibleEnabled = try decoder.decode(Bool.self)
    
    serialNumber = try decoder.decode(Int.self)
    remotenessIndicator = try decoder.decode(Character.self)
    branchDesignator = try decoder.decode(Character.self)
    asymetricID = try decoder.decode(Int.self)
    alternateLocationIndicator = try decoder.decode(Character.self)
    residueName = try decoder.decode(String.self)
    chainIdentifier = try decoder.decode(Character.self)
    residueSequenceNumber = try decoder.decode(Int.self)
    codeForInsertionOfResidues = try decoder.decode(Character.self)
    occupancy = try decoder.decode(Double.self)
    temperaturefactor = try decoder.decode(Double.self)
    segmentIdentifier = try decoder.decode(String.self)
    
    ligandAtom = try decoder.decode(Bool.self)
    backBoneAtom = try decoder.decode(Bool.self)
    fractional = try decoder.decode(Bool.self)
    solvent = try decoder.decode(Bool.self)
    
    copies = try decoder.decode([SKAtomCopy].self)
    
    for copy in copies
    {
      copy.asymmetricParentAtom = self
    }
  }
}
