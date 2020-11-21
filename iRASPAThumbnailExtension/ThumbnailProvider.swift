//
//  ThumbnailProvider.swift
//  iRASPAThumbnailExtension
//
//  Created by David Dubbeldam on 21/11/2020.
//  Copyright © 2020 David Dubbeldam. All rights reserved.
//

import QuickLookThumbnailing
import Cocoa

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
      /*
        handler(QLThumbnailReply(contextSize: request.maximumSize, currentContextDrawing: { () -> Bool in
            // Draw the thumbnail here.
            
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
        */
        /*
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
         
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
         
        // Third way: Set an image file URL.
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fileThumbnail", withExtension: "jpg")!), nil)
        
        */
            
      //debugPrint("yes")
      //let filePath = Bundle.main.path(forResource: "AppIcon", ofType: "png")!
      //let fileUrl = URL(fileURLWithPath: filePath)
      //handler(QLThumbnailReply(imageFileURL: fileUrl), nil)
      
      let image = NSImage(named: "AppIcon")!


          // size calculations

          let maximumSize = request.maximumSize
          let imageSize = image.size

          // calculate `newImageSize` and `contextSize` such that the image fits perfectly and respects the constraints
          var newImageSize = maximumSize
          var contextSize = maximumSize
          let aspectRatio = imageSize.height / imageSize.width
          let proposedHeight = aspectRatio * maximumSize.width

          if proposedHeight <= maximumSize.height {
              newImageSize.height = proposedHeight
              contextSize.height = max(proposedHeight.rounded(.down), request.minimumSize.height)
          } else {
              newImageSize.width = maximumSize.height / aspectRatio
              contextSize.width = max(newImageSize.width.rounded(.down), request.minimumSize.width)
          }

          handler(QLThumbnailReply(contextSize: contextSize, currentContextDrawing: { () -> Bool in
              // Draw the thumbnail here.

              // draw the image in the upper left corner
              //image.draw(in: CGRect(origin: .zero, size: newImageSize))

              // draw the image centered
              image.draw(in: CGRect(x: contextSize.width/2 - newImageSize.width/2,
                                    y: contextSize.height/2 - newImageSize.height/2,
                                    width: newImageSize.width,
                                    height: newImageSize.height))

              // Return true if the thumbnail was successfully drawn inside this block.
              return true
          }), nil)
    }
}
