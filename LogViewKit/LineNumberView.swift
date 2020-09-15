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

open class LineNumberView : NSTextView
{
  public var lineNumberRulerView: LineNumberRulerView?
  
  public required init?(coder: NSCoder)
  {
    super.init(coder: coder)
  }
  
  open override func rulerView(_ ruler: NSRulerView, willSetClientView newClient: NSView)
  {
    
  }
  
  public func setUpLineNumberView()
  {
    lineNumberRulerView = LineNumberRulerView(textView: self)
    
    if font == nil
    {
      font = NSFont.systemFont(ofSize: 16)
    }
    
    if let scrollView = enclosingScrollView
    {
      scrollView.verticalRulerView = lineNumberRulerView
      scrollView.hasVerticalRuler = true
      scrollView.rulersVisible = true
    }
    
    
    
    postsFrameChangedNotifications = true
    NotificationCenter.default.addObserver(self, selector: #selector(frameDidChange), name: NSView.frameDidChangeNotification, object: self)
    
    NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: NSText.didChangeNotification, object: self)
  }
  
  @objc func frameDidChange(notification: NSNotification)
  {
    lineNumberRulerView?.needsDisplay = true
  }
  
  @objc func textDidChange(notification: NSNotification)
  {
    lineNumberRulerView?.needsDisplay = true
  }
}



