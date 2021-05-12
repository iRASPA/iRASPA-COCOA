//
//  PreviewViewController.swift
//  iRASPAQuickLookExtension
//
//  Created by David Dubbeldam on 20/11/2020.
//  Copyright © 2020 David Dubbeldam. All rights reserved.
//

import Cocoa
import Quartz
import BinaryCodable
import ZIPFoundation
import iRASPAKit
import RenderKit

class PreviewViewController: NSViewController, QLPreviewingController
{
  @IBOutlet var appIcon: NSButton?
  @IBOutlet var fileName: NSTextField?
  @IBOutlet var fileSize: NSTextField?
  @IBOutlet var stackView: NSStackView?
    
  override var nibName: NSNib.Name?
  {
    return NSNib.Name("PreviewViewController")
  }

  override func loadView()
  {
    super.loadView()
    preferredContentSize = NSSize(width: 512, height: 512)
  }
   
  func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void)
  {
    // Perform any setup necessary in order to prepare the view.
        
    // Call the completion handler so Quick Look knows that the preview is fully loaded.
    // Quick Look will display a loading spinner while the completion handler is not called.
    handler(nil)
  }
    
  func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void)
  {
    // set fall-back image
    var image: NSImage? = NSImage(named: "MOF")
    let size: CGSize = CGSize(width: 512, height: 512)
    
    guard let projectTreeNode = ProjectTreeNode(url: url) else {return}
    projectTreeNode.unwrapLazyLocalPresentedObjectIfNeeded()
          
    if let project: ProjectStructureNode  = projectTreeNode.representedObject.loadedProjectStructureNode,
       let device = MTLCreateSystemDefaultDevice()
    {
      let camera: RKCamera = RKCamera()
      
      project.setPreviewDefaults(camera: camera, size: size)
      
      let renderer: MetalRenderer = MetalRenderer(device: device, size: size, dataSource: project, camera: camera)
      
      if let data: Data = renderer.renderPicture(device: device, size: size, imagePhysicalSizeInInches: project.renderImagePhysicalSizeInInches, camera: camera, imageQuality: .rgb_8_bits, transparentBackground: false)
      {
        image = NSImage(data: data)
      }
    }
    
    appIcon?.image = image
    fileName?.stringValue = url.lastPathComponent
    
    do
    {
      let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
      if let size = resourceValues.fileSize
      {
        fileSize?.stringValue = ByteCountFormatter().string(fromByteCount: Int64(size))
      }
    }
    catch
    {
      print(error)
    }
        
    handler(nil)
  }
}
