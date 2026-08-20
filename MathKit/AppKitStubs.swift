/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

#if os(iOS)
import UIKit
import Foundation

public typealias NSPoint = CGPoint
public typealias NSSize = CGSize
public typealias NSRect = CGRect

public func NSMakeRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect
{
  return CGRect(x: x, y: y, width: w, height: h)
}

public func NSMakePoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint
{
  return CGPoint(x: x, y: y)
}

public func NSMakeSize(_ w: CGFloat, _ h: CGFloat) -> CGSize
{
  return CGSize(width: w, height: h)
}

public let NSZeroPoint = CGPoint.zero
public let NSZeroSize = CGSize.zero
public let NSZeroRect = CGRect.zero

public func NSMinX(_ r: CGRect) -> CGFloat { return r.minX }
public func NSMinY(_ r: CGRect) -> CGFloat { return r.minY }
public func NSMaxX(_ r: CGRect) -> CGFloat { return r.maxX }
public func NSMaxY(_ r: CGRect) -> CGFloat { return r.maxY }
public func NSMidX(_ r: CGRect) -> CGFloat { return r.midX }
public func NSMidY(_ r: CGRect) -> CGFloat { return r.midY }
public func NSWidth(_ r: CGRect) -> CGFloat { return r.width }
public func NSHeight(_ r: CGRect) -> CGFloat { return r.height }
public func NSInsetRect(_ r: CGRect, _ dx: CGFloat, _ dy: CGFloat) -> CGRect { return r.insetBy(dx: dx, dy: dy) }

open class NSWindowController: NSObject {}

extension UIWindow
{
  public var windowController: NSWindowController? { return nil }
}

open class NSTableView: NSObject
{
  public struct AnimationOptions: OptionSet
  {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let slideLeft = AnimationOptions(rawValue: 1)
    public static let slideRight = AnimationOptions(rawValue: 2)
    public static let slideUp = AnimationOptions(rawValue: 4)
    public static let slideDown = AnimationOptions(rawValue: 8)
    public static let effectGap = AnimationOptions(rawValue: 16)
    public static let effectFade = AnimationOptions(rawValue: 32)
  }
}

open class NSOutlineView: NSTableView
{
  public func reloadItem(_ item: Any?) {}
  public func reloadItem(_ item: Any?, reloadChildren: Bool) {}
  public func reloadData() {}
  public func row(forItem item: Any?) -> Int { return -1 }
  public func view(atColumn column: Int, row: Int, makeIfNecessary: Bool) -> UIView? { return nil }
  public func reloadData(forRowIndexes: IndexSet, columnIndexes: IndexSet) {}
  public func noteHeightOfRows(withIndexesChanged: IndexSet) {}
  public func expandItem(_ item: Any?) {}
  public func collapseItem(_ item: Any?) {}
  public func beginUpdates() {}
  public func endUpdates() {}
  public func parent(forItem item: Any?) -> Any? { return nil }
  public func childIndex(forItem item: Any?) -> Int { return -1 }
  public func removeItems(at indexes: IndexSet, inParent parent: Any?, withAnimation animationOptions: NSTableView.AnimationOptions) {}
  public func insertItems(at indexes: IndexSet, inParent parent: Any?, withAnimation animationOptions: NSTableView.AnimationOptions) {}
  public var window: UIWindow? { return nil }
}

public struct NSPasteboard
{
  public struct PasteboardType: RawRepresentable, Equatable, Hashable
  {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let fileURL = PasteboardType(rawValue: "public.file-url")
  }

  public struct Name: Equatable
  {
    public let rawValue: String
    public init(_ rawValue: String = "") { self.rawValue = rawValue }
    public static let drag = Name("drag")
    public static let general = Name("general")
  }

  public struct WritingOptions: OptionSet
  {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let promised = WritingOptions(rawValue: 1)
  }

  public struct ReadingOptions: OptionSet
  {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public init() { self.rawValue = 0 }
    public static let asData = ReadingOptions(rawValue: 1)
  }

  public var name: Name = .general
  public init(name: Name) { self.name = name }
  public func string(forType type: PasteboardType) -> String? { return nil }
}

public protocol NSPasteboardWriting
{
  func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
}

public extension NSPasteboardWriting
{
  func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  {
    return []
  }
}

public protocol NSPasteboardReading
{
  static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
}

public extension NSPasteboardReading
{
  static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  {
    return []
  }
}

extension URL: NSPasteboardWriting
{
  public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] { return [] }
  public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions { return [] }
  public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? { return nil }
}

extension NSURL
{
  public class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  {
    return []
  }
}

public let kPasteboardTypeFilePromiseContent: String = "com.apple.pasteboard.promised-file-content-type"
public let kPasteboardTypeFileURLPromise: String = "com.apple.pasteboard.promised-file-url"

open class NSProgressIndicator: UIView
{
  public var isIndeterminate: Bool = false
  public var doubleValue: Double = 0
  public var minValue: Double = 0
  public var maxValue: Double = 1
  public var controlSize: Int = 0
  public var style: Int = 0
  public func startAnimation(_ sender: Any?) {}
  public func stopAnimation(_ sender: Any?) {}
}

extension UIView
{
  public enum BackgroundStyle
  {
    case normal
    case emphasized
  }
}

open class NSButton: UIButton {}
open class NSClipView: UIView {}
open class NSColorWell: UIView {}

public class NSGraphicsContext: NSObject
{
  public let cgContext: CGContext
  public init(cgContext: CGContext, flipped: Bool)
  {
    self.cgContext = cgContext
  }
  public static var current: NSGraphicsContext?
  public static func saveGraphicsState() {}
  public static func restoreGraphicsState() { current = nil }
}

public class NSGradient: NSObject
{
  public struct DrawingOptions: OptionSet
  {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let drawsBeforeStartingLocation = DrawingOptions(rawValue: CGGradientDrawingOptions.drawsBeforeStartLocation.rawValue)
    public static let drawsAfterEndingLocation = DrawingOptions(rawValue: CGGradientDrawingOptions.drawsAfterEndLocation.rawValue)
  }

  private let startColor: UIColor
  private let endColor: UIColor

  public init?(starting: UIColor, ending: UIColor)
  {
    self.startColor = starting
    self.endColor = ending
  }

  public func draw(in rect: CGRect, angle: CGFloat)
  {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let colors = [startColor.cgColor, endColor.cgColor] as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
    let radians = angle * .pi / 180
    let dx = cos(radians) * rect.width
    let dy = sin(radians) * rect.height
    ctx.saveGState()
    ctx.addRect(rect)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: rect.midX - dx / 2, y: rect.midY - dy / 2), end: CGPoint(x: rect.midX + dx / 2, y: rect.midY + dy / 2), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
  }

  public func draw(fromCenter startCenter: CGPoint, radius startRadius: CGFloat, toCenter endCenter: CGPoint, radius endRadius: CGFloat, options: DrawingOptions)
  {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let colors = [startColor.cgColor, endColor.cgColor] as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
    ctx.drawRadialGradient(gradient, startCenter: startCenter, startRadius: startRadius, endCenter: endCenter, endRadius: endRadius, options: CGGradientDrawingOptions(rawValue: options.rawValue))
  }
}

public class NSBitmapImageRep: NSObject
{
  public enum FileType
  {
    case png
    case jpeg
    case jpeg2000
    case tiff
  }

  private let cgImage: CGImage
  public init(cgImage: CGImage)
  {
    self.cgImage = cgImage
  }

  public func representation(using type: FileType, properties: [AnyHashable: Any]) -> Data?
  {
    return UIImage(cgImage: cgImage).pngData()
  }
}

#endif
