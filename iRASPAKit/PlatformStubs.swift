/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

#if os(iOS)
import Foundation
import MathKit

public protocol ProgressIndicator: AnyObject
{
  func syncImportProgress(with node: ProjectTreeNode, fraction: Double)
}

public extension ProgressIndicator
{
  func syncImportProgress(with node: ProjectTreeNode, fraction: Double) {}
}

public extension ProjectTreeNode
{
  func finishImportProgressUI(in outlineView: NSOutlineView?)
  {
    importOperation = nil
  }

  func refreshImportProgressUI(in outlineView: NSOutlineView?)
  {
  }
}

#endif
