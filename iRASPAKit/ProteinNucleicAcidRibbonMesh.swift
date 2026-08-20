/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 PyMOL nucleic-acid cartoon backbone (trace + cross-section) and entry point for DNA ribbon meshes.
 *************************************************************************************************************/

import Foundation
import simd
import SymmetryKit
import RenderKit

enum ProteinNucleicAcidRibbonMeshSupport
{
  static func nucleicAcidCrossSectionOffset(angle: Double,
                                            radius: Double,
                                            parameters: ProteinRibbonMeshParameters) -> (alongWidthDirection: Double, alongFaceNormal: Double)
  {
    let perimeterFraction: Double = angle / (2.0 * Double.pi)
    var alongWidthDirection: Double = 0.0
    var alongFaceNormal: Double = 0.0
    
    switch parameters.nucleicAcidBackboneStyle
    {
    case .oval:
      let d: Double = sin(angle)
      var n: Double = cos(angle)
      n = max(-parameters.nucleicAcidOvalWidth, min(parameters.nucleicAcidOvalWidth, n))
      alongWidthDirection = parameters.nucleicAcidOvalLength * radius * d
      alongFaceNormal = radius * n
    case .tube:
      alongWidthDirection = radius * sin(angle)
      alongFaceNormal = radius * cos(angle)
    case .rect:
      rectangleCrossSectionPoint(perimeterFraction: perimeterFraction,
                                 halfLength: parameters.nucleicAcidOvalLength * radius * 0.5,
                                 halfWidth: parameters.nucleicAcidOvalWidth * radius * 0.5,
                                 alongWidthDirection: &alongWidthDirection,
                                 alongFaceNormal: &alongFaceNormal)
    case .dumbbell:
      dumbbellCrossSectionPoint(perimeterFraction: perimeterFraction,
                                halfLength: parameters.nucleicAcidDumbbellLength * radius * 0.5,
                                halfWidth: parameters.nucleicAcidDumbbellWidth * radius * 0.5,
                                bulbRadius: parameters.nucleicAcidDumbbellRadius * radius,
                                alongWidthDirection: &alongWidthDirection,
                                alongFaceNormal: &alongFaceNormal)
    }
    return (alongWidthDirection, alongFaceNormal)
  }
  
  private static func rectangleCrossSectionPoint(perimeterFraction: Double,
                                                 halfLength: Double,
                                                 halfWidth: Double,
                                                 alongWidthDirection: inout Double,
                                                 alongFaceNormal: inout Double)
  {
    let edgeLength: Double = 2.0 * halfLength
    let edgeWidth: Double = 2.0 * halfWidth
    let perimeter: Double = 2.0 * (edgeLength + edgeWidth)
    var distance: Double = perimeterFraction * perimeter
    if distance < 0.0
    {
      distance += perimeter * ceil(-distance / perimeter)
    }
    distance = distance.truncatingRemainder(dividingBy: perimeter)
    
    if distance <= edgeWidth
    {
      alongFaceNormal = -halfWidth + distance
      alongWidthDirection = -halfLength
      return
    }
    distance -= edgeWidth
    if distance <= edgeLength
    {
      alongFaceNormal = halfWidth
      alongWidthDirection = -halfLength + distance
      return
    }
    distance -= edgeLength
    if distance <= edgeWidth
    {
      alongFaceNormal = halfWidth - distance
      alongWidthDirection = halfLength
      return
    }
    distance -= edgeWidth
    alongFaceNormal = -halfWidth
    alongWidthDirection = halfLength - distance
  }
  
