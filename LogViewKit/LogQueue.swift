/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
import os.log
#if os(macOS)
import AppKit
private typealias LogColor = NSColor
private typealias LogFont = NSFont
#else
import UIKit
private typealias LogColor = UIColor
private typealias LogFont = UIFont
#endif

@objc public protocol LogReporting: AnyObject
{
  func update(attributedString: NSTextStorage)
  #if os(macOS)
  var logScriptView: LogScriptTextView? {get set}
  #endif
}


// LogQueue is a singleton
public class LogQueue
{
  public static let shared: LogQueue = LogQueue()
  
  var queue: DispatchQueue = DispatchQueue(label: "Log dispatch queue")
  
  let stateLock: NSLock = NSLock()
  
  public var destinations: NSMapTable<LogReporting, AnyObject> = NSMapTable(keyOptions: .weakMemory, valueOptions: .weakMemory, capacity: 5)
  
  public var textStorageView: NSTextStorage = NSTextStorage(string: NSLocalizedString("Log console ready", bundle: Bundle(for: LogQueue.self), comment: ""),  attributes: [.foregroundColor : LogQueue.logTextColor])
  
  
  public enum Level: Int
  {
    case error = 0
    case warning = 1
    case info = 2
    case verbose = 3

    var systemLogType: OSLogType
    {
      switch(self)
      {
      case .error: return OSLogType.error
      case .warning: return OSLogType.default
      case .info: return OSLogType.info
      case .verbose: return OSLogType.debug
      }
    }
  }

  private static let systemLog: OSLog = OSLog(subsystem: "nl.darkwing.iRASPA", category: "log")
  
  private static var logTextColor: LogColor
  {
    #if os(macOS)
    return NSColor.textColor
    #else
    return UIColor.label
    #endif
  }
  
  public func subscribe(_ subscriber: LogReporting, windowController: AnyObject)
  {
    stateLock.lock()
      
    if self.destinations.object(forKey: subscriber) == nil
    {
      self.destinations.setObject(windowController, forKey: subscriber)
      #if os(macOS)
      subscriber.logScriptView?.layoutManager?.textStorage?.append(textStorageView)
      #endif
    }
    
    stateLock.unlock()
  }
  
  public func unsubscribe(subscriber: LogReporting?)
  {
    stateLock.lock()
    
    if let subscriber = subscriber
    {
      self.destinations.removeObject(forKey: subscriber)
    }
    
    stateLock.unlock()
  }
  
  private init()
  {
  }
  
  
  public func error(destination: AnyObject?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .error, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func warning(destination: AnyObject?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .warning, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func info(destination: AnyObject?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .info, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func verbose(destination: AnyObject?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .verbose, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func dispatchMessage(windowController: AnyObject?, level: Level, message: String, thread: String, completionHandler: @escaping () -> () = {})
  {
    let bundle: Bundle = Bundle(for: LogQueue.self)
    
    queue.async(execute: {
      
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .medium
      let timeString: String = formatter.string(from: Date()) as String
      
      let baseFont: LogFont = LogFont.systemFont(ofSize: LogFont.systemFontSize)
      
      let levelString: NSString
      let colorString: String
      let color: LogColor
      let stringRange: NSRange
      switch(level)
      {
      case .error:
        colorString = NSLocalizedString("Error", bundle: bundle, comment: "")
        levelString = NSString.localizedStringWithFormat("\n%@ %@: %@", colorString, timeString, message)
        color = LogColor.red
      case .warning:
        colorString = NSLocalizedString("Warning", bundle: bundle, comment: "")
        levelString = NSString.localizedStringWithFormat("\n%@ %@: %@", colorString, timeString, message)
        color = LogColor.blue
      case .verbose:
        colorString = NSLocalizedString("Verbose", bundle: bundle, comment: "")
        levelString = NSString.localizedStringWithFormat("\n%@ %@: %@", colorString, timeString, message)
        color = LogColor(red:0.13333333333333333, green:0.5450980392156862, blue:0.13333333333333333, alpha:1.0)
      case .info:
        colorString = NSLocalizedString("Info", bundle: bundle, comment: "")
        levelString = NSString.localizedStringWithFormat("\n%@ %@: %@", colorString, timeString, message)
        color = LogColor.magenta
      }
      let attributedString: NSTextStorage = NSTextStorage(string: String(levelString), attributes: [.foregroundColor : LogQueue.logTextColor])
      let colorRange: NSRange = levelString.localizedStandardRange(of: colorString)
      attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: colorRange)
      stringRange = NSMakeRange(1, attributedString.length - 1)
      attributedString.addAttribute(NSAttributedString.Key.font, value: baseFont, range: stringRange)
      #if os(macOS)
      switch(level)
      {
      case .error:
        attributedString.applyFontTraits(NSFontTraitMask.boldFontMask, range: stringRange)
      case .warning:
        attributedString.applyFontTraits(NSFontTraitMask.italicFontMask, range: stringRange)
      case .verbose, .info:
        attributedString.applyFontTraits(NSFontTraitMask.fixedPitchFontMask, range: stringRange)
      }
      #endif
      
      
      
      // Processes without a log window (the XPC services and the command line tool) would
      // otherwise drop every message, so send it to the system log instead. Visible with
      // Console.app or `log stream`.
      if self.destinations.count == 0
      {
        os_log("%{public}@ %{public}@", log: LogQueue.systemLog, type: level.systemLogType, colorString, message)
      }

      DispatchQueue.main.async(execute: {
        
        self.textStorageView.append(attributedString)
        
        let enumerator: NSEnumerator = self.destinations.keyEnumerator()
        for destination in enumerator
        {
          if windowController == nil || self.destinations.object(forKey: destination as? LogReporting) === windowController
          {
            (destination as? LogReporting)?.update(attributedString: attributedString)
          }
        }
        DispatchQueue.main.async(execute: {
          completionHandler()
        })
      })
    })
  }
}
