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
import RenderKit
import iRASPAKit
import AVFoundation
import AVKit

class MovieCreationService: NSObject, MovieCreationProtocol
{
  private var myContext = 0
  
  var isWaitingForInputReady: Bool = false
  var writeSemaphore: DispatchSemaphore! = DispatchSemaphore(value: 0)
  var assetInput: AVAssetWriterInput? = nil
  
  func makeVideo(project: ProjectStructureNode, camera: RKCamera, size: NSSize, withReply reply: @escaping (URL) -> Void)
  {
    project.setInitialSelectionIfNeeded()
    camera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
    let maximumNumberOfFrames = project.sceneList.maximumNumberOfFrames ?? 0
    
    // Create a temporary file that is also accessible by the main-app.
    // At movie-completion will be moved to the url of the NSSavePabel.
    let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "24U2ZRZ6SC.nl.darkwing.iRASPA")!.appendingPathComponent("movie.mp4")
        
    // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    try? FileManager.default.removeItem(at: url as URL)
        
    let framesPerSecond: Int32 = Int32(project.numberOfFramesPerSecond)
    var frameNumber: Int64 = 0
    
    let qualitySetting: [String:AnyObject] = [AVVideoCodecKey:AVVideoCodecType.h264 as AnyObject,
                                              AVVideoWidthKey: size.width as AnyObject, AVVideoHeightKey: size.height as AnyObject,
                              AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: size.width*size.height*24 as AnyObject,
                                        AVVideoMaxKeyFrameIntervalKey: 150 as AnyObject,
                                        AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel as AnyObject,
                                        AVVideoAllowFrameReorderingKey: false as AnyObject,
                                        AVVideoH264EntropyModeKey:AVVideoH264EntropyModeCAVLC as AnyObject] as AnyObject]
    
    assetInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: qualitySetting)
    
    if let assetInput = assetInput
    {
      assetInput.addObserver(self, forKeyPath: "readyForMoreMediaData", options: NSKeyValueObservingOptions.new, context: &myContext)
      
      let bufferAttributes: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA) as   AnyObject]
      let assetInputAdaptor: AVAssetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetInput,   sourcePixelBufferAttributes: bufferAttributes)
      
      let assetWriter: AVAssetWriter
      do
      {
        // // AVFileTypeQuickTimeMovie (mov) or AVFileTypeMPEG4 (mp4)
        assetWriter = try AVAssetWriter(url: url as URL, fileType: AVFileType.mp4)
      }
      catch let error as NSError
      {
        print("MovieCreateService error: \(error)")
        return
      }
      
      assetWriter.add(assetInput)
      
      // begin encoding
      assetWriter.startWriting()
      assetWriter.startSession(atSourceTime: CMTime.zero)
  
      
      if let pixelBufferPool: CVPixelBufferPool = assetInputAdaptor.pixelBufferPool,
         let device: MTLDevice = self.selectDevice()
      {
        
        var pixelBuffer: CVPixelBuffer? = nil
        let cvReturn: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
        guard(cvReturn == kCVReturnSuccess) else
        {
          return
        }
        
        switch(project.movieType)
        {
        case .frames:
          project.sceneList.setAllMovieFramesToBeginning()
          for _ in 0..<maximumNumberOfFrames
          {
            autoreleasepool {
              let cvReturn: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
              guard(cvReturn == kCVReturnSuccess) else
              {
                return
              }
        
              if let pixelBuffer = pixelBuffer
              {
                let renderer = MetalRenderer(device: device, size: size, dataSource: project, camera: camera)
                self.makeCVPicture(projectStructureNode: project, pixelBuffer: pixelBuffer, renderer: renderer, camera: camera, size: size)
          
                // Wait until write is ready
                if (!assetInput.isReadyForMoreMediaData)
                {
                  isWaitingForInputReady = true
                  _ = writeSemaphore.wait(timeout: DispatchTime.distantFuture)
                }
          
                assetInputAdaptor.append(pixelBuffer, withPresentationTime: CMTimeMake(value: frameNumber, timescale: framesPerSecond))
              }
            }
            frameNumber += 1
            project.sceneList.advanceAllMovieFrames()
          }
        case .rotationY:
          let renderer = MetalRenderer(device: device, size: size, dataSource: project, camera: camera)
          for _ in stride(from: 0, through: 360, by: 3)
          {
            autoreleasepool {
              let cvReturn: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
              guard(cvReturn == kCVReturnSuccess) else
              {
                return
              }
        
              if let pixelBuffer = pixelBuffer
              {
                self.makeCVPicture(projectStructureNode: project, pixelBuffer: pixelBuffer, renderer: renderer, camera: camera, size: size)
          
                if (!assetInput.isReadyForMoreMediaData)
                {
                  isWaitingForInputReady = true
                  _ = writeSemaphore.wait(timeout: DispatchTime.distantFuture)
                }
          
                assetInputAdaptor.append(pixelBuffer, withPresentationTime: CMTimeMake(value: frameNumber, timescale: framesPerSecond))
              }
            }
            frameNumber += 1
            let theta: Double = -3.0 * Double.pi/180.0
            camera.rotateCameraAroundAxisY(angle: theta)
          }
          break
        case .rotationXYlemniscate:
          break
        }
        
        // end encoding
        if (!assetInput.isReadyForMoreMediaData)
        {
          isWaitingForInputReady = true
          _ = writeSemaphore.wait(timeout: DispatchTime.distantFuture)
        }
        
        assetInput.markAsFinished()
        
        assetWriter.finishWriting(completionHandler: {})
        
        reply(url as URL)
      }
    }
  }
  
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
  {
    if (context == &myContext) && (keyPath == "readyForMoreMediaData")
    {
      if let _ = change?[NSKeyValueChangeKey.newKey]
      {
        if (isWaitingForInputReady && (assetInput?.isReadyForMoreMediaData ?? true))
        {
          isWaitingForInputReady = false
          writeSemaphore.signal()
        }
      }
    }
    else
    {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }
  
  deinit
  {
    assetInput?.removeObserver(self, forKeyPath: "readyForMoreMediaData")
  }
  
  public func makeCVPicture(projectStructureNode: ProjectStructureNode, pixelBuffer: CVPixelBuffer, renderer: MetalRenderer, camera: RKCamera?, size: NSSize)
  {
    if let device = selectDevice(),
       let camera = camera
    {
      var coreVideoTextureCache: CVMetalTextureCache? = nil
      CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &coreVideoTextureCache)
    
      var renderTexture: CVMetalTexture? = nil
      CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache!, pixelBuffer, nil, MTLPixelFormat.bgra8Unorm, Int(size.width), Int(size.height), 0, &renderTexture)
          
      if let data: Data = renderer.renderPictureData(device: device, size: size, camera: camera, imageQuality: .rgb_8_bits, transparentBackground: false, renderQuality: .picture)
      {
        CVPixelBufferLockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
        if let destPixels: UnsafeMutablePointer<UInt8> = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self)
        {
          data.copyBytes(to: destPixels, count: data.count)
        }
        CVPixelBufferUnlockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
      }
    }
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
