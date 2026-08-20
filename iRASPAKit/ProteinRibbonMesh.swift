/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
import SymmetryKit
import RenderKit

public struct ProteinRibbonMeshBuilder
{
  struct RibbonStation
  {
    var center: SIMD3<Double>
    var tangent: SIMD3<Double>
    var faceNormal: SIMD3<Double>
    var widthDirection: SIMD3<Double>
    var secondaryStructure: ProteinRibbonSecondaryStructure
    var sheetArrowFactor: Double
    var sheetArrowWidthFactor: Double
    var residuePosition: Double
  }
  
  struct CrossSectionProfile
  {
    var widthClamp: Double
    var radiusScale: Double
    var normalScale: Double
    /// PyMOL ExtrudeRectangle for sheets/arrows; oval clamp for helices.
    var rectangular: Bool
  }
  
  private struct RibbonBackboneSample
  {
    var center: SIMD3<Double>
    var nitrogen: SIMD3<Double>?
    var carbonylCarbon: SIMD3<Double>?
    var carbonylOxygen: SIMD3<Double>?
  }
  
  /// Two consecutive alpha carbons further apart than this are not joined by a peptide bond:
  /// the residues between them are missing from the file. Assigners use the same 4.5 Å cutoff.
  private static let chainBreakAlphaCarbonDistance: Double = 4.5
  
  public static func build(from backbone: ProteinBackbone,
                           radius: Double,
                           contentShift: SIMD3<Double>,
                           parameters: ProteinRibbonMeshParameters = .default,
                           secondaryStructureMethod: ProteinRibbonSecondaryStructureMethod = .stride) -> RKRibbonMesh
  {
    let meshParameters: ProteinRibbonMeshParameters = parameters.clamped
    
    // A fragment is one continuous run of residues. An unbroken chain is a single fragment;
    // a broken one is swept once per run so the ribbon stops at the gap.
    struct FragmentStationData
    {
      var chain: ProteinBackboneChain
      var stations: [RibbonStation]
      var residueSegments: [ProteinRibbonResidueSegment]
      var chainSlot: Int
    }
    
    var fragments: [FragmentStationData] = []
    var chainRingTotals: [Int] = []
    
    for chain in backbone.chains
    {
      let traced: ProteinBackboneChain = tracedResidues(chain)
      // Assign over the whole chain (breaks included). Assigners handle breaks themselves;
      // assigning per fragment would hide that the residues are related.
      let secondaryStructure: [ProteinRibbonSecondaryStructure] = ProteinRibbonSecondaryStructureAssigner.assign(for: traced,
                                                                                                                   contentShift: contentShift,
                                                                                                                   method: secondaryStructureMethod)
      
      var chainFragments: [FragmentStationData] = []
      var chainRings: Int = 0
      for range in continuousResidueRanges(traced)
      {
        let first: Int = range.lowerBound
        let last: Int = min(range.upperBound, secondaryStructure.count)
        guard last > first else {continue}
        
        let fragmentChain: ProteinBackboneChain = ProteinBackboneChain(chainIdentifier: traced.chainIdentifier,
                                                                       residues: Array(traced.residues[first..<last]))
        let fragmentStructure: [ProteinRibbonSecondaryStructure] = Array(secondaryStructure[first..<last])
        let residueSegments: [ProteinRibbonResidueSegment] = ProteinRibbonSegmentSupport.residueSegments(from: fragmentStructure,
                                                                                                           chainIdentifier: fragmentChain.chainIdentifier)
        let stations: [RibbonStation] = ribbonStations(for: fragmentChain,
                                                       contentShift: contentShift,
                                                       secondaryStructure: fragmentStructure,
                                                       parameters: meshParameters)
        guard stations.count >= 2 else {continue}
        
        chainRings += stations.count
        chainFragments.append(FragmentStationData(chain: fragmentChain,
                                                  stations: stations,
                                                  residueSegments: residueSegments,
                                                  chainSlot: chainRingTotals.count))
      }
      
      guard !chainFragments.isEmpty else {continue}
      chainRingTotals.append(chainRings)
      fragments.append(contentsOf: chainFragments)
    }
    
    return extrudeRibbonMesh(fragments: fragments.map
    {
      (chain: $0.chain, stations: $0.stations, residueSegments: $0.residueSegments, chainSlot: $0.chainSlot)
    },
                             chainRingTotals: chainRingTotals,
                             radius: radius,
                             ringResolution: meshParameters.crossSectionRingResolution,
                             parameters: meshParameters)
  }
  
  private static func extrudeRibbonMesh(fragments: [(chain: ProteinBackboneChain,
                                                     stations: [RibbonStation],
                                                     residueSegments: [ProteinRibbonResidueSegment],
                                                     chainSlot: Int)],
                                        chainRingTotals: [Int],
                                        radius: Double,
                                        ringResolution: Int,
                                        parameters: ProteinRibbonMeshParameters) -> RKRibbonMesh
  {
    var mesh: RKRibbonMesh = RKRibbonMesh()
    let totalChains: Int = max(chainRingTotals.count, 1)
    var currentSlot: Int = 0
    var haveSlot: Bool = false
    var slotIndexStart: Int = 0
    var ringOffset: Int = 0
    
    for fragment in fragments
    {
      if !haveSlot || fragment.chainSlot != currentSlot
      {
        if haveSlot
        {
          mesh.chainDrawRanges.append(RKRibbonChainDrawRange(indexStart: slotIndexStart,
                                                             indexCount: mesh.indices.count - slotIndexStart))
          mesh.chainSplineSampleCounts.append(chainRingTotals[currentSlot])
        }
        currentSlot = fragment.chainSlot
        haveSlot = true
        slotIndexStart = mesh.indices.count
        ringOffset = 0
      }
      
      let indexStart: Int = mesh.indices.count
      let vertexBase: Int = mesh.vertices.count
      let built: (vertices: [RKVertex], indices: [UInt32]) = ringMesh(stations: fragment.stations,
                                                                     radius: radius,
                                                                     chainIndex: fragment.chainSlot,
                                                                     totalChains: totalChains,
                                                                     ringResolution: ringResolution,
                                                                     parameters: parameters,
                                                                     ringOffsetWithinChain: ringOffset,
                                                                     chainRingTotal: chainRingTotals[fragment.chainSlot])
      mesh.vertices.append(contentsOf: built.vertices)
      if vertexBase == 0
      {
        mesh.indices.append(contentsOf: built.indices)
      }
      else
      {
        mesh.indices.reserveCapacity(mesh.indices.count + built.indices.count)
        let base: UInt32 = UInt32(vertexBase)
        for localIndex in built.indices
        {
          mesh.indices.append(base &+ localIndex)
        }
      }
      appendSegmentDrawRanges(for: fragment.chain,
                              stations: fragment.stations,
                              chainIndexStart: indexStart,
                              residueSegments: fragment.residueSegments,
                              ringResolution: ringResolution,
                              mesh: &mesh)
      appendResidueDrawRanges(for: fragment.chain,
                              stations: fragment.stations,
                              chainIndexStart: indexStart,
                              ringResolution: ringResolution,
                              mesh: &mesh)
      ringOffset += fragment.stations.count
    }
    if haveSlot
    {
      mesh.chainDrawRanges.append(RKRibbonChainDrawRange(indexStart: slotIndexStart,
                                                         indexCount: mesh.indices.count - slotIndexStart))
      mesh.chainSplineSampleCounts.append(chainRingTotals[currentSlot])
    }
    
    applyPickingIndices(mesh: &mesh)
    applyRibbonStripeCoordinates(mesh: &mesh)
    return mesh
  }
  
