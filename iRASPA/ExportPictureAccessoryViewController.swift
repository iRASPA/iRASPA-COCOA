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

class CitationAccessoryTextView: NSTextView
{
  override var intrinsicContentSize: NSSize
  {
    return NSMakeSize(NSView.noIntrinsicMetric, 70.0)
  }
}

class ExportPictureAccessoryViewController: NSViewController
{
  @IBOutlet var textView: CitationAccessoryTextView?
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    let publicationString: NSMutableAttributedString = NSMutableAttributedString(string: "For use in scientific publications, please cite:\n", attributes: [.foregroundColor : NSColor.textColor])
    let fontMask: NSFontTraitMask = NSFontTraitMask.boldFontMask
    let stringRange: NSRange = NSMakeRange(0, publicationString.length - 1)
    publicationString.applyFontTraits(fontMask, range: stringRange)
    publicationString.append(NSAttributedString(string: "D. Dubbeldam, S. Calero, and T.J.H. Vlugt,\n \"iRASPA: GPU-Accelerated Visualization Software for Materials Scientists\",\nMol. Simulat., 44(8), 653-676, 2018. ", attributes: [.foregroundColor : NSColor.textColor]))
    
    let foundRange: NSRange = publicationString.mutableString.range(of: "iRASPA: GPU-Accelerated Visualization Software for Materials Scientists")
    
    if foundRange.location != NSNotFound
    {
      publicationString.addAttribute(NSAttributedString.Key.link, value: "http://dx.doi.org/10.1080/08927022.2018.1426855", range: foundRange)
    }
    
    self.textView?.textStorage?.setAttributedString(publicationString)
  }
}
