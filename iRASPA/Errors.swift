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

public struct iRASPAMainError
{
  public static var domain = "iRASPAErrorDomain"
  
  public enum code: Int
  {
    case corruptedGalleryFile
    case corruptedProjectFile
    case corruptedCloudFile
    case galleryFileNotFound
    case projectFileNotFound
    case cloudFileNotFound
    case pasteboardReadingError
  }
  
  init()
  {
    // 2017 Session 236 "Cocoa Development tips", 20:00
    NSError.setUserInfoValueProvider(forDomain: iRASPAMainError.domain, provider: { (error: Error, key) -> Any? in
      if let errorCode = iRASPAMainError.code(rawValue: (error as NSError).code)
      {
        switch(key)
        {
        case NSLocalizedFailureReasonErrorKey:
          switch(errorCode)
          {
          case .corruptedGalleryFile:
            return NSLocalizedString("Gallery-file not found", comment: "Gallery-file not found")
          case .pasteboardReadingError:
            return NSLocalizedString("Cannot init from data", comment: "Failure init from data")
          default:
            return nil
          }
        default:
          return nil
        }
      }
      return nil
    })
  }
}
