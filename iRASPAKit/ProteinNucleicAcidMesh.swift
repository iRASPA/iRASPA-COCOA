/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
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
import SymmetryKit
import RenderKit

public struct ProteinNucleicAcidMeshBuilder
{
  /// PyMOL cartoon_ring_mode 1 filled planes + cartoon_ladder_mode 1 rungs, appended as one extra chain draw range.
  public static func appendRingAndLadderMeshes(mesh: inout RKRibbonMesh,
                                               geometry: DNANucleotideGeometry,
                                               basePairs: [DNANucleotideBasePair],
                                               contentShift: SIMD3<Double>,
                                               radius: Double,
                                               parameters: ProteinRibbonMeshParameters)
  {
    let drawRings: Bool = parameters.nucleicAcidRingMode == .filledPlanes
    let drawLadder: Bool = parameters.nucleicAcidLadderMode == .rungs
    guard drawRings || drawLadder else {return}
    
    let ringHalfThickness: Double = max(parameters.nucleicAcidRingWidth, 0.01) * radius * 0.5
    let ladderRadius: Double = max(parameters.nucleicAcidLadderRadius, 0.01) * radius
    let cylinderSegments: Int = max(parameters.nucleicAcidLadderSegments, 6)
    
    var auxiliaryVertices: [RKVertex] = []
    var auxiliaryIndices: [UInt32] = []
    auxiliaryVertices.reserveCapacity(geometry.residues.count * 48)
    auxiliaryIndices.reserveCapacity(geometry.residues.count * 96)
    
    if drawRings
    {
      let backboneColor: Float = SKNucleotideBase.vertexStructureTypeCode(.unknown, backbone: true)
      for residue in geometry.residues
      {
        let pickIndex: Int = residue.globalResidueIndex
        let baseColor: Float = SKNucleotideBase.vertexStructureTypeCode(residue.baseKind)
        if residue.riboseRingAtoms.count >= 3
        {
          appendFilledRingPlane(vertices: &auxiliaryVertices,
                                indices: &auxiliaryIndices,
                                ringPoints: residue.riboseRingPositions(contentShift: contentShift),
                                halfThickness: ringHalfThickness,
                                residuePickIndex: pickIndex,
                                structureType: backboneColor)
        }
        if residue.baseRingAtoms.count >= 3
        {
          appendFilledRingPlane(vertices: &auxiliaryVertices,
                                indices: &auxiliaryIndices,
                                ringPoints: residue.baseRingPositions(contentShift: contentShift),
                                halfThickness: ringHalfThickness,
                                residuePickIndex: pickIndex,
                                structureType: baseColor)
        }
      }
    }
    
    if drawLadder
    {
      for residue in geometry.residues
      {
        let pickIndex: Int = residue.globalResidueIndex
        let baseColor: Float = SKNucleotideBase.vertexStructureTypeCode(residue.baseKind)
        let base: SIMD3<Double>? = residue.baseAnchorPosition(contentShift: contentShift)
        
        if let c1: SIMD3<Double> = residue.c1PrimePosition(contentShift: contentShift),
           let baseAnchor: SIMD3<Double> = base
        {
          appendCylinder(vertices: &auxiliaryVertices,
                         indices: &auxiliaryIndices,
                         start: c1,
                         end: baseAnchor,
                         cylinderRadius: ladderRadius,
                         segments: cylinderSegments,
                         residuePickIndex: pickIndex,
                         structureType: baseColor)
        }
        
        if let phosphate: SIMD3<Double> = residue.phosphatePosition(contentShift: contentShift),
           let baseAnchor: SIMD3<Double> = base
        {
          let outer: SIMD3<Double> = phosphate * 0.333333 + baseAnchor * 0.666667
          appendCylinder(vertices: &auxiliaryVertices,
                         indices: &auxiliaryIndices,
                         start: outer,
                         end: baseAnchor,
                         cylinderRadius: ladderRadius,
                         segments: cylinderSegments,
                         residuePickIndex: pickIndex,
                         structureType: baseColor)
        }
      }
      
      for pair in basePairs
      {
        guard pair.residueGeometryIndexA >= 0, pair.residueGeometryIndexB >= 0 else {continue}
        guard pair.residueGeometryIndexA < geometry.residues.count,
              pair.residueGeometryIndexB < geometry.residues.count else {continue}
        let residueA: DNANucleotideResidueGeometry = geometry.residues[pair.residueGeometryIndexA]
        let residueB: DNANucleotideResidueGeometry = geometry.residues[pair.residueGeometryIndexB]
        guard let anchorA: SIMD3<Double> = residueA.baseAnchorPosition(contentShift: contentShift),
              let anchorB: SIMD3<Double> = residueB.baseAnchorPosition(contentShift: contentShift) else {continue}
        let pairColor: Float = SKNucleotideBase.vertexStructureTypeCode(residueA.baseKind)
        appendCylinder(vertices: &auxiliaryVertices,
                       indices: &auxiliaryIndices,
                       start: anchorA,
                       end: anchorB,
                       cylinderRadius: ladderRadius,
                       segments: cylinderSegments,
                       residuePickIndex: residueA.globalResidueIndex,
                       structureType: pairColor)
      }
    }
    
    guard !auxiliaryIndices.isEmpty else {return}
    let indexStart: Int = mesh.indices.count
    let vertexBase: UInt32 = UInt32(mesh.vertices.count)
    mesh.vertices.append(contentsOf: auxiliaryVertices)
    mesh.indices.reserveCapacity(mesh.indices.count + auxiliaryIndices.count)
    for localIndex in auxiliaryIndices
    {
      mesh.indices.append(vertexBase &+ localIndex)
    }
    mesh.chainDrawRanges.append(RKRibbonChainDrawRange(indexStart: indexStart,
                                                       indexCount: mesh.indices.count - indexStart))
  }
  
