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

import Cocoa
import RenderKit
import SymmetryKit
import BinaryCodable
import simd


public class VolumetricData: Object, IsosurfaceViewer, RKRenderUnitCellSource
{  
  private static var classVersionNumber: Int = 2
  
  public override var materialType: Object.ObjectType
  {
    return .volumetricData
  }
  
  public var dimensions: SIMD3<Int32> = SIMD3<Int32>()
  public var spacing: SIMD3<Double> = SIMD3<Double>()
  public var range: (Double, Double) = (0.0,0.0)
  public var data: Data = Data()
  public var average: Double = 0.0
  public var variance: Double = 0.0
  
  public var drawAdsorptionSurface: Bool = false
  
  public var adsorptionSurfaceRenderingMethod: RKEnergySurfaceType = RKEnergySurfaceType.isoSurface
  public var adsorptionVolumeTransferFunction: RKPredefinedVolumeRenderingTransferFunction = RKPredefinedVolumeRenderingTransferFunction.CoolWarmDiverging
  public var adsorptionVolumeStepLength: Double = 0.0005
  
  public var adsorptionSurfaceOpacity: Double = 1.0
  public var adsorptionTransparencyThreshold: Double = 0.0
  public var adsorptionSurfaceIsoValue: Double = 0.0
  public var encompassingPowerOfTwoCubicGridSize: Int = 7
  
  public var adsorptionSurfaceProbeMolecule: Structure.ProbeMolecule = .helium
  public var adsorptionSurfaceProbeParameters: SIMD2<Double>
  {
    switch(adsorptionSurfaceProbeMolecule)
    {
    case .helium:
      return SIMD2<Double>(10.9, 2.64)
    case .nitrogen:
      return SIMD2<Double>(36.0,3.31)
    case .methane:
      return SIMD2<Double>(158.5,3.72)
    case .hydrogen:
      return SIMD2<Double>(36.7,2.958)
    case .water:
      return SIMD2<Double>(89.633,3.097)
    case .co2:
      // Y. Iwai, H. Higashi, H. Uchida, Y. Arai, Fluid Phase Equilibria 127 (1997) 251-261.
      return SIMD2<Double>(236.1,3.72)
    case .xenon:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return SIMD2<Double>(226.14,3.949)
    case .krypton:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return SIMD2<Double>(162.58,3.6274)
    case .argon:
      return SIMD2<Double>(119.8,3.34)
    }
  }
  public var adsorptionSurfaceNumberOfTriangles: Int = 0
  
  public var adsorptionSurfaceHue: Double = 1.0;
  public var adsorptionSurfaceSaturation: Double = 1.0;
  public var adsorptionSurfaceValue: Double = 1.0;
  
  public var adsorptionSurfaceFrontSideHDR: Bool = true
  public var adsorptionSurfaceFrontSideHDRExposure: Double = 2.0
  public var adsorptionSurfaceFrontSideAmbientColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var adsorptionSurfaceFrontSideDiffuseColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var adsorptionSurfaceFrontSideSpecularColor: NSColor = NSColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
  public var adsorptionSurfaceFrontSideDiffuseIntensity: Double = 1.0
  public var adsorptionSurfaceFrontSideAmbientIntensity: Double = 0.0
  public var adsorptionSurfaceFrontSideSpecularIntensity: Double = 0.5
  public var adsorptionSurfaceFrontSideShininess: Double = 4.0
  
  public var adsorptionSurfaceBackSideHDR: Bool = true
  public var adsorptionSurfaceBackSideHDRExposure: Double = 2.0
  public var adsorptionSurfaceBackSideAmbientColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var adsorptionSurfaceBackSideDiffuseColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var adsorptionSurfaceBackSideSpecularColor: NSColor = NSColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
  public var adsorptionSurfaceBackSideDiffuseIntensity: Double = 1.0
  public var adsorptionSurfaceBackSideAmbientIntensity: Double = 0.0
  public var adsorptionSurfaceBackSideSpecularIntensity: Double = 0.5
  public var adsorptionSurfaceBackSideShininess: Double = 4.0
  
  public override init()
  {
    super.init()
  }
  
  public init(copy gridVolume: VolumetricData)
  {
    super.init(copy: gridVolume)
  }
  
