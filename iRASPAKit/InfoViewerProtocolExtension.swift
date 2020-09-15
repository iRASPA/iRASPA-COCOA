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
import simd
import MathKit
import RenderKit


extension InfoViewer
{

  
  public var structureAuthorFirstName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorFirstName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorFirstName = newValue ?? ""}
    }
  }
  
  public var structureAuthorMiddleName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorMiddleName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorMiddleName = newValue ?? ""}
    }
  }
  
  public var structureAuthorLastName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorLastName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorLastName = newValue ?? ""}
    }
  }
  
  public var structureAuthorOrchidID: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorOrchidID })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorOrchidID = newValue ?? ""}
    }
  }
 
  public var structureAuthorResearcherID: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorResearcherID })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorResearcherID = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationUniversityName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationUniversityName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationUniversityName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationFacultyName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationFacultyName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationFacultyName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationInstituteName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationInstituteName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationInstituteName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationCityName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationCityName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationCityName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationCountryName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationCountryName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationCountryName = newValue ?? ""}
    }
  }
  
  public var structureCreationDate: Date?
  {
    get
    {
      let set: Set<Date> = Set(self.allStructures.compactMap{ return $0.creationDate })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationDate = newValue ?? Date()}
    }
  }
  
  public var structureCreationTemperature: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationTemperature })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationTemperature = newValue ?? ""}
    }
  }
  
  public var structureCreationTemperatureScale: Structure.TemperatureScale?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationTemperatureScale.rawValue })
      return Set(set).count == 1 ? Structure.TemperatureScale(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationTemperatureScale = newValue ?? .Kelvin}
    }
  }
  
  public var structureCreationPressure: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationPressure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationPressure = newValue ?? ""}
    }
  }

  public var structureCreationPressureScale: Structure.PressureScale?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationPressureScale.rawValue })
      return Set(set).count == 1 ? Structure.PressureScale(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationPressureScale = newValue ?? .Pascal}
    }
  }
  
  public var structureCreationMethod: Structure.CreationMethod?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationMethod.rawValue })
      return Set(set).count == 1 ? Structure.CreationMethod(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationMethod = newValue ?? .unknown}
    }
  }
  
  public var structureCreationUnitCellRelaxationMethod: Structure.UnitCellRelaxationMethod?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationUnitCellRelaxationMethod.rawValue })
      return Set(set).count == 1 ? Structure.UnitCellRelaxationMethod(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationUnitCellRelaxationMethod = newValue ?? .unknown}
    }
  }
  
  public var structureCreationAtomicPositionsSoftwarePackage: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsSoftwarePackage })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsSoftwarePackage = newValue ?? ""}
    }
  }

  
  public var structureCreationAtomicPositionsIonsRelaxationAlgorithm: Structure.IonsRelaxationAlgorithm?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsIonsRelaxationAlgorithm.rawValue })
      return Set(set).count == 1 ? Structure.IonsRelaxationAlgorithm(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsIonsRelaxationAlgorithm = newValue ?? .unknown}
    }
  }
  
  public var structureCreationAtomicPositionsIonsRelaxationCheck: Structure.IonsRelaxationCheck?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsIonsRelaxationCheck.rawValue })
      return Set(set).count == 1 ? Structure.IonsRelaxationCheck(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsIonsRelaxationCheck = newValue ?? .unknown }
    }
  }
  
  public var structureCreationAtomicPositionsForcefield: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsForcefield })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsForcefield = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicPositionsForcefieldDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsForcefieldDetails })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsForcefieldDetails = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesSoftwarePackage: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesSoftwarePackage })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesSoftwarePackage = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesAlgorithms: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesAlgorithms })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesAlgorithms = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesForcefield: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesForcefield })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesForcefield = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesForcefieldDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesForcefieldDetails })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesForcefieldDetails = newValue ?? ""}
    }
  }
  
  // Experimental
  
  public var structureExperimentalMeasurementRadiation: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRadiation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRadiation = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementWaveLength: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementWaveLength })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementWaveLength = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementThetaMin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementThetaMin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementThetaMin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementThetaMax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementThetaMax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementThetaMax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsHmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsHmin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsHmin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsHmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsHmax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsHmax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsKmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsKmin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsKmin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsKmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsKmax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsKmax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsLmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsLmin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsLmin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsLmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsLmax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsLmax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementNumberOfSymmetryIndependentReflections: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementNumberOfSymmetryIndependentReflections })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementNumberOfSymmetryIndependentReflections = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementSoftware: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementSoftware })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementSoftware = newValue ?? ""}
    }
  }

  public var structureExperimentalMeasurementRefinementDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRefinementDetails })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRefinementDetails = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementGoodnessOfFit: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementGoodnessOfFit })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementGoodnessOfFit = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementRFactorGt: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRFactorGt })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRFactorGt = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementRFactorAll: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRFactorAll })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRFactorAll = newValue ?? ""}
    }
  }
  
  // chemical
  public var structureChemicalFormulaMoiety: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.chemicalFormulaMoiety })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.chemicalFormulaMoiety = newValue ?? ""}
    }
  }
  public var structureChemicalFormulaSum: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.chemicalFormulaSum })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.chemicalFormulaSum = newValue ?? ""}
    }
  }
  public var structureChemicalNameSystematic: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.chemicalNameSystematic })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.chemicalNameSystematic = newValue ?? ""}
    }
  }
  
  
  // citation
  public var structureCitationArticleTitle: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationArticleTitle })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationArticleTitle = newValue ?? ""}
    }
  }
  public var structureCitationAuthors: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationAuthors })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationAuthors = newValue ?? ""}
    }
  }
  public var structureCitationJournalTitle: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationJournalTitle })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationJournalTitle = newValue ?? ""}
    }
  }
  public var structureCitationJournalVolume: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationJournalVolume })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationJournalVolume = newValue ?? ""}
    }
  }
  public var structureCitationJournalNumber: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationJournalNumber })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationJournalNumber = newValue ?? ""}
    }
  }
  public var structureCitationDOI: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationDOI })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationDOI = newValue ?? ""}
    }
  }
  public var structureCitationPublicationDate: Date?
  {
    get
    {
      let set: Set<Date> = Set(self.allStructures.compactMap{ return $0.citationPublicationDate })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationPublicationDate = newValue ?? Date()}
    }
  }
  public var structureCitationDatebaseCodes: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationDatebaseCodes })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationDatebaseCodes = newValue ?? ""}
    }
  }
}

