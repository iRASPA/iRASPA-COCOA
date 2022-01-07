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

public protocol PrimitiveEditor: AnyObject
{
  var primitiveOrientation: simd_quatd {get set}
  var primitiveRotationDelta: Double  {get set}
  var primitiveTransformationMatrix: double3x3  {get set}
  
  var primitiveOpacity: Double {get set}
  var primitiveNumberOfSides: Int {get set}
  var primitiveIsCapped: Bool {get set}
  var primitiveIsFractional: Bool {get set}
  var primitiveThickness: Double {get set}
  
  var primitiveSelectionStyle: RKSelectionStyle {get set}
  var primitiveSelectionScaling: Double {get set}
  var primitiveSelectionStripesDensity: Double {get set}
  var primitiveSelectionStripesFrequency: Double {get set}
  var primitiveSelectionWorleyNoise3DFrequency: Double {get set}
  var primitiveSelectionWorleyNoise3DJitter: Double {get set}
  var primitiveSelectionIntensity: Double {get set}
  
  var renderPrimitiveSelectionDensity: Double {get set}
  var renderPrimitiveSelectionFrequency: Double {get set}
  
  var primitiveHue: Double {get set}
  var primitiveSaturation: Double {get set}
  var primitiveValue: Double {get set}
  
  var primitiveFrontSideHDR: Bool {get set}
  var primitiveFrontSideHDRExposure: Double {get set}
  var primitiveFrontSideAmbientIntensity: Double {get set}
  var primitiveFrontSideDiffuseIntensity: Double {get set}
  var primitiveFrontSideSpecularIntensity: Double {get set}
  var primitiveFrontSideShininess: Double {get set}
  var primitiveFrontSideAmbientColor: NSColor {get set}
  var primitiveFrontSideDiffuseColor: NSColor {get set}
  var primitiveFrontSideSpecularColor: NSColor {get set}
  
  var primitiveBackSideHDR: Bool {get set}
  var primitiveBackSideHDRExposure: Double {get set}
  var primitiveBackSideAmbientIntensity: Double {get set}
  var primitiveBackSideDiffuseIntensity: Double {get set}
  var primitiveBackSideSpecularIntensity: Double {get set}
  var primitiveBackSideShininess: Double {get set}
  var primitiveBackSideAmbientColor: NSColor {get set}
  var primitiveBackSideDiffuseColor: NSColor {get set}
  var primitiveBackSideSpecularColor: NSColor {get set}
}
