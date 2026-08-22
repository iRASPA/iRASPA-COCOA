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

import Cocoa

/// Name field for source-list rows: single click selects the row;
/// double-click calls `beginRenaming()` to enable editing.
class TableListNameTextField: NSTextField
{
  private(set) var allowsRenaming: Bool = false
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    isSelectable = false
    isEditable = false
  }
  
  override var acceptsFirstResponder: Bool
  {
    return allowsRenaming && super.acceptsFirstResponder
  }
  
  override func mouseDown(with event: NSEvent)
  {
    if allowsRenaming
    {
      super.mouseDown(with: event)
      return
    }
    
    if let listView = enclosingListView()
    {
      listView.mouseDown(with: event)
    }
    else
    {
      super.mouseDown(with: event)
    }
  }
  
  /// The storyboard marks this field selectable so the system "Look Up" menu
  /// appears on right-click. Rows already have the outline's project menu;
  /// use that unless the name is being edited.
  override func menu(for event: NSEvent) -> NSMenu?
  {
    if allowsRenaming
    {
      return super.menu(for: event)
    }
    return enclosingListView()?.menu(for: event)
  }
  
  func beginRenaming()
  {
    allowsRenaming = true
    isEditable = true
    isSelectable = true
    applyEditingAppearance()
  }
  
  func endRenaming()
  {
    allowsRenaming = false
    isEditable = false
    isSelectable = false
    drawsBackground = false
    backgroundColor = nil
    textColor = nil
    if let cell = cell as? NSTextFieldCell
    {
      cell.backgroundStyle = .normal
      cell.textColor = nil
      cell.backgroundColor = nil
    }
  }
  
  override func becomeFirstResponder() -> Bool
  {
    let becameFirstResponder = super.becomeFirstResponder()
    if becameFirstResponder && allowsRenaming
    {
      applyEditingAppearance()
      configureFieldEditor()
    }
    return becameFirstResponder
  }
  
  /// Call while the row may still be selection-emphasized so edit text stays readable.
  func applyEditingAppearance()
  {
    drawsBackground = true
    backgroundColor = .textBackgroundColor
    textColor = .labelColor
    if let cell = cell as? NSTextFieldCell
    {
      // Emphasized (selected) rows force white text; editing needs a normal style.
      cell.backgroundStyle = .normal
      cell.textColor = .labelColor
      cell.backgroundColor = .textBackgroundColor
    }
    configureFieldEditor()
  }
  
  private func configureFieldEditor()
  {
    guard let textView = currentEditor() as? NSTextView else { return }
    textView.drawsBackground = true
    textView.backgroundColor = .textBackgroundColor
    textView.textColor = .labelColor
    textView.insertionPointColor = .labelColor
    var typing: [NSAttributedString.Key: Any] = textView.typingAttributes
    typing[.foregroundColor] = NSColor.labelColor
    if let font = font
    {
      typing[.font] = font
    }
    textView.typingAttributes = typing
    textView.selectedTextAttributes = [
      .foregroundColor: NSColor.selectedTextColor,
      .backgroundColor: NSColor.selectedTextBackgroundColor
    ]
    // Re-color any already-inserted characters (may still be white from selection style).
    if let storage = textView.textStorage, storage.length > 0
    {
      storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: storage.length))
    }
  }
  
  private func enclosingListView() -> NSView?
  {
    var view: NSView? = superview
    while let current = view
    {
      if current is NSOutlineView || current is NSTableView { return current }
      view = current.superview
    }
    return nil
  }
}

