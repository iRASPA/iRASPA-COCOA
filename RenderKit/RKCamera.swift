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
import BinaryCodable
import simd
import MathKit
import SymmetryKit


public class RKCamera: Decodable, BinaryDecodable, BinaryEncodable
{
  
  private var versionNumber: Int = 1
  private static var classVersionNumber: Int = 1
  
  public enum ResetDirectionType: Int
  {
    case plus_X = 0
    case plus_Y = 1
    case plus_Z = 2
    case minus_X = 3
    case minus_Y = 4
    case minus_Z = 5
  }
  
  public enum FrustrumType: Int
  {
    case perspective = 0
    case orthographic = 1
  }
  
  public var zNear: Double = 0.0
  public var zFar: Double = 0.0
  public var left: Double = -10.0
  public var right: Double = 10.0
  public var bottom: Double = -10.0
  public var top: Double = 10.0
  public var windowWidth: Double = 100.0
  public var windowHeight: Double = 100.0
  public var aspectRatio: Double = 100.0
  public var boundingBox: SKBoundingBox = SKBoundingBox()
  
  public var boundingBoxAspectRatio: Double = 1.0
  public var centerOfScene: double3 = double3(0,0,0)
  public var panning: double3 = double3(0.0,0.0,0.0)
  public var centerOfRotation: double3 = double3(0,0,0)
  public var eye: double3 = double3(0,0,0)
  public var distance: double3 = double3(0.0,0.0,50.0)
  public var orthoScale: Double = 1.0
  public var angleOfView: Double = 60.0
  public var frustrumType: FrustrumType = .orthographic
  public var resetDirectionType: ResetDirectionType = .plus_Z
  
  public var resetPercentage: Double = 0.85
  public var initialized: Bool = false
  
  public var worldRotation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  public var trackBallRotation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  public var rotationDelta: Double = 15.0
  
  public var bloomLevel: Double = 1.0
  public var bloomPulse: Double = 1.0
  
  public var viewMatrix: double4x4 = double4x4()
  
  private var cameraBoundingBox: SKBoundingBox
  {
    // use at least 5,5,5 as the minimum-size
    let center: double3 = boundingBox.minimum + (boundingBox.maximum - boundingBox.minimum) * 0.5
    let width: double3 = max(double3(5.0),boundingBox.maximum - boundingBox.minimum)
    return SKBoundingBox(center: center, width: width)
  }
  
