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
import simd
import RenderKit


public protocol VolumetricDataViewer: AnyObject
{
  var drawAdsorptionSurface: Bool {get set}
  var encompassingPowerOfTwoCubicGridSize: Int {get}
  var range: (Double, Double) {get}
  var dimensions: SIMD3<Int32>  {get}
  var spacing: SIMD3<Double> {get}
  var data: Data {get}
  var average: Double {get}
  var variance: Double {get}

  var adsorptionSurfaceOpacity: Double {get set}
  var adsorptionTransparencyThreshold: Double {get set}
  var adsorptionSurfaceIsoValue: Double {get set}
  var adsorptionSurfaceProbeMolecule: Structure.ProbeMolecule {get set}
  
  var adsorptionSurfaceRenderingMethod: RKEnergySurfaceType {get set}
  var adsorptionVolumeTransferFunction: RKPredefinedVolumeRenderingTransferFunction {get set}
  var adsorptionVolumeStepLength: Double {get set}
  
  var adsorptionSurfaceHue: Double {get set}
  var adsorptionSurfaceSaturation: Double {get set}
  var adsorptionSurfaceValue: Double {get set}
  
  var adsorptionSurfaceFrontSideHDR: Bool {get set}
  var adsorptionSurfaceFrontSideHDRExposure: Double {get set}
  var adsorptionSurfaceFrontSideAmbientIntensity: Double {get set}
  var adsorptionSurfaceFrontSideDiffuseIntensity: Double {get set}
  var adsorptionSurfaceFrontSideSpecularIntensity: Double {get set}
  var adsorptionSurfaceFrontSideShininess: Double {get set}
  var adsorptionSurfaceFrontSideAmbientColor: NSColor {get set}
  var adsorptionSurfaceFrontSideDiffuseColor: NSColor {get set}
  var adsorptionSurfaceFrontSideSpecularColor: NSColor {get set}
  
  var adsorptionSurfaceBackSideHDR: Bool {get set}
  var adsorptionSurfaceBackSideHDRExposure: Double {get set}
  var adsorptionSurfaceBackSideAmbientIntensity: Double {get set}
  var adsorptionSurfaceBackSideDiffuseIntensity: Double {get set}
  var adsorptionSurfaceBackSideSpecularIntensity: Double {get set}
  var adsorptionSurfaceBackSideShininess: Double {get set}
  var adsorptionSurfaceBackSideAmbientColor: NSColor {get set}
  var adsorptionSurfaceBackSideDiffuseColor: NSColor {get set}
  var adsorptionSurfaceBackSideSpecularColor: NSColor {get set}
}

public protocol VolumetricDataEditor: VolumetricDataViewer
{
  var encompassingPowerOfTwoCubicGridSize: Int {get set}
}
