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

public class PythonScriptTextView: LineNumberView
{
  public var previousTextCount: Int = 0
  
  public required init?(coder: NSCoder)
  {
    super.init(coder: coder)
   
    self.isRichText = true
    self.isAutomaticDataDetectionEnabled = false
    self.isAutomaticLinkDetectionEnabled = false
    
    self.isAutomaticQuoteSubstitutionEnabled = false
    self.isAutomaticDashSubstitutionEnabled = false
    self.isAutomaticSpellingCorrectionEnabled = false
    self.isContinuousSpellCheckingEnabled = false
    self.isAutomaticTextReplacementEnabled = false
    self.enabledTextCheckingTypes = 0
    
    self.isEditable = true
    self.isSelectable = true
    
    self.font = NSFont.userFixedPitchFont(ofSize: NSFont.systemFontSize)
  }
  
  deinit
  {
    //Swift.print("deinit: PythonScriptTextView")
  }
  
  public var lastCommandLine: String
  {
    let index = self.string.index(string.startIndex, offsetBy: previousTextCount)
    return String(self.string[index...])
  }
  
  public func pythonOut(string: NSString)
  {
    let attributedString: NSTextStorage = NSTextStorage(string: string as String, attributes: [.foregroundColor : NSColor.textColor])
    attributedString.font = self.font
    self.layoutManager?.textStorage?.append(attributedString)
    
    self.scrollRangeToVisible(NSMakeRange((self.string as NSString).length, 0))
      
    self.previousTextCount = (self.string as NSString).length
    
    self.lineNumberRulerView?.needsDisplay = true
  }
  
  var mouseLocation: NSPoint? = nil
  var previousCursorLocation: Int? = nil
  
  public override func mouseDown(with event: NSEvent)
  {
    self.mouseLocation = self.convert(event.locationInWindow, from: nil)
    self.previousCursorLocation = self.selectedRanges[0].rangeValue.location
    
    super.mouseDown(with: event)
    self.mouseLocation = nil
  }
  
  public override func keyDown(with event: NSEvent)
  {
    if self.selectedRanges[0].rangeValue.location < self.previousTextCount,
      let previousCursorLocation = self.previousCursorLocation
    {
      setSelectedRange(NSMakeRange(max(previousCursorLocation, self.previousTextCount), 0))
    }
    
    super.keyDown(with: event)
  }
  
  public override func updateInsertionPointStateAndRestartTimer(_ restartFlag: Bool)
  {
    if let _ = mouseLocation
    {
      if self.selectedRanges[0].rangeValue.location < self.previousTextCount
      {
        return
      }
    }
    
    super.updateInsertionPointStateAndRestartTimer(restartFlag)
    
    self.lineNumberRulerView?.needsDisplay = true
  }
  
  private let caretSize: CGFloat = 8
  
  public override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool)
  {
    var rect = rect
    rect.size.width = caretSize
    super.drawInsertionPoint(in: rect, color: NSColor.systemGray, turnedOn: flag)
  }
  
  public override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool)
  {
    var rect = rect
    rect.size.width += caretSize - 1
    super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
  }
 
}
