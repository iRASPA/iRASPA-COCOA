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

import Cocoa
import RenderKit
import SymmetryKit
import BinaryCodable
import simd

public class Primitive: Object, AtomViewer, PrimitiveViewer
{
  private static var classVersionNumber: Int = 2
  
  public func readySelectedAtomsForCopyAndPaste() -> [SKAtomTreeNode] {
    return []
  }
  
  public func expandSymmetry(asymmetricAtom: SKAsymmetricAtom) {
    
  }
  
  public var atomColorSchemeIdentifier: String
  {
    return "Default"
  }
  
  public var atomForceFieldIdentifier: String
  {
    return "Default"
  }
  
  public var isFractional: Bool = true
  
  public required init(from object: Object)
  {
    super.init(from: object)
  }
  
  public init(clone: Primitive)
  {
    super.init()
  }
  
  public init(copy: Primitive)
  {
    super.init()
  }
  
  public var selectionCOMTranslation: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
  public var selectionRotationIndex: Int = 0
  public var selectionBodyFixedBasis: double3x3 = double3x3(diagonal: SIMD3<Double>(1.0, 1.0, 1.0))
  
  public var renderDrawAtoms: Bool?
  
  public var numberOfAtoms: Int = 0
  public var atomSelectionStyle: RKSelectionStyle = .WorleyNoise3D
  public var atomSelectionScaling: Double = 1.2
  public var atomSelectionStripesDensity: Double = 0.25
  public var atomSelectionStripesFrequency: Double = 12.0
  public var atomSelectionWorleyNoise3DFrequency: Double = 2.0
  public var atomSelectionWorleyNoise3DJitter: Double = 1.0
  public var atomSelectionIntensity: Double = 0.5
  
  public var drawAtoms: Bool =  true
  public var atomTreeController: SKAtomTreeController = SKAtomTreeController()
  
  public var primitiveTransformationMatrix: double3x3 = double3x3(1.0)
  public var primitiveOrientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  public var primitiveRotationDelta: Double = 5.0
  
  public var primitiveOpacity: Double = 1.0
  public var primitiveIsCapped: Bool = false
  public var primitiveIsFractional: Bool = true
  public var primitiveNumberOfSides: Int = 6
  public var primitiveThickness: Double = 0.05
  
  public var primitiveHue: Double = 1.0
  public var primitiveSaturation: Double = 1.0
  public var primitiveValue: Double = 1.0
  
  public var primitiveSelectionStyle: RKSelectionStyle = .striped
  public var primitiveSelectionScaling: Double = 1.0
  public var primitiveSelectionStripesDensity: Double = 0.25
  public var primitiveSelectionStripesFrequency: Double = 12.0
  public var primitiveSelectionWorleyNoise3DFrequency: Double = 2.0
  public var primitiveSelectionWorleyNoise3DJitter: Double = 1.0
  public var primitiveSelectionIntensity: Double = 1.0
  
  public var primitiveFrontSideHDR: Bool = true
  public var primitiveFrontSideHDRExposure: Double = 2.0
  public var primitiveFrontSideAmbientColor: NSColor = NSColor.white
  public var primitiveFrontSideDiffuseColor: NSColor = NSColor.yellow
  public var primitiveFrontSideSpecularColor: NSColor = NSColor.white
  public var primitiveFrontSideAmbientIntensity: Double = 0.1
  public var primitiveFrontSideDiffuseIntensity: Double = 1.0
  public var primitiveFrontSideSpecularIntensity: Double = 0.2
  public var primitiveFrontSideShininess: Double = 4.0
  
  public var primitiveBackSideHDR: Bool = true
  public var primitiveBackSideHDRExposure: Double = 2.0
  public var primitiveBackSideAmbientColor: NSColor = NSColor.white
  public var primitiveBackSideDiffuseColor: NSColor = NSColor(red: 0.0, green: 0.5490196, blue: 1.0, alpha: 1.0) // Aqua
  public var primitiveBackSideSpecularColor: NSColor = NSColor.white
  public var primitiveBackSideAmbientIntensity: Double = 0.1
  public var primitiveBackSideDiffuseIntensity: Double = 1.0
  public var primitiveBackSideSpecularIntensity: Double = 0.2
  public var primitiveBackSideShininess: Double = 4.0
  
  override init()
  {
    super.init()
  }
  
  public init(name: String)
  {
    super.init()
    self.displayName = name
  }
  
