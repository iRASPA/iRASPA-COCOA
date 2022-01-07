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
import BinaryCodable

public class RKGlobalAxes: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  
  public enum Style: Int
  {
    case `default` = 0
    case thickRGB = 1
    case thick = 2
    case thinRGB = 3
    case thin = 4
    case beamArrowRGB = 5
    case beamArrow = 6
    case beamRGB = 7
    case beam = 8
    case squashedRGB = 9
    case squashed = 10
  }
  
  public enum Position: Int
  {
    case none = 0
    case bottomLeft = 1
    case midLeft = 2
    case topLeft = 3
    case midTop = 4
    case topRight = 5
    case midRight = 6
    case bottomRight = 7
    case midBottom = 8
    case center = 9
  }
  
  public enum CenterType: Int
  {
    case cube = 0
    case sphere = 1
  }
  
  public enum BackgroundStyle: Int
  {
    case none = 0
    case filledCircle = 1
    case fillesSquare = 2
    case filledRoundedSquare = 3
    case circle = 4
    case square = 5
    case roundedSquare = 6
  }
  
  public var style: RKGlobalAxes.Style = RKGlobalAxes.Style.default
  public var position: RKGlobalAxes.Position = .bottomLeft
  
  public var borderOffsetScreenFraction: Double = 1.0/32.0
  public var sizeScreenFraction: Double = 1.0/5.0
  
  public var axesBackgroundColor: NSColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 0.1882)
  public var axesBackgroundAdditionalSize: Double = 0.0
  public var axesBackgroundStyle: BackgroundStyle = .filledCircle
  
  public var textScale: SIMD3<Double> = SIMD3<Double>(1.0,1.0,1.0)
  public var textColorX: NSColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var textColorY: NSColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var textColorZ: NSColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var textDisplacementX: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
  public var textDisplacementY: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
  public var textDisplacementZ: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
  
  
  // internal options
  
  var HDR: Bool = true
  var exposure: Double = 1.5
  
  var NumberOfSectors: Int = 41

  var centerScale: Double = 0.5
  var textOffset: Double = 0.0
  var axisScale: Double = 5.0
  
  var shaftLength: Double = 2.0/3.0
  var shaftWidth: Double = 1.0/24.0
  
  var tipLength: Double = 2.0/3.0
  var tipWidth: Double = 1.0/24.0

  var centerType: RKGlobalAxes.CenterType = .cube
  var tipVisibility: Bool = true
  
  var aspectRatio: Double = 1.0
 
  var centerAmbientColor: NSColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
  var centerDiffuseColor: NSColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var centerSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var centerShininess: Double = 4.0
  
  var axisXAmbientColor: NSColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
  var axisXDiffuseColor: NSColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var axisXSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var axisXShininess: Double = 4.0
  
  var axisYAmbientColor: NSColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
  var axisYDiffuseColor: NSColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var axisYSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var axisYShininess: Double = 4.0
  
  var axisZAmbientColor: NSColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
  var axisZDiffuseColor: NSColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var axisZSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  var axisZShininess: Double = 4.0
  
  public init(style: RKGlobalAxes.Style = RKGlobalAxes.Style.default)
  {
    setStyle(style: style)
  }
  
  var totalAxesSize: Double
  {
    return axisScale + centerScale + textOffset + 2.0*max(textScale.x, textScale.y, textScale.z) + axesBackgroundAdditionalSize
  }

  public func setStyle(style: RKGlobalAxes.Style)
  {
    switch(style)
    {
    case .default:
      HDR = true
      exposure = 1.5

      centerScale = 0.125
      textOffset = 1.0
      
      NumberOfSectors = 4
      
      shaftLength = 1.0
      shaftWidth = 0.125 * sqrt(2.0)
      
      tipLength = 0.0
      tipWidth = 1.0/6.0

      centerType = .cube
      tipVisibility = false
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .thickRGB:
      HDR = true
      exposure = 1.5

      NumberOfSectors = 41
      
      centerScale = 0.125
      textOffset = 0.0
      
      shaftLength = 2.0/3.0
      shaftWidth = 3.0/48.0
      
      tipLength = 1.0/3.0
      tipWidth = 3.0/24.0

      centerType = .cube
      tipVisibility = true
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .thick:
      HDR = true
      exposure = 1.5

      NumberOfSectors = 41
      
      centerScale = 0.125
      textOffset = 0.0
      
      shaftLength = 2.0/3.0
      shaftWidth = 3.0/48.0
      
      tipLength = 1.0/3.0
      tipWidth = 3.0/24.0

      centerType = .cube
      tipVisibility = true
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.7, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.7, green: 1.0, blue: 0.4, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .thinRGB:
      HDR = true
      exposure = 1.5

      NumberOfSectors = 41
      
      centerScale = 0.0625
      textOffset = 0.0
      
      shaftLength = 2.0/3.0
      shaftWidth = 1.0/24.0
      
      tipLength = 1.0/3.0
      tipWidth = 1.0/12.0
      
      centerType = .sphere
      tipVisibility = true
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .thin:
      HDR = true
      exposure = 1.5

      NumberOfSectors = 41
      
      centerScale = 0.0625
      textOffset = 0.0
      
      shaftLength = 2.0/3.0
      shaftWidth = 1.0/24.0
      
      tipLength = 1.0/3.0
      tipWidth = 1.0/12.0
      
      centerType = .sphere
      tipVisibility = true
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.7, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.7, green: 1.0, blue: 0.4, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .beamArrowRGB:
      HDR = true
      exposure = 1.5

      centerScale = 0.125
      textOffset = 0.0
      
      NumberOfSectors = 4
      
      shaftLength = 2.0/3.0
      shaftWidth = 1.0/12.0
      
      tipLength = 1.0/3.0
      tipWidth = 1.0/6.0

      centerType = .cube
      tipVisibility = true
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .beamArrow:
      HDR = true
      exposure = 1.5

      centerScale = 0.125
      textOffset = 0.0
      
      NumberOfSectors = 4
      
      shaftLength = 2.0/3.0
      shaftWidth = 1.0/12.0
      
      tipLength = 1.0/3.0
      tipWidth = 1.0/6.0

      centerType = .cube
      tipVisibility = true
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.7, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.7, green: 1.0, blue: 0.4, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .beamRGB:
      HDR = true
      exposure = 1.5

      centerScale = 0.125
      textOffset = 0.5
      
      NumberOfSectors = 4
      
      shaftLength = 1.0
      shaftWidth = 0.125 // * sqrt(2.0)
      
      tipLength = 0.0
      tipWidth = 1.0/6.0

      centerType = .cube
      tipVisibility = false
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .beam:
      HDR = true
      exposure = 1.5

      centerScale = 0.125
      textOffset = 0.5
      
      NumberOfSectors = 4
      
      shaftLength = 1.0
      shaftWidth = 0.125 // * sqrt(2.0)
      
      tipLength = 0.0
      tipWidth = 1.0/6.0

      centerType = .cube
      tipVisibility = false
      
      aspectRatio = 1.0
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.7, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.7, green: 1.0, blue: 0.4, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .squashedRGB:
      HDR = true
      exposure = 1.5

      NumberOfSectors = 41
      
      centerScale = 0.125
      textOffset = 0.0
      
      shaftLength = 2.0/3.0
      shaftWidth = 3.0/48.0/2.5
      
      tipLength = 1.0/3.0
      tipWidth = 3.0/24.0/2.5

      centerType = .sphere
      tipVisibility = true
      
      aspectRatio = 0.25
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    case .squashed:
      HDR = true
      exposure = 1.5

      NumberOfSectors = 41
      
      centerScale = 0.125
      textOffset = 0.0
      
      shaftLength = 2.0/3.0
      shaftWidth = 3.0/48.0/2.5
      
      tipLength = 1.0/3.0
      tipWidth = 3.0/24.0/2.5

      centerType = .sphere
      tipVisibility = true
      
      aspectRatio = 0.25
     
      centerAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      centerDiffuseColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      centerShininess = 4.0
      
      axisXAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisXDiffuseColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.7, alpha: 1.0)
      axisXSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisXShininess = 4.0
      
      axisYAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisYDiffuseColor = NSColor(calibratedRed: 0.7, green: 1.0, blue: 0.4, alpha: 1.0)
      axisYSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisYShininess = 4.0
      
      axisZAmbientColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.2)
      axisZDiffuseColor = NSColor(calibratedRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
      axisZSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      axisZShininess = 4.0
    }
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(RKGlobalAxes.classVersionNumber)
    
    encoder.encode(self.style.rawValue)
    encoder.encode(self.position.rawValue)
    
    encoder.encode(borderOffsetScreenFraction)
    encoder.encode(sizeScreenFraction)
    
    encoder.encode(axesBackgroundColor)
    encoder.encode(axesBackgroundAdditionalSize)
    encoder.encode(axesBackgroundStyle.rawValue)
    
    encoder.encode(textScale)
    encoder.encode(textColorX)
    encoder.encode(textColorY)
    encoder.encode(textColorZ)
    encoder.encode(textDisplacementX)
    encoder.encode(textDisplacementY)
    encoder.encode(textDisplacementZ)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > RKGlobalAxes.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    guard let style = try RKGlobalAxes.Style(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.style = style
    guard let position = try RKGlobalAxes.Position(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.position = position
    
    self.borderOffsetScreenFraction = try decoder.decode(Double.self)
    self.sizeScreenFraction = try decoder.decode(Double.self)
    
    
    self.axesBackgroundColor = try decoder.decode(NSColor.self)
    self.axesBackgroundAdditionalSize = try decoder.decode(Double.self)
    guard let axesBackgroundStyle = try RKGlobalAxes.BackgroundStyle(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.axesBackgroundStyle = axesBackgroundStyle
    
    self.textScale = try decoder.decode(SIMD3<Double>.self)
    self.textColorX = try decoder.decode(NSColor.self)
    self.textColorY = try decoder.decode(NSColor.self)
    self.textColorZ = try decoder.decode(NSColor.self)
    self.textDisplacementX = try decoder.decode(SIMD3<Double>.self)
    self.textDisplacementY = try decoder.decode(SIMD3<Double>.self)
    self.textDisplacementZ = try decoder.decode(SIMD3<Double>.self)
    
    self.setStyle(style: style)
  }
}
