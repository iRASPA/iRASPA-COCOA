/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import iRASPAKit

class iRASPAPredicateEditorRowTemplate: NSPredicateEditorRowTemplate
{
  override init()
  {
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    
    if let view = templateViews.last
    {
      view.setFrameSize(NSMakeSize(200, view.bounds.height))
    }
  }
}

class PredicateEditorViewController: NSViewController
{
  @IBOutlet var predicateEditor: NSPredicateEditor? = nil
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
  }
  
  @objc dynamic var predicate: NSPredicate = NSPredicate(format: "heliumVoidFraction >= 0.0 AND gravimetricSurfaceArea >= 0.0 AND restrictingPoreDiameter >= 0.0")
  {
    didSet
    {
      (self.representedObject as? DirectoryCollectionViewController)?.predicate = predicate
    }
  }
 
}