  /// Residues that are traced, in file order (only those with an alpha carbon).
  private static func tracedResidues(_ chain: ProteinBackboneChain) -> ProteinBackboneChain
  {
    return ProteinBackboneChain(chainIdentifier: chain.chainIdentifier,
                                residues: chain.residues.filter{$0.alphaCarbon != nil})
  }
  
  /// Half-open continuous residue ranges, split wherever consecutive Cα distance exceeds 4.5 Å.
  private static func continuousResidueRanges(_ traced: ProteinBackboneChain) -> [Range<Int>]
  {
    guard !traced.residues.isEmpty else {return []}
    var ranges: [Range<Int>] = []
    var start: Int = 0
    for index in 1..<traced.residues.count
    {
      guard let previous: SKAsymmetricAtom = traced.residues[index - 1].alphaCarbon,
            let current: SKAsymmetricAtom = traced.residues[index].alphaCarbon else {continue}
      if length(current.position - previous.position) > chainBreakAlphaCarbonDistance
      {
        ranges.append(start..<index)
        start = index
      }
    }
    ranges.append(start..<traced.residues.count)
    return ranges
  }
  
  /// Fills stripeST.x with arc-length fraction along each residue span (0–1); stripeST.y is set during mesh generation.
  static func applyRibbonStripeCoordinates(mesh: inout RKRibbonMesh)
  {
    for drawRange in mesh.residueDrawRanges
    {
      guard drawRange.indexCount > 0 else {continue}
      let end: Int = drawRange.indexStart + drawRange.indexCount
      var minU: Float = Float.greatestFiniteMagnitude
      var maxU: Float = -Float.greatestFiniteMagnitude
      for indexOffset in drawRange.indexStart..<end
      {
        let vertexIndex: Int = Int(mesh.indices[indexOffset])
        let alongChain: Float = mesh.vertices[vertexIndex].st.x
        minU = min(minU, alongChain)
        maxU = max(maxU, alongChain)
      }
      let span: Float = max(maxU - minU, 1.0e-6)
      for indexOffset in drawRange.indexStart..<end
      {
        let vertexIndex: Int = Int(mesh.indices[indexOffset])
        let alongChain: Float = mesh.vertices[vertexIndex].st.x
        mesh.vertices[vertexIndex].stripeST.x = (alongChain - minU) / span
      }
    }
  }
  
  /// Writes global segment and residue draw-range indices into each vertex for ribbon picking.
  static func applyPickingIndices(mesh: inout RKRibbonMesh)
  {
    for (segmentIndex, drawRange) in mesh.segmentDrawRanges.enumerated()
    {
      guard drawRange.indexCount > 0 else {continue}
      let end: Int = drawRange.indexStart + drawRange.indexCount
      for indexOffset in drawRange.indexStart..<end
      {
        let vertexIndex: Int = Int(mesh.indices[indexOffset])
        mesh.vertices[vertexIndex].normal.w = Float(segmentIndex)
      }
    }
    for (residueIndex, drawRange) in mesh.residueDrawRanges.enumerated()
    {
      guard drawRange.indexCount > 0 else {continue}
      let end: Int = drawRange.indexStart + drawRange.indexCount
      for indexOffset in drawRange.indexStart..<end
      {
        let vertexIndex: Int = Int(mesh.indices[indexOffset])
        mesh.vertices[vertexIndex].pad.y = Float(residueIndex)
      }
    }
  }
  
  private static func alphaCarbonsOfChain(_ chain: ProteinBackboneChain) -> [SKAsymmetricAtom]
  {
    return chain.residues.compactMap{$0.alphaCarbon}
  }
  
  private static func alphaCarbonTag(_ alphaCarbons: [SKAsymmetricAtom], residueIndex: Int) -> Int
  {
    guard residueIndex >= 0 && residueIndex < alphaCarbons.count else {return -1}
    return alphaCarbons[residueIndex].tag
  }
  
  static func appendResidueDrawRanges(for chain: ProteinBackboneChain,
                                              stations: [RibbonStation],
                                              chainIndexStart: Int,
                                              ringResolution: Int,
                                              mesh: inout RKRibbonMesh)
  {
    guard stations.count >= 2 else {return}
    
    let alphaCarbons: [SKAsymmetricAtom] = alphaCarbonsOfChain(chain)
    let residueCount: Int = alphaCarbons.count
    guard residueCount > 0 else {return}
    
    let indicesPerRingPair: Int = ringResolution * 6
    var residueStarts: [Int?] = Array(repeating: nil, count: residueCount)
    var residueEnds: [Int?] = Array(repeating: nil, count: residueCount)
    
    for (stationIndex, station) in stations.enumerated()
    {
      let residueIndex: Int = Int(round(station.residuePosition))
      guard residueIndex >= 0 && residueIndex < residueCount else {continue}
      if residueStarts[residueIndex] == nil
      {
        residueStarts[residueIndex] = stationIndex
      }
      residueEnds[residueIndex] = stationIndex
    }
    
    for residueIndex in 0..<residueCount
    {
      guard let startRing: Int = residueStarts[residueIndex],
            let endRing: Int = residueEnds[residueIndex],
            endRing > startRing else {continue}
      
      var drawEndRing: Int = endRing
      if residueIndex + 1 < residueCount
      {
        drawEndRing = min(stations.count - 1, endRing + 1)
      }
      
      mesh.residueDrawRanges.append(RKRibbonChainDrawRange(indexStart: chainIndexStart + startRing * indicesPerRingPair,
                                                           indexCount: (drawEndRing - startRing) * indicesPerRingPair))
      mesh.residueAlphaCarbonTags.append(alphaCarbonTag(alphaCarbons, residueIndex: residueIndex))
    }
  }
  
