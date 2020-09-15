/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Foundation

let readPermissionDataKey: String = "nl.darkwing.iRASPA-CLI.readPermissionData"
let writePermissionDataKey: String = "nl.darkwing.iRASPA-CLI.writePermissionData"
let transferReadPermissionDataKey: String = "group.nl.darkwing.iRASPA.transferReadPermissionData"
let transferWritePermissionDataKey: String = "group.nl.darkwing.iRASPA.transferWritePermissionData"

let helpOption = OptionType.bool(value: false, shortOption: "h", longOption: "help", description: "Prints a help message.")
let surfaceAreaOption = OptionType.bool(value: false, shortOption: "s", longOption: "surfacearea", description: "Computes the surface area.")
let voidFractionOption = OptionType.bool(value: false, shortOption: "v", longOption: "voidfraction", description: "Computes the void fraction.")


if let groupDefaults: UserDefaults = UserDefaults(suiteName: "24U2ZRZ6SC.nl.darkwing.iRASPA")
{
  if let data: Data = groupDefaults.value(forKey: transferReadPermissionDataKey) as? Data
  {
    if data.count == 0
    {
      UserDefaults.standard.removeObject(forKey: readPermissionDataKey)
      groupDefaults.removeObject(forKey: transferReadPermissionDataKey)
    }
    else
    {
      var isStale: Bool = false
      do
      {
        let url: URL = try URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &isStale)
        
        let localData: Data = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(localData, forKey: readPermissionDataKey)
        
        // clear data
        groupDefaults.removeObject(forKey: transferReadPermissionDataKey)
        
      }
      catch let error
      {
        print("error: \(error.localizedDescription)")
      }
    }
  }
  
  if let data: Data = groupDefaults.value(forKey: transferWritePermissionDataKey) as? Data
  {
    if data.count == 0
    {
      UserDefaults.standard.removeObject(forKey: writePermissionDataKey)
      groupDefaults.removeObject(forKey: transferWritePermissionDataKey)
    }
    else
    {
      var isStale: Bool = false
      do
      {
        let url: URL = try URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &isStale)
        
        let localData: Data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(localData, forKey: writePermissionDataKey)
        
        // clear data
        groupDefaults.removeObject(forKey: transferWritePermissionDataKey)
      }
      catch let error
      {
        print("error: \(error.localizedDescription)")
      }
    }
  }
}

let options: [OptionType] = [surfaceAreaOption, voidFractionOption, helpOption]
let console = Console(arguments: Swift.CommandLine.arguments, options: options)

if Swift.CommandLine.arguments.count <= 1
{
  console.printUsage()
}
else
{
  if let data: Data = UserDefaults.standard.value(forKey: readPermissionDataKey) as? Data, data.count > 0
  {
    var isStale: Bool = false
    do
    {
      //var writePermissionURL: URL? = nil
      
      let permissionURL: URL = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
      
      let _: Bool = permissionURL.startAccessingSecurityScopedResource()
      
      do
      {
        try console.parse()
          
        for file in console.unparsedArguments
        {
          let url: URL = URL(fileURLWithPath: file)
          let fileName: String = url.lastPathComponent
            
          if let project: Project = Project(url: url, onlyAsymmetricUnit: false, asMolecule: false)
          {
            for option in console.options
            {
              switch(option)
              {
              case surfaceAreaOption:
                if case .bool(let value, _, _, _) = option, value
                {
                  let surfaceAreas: (gravimetric: [Double], volumetric: [Double]) = project.surfaceAreas
                  print("\(fileName) Surface area: \(surfaceAreas.gravimetric) [m^2/g]")
                  print("\(fileName) Surface area: \(surfaceAreas.volumetric) [m^2/cm^3]")
                }
              case voidFractionOption:
                if case .bool(let value, _, _, _) = option, value
                {
                  print("\(fileName) Helium void-fraction: \(project.voidFractions) [-]")
                }
              default:
                break
              }
            }
          }
          else
          {
            console.writeMessage("Unknown file \(file)")
          }
        }
        
        for option in console.options
        {
          if option == helpOption, case .bool(let value, _, _, _) = option, value
          {
            console.printUsage()
          }
        }
      }
      catch
      {
        console.printUsage()
      }
        
      //writePermissionURL?.stopAccessingSecurityScopedResource()
        
      permissionURL.stopAccessingSecurityScopedResource()
    }
  }
  else
  {
    print("Setup file-access permissions using iRASPA's preference panel.")
  }
}
