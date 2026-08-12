/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation

/// IEEE 754 binary16 ↔ Float32 without Swift `Float16` (not available on all macOS deployment targets).
enum RKHalfFloat
{
  static func float(fromHalfBits half: UInt16) -> Float
  {
    let sign: UInt32 = UInt32(half & 0x8000) << 16
    let exponent: UInt32 = UInt32((half >> 10) & 0x1F)
    let mantissa: UInt32 = UInt32(half & 0x03FF)
    
    if exponent == 0
    {
      if mantissa == 0
      {
        return Float(bitPattern: sign)
      }
      var normalizedMantissa: UInt32 = mantissa
      var shift: UInt32 = 0
      while (normalizedMantissa & 0x0400) == 0
      {
        normalizedMantissa <<= 1
        shift += 1
      }
      normalizedMantissa &= 0x03FF
      let floatExponent: UInt32 = 127 - 15 - shift + 1
      return Float(bitPattern: sign | (floatExponent << 23) | (normalizedMantissa << 13))
    }
    
    if exponent == 31
    {
      if mantissa == 0
      {
        return Float(bitPattern: sign | 0x7F80_0000)
      }
      return Float(bitPattern: sign | 0x7F80_0000 | (mantissa << 13))
    }
    
    let floatExponent: UInt32 = exponent + 112
    return Float(bitPattern: sign | (floatExponent << 23) | (mantissa << 13))
  }
  
  static func halfBits(from value: Float) -> UInt16
  {
    let bits: UInt32 = value.bitPattern
    var half: UInt16 = UInt16((bits >> 16) & 0x8000)
    let exponent: Int = Int((bits >> 23) & 0xFF)
    var mantissa: UInt32 = bits & 0x007F_FFFF
    
    if exponent == 255
    {
      if mantissa != 0
      {
        return half | 0x7E00
      }
      return half | 0x7C00
    }
    
    var halfExponent: Int = exponent - 127 + 15
    if halfExponent >= 31
    {
      return half | 0x7C00
    }
    if halfExponent <= 0
    {
      if halfExponent < -10
      {
        return half
      }
      mantissa |= 0x0080_0000
      let shift: Int = 1 - halfExponent
      mantissa >>= UInt32(shift)
      return half | UInt16(mantissa >> 13)
    }
    
    return half | UInt16(halfExponent << 10) | UInt16(mantissa >> 13)
  }
}

/// Post-processing for ribbon lightmaps (matches ands/lightmapper lmImageDilate + lmImageSmooth).
enum RibbonAOTexturePostProcess
{
  static func dilateAndSmooth(_ data: inout [Float], width: Int, height: Int, smoothPasses: Int = 2)
  {
    guard width > 0, height > 0, data.count >= width * height else {return}
    
    var dilated: [Float] = data
    dilate(&dilated, width: width, height: height)
    dilate(&dilated, width: width, height: height)
    
    var current: [Float] = dilated
    var scratch: [Float] = Array(repeating: 0.0, count: width * height)
    for _ in 0..<max(smoothPasses, 1)
    {
      smooth(current, into: &scratch, width: width, height: height)
      swap(&current, &scratch)
    }
    // One extra U-axis pass softens ring-column banding on beta sheets without touching render sampling.
    smoothAlongStrand(current, into: &scratch, width: width, height: height, radius: 4)
    swap(&current, &scratch)
    data = current
  }
  
  private static func dilate(_ data: inout [Float], width: Int, height: Int)
  {
    let source: [Float] = data
    let offsets: [(Int, Int)] = [(-1, 0), (0, 1), (1, 0), (0, -1)]
    
    for y in 0..<height
    {
      for x in 0..<width
      {
        let index: Int = y * width + x
        if source[index] > 0.0
        {
          continue
        }
        
        var sum: Float = 0.0
        var count: Int = 0
        for offset in offsets
        {
          let neighborX: Int = x + offset.0
          let neighborY: Int = y + offset.1
          guard neighborX >= 0, neighborX < width, neighborY >= 0, neighborY < height else {continue}
          let neighborValue: Float = source[neighborY * width + neighborX]
          if neighborValue > 0.0
          {
            sum += neighborValue
            count += 1
          }
        }
        if count > 0
        {
          data[index] = sum / Float(count)
        }
      }
    }
  }
  
  private static func smooth(_ source: [Float], into data: inout [Float], width: Int, height: Int)
  {
    for y in 0..<height
    {
      for x in 0..<width
      {
        let centerIndex: Int = y * width + x
        let centerValue: Float = source[centerIndex]
        if centerValue <= 0.0
        {
          data[centerIndex] = 0.0
          continue
        }
        
        var sum: Float = centerValue * 2.0
        var weight: Float = 2.0
        for dy in -1...1
        {
          for dx in -1...1
          {
            if dx == 0 && dy == 0 {continue}
            let neighborX: Int = x + dx
            let neighborY: Int = y + dy
            guard neighborX >= 0, neighborX < width, neighborY >= 0, neighborY < height else {continue}
            let neighborValue: Float = source[neighborY * width + neighborX]
            if neighborValue > 0.0
            {
              sum += neighborValue
              weight += 1.0
            }
          }
        }
        data[centerIndex] = sum / weight
      }
    }
  }
  
  /// 1D smooth along atlas U (strand length). Same rules as `smooth`: only non-zero texels are updated.
  private static func smoothAlongStrand(_ source: [Float], into data: inout [Float], width: Int, height: Int, radius: Int)
  {
    for y in 0..<height
    {
      for x in 0..<width
      {
        let centerIndex: Int = y * width + x
        let centerValue: Float = source[centerIndex]
        if centerValue <= 0.0
        {
          data[centerIndex] = 0.0
          continue
        }
        
        var sum: Float = centerValue * 2.0
        var weight: Float = 2.0
        for dx in (-radius)...radius
        {
          if dx == 0 {continue}
          let neighborX: Int = x + dx
          guard neighborX >= 0, neighborX < width else {continue}
          let neighborValue: Float = source[y * width + neighborX]
          if neighborValue > 0.0
          {
            sum += neighborValue
            weight += 1.0
          }
        }
        data[centerIndex] = sum / weight
      }
    }
  }
}