  public init(clone gridVolume: VolumetricData)
  {
    super.init(clone: gridVolume)
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
    
    if let isosurfaceViewer: IsosurfaceViewer = object as? IsosurfaceViewer
    {
      self.drawAdsorptionSurface = isosurfaceViewer.drawAdsorptionSurface
      self.encompassingPowerOfTwoCubicGridSize = isosurfaceViewer.encompassingPowerOfTwoCubicGridSize
      self.dimensions = isosurfaceViewer.dimensions
      self.spacing = isosurfaceViewer.spacing
      self.range = isosurfaceViewer.range
      self.data = isosurfaceViewer.data
      self.average = isosurfaceViewer.average
      self.variance = isosurfaceViewer.variance
      
      self.adsorptionSurfaceOpacity = isosurfaceViewer.adsorptionSurfaceOpacity
      self.adsorptionTransparencyThreshold = isosurfaceViewer.adsorptionTransparencyThreshold
      self.adsorptionSurfaceIsoValue = isosurfaceViewer.adsorptionSurfaceIsoValue
      self.adsorptionSurfaceProbeMolecule = isosurfaceViewer.adsorptionSurfaceProbeMolecule
      
      self.adsorptionSurfaceRenderingMethod = isosurfaceViewer.adsorptionSurfaceRenderingMethod
      self.adsorptionVolumeTransferFunction = isosurfaceViewer.adsorptionVolumeTransferFunction
      self.adsorptionVolumeStepLength = isosurfaceViewer.adsorptionVolumeStepLength
      
      self.adsorptionSurfaceHue = isosurfaceViewer.adsorptionSurfaceHue
      self.adsorptionSurfaceSaturation = isosurfaceViewer.adsorptionSurfaceSaturation
      self.adsorptionSurfaceValue = isosurfaceViewer.adsorptionSurfaceValue
      
      self.adsorptionSurfaceFrontSideHDR = isosurfaceViewer.adsorptionSurfaceFrontSideHDR
      self.adsorptionSurfaceFrontSideHDRExposure = isosurfaceViewer.adsorptionSurfaceFrontSideHDRExposure
      self.adsorptionSurfaceFrontSideAmbientIntensity = isosurfaceViewer.adsorptionSurfaceFrontSideAmbientIntensity
      self.adsorptionSurfaceFrontSideDiffuseIntensity = isosurfaceViewer.adsorptionSurfaceFrontSideDiffuseIntensity
      self.adsorptionSurfaceFrontSideSpecularIntensity = isosurfaceViewer.adsorptionSurfaceFrontSideSpecularIntensity
      self.adsorptionSurfaceFrontSideShininess = isosurfaceViewer.adsorptionSurfaceFrontSideShininess
      self.adsorptionSurfaceFrontSideAmbientColor = isosurfaceViewer.adsorptionSurfaceFrontSideAmbientColor
      self.adsorptionSurfaceFrontSideDiffuseColor = isosurfaceViewer.adsorptionSurfaceFrontSideDiffuseColor
      self.adsorptionSurfaceFrontSideSpecularColor = isosurfaceViewer.adsorptionSurfaceFrontSideSpecularColor
      
      self.adsorptionSurfaceBackSideHDR = isosurfaceViewer.adsorptionSurfaceBackSideHDR
      self.adsorptionSurfaceBackSideHDRExposure = isosurfaceViewer.adsorptionSurfaceBackSideHDRExposure
      self.adsorptionSurfaceBackSideAmbientIntensity = isosurfaceViewer.adsorptionSurfaceBackSideAmbientIntensity
      self.adsorptionSurfaceBackSideDiffuseIntensity = isosurfaceViewer.adsorptionSurfaceBackSideDiffuseIntensity
      self.adsorptionSurfaceBackSideSpecularIntensity = isosurfaceViewer.adsorptionSurfaceBackSideSpecularIntensity
      self.adsorptionSurfaceBackSideShininess = isosurfaceViewer.adsorptionSurfaceBackSideShininess
      self.adsorptionSurfaceBackSideAmbientColor = isosurfaceViewer.adsorptionSurfaceBackSideAmbientColor
      self.adsorptionSurfaceBackSideDiffuseColor = isosurfaceViewer.adsorptionSurfaceBackSideDiffuseColor
      self.adsorptionSurfaceBackSideSpecularColor = isosurfaceViewer.adsorptionSurfaceBackSideSpecularColor
    }
  }
  
