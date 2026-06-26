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
import ObjectiveC


// View-based table-views: row drawing customization should be done by subclassing NSTableRowView.
open class SourceListStyledTableRowView: NSTableRowView
{
  static let selectionCornerRadius: CGFloat = 6.0
  
  public var secondaryHighlighted: Bool = false
  {
    didSet
    {
      guard oldValue != secondaryHighlighted else { return }
      needsDisplay = true
    }
  }
  
  override open var isOpaque: Bool { return false }
  
  override public init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    configureRowView()
  }
  
  required public init?(coder: NSCoder)
  {
    super.init(coder: coder)
    configureRowView()
  }
  
  private func configureRowView()
  {
    wantsLayer = false
    selectionHighlightStyle = .none
    autoresizesSubviews = true
  }
  
  override open var wantsUpdateLayer: Bool
  {
    return false
  }
  
  override open var isSelected: Bool
  {
    didSet
    {
      guard oldValue != isSelected else { return }
      resetSyncedCellEmphasis()
      updateCellBackgroundStyles()
      needsDisplay = true
    }
  }
  
  override open var isEmphasized: Bool
  {
    didSet
    {
      guard oldValue != isEmphasized else { return }
      resetSyncedCellEmphasis()
      updateCellBackgroundStyles()
      needsDisplay = true
    }
  }
  
  override open func didAddSubview(_ subview: NSView)
  {
    super.didAddSubview(subview)
    resetSyncedCellEmphasis()
    updateCellBackgroundStyles()
  }
  
  private var lastSyncedCellEmphasis: Bool?
  
  private func updateCellBackgroundStyles()
  {
    let emphasized = isSelected && emphasizesSelection
    if lastSyncedCellEmphasis == emphasized
    {
      return
    }
    lastSyncedCellEmphasis = emphasized
    
    let style: NSView.BackgroundStyle = emphasized ? .emphasized : .normal
    
    for case let cellView as NSTableCellView in subviews
    {
      if cellView.backgroundStyle != style
      {
        cellView.backgroundStyle = style
      }
      else
      {
        (cellView as? ProjectTableCellView)?.syncSelectionAppearance(for: style)
        (cellView as? MovieTableCellView)?.syncSelectionAppearance(for: style)
        (cellView as? FrameTableCellView)?.syncSelectionAppearance(for: style)
        (cellView.imageView as? TableImageViewIcon)?.applyBackgroundStyle(style)
      }
    }
  }
  
  private func resetSyncedCellEmphasis()
  {
    lastSyncedCellEmphasis = nil
  }
  
  open func listRowContentWidth() -> CGFloat
  {
    guard let tableView = enclosingListView else { return bounds.width }
    return max(bounds.width, tableView.bounds.width - frame.origin.x)
  }
  
  open func selectionRect() -> NSRect
  {
    NSRect(x: 0.0, y: 0.0, width: listRowContentWidth(), height: max(12.0, bounds.height))
  }
  
  open func drawAdditionalBackground(in rect: NSRect)
  {
  }
  
  /// AppKit uses the accent blue when the window is key and the list is first responder; grey otherwise.
  open var emphasizesSelection: Bool
  {
    guard let listView = enclosingListView,
          let window = listView.window,
          window.isKeyWindow else
    {
      return false
    }
    if window.firstResponder === listView
    {
      return true
    }
    return isEmphasized
  }
  
  private var enclosingListView: NSTableView?
  {
    var view: NSView? = superview
    while let current = view
    {
      if let tableView = current as? NSTableView
      {
        return tableView
      }
      view = current.superview
    }
    return nil
  }
  
  /// NSOutlineView paints the source-list background itself; NSTableView does not once
  /// selectionHighlightStyle is .none and row views are non-opaque.
  private var enclosingPlainTableView: NSTableView?
  {
    guard let listView = enclosingListView, !(listView is NSOutlineView) else { return nil }
    return listView
  }
  
  open func fillListBackground(in rect: NSRect)
  {
    sourceListBackgroundColor().setFill()
    rect.fill()
  }
  
  private func sourceListBackgroundColor() -> NSColor
  {
    if let tableView = enclosingListView as? FrameListTableView
    {
      return tableView.backgroundColor
    }
    return enclosingListView?.backgroundColor ?? FrameListTableView.sourceListBackgroundColor()
  }
  
  open func refreshCellBackgroundStyles()
  {
    resetSyncedCellEmphasis()
    updateCellBackgroundStyles()
  }
  
  private func sourceListSelectionFillColor() -> NSColor
  {
    emphasizesSelection
      ? NSColor.selectedContentBackgroundColor
      : NSColor.unemphasizedSelectedContentBackgroundColor
  }
  
  private func drawSelectionStroke(in rect: NSRect)
  {
    let cornerRadius = Self.selectionCornerRadius
    guard rect.height >= 2.0 * cornerRadius else { return }
    
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let strokeColor = emphasizesSelection ? NSColor.white : NSColor.systemGray
    strokeColor.setStroke()
    path.lineWidth = 2.0
    path.stroke()
  }
  
  private func drawRoundedFill(in rect: NSRect, fill: NSColor)
  {
    let cornerRadius = Self.selectionCornerRadius
    guard rect.height >= 2.0 * cornerRadius else { return }
    
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    fill.setFill()
    path.fill()
  }
  
  override open func drawBackground(in dirtyRect: NSRect)
  {
    super.drawBackground(in: dirtyRect)
    
    if enclosingPlainTableView != nil
    {
      fillListBackground(in: bounds)
    }
    
    let rect = selectionRect()
    drawAdditionalBackground(in: rect)
    
    if isSelected
    {
      resetSyncedCellEmphasis()
      updateCellBackgroundStyles()
      drawRoundedFill(in: rect, fill: sourceListSelectionFillColor())
    }
    
    if secondaryHighlighted
    {
      drawSelectionStroke(in: rect)
    }
  }
  
  func drawImplicitSelectionBackground(in rect: NSRect, emphasized: Bool)
  {
    let fillColor = emphasized
      ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.20)
      : NSColor.systemGray.withAlphaComponent(0.2)
    drawRoundedFill(in: rect, fill: fillColor)
  }
}

private var sourceListWindowKeyObserversKey: UInt8 = 0

extension NSTableView
{
  func sourceList_refreshSelectionEmphasis()
  {
    enumerateAvailableRowViews { rowView, _ in
      (rowView as? SourceListStyledTableRowView)?.refreshCellBackgroundStyles()
      rowView.needsDisplay = true
    }
  }
  
  func sourceList_installWindowKeyObservation()
  {
    sourceList_removeWindowKeyObservation()
    guard let window = window else { return }
    
    let center = NotificationCenter.default
    let tokens = [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification].map { name in
      center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
        // Defer so window key state and first responder are settled before syncing.
        DispatchQueue.main.async {
          self?.sourceList_refreshSelectionEmphasis()
        }
      }
    }
    objc_setAssociatedObject(self, &sourceListWindowKeyObserversKey, tokens, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
  
  func sourceList_removeWindowKeyObservation()
  {
    if let tokens = objc_getAssociatedObject(self, &sourceListWindowKeyObserversKey) as? [NSObjectProtocol]
    {
      tokens.forEach { NotificationCenter.default.removeObserver($0) }
      objc_setAssociatedObject(self, &sourceListWindowKeyObserversKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}
