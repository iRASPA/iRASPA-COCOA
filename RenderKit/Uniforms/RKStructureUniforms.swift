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

// IMPORTANT: must be aligned on 256-bytes boundaries (Metal constant buffers on iOS).
// Payload is 1136 bytes; padded to 1280 so array strides (index * stride) stay 256-aligned.
public struct RKStructureUniforms
{
  public var sceneIdentifier: Int32 = 0
  public var MovieIdentifier: Int32 = 0
  public var atomScaleFactor: Float = 1.0
  public var numberOfMultiSamplePoints: Int32 = 8;
  
  public var ambientOcclusion: Int32 = 1
  public var ambientOcclusionPatchNumber: Int32 = 64;
  public var ambientOcclusionPatchSize: Float = 16.0;
  public var ambientOcclusionInverseTextureSize: Float = 1.0/1024.0;
  
  public var atomHue: Float = 1.0
  public var atomSaturation: Float = 1.0
  public var atomValue: Float = 1.0
  public var structureIdentifier: Int32 = 0
  
  public var atomHDR: Int32 = 0
  public var atomHDRExposure: Float = 1.5;
  public var atomSelectionIntensity: Float = 0.5;
  public var clipAtomsAtUnitCell: Bool = false;
  
  public var atomAmbient: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var atomDiffuse: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var atomSpecular: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var atomShininess: Float = 4.0
  
  public var bondHue: Float = 0.0
  public var bondSaturation: Float = 0.0
  public var bondValue: Float = 0.0
  
  //----------------------------------------  128 bytes boundary
  
  public var bondHDR: Int32 = 0
  public var bondHDRExposure: Float = 1.5;
  public var bondSelectionIntensity: Float = 0.5;
  public var clipBondsAtUnitCell: Bool = false;
  
  public var bondAmbientColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var bondDiffuseColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var bondSpecularColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var bondShininess: Float = 4.0
  public var bondScaling: Float = 1.0
  public var bondColorMode: Int32 = 0
  
  public var unitCellScaling: Float = 1.0
  public var unitCellDiffuseColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var clipPlaneLeft: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var clipPlaneRight: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  //----------------------------------------  256 bytes boundary
  
  public var clipPlaneTop: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var clipPlaneBottom: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var clipPlaneFront: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var clipPlaneBack: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var modelMatrix: float4x4 = float4x4(Double4x4: double4x4())
  
  //----------------------------------------  384 bytes boundary
  
  public var inverseModelMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  public var boxMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  
  
  //----------------------------------------  512 bytes boundary
  public var inverseBoxMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  
  public var atomSelectionStripesDensity: Float = 0.25
  public var atomSelectionStripesFrequency: Float = 12.0
  public var atomSelectionWorleyNoise3DFrequency: Float = 2.0
  // Jitter 0 is not a neutral starting value: it puts every feature point at the exact centre of its
  // cell, which turns the noise into the cubic cell lattice and the selection into a grid of straight
  // dark walls. It matches the model-side default, as the bond and primitive jitters below do.
  public var atomSelectionWorleyNoise3DJitter: Float = 1.0
  
  public var atomAnnotationTextDisplacement: SIMD4<Float> = SIMD4<Float>()
  public var atomAnnotationTextColor: SIMD4<Float> = SIMD4<Float>(0.0,0.0,0.0,1.0)
  public var atomAnnotationTextScaling: Float = 1.0
  public var atomSelectionScaling: Float = 1.0
  public var bondSelectionScaling: Float = 1.25
  public var colorAtomsWithBondColor: Bool = false
  
  //----------------------------------------  640 bytes boundary
  
  public var transformationMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  public var transformationNormalMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  
  //----------------------------------------  768 bytes boundary
  