  public override var boundingBox: SKBoundingBox
  {
    let minimumReplica = cell.minimumReplica
    let maximumReplica = cell.maximumReplica
    
    let c0: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),  y: Double(minimumReplica.y),  z: Double(minimumReplica.z)))
    let c1: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(minimumReplica.z)))
    let c2: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(minimumReplica.z)))
    let c3: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(minimumReplica.z)))
    let c4: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1)))
    let c5: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1)))
    let c6: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1)))
    let c7: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1)))
    
    let minimum = SIMD3<Double>(x: min(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                                y: min(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                                z: min(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))

    let maximum = SIMD3<Double>(x: max(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                                y: max(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                                z: max(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  // MARK: protocol RKRenderUnitCellSource implementation
  // =====================================================================
  
  public override var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms]()
    
    let boundingBoxWidths: SIMD3<Double> = self.cell.boundingBox.widths
    
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
    {
      for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
      {
        for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
        {
          let cartesianPosition: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
          let spherePosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: 1.0)
          
          let ambient: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          let diffuse: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          let specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          
          data.append(RKInPerInstanceAttributesAtoms(position: spherePosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(scale), tag: UInt32(0)))
        }
      }
    }
    
    return data
  }

  public override var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    
    let color1: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let color2: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    let boundingBoxWidths: SIMD3<Double> = self.cell.boundingBox.widths
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
    {
      for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
      {
        for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
        {
          
          if(k1 <= self.cell.maximumReplica[0])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
            let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1+1), y: Double(k2), z: Double(k3)))
            cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
              position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
              color1: SIMD4<Float>(color: color1),
              color2: SIMD4<Float>(color: color2),
              scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
          }
          
          if(k2 <= self.cell.maximumReplica[1])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
            let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2+1), z: Double(k3)))
            cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
              position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
              color1: SIMD4<Float>(color: color1),
              color2: SIMD4<Float>(color: color2),
              scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
          }
          
          if(k3 <= self.cell.maximumReplica[2])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
            let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3+1)))
            cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
              position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
              color1: SIMD4<Float>(color: color1),
              color2: SIMD4<Float>(color: color2),
              scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
          }
        }
      }
    }
    
    return data
  }
   
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(VolumetricData.classVersionNumber)
   
    encoder.encode(self.dimensions)
    encoder.encode(self.spacing)
    encoder.encode(self.range.0)
    encoder.encode(self.range.1)
    encoder.encode(self.data)
    encoder.encode(self.average)
    encoder.encode(self.variance)
    
    encoder.encode(self.drawAdsorptionSurface)
    
    encoder.encode(self.adsorptionSurfaceOpacity)
    encoder.encode(self.adsorptionTransparencyThreshold)
    encoder.encode(self.adsorptionSurfaceIsoValue)
    encoder.encode(self.encompassingPowerOfTwoCubicGridSize)
    
    encoder.encode(self.adsorptionSurfaceProbeMolecule.rawValue)
    encoder.encode(self.adsorptionSurfaceRenderingMethod.rawValue)
    encoder.encode(self.adsorptionVolumeTransferFunction.rawValue)
    encoder.encode(self.adsorptionVolumeStepLength)
    
    encoder.encode(self.adsorptionSurfaceHue)
    encoder.encode(self.adsorptionSurfaceSaturation)
    encoder.encode(self.adsorptionSurfaceValue)
    
    encoder.encode(self.adsorptionSurfaceFrontSideHDR)
    encoder.encode(self.adsorptionSurfaceFrontSideHDRExposure)
    encoder.encode(self.adsorptionSurfaceFrontSideAmbientColor)
    encoder.encode(self.adsorptionSurfaceFrontSideDiffuseColor)
    encoder.encode(self.adsorptionSurfaceFrontSideSpecularColor)
    encoder.encode(self.adsorptionSurfaceFrontSideAmbientIntensity)
    encoder.encode(self.adsorptionSurfaceFrontSideDiffuseIntensity)
    encoder.encode(self.adsorptionSurfaceFrontSideSpecularIntensity)
    encoder.encode(self.adsorptionSurfaceFrontSideShininess)
    
    encoder.encode(self.adsorptionSurfaceBackSideHDR)
    encoder.encode(self.adsorptionSurfaceBackSideHDRExposure)
    encoder.encode(self.adsorptionSurfaceBackSideAmbientColor)
    encoder.encode(self.adsorptionSurfaceBackSideDiffuseColor)
    encoder.encode(self.adsorptionSurfaceBackSideSpecularColor)
    encoder.encode(self.adsorptionSurfaceBackSideAmbientIntensity)
    encoder.encode(self.adsorptionSurfaceBackSideDiffuseIntensity)
    encoder.encode(self.adsorptionSurfaceBackSideSpecularIntensity)
    encoder.encode(self.adsorptionSurfaceBackSideShininess)
    
    encoder.encode(Int(0x6f6b6195))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > VolumetricData.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    dimensions = try decoder.decode(SIMD3<Int32>.self)
    spacing = try decoder.decode(SIMD3<Double>.self)
    let range_low = try decoder.decode(Double.self)
    let range_high = try decoder.decode(Double.self)
    self.range = (range_low, range_high)
    data = try decoder.decode(Data.self)
    
    if readVersionNumber >= 2 // introduced in version 2
    {
      self.average = try decoder.decode(Double.self)
      self.variance = try decoder.decode(Double.self)
      
      self.drawAdsorptionSurface = try decoder.decode(Bool.self)
      
      self.adsorptionSurfaceOpacity = try decoder.decode(Double.self)
      self.adsorptionTransparencyThreshold = try decoder.decode(Double.self)
      self.adsorptionSurfaceIsoValue = try decoder.decode(Double.self)
      self.encompassingPowerOfTwoCubicGridSize = try decoder.decode(Int.self)
      
      guard let probeMolecule = Structure.ProbeMolecule(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.adsorptionSurfaceProbeMolecule = probeMolecule
      guard let adsorptionSurfaceRenderingMethod = RKEnergySurfaceType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.adsorptionSurfaceRenderingMethod = adsorptionSurfaceRenderingMethod
      guard let adsorptionVolumeTransferFunction = RKPredefinedVolumeRenderingTransferFunction(rawValue: try decoder.decode(Int.self)) else {throw   BinaryCodableError.invalidArchiveData}
      self.adsorptionVolumeTransferFunction = adsorptionVolumeTransferFunction
      self.adsorptionVolumeStepLength = try decoder.decode(Double.self)
      
      self.adsorptionSurfaceHue = try decoder.decode(Double.self)
      self.adsorptionSurfaceSaturation = try decoder.decode(Double.self)
      self.adsorptionSurfaceValue = try decoder.decode(Double.self)
   
      self.adsorptionSurfaceFrontSideHDR = try decoder.decode(Bool.self)
      self.adsorptionSurfaceFrontSideHDRExposure = try decoder.decode(Double.self)
      self.adsorptionSurfaceFrontSideAmbientColor = try decoder.decode(NSColor.self)
      self.adsorptionSurfaceFrontSideDiffuseColor = try decoder.decode(NSColor.self)
      self.adsorptionSurfaceFrontSideSpecularColor = try decoder.decode(NSColor.self)
      self.adsorptionSurfaceFrontSideAmbientIntensity = try decoder.decode(Double.self)
      self.adsorptionSurfaceFrontSideDiffuseIntensity = try decoder.decode(Double.self)
      self.adsorptionSurfaceFrontSideSpecularIntensity = try decoder.decode(Double.self)
      self.adsorptionSurfaceFrontSideShininess = try decoder.decode(Double.self)
      
      self.adsorptionSurfaceBackSideHDR = try decoder.decode(Bool.self)
      self.adsorptionSurfaceBackSideHDRExposure = try decoder.decode(Double.self)
      self.adsorptionSurfaceBackSideAmbientColor = try decoder.decode(NSColor.self)
      self.adsorptionSurfaceBackSideDiffuseColor = try decoder.decode(NSColor.self)
      self.adsorptionSurfaceBackSideSpecularColor = try decoder.decode(NSColor.self)
      self.adsorptionSurfaceBackSideAmbientIntensity = try decoder.decode(Double.self)
      self.adsorptionSurfaceBackSideDiffuseIntensity = try decoder.decode(Double.self)
      self.adsorptionSurfaceBackSideSpecularIntensity = try decoder.decode(Double.self)
      self.adsorptionSurfaceBackSideShininess = try decoder.decode(Double.self)
    }
    
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6195)
    {
      throw BinaryDecodableError.invalidMagicNumber
    }
    
    try super.init(fromBinary: decoder)
  }
}
