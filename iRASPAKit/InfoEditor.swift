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

import Foundation
import simd
import RenderKit


public protocol InfoEditor: AnyObject
{
  var authorFirstName: String {get set}
  var authorMiddleName: String {get set}
  var authorLastName: String {get set}
  var authorOrchidID: String {get set}
  var authorResearcherID: String {get set}
  var authorAffiliationUniversityName: String {get set}
  var authorAffiliationFacultyName: String {get set}
  var authorAffiliationInstituteName: String {get set}
  var authorAffiliationCityName: String {get set}
  var authorAffiliationCountryName: String {get set}
  
  var creationDate: Date {get set}
  var creationTemperature: String {get set}
  var creationTemperatureScale: Structure.TemperatureScale {get set}
  var creationPressure: String {get set}
  var creationPressureScale: Structure.PressureScale {get set}
  var creationMethod: Structure.CreationMethod {get set}
  var creationUnitCellRelaxationMethod: Structure.UnitCellRelaxationMethod {get set}
  var creationAtomicPositionsSoftwarePackage: String {get set}
  var creationAtomicPositionsIonsRelaxationAlgorithm: Structure.IonsRelaxationAlgorithm {get set}
  var creationAtomicPositionsIonsRelaxationCheck: Structure.IonsRelaxationCheck {get set}
  var creationAtomicPositionsForcefield: String {get set}
  var creationAtomicPositionsForcefieldDetails: String {get set}
  var creationAtomicChargesSoftwarePackage: String {get set}
  var creationAtomicChargesAlgorithms: String {get set}
  var creationAtomicChargesForcefield: String {get set}
  var creationAtomicChargesForcefieldDetails: String {get set}
  
  var experimentalMeasurementRadiation: String {get set}
  var experimentalMeasurementWaveLength: String {get set}
  var experimentalMeasurementThetaMin: String {get set}
  var experimentalMeasurementThetaMax: String {get set}
  var experimentalMeasurementIndexLimitsHmin: String {get set}
  var experimentalMeasurementIndexLimitsHmax: String {get set}
  var experimentalMeasurementIndexLimitsKmin: String {get set}
  var experimentalMeasurementIndexLimitsKmax: String {get set}
  var experimentalMeasurementIndexLimitsLmin: String {get set}
  var experimentalMeasurementIndexLimitsLmax: String {get set}
  var experimentalMeasurementNumberOfSymmetryIndependentReflections: String {get set}
  var experimentalMeasurementSoftware: String {get set}
  var experimentalMeasurementRefinementDetails: String {get set}
  var experimentalMeasurementGoodnessOfFit: String {get set}
  var experimentalMeasurementRFactorGt: String {get set}
  var experimentalMeasurementRFactorAll: String {get set}
  
  var chemicalFormulaMoiety: String {get set}
  var chemicalFormulaSum: String {get set}
  var chemicalNameSystematic: String {get set}
  
  var citationArticleTitle: String {get set}
  var citationAuthors: String {get set}
  var citationJournalTitle: String {get set}
  var citationJournalVolume: String {get set}
  var citationJournalNumber: String {get set}
  var citationDOI: String {get set}
  var citationPublicationDate: Date {get set}
  var citationDatebaseCodes: String {get set}
}