  private static func dumbbellCrossSectionPoint(perimeterFraction: Double,
                                                halfLength: Double,
                                                halfWidth: Double,
                                                bulbRadius: Double,
                                                alongWidthDirection: inout Double,
                                                alongFaceNormal: inout Double)
  {
    let centerOffset: Double = max(halfLength - bulbRadius, bulbRadius * 0.25)
    let arcLength: Double = Double.pi * bulbRadius
    let connectorLength: Double = 2.0 * centerOffset
    let bridgeWidth: Double = halfWidth
    let perimeter: Double = 2.0 * arcLength + 2.0 * connectorLength + 2.0 * bridgeWidth
    var distance: Double = perimeterFraction * perimeter
    if distance < 0.0
    {
      distance += perimeter * ceil(-distance / perimeter)
    }
    distance = distance.truncatingRemainder(dividingBy: perimeter)
    
    let bottomCenterY: Double = -centerOffset
    let topCenterY: Double = centerOffset
    
    if distance <= arcLength
    {
      let theta: Double = Double.pi + distance / bulbRadius
      alongWidthDirection = bottomCenterY + bulbRadius * sin(theta)
      alongFaceNormal = bulbRadius * cos(theta)
      return
    }
    distance -= arcLength
    
    if distance <= connectorLength
    {
      alongWidthDirection = bottomCenterY + distance
      alongFaceNormal = bridgeWidth
      return
    }
    distance -= connectorLength
    
    if distance <= arcLength
    {
      let theta: Double = distance / bulbRadius
      alongWidthDirection = topCenterY + bulbRadius * sin(theta)
      alongFaceNormal = bulbRadius * cos(theta)
      return
    }
    distance -= arcLength
    
    alongWidthDirection = topCenterY - distance
    alongFaceNormal = -bridgeWidth
  }
}

extension ProteinRibbonMeshBuilder
{
  private enum NucleicAcidTraceRole
  {
    case o5PrimeCap
    case phosphate
    case o3PrimeCap
  }
  
  private struct NucleicAcidBackboneSample
  {
    var center: SIMD3<Double>
    var c2: SIMD3<Double>?
    var c3: SIMD3<Double>?
    var role: NucleicAcidTraceRole
    var residueIndex: Int
    var nucleotidePosition: Double
  }
  
  /// PyMOL-style nucleic-acid cartoon: phosphate/C3′ trace, NA cross-section, rings and ladders.
  public static func buildNucleicAcidRibbon(from backbone: DNABackbone,
                                            atoms: [SKAsymmetricAtom],
                                            radius: Double,
                                            contentShift: SIMD3<Double>,
                                            parameters: ProteinRibbonMeshParameters = .default) -> RKRibbonMesh
  {
    var meshParameters: ProteinRibbonMeshParameters = parameters.clamped
    meshParameters.nucleicAcidRendering = true
    
    let proteinBackbone: ProteinBackbone = backbone.toProteinBackbone()
    var chainStations: [(chain: ProteinBackboneChain, stations: [RibbonStation], residueSegments: [ProteinRibbonResidueSegment])] = []
    chainStations.reserveCapacity(backbone.chains.count)
    
    for (chainIndex, dnaChain) in backbone.chains.enumerated()
    {
      let samples: [NucleicAcidBackboneSample] = nucleicAcidBackboneSamples(for: dnaChain,
                                                                              contentShift: contentShift,
                                                                              traceMode: meshParameters.nucleicAcidTraceMode)
      guard samples.count >= 2 else {continue}
      
      let proteinChain: ProteinBackboneChain
      if chainIndex < proteinBackbone.chains.count
      {
        proteinChain = proteinBackbone.chains[chainIndex]
      }
      else
      {
        proteinChain = ProteinBackboneChain(chainIdentifier: dnaChain.chainIdentifier, residues: [])
      }
      
      // PyMOL tags nucleic acids as ss_t::NUCLEIC (not HELIX) so refine_normals may flip orientations.
      let secondaryStructure: [ProteinRibbonSecondaryStructure] = Array(repeating: .coil, count: samples.count)
      let residueSegments: [ProteinRibbonResidueSegment] = ProteinRibbonSegmentSupport.residueSegments(from: secondaryStructure,
                                                                                                         chainIdentifier: dnaChain.chainIdentifier)
      let stations: [RibbonStation] = ribbonStationsFromNucleicAcid(samples: samples,
                                                                    secondaryStructure: secondaryStructure,
                                                                    parameters: meshParameters)
      guard stations.count >= 2 else {continue}
      chainStations.append((chain: proteinChain, stations: stations, residueSegments: residueSegments))
    }
    
    return extrudeNucleicAcidChains(chainStations,
                                    radius: radius,
                                    parameters: meshParameters,
                                    atoms: atoms,
                                    backbone: backbone,
                                    contentShift: contentShift,
                                    includeRingsAndLadders: true)
  }
  
