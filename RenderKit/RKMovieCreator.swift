/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import LogViewKit
import AVFoundation
import AVKit

private var myContext = 0

// NSObject because of KVO
public class RKMovieCreator: NSObject
{
  var url: URL = URL(fileURLWithPath: "")
  
  var assetInput: AVAssetWriterInput
  var assetInputAdaptor: AVAssetWriterInputPixelBufferAdaptor
  var assetWriter: AVAssetWriter? = nil
  var qualitySetting: [String:AnyObject]
  var framesPerSecond: Int32 = 15
  var isWaitingForInputReady: Bool = false
  var writeSemaphore: DispatchSemaphore! = DispatchSemaphore(value: 0)
  
  var width: Int
  var height: Int
  
  var frameNumber: Int64 = 0
  
  let bytesPerRow: Int
  
  var renderer: RenderViewController? = nil
  
  var pixelBufferPool: CVPixelBufferPool? = nil
  var pixelBuffer: CVPixelBuffer? = nil
  weak var provider: RenderViewController?
  
  public init(url: URL,width: Int, height: Int, framesPerSecond: Int, provider: RenderViewController)
  {
    self.renderer = provider
    self.url = url
    self.framesPerSecond = Int32(framesPerSecond)
    self.provider = provider
    
    qualitySetting = [AVVideoCodecKey:AVVideoCodecH264 as AnyObject, AVVideoWidthKey: width as AnyObject, AVVideoHeightKey: height as AnyObject,
      AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: width*height*24 as AnyObject, AVVideoMaxKeyFrameIntervalKey: 150 as AnyObject, AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel as AnyObject, AVVideoAllowFrameReorderingKey: false as AnyObject, AVVideoH264EntropyModeKey:AVVideoH264EntropyModeCAVLC as AnyObject] as AnyObject]
    
    self.width = width
    self.height = height
    
    bytesPerRow = width * 4
    
    self.assetInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: qualitySetting)
    
    let bufferAttributes: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA) as AnyObject]
    self.assetInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetInput, sourcePixelBufferAttributes: bufferAttributes)
    
    do
    {
      // // AVFileTypeQuickTimeMovie (mov) or AVFileTypeMPEG4 (mp4)
      self.assetWriter = try AVAssetWriter(url: url, fileType: AVFileType.mp4)
    }
    catch let error as NSError
    {
      fatalError("\(error)")
    }
    
    super.init()
    
    assetWriter?.add(assetInput)
    
    assetInput.addObserver(self, forKeyPath: "readyForMoreMediaData", options: NSKeyValueObservingOptions.new, context: &myContext)
  }
  
  public func beginEncoding()
  {
    let fileCoordinator: NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
    var error: NSError?
    fileCoordinator.coordinate(writingItemAt: self.url, options: NSFileCoordinator.WritingOptions.forMerging, error: &error, byAccessor:
      {
        writeUrl in
        
        // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
        do
        {
          try FileManager.default.removeItem(at: writeUrl)
        }
        catch _ as NSError
        {
        }
        
        self.assetWriter?.startWriting()
        self.assetWriter?.startSession(atSourceTime: CMTime.zero)
        return
    })

    
    
    pixelBufferPool = assetInputAdaptor.pixelBufferPool
    
    let cvReturn: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool!, &pixelBuffer)
    guard(cvReturn == kCVReturnSuccess) else
    {
      LogQueue.shared.error(destination: provider?.view.window?.windowController, message: "Movie failed (could not create a pixelBuffer)")
      return
    }
  }
  
  
  
  public func addFrameToVideo()
  {

    let cvReturn: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool!, &pixelBuffer)
    guard(cvReturn == kCVReturnSuccess) else
    {
      LogQueue.shared.error(destination: provider?.view.window?.windowController, message: "Movie failed (could not create a pixelBuffer)")
      return
    }

    renderer?.makeCVPicture(pixelBuffer!)
    
    // Wait until write is ready
    if (!assetInput.isReadyForMoreMediaData)
    {
      isWaitingForInputReady = true
      _ = writeSemaphore.wait(timeout: DispatchTime.distantFuture)
    }
    let fileCoordinator: NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
    var error: NSError?
    fileCoordinator.coordinate(writingItemAt: self.url, options: NSFileCoordinator.WritingOptions.forMerging, error: &error, byAccessor:
      {
        writeUrl in
        self.assetInputAdaptor.append(self.pixelBuffer!, withPresentationTime: CMTimeMake(value: self.frameNumber, timescale: self.framesPerSecond))
        self.frameNumber = self.frameNumber + 1
        return
    })

  }
  
  public func endEncoding()
  {
    if (!assetInput.isReadyForMoreMediaData)
    {
      isWaitingForInputReady = true
      _ = writeSemaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    assetInput.markAsFinished()
    
    assetWriter?.finishWriting(completionHandler: {})
  }
  

  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
  {
    if (context == &myContext) && (keyPath == "readyForMoreMediaData")
    {
      if let _ = change?[NSKeyValueChangeKey.newKey]
      {
        if (isWaitingForInputReady && assetInput.isReadyForMoreMediaData)
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
    assetInput.removeObserver(self, forKeyPath: "readyForMoreMediaData")
  }
}
