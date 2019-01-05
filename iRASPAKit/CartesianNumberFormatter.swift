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

import Foundation

public class CartesianNumberFormatter: NumberFormatter
{
  let shortFormatter: NumberFormatter
  let longFormatter: NumberFormatter
  
  override public init()
  {
    shortFormatter = NumberFormatter()
    shortFormatter.numberStyle = NumberFormatter.Style.decimal
    shortFormatter.paddingPosition = .beforePrefix
    shortFormatter.minimumIntegerDigits = 1
    shortFormatter.maximumIntegerDigits = 4
    shortFormatter.minimumFractionDigits = 3
    shortFormatter.maximumFractionDigits = 3
    
    
    longFormatter = NumberFormatter()
    longFormatter.numberStyle = NumberFormatter.Style.decimal
    longFormatter.usesSignificantDigits = true
    longFormatter.maximumSignificantDigits = 16
    
    super.init()
    
    self.numberStyle = NumberFormatter.Style.decimal
    self.usesSignificantDigits = true
    self.maximumSignificantDigits = 16
  }
  
  public required init?(coder aDecoder: NSCoder)
  {
    shortFormatter = NumberFormatter()
    shortFormatter.numberStyle = NumberFormatter.Style.decimal
    shortFormatter.paddingPosition = .beforePrefix
    shortFormatter.minimumIntegerDigits = 1
    shortFormatter.maximumIntegerDigits = 4
    shortFormatter.minimumFractionDigits = 3
    shortFormatter.maximumFractionDigits = 3
    
    longFormatter = NumberFormatter()
    longFormatter.numberStyle = NumberFormatter.Style.decimal
    longFormatter.usesSignificantDigits = true
    longFormatter.maximumSignificantDigits = 16
    
    
    super.init(coder: aDecoder)
    
    self.numberStyle = NumberFormatter.Style.decimal
    self.usesSignificantDigits = true
    self.maximumSignificantDigits = 16
  }
  
  public override func string(for obj: Any?) -> String?
  {
    if let obj: NSNumber = obj as? NSNumber
    {
      return shortFormatter.string(from: obj)
    }
    return super.string(for: obj)
  }
  
  public override func editingString(for obj: Any) -> String?
  {
    if let obj: NSNumber = obj as? NSNumber
    {
      return longFormatter.string(from: obj)
    }
    return nil
  }
}