  private static func extrudeNucleicAcidChains(_ chainStations: [(chain: ProteinBackboneChain,
                                                                  stations: [RibbonStation],
                                                                  residueSegments: [ProteinRibbonResidueSegment])],
                                               radius: Double,
                                               parameters: ProteinRibbonMeshParameters,
                                               atoms: [SKAsymmetricAtom],
                                               backbone: DNABackbone,
                                               contentShift: SIMD3<Double>,
                                               includeRingsAndLadders: Bool) -> RKRibbonMesh
  {
    let ringResolution: Int = parameters.crossSectionRingResolution
    var mesh: RKRibbonMesh = RKRibbonMesh()
    let totalChains: Int = max(chainStations.count, 1)
    for (chainIndex, chainData) in chainStations.enumerated()
    {
      let indexStart: Int = mesh.indices.count
      let vertexBase: Int = mesh.vertices.count
      let built: (vertices: [RKVertex], indices: [UInt32]) = ringMesh(stations: chainData.stations,
                                                                     radius: radius,
                                                                     chainIndex: chainIndex,
                                                                     totalChains: totalChains,
                                                                     ringResolution: ringResolution,
                                                                     parameters: parameters)
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
      mesh.chainDrawRanges.append(RKRibbonChainDrawRange(indexStart: indexStart,
                                                         indexCount: mesh.indices.count - indexStart))
      mesh.chainSplineSampleCounts.append(chainData.stations.count)
      appendSegmentDrawRanges(for: chainData.chain,
                              stations: chainData.stations,
                              chainIndexStart: indexStart,
                              residueSegments: chainData.residueSegments,
                              ringResolution: ringResolution,
                              mesh: &mesh)
      appendResidueDrawRanges(for: chainData.chain,
                              stations: chainData.stations,
                              chainIndexStart: indexStart,
                              ringResolution: ringResolution,
                              mesh: &mesh)
    }
    
    if includeRingsAndLadders
    {
      var nucleotideGeometry: DNANucleotideGeometry = DNANucleotideGeometry.build(from: atoms)
      DNANucleotideGeometry.assignGlobalResidueIndicesFromBackbone(&nucleotideGeometry, backbone: backbone)
      let basePairs: [DNANucleotideBasePair] = DNANucleotideGeometry.detectWatsonCrickPairs(nucleotideGeometry)
      ProteinNucleicAcidMeshBuilder.appendRingAndLadderMeshes(mesh: &mesh,
                                                              geometry: nucleotideGeometry,
                                                              basePairs: basePairs,
                                                              contentShift: contentShift,
                                                              radius: radius,
                                                              parameters: parameters)
    }
    
    applyPickingIndices(mesh: &mesh)
    applyRibbonStripeCoordinates(mesh: &mesh)
    return mesh
  }
  
