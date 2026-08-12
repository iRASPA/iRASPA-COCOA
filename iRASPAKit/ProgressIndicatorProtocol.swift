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

import AppKit
import Foundation

public protocol ProgressIndicator: AnyObject
{
  var progressIndicator: ProjectProgressIndicator? {get}
  var cancelButton: NSButton? {get}
}

public extension ProgressIndicator
{
  func setImportProgressVisible(_ visible: Bool, fraction: Double = 0.0)
  {
    progressIndicator?.isHidden = !visible
    cancelButton?.isHidden = !visible
    if visible
    {
      progressIndicator?.applyImportProgressFraction(fraction)
    }
  }
  
  func updateImportProgressFraction(_ fraction: Double)
  {
    setImportProgressVisible(true, fraction: fraction)
  }
  
  func syncImportProgress(with node: ProjectTreeNode, fraction: Double)
  {
    setImportProgressVisible(node.showsImportProgress, fraction: fraction)
  }
}

public extension ProjectTreeNode
{
  /// Clears the import operation and updates the visible project row (reload alone does not reconfigure cells on recent macOS).
  func finishImportProgressUI(in outlineView: NSOutlineView?)
  {
    importOperation = nil
    refreshImportProgressUI(in: outlineView)
  }
  
  func refreshImportProgressUI(in outlineView: NSOutlineView?)
  {
    guard let outlineView else {return}
    let row: Int = outlineView.row(forItem: self)
    guard row >= 0 else {return}
    
    if let view: ProgressIndicator = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ProgressIndicator
    {
      view.setImportProgressVisible(showsImportProgress)
    }
    
    outlineView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
    outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
  }
}