  static func appendSegmentDrawRanges(for chain: ProteinBackboneChain,
                                              stations: [RibbonStation],
                                              chainIndexStart: Int,
                                              residueSegments: [ProteinRibbonResidueSegment],
                                              ringResolution: Int,
                                              mesh: inout RKRibbonMesh)
  {
    guard stations.count >= 2 else {return}
    guard !residueSegments.isEmpty else {return}
    
    let alphaCarbons: [SKAsymmetricAtom] = alphaCarbonsOfChain(chain)
    let indicesPerRingPair: Int = ringResolution * 6
    let residueCount: Int = alphaCarbons.count
    var residueToSegment: [Int] = Array(repeating: -1, count: max(residueCount, 1))
    for (segmentIndex, segment) in residueSegments.enumerated()
    {
      let lower: Int = max(0, segment.firstResidueIndex)
      let upper: Int = min(residueCount - 1, segment.lastResidueIndex)
      guard lower <= upper else {continue}
      for residueIndex in lower...upper
      {
        residueToSegment[residueIndex] = segmentIndex
      }
    }
    
    var segmentStarts: [Int?] = Array(repeating: nil, count: residueSegments.count)
    var segmentEnds: [Int?] = Array(repeating: nil, count: residueSegments.count)
    
    for (stationIndex, station) in stations.enumerated()
    {
      let residueIndex: Int = Int(round(station.residuePosition))
      guard residueIndex >= 0 && residueIndex < residueToSegment.count else {continue}
      let segmentIndex: Int = residueToSegment[residueIndex]
      guard segmentIndex >= 0 else {continue}
      if segmentStarts[segmentIndex] == nil
      {
        segmentStarts[segmentIndex] = stationIndex
      }
      segmentEnds[segmentIndex] = stationIndex
    }
    
    for (segmentIndex, segment) in residueSegments.enumerated()
    {
      guard let startRing: Int = segmentStarts[segmentIndex],
            let endRing: Int = segmentEnds[segmentIndex],
            endRing > startRing else {continue}
      
      var drawEndRing: Int = endRing
      if segmentIndex + 1 < residueSegments.count
      {
        drawEndRing = min(stations.count - 1, endRing + 1)
      }
      
      mesh.segmentDrawRanges.append(RKRibbonChainDrawRange(indexStart: chainIndexStart + startRing * indicesPerRingPair,
                                                           indexCount: (drawEndRing - startRing) * indicesPerRingPair))
      mesh.segmentAlphaCarbonTags.append(alphaCarbonTag(alphaCarbons, residueIndex: segment.firstResidueIndex))
    }
  }
  
  private static func ribbonStations(for chain: ProteinBackboneChain,
                                     contentShift: SIMD3<Double>,
                                     secondaryStructure: [ProteinRibbonSecondaryStructure],
                                     parameters: ProteinRibbonMeshParameters) -> [RibbonStation]
  {
    let residues: [ProteinBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}
    guard residues.count >= 2 else {return []}
    
    let samples: [RibbonBackboneSample] = ribbonBackboneSamples(for: residues, contentShift: contentShift)
    var centers: [SIMD3<Double>] = samples.map{$0.center}
    var orientationVectors: [SIMD3<Double>] = computeCartoonOrientationVectors(samples: samples)
    let directionNormals: [SIMD3<Double>] = computeChainDirectionNormals(centers: centers)
    let chainTangents: [SIMD3<Double>] = computeChainTangents(directionNormals: directionNormals)
    computeRoundHelices(orientations: &orientationVectors,
                        centers: centers,
                        tangents: chainTangents,
                        secondaryStructure: secondaryStructure)
    refineCartoonOrientationNormals(orientations: &orientationVectors,
                                    tangents: chainTangents,
                                    secondaryStructure: secondaryStructure)
    // PyMOL cartoon_flat_sheets: tauten β-strands by averaging Cα and orientations.
    flattenCartoonSheets(centers: &centers,
                         orientations: &orientationVectors,
                         secondaryStructure: secondaryStructure,
                         cycles: parameters.normalSmoothingRadius)
    
    let path: any ProteinRibbonCenterlinePath
    switch parameters.splineType
    {
    case .bSpline:
      path = ProteinBSpline(controlPoints: centers,
                            orientationVectors: orientationVectors,
                            degree: 3)
    case .catmullRom:
      path = ProteinCatmullRomSpline(controlPoints: centers,
                                     orientationVectors: orientationVectors)
    }
    
    let totalLength: Double = path.arcLength(1.0)
    let subdivisionsPerSegment: Int = parameters.subdivisionsPerSegment
    
    let sampleCount: Int = (centers.count - 1) * subdivisionsPerSegment + 1
    var stations: [RibbonStation] = []
    stations.reserveCapacity(sampleCount)
    
    for sampleIndex in 0..<sampleCount
    {
      let targetLength: Double = Double(sampleIndex) / Double(sampleCount - 1) * totalLength
      let t: Double = path.parameterFromArcLength(targetLength: targetLength)
      let residuePosition: Double = t * Double(centers.count - 1)
      
      let center: SIMD3<Double> = path.evaluate(t)
      let tangent: SIMD3<Double> = safeNormalize(path.derivative(t),
                                                 fallback: tangentAt(centers: centers,
                                                                     index: min(Int(round(residuePosition)), centers.count - 1)))
      let frame: (faceNormal: SIMD3<Double>, widthDirection: SIMD3<Double>) = ribbonFrame(at: t,
                                                                                          tangent: tangent,
                                                                                          path: path)
      
      let structure: ProteinRibbonSecondaryStructure = interpolatedSecondaryStructure(assignment: secondaryStructure,
                                                                                        residuePosition: residuePosition)
      let sheetArrowFactor: Double = sheetArrowFactor(residuePosition: residuePosition,
                                                      assignment: secondaryStructure,
                                                      parameters: parameters)
      let sheetArrowWidthFactor: Double = sheetArrowWidthFactor(residuePosition: residuePosition,
                                                                assignment: secondaryStructure,
                                                                parameters: parameters)
      
      stations.append(RibbonStation(center: center,
                                    tangent: tangent,
                                    faceNormal: frame.faceNormal,
                                    widthDirection: frame.widthDirection,
                                    secondaryStructure: structure,
                                    sheetArrowFactor: sheetArrowFactor,
                                    sheetArrowWidthFactor: sheetArrowWidthFactor,
                                    residuePosition: residuePosition))
    }
    return stations
  }
  
