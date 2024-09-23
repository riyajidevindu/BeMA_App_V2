import 'package:flutter/foundation.dart';

class QuestionnaireProvider with ChangeNotifier {

  int? _age;
  String? _heightValue;
  String _heightUnit = 'cm'; // Default height unit is cm
  String? _weightValue;
  String _weightUnit = 'kg'; // Default weight unit is kg
  String? _selectedGender;
  String? _selectedOccupation;
  String? _customOccupation;
  bool? _hasDiabetes;
  String? _diabetesDuration;
  bool? _hasHypertension;
  String? _hypertensionDuration;
  bool? _hasCholesterol;
  String? _cholesterolDuration;
  bool? _hasAllergies;
  String? _allergiesDescription;
  bool? _hasSurgeries;
  String? _surgeryYear;
  String? _surgeryType;
  bool? _hasFamilyMedHis;
  String? _familyMedHistory;
  bool? _hasDisability;
  String? _disabilityDescription;

  // Getters
  int? get age => _age;
  String? get heightValue => _heightValue;
  String get heightUnit => _heightUnit;
  String? get weightValue => _weightValue;
  String get weightUnit => _weightUnit;
  String? get selectedGender => _selectedGender;
  String? get selectedOccupation => _selectedOccupation;
  String? get customOccupation => _customOccupation;
  bool? get hasDiabetes => _hasDiabetes;
  String? get diabetesDuration => _diabetesDuration;
  bool? get hasHypertension => _hasHypertension;
  String? get hypertensionDuration => _hypertensionDuration;
  bool? get hasCholesterol => _hasCholesterol;
  String? get cholesterolDuration => _cholesterolDuration;
  bool? get hasAllergies => _hasAllergies;
  String? get allergiesDescription => _allergiesDescription;
  bool? get hasSurgeries => _hasSurgeries;
  String? get surgeryYear => _surgeryYear;
  String? get surgeryType => _surgeryType;
  bool? get hasFamilyMedHis => _hasFamilyMedHis;
  String? get familyMedHistory => _familyMedHistory;
  bool? get hasDisability => _hasDisability;
  String? get disabilityDescription => _disabilityDescription;
  

  // Setters with notifyListeners to update UI when state changes

  void setHasDiabetes(bool? value) {
    _hasDiabetes = value;
    notifyListeners();
  }

  void setDiabetesDuration(String? value) {
    _diabetesDuration = value;
    notifyListeners();
  }

  void setAge(int? value) {
    _age = value;
    notifyListeners();
  }

  void setHeightValue(String value) {
    _heightValue = value;
    notifyListeners();
  }

  void setHeightUnit(String unit) {
    _heightUnit = unit;
    notifyListeners();
  }

  void setWeightValue(String value) {
    _weightValue = value;
    notifyListeners();
  }

  void setWeightUnit(String unit) {
    _weightUnit = unit;
    notifyListeners();
  }

  bool get isHeightWeightContinueButtonActive {
    return (_heightValue != null && _heightValue!.isNotEmpty) &&
           (_weightValue != null && _weightValue!.isNotEmpty);
  }

  void setSelectedGender(String? value) {
    _selectedGender = value;
    notifyListeners(); 
  }

  // Setters with notifyListeners to update UI when state changes
  void setSelectedOccupation(String occupation) {
    _selectedOccupation = occupation;
    _customOccupation = null; // Reset custom occupation if preset is chosen
    notifyListeners();
  }

  void setCustomOccupation(String occupation) {
    _customOccupation = occupation;
    _selectedOccupation = null; // Reset selected occupation if custom is entered
    notifyListeners();
  }

  // Method to check if the continue button should be active
  bool get isContinueButtonActive {
    return _selectedOccupation != null || (_customOccupation?.isNotEmpty ?? false);
  }

    void setHasHypertension(bool? value) {
    _hasHypertension = value;
    notifyListeners();
  }

  void setHypertensionDuration(String value) {
    _hypertensionDuration = value;
    notifyListeners();
  }

  // Method to check if the continue button should be active
  bool get isContinueButtonActive08 {
    if (_hasHypertension == null) {
      return false;
    } else if (_hasHypertension == true) {
      return _hypertensionDuration != null && _hypertensionDuration!.isNotEmpty;
    } else {
      return true; // Continue is enabled when "No" is selected
    }
  }

  void setHasCholesterol(bool? value) {
    _hasCholesterol = value;
    notifyListeners();
  }

  void setCholesterolDuration(String value) {
    _cholesterolDuration = value;
    notifyListeners();
  }

  // Method to check if the continue button should be active
  bool get isCholesterolContinueButtonActive {
    if (_hasCholesterol == null) {
      return false;
    } else if (_hasCholesterol == true) {
      return _cholesterolDuration != null && _cholesterolDuration!.isNotEmpty;
    } else {
      return true; // Continue is enabled when "No" is selected
    }
  }

  void setHasAllergies(bool? value) {
    _hasAllergies = value;
    notifyListeners();
  }

  void setAllergiesDescription(String value) {
    _allergiesDescription = value;
    notifyListeners();
  }

  bool get isAllergiesContinueButtonActive {
    if (_hasAllergies == null) {
      return false;
    } else if (_hasAllergies == true) {
      return _allergiesDescription != null && _allergiesDescription!.isNotEmpty;
    } else {
      return true;
    }
  }

  void setHasSurgeries(bool? value) {
    _hasSurgeries = value;
    notifyListeners();
  }

  void setSurgeryYear(String value) {
    _surgeryYear = value;
    notifyListeners();
  }

  void setSurgeryType(String value) {
    _surgeryType = value;
    notifyListeners();
  }

  bool get isSurgeriesContinueButtonActive {
    if (_hasSurgeries == null) {
      return false;
    } else if (_hasSurgeries == true) {
      return (_surgeryYear != null && _surgeryYear!.isNotEmpty) &&
             (_surgeryType != null && _surgeryType!.isNotEmpty);
    } else {
      return true; 
    }
  }

  void setHasFamilyMedHis(bool? value) {
    _hasFamilyMedHis = value;
    notifyListeners();
  }

  void setFamilyMedHistory(String value) {
    _familyMedHistory = value;
    notifyListeners();
  }

  bool get isFamMedHisContinueButtonActive {
    if (_hasFamilyMedHis == null) {
      return false;
    } else if (_hasFamilyMedHis == true) {
      return _familyMedHistory != null && _familyMedHistory!.isNotEmpty;
    } else {
      return true;
    }
  }

  void setHasDisability(bool? value) {
    _hasDisability = value;
    notifyListeners();
  }

  void setDisabilityDescription(String value) {
    _disabilityDescription = value;
    notifyListeners();
  }

  bool get isDisabilityButtonActive {
    if (_hasDisability == null) {
      return false;
    } else if (_hasDisability == true) {
      return _disabilityDescription != null && _disabilityDescription!.isNotEmpty;
    } else {
      return true;
    }
  }

}