  public var projectionMatrix: double4x4
  {
    get
    {
      switch(frustrumType)
      {
      case .orthographic:
        return glFrustumfOrthographic(left: left, right: right,  bottom: bottom,  top: top,  near: zNear, far: zFar)
      case .perspective:
        return glFrustumfPerspective(left: left, right: right, bottom: bottom, top: top, near: zNear, far: zFar)
      }
    }
  }
  
  
  // The "camera" or viewpoint is at (0., 0., 0.) in eye space. When you turn this into a vector [0 0 0 1] and multiply it by the inverse of the ModelView matrix, the resulting vector is the object-space location of the camera.
  public var position: double3
  {
    let cameraPosition: double4 = modelViewMatrix.inverse * double4(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
    
    // return distance vector to the center of the scene
    return double3(x: cameraPosition.x, y: cameraPosition.y, z: cameraPosition.z)
  }
  
  private var referenceDirection: simd_quatd
  {
    switch(resetDirectionType)
    {
    case .plus_Z:
      return simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    case .plus_Y:
      return simd_quatd(ix: sin(Double.pi / 4.0), iy: 0.0, iz: 0.0, r: cos(Double.pi / 4.0))
    case .plus_X:
      return simd_quatd(ix: 0.0, iy: sin(Double.pi / 4.0), iz: 0.0, r: cos(Double.pi / 4.0))
    case .minus_Z:
      return simd_quatd(ix: 0.0, iy: sin(Double.pi / 2.0), iz: 0.0, r: cos(Double.pi / 2.0))
    case .minus_Y:
      return simd_quatd(ix: sin(-Double.pi / 4.0), iy: 0.0, iz: 0.0, r: cos(-Double.pi / 4.0))
    case .minus_X:
      return simd_quatd(ix: 0.0, iy: sin(-Double.pi / 4.0), iz: 0.0, r: cos(-Double.pi / 4.0))
    }
  }
  
  public init()
  {
    var boundingBoxMinimum: double3
    var boundingBoxMaximum: double3
    
    zNear = 1.0
    zFar = 1000.0
    
    distance = double3(0.0, 0.0, 60.0)
    orthoScale = 10.0
    centerOfScene = double3(x: 10,y: 10,z: 10)
    centerOfRotation = double3(x: 10,y: 10,z: 10)
    panning = double3(0.0,0.0,0.0)
    eye = centerOfScene + distance + panning
    windowWidth = 1160
    windowHeight = 720
    angleOfView = 60.0 * Double.pi / 180.0
    resetPercentage = 0.85
    aspectRatio = windowWidth / windowHeight
    boundingBoxMinimum = double3(x: 0.0, y: 0.0, z: 0.0)
    boundingBoxMaximum = double3(x: 10.0, y: 10.0, z: 10.0)
    boundingBox = SKBoundingBox(minimum: boundingBoxMinimum, maximum: boundingBoxMaximum)
    boundingBoxAspectRatio = 1.0
    frustrumType = .orthographic;
    resetDirectionType = .plus_Z;
    
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0, y: 1, z:0))
  }
  
  public required init(camera: RKCamera)
  {
    self.zNear = camera.zNear
    self.zFar = camera.zFar
    self.left = camera.left
    self.right = camera.right
    self.bottom = camera.bottom
    self.top = camera.top
    self.windowWidth = camera.windowWidth
    self.windowHeight = camera.windowHeight
    self.aspectRatio = camera.aspectRatio
    self.boundingBox = camera.boundingBox
    self.boundingBoxAspectRatio = camera.boundingBoxAspectRatio
    self.centerOfScene = camera.centerOfScene
    self.centerOfRotation = camera.centerOfRotation
    self.panning = camera.panning
    self.eye = camera.eye
    self.distance = camera.distance
    self.orthoScale = camera.orthoScale
    self.angleOfView = camera.angleOfView
    self.frustrumType = camera.frustrumType
    self.resetDirectionType = camera.resetDirectionType
    
    self.bloomLevel = camera.bloomLevel
    
    self.resetPercentage = camera.resetPercentage
    self.initialized = camera.initialized
    
    self.worldRotation = camera.worldRotation
    self.trackBallRotation = camera.trackBallRotation
    self.rotationDelta = camera.rotationDelta
    
    self.viewMatrix = camera.viewMatrix

  }
  
  
  // MARK: -
  // MARK: NSCopying support
  
  public func copy(with zone: NSZone?) -> Any
  {
    return type(of: self).init(camera: self)
  }
  
  
  // MARK: -
  // MARK: Decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let versionNumber: Int = try container.decode(Int.self)
    if versionNumber > self.versionNumber
    {
      //throw iRASPAError.invalidArchiveVersion
    }
    
    self.zNear = try container.decode(Double.self)
    self.zFar = try container.decode(Double.self)
    self.windowWidth = try container.decode(Double.self)
    self.windowHeight = try container.decode(Double.self)
    self.aspectRatio = try container.decode(Double.self)
    
    
    self.boundingBox = try container.decode(SKBoundingBox.self)
    self.centerOfScene = try container.decode(double3.self)
    self.centerOfRotation = try container.decode(double3.self)
    
    self.panning = try container.decode(double3.self)
    
    self.eye = try container.decode(double3.self)
    
    self.distance = try container.decode(double3.self)
    self.orthoScale = try container.decode(Double.self)
    
    self.frustrumType = try FrustrumType(rawValue: container.decode(Int.self))!
    self.resetDirectionType = try  ResetDirectionType(rawValue: container.decode(Int.self))!
    
    self.angleOfView = try container.decode(Double.self)
    self.resetPercentage = try container.decode(Double.self)
    self.initialized = try container.decode(Bool.self)
    
    self.worldRotation = try container.decode(simd_quatd.self)
    
    self.trackBallRotation = try container.decode(simd_quatd.self)
    
    self.rotationDelta = try container.decode(Double.self)
    
    self.bloomLevel = try container.decode(Double.self)
    
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0, y: 1, z:0))
    
    self.initialized = false
  }
  
  
  

  public var EulerAngles: double3
  {
    return (trackBallRotation * worldRotation).EulerAngles
  }
  
  public var modelMatrix: double4x4
  {
    return double4x4(transformation: double4x4(simd_quatd: trackBallRotation * worldRotation * referenceDirection), aroundPoint: centerOfRotation)
  }
  
  public var modelViewMatrix: double4x4
  {
    get
    {
      // first rotate the actors, and then construct the modelView-matrix
      return viewMatrix*double4x4(transformation: double4x4(simd_quatd: trackBallRotation * worldRotation * referenceDirection), aroundPoint: centerOfRotation)
    }
  }

  public func pan(x panx: Double, y pany: Double)
  {
    panning.x += panx
    panning.y += pany
    eye = centerOfScene + distance + panning
    
    //centerOfRotation = centerOfScene
    
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0.0, y: 1.0, z: 0.0))
    updateCameraForWindowResize(width: windowWidth,height: windowHeight)

  }
  
  public func increaseDistance(_ deltaDistance: Double)
  {
    let transformedBoundingBox: SKBoundingBox = self.cameraBoundingBox.adjustForTransformation(self.modelMatrix)
    var delta: double3 = double3()
    delta.x = fabs(transformedBoundingBox.maximum.x-transformedBoundingBox.minimum.x)
    delta.y = fabs(transformedBoundingBox.maximum.y-transformedBoundingBox.minimum.y)
    delta.z = fabs(transformedBoundingBox.maximum.z-transformedBoundingBox.minimum.z)
    let focalLength: Double = 1.0 / tan(0.5 * angleOfView)
    
    switch(self.frustrumType)
    {
    case .orthographic:
      if ((orthoScale - 0.25 * deltaDistance) * focalLength > 0.0)
      {
        orthoScale -= 0.25 * deltaDistance
        distance.z = orthoScale * focalLength + 0.5 * delta.z
      }
    case .perspective:
      if (distance.z - 0.25 * deltaDistance > 0.0)
      {
        distance.z -= 0.25 * deltaDistance
        orthoScale = (distance.z - 0.5 * delta.z) * tan(0.5 * angleOfView)
      }
    }
      
    eye = centerOfScene + distance + panning
      
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0.0, y: 1.0, z: 0.0))
    updateCameraForWindowResize(width: windowWidth,height: windowHeight)
  }
  
  public func updateFieldOfView()
  {
    updateCameraForWindowResize(width: windowWidth,height: windowHeight)
  }
  
  public func updateCameraForWindowResize(width: Double, height: Double)
  {
    windowWidth = width
    windowHeight = height
    
    aspectRatio = windowWidth/windowHeight
    
    switch frustrumType
    {
    case .perspective:
      setCameraToPerspective()
    case .orthographic:
      setCameraToOrthographic()
    }
  }
  
  public func setCameraToPerspective()
  {
    frustrumType = .perspective
    
    let transformedBoundingBox: SKBoundingBox = self.cameraBoundingBox.adjustForTransformation(self.modelMatrix)
    
    var delta: double3 = double3(fabs(transformedBoundingBox.maximum.x-transformedBoundingBox.minimum.x),
                                 fabs(transformedBoundingBox.maximum.y-transformedBoundingBox.minimum.y),
                                 fabs(transformedBoundingBox.maximum.z-transformedBoundingBox.minimum.z))
    
    let inverseFocalPoint: Double = tan(angleOfView * 0.5)
    let focalPoint: Double = 1.0 / inverseFocalPoint
    
    distance.z = max(orthoScale * focalPoint + 0.5 * delta.z, 0.25)
    
    zNear = max(1.0, length(position) - 2.0 * max(delta.x,delta.y,delta.z))
    zFar = length(position) + 2.0 * max(delta.x,delta.y,delta.z)
    
    // halfHeight  half of frustum height at znear  znear∗tan(fov/2)
    // halfWidth   half of frustum width at znear   halfHeight×aspect
    // depth       depth of view frustum            zfar−znear
    
    if (aspectRatio > boundingBoxAspectRatio)
    {
      left =  -aspectRatio * zNear * inverseFocalPoint  / boundingBoxAspectRatio
      right = aspectRatio * zNear * inverseFocalPoint  / boundingBoxAspectRatio
      top = zNear * inverseFocalPoint  / boundingBoxAspectRatio
      bottom = -zNear * inverseFocalPoint  / boundingBoxAspectRatio
    }
    else
    {
      left = -zNear * inverseFocalPoint
      right = zNear * inverseFocalPoint
      top = zNear * inverseFocalPoint  / aspectRatio
      bottom = -zNear * inverseFocalPoint  / aspectRatio
    }
  }
  
  public func setCameraToOrthographic()
  {
    frustrumType = .orthographic
    
    let transformedBoundingBox: SKBoundingBox = self.cameraBoundingBox.adjustForTransformation(self.modelMatrix)
    
    var delta: double3 = double3(fabs(transformedBoundingBox.maximum.x-transformedBoundingBox.minimum.x),
                                 fabs(transformedBoundingBox.maximum.y-transformedBoundingBox.minimum.y),
                                 fabs(transformedBoundingBox.maximum.z-transformedBoundingBox.minimum.z))
    
    let inverseFocalPoint: Double = tan(angleOfView * 0.5)
    orthoScale = max(distance.z - 0.5 * delta.z, 0.25) * inverseFocalPoint
    
    zNear = max(1.0, length(position) - 2.0 * max(delta.x,delta.y,delta.z))
    zFar = length(position) + 2.0 * max(delta.x,delta.y,delta.z)
    
    if (aspectRatio > boundingBoxAspectRatio)
    {
      left =  -aspectRatio*orthoScale/boundingBoxAspectRatio;
      right = aspectRatio*orthoScale/boundingBoxAspectRatio;
      top = orthoScale/boundingBoxAspectRatio;
      bottom = -orthoScale/boundingBoxAspectRatio;
      
    }
    else
    {
      left = -orthoScale;
      right = orthoScale;
      top = orthoScale/aspectRatio;
      bottom = -orthoScale/aspectRatio;
    }
  }
  
  /*
  public func resetDistanceForNewBoundingBox()
  {
    let transformedBoundingBoxNew: SKBoundingBox = self.boundingBox.adjustForTransformation(self.modelMatrix)
    
    let deltaNew: double3 = double3(fabs(transformedBoundingBoxNew.maximum.x-transformedBoundingBoxNew.minimum.x),
                                    fabs(transformedBoundingBoxNew.maximum.y-transformedBoundingBoxNew.minimum.y),
                                    fabs(transformedBoundingBoxNew.maximum.z-transformedBoundingBoxNew.minimum.z))
    
    let inverseFocalLength: Double = tan(0.5 * angleOfView)

    // constant distance.z, adjust 'orthoScale' to new deltaNew.z
    orthoScale = (distance.z - 0.5 * deltaNew.z) * inverseFocalLength
    updateCameraForWindowResize(width: windowWidth,height: windowHeight)
  }*/
  
  public func resetForNewBoundingBox(_ box: SKBoundingBox)
  {
    let transformedBoundingBoxOld: SKBoundingBox = self.cameraBoundingBox.adjustForTransformation(self.modelMatrix)
    
    let deltaOld: double3 = double3(fabs(transformedBoundingBoxOld.maximum.x-transformedBoundingBoxOld.minimum.x),
                                    fabs(transformedBoundingBoxOld.maximum.y-transformedBoundingBoxOld.minimum.y),
                                    fabs(transformedBoundingBoxOld.maximum.z-transformedBoundingBoxOld.minimum.z))
    
    self.boundingBox = box
    let transformedBoundingBoxNew: SKBoundingBox = self.cameraBoundingBox.adjustForTransformation(self.modelMatrix)
    
    let deltaNew: double3 = double3(fabs(transformedBoundingBoxNew.maximum.x-transformedBoundingBoxNew.minimum.x),
                                    fabs(transformedBoundingBoxNew.maximum.y-transformedBoundingBoxNew.minimum.y),
                                    fabs(transformedBoundingBoxNew.maximum.z-transformedBoundingBoxNew.minimum.z))
    
    let inverseFocalLength: Double = tan(0.5 * angleOfView)
    let focalLength: Double = 1.0 / inverseFocalLength
    boundingBoxAspectRatio = deltaNew.x / deltaNew.y
    let distanceNew: Double = 0.5 * deltaNew.z + 0.5 * deltaNew.x * focalLength
    let distanceOld: Double = 0.5 * deltaOld.z + 0.5 * deltaOld.x * focalLength
    distance.z += (distanceNew - distanceOld)
    orthoScale = (distance.z - 0.5 * deltaNew.z) * inverseFocalLength
    
    centerOfScene = cameraBoundingBox.minimum + (cameraBoundingBox.maximum - cameraBoundingBox.minimum) * 0.5
    centerOfRotation = centerOfScene
    eye = centerOfScene + distance + panning
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0.0, y: 1.0, z: 0.0))
    
    updateCameraForWindowResize(width: windowWidth,height: windowHeight)
  }
  
  
  public func resetCameraToDirection()
  {
    initialized = true
    
    centerOfScene = cameraBoundingBox.minimum + (cameraBoundingBox.maximum - cameraBoundingBox.minimum) * 0.5
    centerOfRotation = centerOfScene
    
    worldRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    
    resetCameraDistance()
  }
  
  public func resetCameraDistance()
  {
    var delta: double3 = double3()
    
    initialized = true
    
    centerOfScene = cameraBoundingBox.minimum + (cameraBoundingBox.maximum - cameraBoundingBox.minimum) * 0.5
    centerOfRotation = centerOfScene
    
    let matrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: referenceDirection * worldRotation) , aroundPoint: centerOfRotation)
    let transformedBoundingBox: SKBoundingBox = self.cameraBoundingBox.adjustForTransformation(matrix)
    
    delta.x = fabs(transformedBoundingBox.maximum.x-transformedBoundingBox.minimum.x)
    delta.y = fabs(transformedBoundingBox.maximum.y-transformedBoundingBox.minimum.y)
    delta.z = fabs(transformedBoundingBox.maximum.z-transformedBoundingBox.minimum.z)
    
    let focalPoint: Double = 1.0 / tan(0.5 * angleOfView)
    boundingBoxAspectRatio = delta.x / delta.y
    orthoScale = 0.5 * delta.x / self.resetPercentage
    distance.z = orthoScale * focalPoint  + 0.5 * delta.z
    
    panning = double3(0.0,0.0,0.0)
    trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r:1.0)
    
    eye = centerOfScene + distance + panning
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0.0, y: 1.0, z: 0.0))
    
    updateCameraForWindowResize(width: windowWidth,height: windowHeight)
  }
  
  
  // This function computes the inverse camera transform according to its parameters
  public static func GluLookAt(eye: double3, center: double3, up: double3) -> double4x4
  {
    var up = up
    var forward: double3 = double3()
    var side: double3 = double3()
    var viewMatrix: double4x4
    var inv_length: Double
    
    forward.x = center.x - eye.x
    forward.y = center.y - eye.y
    forward.z = center.z - eye.z
    inv_length=1.0/sqrt((forward.x*forward.x)+(forward.y*forward.y)+(forward.z*forward.z));
    forward.x *= inv_length;
    forward.y *= inv_length;
    forward.z *= inv_length;
    
    inv_length = 1.0/sqrt((up.x*up.x)+(up.y*up.y)+(up.z*up.z))
    up.x *= inv_length
    up.y *= inv_length
    up.z *= inv_length
    
    /* Side = forward x up */
    side.x = forward.y * up.z - forward.z * up.y
    side.y = forward.z * up.x - forward.x * up.z
    side.z = forward.x * up.y - forward.y * up.x
    inv_length=1.0/sqrt((side.x*side.x)+(side.y*side.y)+(side.z*side.z))
    side.x *= inv_length
    side.y *= inv_length
    side.z *= inv_length
    
    /* Up = side x forward */
    up.x = side.y * forward.z - side.z * forward.y
    up.y = side.z * forward.x - side.x * forward.z
    up.z = side.x * forward.y - side.y * forward.x
    
    
    // note that the inverse matrix is setup, i.e. the transpose
    viewMatrix=double4x4([double4(x: side.x, y: up.x, z: -forward.x, w: 0), // 1th column
      double4(x: side.y, y: up.y, z: -forward.y, w: 0), // 2nd column
      double4(x: side.z, y: up.z, z: -forward.z, w: 0), // 3rd column
      double4(x: 0, y: 0, z: 0, w: 1)])                 // 4th column
    
    
    // set translation part
    viewMatrix[3][0] = -(viewMatrix[0][0]*eye.x+viewMatrix[1][0]*eye.y+viewMatrix[2][0]*eye.z);
    viewMatrix[3][1] = -(viewMatrix[0][1]*eye.x+viewMatrix[1][1]*eye.y+viewMatrix[2][1]*eye.z);
    viewMatrix[3][2] = -(viewMatrix[0][2]*eye.x+viewMatrix[1][2]*eye.y+viewMatrix[2][2]*eye.z);
    
    viewMatrix[3][0] = -eye.x
    viewMatrix[3][1] = -eye.y
    viewMatrix[3][2] = -eye.z
    
    return viewMatrix;
  }
  
  
  
  // http://www.songho.ca/opengl/gl_projectionmatrix.html
  public func glFrustumfPerspective(left: Double, right: Double,  bottom: Double,  top: Double,  near: Double, far: Double) -> double4x4
  {
    var m: double4x4 = double4x4()
    
    let _2n: Double = 2.0 * near
    let _1over_rml: Double = 1.0 / (right - left)
    let _1over_fmn: Double = 1.0 / (far - near);
    let _1over_tmb: Double = 1.0 / (top - bottom)
    
    m=double4x4([double4(x:_2n * _1over_rml, y: 0.0, z: 0.0, w: 0.0),
      double4(x:0.0, y: _2n * _1over_tmb, z: 0.0, w: 0.0),
      double4(x:(right + left) * _1over_rml, y: (top + bottom) * _1over_tmb, z: (-(far + near)) * _1over_fmn, w: -1.0),
      double4(x:0.0, y: 0.0, z: -(_2n * far * _1over_fmn),w: 0.0)])
    
    return m
  }
  
  
  
  
  func glFrustumfPerspective(fov: Double, aspectratio: Double, boundingBoxAspectRatio: Double, near: Double, far: Double) -> double4x4
  {
    var m: double4x4
    let _1over_fmn: Double = 1.0 / (near - far)
    let focolPoint: Double = 1.0/tan(0.5*fov)
  
    // When the Aspect Ratio is larger than unity, gluPerspective fixes the height, lengthens/shortens the width
    // When the Aspect Ratio is less than unity, gluPerspective fixes the width, lengthens/shortens the height
  
    m=double4x4(double4(x: focolPoint / (aspectratio > 1.0 ? aspectratio : 1.0), y: 0.0, z:0.0, w: 0.0),
                double4(x:0.0, y: focolPoint * (aspectratio < 1.0 ? aspectratio : 1.0), z: 0.0, w: 0.0),
                double4(x:0.0, y: 0.0, z: ((far + near)) * _1over_fmn, w: -1.0),
                double4(x:0.0, y: 0.0, z: (2.0 * near * far * _1over_fmn), w: 0.0))
  
    return m
  }

  
  
  
  
  public func glFrustumfOrthographic(left: Double, right: Double,  bottom: Double,  top: Double,  near: Double, far: Double) -> double4x4
  {
    var m: double4x4
    let _1over_rml: Double  = 1.0 / (right - left)
    let _1over_fmn: Double  = 1.0 / (far - near)
    let _1over_tmb : Double = 1.0 / (top - bottom)
    
    m=double4x4([double4(x:2.0 * _1over_rml, y: 0.0,z: 0.0,w: 0.0),
      double4(x:0.0, y: 2.0 * _1over_tmb, z: 0.0, w: 0.0),
      double4(x:0.0, y: 0.0, z: -2.0 * _1over_fmn, w: 0.0),
      double4(x:-(right + left) * _1over_rml, y: -(top + bottom) * _1over_tmb, z: (-(far + near)) * _1over_fmn, w: 1.0)])
    return m;
  }
  
  
  // projection: point in “world” -> model-view -> projection -> viewport -> point on “screen”
  // unprojection: point on “screen” -> viewport^(–1) -> projection^(–1) -> model-view^(–1) -> point in “world”
  
  // It turns out that, the way OpenGL calculates things, winZ == 0.0 (the screen) corresponds to objZ == –N (the near plane),
  // and winZ == 1.0 corresponds to objZ == –F (the far plane)
  
  // Since two points determine a line, we actually need to call gluUnProject() twice: once with winZ == 0.0, then again with winZ == 1.0
  // this will give us the world points that correspond to the mouse click on the near and far planes, respectively
  // https://www.opengl.org/wiki/GluProject_and_gluUnProject_code
  public func myGluUnProject(_ position: double3, inViewPort viewPort: NSRect) ->double3
  {
    var finalMatrix: double4x4
    var inVector: double4 = double4()
    
    // Map x and y from window coordinates
    inVector.x = (position.x - Double(viewPort.origin.x)) / Double(viewPort.size.width)
    inVector.y = (position.y - Double(viewPort.origin.y)) / Double(viewPort.size.height)
    inVector.z = Double(position.z)
    inVector.w = 1.0
    
    // Map to range -1 to 1 NDC-coordinates
    inVector.x = inVector.x * 2.0 - 1.0
    inVector.y = inVector.y * 2.0 - 1.0
    inVector.z = inVector.z * 2.0 - 1.0
    inVector.w = 1.0
    
    
    // Coordinate space ranges from -Wc to Wc in all three axes, where Wc is the Clip Coordinate W value.
    // OpenGL clips all coordinates outside this range.
    
    // transform from clip-coordinates to object coordinates
    finalMatrix = (self.projectionMatrix * self.modelViewMatrix).inverse
    let outVector:double4 = finalMatrix * inVector
    
    if(fabs(outVector.w ) < Double.leastNormalMagnitude)
    {
      return double3(x: 0.0, y: 0.0, z: 0.0)
    }
    else
    {
      return double3(x: outVector.x/outVector.w, y: outVector.y/outVector.w, z: outVector.z/outVector.w)
    }
  }
  
  public func myGluUnProject(_ position: double3, modelMatrix: double4x4, inViewPort viewPort: NSRect) ->double3
  {
    var finalMatrix: double4x4
    var inVector: double4 = double4()
    
    // Map x and y from window coordinates
    inVector.x = (position.x - Double(viewPort.origin.x)) / Double(viewPort.size.width)
    inVector.y = (position.y - Double(viewPort.origin.y)) / Double(viewPort.size.height)
    inVector.z = Double(position.z)
    inVector.w = 1.0
    
    // Map to range -1 to 1 NDC-coordinates
    inVector.x = inVector.x * 2.0 - 1.0
    inVector.y = inVector.y * 2.0 - 1.0
    inVector.z = inVector.z * 2.0 - 1.0
    inVector.w = 1.0
    
    
    // Coordinate space ranges from -Wc to Wc in all three axes, where Wc is the Clip Coordinate W value.
    // OpenGL clips all coordinates outside this range.
    
    // transform from clip-coordinates to object coordinates
    finalMatrix = (self.projectionMatrix * self.modelViewMatrix * modelMatrix).inverse
    let outVector:double4 = finalMatrix * inVector
    
    if(fabs(outVector.w ) < Double.leastNormalMagnitude)
    {
      return double3(x: 0.0, y: 0.0, z: 0.0)
    }
    else
    {
      return double3(x: outVector.x/outVector.w, y: outVector.y/outVector.w, z: outVector.z/outVector.w)
    }
  }
  
  
  public func myGluProject(_ position: double3, inViewPort viewPort: NSRect) ->double3
  {
    var outVector: double4 = double4()
    var finalVector: double3 = double3()
    
    // convert to clip-coordinates
    let mvpMatrix: double4x4 = self.projectionMatrix * self.modelViewMatrix
    outVector = mvpMatrix * double4(x: position.x, y: position.y, z: position.z, w: 1.0)
    
    // perform perspective division
    let factor: Double = 1.0 / outVector.w
    outVector.x *= factor
    outVector.y *= factor
    outVector.z *= factor
    
    // Map x, y to range 0-1
    finalVector.x = (0.5*outVector.x + 0.5) * Double(viewPort.size.width) + Double(viewPort.origin.x)
    finalVector.y = (0.5*outVector.y + 0.5) * Double(viewPort.size.height) + Double(viewPort.origin.y)
    finalVector.z = 0.5*outVector.z + 0.5    // Between 0 and 1, this is only correct when glDepthRange(0.0, 1.0)
    
    return finalVector
  }
  
  
  // http://www.3dkingdoms.com/selection.html
  public func selectPositionsInRectangle(_ positions: [double3], inRect rect: NSRect, withOrigin origin: double3, inViewPort bounds: NSRect) -> IndexSet
  {
    let Points0: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x), y: Double(rect.origin.y), z: 0.0), inViewPort: bounds)
    let Points1: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x), y: Double(rect.origin.y), z: 1.0), inViewPort: bounds)
    
    let Points2: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x), y: Double(rect.origin.y+rect.size.height), z: 0.0), inViewPort: bounds)
    let Points3: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x), y: Double(rect.origin.y+rect.size.height), z: 1.0), inViewPort: bounds)
    
    let Points4: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x+rect.size.width), y: Double(rect.origin.y+rect.size.height), z: 0.0), inViewPort: bounds)
    let Points5: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x+rect.size.width), y: Double(rect.origin.y+rect.size.height), z: 1.0), inViewPort: bounds)
    
    let Points6: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x+rect.size.width), y: Double(rect.origin.y), z: 0.0), inViewPort: bounds)
    let Points7: double3 = self.myGluUnProject(double3(x: Double(rect.origin.x+rect.size.width), y: Double(rect.origin.y), z: 1.0), inViewPort: bounds)
    
    
    let FrustrumPlane0: double3 = normalize(cross(Points0 - Points1, Points0 - Points2))
    let FrustrumPlane1: double3 = normalize(cross(Points2 - Points3, Points2 - Points4))
    let FrustrumPlane2: double3 = normalize(cross(Points4 - Points5, Points4 - Points6))
    let FrustrumPlane3: double3 = normalize(cross(Points6 - Points7, Points6 - Points0))
    
    let indexSet: NSMutableIndexSet = NSMutableIndexSet()
    let numberOfObjects: Int = positions.count
    for j in 0..<numberOfObjects
    {
      let position: double3 = positions[j] + origin
      if((dot(position-Points0,FrustrumPlane0)<0) &&
        (dot(position-Points2,FrustrumPlane1)<0) &&
        (dot(position-Points4,FrustrumPlane2)<0) &&
        (dot(position-Points6,FrustrumPlane3)<0))
      {
        indexSet.add(j)
      }
    }
    return IndexSet(indexSet)
  }
  
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(RKCamera.classVersionNumber)
    encoder.encode(self.zNear)
    encoder.encode(self.zFar)
    encoder.encode(self.left)
    encoder.encode(self.right)
    encoder.encode(self.bottom)
    encoder.encode(self.top)
    
    encoder.encode(self.boundingBox)
    
    encoder.encode(self.boundingBoxAspectRatio)
    encoder.encode(self.centerOfScene)
    encoder.encode(self.panning)
    encoder.encode(self.centerOfRotation)
    encoder.encode(self.eye)
    encoder.encode(self.distance)
    encoder.encode(self.orthoScale)
    encoder.encode(self.angleOfView)
    encoder.encode(self.frustrumType.rawValue)
    encoder.encode(self.resetDirectionType.rawValue)
    
    encoder.encode(self.resetPercentage)
    
    encoder.encode(self.worldRotation)
    encoder.encode(self.rotationDelta)
    
    encoder.encode(self.bloomLevel)
    encoder.encode(self.bloomPulse)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > RKCamera.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.zNear = try decoder.decode(Double.self)
    self.zFar = try decoder.decode(Double.self)
    self.left = try decoder.decode(Double.self)
    self.right = try decoder.decode(Double.self)
    self.bottom = try decoder.decode(Double.self)
    self.top = try decoder.decode(Double.self)
    
    self.boundingBox = try decoder.decode(SKBoundingBox.self)
    
    self.boundingBoxAspectRatio = try decoder.decode(Double.self)
    self.centerOfScene = try decoder.decode(double3.self)
    self.panning = try decoder.decode(double3.self)
    self.centerOfRotation = try decoder.decode(double3.self)
    self.eye = try decoder.decode(double3.self)
    self.distance = try decoder.decode(double3.self)
    self.orthoScale = try decoder.decode(Double.self)
    self.angleOfView = try decoder.decode(Double.self)
    self.frustrumType = try FrustrumType(rawValue: decoder.decode(Int.self))!
    self.resetDirectionType = try ResetDirectionType(rawValue: decoder.decode(Int.self))!
    
    self.resetPercentage = try decoder.decode(Double.self)
    
    self.worldRotation = try decoder.decode(simd_quatd.self)
    self.rotationDelta = try decoder.decode(Double.self)
    
    self.bloomLevel = try decoder.decode(Double.self)
    self.bloomPulse = try decoder.decode(Double.self)
    
    viewMatrix = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: double3(x: 0, y: 1, z:0))
    
    self.initialized = false
  }
  
}
