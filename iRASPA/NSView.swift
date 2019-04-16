//
//  NSView.swift
//  iRASPA
//
//  Created by David Dubbeldam on 15/04/2019.
//  Copyright © 2019 David Dubbeldam. All rights reserved.
//

import Cocoa

extension NSView
{  
  /** This is the function to get subViews of a view of a particular type
   */
  func allSubViewsOf<T : NSView>(type : T.Type) -> [T]{
    var all = [T]()
    func getSubview(view: NSView) {
      if let aView = view as? T{
        all.append(aView)
      }
      guard view.subviews.count>0 else { return }
      view.subviews.forEach{ getSubview(view: $0) }
    }
    getSubview(view: self)
    return all
  }
}
