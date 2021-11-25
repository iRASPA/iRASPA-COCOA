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
import RenderKit
import SymmetryKit
import BinaryCodable
import simd

public class GaussianCubeVolume: GridVolume
{
  private static var classVersionNumber: Int = 1
  
  public override var materialType: Object.ObjectType
  {
    return .GaussianCubeVolume
  }
  
  public required init(copy GaussianCubeVolume: GaussianCubeVolume)
  {
    super.init(copy: GaussianCubeVolume)
  }
  
  public required init(clone GaussianCubeVolume: GaussianCubeVolume)
  {
    super.init(clone: GaussianCubeVolume)
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
  }
  
  public init(name: String)
  {
    super.init()
    self.displayName = name
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(GaussianCubeVolume.classVersionNumber)
    
   
    encoder.encode(Int(0x6f6b6199))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > GaussianCubeVolume.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6199)
    {
      throw BinaryDecodableError.invalidMagicNumber
    }
    
    try super.init(fromBinary: decoder)
  }
}
