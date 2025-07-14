//
//  ThumbnailProvider.swift
//  iRASPAThumbnailExtension
//
//  Created by David Dubbeldam on 21/11/2020.
//  Copyright © 2020 David Dubbeldam. All rights reserved.
//

import QuickLookThumbnailing
import Cocoa
import BinaryCodable
import ZIPFoundation
import iRASPAKit
import RenderKit

class ThumbnailProvider: QLThumbnailProvider
{
  override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void)
  {
    // set fall-back image
    var image: NSImage? = NSImage(named: "MOF")
    
    // size calculations
    let maximumSize: CGSize = request.maximumSize
    
    guard let projectTreeNode = ProjectTreeNode(url: request.fileURL, preview: true) else {return}
    projectTreeNode.unwrapLazyLocalPresentedObjectIfNeeded()
          
    if let project: ProjectStructureNode  = projectTreeNode.representedObject.loadedProjectStructureNode,
       let device = MTLCreateSystemDefaultDevice(),
       project.sceneList.totalNumberOfAtoms < 5000
    {
      let camera: RKCamera = RKCamera()
      
      project.setPreviewDefaults(camera: camera, size: maximumSize)
      
      let renderer: MetalRenderer = MetalRenderer(device: device, size: maximumSize, dataSource: project, camera: camera)
      
      if let data: Data = renderer.renderPicture(device: device, size: maximumSize, imagePhysicalSizeInInches: project.renderImagePhysicalSizeInInches, camera: camera, imageQuality: .rgb_8_bits, renderQuality: .low)
      {
        image = NSImage(data: data)
          
        handler(QLThumbnailReply(contextSize: maximumSize, currentContextDrawing: { () -> Bool in
                     
        image?.draw(in: CGRect(x: 0,
                               y: 0,
                               width: maximumSize.width,
                               height: maximumSize.height))

        // Return true if the thumbnail was successfully drawn inside this block.
        return true
        }), nil)
      }
    }
    else
    {
      let imageSize = image?.size ?? NSSize()

      // calculate `newImageSize` and `contextSize` such that the image fits perfectly and respects the constraints
      var newImageSize = maximumSize
      var contextSize = maximumSize
      let aspectRatio = imageSize.height / imageSize.width
      let proposedHeight = aspectRatio * maximumSize.width

      if proposedHeight <= maximumSize.height
      {
        newImageSize.height = proposedHeight
        contextSize.height = max(proposedHeight.rounded(.down), request.minimumSize.height)
      }
      else
      {
        newImageSize.width = maximumSize.height / aspectRatio
        contextSize.width = max(newImageSize.width.rounded(.down), request.minimumSize.width)
      }

      handler(QLThumbnailReply(contextSize: contextSize, currentContextDrawing: { () -> Bool in
          // draw the image centered
          if let image = image
          {
            image.draw(in: CGRect(x: contextSize.width/2 - newImageSize.width/2,
                                  y: contextSize.height/2 - newImageSize.height/2,
                                  width: newImageSize.width,
                                  height: newImageSize.height))

            // Return true if the thumbnail was successfully drawn inside this block.
            return true
          }
          return false
        }), nil)
    }
  }
}