  public var primitiveAmbientFrontSide: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var primitiveDiffuseFrontSide: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 0.0, w:1.0)
  public var primitiveSpecularFrontSide: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var primitiveFrontSideHDR: Int32 = 1
  public var primitiveFrontSideHDRExposure: Float = 1.5
  public var primitiveOpacity: Float = 0.0
  public var primitiveShininessFrontSide: Float = 4.0
  
  public var primitiveAmbientBackSide: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var primitiveDiffuseBackSide: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 0.0, w:1.0)
  public var primitiveSpecularBackSide: SIMD4<Float> = SIMD4<Float>(x: 0.9, y: 0.9, z: 0.9, w: 1.0)
  public var primitiveBackSideHDR: Int32 = 1
  public var primitiveBackSideHDRExposure: Float = 1.5
  /// See `edgeCueingRibbons` in Common.h.
  public var edgeCueingRibbons: Float = 0.0
  public var primitiveShininessBackSide: Float = 4.0
  
  //----------------------------------------  896 bytes boundary
  
  public var bondSelectionStripesDensity: Float = 0.25
  public var bondSelectionStripesFrequency: Float = 12.0
  public var bondSelectionWorleyNoise3DFrequency: Float = 2.0
  public var bondSelectionWorleyNoise3DJitter: Float = 1.0
  
  public var primitiveSelectionStripesDensity: Float = 0.25;
  public var primitiveSelectionStripesFrequency: Float = 12.0;
  public var primitiveSelectionWorleyNoise3DFrequency: Float = 2.0;
  public var primitiveSelectionWorleyNoise3DJitter: Float = 1.0;

  public var primitiveSelectionScaling: Float = 1.01;
  public var primitiveSelectionIntensity: Float = 0.8;
  public var isUnity: Bool = false;
  /// See `edgeCueingAtoms` in Common.h.
  public var edgeCueingAtoms: Float = 0.0

  public var primitiveHue: Float = 1.0;
  public var primitiveSaturation: Float = 1.0;
  public var primitiveValue: Float = 1.0;
  /// See `ambientOcclusionStrength` in Common.h. Set by the renderer from the project rather than by
  /// the per-structure initializers, since it is one grading applied to the whole scene.
  public var ambientOcclusionStrength: Float = 0.0

  public var localAxisPosition: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var numberOfReplicas: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var ribbonCoilColor: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 1.0, z: 0.0, w: 1.0)
  public var ribbonHelixColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 0.0, z: 1.0, w: 1.0)
  public var ribbonSheetColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 0.0, w: 1.0)
  public var ribbonHDR: Int32 = 0
  public var ribbonHDRExposure: Float = 1.5
  public var ribbonHue: Float = 1.0
  public var ribbonSaturation: Float = 0.5
  public var ribbonValue: Float = 1.0
  public var ribbonAmbientOcclusion: Int32 = 1
  public var padRibbon1: Float = 0.0
  public var ribbonShininess: Float = 4.0
  public var padRibbon2: Float = 0.0
  public var ribbonAmbientColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var ribbonDiffuseColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var ribbonSpecularColor: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  //----------------------------------------  1136 bytes boundary
  // The bond occlusion atlas holds the internal bonds first and the external ones after them, so that a
  // structure needs only one texture; the base is where the second range starts.
  public var bondAmbientOcclusion: Int32 = 0
  public var bondAmbientOcclusionPatchNumber: Int32 = 1
  public var bondAmbientOcclusionPatchSize: Float = 1.0
  public var bondAmbientOcclusionInverseTextureSize: Float = 1.0
  public var externalBondAmbientOcclusionPatchBase: Int32 = 0
  public var padBondAmbientOcclusion0: Float = 0.0
  public var padBondAmbientOcclusion1: Float = 0.0
  public var padBondAmbientOcclusion2: Float = 0.0
  // Pad 112 bytes so stride is 1280 (multiple of 256) for set*BufferOffset.
  public var padAlignment2: SIMD4<Float> = SIMD4<Float>()
  public var padAlignment3: SIMD4<Float> = SIMD4<Float>()
  public var padAlignment4: SIMD4<Float> = SIMD4<Float>()
  public var padAlignment5: SIMD4<Float> = SIMD4<Float>()
  public var padAlignment6: SIMD4<Float> = SIMD4<Float>()
  public var padAlignment7: SIMD4<Float> = SIMD4<Float>()
  public var padAlignment8: SIMD4<Float> = SIMD4<Float>()
  //----------------------------------------  1280 bytes boundary

  /// Smallest shell a selection may be drawn at, as a multiple of the radius of what it marks.
  ///
  /// The shell depth-tests against the surface it covers, so it cannot be allowed to coincide with
  /// it exactly; 0.1% of clearance is ample for the rounding involved. It is only enough because the
  /// overlays shade at the same MSAA rate as the geometry they test against, both depths then being
  /// evaluated at the same points. When the rates were crossed the comparison was off by the depth
  /// slope times the sample offset, which beat 0.1% over most of any atom more than a few dozen
  /// pixels across and painted screen-aligned bands there; see AtomSelectionPerSampleFragmentShaderIn.
  static let minimumSelectionScaling: Double = 1.001

  public init()
  {
    
  }
  
  public init(structureIdentifier: Int, structure: RKRenderObject)
  {
    let boundingBox: SKBoundingBox = structure.cell.boundingBox
    let centerOfRotation: SIMD3<Double> = boundingBox.center
    
    //self.sceneIdentifier = Int32(sceneIdentifier)
    //self.MovieIdentifier = Int32(movieIdentifier)
    self.structureIdentifier = Int32(structureIdentifier)
    
    let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: centerOfRotation, withTranslation: structure.origin)
    self.modelMatrix = float4x4(Double4x4: modelMatrix)
    self.inverseModelMatrix = float4x4(Double4x4: modelMatrix.inverse)
    
    let numberOfReplicas: SIMD3<Int32> = structure.cell.numberOfReplicas
    self.numberOfReplicas = SIMD4<Float>(Float(numberOfReplicas.x),Float(numberOfReplicas.y),Float(numberOfReplicas.z),0.0)
    
    if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource
    {
      self.colorAtomsWithBondColor = structure.colorAtomsWithBondColor
    
      self.atomScaleFactor = Float(structure.atomScaleFactor)
      self.atomHue = Float(structure.atomHue)
      self.atomSaturation = Float(structure.atomSaturation)
      self.atomValue = Float(structure.atomValue)
    
      self.ambientOcclusion = structure.atomAmbientOcclusion ? 1: 0
      self.ambientOcclusionPatchNumber = Int32(structure.atomAmbientOcclusionPatchNumber)
      self.ambientOcclusionPatchSize = Float(structure.atomAmbientOcclusionPatchSize)
      self.ambientOcclusionInverseTextureSize = Float(1.0/Double(structure.atomAmbientOcclusionTextureSize))
    
      self.atomAmbient = Float(structure.atomAmbientIntensity) * SIMD4<Float>(color:  structure.atomAmbientColor)
      self.atomDiffuse = Float(structure.atomDiffuseIntensity) * SIMD4<Float>(color: structure.atomDiffuseColor)
      self.atomSpecular = Float(structure.atomSpecularIntensity) * SIMD4<Float>(color: structure.atomSpecularColor)
      self.atomShininess = Float(structure.atomShininess)
    
      self.atomHDR = structure.atomHDR ? 1 : 0
      self.atomHDRExposure = Float(structure.atomHDRExposure)

      self.edgeCueingAtoms = Float(structure.atomEdgeCueing.rawValue)
      
      self.clipAtomsAtUnitCell = structure.clipAtomsAtUnitCell
      
      self.atomSelectionStripesDensity = Float(structure.atomSelectionStripesDensity)
      self.atomSelectionStripesFrequency = Float(structure.atomSelectionStripesFrequency)
      self.atomSelectionWorleyNoise3DFrequency = Float(structure.atomSelectionWorleyNoise3DFrequency)
      self.atomSelectionWorleyNoise3DJitter = Float(structure.atomSelectionWorleyNoise3DJitter)
      self.atomSelectionScaling = Float(max(RKStructureUniforms.minimumSelectionScaling, structure.atomSelectionScaling))
      self.atomSelectionIntensity = Float(structure.atomSelectionIntensity)
      
      self.atomAnnotationTextColor = SIMD4<Float>(color: structure.atomTextColor)
      self.atomAnnotationTextScaling = Float(structure.atomTextScaling)
      self.atomAnnotationTextDisplacement = SIMD4<Float>(x: Float(structure.atomTextOffset.x),
                                                   y: Float(structure.atomTextOffset.y),
                                                   z: Float(structure.atomTextOffset.z),
                                                   w: 0.0)
      
    }
    
    if let structure: RKRenderUnitCellSource = structure as? RKRenderUnitCellSource
    {
      self.unitCellScaling =  Float(structure.unitCellScaleFactor)
      self.unitCellDiffuseColor = Float(structure.unitCellDiffuseIntensity) * SIMD4<Float>(color:  structure.unitCellDiffuseColor)
    }
    
   
    if let structure: RKRenderBondSource = structure as? RKRenderBondSource
    {
      self.bondScaling = Float(structure.bondScaleFactor)
      self.bondColorMode = Int32(structure.bondColorMode.rawValue)
    
      self.bondHDR = structure.bondHDR ? 1 : 0
      self.bondHDRExposure = Float(structure.bondHDRExposure)
      
      self.clipBondsAtUnitCell = structure.clipBondsAtUnitCell
    
      self.bondHue = Float(structure.bondHue)
      self.bondSaturation = Float(structure.bondSaturation)
      self.bondValue = Float(structure.bondValue)
    
      self.bondAmbientColor = Float(structure.bondAmbientIntensity) * SIMD4<Float>(color:  structure.bondAmbientColor)
      self.bondDiffuseColor = Float(structure.bondDiffuseIntensity) * SIMD4<Float>(color: structure.bondDiffuseColor)
      self.bondSpecularColor = Float(structure.bondSpecularIntensity) * SIMD4<Float>(color: structure.bondSpecularColor)
      self.bondShininess = Float(structure.bondShininess)
      
      self.isUnity = structure.isUnity
      
      self.bondAmbientOcclusion = structure.bondAmbientOcclusion ? 1 : 0
      self.bondAmbientOcclusionPatchNumber = Int32(structure.bondAmbientOcclusionPatchNumber)
      self.bondAmbientOcclusionPatchSize = Float(structure.bondAmbientOcclusionPatchSize)
      self.bondAmbientOcclusionInverseTextureSize = Float(1.0/Double(max(structure.bondAmbientOcclusionTextureSize, 1)))
      self.externalBondAmbientOcclusionPatchBase = Int32(structure.externalBondAmbientOcclusionPatchBase)
      
      self.bondSelectionStripesDensity = Float(structure.bondSelectionStripesDensity)
      self.bondSelectionStripesFrequency = Float(structure.bondSelectionStripesFrequency)
      self.bondSelectionWorleyNoise3DFrequency = Float(structure.bondSelectionWorleyNoise3DFrequency)
      self.bondSelectionWorleyNoise3DJitter = Float(structure.bondSelectionWorleyNoise3DJitter)
      self.bondSelectionIntensity = Float(structure.bondSelectionIntensity)
      self.bondSelectionScaling = Float(max(RKStructureUniforms.minimumSelectionScaling, structure.bondSelectionScaling))
    }
    
    if let structure: RKRenderPrimitiveSource = structure as? RKRenderPrimitiveSource
    {
      self.atomSelectionStripesDensity = Float(structure.atomSelectionStripesDensity)
      self.atomSelectionStripesFrequency = Float(structure.atomSelectionStripesFrequency)
      self.atomSelectionWorleyNoise3DFrequency = Float(structure.atomSelectionWorleyNoise3DFrequency)
      self.atomSelectionWorleyNoise3DJitter = Float(structure.atomSelectionWorleyNoise3DJitter)
      self.atomSelectionScaling = Float(max(RKStructureUniforms.minimumSelectionScaling, structure.atomSelectionScaling))
      self.atomSelectionIntensity = Float(structure.atomSelectionIntensity)
      
      let primitiveModelMatrix = float4x4(Double4x4: double4x4(simd_quatd: structure.primitiveOrientation))
      let primitiveNormalMatrix = float4x4(Double3x3: double3x3(simd_quatd: structure.primitiveOrientation).inverse.transpose)
      
      self.transformationMatrix = primitiveModelMatrix * float4x4(Double3x3: structure.primitiveTransformationMatrix)
      self.transformationNormalMatrix = primitiveNormalMatrix * float4x4(Double3x3: structure.primitiveTransformationMatrix.inverse.transpose)
      
      self.primitiveOpacity = Float(structure.primitiveOpacity)
      
      
      self.primitiveHue = Float(structure.primitiveHue)
      self.primitiveSaturation = Float(structure.primitiveSaturation)
      self.primitiveValue = Float(structure.primitiveValue)
      
      self.primitiveSelectionScaling = Float(max(RKStructureUniforms.minimumSelectionScaling, structure.primitiveSelectionScaling))
      self.primitiveSelectionStripesDensity = Float(structure.primitiveSelectionStripesDensity)
      self.primitiveSelectionStripesFrequency = Float(structure.primitiveSelectionStripesFrequency)
      self.primitiveSelectionWorleyNoise3DFrequency = Float(structure.primitiveSelectionWorleyNoise3DFrequency)
      self.primitiveSelectionWorleyNoise3DJitter = Float(structure.primitiveSelectionWorleyNoise3DJitter)
      self.primitiveSelectionIntensity = Float(structure.primitiveSelectionIntensity)
      
      self.primitiveFrontSideHDR = structure.primitiveFrontSideHDR ? 1 : 0
      self.primitiveFrontSideHDRExposure = Float(structure.primitiveFrontSideHDRExposure)
      self.primitiveAmbientFrontSide = Float(structure.primitiveFrontSideAmbientIntensity) * SIMD4<Float>(color: structure.primitiveFrontSideAmbientColor, opacity: structure.primitiveOpacity)
      self.primitiveDiffuseFrontSide = Float(structure.primitiveFrontSideDiffuseIntensity) * SIMD4<Float>(color: structure.primitiveFrontSideDiffuseColor, opacity: structure.primitiveOpacity)
      self.primitiveSpecularFrontSide = Float(structure.primitiveFrontSideSpecularIntensity) * SIMD4<Float>(color: structure.primitiveFrontSideSpecularColor, opacity: structure.primitiveOpacity)
      self.primitiveShininessFrontSide = Float(structure.primitiveFrontSideShininess)
      
      self.primitiveBackSideHDR = structure.primitiveBackSideHDR ? 1 : 0
      self.primitiveBackSideHDRExposure = Float(structure.primitiveBackSideHDRExposure)
      self.primitiveAmbientBackSide = Float(structure.primitiveBackSideAmbientIntensity) * SIMD4<Float>(color: structure.primitiveBackSideAmbientColor, opacity: structure.primitiveOpacity)
      self.primitiveDiffuseBackSide = Float(structure.primitiveBackSideDiffuseIntensity) * SIMD4<Float>(color: structure.primitiveBackSideDiffuseColor, opacity: structure.primitiveOpacity)
      self.primitiveSpecularBackSide = Float(structure.primitiveBackSideSpecularIntensity) * SIMD4<Float>(color: structure.primitiveBackSideSpecularColor, opacity: structure.primitiveOpacity)
      self.primitiveShininessBackSide = Float(structure.primitiveBackSideShininess)
    }
    
    let unitCell: double3x3 = structure.cell.unitCell
    let box: double3x3 = structure.cell.box
    let corner: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(structure.cell.minimumReplica.x), y: Double(structure.cell.minimumReplica.y), z: Double(structure.cell.minimumReplica.z))
    let corner2: SIMD3<Double> = unitCell * SIMD3<Double>(x: Double(structure.cell.maximumReplica.x)+1.0, y: Double(structure.cell.maximumReplica.y)+1.0, z: Double(structure.cell.maximumReplica.z)+1.0)
    
    
    self.boxMatrix = float4x4(Double3x3: box)
    let shift: SIMD3<Double> = structure.cell.unitCell * SIMD3<Double>(structure.cell.minimumReplica)
    self.boxMatrix[3][0] = Float(shift.x)
    self.boxMatrix[3][1] = Float(shift.y)
    self.boxMatrix[3][2] = Float(shift.z)
    self.inverseBoxMatrix = float4x4(Double3x3: box.inverse)
    
    
    // clipping planes are in object space
    let u_plane0: SIMD3<Double> = normalize(cross(box[0],box[1]))
    let u_plane1: SIMD3<Double> = normalize(cross(box[2],box[0]))
    let u_plane2: SIMD3<Double> = normalize(cross(box[1],box[2]))
    clipPlaneBack = SIMD4<Float>(x: u_plane0.x, y: u_plane0.y, z: u_plane0.z, w: -dot(u_plane0,corner))
    clipPlaneBottom = SIMD4<Float>(x: u_plane1.x, y: u_plane1.y, z: u_plane1.z, w: -dot(u_plane1,corner))
    clipPlaneLeft = SIMD4<Float>(x: u_plane2.x, y: u_plane2.y, z: u_plane2.z, w: -dot(u_plane2,corner))
    clipPlaneFront = -SIMD4<Float>(x: u_plane0.x, y: u_plane0.y, z: u_plane0.z, w: -dot(u_plane0,corner2))
    clipPlaneTop = -SIMD4<Float>(x: u_plane1.x, y: u_plane1.y, z: u_plane1.z, w: -dot(u_plane1,corner2))
    clipPlaneRight = -SIMD4<Float>(x: u_plane2.x, y: u_plane2.y, z: u_plane2.z, w: -dot(u_plane2,corner2))
    
    if let structure: RKRenderRibbonSource = structure as? RKRenderRibbonSource
    {
      let coilColor: SIMD3<Float> = structure.ribbonCoilColor
      let helixColor: SIMD3<Float> = structure.ribbonHelixColor
      let sheetColor: SIMD3<Float> = structure.ribbonSheetColor
      self.ribbonCoilColor = SIMD4<Float>(x: coilColor.x, y: coilColor.y, z: coilColor.z, w: 1.0)
      self.ribbonHelixColor = SIMD4<Float>(x: helixColor.x, y: helixColor.y, z: helixColor.z, w: 1.0)
      self.ribbonSheetColor = SIMD4<Float>(x: sheetColor.x, y: sheetColor.y, z: sheetColor.z, w: 1.0)
      self.ribbonHDR = structure.ribbonHDR ? 1 : 0
      self.ribbonHDRExposure = Float(structure.ribbonHDRExposure)
      self.edgeCueingRibbons = Float(structure.ribbonEdgeCueing.rawValue)
      self.ribbonHue = Float(structure.ribbonHue)
      self.ribbonSaturation = Float(structure.ribbonSaturation)
      self.ribbonValue = Float(structure.ribbonValue)
      self.ribbonAmbientOcclusion = structure.ribbonAmbientOcclusion ? 1 : 0
      self.ribbonAmbientColor = Float(structure.ribbonAmbientIntensity) * SIMD4<Float>(color: structure.ribbonAmbientColor)
      self.ribbonDiffuseColor = Float(structure.ribbonDiffuseIntensity) * SIMD4<Float>(color: structure.ribbonDiffuseColor)
      self.ribbonSpecularColor = Float(structure.ribbonSpecularIntensity) * SIMD4<Float>(color: structure.ribbonSpecularColor)
      self.ribbonShininess = Float(structure.ribbonShininess)
    }
    
    if let structure: RKRenderLocalAxesSource = structure as? RKRenderLocalAxesSource
    {
      let offset: SIMD3<Double> = structure.renderLocalAxis.offset
      let displacement = SIMD4<Float>(Float(offset.x),Float(offset.y),Float(offset.z),0.0);

      switch(structure.renderLocalAxis.position)
      {
      case RKLocalAxes.Position.none:
        localAxisPosition = SIMD4<Float>(0.0,0.0,0.0,1.0) + displacement
      case RKLocalAxes.Position.origin:
        localAxisPosition = SIMD4<Float>(0.0,0.0,0.0,1.0) + displacement
      case RKLocalAxes.Position.center:
        let pos = box * SIMD3<Double>(0.5,0.5,0.5)
        localAxisPosition = SIMD4<Float>(Float(pos.x),Float(pos.y),Float(pos.z),1.0)  + displacement
      case RKLocalAxes.Position.originBoundingBox:
        localAxisPosition = SIMD4<Float>(Float(boundingBox.minimum.x),Float(boundingBox.minimum.y),Float(boundingBox.minimum.z),1.0) + displacement
      case RKLocalAxes.Position.centerBoundingBox:
        localAxisPosition = SIMD4<Float>(Float(centerOfRotation.x), Float(centerOfRotation.y), Float(centerOfRotation.z), 1.0) + displacement
      }
    }
  }
  
  public init(structureIdentifier: Int, structure: RKRenderObject, inverseModelMatrix: double4x4)
  {
    self.init(structureIdentifier: structureIdentifier, structure: structure)
    
    let boundingBox: SKBoundingBox = structure.cell.boundingBox
    let centerOfRotation: SIMD3<Double> = boundingBox.center
    let modelMatrix: double4x4 = inverseModelMatrix * double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: centerOfRotation, withTranslation: structure.origin)
    self.modelMatrix = float4x4(Double4x4: modelMatrix)
    // the pair has to stay a pair: a shader that carries an eye-space point back into structure space, as
    // the clipping of the external bonds does, undoes exactly the matrix that took it there
    self.inverseModelMatrix = float4x4(Double4x4: modelMatrix.inverse)
  }
}