extension Array where Iterator.Element == InfoViewer
{
  public var allStructures: [Structure]
  {
    return self.flatMap{$0.allStructures}
  }
  
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allRenderFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allRenderFrames}
  }
  

  
  public var structureAuthorFirstName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorFirstName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorFirstName = newValue ?? ""}
    }
  }
  
  public var structureAuthorMiddleName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorMiddleName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorMiddleName = newValue ?? ""}
    }
  }
  
  public var structureAuthorLastName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorLastName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorLastName = newValue ?? ""}
    }
  }
  
  public var structureAuthorOrchidID: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorOrchidID })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorOrchidID = newValue ?? ""}
    }
  }
  
  public var structureAuthorResearcherID: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorResearcherID })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorResearcherID = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationUniversityName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationUniversityName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationUniversityName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationFacultyName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationFacultyName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationFacultyName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationInstituteName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationInstituteName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationInstituteName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationCityName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationCityName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationCityName = newValue ?? ""}
    }
  }
  
  public var structureAuthorAffiliationCountryName: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.authorAffiliationCountryName })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.authorAffiliationCountryName = newValue ?? ""}
    }
  }
  
  public var structureCreationDate: Date?
  {
    get
    {
      let set: Set<Date> = Set(self.allStructures.compactMap{ return $0.creationDate })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationDate = newValue ?? Date()}
    }
  }
  
  public var structureCreationTemperature: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationTemperature })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationTemperature = newValue ?? ""}
    }
  }
  
  public var structureCreationTemperatureScale: Structure.TemperatureScale?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationTemperatureScale.rawValue })
      return Set(set).count == 1 ? Structure.TemperatureScale(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationTemperatureScale = newValue ?? .Kelvin}
    }
  }
  
  public var structureCreationPressure: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationPressure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationPressure = newValue ?? ""}
    }
  }
  
  public var structureCreationPressureScale: Structure.PressureScale?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationPressureScale.rawValue })
      return Set(set).count == 1 ? Structure.PressureScale(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationPressureScale = newValue ?? .Pascal}
    }
  }
  
  public var structureCreationMethod: Structure.CreationMethod?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationMethod.rawValue })
      return Set(set).count == 1 ? Structure.CreationMethod(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationMethod = newValue ?? .unknown}
    }
  }
  
  public var structureCreationUnitCellRelaxationMethod: Structure.UnitCellRelaxationMethod?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationUnitCellRelaxationMethod.rawValue })
      return Set(set).count == 1 ? Structure.UnitCellRelaxationMethod(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationUnitCellRelaxationMethod = newValue ?? .unknown}
    }
  }
  
  public var structureCreationAtomicPositionsSoftwarePackage: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsSoftwarePackage })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsSoftwarePackage = newValue ?? ""}
    }
  }
  
  
  public var structureCreationAtomicPositionsIonsRelaxationAlgorithm: Structure.IonsRelaxationAlgorithm?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsIonsRelaxationAlgorithm.rawValue })
      return Set(set).count == 1 ? Structure.IonsRelaxationAlgorithm(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsIonsRelaxationAlgorithm = newValue ?? .unknown}
    }
  }
  
  public var structureCreationAtomicPositionsIonsRelaxationCheck: Structure.IonsRelaxationCheck?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsIonsRelaxationCheck.rawValue })
      return Set(set).count == 1 ? Structure.IonsRelaxationCheck(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsIonsRelaxationCheck = newValue ?? .unknown }
    }
  }
  
  public var structureCreationAtomicPositionsForcefield: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsForcefield })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsForcefield = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicPositionsForcefieldDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicPositionsForcefieldDetails })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicPositionsForcefieldDetails = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesSoftwarePackage: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesSoftwarePackage })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesSoftwarePackage = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesAlgorithms: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesAlgorithms })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesAlgorithms = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesForcefield: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesForcefield })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesForcefield = newValue ?? ""}
    }
  }
  
  public var structureCreationAtomicChargesForcefieldDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.creationAtomicChargesForcefieldDetails })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.creationAtomicChargesForcefieldDetails = newValue ?? ""}
    }
  }
  
  // Experimental
  
  public var structureExperimentalMeasurementRadiation: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRadiation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRadiation = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementWaveLength: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementWaveLength })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementWaveLength = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementThetaMin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementThetaMin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementThetaMin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementThetaMax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementThetaMax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementThetaMax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsHmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsHmin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsHmin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsHmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsHmax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsHmax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsKmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsKmin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsKmin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsKmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsKmax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsKmax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsLmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsLmin })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsLmin = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementIndexLimitsLmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementIndexLimitsLmax })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementIndexLimitsLmax = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementNumberOfSymmetryIndependentReflections: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementNumberOfSymmetryIndependentReflections })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementNumberOfSymmetryIndependentReflections = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementSoftware: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementSoftware })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementSoftware = newValue ?? ""}
    }
  }
  
  public var structureExperimentalMeasurementRefinementDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRefinementDetails })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRefinementDetails = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementGoodnessOfFit: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementGoodnessOfFit })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementGoodnessOfFit = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementRFactorGt: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRFactorGt })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRFactorGt = newValue ?? ""}
    }
  }
  public var structureExperimentalMeasurementRFactorAll: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.experimentalMeasurementRFactorAll })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.experimentalMeasurementRFactorAll = newValue ?? ""}
    }
  }
  
  // chemical
  public var structureChemicalFormulaMoiety: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.chemicalFormulaMoiety })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.chemicalFormulaMoiety = newValue ?? ""}
    }
  }
  public var structureChemicalFormulaSum: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.chemicalFormulaSum })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.chemicalFormulaSum = newValue ?? ""}
    }
  }
  public var structureChemicalNameSystematic: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.chemicalNameSystematic })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.chemicalNameSystematic = newValue ?? ""}
    }
  }
  
  
  // citation
  public var structureCitationArticleTitle: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationArticleTitle })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationArticleTitle = newValue ?? ""}
    }
  }
  public var structureCitationAuthors: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationAuthors })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationAuthors = newValue ?? ""}
    }
  }
  public var structureCitationJournalTitle: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationJournalTitle })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationJournalTitle = newValue ?? ""}
    }
  }
  public var structureCitationJournalVolume: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationJournalVolume })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationJournalVolume = newValue ?? ""}
    }
  }
  public var structureCitationJournalNumber: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationJournalNumber })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationJournalNumber = newValue ?? ""}
    }
  }
  public var structureCitationDOI: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationDOI })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationDOI = newValue ?? ""}
    }
  }
  public var structureCitationPublicationDate: Date?
  {
    get
    {
      let set: Set<Date> = Set(self.allStructures.compactMap{ return $0.citationPublicationDate })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationPublicationDate = newValue ?? Date()}
    }
  }
  public var structureCitationDatebaseCodes: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.citationDatebaseCodes })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.citationDatebaseCodes = newValue ?? ""}
    }
  }
}
