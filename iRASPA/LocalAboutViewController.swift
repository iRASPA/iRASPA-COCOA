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

class LocalAboutViewController: NSViewController
{
  var appURL: URL? = nil
  @IBOutlet var appNameTextField: NSTextField?
  @IBOutlet var textView: NSTextView?
  @IBOutlet var versionTextField: NSTextField?
  @IBOutlet var acknowledgementButton: NSButton?
  
  var version: String
  {
    if let dictionary = Bundle.main.infoDictionary
    {
      let version = dictionary["CFBundleShortVersionString"] as? String ?? ""
      let build = dictionary["CFBundleVersion"] as? String ?? ""
      return "Version \(version) (build \(build))"
    }
    return ""
  }
  
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    self.appNameTextField?.attributedStringValue = NSAttributedString(string: "iRASPA", attributes: [.foregroundColor : NSColor.textColor])
    self.versionTextField?.attributedStringValue = NSAttributedString(string:  version, attributes: [.foregroundColor : NSColor.textColor])
    self.appURL = URL(string:"https://www.uva.nl/en/profile/d/u/d.dubbeldam/d.dubbeldam.html")
    
    if let creditsURL: URL = Bundle.main.url(forResource: "Credits", withExtension: "rtf"),
      let mutableAttributedString: NSMutableAttributedString = try? NSMutableAttributedString(url: creditsURL, options: [:], documentAttributes: nil)
    {
      mutableAttributedString.addAttributes([.foregroundColor : NSColor.textColor], range: NSMakeRange(0, mutableAttributedString.length))
      let foundRangeArticleLink: NSRange = mutableAttributedString.mutableString.range(of: "Link to the article in 'Molecular Simulation Journal' (open access)")
      
      if foundRangeArticleLink.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "http://dx.doi.org/10.1080/08927022.2018.1426855", range: foundRangeArticleLink)
      }
      
      let foundRangeDubbeldam: NSRange = mutableAttributedString.mutableString.range(of: "David Dubbeldam")
      if foundRangeDubbeldam.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "https://www.uva.nl/en/profile/d/u/d.dubbeldam/d.dubbeldam.html", range: foundRangeDubbeldam)
      }
      
      let foundRangeCalero: NSRange = mutableAttributedString.mutableString.range(of: "Sofia Calero")
      if foundRangeCalero.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "https://www.tue.nl/en/research/researchers/sofia-calero/", range: foundRangeCalero)
      }
      
      let foundRangeVlugt: NSRange = mutableAttributedString.mutableString.range(of: "Thijs J.H. Vlugt")
      if foundRangeVlugt.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "http://homepage.tudelft.nl/v9k6y/", range: foundRangeVlugt)
      }
      
      let foundRangeSnurr: NSRange = mutableAttributedString.mutableString.range(of: "Randall Q. Snurr")
      if foundRangeSnurr.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "http://www.iec.northwestern.edu", range: foundRangeSnurr)
      }
      
      let foundRangeYoungchul: NSRange = mutableAttributedString.mutableString.range(of: "Chung G. Yongchul ")
      if foundRangeYoungchul.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "http://gregchung.github.io", range: foundRangeYoungchul)
      }
      
      let foundRangeStefanGustavson: NSRange = mutableAttributedString.mutableString.range(of: "Stefan Gustavson")
      if foundRangeStefanGustavson.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "https://github.com/stegu", range: foundRangeStefanGustavson)
      }
      
      let foundRangeErikSmistad: NSRange = mutableAttributedString.mutableString.range(of: "Erik Smistad")
      if foundRangeErikSmistad.location != NSNotFound
      {
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: "https://www.eriksmistad.no/marching-cubes-implementation-using-opencl-and-opengl/", range: foundRangeErikSmistad)
      }
      
      
      let attributedString: NSAttributedString = NSAttributedString(attributedString: mutableAttributedString)
      self.textView?.textStorage?.setAttributedString(attributedString)
      
      
      self.textView?.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor : NSColor.tertiaryLabelColor,
        NSAttributedString.Key.cursor : NSCursor.pointingHand]
      
      self.textView?.font = NSFont(name: "HelveticaNeue", size: 12.0) ?? NSFont.systemFont(ofSize: 12.0)
      self.textView?.textColor = NSColor.tertiaryLabelColor
    }
  }
  
  @IBAction func visitWebsite(_ sender: AnyObject)
  {
    guard let url = self.appURL else { return }
    NSWorkspace.shared.open(url)
  }
  
  @IBAction func showAcknowledgedLicenses(_ sender: AnyObject)
  {
    guard let pdfURL = Bundle.main.url(forResource: "AcknowledgedLicenses", withExtension: "pdf")
      else { return }
    NSWorkspace.shared.open(pdfURL)
  }
}

