/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Foundation

@objc public protocol LogReporting: class
{
  func update(attributedString: NSTextStorage)
  var logScriptView: LogScriptTextView? {get set}
}


// LogQueue is a singleton
public class LogQueue
{
  public static let shared: LogQueue = LogQueue()
  
  // Create a serial queue
  var queue: DispatchQueue = DispatchQueue(label: "Log dispatch queue")
  
  let stateLock: NSLock = NSLock()
  
  public var destinations: NSMapTable<LogReporting, NSWindowController> = NSMapTable(keyOptions: .weakMemory, valueOptions: .weakMemory, capacity: 5)
  
  // Create the text-storage in the LogQueue. This allows logging of initalization (e.g. iCloud) messages when the viewcontrollers are not yet onscreen.
  public var textStorageView: NSTextStorage = NSTextStorage(string: "Log console ready",  attributes: [.foregroundColor : NSColor.textColor])
  
  
  public enum Level: Int
  {
    case error = 0
    case warning = 1
    case info = 2
    case verbose = 3
  }
  
  public func subscribe(_ subscriber: LogReporting, windowController: NSWindowController)
  {
    stateLock.lock()
      
    if self.destinations.object(forKey: subscriber) == nil
    {
      self.destinations.setObject(windowController, forKey: subscriber)
      subscriber.logScriptView?.layoutManager?.textStorage?.append(textStorageView)
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
    //let font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: NSFont.Weight.regular)
    //NSFont.setUserFixedPitch(font)
    //textStorageView.font = font
  }
  
  
  public func error(destination: NSWindowController?, message: String, completionHandler: @escaping () -> () = {})
  {
    
    self.dispatchMessage(windowController: destination, level: .error, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
    
  }
  
  public func warning(destination: NSWindowController?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .warning, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func info(destination: NSWindowController?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .info, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func verbose(destination: NSWindowController?, message: String, completionHandler: @escaping () -> () = {})
  {
    self.dispatchMessage(windowController: destination, level: .verbose, message: message, thread: Thread.current.name ?? "unknown", completionHandler: completionHandler)
  }
  
  public func dispatchMessage(windowController: NSWindowController?, level: Level, message: String, thread: String, completionHandler: @escaping () -> () = {})
  {
    queue.async(execute: {
      
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .medium
      let timeString: String = formatter.string(from: Date()) as String
      
      let baseFont: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
      
      let levelString: NSString
      let color: NSColor
      let stringRange: NSRange
      let fontMask: NSFontTraitMask
      switch(level)
      {
      case .error:
        levelString = "error (\(timeString)):" as NSString
        color = NSColor.red
        fontMask = NSFontTraitMask.boldFontMask
      case .warning:
        levelString = "warning (\(timeString)):" as NSString
        color = NSColor.blue
        fontMask = NSFontTraitMask.italicFontMask
      case .verbose:
        levelString = "verbose (\(timeString)):" as NSString
        color = NSColor(calibratedRed:0.13333333333333333, green:0.5450980392156862, blue:0.13333333333333333, alpha:1.0)   // Forest green
        fontMask = NSFontTraitMask.fixedPitchFontMask
      case .info:
        levelString = "info (\(timeString)):" as NSString
        color = NSColor.magenta
        fontMask = NSFontTraitMask.fixedPitchFontMask
      }
      let attributedString: NSTextStorage = NSTextStorage(string: "\n" + String(levelString) + " " + message, attributes: [.foregroundColor : NSColor.textColor])
      let colorRange: NSRange = NSMakeRange(1, levelString.length)
      attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: colorRange)
      stringRange = NSMakeRange(1, attributedString.length - 1)
      attributedString.addAttribute(NSAttributedString.Key.font, value: baseFont, range: stringRange)
      attributedString.applyFontTraits(fontMask, range: stringRange)
      
      
      
      DispatchQueue.main.async(execute: {
        
        self.textStorageView.append(attributedString)
        
        let enumerator: NSEnumerator = self.destinations.keyEnumerator()
        for destination in enumerator
        {
          // send message to designated windowController or to all if nil
          if windowController == nil || self.destinations.object(forKey: destination as? LogReporting) == windowController
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


