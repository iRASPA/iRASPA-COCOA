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

class Preferences
{
  public static let shared: Preferences = Preferences()
  
  static let selectionAnimationKey: String = "nl.darkwing.iRASPA.selectionAnimation"
  static let renderTooltipKey: String = "nl.darkwing.iRASPA.rendertooltip"
  static let autosavingKey: String = "nl.darkwing.iRASPA.autosaving"
  static let readPermissionPathKey: String = "nl.darkwing.iRASPA.readPermissionPath"
  static let writePermissionPathKey: String = "nl.darkwing.iRASPA.writePermissionPath"
  static let transferReadPermissionDataKey: String = "group.nl.darkwing.iRASPA.transferReadPermissionData"
  static let transferWritePermissionDataKey: String = "group.nl.darkwing.iRASPA.transferWritePermissionData"
  
  static let AnimationSettingsDidChange: String = "AnimationSettingsDidChange"
  static let TooltipSettingsDidChange: String = "TooltipSettingsDidChange"
  
  enum SelectionAnimation: Int
  {
    case undefined = -1
    case always = 0
    case whenConnectedToPower = 1
    case never = 2
  }
  
  init()
  {
    UserDefaults.standard.register(defaults: [
        Preferences.renderTooltipKey : true,
        Preferences.selectionAnimationKey : Preferences.SelectionAnimation.never.rawValue,
        Preferences.autosavingKey : true
      ])
  }
  
  var showRenderTooptip: Bool
  {
    get
    {
      if let renderTooltipBool: Bool = UserDefaults.standard.value(forKey: Preferences.renderTooltipKey) as? Bool
      {
        return renderTooltipBool
      }
      return false
    }
    set(newValue)
    {
      UserDefaults.standard.set(newValue, forKey: Preferences.renderTooltipKey)
      NotificationCenter.default.post(name: Notification.Name(Preferences.TooltipSettingsDidChange), object: self)
    }
  }
  
  var selectionAnimation: SelectionAnimation
  {
    get
    {
      if let selectionAnimationRawValue: Int = UserDefaults.standard.value(forKey: Preferences.selectionAnimationKey) as? Int,
        let selectionAnimation: SelectionAnimation = SelectionAnimation(rawValue: selectionAnimationRawValue)
      {
        return selectionAnimation
      }
      return SelectionAnimation.undefined
    }
    set(newValue)
    {
      UserDefaults.standard.set(newValue.rawValue, forKey: Preferences.selectionAnimationKey)
      NotificationCenter.default.post(name: Notification.Name(Preferences.AnimationSettingsDidChange), object: self)
    }
  }
  
  public var autosaving: Bool
  {
    get
    {
      if let autosavingBool: Bool = UserDefaults.standard.value(forKey: Preferences.autosavingKey) as? Bool
      {
        return autosavingBool
      }
      return true
    }
    set(newValue)
    {
      UserDefaults.standard.set(newValue, forKey: Preferences.autosavingKey)
    }
  }
}