  public var renderPrimitiveSelectionFrequency: Double
  {
    get
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
        return 0.0
      case .striped:
        return self.primitiveSelectionStripesFrequency
      case .WorleyNoise3D:
        return self.primitiveSelectionWorleyNoise3DFrequency
      }
    }
    set(newValue)
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
        break
      case .striped:
        self.primitiveSelectionStripesFrequency = newValue
      case .WorleyNoise3D:
        self.primitiveSelectionWorleyNoise3DFrequency = newValue
      }
    }
  }
  
  public var renderPrimitiveSelectionDensity: Double
  {
    get
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
          return 0.0
        case .striped:
          return self.primitiveSelectionStripesDensity
        case .WorleyNoise3D:
          return self.primitiveSelectionWorleyNoise3DJitter
      }
    }
    set(newValue)
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
        break
      case .striped:
        self.primitiveSelectionStripesDensity = newValue
      case .WorleyNoise3D:
        self.primitiveSelectionWorleyNoise3DJitter = newValue
      }
    }
  }
  
  public func filterCartesianAtomPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
  {
    return []
  }
  
  public func centerOfMassOfSelection(atoms: [SKAtomCopy]) -> SIMD3<Double>
  {
    return SIMD3<Double>(0.0,0.0,0.0)
  }
  
  public func matrixOfInertia(atoms: [SKAtomCopy]) -> double3x3
  {
    return double3x3()
  }
  
  
  public func recomputeSelectionBodyFixedBasis(atoms: [SKAtomCopy]) -> double3x3
  {
    let intertiaMatrix: double3x3 = matrixOfInertia(atoms: atoms)

    var eigenvectors: double3x3 = double3x3()
    var eigenvalues: SIMD3<Double> = SIMD3<Double>()
    intertiaMatrix.EigenSystemSymmetric3x3(Q: &eigenvectors, w: &eigenvalues)
    return eigenvectors
  }
  
  // -1: always update
  // 0: x
  // 1: y
  // 2: z
  // update when index changes, so when a new direction of rotation has been chosen
  public func recomputeSelectionBodyFixedBasis(index: Int)
  {
    let atoms: [SKAtomCopy] = self.atomTreeController.selectedTreeNodes.flatMap{$0.representedObject.copies}.filter{$0.type == .copy}
    if index < 0 || self.selectionRotationIndex != index
    {
      self.selectionRotationIndex = index
      self.selectionCOMTranslation = centerOfMassOfSelection(atoms: atoms)
      let intertiaMatrix: double3x3 = matrixOfInertia(atoms: atoms)

      var eigenvectors: double3x3 = double3x3()
      var eigenvalues: SIMD3<Double> = SIMD3<Double>()
      intertiaMatrix.EigenSystemSymmetric3x3(Q: &eigenvectors, w: &eigenvalues)
      self.selectionBodyFixedBasis = eigenvectors
    }
  }
  
  public func translatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by translation: SIMD3<Double>) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func translatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by translation: SIMD3<Double>) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func rotatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by rotation: simd_quatd) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func rotatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by rotation: simd_quatd) -> [SIMD3<Double>]
  {
    return []
  }
  
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(Primitive.classVersionNumber)
    
    encoder.encode(drawAtoms)
    self.atomTreeController.tag()
    encoder.encode(atomTreeController)
    
    encoder.encode(primitiveTransformationMatrix)
    encoder.encode(primitiveOrientation)
    encoder.encode(primitiveRotationDelta)
    
    encoder.encode(primitiveOpacity)
    encoder.encode(primitiveIsCapped)
    encoder.encode(primitiveIsFractional)
    encoder.encode(primitiveNumberOfSides)
    encoder.encode(primitiveThickness)
    
    encoder.encode(primitiveHue)
    encoder.encode(primitiveSaturation)
    encoder.encode(primitiveValue)
    
    encoder.encode(primitiveSelectionStyle.rawValue)
    encoder.encode(primitiveSelectionStripesDensity)
    encoder.encode(primitiveSelectionStripesFrequency)
    encoder.encode(primitiveSelectionWorleyNoise3DFrequency)
    encoder.encode(primitiveSelectionWorleyNoise3DJitter)
    encoder.encode(primitiveSelectionScaling)
    encoder.encode(primitiveSelectionIntensity)
    
    encoder.encode(primitiveFrontSideHDR)
    encoder.encode(primitiveFrontSideHDRExposure)
    encoder.encode(primitiveFrontSideAmbientColor)
    encoder.encode(primitiveFrontSideDiffuseColor)
    encoder.encode(primitiveFrontSideSpecularColor)
    encoder.encode(primitiveFrontSideDiffuseIntensity)
    encoder.encode(primitiveFrontSideAmbientIntensity)
    encoder.encode(primitiveFrontSideSpecularIntensity)
    encoder.encode(primitiveFrontSideShininess)
    
    encoder.encode(primitiveBackSideHDR)
    encoder.encode(primitiveBackSideHDRExposure)
    encoder.encode(primitiveBackSideAmbientColor)
    encoder.encode(primitiveBackSideDiffuseColor)
    encoder.encode(primitiveBackSideSpecularColor)
    encoder.encode(primitiveBackSideDiffuseIntensity)
    encoder.encode(primitiveBackSideAmbientIntensity)
    encoder.encode(primitiveBackSideSpecularIntensity)
    encoder.encode(primitiveBackSideShininess)
    
    encoder.encode(Int(0x6f6b6188))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Primitive.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.drawAtoms = try decoder.decode(Bool.self)
    self.atomTreeController = try decoder.decode(SKAtomTreeController.self)
    self.atomTreeController.tag()
    
    self.primitiveTransformationMatrix = try decoder.decode(double3x3.self)
    self.primitiveOrientation = try decoder.decode(simd_quatd.self)
    self.primitiveRotationDelta = try decoder.decode(Double.self)

    self.primitiveOpacity = try decoder.decode(Double.self)
    self.primitiveIsCapped = try decoder.decode(Bool.self)
    self.primitiveIsFractional = try decoder.decode(Bool.self)
    self.primitiveNumberOfSides = try decoder.decode(Int.self)
    self.primitiveThickness = try decoder.decode(Double.self)
    
    self.primitiveHue = try decoder.decode(Double.self)
    self.primitiveSaturation = try decoder.decode(Double.self)
    self.primitiveValue = try decoder.decode(Double.self)
    
    guard let primitiveSelectionStyle = RKSelectionStyle(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.primitiveSelectionStyle = primitiveSelectionStyle
    self.primitiveSelectionStripesDensity = try decoder.decode(Double.self)
    self.primitiveSelectionStripesFrequency = try decoder.decode(Double.self)
    self.primitiveSelectionWorleyNoise3DFrequency = try decoder.decode(Double.self)
    self.primitiveSelectionWorleyNoise3DJitter = try decoder.decode(Double.self)
    self.primitiveSelectionScaling = try decoder.decode(Double.self)
    self.primitiveSelectionIntensity = try decoder.decode(Double.self)
    
    self.primitiveFrontSideHDR = try decoder.decode(Bool.self)
    self.primitiveFrontSideHDRExposure = try decoder.decode(Double.self)
    self.primitiveFrontSideAmbientColor = try decoder.decode(NSColor.self)
    self.primitiveFrontSideDiffuseColor = try decoder.decode(NSColor.self)
    self.primitiveFrontSideSpecularColor = try decoder.decode(NSColor.self)
    self.primitiveFrontSideDiffuseIntensity = try decoder.decode(Double.self)
    self.primitiveFrontSideAmbientIntensity = try decoder.decode(Double.self)
    self.primitiveFrontSideSpecularIntensity = try decoder.decode(Double.self)
    self.primitiveFrontSideShininess = try decoder.decode(Double.self)

    self.primitiveBackSideHDR = try decoder.decode(Bool.self)
    self.primitiveBackSideHDRExposure = try decoder.decode(Double.self)
    self.primitiveBackSideAmbientColor = try decoder.decode(NSColor.self)
    self.primitiveBackSideDiffuseColor = try decoder.decode(NSColor.self)
    self.primitiveBackSideSpecularColor = try decoder.decode(NSColor.self)
    self.primitiveBackSideDiffuseIntensity = try decoder.decode(Double.self)
    self.primitiveBackSideAmbientIntensity = try decoder.decode(Double.self)
    self.primitiveBackSideSpecularIntensity = try decoder.decode(Double.self)
    self.primitiveBackSideShininess = try decoder.decode(Double.self)
    
    if readVersionNumber >= 2
    {
      let magicNumber = try decoder.decode(Int.self)
      if magicNumber != Int(0x6f6b6188)
      {
        throw BinaryDecodableError.invalidMagicNumber
      }
    }
    
    try super.init(fromBinary: decoder)
  }
}