  private static func safeNormalize(_ vector: SIMD3<Double>, fallback: SIMD3<Double>) -> SIMD3<Double>
  {
    if length_squared(vector) < 1.0e-12
    {
      return fallback
    }
    return normalize(vector)
  }
  
  private static func makeVertex(position: SIMD3<Double>,
                                 normal: SIMD3<Double>,
                                 residuePickIndex: Int,
                                 structureType: Float) -> RKVertex
  {
    var vertex: RKVertex = RKVertex()
    vertex.position = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), 1.0)
    vertex.normal = SIMD4<Float>(Float(normal.x), Float(normal.y), Float(normal.z), 0.0)
    vertex.st = SIMD2<Float>(0.5, 0.5)
    vertex.pad = SIMD2<Float>(structureType, Float(residuePickIndex))
    vertex.stripeST = SIMD2<Float>(0.0, 0.0)
    return vertex
  }
  
  private static func pushTriangle(_ indices: inout [UInt32], _ a: UInt32, _ b: UInt32, _ c: UInt32)
  {
    indices.append(a)
    indices.append(b)
    indices.append(c)
  }
  
  private static func ringPlane(ringPoints: [SIMD3<Double>]) -> (center: SIMD3<Double>, normal: SIMD3<Double>)?
  {
    guard ringPoints.count >= 3 else {return nil}
    var center: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    for point in ringPoints
    {
      center += point
    }
    center /= Double(ringPoints.count)
    
    var accumulatedNormal: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    for index in 0..<ringPoints.count
    {
      let v0: SIMD3<Double> = ringPoints[index] - center
      let v1: SIMD3<Double> = ringPoints[(index + 1) % ringPoints.count] - center
      accumulatedNormal += cross(v0, v1)
    }
    return (center, safeNormalize(accumulatedNormal, fallback: SIMD3<Double>(0.0, 0.0, 1.0)))
  }
  
  private static func appendFilledRingPlane(vertices: inout [RKVertex],
                                            indices: inout [UInt32],
                                            ringPoints: [SIMD3<Double>],
                                            halfThickness: Double,
                                            residuePickIndex: Int,
                                            structureType: Float)
  {
    guard let plane: (center: SIMD3<Double>, normal: SIMD3<Double>) = ringPlane(ringPoints: ringPoints) else {return}
    let center: SIMD3<Double> = plane.center
    let normal: SIMD3<Double> = plane.normal
    let topOffset: SIMD3<Double> = normal * halfThickness
    let bottomOffset: SIMD3<Double> = normal * -halfThickness
    let downNormal: SIMD3<Double> = normal * -1.0
    
    let count: Int = ringPoints.count
    let topCenterIndex: UInt32 = UInt32(vertices.count)
    vertices.append(makeVertex(position: center + topOffset, normal: normal, residuePickIndex: residuePickIndex, structureType: structureType))
    let bottomCenterIndex: UInt32 = UInt32(vertices.count)
    vertices.append(makeVertex(position: center + bottomOffset, normal: downNormal, residuePickIndex: residuePickIndex, structureType: structureType))
    
    var topRim: [UInt32] = []
    var bottomRim: [UInt32] = []
    topRim.reserveCapacity(count)
    bottomRim.reserveCapacity(count)
    for index in 0..<count
    {
      topRim.append(UInt32(vertices.count))
      vertices.append(makeVertex(position: ringPoints[index] + topOffset, normal: normal, residuePickIndex: residuePickIndex, structureType: structureType))
      bottomRim.append(UInt32(vertices.count))
      vertices.append(makeVertex(position: ringPoints[index] + bottomOffset, normal: downNormal, residuePickIndex: residuePickIndex, structureType: structureType))
    }
    
    for index in 0..<count
    {
      let next: Int = (index + 1) % count
      pushTriangle(&indices, topCenterIndex, topRim[index], topRim[next])
      pushTriangle(&indices, bottomCenterIndex, bottomRim[next], bottomRim[index])
      
      let sideNormal: SIMD3<Double> = safeNormalize(cross((ringPoints[next] + topOffset) - (ringPoints[index] + topOffset), normal),
                                                    fallback: normal)
      let side0: UInt32 = UInt32(vertices.count)
      vertices.append(makeVertex(position: ringPoints[index] + topOffset, normal: sideNormal, residuePickIndex: residuePickIndex, structureType: structureType))
      let side1: UInt32 = UInt32(vertices.count)
      vertices.append(makeVertex(position: ringPoints[next] + topOffset, normal: sideNormal, residuePickIndex: residuePickIndex, structureType: structureType))
      let side2: UInt32 = UInt32(vertices.count)
      vertices.append(makeVertex(position: ringPoints[index] + bottomOffset, normal: sideNormal, residuePickIndex: residuePickIndex, structureType: structureType))
      let side3: UInt32 = UInt32(vertices.count)
      vertices.append(makeVertex(position: ringPoints[next] + bottomOffset, normal: sideNormal, residuePickIndex: residuePickIndex, structureType: structureType))
      pushTriangle(&indices, side0, side1, side3)
      pushTriangle(&indices, side0, side3, side2)
    }
  }
  
  private static func appendCylinder(vertices: inout [RKVertex],
                                     indices: inout [UInt32],
                                     start: SIMD3<Double>,
                                     end: SIMD3<Double>,
                                     cylinderRadius: Double,
                                     segments: Int,
                                     residuePickIndex: Int,
                                     structureType: Float)
  {
    let segmentCount: Int = segments < 3 ? 8 : segments
    let axis: SIMD3<Double> = end - start
    guard length_squared(axis) >= 1.0e-12 else {return}
    let tangent: SIMD3<Double> = normalize(axis)
    let reference: SIMD3<Double> = abs(tangent.z) < 0.9 ? SIMD3<Double>(0.0, 0.0, 1.0) : SIMD3<Double>(0.0, 1.0, 0.0)
    let bitangent: SIMD3<Double> = safeNormalize(cross(tangent, reference), fallback: SIMD3<Double>(1.0, 0.0, 0.0))
    let normalAxis: SIMD3<Double> = safeNormalize(cross(tangent, bitangent), fallback: bitangent)
    
    let startBase: UInt32 = UInt32(vertices.count)
    for segment in 0..<segmentCount
    {
      let angle: Double = 2.0 * Double.pi * Double(segment) / Double(segmentCount)
      let radial: SIMD3<Double> = bitangent * cos(angle) + normalAxis * sin(angle)
      vertices.append(makeVertex(position: start + radial * cylinderRadius,
                                 normal: radial,
                                 residuePickIndex: residuePickIndex,
                                 structureType: structureType))
    }
    let endBase: UInt32 = UInt32(vertices.count)
    for segment in 0..<segmentCount
    {
      let angle: Double = 2.0 * Double.pi * Double(segment) / Double(segmentCount)
      let radial: SIMD3<Double> = bitangent * cos(angle) + normalAxis * sin(angle)
      vertices.append(makeVertex(position: end + radial * cylinderRadius,
                                 normal: radial,
                                 residuePickIndex: residuePickIndex,
                                 structureType: structureType))
    }
    
    for segment in 0..<segmentCount
    {
      let next: UInt32 = UInt32((segment + 1) % segmentCount)
      let s0: UInt32 = startBase &+ UInt32(segment)
      let s1: UInt32 = startBase &+ next
      let e0: UInt32 = endBase &+ UInt32(segment)
      let e1: UInt32 = endBase &+ next
      pushTriangle(&indices, s0, s1, e1)
      pushTriangle(&indices, s0, e1, e0)
    }
  }
}
