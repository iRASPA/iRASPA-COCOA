/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd

/// Sub-range within a ribbon index buffer for one chain / segment / residue draw call.
public struct RKRibbonChainDrawRange
{
  public var indexStart: Int
  public var indexCount: Int
  
  public init(indexStart: Int, indexCount: Int)
  {
    self.indexStart = indexStart
    self.indexCount = indexCount
  }
}

public struct RKRibbonMesh
{
  public static let subdivisionsPerSegment: Int = 24
  /// Lightmap strip height (matches RibbonRendering 2048×32 atlas).
  public static let lightmapStripHeight: Int = 32
  public static let lightmapWidth: Int = 2048
  
  public var vertices: [RKVertex] = []
  public var indices: [UInt32] = []
  public var chainDrawRanges: [RKRibbonChainDrawRange] = []
  /// Sub-ranges within `indices` for each secondary-structure segment (N→C, all chains).
  public var segmentDrawRanges: [RKRibbonChainDrawRange] = []
  /// Sub-ranges within `indices` for each Cα residue (N→C, all chains).
  public var residueDrawRanges: [RKRibbonChainDrawRange] = []
  /// Cα atom tags aligned 1:1 with `segmentDrawRanges` (survives tree rebuilds better than indices alone).
  public var segmentAlphaCarbonTags: [Int] = []
  /// Cα atom tags aligned 1:1 with `residueDrawRanges`.
  public var residueAlphaCarbonTags: [Int] = []
  public var chainSplineSampleCounts: [Int] = []
  
  public var numberOfChains: Int
  {
    return chainDrawRanges.count
  }
  
  public var maxSplineSampleCount: Int
  {
    return chainSplineSampleCounts.max() ?? 1
  }
  
  public var numberOfRings: Int
  {
    return maxSplineSampleCount
  }
  
  /// Parametric lightmap atlas: U = arc-length along spline, V = arc-length around cross-section (per chain strip).
  /// Width is limited by spline sample count and by the same atom-count tiers used for atom AO.
  public static func ambientOcclusionAtlasDimensions(maxSplineSampleCount: Int,
                                                     numberOfChains: Int,
                                                     numberOfAtoms: Int,
                                                     maxTextureDimension: Int = 16384) -> (width: Int, height: Int, stripHeight: Int)
  {
    let stripHeight: Int = lightmapStripHeight
    let alignedRingCount: Int = max(maxSplineSampleCount - 1, 1)
    let ringBasedWidth: Int = ((alignedRingCount + 127) / 128) * 128
    let atomCap: Int = RKAmbientOcclusionSizing.maxTextureSize(numberOfAtoms: numberOfAtoms,
                                                               maxTextureDimension: maxTextureDimension)
    let width: Int = min(maxTextureDimension, max(256, min(atomCap, ringBasedWidth)))
    let height: Int = min(maxTextureDimension, max(stripHeight, stripHeight * max(numberOfChains, 1)))
    return (width, height, stripHeight)
  }
  
  public init()
  {
  }
  
  public init(vertices: [RKVertex], indices: [UInt32], chainDrawRanges: [RKRibbonChainDrawRange])
  {
    self.vertices = vertices
    self.indices = indices
    self.chainDrawRanges = chainDrawRanges
  }
  
  /// Merges contiguous or overlapping visible ranges into fewer Metal draw calls.
  /// Residue/segment ribbon ranges intentionally overlap by one ring pair at boundaries.
  public static func mergedVisibleDrawRanges(_ ranges: [RKRibbonChainDrawRange],
                                             visible: [Bool]) -> [RKRibbonChainDrawRange]
  {
    precondition(visible.count == ranges.count)
    var merged: [RKRibbonChainDrawRange] = []
    merged.reserveCapacity(ranges.count)
    
    var currentStart: Int? = nil
    var currentEnd: Int = 0
    
    for index in 0..<ranges.count
    {
      let range: RKRibbonChainDrawRange = ranges[index]
      guard visible[index], range.indexCount > 0 else
      {
        if let start: Int = currentStart
        {
          merged.append(RKRibbonChainDrawRange(indexStart: start, indexCount: currentEnd - start))
          currentStart = nil
        }
        continue
      }
      
      let rangeEnd: Int = range.indexStart + range.indexCount
      if currentStart != nil, range.indexStart <= currentEnd
      {
        currentEnd = max(currentEnd, rangeEnd)
      }
      else
      {
        if let start: Int = currentStart
        {
          merged.append(RKRibbonChainDrawRange(indexStart: start, indexCount: currentEnd - start))
        }
        currentStart = range.indexStart
        currentEnd = rangeEnd
      }
    }
    
    if let start: Int = currentStart
    {
      merged.append(RKRibbonChainDrawRange(indexStart: start, indexCount: currentEnd - start))
    }
    return merged
  }
}
