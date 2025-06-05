/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa

class CommandLinePreferences: NSViewController, NSPathControlDelegate
{
  @IBOutlet weak var readPermissionPathControl: NSPathControl?
  @IBOutlet weak var writePermissionPathControl: NSPathControl?
  
  override func viewWillAppear()
  {
    super.viewWillAppear()
    
    if let readPermissionPath: String = UserDefaults.standard.value(forKey: Preferences.readPermissionPathKey) as? String
    {
      readPermissionPathControl?.url = URL(fileURLWithPath: readPermissionPath)
    }
    else
    {
      readPermissionPathControl?.url = nil
    }
   
    if let writePermissionPath: String = UserDefaults.standard.value(forKey: Preferences.writePermissionPathKey) as? String
    {
      writePermissionPathControl?.url = URL(fileURLWithPath: writePermissionPath)
      
    }
    else
    {
      writePermissionPathControl?.url = nil
    }
  }
  
  @IBAction func readPathControlSingleClick(_ sender: NSPathControl)
  {
    if let url: URL = readPermissionPathControl?.clickedPathItem?.url
    {
      readPermissionPathControl?.url = url
    
      do
      {
        let data: Data = try url.bookmarkData(options: URL.BookmarkCreationOptions.minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
      
        if let userDefaults: UserDefaults = UserDefaults(suiteName: "24U2ZRZ6SC.nl.darkwing.iRASPA")
        {
          userDefaults.set(data, forKey: Preferences.transferReadPermissionDataKey)
        }
        UserDefaults.standard.set(url.path, forKey: Preferences.readPermissionPathKey)
      }
      catch let error
      {
        debugPrint("error: \(error.localizedDescription)")
      }
    }
  }
  
  @IBAction func writePathControlSingleClick(_ sender: NSPathControl)
  {
    if let url: URL = writePermissionPathControl?.clickedPathItem?.url
    {
      writePermissionPathControl?.url = url
      
      do
      {
        let data: Data = try url.bookmarkData(options: URL.BookmarkCreationOptions.minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        
        if let userDefaults: UserDefaults = UserDefaults(suiteName: "24U2ZRZ6SC.nl.darkwing.iRASPA")
        {
          userDefaults.set(data, forKey: Preferences.transferWritePermissionDataKey)
        }
        UserDefaults.standard.set(url.path, forKey: Preferences.writePermissionPathKey)
      }
      catch let error
      {
        debugPrint("error: \(error.localizedDescription)")
      }
    }
  }
  
  func pathControl(_ pathControl: NSPathControl, willDisplay openPanel: NSOpenPanel)
  {
    openPanel.title = NSLocalizedString("Select a Top-Level Directory", comment: "")
    openPanel.prompt = "Select"
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false
  }
  
  func pathControl(_ pathControl: NSPathControl, willPopUp menu: NSMenu)
  {
    let title: String = NSLocalizedString("Remove Permission", comment: "")
    
    if pathControl === self.readPermissionPathControl, pathControl.url != nil
    {
      let newItem: NSMenuItem = NSMenuItem(title: title, action: #selector(menuItemRemoveReadPersmissionAction(_:)), keyEquivalent: "")
      newItem.target = self
      menu.insertItem(newItem, at: 1)
    }
    
    if pathControl === self.writePermissionPathControl, pathControl.url != nil
    {
      let newItem: NSMenuItem = NSMenuItem(title: title, action: #selector(menuItemRemoveWritePersmissionAction(_:)), keyEquivalent: "")
      newItem.target = self
      menu.insertItem(newItem, at: 1)
    }
  }
  
  @IBAction func menuItemRemoveReadPersmissionAction(_ sender: NSMenuItem)
  {
    self.readPermissionPathControl?.url = nil
    
    UserDefaults.standard.removeObject(forKey: Preferences.readPermissionPathKey)
    
    if let userDefaults: UserDefaults = UserDefaults(suiteName: "24U2ZRZ6SC.nl.darkwing.iRASPA")
    {
      userDefaults.set(Data(), forKey: Preferences.transferReadPermissionDataKey)
    }
  }
  
  @IBAction func menuItemRemoveWritePersmissionAction(_ sender: NSMenuItem)
  {
    self.writePermissionPathControl?.url = nil
    
    UserDefaults.standard.removeObject(forKey: Preferences.writePermissionPathKey)
    
    if let userDefaults: UserDefaults = UserDefaults(suiteName: "24U2ZRZ6SC.nl.darkwing.iRASPA")
    {
      userDefaults.set(Data(), forKey: Preferences.transferWritePermissionDataKey)
    }
  }
  
  func pathControl(_ pathControl: NSPathControl, validateDrop info: NSDraggingInfo) -> NSDragOperation
  {
    return NSDragOperation.copy
  }
  
  func pathControl(_ pathControl: NSPathControl, acceptDrop info: NSDraggingInfo) -> Bool
  {
    if let url: NSURL = NSURL(from: info.draggingPasteboard)
    {
      pathControl.url = url as URL
      return true
    }
    return false
  }
  
  func pathControl(_ pathControl: NSPathControl, shouldDrag pathComponentCell: NSPathComponentCell, with pasteboard: NSPasteboard) -> Bool
  {
    if let url: URL = pathComponentCell.url, url.isFileURL, url.pathComponents.count < 4
    {
      return false
    }
    return true
  }
  
}