  private static func interpolatedSecondaryStructure(assignment: [ProteinRibbonSecondaryStructure],
                                                     residuePosition: Double) -> ProteinRibbonSecondaryStructure
  {
    guard !assignment.isEmpty else {return .coil}
    let clampedPosition: Double = min(max(residuePosition, 0.0), Double(assignment.count - 1))
    let lowerIndex: Int = min(Int(floor(clampedPosition)), assignment.count - 1)
    let upperIndex: Int = min(lowerIndex + 1, assignment.count - 1)
    let localT: Double = clampedPosition - Double(lowerIndex)
    return ProteinRibbonSecondaryStructureAssigner.interpolate(assignment[lowerIndex], assignment[upperIndex], t: localT)
  }
  
  private static func sheetArrowFactor(residuePosition: Double,
                                       assignment: [ProteinRibbonSecondaryStructure],
                                       parameters: ProteinRibbonMeshParameters) -> Double
  {
    let index: Int = min(max(Int(round(residuePosition)), 0), assignment.count - 1)
    guard assignment[index] == .sheet else {return 1.0}
    
    var runStart: Int = index
    while runStart > 0 && assignment[runStart - 1] == .sheet
    {
      runStart -= 1
    }
    var runEnd: Int = index
    while runEnd + 1 < assignment.count && assignment[runEnd + 1] == .sheet
    {
      runEnd += 1
    }
    
    let runLength: Int = runEnd - runStart + 1
    guard runLength >= 3 else {return 1.0}
    
    let sheetArrowLengthExtent: Double = parameters.sheetArrowLengthExtent
    let distanceFromTrailingEdge: Double = Double(runEnd) - residuePosition
    if distanceFromTrailingEdge > sheetArrowLengthExtent {return 1.0}
    if distanceFromTrailingEdge <= 0.0 {return 0.25}
    if distanceFromTrailingEdge <= 1.0
    {
      return 0.25 + 0.25 * distanceFromTrailingEdge
    }
    return 0.5 + 0.5 * (distanceFromTrailingEdge - 1.0)
  }
  
  private static func sheetArrowWidthFactor(residuePosition: Double,
                                            assignment: [ProteinRibbonSecondaryStructure],
                                            parameters: ProteinRibbonMeshParameters) -> Double
  {
    let index: Int = min(max(Int(round(residuePosition)), 0), assignment.count - 1)
    guard assignment[index] == .sheet else {return 1.0}
    
    var runStart: Int = index
    while runStart > 0 && assignment[runStart - 1] == .sheet
    {
      runStart -= 1
    }
    var runEnd: Int = index
    while runEnd + 1 < assignment.count && assignment[runEnd + 1] == .sheet
    {
      runEnd += 1
    }
    
    let runLength: Int = runEnd - runStart + 1
    guard runLength >= 3 else {return 1.0}
    
    // PyMOL ExtrudeCGOSurfaceStrand: peak at the arrow base, linear taper toward the tip.
    // Floor at coilRadiusScale so the continuous ribbon meets the loop tube instead of
    // collapsing to a wire over the last fine spline samples.
    let sheetArrowLengthExtent: Double = parameters.sheetArrowLengthExtent
    let sheetArrowPeakWidthFactor: Double = parameters.sheetArrowPeakWidthFactor
    let distanceFromTrailingEdge: Double = Double(runEnd) - residuePosition
    if distanceFromTrailingEdge > sheetArrowLengthExtent {return 1.0}
    if distanceFromTrailingEdge <= 0.0 {return parameters.coilRadiusScale}
    let tapered: Double = sheetArrowPeakWidthFactor * (distanceFromTrailingEdge / sheetArrowLengthExtent)
    return max(tapered, parameters.coilRadiusScale)
  }
  
  static func crossSectionProfile(for station: RibbonStation,
                                          parameters: ProteinRibbonMeshParameters) -> CrossSectionProfile
  {
    if parameters.nucleicAcidRendering
    {
      switch parameters.nucleicAcidBackboneStyle
      {
      case .oval:
        return CrossSectionProfile(widthClamp: 1.0, radiusScale: parameters.nucleicAcidOvalLength, normalScale: parameters.nucleicAcidOvalWidth, rectangular: false)
      case .tube:
        return CrossSectionProfile(widthClamp: 1.0, radiusScale: 1.0, normalScale: 1.0, rectangular: false)
      case .rect:
        return CrossSectionProfile(widthClamp: 1.0, radiusScale: parameters.nucleicAcidOvalLength, normalScale: parameters.nucleicAcidOvalWidth, rectangular: true)
      case .dumbbell:
        return CrossSectionProfile(widthClamp: 1.0, radiusScale: parameters.nucleicAcidDumbbellLength, normalScale: parameters.nucleicAcidDumbbellWidth, rectangular: false)
      }
    }
    switch station.secondaryStructure
    {
    case .coil:
      return CrossSectionProfile(widthClamp: 1.0, radiusScale: parameters.coilRadiusScale, normalScale: 1.0, rectangular: false)
    case .helix:
      // PyMOL ExtrudeOval: narrow cartoon_oval_width along orientation (cos / faceNormal),
      // full cartoon_oval_length along cross(tangent, orientation) (sin / widthDirection).
      return CrossSectionProfile(widthClamp: 1.0, radiusScale: 1.0, normalScale: parameters.ribbonWidthClamp, rectangular: false)
    case .sheet:
      // PyMOL ExtrudeRectangle + ExtrudeCGOSurfaceStrand: flat rectangle in the sheet plane
      // (wide along widthDirection). Arrow scales only that in-plane width (s0[2]); thickness
      // stays constant. Oval tips collapse to a normal-axis spike and read as a thin line.
      return CrossSectionProfile(widthClamp: station.sheetArrowWidthFactor,
                                 radiusScale: 1.0,
                                 normalScale: parameters.ribbonWidthClamp,
                                 rectangular: true)
    }
  }
  
  private static func insetLightmapUV(_ coordinate: Float) -> Float
  {
    return 0.999 * coordinate + 0.0005
  }
  
