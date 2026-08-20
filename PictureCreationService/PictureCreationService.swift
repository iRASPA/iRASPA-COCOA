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
import iRASPAKit
import RenderKit
import BinaryCodable

class PictureCreationService: NSObject, PictureCreationProtocol
{
  func makePicture(project projectStructureNode: ProjectStructureNode, camera: RKCamera, size: NSSize, withReply reply: @escaping (NSData, NSString) -> Void)
  {
    projectStructureNode.renderBackgroundCachedImage = projectStructureNode.drawGradientCGImage()
    
    camera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
    
    // create Ambient Occlusion in higher quality
    //self.invalidateCachedAmbientOcclusionTexture(projectStructureNode.renderStructures)
    
    guard let device = selectDevice() else
    {
      reply(NSData(), "no Metal device available" as NSString)
      return
    }

    let renderer: MetalRenderer = MetalRenderer(device: device, size: size, dataSource: projectStructureNode, camera: camera)

    guard let data: Data = renderer.renderPicture(device: device, size: size, imagePhysicalSizeInInches: projectStructureNode.renderImagePhysicalSizeInInches, camera: camera, imageQuality: projectStructureNode.renderImageQuality, renderQuality: .picture, renderMode: projectStructureNode.pictureRenderMode, pathTracerSettings: projectStructureNode.picturePathTracerSettings) else
    {
      reply(NSData(), "rendering produced no image (\(renderer.lastPictureDiagnostic))" as NSString)
      return
    }

    reply(data as NSData, renderer.lastPictureDiagnostic as NSString)
  }
  
  func selectDevice() -> MTLDevice?
  {
    guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
        debugPrint( "Failed to get the system's default Metal device." )
        return nil
    }
    
    let devices: [MTLDevice] = MTLCopyAllDevices()
       
    var externalGPUs = [MTLDevice]()
    var integratedGPUs = [MTLDevice]()
    var discreteGPUs = [MTLDevice]()
            
    for device in devices
    {
      if device.isRemovable
      {
        externalGPUs.append(device)
      }
      else if device.isLowPower
      {
        integratedGPUs.append(device)
      }
      else
      {
        discreteGPUs.append(device)
      }
    }
    
    if discreteGPUs.count <= 1
    {
      return defaultDevice
    }
    
    if let index: Int = discreteGPUs.map({$0.registryID}).firstIndex(of: defaultDevice.registryID)
    {
      discreteGPUs.remove(at: index)
    }
    
    return (discreteGPUs + externalGPUs + [defaultDevice]).first
  }
}
