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
import iRASPAKit

public class ProjectTableCellView: NSTableCellView, ProgressIndicator
{
  @IBOutlet public weak var progressIndicator: ProjectProgressIndicator? = nil
  @IBOutlet public weak var cancelButton: NSButton? = nil
  
  private var isReadOnly: Bool = false
  private var lockImageView: NSImageView?
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    self.textField?.wantsLayer = true
  }
  
  required public init?(coder: NSCoder)
  {
    super.init(coder: coder)
    self.textField?.wantsLayer = true
  }
  
  override public func awakeFromNib()
  {
    super.awakeFromNib()
    _ = ensureLockImageView()
  }
  
  override public var backgroundStyle: NSView.BackgroundStyle
  {
    didSet
    {
      syncSelectionAppearance(for: backgroundStyle)
    }
  }
  
  func configureReadOnly(_ isReadOnly: Bool, toolTip: String?)
  {
    self.isReadOnly = isReadOnly
    self.toolTip = toolTip
    let lockView = ensureLockImageView()
    lockView.isHidden = !isReadOnly
    lockView.toolTip = toolTip
  }
  
  func syncSelectionAppearance(for style: NSView.BackgroundStyle)
  {
    let nameField = textField as? TableListNameTextField
    let isRenaming = nameField?.allowsRenaming == true
    
    if isRenaming
    {
      nameField?.applyEditingAppearance()
    }
    else
    {
      textField?.cell?.backgroundStyle = style
    }
    
    (imageView as? TableImageViewIcon)?.applyBackgroundStyle(style)
    imageView?.cell?.backgroundStyle = style
    progressIndicator?.backgroundStyle = style
    cancelButton?.cell?.backgroundStyle = style
    
    if !isRenaming
    {
      if style == .emphasized
      {
        textField?.textColor = NSColor.alternateSelectedControlTextColor
        lockImageView?.contentTintColor = NSColor.alternateSelectedControlTextColor
      }
      else if isReadOnly
      {
        if textField?.textColor != NSColor.red
        {
          textField?.textColor = NSColor.secondaryLabelColor
        }
        lockImageView?.contentTintColor = NSColor.tertiaryLabelColor
      }
      else if textField?.textColor == NSColor.alternateSelectedControlTextColor
      {
        textField?.textColor = nil
        lockImageView?.contentTintColor = NSColor.tertiaryLabelColor
      }
      else
      {
        lockImageView?.contentTintColor = NSColor.tertiaryLabelColor
      }
    }
    
    textField?.needsDisplay = true
  }
  
  private func ensureLockImageView() -> NSImageView
  {
    if let lockImageView
    {
      return lockImageView
    }
    
    let lockView = NSImageView()
    lockView.translatesAutoresizingMaskIntoConstraints = false
    let symbol = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: NSLocalizedString("Read-only", comment: ""))
    lockView.image = symbol?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 9, weight: .semibold))
    lockView.imageScaling = .scaleProportionallyDown
    lockView.contentTintColor = NSColor.tertiaryLabelColor
    lockView.setContentHuggingPriority(.required, for: .horizontal)
    lockView.setContentCompressionResistancePriority(.required, for: .horizontal)
    NSLayoutConstraint.activate([
      lockView.widthAnchor.constraint(equalToConstant: 10),
      lockView.heightAnchor.constraint(equalToConstant: 10)
    ])
    lockView.isHidden = true
    
    if let stack = subviews.compactMap({ $0 as? NSStackView }).first
    {
      if let textField, let index = stack.arrangedSubviews.firstIndex(of: textField)
      {
        stack.insertArrangedSubview(lockView, at: index + 1)
      }
      else
      {
        stack.addArrangedSubview(lockView)
      }
    }
    else
    {
      addSubview(lockView)
    }
    
    lockImageView = lockView
    return lockView
  }
}