  private static func parametricLightmapUV(ringIndex: Int,
                                           splineSamples: Int,
                                           arcLengthFraction: Float,
                                           chainIndex: Int,
                                           totalChains: Int) -> SIMD2<Float>
  {
    let u: Float = splineSamples > 1 ? Float(ringIndex) / Float(splineSamples - 1) : 0.0
    let vLocal: Float = arcLengthFraction
    let v: Float = (Float(chainIndex) + vLocal) / Float(max(totalChains, 1))
    return SIMD2<Float>(insetLightmapUV(u), insetLightmapUV(v))
  }
  
  static func ringMesh(stations: [RibbonStation],
                               radius: Double,
                               chainIndex: Int,
                               totalChains: Int,
                               ringResolution: Int,
                               parameters: ProteinRibbonMeshParameters,
                               ringOffsetWithinChain: Int = 0,
                               chainRingTotal: Int = 0) -> (vertices: [RKVertex], indices: [UInt32])
  {
    let splineSamples: Int = stations.count
    guard splineSamples >= 2 else {return ([], [])}
    let lightmapRingTotal: Int = chainRingTotal > 0 ? chainRingTotal : splineSamples
    
    let loopResolution: Int = ringResolution
    let verticesPerRing: Int = loopResolution + 1
    let totalVertices: Int = splineSamples * verticesPerRing
    
    var ringPositions: [[SIMD3<Double>]] = []
    ringPositions.reserveCapacity(splineSamples)
    var ringStructureTypes: [Float] = []
    ringStructureTypes.reserveCapacity(splineSamples)
    
    for station in stations
    {
      let profile: CrossSectionProfile = crossSectionProfile(for: station, parameters: parameters)
      let structureType: Float = parameters.nucleicAcidRendering
        ? SKNucleotideBase.vertexStructureTypeCode(.unknown, backbone: true)
        : structureTypeCode(station.secondaryStructure)
      var ring: [SIMD3<Double>] = []
      ring.reserveCapacity(loopResolution)
      
      // Lightmap UV seam is at segment 0 / loopResolution. Both flattened ovals (cos clamp)
      // and rectangles (max-norm square) place angle 0 at the center of a wide face, which
      // shows up as a dark AO stripe. Offset by π/2 so the seam sits on a thin lateral edge.
      let seamAngleOffset: Double = 0.5 * Double.pi
      
      for segment in 0..<loopResolution
      {
        let angle: Double = 2.0 * Double.pi * Double(segment) / Double(loopResolution) + seamAngleOffset
        let offset: SIMD3<Double>
        if parameters.nucleicAcidRendering
        {
          let crossSection: (alongWidthDirection: Double, alongFaceNormal: Double) =
            ProteinNucleicAcidRibbonMeshSupport.nucleicAcidCrossSectionOffset(angle: angle,
                                                                              radius: radius,
                                                                              parameters: parameters)
          offset = crossSection.alongWidthDirection * station.widthDirection +
                   crossSection.alongFaceNormal * station.faceNormal
        }
        else
        {
          let angleCos: Double = cos(angle)
          let angleSin: Double = sin(angle)
          let d: Double
          let n: Double
          
          if profile.rectangular
          {
            // Unit square via max-norm: flat faces in the sheet plane (PyMOL ExtrudeRectangle).
            // widthClamp is in-plane half-width (body 1, arrow peak > 1, tip → 0).
            let m: Double = max(abs(angleCos), abs(angleSin))
            let scale: Double = m > 1.0e-12 ? 1.0 / m : 1.0
            d = angleSin * scale * profile.widthClamp
            n = angleCos * scale * profile.normalScale
          }
          else if station.secondaryStructure == .helix
          {
            // Thin along faceNormal (orientation); wide along widthDirection.
            var helixN: Double = angleCos
            if profile.normalScale < 1.0
            {
              helixN = max(-profile.normalScale, min(profile.normalScale, helixN))
            }
            d = angleSin * profile.widthClamp
            n = helixN
          }
          else
          {
            var width: Double = angleSin
            var normal: Double = angleCos
            if profile.widthClamp < 1.0
            {
              width = max(-profile.widthClamp, min(profile.widthClamp, width))
            }
            normal *= profile.normalScale
            d = width
            n = normal
          }
          
          offset = profile.radiusScale * radius * (d * station.widthDirection + n * station.faceNormal)
        }
        ring.append(station.center + offset)
      }
      ringPositions.append(ring)
      ringStructureTypes.append(structureType)
    }
    
    var meshVertices: [RKVertex] = Array(repeating: RKVertex(), count: totalVertices)
    var vertexNormals: [SIMD3<Double>] = Array(repeating: SIMD3<Double>(0.0, 0.0, 0.0), count: totalVertices)
    var normalCounts: [Int] = Array(repeating: 0, count: totalVertices)
    
    for ringIndex in 0..<splineSamples
    {
      var distAroundRing: [Double] = Array(repeating: 0.0, count: verticesPerRing)
      var previousPosition: SIMD3<Double> = ringPositions[ringIndex][0]
      for segment in 1...loopResolution
      {
        let wrappedSegment: Int = segment % loopResolution
        let position: SIMD3<Double> = ringPositions[ringIndex][wrappedSegment]
        distAroundRing[segment] = distAroundRing[segment - 1] + length(position - previousPosition)
        previousPosition = position
      }
      let totalRingDistance: Double = distAroundRing[loopResolution]
      
      for segment in 0...loopResolution
      {
        let vertexIndex: Int = ringIndex * verticesPerRing + segment
        let wrappedSegment: Int = segment % loopResolution
        let position: SIMD3<Double> = ringPositions[ringIndex][wrappedSegment]
        let arcLengthFraction: Float = totalRingDistance > 1.0e-12 ? Float(distAroundRing[segment] / totalRingDistance) : 0.0
        
        meshVertices[vertexIndex].position = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), 1.0)
        meshVertices[vertexIndex].st = parametricLightmapUV(ringIndex: ringOffsetWithinChain + ringIndex,
                                                            splineSamples: lightmapRingTotal,
                                                            arcLengthFraction: arcLengthFraction,
                                                            chainIndex: chainIndex,
                                                            totalChains: totalChains)
        meshVertices[vertexIndex].pad = SIMD2<Float>(ringStructureTypes[ringIndex], 0.0)
        meshVertices[vertexIndex].stripeST = SIMD2<Float>(0.0, arcLengthFraction)
      }
    }
    
    func accumulateNormal(vertexIndex: Int, normal: SIMD3<Double>)
    {
      vertexNormals[vertexIndex] += normal
      normalCounts[vertexIndex] += 1
    }
    
    for ringIndex in 0..<(splineSamples - 1)
    {
      for segment in 0..<loopResolution
      {
        let v0: Int = ringIndex * verticesPerRing + segment
        let v1Base: Int = ringIndex * verticesPerRing + (segment + 1) % loopResolution
        let v2: Int = (ringIndex + 1) * verticesPerRing + segment
        let v3Base: Int = (ringIndex + 1) * verticesPerRing + (segment + 1) % loopResolution
        
        let pos0: SIMD3<Double> = ringPositions[ringIndex][segment]
        let pos1: SIMD3<Double> = ringPositions[ringIndex][(segment + 1) % loopResolution]
        let pos2: SIMD3<Double> = ringPositions[ringIndex + 1][segment]
        let pos3: SIMD3<Double> = ringPositions[ringIndex + 1][(segment + 1) % loopResolution]
        
        let normal1: SIMD3<Double> = safeNormalize(cross(pos1 - pos0, pos2 - pos0), fallback: SIMD3<Double>(0.0, 0.0, 1.0))
        accumulateNormal(vertexIndex: v0, normal: normal1)
        accumulateNormal(vertexIndex: v1Base, normal: normal1)
        accumulateNormal(vertexIndex: v2, normal: normal1)
        
        let normal2: SIMD3<Double> = safeNormalize(cross(pos3 - pos1, pos2 - pos1), fallback: SIMD3<Double>(0.0, 0.0, 1.0))
        accumulateNormal(vertexIndex: v1Base, normal: normal2)
        accumulateNormal(vertexIndex: v3Base, normal: normal2)
        accumulateNormal(vertexIndex: v2, normal: normal2)
      }
    }
    
    for vertexIndex in 0..<totalVertices
    {
      var baseIndex: Int = vertexIndex
      if vertexIndex % verticesPerRing == loopResolution
      {
        baseIndex -= loopResolution
      }
      if normalCounts[baseIndex] > 0
      {
        let averagedNormal: SIMD3<Double> = safeNormalize(vertexNormals[baseIndex] / Double(normalCounts[baseIndex]),
                                                        fallback: SIMD3<Double>(0.0, 0.0, 1.0))
        meshVertices[vertexIndex].normal = SIMD4<Float>(Float(averagedNormal.x), Float(averagedNormal.y), Float(averagedNormal.z), 0.0)
      }
    }
    
    var indices: [UInt32] = Array(repeating: 0, count: (splineSamples - 1) * loopResolution * 6)
    var indexOffset: Int = 0
    
    for ringIndex in 0..<(splineSamples - 1)
    {
      for segment in 0..<loopResolution
      {
        let v0: UInt32 = UInt32(ringIndex * verticesPerRing + segment)
        let v1: UInt32 = UInt32(ringIndex * verticesPerRing + segment + 1)
        let v2: UInt32 = UInt32((ringIndex + 1) * verticesPerRing + segment)
        let v3: UInt32 = UInt32((ringIndex + 1) * verticesPerRing + segment + 1)
        
        indices[indexOffset] = v0
        indices[indexOffset + 1] = v1
        indices[indexOffset + 2] = v2
        indices[indexOffset + 3] = v1
        indices[indexOffset + 4] = v3
        indices[indexOffset + 5] = v2
        indexOffset += 6
      }
    }
    
    return (meshVertices, indices)
  }
  
  static func ribbonFrame(at t: Double,
                                  tangent: SIMD3<Double>,
                                  path: any ProteinRibbonCenterlinePath) -> (faceNormal: SIMD3<Double>, widthDirection: SIMD3<Double>)
  {
    // Match PyMOL get_system2f3f: x=tangent, y=orientation, z=cross(tangent, orientation).
    let x: SIMD3<Double> = safeNormalize(tangent, fallback: SIMD3<Double>(0.0, 0.0, 1.0))
    let orientation: SIMD3<Double> = path.evaluateOrientation(t)
    let z: SIMD3<Double> = safeNormalize(cross(x, orientation), fallback: perpendicularVector(to: x))
    let y: SIMD3<Double> = safeNormalize(cross(z, x), fallback: orientation)
    return (y, z)
  }
  
  private static func projectToPlane(_ vector: SIMD3<Double>, planeNormal: SIMD3<Double>) -> SIMD3<Double>
  {
    return vector - planeNormal * dot(vector, planeNormal)
  }
  
  private static func ribbonBackboneSamples(for residues: [ProteinBackboneResidue],
                                            contentShift: SIMD3<Double>) -> [RibbonBackboneSample]
  {
    return residues.map
    { residue in
      let center: SIMD3<Double> = (residue.alphaCarbon?.position ?? .zero) + contentShift
      return RibbonBackboneSample(center: center,
                                  nitrogen: residue.nitrogen.map{$0.position + contentShift},
                                  carbonylCarbon: residue.carbonylCarbon.map{$0.position + contentShift},
                                  carbonylOxygen: residue.carbonylOxygen.map{$0.position + contentShift})
    }
  }
  
  private static func orientationOrthogonalToTangent(_ orientation: SIMD3<Double>, tangent: SIMD3<Double>) -> SIMD3<Double>
  {
    return safeNormalize(projectToPlane(orientation, planeNormal: tangent), fallback: orientation)
  }
  
  // PyMOL RepCartoon PASS1: cross(normalize(N-C), normalize(N-O)).
  private static func computeCartoonOrientationVectors(samples: [RibbonBackboneSample]) -> [SIMD3<Double>]
  {
    guard !samples.isEmpty else {return []}
    
    var orientations: [SIMD3<Double>] = []
    orientations.reserveCapacity(samples.count)
    for index in 0..<samples.count
    {
      let sample: RibbonBackboneSample = samples[index]
      var orientation: SIMD3<Double>
      if let nitrogen: SIMD3<Double> = sample.nitrogen,
         let carbonylCarbon: SIMD3<Double> = sample.carbonylCarbon,
         let carbonylOxygen: SIMD3<Double> = sample.carbonylOxygen
      {
        let nToC: SIMD3<Double> = safeNormalize(nitrogen - carbonylCarbon, fallback: SIMD3<Double>(0.0, 0.0, 1.0))
        let nToO: SIMD3<Double> = safeNormalize(nitrogen - carbonylOxygen, fallback: SIMD3<Double>(0.0, 0.0, 1.0))
        orientation = cross(nToC, nToO)
      }
      else if index > 0 && index + 1 < samples.count
      {
        let t0: SIMD3<Double> = samples[index - 1].center - sample.center
        let t1: SIMD3<Double> = samples[index + 1].center - sample.center
        orientation = safeNormalize(t0 + t1, fallback: SIMD3<Double>(0.0, 0.0, 1.0))
      }
      else
      {
        orientation = SIMD3<Double>(0.0, 0.0, 0.0)
      }
      if length_squared(orientation) < 1.0e-12
      {
        orientation = SIMD3<Double>(0.0, 0.0, 0.0)
      }
      else
      {
        orientation = normalize(orientation)
      }
      orientations.append(orientation)
    }
    return orientations
  }
  
  // PyMOL RepCartoonComputeDifferencesAndNormals (chain direction normals).
  static func computeChainDirectionNormals(centers: [SIMD3<Double>]) -> [SIMD3<Double>]
  {
    guard !centers.isEmpty else {return []}
    guard centers.count > 1 else {return [SIMD3<Double>(0.0, 0.0, 0.0)]}
    
    var normals: [SIMD3<Double>] = Array(repeating: SIMD3<Double>(0.0, 0.0, 0.0), count: centers.count)
    for index in 0..<(centers.count - 1)
    {
      let difference: SIMD3<Double> = centers[index + 1] - centers[index]
      let segmentLength: Double = length(difference)
      if segmentLength > 1.0e-6
      {
        normals[index] = difference / segmentLength
      }
      else if index > 0
      {
        normals[index] = normals[index - 1]
      }
    }
    normals[centers.count - 1] = normals[centers.count - 2]
    return normals
  }
  
  // PyMOL RepCartoonComputeTangents.
  static func computeChainTangents(directionNormals: [SIMD3<Double>]) -> [SIMD3<Double>]
  {
    guard !directionNormals.isEmpty else {return []}
    guard directionNormals.count > 1 else {return directionNormals}
    
    var tangents: [SIMD3<Double>] = directionNormals
    tangents[0] = directionNormals[0]
    for index in 1..<(directionNormals.count - 1)
    {
      tangents[index] = safeNormalize(directionNormals[index] + directionNormals[index - 1],
                                      fallback: directionNormals[index])
    }
    tangents[directionNormals.count - 1] = directionNormals[directionNormals.count - 2]
    return tangents
  }
  
  private static func setOrientationFromAxisCrossTangent(orientations: inout [SIMD3<Double>],
                                                         tangents: [SIMD3<Double>],
                                                         orientationIndex: Int,
                                                         axis: SIMD3<Double>)
  {
    guard orientationIndex >= 0 && orientationIndex < orientations.count else {return}
    orientations[orientationIndex] = orientationOrthogonalToTangent(cross(axis, tangents[orientationIndex]),
                                                                      tangent: tangents[orientationIndex])
  }
  
  // PyMOL RepCartoonComputeRoundHelices (cartoon_round_helices).
  private static func computeRoundHelices(orientations: inout [SIMD3<Double>],
                                          centers: [SIMD3<Double>],
                                          tangents: [SIMD3<Double>],
                                          secondaryStructure: [ProteinRibbonSecondaryStructure])
  {
    let count: Int = centers.count
    guard count > 1,
          orientations.count == count,
          tangents.count == count,
          secondaryStructure.count == count else {return}
    
    var helixCA1: SIMD3<Double>? = nil
    var helixCA2: SIMD3<Double>? = nil
    var helixCA3: SIMD3<Double>? = nil
    var helixCA4: SIMD3<Double>? = nil
    var helixCA5: SIMD3<Double>? = nil
    var helixRoundPassCount: Int = 0
    var previousHelixAxisPoint: SIMD3<Double>? = nil
    
    for index in 0..<count
    {
      helixCA5 = helixCA4
      helixCA4 = helixCA3
      helixCA3 = helixCA2
      helixCA2 = helixCA1
      
      if secondaryStructure[index] == .helix
      {
        helixCA1 = centers[index]
      }
      else
      {
        if helixRoundPassCount < 2, let ca2: SIMD3<Double> = helixCA2, let ca3: SIMD3<Double> = helixCA3
        {
          var axis: SIMD3<Double> = safeNormalize(ca2 - centers[index], fallback: SIMD3<Double>(0.0, 0.0, 0.0))
          var segment: SIMD3<Double> = safeNormalize(ca3 - ca2, fallback: axis)
          axis = safeNormalize(axis + segment, fallback: axis)
          if let ca4: SIMD3<Double> = helixCA4
          {
            segment = safeNormalize(ca4 - ca3, fallback: segment)
            axis = safeNormalize(axis + segment, fallback: axis)
          }
          if let ca4: SIMD3<Double> = helixCA4, let ca5: SIMD3<Double> = helixCA5
          {
            segment = safeNormalize(ca5 - ca4, fallback: segment)
            axis = safeNormalize(axis + segment, fallback: axis)
          }
          if length_squared(axis) > 1.0e-12
          {
            setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 1, axis: axis)
            setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 2, axis: axis)
            if helixCA4 != nil
            {
              setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 3, axis: axis)
            }
            if helixCA5 != nil
            {
              setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 4, axis: axis)
              if index >= 4 && dot(orientations[index - 3], orientations[index - 4]) < -0.8
              {
                orientations[index - 4] = -orientations[index - 4]
              }
            }
          }
        }
        helixCA1 = nil
        helixCA2 = nil
        helixCA3 = nil
        helixCA4 = nil
        helixCA5 = nil
        helixRoundPassCount = 0
        previousHelixAxisPoint = nil
      }
      
      if let ca1: SIMD3<Double> = helixCA1,
         let ca2: SIMD3<Double> = helixCA2,
         let ca3: SIMD3<Double> = helixCA3,
         let ca4: SIMD3<Double> = helixCA4
      {
        let axisPoint: SIMD3<Double> = (ca1 + ca4) * 0.2130 + (ca2 + ca3) * 0.2870
        if helixRoundPassCount > 0, let previousPoint: SIMD3<Double> = previousHelixAxisPoint
        {
          let axisDirection: SIMD3<Double> = safeNormalize(previousPoint - axisPoint, fallback: tangents[index])
          setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index, axis: axisDirection)
          setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 1, axis: axisDirection)
          setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 2, axis: axisDirection)
          if helixRoundPassCount == 1
          {
            setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 3, axis: axisDirection)
            setOrientationFromAxisCrossTangent(orientations: &orientations, tangents: tangents, orientationIndex: index - 4, axis: axisDirection)
          }
        }
        helixRoundPassCount += 1
        previousHelixAxisPoint = axisPoint
      }
    }
  }
  
  // PyMOL RepCartoonRefineNormals (cartoon_refine_normals).
  static func refineCartoonOrientationNormals(orientations: inout [SIMD3<Double>],
                                                      tangents: [SIMD3<Double>],
                                                      secondaryStructure: [ProteinRibbonSecondaryStructure])
  {
    let count: Int = orientations.count
    guard count >= 2, tangents.count == count, secondaryStructure.count == count else {return}
    
    for index in 1..<(count - 1)
    {
      orientations[index] = orientationOrthogonalToTangent(orientations[index], tangent: tangents[index])
    }
    
    var alternatives: [SIMD3<Double>] = Array(repeating: SIMD3<Double>(0.0, 0.0, 0.0), count: count * 2)
    for index in 0..<count
    {
      alternatives[index * 2] = orientations[index]
      alternatives[index * 2 + 1] = orientations[index]
      if secondaryStructure[index] != .helix
      {
        alternatives[index * 2 + 1] = -alternatives[index * 2 + 1]
      }
    }
    
    for index in 1..<(count - 1)
    {
      let previousOrientation: SIMD3<Double> = orientationOrthogonalToTangent(orientations[index - 1], tangent: tangents[index])
      let candidateA: SIMD3<Double> = orientationOrthogonalToTangent(alternatives[index * 2], tangent: tangents[index])
      let candidateB: SIMD3<Double> = orientationOrthogonalToTangent(alternatives[index * 2 + 1], tangent: tangents[index])
      var bestDot: Double = dot(previousOrientation, candidateA)
      orientations[index] = alternatives[index * 2]
      let alternateDot: Double = dot(previousOrientation, candidateB)
      if alternateDot > bestDot
      {
        orientations[index] = alternatives[index * 2 + 1]
        bestDot = alternateDot
      }
    }
    
    var softenedAlternatives: [SIMD3<Double>] = Array(repeating: SIMD3<Double>(0.0, 0.0, 0.0), count: count * 2)
    for index in 1..<(count - 1)
    {
      let kinkMetric: Double = dot(orientations[index], orientations[index + 1]) * dot(orientations[index], orientations[index - 1])
      if kinkMetric < -0.10
      {
        var blended: SIMD3<Double> = orientations[index + 1] + orientations[index - 1]
        blended += orientations[index] * 0.001
        blended = orientationOrthogonalToTangent(blended, tangent: tangents[index])
        let adjusted: SIMD3<Double> = normalize(dot(orientations[index], blended) < 0.0
                                                ? orientations[index] - blended
                                                : orientations[index] + blended)
        var mixAmount: Double = 2.0 * (-0.10 - kinkMetric)
        mixAmount = min(mixAmount, 1.0)
        softenedAlternatives[index * 2] = normalize(orientations[index] * (1.0 - mixAmount) + adjusted * mixAmount)
        softenedAlternatives[index * 2 + 1] = -softenedAlternatives[index * 2 + 1]
      }
      else
      {
        softenedAlternatives[index * 2] = orientations[index]
        softenedAlternatives[index * 2 + 1] = -softenedAlternatives[index * 2]
      }
    }
    
    for index in 1..<(count - 1)
    {
      orientations[index] = softenedAlternatives[index * 2]
    }
  }
  
  // PyMOL RepCartoonFlattenSheets (cartoon_flat_sheets / cartoon_flat_cycles).
  private static func flattenCartoonSheets(centers: inout [SIMD3<Double>],
                                           orientations: inout [SIMD3<Double>],
                                           secondaryStructure: [ProteinRibbonSecondaryStructure],
                                           cycles: Int)
  {
    let count: Int = centers.count
    guard cycles > 0,
          count >= 3,
          orientations.count == count,
          secondaryStructure.count == count else {return}
    
    var tmpCenters: [SIMD3<Double>] = centers
    var tmpOrientations: [SIMD3<Double>] = orientations
    let window: Int = 1
    
    var index: Int = 0
    while index < count
    {
      guard secondaryStructure[index] == .sheet else
      {
        index += 1
        continue
      }
      
      let runStart: Int = index
      while index < count && secondaryStructure[index] == .sheet
      {
        index += 1
      }
      let runEnd: Int = index - 1
      guard runEnd - runStart >= 2 * window else {continue}
      
      for _ in 0..<cycles
      {
        for b in (runStart + window)...(runEnd - window)
        {
          var sum: SIMD3<Double> = .zero
          for e in -window...window
          {
            sum += centers[b + e]
          }
          tmpCenters[b] = sum / Double(window * 2 + 1)
        }
        for b in (runStart + window)...(runEnd - window)
        {
          centers[b] = tmpCenters[b]
        }
        
        for b in (runStart + window)...(runEnd - window)
        {
          var sum: SIMD3<Double> = .zero
          for e in -window...window
          {
            sum += orientations[b + e]
          }
          tmpOrientations[b] = sum / Double(window * 2 + 1)
        }
        for b in (runStart + window)...(runEnd - window)
        {
          let tangent: SIMD3<Double> = safeNormalize(centers[b + 1] - centers[b - 1],
                                                     fallback: perpendicularVector(to: orientations[b]))
          orientations[b] = orientationOrthogonalToTangent(tmpOrientations[b], tangent: tangent)
        }
      }
    }
  }
  
  private static func tangentAt(centers: [SIMD3<Double>], index: Int) -> SIMD3<Double>
  {
    if index == 0
    {
      return normalize(centers[1] - centers[0])
    }
    if index == centers.count - 1
    {
      return normalize(centers[index] - centers[index - 1])
    }
    return normalize(centers[index + 1] - centers[index - 1])
  }
  
  static func safeNormalize(_ vector: SIMD3<Double>, fallback: SIMD3<Double>) -> SIMD3<Double>
  {
    if length_squared(vector) < 1.0e-12
    {
      return fallback
    }
    return normalize(vector)
  }
  
  static func perpendicularVector(to tangent: SIMD3<Double>) -> SIMD3<Double>
  {
    if abs(tangent.x) > abs(tangent.z)
    {
      return normalize(cross(tangent, SIMD3<Double>(0.0, 0.0, 1.0)))
    }
    return normalize(cross(tangent, SIMD3<Double>(0.0, 1.0, 0.0)))
  }
  
  static func structureTypeCode(_ structure: ProteinRibbonSecondaryStructure) -> Float
  {
    switch structure
    {
    case .coil: return 0.0
    case .helix: return 1.0
    case .sheet: return 2.0
    }
  }
}
