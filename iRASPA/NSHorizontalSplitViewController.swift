/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

class NSHorizontalSplitViewController: NSSplitViewController
{
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.view.autoresizingMask = [.height, .width]
    self.view.translatesAutoresizingMaskIntoConstraints = true
    
    /*
    let topView = self.splitView.arrangedSubviews[0]
    topView.translatesAutoresizingMaskIntoConstraints = false
    let leftConstraintsTopView = topView.superview!.leftAnchor.constraint(equalTo: topView.leftAnchor)
    let rightConstraintsTopView = topView.superview!.rightAnchor.constraint(equalTo: topView.rightAnchor)
    let topConstraintsTopView = topView.superview!.topAnchor.constraint(equalTo: topView.topAnchor)
    topConstraintsTopView.priority = .dragThatCannotResizeWindow
    NSLayoutConstraint.activate([leftConstraintsTopView,rightConstraintsTopView,topConstraintsTopView])
    
    
    let bottomView = self.splitView.arrangedSubviews[1]
    bottomView.translatesAutoresizingMaskIntoConstraints = false
    let leftConstraintsBottomView = bottomView.superview!.leftAnchor.constraint(equalTo: bottomView.leftAnchor)
    let rightConstraintsBottomView = bottomView.superview!.rightAnchor.constraint(equalTo: bottomView.rightAnchor)
    let bottomConstraintsBottomView = bottomView.superview!.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor)
    bottomConstraintsBottomView.priority = .dragThatCannotResizeWindow
    NSLayoutConstraint.activate([leftConstraintsBottomView,rightConstraintsBottomView,bottomConstraintsBottomView])
    
    let dividerView = view.subviews[0].subviews[2]
    dividerView.translatesAutoresizingMaskIntoConstraints = false
    let leftConstraintsDividerView = dividerView.superview!.leftAnchor.constraint(equalTo: dividerView.leftAnchor)
    let rightConstraintsDividerView = dividerView.superview!.rightAnchor.constraint(equalTo: dividerView.rightAnchor)
    let topConstraintsDividerView = dividerView.topAnchor.constraint(equalTo: topView.bottomAnchor)
    topConstraintsDividerView.priority = .dragThatCannotResizeWindow
    let bottomConstraintsDividerView = dividerView.bottomAnchor.constraint(equalTo: bottomView.topAnchor)
    bottomConstraintsDividerView.priority = .dragThatCannotResizeWindow
    NSLayoutConstraint.activate([leftConstraintsDividerView,rightConstraintsDividerView,topConstraintsDividerView,bottomConstraintsDividerView])
 */
  }
}
