/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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
import simd

class CubeObject: NSObject, RKRenderStructure
{
  func CartesianPosition(for position: double3, replicaPosition: int3) -> double3 {
    return double3()
  }
  
  var renderSelectionScaling: Double = 1.2
  
  var renderTextOffset: double3 = double3()
  
  var renderTextData: [RKInPerInstanceAttributesText] = []
  
  var renderTextColor: NSColor = NSColor.black
  
  public var clipAtomsAtUnitCell: Bool {return false}
  public var clipBondsAtUnitCell: Bool {return false}
  
  public var renderTextType: RKTextType
  {
    return RKTextType.none
  }
  
  public var renderTextStyle: RKTextStyle
  {
    return RKTextStyle.flatBillboard
  }
  
  public var renderTextAlignment: RKTextAlignment
  {
    return RKTextAlignment.center
  }
  
  public var renderTextFont: String
  {
    return "Helvetica"
  }
  
  public var renderTextScaling: Double
  {
    return 1.0
  }
  
  var renderSelectionStripesDensity: Double = 0.25
  
  var renderSelectionStripesFrequency: Double = 12.0
  
  var renderSelectionWorleyNoise3DFrequency: Double = 2.0
  
  var renderSelectionWorleyNoise3DJitter: Double = 0.0
  
  var renderSelectionStyle: RKSelectionStyle = .glow
  
  var displayName: String = "Sphere"
  
  var isVisible: Bool = true
  
  var atomPositions: [double3] = []
  
  var bondPositions: [double3] = []
  
  var potentialParameters: [double2] = []
  
  var renderAtoms: [RKInPerInstanceAttributesAtoms] = []
  
  var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms] = []
  
  var renderInternalBonds: [RKInPerInstanceAttributesBonds] = []
  
  var renderExternalBonds: [RKInPerInstanceAttributesBonds] = []
  
  var renderSelectedBonds: [RKInPerInstanceAttributesBonds] = []
  
  var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms] = []
  
  var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds] = []
  
  var numberOfAtoms: Int = 0
  
  var numberOfInternalBonds: Int = 0
  
  var numberOfExternalBonds: Int = 0
  
  var drawUnitCell: Bool = false
  
  var drawAtoms: Bool = true
  
  var drawBonds: Bool = false
  
  var orientation: simd_quatd = simd_quatd()
  
  var origin: double3 = double3()
  
  var atomAmbientColor: NSColor = NSColor()
  
  var atomDiffuseColor: NSColor = NSColor()
  
  var atomSpecularColor: NSColor = NSColor()
  
  var atomAmbientIntensity: Double = 1.0
  
  var atomDiffuseIntensity: Double = 1.0
  
  var atomSpecularIntensity: Double = 1.0
  
  var atomShininess: Double = 1.0;
  
  var cell: SKCell = SKCell()
  
  var atomCacheAmbientOcclusionTexture: [CUnsignedChar] = []
  
  var hasExternalBonds: Bool = false
  
  var atomHue: Double = 1.0
  
  var atomSaturation: Double = 1.0
  
  var atomValue: Double = 1.0
  
  var atomScaleFactor: Double = 1.0
  
  var atomAmbientOcclusion: Bool = false
  
  var atomAmbientOcclusionPatchNumber: Int = 0
  
  var atomAmbientOcclusionPatchSize: Int = 0
  
  var atomAmbientOcclusionTextureSize: Int = 0
  
  var atomHDR: Bool = false
  
  var atomHDRExposure: Double = 1.0
  
  var atomHDRBloomLevel: Double = 1.0
  
  var bondAmbientColor: NSColor = NSColor()
  
  var bondDiffuseColor: NSColor = NSColor()
  
  var bondSpecularColor: NSColor = NSColor()
  
  var bondAmbientIntensity: Double = 1.0
  
  var bondDiffuseIntensity: Double = 1.0
  
  var bondSpecularIntensity: Double = 1.0
  
  var bondShininess: Double = 1.0
  
  var bondScaleFactor: Double = 1.0
  
  var bondColorMode: RKBondColorMode = RKBondColorMode.uniform
  
  var bondHDR: Bool = false
  
  var bondHDRExposure: Double = 1.0
  
  var bondHDRBloomLevel: Double = 1.0
  
  var bondHue: Double = 1.0
  
  var bondSaturation: Double = 1.0
  
  var bondValue: Double = 1.0
  
  var unitCellScaleFactor: Double = 1.0
  
  var unitCellDiffuseColor: NSColor = NSColor()
  
  var unitCellDiffuseIntensity: Double = 1.0
  
  var drawAdsorptionSurface: Bool = false
  
  var adsorptionSurfaceOpacity: Double = 1.0
  
  var adsorptionSurfaceIsoValue: Double = 1.0
  
  var adsorptionSurfaceSize: Int = 0
  
  var adsorptionSurfaceProbeParameters: double2 = double2()
  
  var adsorptionSurfaceNumberOfTriangles: Int = 0
  
  var adsorptionSurfaceFrontSideHDR: Bool = false
  
  var adsorptionSurfaceFrontSideHDRExposure: Double = 1.0
  
  var adsorptionSurfaceFrontSideAmbientColor: NSColor = NSColor()
  
  var adsorptionSurfaceFrontSideDiffuseColor: NSColor = NSColor()
  
  var adsorptionSurfaceFrontSideSpecularColor: NSColor = NSColor()
  
  var adsorptionSurfaceFrontSideDiffuseIntensity: Double = 1.0
  
  var adsorptionSurfaceFrontSideAmbientIntensity: Double = 1.0
  
  var adsorptionSurfaceFrontSideSpecularIntensity: Double = 1.0
  
  var adsorptionSurfaceFrontSideShininess: Double = 1.0
  
  var adsorptionSurfaceBackSideHDR: Bool = false
  
  var adsorptionSurfaceBackSideHDRExposure: Double = 1.0
  
  var adsorptionSurfaceBackSideAmbientColor: NSColor
    = NSColor()
  var adsorptionSurfaceBackSideDiffuseColor: NSColor = NSColor()
  
  var adsorptionSurfaceBackSideSpecularColor: NSColor = NSColor()
  
  var adsorptionSurfaceBackSideDiffuseIntensity: Double = 1.0
  
  var adsorptionSurfaceBackSideAmbientIntensity: Double = 1.0
  
  var adsorptionSurfaceBackSideSpecularIntensity: Double = 1.0
  
  var adsorptionSurfaceBackSideShininess: Double = 1.0
  
  override init()
  {
    super.init()
  }
  
}

