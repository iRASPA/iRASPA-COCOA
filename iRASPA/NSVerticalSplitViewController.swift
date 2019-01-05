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

import Cocoa

class NSVerticalSplitViewController: NSSplitViewController
{

  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.view.autoresizingMask = [.width, .height]
    self.view.translatesAutoresizingMaskIntoConstraints = true
    
    /*
    let leftView = self.splitView.arrangedSubviews[0]
    leftView.translatesAutoresizingMaskIntoConstraints = false
    let topConstraintLeftView = leftView.superview!.topAnchor.constraint(equalTo: leftView.topAnchor)
    let bottomConstraintLeftView = leftView.superview!.bottomAnchor.constraint(equalTo: leftView.bottomAnchor)
    let leftConstraintLeftView = leftView.superview!.leftAnchor.constraint(equalTo: leftView.leftAnchor)
    leftConstraintLeftView.priority = .dragThatCannotResizeWindow
    NSLayoutConstraint.activate([topConstraintLeftView,bottomConstraintLeftView,leftConstraintLeftView])
    
    
    let rightView = self.splitView.arrangedSubviews[1]
    rightView.translatesAutoresizingMaskIntoConstraints = false
    let topConstraintRightView = rightView.superview!.topAnchor.constraint(equalTo: rightView.topAnchor)
    let bottomConstraintRightView = rightView.superview!.bottomAnchor.constraint(equalTo: rightView.bottomAnchor)
    let rightConstraintRightView = rightView.superview!.rightAnchor.constraint(equalTo: rightView.rightAnchor)
    rightConstraintRightView.priority = .dragThatCannotResizeWindow
    NSLayoutConstraint.activate([topConstraintRightView,bottomConstraintRightView,rightConstraintRightView])
    
    
    let dividerView = view.subviews[0].subviews[2]
    dividerView.translatesAutoresizingMaskIntoConstraints = false
    let topConstraintDividerView = dividerView.superview!.topAnchor.constraint(equalTo: dividerView.topAnchor)
    let bottomConstraintDividerView = dividerView.superview!.bottomAnchor.constraint(equalTo: dividerView.bottomAnchor)
    let leftConstraintDividerView = dividerView.leftAnchor.constraint(equalTo: leftView.rightAnchor)
    leftConstraintDividerView.priority = .dragThatCannotResizeWindow
    let rightConstraintDividerView = dividerView.rightAnchor.constraint(equalTo: rightView.leftAnchor)
    rightConstraintDividerView.priority = .dragThatCannotResizeWindow
    NSLayoutConstraint.activate([leftConstraintDividerView,rightConstraintDividerView,topConstraintDividerView,bottomConstraintDividerView])
 */
  }
}
