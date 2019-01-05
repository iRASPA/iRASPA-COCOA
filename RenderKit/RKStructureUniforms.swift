/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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

// IMPORTANT: must be aligned on 256-bytes boundaries
// current number of bytes: 512 bytes
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
  
  public var changeHueSaturationValue: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var atomHDR: Int32 = 0
  public var atomHDRExposure: Float = 1.5;
  public var atomHDRBloomLevel: Float = 0.5;
  public var clipAtomsAtUnitCell: Bool = false;
  
  public var atomAmbient: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var atomDiffuse: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var atomSpecular: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var atomShininess: Float = 4.0
  
  public var bondHue: Float = 0.0
  public var bondSaturation: Float = 0.0
  public var bondValue: Float = 0.0
  
  //----------------------------------------  128 bytes boundary
  
  public var bondHDR: Int32 = 0
  public var bondHDRExposure: Float = 1.5;
  public var bondHDRBloomLevel: Float = 1.0;
  public var clipBondsAtUnitCell: Bool = false;
  
  
  public var bondAmbientColor: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var bondDiffuseColor: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var bondSpecularColor: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var bondShininess: Float = 4.0
  public var bondScaling: Float = 1.0
  public var bondColorMode: Int32 = 0
  
  public var unitCellScaling: Float = 1.0
  public var unitCellDiffuseColor: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var clipPlaneLeft: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var clipPlaneRight: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  //----------------------------------------  256 bytes boundary
  
  public var clipPlaneTop: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var clipPlaneBottom: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var clipPlaneFront: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var clipPlaneBack: float4 = float4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  
  public var modelMatrix: float4x4 = float4x4(Double4x4: double4x4())
  
  //----------------------------------------  384 bytes boundary
  
  public var boxMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  public var atomSelectionStripesDensity: Float = 0.25
  public var atomSelectionStripesFrequency: Float = 12.0
  public var atomSelectionWorleyNoise3DFrequency: Float = 2.0
  public var atomSelectionWorleyNoise3DJitter: Float = 0.0
  
  public var atomAnnotationTextDisplacement: float4 = float4()
  public var atomAnnotationTextColor: float4 = float4(0.0,0.0,0.0,1.0)
  public var atomAnnotationTextScaling: Float = 1.0
  public var bondAnnotationTextScaling: Float = 1.0
  public var selectionScaling: Float = 1.25
  public var pad: Int32 = 0
  
  
  public init()
  {
    
  }
  
  public init(sceneIdentifier: Int, movieIdentifier: Int, structure: RKRenderStructure)
  {
    let boundingBox: SKBoundingBox = structure.cell.boundingBox
    let centerOfRotation: double3 = boundingBox.center
    
    let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: centerOfRotation, withTranslation: structure.origin)
    
    let hsv: double4 = double4(x: structure.atomHue, y: structure.atomSaturation, z: structure.atomValue, w: 0.0)
    
    self.sceneIdentifier = Int32(sceneIdentifier)
    self.MovieIdentifier = Int32(movieIdentifier)
    self.atomScaleFactor = GLfloat(structure.atomScaleFactor)
    self.modelMatrix = float4x4(Double4x4: modelMatrix)
    self.changeHueSaturationValue = float4(Double4: hsv)
    
    self.ambientOcclusion = structure.atomAmbientOcclusion ? 1: 0
    self.ambientOcclusionPatchNumber = Int32(structure.atomAmbientOcclusionPatchNumber)
    self.ambientOcclusionPatchSize = GLfloat(structure.atomAmbientOcclusionPatchSize)
    self.ambientOcclusionInverseTextureSize = GLfloat(1.0/Double(structure.atomAmbientOcclusionTextureSize))
    
    
    self.atomAmbient = Float(structure.atomAmbientIntensity) * float4(color:  structure.atomAmbientColor)
    self.atomDiffuse = Float(structure.atomDiffuseIntensity) * float4(color: structure.atomDiffuseColor)
    self.atomSpecular = Float(structure.atomSpecularIntensity) * float4(color: structure.atomSpecularColor)
    self.atomShininess = GLfloat(structure.atomShininess)
    
    
    self.bondScaling = GLfloat(structure.bondScaleFactor)
    self.bondColorMode = Int32(structure.bondColorMode.rawValue)
    
    self.unitCellScaling =  GLfloat(structure.unitCellScaleFactor)
    self.unitCellDiffuseColor = Float(structure.unitCellDiffuseIntensity) * float4(color:  structure.unitCellDiffuseColor)
    
    self.atomHDR = structure.atomHDR ? 1 : 0
    self.atomHDRExposure = GLfloat(structure.atomHDRExposure)
    self.atomHDRBloomLevel = GLfloat(structure.atomHDRBloomLevel)
    self.clipAtomsAtUnitCell = structure.clipAtomsAtUnitCell
    
    self.bondHDR = structure.bondHDR ? 1 : 0
    self.bondHDRExposure = GLfloat(structure.bondHDRExposure)
    self.bondHDRBloomLevel = GLfloat(structure.bondHDRBloomLevel)
    self.clipBondsAtUnitCell = structure.clipBondsAtUnitCell
    
    self.bondHue = GLfloat(structure.bondHue)
    self.bondSaturation = GLfloat(structure.bondSaturation)
    self.bondValue = GLfloat(structure.bondValue)
    
    self.bondAmbientColor = Float(structure.bondAmbientIntensity) * float4(color:  structure.bondAmbientColor)
    self.bondDiffuseColor = Float(structure.bondDiffuseIntensity) * float4(color: structure.bondDiffuseColor)
    self.bondSpecularColor = Float(structure.bondSpecularIntensity) * float4(color: structure.bondSpecularColor)
    self.bondShininess = GLfloat(structure.bondShininess)
    
    
    let unitCell: double3x3 = structure.cell.unitCell
    let box: double3x3 = structure.cell.box
    let corner: double3 = unitCell * double3(x: Double(structure.cell.minimumReplica.x), y: Double(structure.cell.minimumReplica.y), z: Double(structure.cell.minimumReplica.z))
    let corner2: double3 = unitCell * double3(x: Double(structure.cell.maximumReplica.x)+1.0, y: Double(structure.cell.maximumReplica.y)+1.0, z: Double(structure.cell.maximumReplica.z)+1.0)
    
    
    self.boxMatrix = float4x4(Double3x3: box)
    let shift: double3 = structure.cell.unitCell * double3(structure.cell.minimumReplica)
    self.boxMatrix[3][0] = Float(shift.x)
    self.boxMatrix[3][1] = Float(shift.y)
    self.boxMatrix[3][2] = Float(shift.z)
    
    self.selectionScaling = Float(max(1.001,structure.renderSelectionScaling)) // avoid artifacts
    self.atomSelectionStripesDensity = Float(structure.renderSelectionStripesDensity)
    self.atomSelectionStripesFrequency = Float(structure.renderSelectionStripesFrequency)
    self.atomSelectionWorleyNoise3DFrequency = Float(structure.renderSelectionWorleyNoise3DFrequency)
    self.atomSelectionWorleyNoise3DJitter = Float(structure.renderSelectionWorleyNoise3DJitter)
    
    self.atomAnnotationTextColor = float4(color: structure.renderTextColor)
    self.atomAnnotationTextScaling = Float(structure.renderTextScaling)
    self.bondAnnotationTextScaling = 1.0
    self.atomAnnotationTextDisplacement = float4(x: Float(structure.renderTextOffset.x),
                                                 y: Float(structure.renderTextOffset.y),
                                                 z: Float(structure.renderTextOffset.z),
                                                 w: 0.0)
    
    // clipping planes are in object space
    let u_plane0: double3 = normalize(cross(box[0],box[1]))
    let u_plane1: double3 = normalize(cross(box[2],box[0]))
    let u_plane2: double3 = normalize(cross(box[1],box[2]))
    clipPlaneBack = float4(x: u_plane0.x, y: u_plane0.y, z: u_plane0.z, w: -dot(u_plane0,corner))
    clipPlaneBottom = float4(x: u_plane1.x, y: u_plane1.y, z: u_plane1.z, w: -dot(u_plane1,corner))
    clipPlaneLeft = float4(x: u_plane2.x, y: u_plane2.y, z: u_plane2.z, w: -dot(u_plane2,corner))
    clipPlaneFront = -float4(x: u_plane0.x, y: u_plane0.y, z: u_plane0.z, w: -dot(u_plane0,corner2))
    clipPlaneTop = -float4(x: u_plane1.x, y: u_plane1.y, z: u_plane1.z, w: -dot(u_plane1,corner2))
    clipPlaneRight = -float4(x: u_plane2.x, y: u_plane2.y, z: u_plane2.z, w: -dot(u_plane2,corner2))
  }
  
  public init(sceneIdentifier: Int, movieIdentifier: Int, structure: RKRenderStructure, inverseModelMatrix: double4x4)
  {
    self.init(sceneIdentifier: sceneIdentifier, movieIdentifier: movieIdentifier, structure: structure)
    
    let boundingBox: SKBoundingBox = structure.cell.boundingBox
    let centerOfRotation: double3 = boundingBox.center
    let modelMatrix: double4x4 = inverseModelMatrix * double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: centerOfRotation, withTranslation: structure.origin)
    self.modelMatrix = float4x4(Double4x4: modelMatrix)
  }
}
