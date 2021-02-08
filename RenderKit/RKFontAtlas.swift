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
import CoreGraphics
import Metal
import simd

struct GlyphDescriptor
{
  let glyphIndex: CGGlyph
  let topLeftTexCoord: CGPoint
  let bottomRightTexCoord: CGPoint
  
  init(glyphIndex: CGGlyph, topLeftTexCoord: CGPoint, bottomRightTexCoord: CGPoint)
  {
    self.glyphIndex = glyphIndex
    self.topLeftTexCoord = topLeftTexCoord
    self.bottomRightTexCoord = bottomRightTexCoord
  }
}



public class RKFontAtlas
{
  static let atlasSize: Int = 4096
  let parentFont: NSFont
  var fontPointSize: CGFloat
  var spread: CGFloat = 1.0
  let textureSize: Int
  var glyphDescriptors : [GlyphDescriptor] = []
  public var textureData: NSData?
  
  public init(font: NSFont, textureSize: Int)
  {
    self.parentFont = font
    self.textureSize = textureSize
    self.fontPointSize = font.pointSize
    self.spread = self.estimatedLineWidthForFont(font)
    self.createTextureData()
  }
  
  public func buildMeshWithString(position: SIMD4<Float>, scale: SIMD4<Float>, text: String, alignment: RKTextAlignment) -> [RKInPerInstanceAttributesText]
  {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.alignment = .center
    let attrString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font : self.parentFont as Any, NSAttributedString.Key.paragraphStyle : paragraph])
    let stringRange = CFRangeMake(0, attrString.length)
    
    let size: NSSize = attrString.size()
    let boundingRect: CGRect = attrString.boundingRect(with: size, options: [], context: nil)
    let rect = CGRect(x: 0.0, y: 0.0, width: boundingRect.width, height: CGFloat.greatestFiniteMagnitude)
    let rectPath = CGPath(rect: rect, transform: nil)
    let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attrString)
    let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, stringRange, rectPath, nil)
    
    let lines: [CTLine] = CTFrameGetLines(frame) as! [CTLine]
    let frameGlyphCount = lines.reduce(0){$0 + CTLineGetGlyphCount($1)}
    
    let shift: SIMD2<Float>
    switch(alignment)
    {
    case .center:
      shift = SIMD2<Float>(0.0,0.0)
    case .left:
      shift = SIMD2<Float>(-Float(NSMidX(boundingRect)),0.0)
    case .right:
      shift = SIMD2<Float>(Float(NSMidX(boundingRect)),0.0)
    case .top:
      shift = SIMD2<Float>(0.0,-Float(NSMidY(boundingRect)))
    case .bottom:
      shift = SIMD2<Float>(0.0,Float(NSMidY(boundingRect)))
    case .topLeft:
      shift = SIMD2<Float>(-Float(NSMidX(boundingRect)),-Float(NSMidY(boundingRect)))
    case .topRight:
      shift = SIMD2<Float>(Float(NSMidX(boundingRect)),-Float(NSMidY(boundingRect)))
    case .bottomLeft:
      shift = SIMD2<Float>(-Float(NSMidX(boundingRect)),Float(NSMidY(boundingRect)))
    case .bottomRight:
      shift = SIMD2<Float>(Float(NSMidX(boundingRect)),Float(NSMidY(boundingRect)))
    }
    
    var vertices = [RKInPerInstanceAttributesText](repeating: RKInPerInstanceAttributesText(), count: frameGlyphCount)
    
    var vertex = 0
    var positions: [SIMD4<Float>] = []
    
    
    enumerateGlyphsInFrame(frame: frame) { (glyph: CGGlyph, glyphIndex: Int, glyphBounds: CGRect) in
      let fontIndex = Int(glyph)
      if (fontIndex >= self.glyphDescriptors.count)
      {
        NSLog("Font atlas has no entry corresponding to glyph \(glyphIndex)")
        return
      }
      let glyphInfo = self.glyphDescriptors[fontIndex]
      let minX = Float(glyphBounds.minX)
      let maxX = Float(glyphBounds.maxX)
      let minY = Float(glyphBounds.minY)
      let maxY = Float(glyphBounds.maxY)
      let minS = Float(glyphInfo.topLeftTexCoord.x)
      let maxS = Float(glyphInfo.bottomRightTexCoord.x)
      let minT = Float(glyphInfo.topLeftTexCoord.y)
      let maxT = Float(glyphInfo.bottomRightTexCoord.y)
      
      let position1: SIMD4<Float> = SIMD4<Float>(x: minX , y: maxY, z: 0.0, w: 1.0)
      let position2: SIMD4<Float> = SIMD4<Float>(x: minX , y: minY, z: 0.0, w: 1.0)
      let position3: SIMD4<Float> = SIMD4<Float>(x: maxX , y: minY, z: 0.0, w: 1.0)
      let position4: SIMD4<Float> = SIMD4<Float>(x: maxX , y: maxY, z: 0.0, w: 1.0)
      
      positions.append(position1)
      positions.append(position2)
      positions.append(position3)
      positions.append(position4)
      
      let vertexPosition: SIMD4<Float> = SIMD4<Float>(x: minX, y: maxX, z: minY, w: maxY)
      let st: SIMD4<Float> = SIMD4<Float>(x: minS, y: maxS, z: minT, w: maxT)
      
      vertices[vertex] = RKInPerInstanceAttributesText(position: position, scale: scale, vertexData: vertexPosition, textureCoordinatesData: st)
      vertex += 1
    }
    
    
    let x: [Float] = positions.map{Float($0.x)}
    let y: [Float] = positions.map{Float($0.y)}
    if let minx = x.min(),
      let maxx = x.max(),
      let miny = y.min(),
      let maxy = y.max()
    {
      let center = 0.5*SIMD2<Float>(maxx+minx,maxy+miny)
      //let center = float2(Float(NSMidX(boundingRect) + lineOriginArray[0].x),
      //                    Float(NSMidY(boundingRect) + lineOriginArray[0].y))
      for i in 0..<frameGlyphCount
      {
        vertices[i].vertexCoordinatesData.x -= center.x
        vertices[i].vertexCoordinatesData.y -= center.x
        vertices[i].vertexCoordinatesData.z -= center.y
        vertices[i].vertexCoordinatesData.w -= center.y
        vertices[i].vertexCoordinatesData.x += shift.x
        vertices[i].vertexCoordinatesData.y += shift.x
        vertices[i].vertexCoordinatesData.z += shift.y
        vertices[i].vertexCoordinatesData.w += shift.y
        vertices[i].vertexCoordinatesData.x /= 50.0
        vertices[i].vertexCoordinatesData.y /= 50.0
        vertices[i].vertexCoordinatesData.z /= 50.0
        vertices[i].vertexCoordinatesData.w /= 50.0
      }
    }
    
    return vertices
  }
  
  
  private func enumerateGlyphsInFrame(frame: CTFrame, callback: (CGGlyph, Int, CGRect) -> ())
  {
    let entire = CFRangeMake(0, 0)
    let framePath = CTFrameGetPath(frame)
    let frameBoundingRect = framePath.boundingBox
    let lines: [CTLine]  = CTFrameGetLines(frame) as! [CTLine]
    var lineOriginArray = [CGPoint](repeating: CGPoint(), count: lines.count)
    CTFrameGetLineOrigins(frame, entire, &lineOriginArray)
    var glyphIndexInFrame = 0
    
    let size = NSMakeSize(1, 1);
    let im = NSImage(size: size)
    
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(size.width),
                               pixelsHigh: Int(size.height),
                               bitsPerSample: 8,
                               samplesPerPixel: 4,
                               hasAlpha: true,
                               isPlanar: false,
                               colorSpaceName: NSColorSpaceName.calibratedRGB,
                               bytesPerRow: 0,
                               bitsPerPixel: 0)
    
    im.addRepresentation(rep!)
    im.lockFocus()
    
    let context = NSGraphicsContext.current?.cgContext
    for (i, line) in lines.enumerated()
    {
      let lineOrigin = lineOriginArray[i]
      let runs: [CTRun] = CTLineGetGlyphRuns(line) as! [CTRun]
      
      for run in runs
      {
        let glyphCount = CTRunGetGlyphCount(run)
        var glyphArray = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
        CTRunGetGlyphs(run, entire, &glyphArray)
        var positionArray = [CGPoint](repeating: CGPoint(), count: glyphCount)
        CTRunGetPositions(run, entire, &positionArray)
        for glyphIndex in 0..<glyphCount
        {
          let glyph = glyphArray[glyphIndex]
          let glyphOrigin = positionArray[glyphIndex]
          var glyphRect = CTRunGetImageBounds(run, context, CFRangeMake(glyphIndex, 1))
          let boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
          let boundsTransY = frameBoundingRect.height + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
          let pathTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: boundsTransX, ty: boundsTransY)
          glyphRect = glyphRect.applying(pathTransform)
          callback(glyph, glyphIndexInFrame, glyphRect)
          glyphIndexInFrame += 1
        }
      }
    }
    im.unlockFocus()
  }
  
  private func createTextureData()
  {
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: 0) //[CGBitmapInfo.alphaInfoMask, CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)]
    guard let context = CGContext(data: nil,
                                  width: RKFontAtlas.atlasSize, height: RKFontAtlas.atlasSize, bitsPerComponent: 8,
                                  bytesPerRow: RKFontAtlas.atlasSize, space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
                                    return
    }
    // Generate an atlas image for the font, resizing if necessary to fit in the specified size.
    createAtlasForFont(context: context, font: parentFont, width:RKFontAtlas.atlasSize, height:RKFontAtlas.atlasSize)
    guard let atlasData = context.data?.assumingMemoryBound(to: UInt8.self) else {
      return
    }
    // Create the signed-distance field representation of the font atlas from the rasterized glyph image.
    var distanceField = createSignedDistanceFieldForGrayscaleImage(imageData: atlasData, width: RKFontAtlas.atlasSize, height: RKFontAtlas.atlasSize)
    //let distanceField = [Float](repeating: 1.0, count: FontAtlas.atlasSize * FontAtlas.atlasSize)
    // Downsample the signed-distance field to the expected texture resolution
    let scaleFactor = RKFontAtlas.atlasSize / self.textureSize
    if var scaledField = createResampledData(&distanceField, width: RKFontAtlas.atlasSize, height: RKFontAtlas.atlasSize, scaleFactor: scaleFactor)
    {
      let spread = Float(estimatedLineWidthForFont(parentFont) * 0.5)
      // Quantize the downsampled distance field into an 8-bit grayscale array suitable for use as a texture
      let texData = createQuantizedDistanceField(&scaledField, width: textureSize, height: textureSize, normalizationFactor: spread)
      self.textureData = NSData(bytesNoCopy: texData, length: textureSize*textureSize, freeWhenDone: true)
    }
  }
  
  // MARK: Auxilary routines
  
  private func estimatedLineWidthForFont(_ font: NSFont) -> CGFloat
  {
    let size: CGSize = "!".size(withAttributes: [NSAttributedString.Key.font: font])
    let estimatedStrokeWidth = Float(size.width)
    return CGFloat(ceilf(estimatedStrokeWidth))
  }
  
  private func estimatedGlyphSizeForFont(_ font: NSFont) -> CGSize
  {
    let exemplarString = "{ǺOJMQYZa@jmqyw" as NSString
    let exemplarStringSize = exemplarString.size(withAttributes: [NSAttributedString.Key.font: font ])
    let averageGlyphWidth = ceilf(Float(exemplarStringSize.width) / Float(exemplarString.length))
    let maxGlyphHeight = ceilf(Float(exemplarStringSize.height))
    return CGSize(width: CGFloat(averageGlyphWidth), height: CGFloat(maxGlyphHeight))
  }
  
  private func pointSizeThatFitsForFont(_ font: NSFont, rect: CGRect) -> Float
  {
    var fittedSize = Float(font.pointSize)
    while isLikelyToFit(font: font, size: CGFloat(fittedSize), rect: rect)
    {
      fittedSize += 1
    }
    while !isLikelyToFit(font: font, size: CGFloat(fittedSize), rect: rect)
    {
      fittedSize -= 1
    }
    return fittedSize
  }
  
  private func isLikelyToFit(font: NSFont, size: CGFloat, rect: CGRect) -> Bool
  {
    let textureArea = rect.size.width * rect.size.height
    guard let trialFont = NSFont(name: font.fontName, size: size) else {
      return false
    }
    let trialCTFont = CTFontCreateWithName(font.fontName as CFString, size, nil)
    let fontGlyphCount = CTFontGetGlyphCount(trialCTFont)
    let glyphMargin = self.estimatedLineWidthForFont(trialFont)
    let averageGlyphSize = self.estimatedGlyphSizeForFont(trialFont)
    let estimatedGlyphTotalArea = (averageGlyphSize.width + glyphMargin) * (averageGlyphSize.height + glyphMargin) * CGFloat(fontGlyphCount)
    return (estimatedGlyphTotalArea < textureArea)
  }
  
  private func createAtlasForFont(context: CGContext, font: NSFont, width: Int, height: Int)
  {
    // Turn off antialiasing so we only get fully-on or fully-off pixels.
    // This implicitly disables subpixel antialiasing and hinting.
    context.setAllowsAntialiasing(false)
    // Flip context coordinate space so y increases downward
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)

    // Fill the context with an opaque black color
    context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
    let fullRect = CGRect(x: 0, y: 0, width: width, height: height)
    context.fill(fullRect)
    
    fontPointSize = CGFloat(pointSizeThatFitsForFont(font, rect:CGRect(x: 0, y: 0, width: width, height: height)))
    let ctFont = CTFontCreateWithName(font.fontName as CFString, CGFloat(fontPointSize), nil)
    guard let parentFont = NSFont(name: font.fontName, size: CGFloat(fontPointSize)) else {
      // should throw an exception
      return
    }
    let fontGlyphCount = CTFontGetGlyphCount(ctFont)
    let glyphMargin = estimatedLineWidthForFont(parentFont)
    // Set fill color so that glyphs are solid white
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    glyphDescriptors.removeAll()
    let fontAscent = CTFontGetAscent(ctFont)
    let fontDescent = CTFontGetDescent(ctFont)
    var origin = CGPoint(x: 0, y: fontAscent)
    var maxYCoordForLine :CGFloat = -1
    
    for i in 0..<fontGlyphCount
    {
      var glyph = CGGlyph(i)
      var boundingRect = CGRect()
      CTFontGetBoundingRectsForGlyphs(ctFont, CTFontOrientation.horizontal, &glyph, &boundingRect, 1)
      if origin.x + boundingRect.maxX + glyphMargin > CGFloat(width)
      {
        origin.x = 0
        origin.y = maxYCoordForLine + glyphMargin + fontDescent
        maxYCoordForLine = -1
      }
      if origin.y + boundingRect.maxY > maxYCoordForLine
      {
        maxYCoordForLine = origin.y + boundingRect.maxY
      }
      let glyphOriginX = origin.x - boundingRect.origin.x + 0.5 * glyphMargin
      let glyphOriginY = origin.y + glyphMargin * 0.5
      var glyphTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: glyphOriginX, ty: glyphOriginY)
      let path = CTFontCreatePathForGlyph(ctFont, glyph, &glyphTransform) ?? CGPath(rect: CGRect.null, transform: nil)
      context.addPath(path)
      context.fillPath()
      var glyphPathBoundingRect = path.boundingBox
      // The null rect (i.e., the bounding rect of an empty path) is problematic
      // because it has its origin at (+inf, +inf); we fix that up here
      if glyphPathBoundingRect.equalTo(CGRect.null) {
        glyphPathBoundingRect = CGRect.zero
      }
      let texCoordLeft = glyphPathBoundingRect.origin.x / CGFloat(width)
      let texCoordRight = (glyphPathBoundingRect.origin.x + glyphPathBoundingRect.size.width) / CGFloat(width)
      let texCoordTop = (glyphPathBoundingRect.origin.y) / CGFloat(height)
      let texCoordBottom = (glyphPathBoundingRect.origin.y + glyphPathBoundingRect.size.height) / CGFloat(height)
      let descriptor = GlyphDescriptor(
        glyphIndex: glyph,
        topLeftTexCoord: CGPoint(x: texCoordLeft, y: texCoordTop),
        bottomRightTexCoord: CGPoint(x: texCoordRight, y: texCoordBottom))
      glyphDescriptors.append(descriptor)
      origin.x += boundingRect.width + glyphMargin
    }
  }
  
  /// Compute signed-distance field for an 8-bpp grayscale image (values greater than 127 are considered "on")
  /// For details of this algorithm, see "The 'dead reckoning' signed distance transform" [Grevera 2004]
  private func createSignedDistanceFieldForGrayscaleImage(imageData: UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> [Float]
  {
    let maxDist = hypot(Float(width), Float(height))
    // Initialization phase
    let count = width * height
    // distance to nearest boundary point map - set all distances to "infinity"
    var distanceMap = [Float](repeating: maxDist, count: count)
  
    // nearest boundary point map - zero out nearest boundary point map
    var boundaryPointMap = [SIMD2<Int32>](repeating: SIMD2<Int32>(0,0), count: count)
    let distUnit :Float = 1
    let distDiag :Float = sqrtf(2)
    // Immediate interior/exterior phase: mark all points along the boundary as such
    for y in 1..<(height-1)
    {
      for x in 1..<(width-1)
      {
        let inside = imageData[y * width + x] > 0x7f
        if (imageData[y * width + x - 1] > 0x7f) != inside
          || (imageData[y * width + x + 1] > 0x7f) != inside
          || (imageData[(y - 1) * width + x] > 0x7f) != inside
          || (imageData[(y + 1) * width + x] > 0x7f) != inside
        {
          distanceMap[y * width + x] = 0
          boundaryPointMap[y * width + x].x = Int32(x)
          boundaryPointMap[y * width + x].y = Int32(y)
        }
      }
    }
    // Forward dead-reckoning pass
    for y in 1..<(height-2)
    {
      for x in 1..<(width-2)
      {
        var d = distanceMap[y * width + x]
        var n = boundaryPointMap[y * width + x]
        if distanceMap[(y - 1) * width + x - 1] + distDiag < d
        {
          n = boundaryPointMap[(y - 1) * width + (x - 1)]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
        if distanceMap[(y - 1) * width + x] + distUnit < d {
          n = boundaryPointMap[(y - 1) * width + x]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
        if distanceMap[(y - 1) * width + x + 1] + distDiag < d {
          n = boundaryPointMap[(y - 1) * width + (x + 1)]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
        if distanceMap[y * width + x - 1] + distUnit < d {
          n = boundaryPointMap[y * width + (x - 1)]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
      }
    }
    // Backward dead-reckoning pass
    for y in (1...(height-2)).reversed()
    {
      for x in (1...(width-2)).reversed()
      {
        var d = distanceMap[y * width + x]
        var n = boundaryPointMap[y * width + x]
        if distanceMap[y * width + x + 1] + distUnit < d
        {
          n = boundaryPointMap[y * width + x + 1]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
        if distanceMap[(y + 1) * width + x - 1] + distDiag < d
        {
          n = boundaryPointMap[(y + 1) * width + x - 1]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
        if distanceMap[(y + 1) * width + x] + distUnit < d
        {
          n = boundaryPointMap[(y + 1) * width + x]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
        if distanceMap[(y + 1) * width + x + 1] + distDiag < d
        {
          n = boundaryPointMap[(y + 1) * width + x + 1]
          d = hypot(Float(x) - Float(n.x), Float(y) - Float(n.y))
          boundaryPointMap[y * width + x] = n
          distanceMap[y * width + x] = d
        }
      }
    }
    // Interior distance negation pass; distances outside the figure are considered negative
    for y in 0..<height
    {
      for x in 0..<width
      {
        if imageData[y * width + x] <= 0x7f
        {
          distanceMap[y * width + x] = -distanceMap[y * width + x]
        }
      }
    }
    return distanceMap
  }
  
  private func createResampledData(_ inData: UnsafeMutablePointer<Float>, width: Int, height: Int, scaleFactor: Int) -> [Float]?
  {
    if width % scaleFactor != 0 || height % scaleFactor != 0
    {
      // Scale factor does not evenly divide width and height of source distance field
      //throw FontAtlasError.UnsupportedTextureSize
      return nil
    }
    let scaledWidth = width / scaleFactor
    let scaledHeight = height / scaleFactor
    let count = scaledWidth * scaledHeight
    var outData = [Float](repeating: 0.0, count: count)
    for y in stride(from: 0, to: height, by: scaleFactor)
    {
      for x in stride(from: 0, to: width, by: scaleFactor)
      {
        var accum :Float = 0
        for ky in 0..<scaleFactor
        {
          for kx in 0..<scaleFactor
          {
            accum += inData[(y + ky) * width + (x + kx)]
          }
        }
        accum = accum / Float(scaleFactor * scaleFactor)
        outData[(y / scaleFactor) * scaledWidth + (x / scaleFactor)] = accum
      }
    }
    return outData
  }
  
  private func createQuantizedDistanceField(_ inData: UnsafeMutablePointer<Float>, width: Int, height: Int, normalizationFactor: Float) -> UnsafeMutablePointer<UInt8>
  {
    let count = width * height
    let outData = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
    outData.initialize(repeating: 0, count: count)
    for y in 0..<height
    {
      for x in 0..<width
      {
        let dist = inData[y * width + x]
        let clampDist = fmaxf(-normalizationFactor, fminf(dist, normalizationFactor))
        let scaledDist = clampDist / normalizationFactor
        let value = ((scaledDist + 1) / 2) * Float(UInt8.max)
        outData[y * width + x] = UInt8(value)
      }
    }
    return outData
  }
}
