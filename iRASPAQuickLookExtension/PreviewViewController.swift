//
//  PreviewViewController.swift
//  iRASPAQuickLookExtension
//
//  Created by David Dubbeldam on 20/11/2020.
//  Copyright © 2020 David Dubbeldam. All rights reserved.
//

import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController
{
  
  @IBOutlet var appIcon: NSButton?
  @IBOutlet var fileName: NSTextField?
  @IBOutlet var fileSize: NSTextField?
    
  override var nibName: NSNib.Name?
  {
    return NSNib.Name("PreviewViewController")
  }

  override func loadView()
  {
    super.loadView()
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
    preferredContentSize = NSSize(width: 480, height: 168)
    appIcon?.image = NSImage(named: "MOF")
    fileName?.stringValue = url.lastPathComponent
    
    do {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        if let size = resourceValues.fileSize
        {
          fileSize?.stringValue = ByteCountFormatter().string(fromByteCount: Int64(size))
        }
    } catch { print(error) }
        
    handler(nil)
  }
}
