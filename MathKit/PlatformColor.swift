/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

#if os(macOS)
import AppKit

public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
public typealias PlatformFont = NSFont
#else
@_exported import UIKit

public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
public typealias PlatformFont = UIFont
public typealias NSColor = UIColor
public typealias NSImage = UIImage
public typealias NSFont = UIFont

public final class NSColorSpace: NSObject
{
  public static let deviceRGB = NSColorSpace()
  public static let genericRGB = NSColorSpace()
  public static let genericCMYK = NSColorSpace()
}

extension UIColor
{
  public static var textColor: UIColor { return .label }

  public convenience init(calibratedRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
  {
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }

  public var redComponent: CGFloat
  {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return r
  }

  public var greenComponent: CGFloat
  {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return g
  }

  public var blueComponent: CGFloat
  {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return b
  }

  public var alphaComponent: CGFloat
  {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return a
  }

  public func usingColorSpace(_ space: NSColorSpace) -> UIColor?
  {
    return self
  }
}
#endif