  private static func nucleicAcidBackboneSamples(for chain: DNABackboneChain,
                                                 contentShift: SIMD3<Double>,
                                                 traceMode: NucleicAcidTraceMode) -> [NucleicAcidBackboneSample]
  {
    let residueCount: Int = chain.residues.count
    guard residueCount > 0 else {return []}
    
    var samples: [NucleicAcidBackboneSample] = []
    samples.reserveCapacity(residueCount + 2)
    
    if traceMode == .c3PrimeMode1
    {
      for residueIndex in 0..<residueCount
      {
        let residue: DNABackboneResidue = chain.residues[residueIndex]
        guard let c3Prime: SKAsymmetricAtom = residue.c3Prime else {continue}
        samples.append(makeNucleicAcidTraceSample(residue: residue,
                                                  centerAtom: c3Prime,
                                                  contentShift: contentShift,
                                                  role: .phosphate,
                                                  residueIndex: residueIndex,
                                                  nucleotidePosition: Double(residueIndex)))
      }
      return samples
    }
    
    let firstResidue: DNABackboneResidue = chain.residues[0]
    if let o5Prime: SKAsymmetricAtom = firstResidue.o5Prime
    {
      samples.append(makeNucleicAcidTraceSample(residue: firstResidue,
                                                centerAtom: o5Prime,
                                                contentShift: contentShift,
                                                role: .o5PrimeCap,
                                                residueIndex: 0,
                                                nucleotidePosition: 0.0))
    }
    
    for residueIndex in 0..<residueCount
    {
      let residue: DNABackboneResidue = chain.residues[residueIndex]
      guard let phosphate: SKAsymmetricAtom = residue.phosphate else {continue}
      samples.append(makeNucleicAcidTraceSample(residue: residue,
                                                centerAtom: phosphate,
                                                contentShift: contentShift,
                                                role: .phosphate,
                                                residueIndex: residueIndex,
                                                nucleotidePosition: Double(residueIndex)))
    }
    
    let lastResidue: DNABackboneResidue = chain.residues[residueCount - 1]
    if let o3Prime: SKAsymmetricAtom = lastResidue.o3Prime
    {
      samples.append(makeNucleicAcidTraceSample(residue: lastResidue,
                                                centerAtom: o3Prime,
                                                contentShift: contentShift,
                                                role: .o3PrimeCap,
                                                residueIndex: residueCount - 1,
                                                nucleotidePosition: Double(residueCount - 1)))
    }
    
    return samples
  }
  
  private static func makeNucleicAcidTraceSample(residue: DNABackboneResidue,
                                                 centerAtom: SKAsymmetricAtom,
                                                 contentShift: SIMD3<Double>,
                                                 role: NucleicAcidTraceRole,
                                                 residueIndex: Int,
                                                 nucleotidePosition: Double) -> NucleicAcidBackboneSample
  {
    return NucleicAcidBackboneSample(center: centerAtom.position + contentShift,
                                     c2: residue.c2Prime.map{$0.position + contentShift},
                                     c3: residue.c3Prime.map{$0.position + contentShift},
                                     role: role,
                                     residueIndex: residueIndex,
                                     nucleotidePosition: nucleotidePosition)
  }
  
  private static func computeNucleicAcidOrientationVectors(samples: [NucleicAcidBackboneSample]) -> [SIMD3<Double>]
  {
    guard !samples.isEmpty else {return []}
    
    var orientations: [SIMD3<Double>] = []
    orientations.reserveCapacity(samples.count)
    var previousC2: SIMD3<Double>? = nil
    
    for index in 0..<samples.count
    {
      let sample: NucleicAcidBackboneSample = samples[index]
      var orientation: SIMD3<Double> = .zero
      if let c2: SIMD3<Double> = sample.c2, let c3: SIMD3<Double> = sample.c3
      {
        if let previous: SIMD3<Double> = previousC2
        {
          let midpoint: SIMD3<Double> = (c2 + previous * 2.0) * (1.0 / 3.0)
          orientation = safeNormalize(c3 - midpoint, fallback: .zero)
        }
        else
        {
          orientation = safeNormalize(c3 - c2, fallback: .zero)
        }
        previousC2 = c2
      }
      else if index > 0 && index + 1 < samples.count
      {
        let t0: SIMD3<Double> = sample.center - samples[index - 1].center
        let t1: SIMD3<Double> = samples[index + 1].center - sample.center
        orientation = safeNormalize(t0 + t1, fallback: SIMD3<Double>(0.0, 0.0, 1.0))
        previousC2 = nil
      }
      else
      {
        previousC2 = nil
      }
      orientations.append(orientation)
    }
    return orientations
  }
  
  private static func tangentAtNucleicAcidSamples(_ samples: [NucleicAcidBackboneSample], index: Int) -> SIMD3<Double>
  {
    let count: Int = samples.count
    let clampedIndex: Int = max(0, min(index, count - 1))
    guard count >= 2 else {return SIMD3<Double>(0.0, 0.0, 1.0)}
    if clampedIndex == 0
    {
      return normalize(samples[1].center - samples[0].center)
    }
    if clampedIndex == count - 1
    {
      return normalize(samples[clampedIndex].center - samples[clampedIndex - 1].center)
    }
    return normalize(samples[clampedIndex + 1].center - samples[clampedIndex - 1].center)
  }
  
  private static func ribbonStationsFromNucleicAcid(samples: [NucleicAcidBackboneSample],
                                                    secondaryStructure: [ProteinRibbonSecondaryStructure],
                                                    parameters: ProteinRibbonMeshParameters) -> [RibbonStation]
  {
    guard samples.count >= 2 else {return []}
    
    let centers: [SIMD3<Double>] = samples.map{$0.center}
    var orientationVectors: [SIMD3<Double>] = computeNucleicAcidOrientationVectors(samples: samples)
    let directionNormals: [SIMD3<Double>] = computeChainDirectionNormals(centers: centers)
    let chainTangents: [SIMD3<Double>] = computeChainTangents(directionNormals: directionNormals)
    // PyMOL RepCartoonComputeRoundHelices only runs for ss_t::HELIX, not NUCLEIC — keep C2'/C3' frame.
    refineCartoonOrientationNormals(orientations: &orientationVectors,
                                    tangents: chainTangents,
                                    secondaryStructure: secondaryStructure)
    
    let nucleotidePositions: [SIMD3<Double>] = samples.map{SIMD3<Double>($0.nucleotidePosition, 0.0, 0.0)}
    let nucleotideOrientationAxes: [SIMD3<Double>] = Array(repeating: SIMD3<Double>(0.0, 0.0, 1.0), count: nucleotidePositions.count)
    
    // PyMOL interpolates through trace atoms (phosphate / terminal O5'/O3'), not an approximating B-spline.
    let path: ProteinCatmullRomSpline = ProteinCatmullRomSpline(controlPoints: centers, orientationVectors: orientationVectors)
    let nucleotidePath: ProteinCatmullRomSpline = ProteinCatmullRomSpline(controlPoints: nucleotidePositions,
                                                                          orientationVectors: nucleotideOrientationAxes)
    
    let totalLength: Double = path.arcLength(1.0)
    let centerCount: Int = samples.count
    let subdivisionsPerSegment: Int = parameters.subdivisionsPerSegment
    let sampleCount: Int = (centerCount - 1) * subdivisionsPerSegment + 1
    
    var stations: [RibbonStation] = []
    stations.reserveCapacity(sampleCount)
    for sampleIndex in 0..<sampleCount
    {
      let targetLength: Double = Double(sampleIndex) / Double(sampleCount - 1) * totalLength
      let t: Double = path.parameterFromArcLength(targetLength: targetLength)
      let residuePosition: Double = nucleotidePath.evaluate(t).x
      let nearestSampleIndex: Int = min(max(Int(round(t * Double(centerCount - 1))), 0), centerCount - 1)
      
      let center: SIMD3<Double> = path.evaluate(t)
      let tangent: SIMD3<Double> = safeNormalize(path.derivative(t),
                                                 fallback: tangentAtNucleicAcidSamples(samples, index: nearestSampleIndex))
      let frame: (faceNormal: SIMD3<Double>, widthDirection: SIMD3<Double>) = ribbonFrame(at: t, tangent: tangent, path: path)
      
      stations.append(RibbonStation(center: center,
                                    tangent: tangent,
                                    faceNormal: frame.faceNormal,
                                    widthDirection: frame.widthDirection,
                                    secondaryStructure: .coil,
                                    sheetArrowFactor: 1.0,
                                    sheetArrowWidthFactor: 1.0,
                                    residuePosition: residuePosition))
    }
    return stations
  }
}
