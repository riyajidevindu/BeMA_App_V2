import 'package:flutter/foundation.dart';

class QuestionnaireProvider with ChangeNotifier {
  bool? _hasAllergies;
  String? _allergiesDescription;
  bool? _hasDiabetes;
  String? _diabetesDuration;
  int? _age;
  String? _selectedGender;
  String? _selectedOccupation;
  String? _customOccupation;
  bool? _hasHypertension;
  String? _hypertensionDuration;
  bool? _hasCholesterol;
  String? _cholesterolDuration;

  // Getters
  bool? get hasAllergies => _hasAllergies;
  String? get allergiesDescription => _allergiesDescription;
  bool? get hasDiabetes => _hasDiabetes;
  String? get diabetesDuration => _diabetesDuration;
  int? get age => _age;
  String? get selectedGender => _selectedGender;
  String? get selectedOccupation => _selectedOccupation;
  String? get customOccupation => _customOccupation;
  bool? get hasHypertension => _hasHypertension;
  String? get hypertensionDuration => _hypertensionDuration;
  bool? get hasCholesterol => _hasCholesterol;
  String? get cholesterolDuration => _cholesterolDuration;
  

  // Setters with notifyListeners to update UI when state changes
  void setHasAllergies(bool? value) {
    _hasAllergies = value;
    notifyListeners();
  }

  void setAllergiesDescription(String? value) {
    _allergiesDescription = value;
    notifyListeners();
  }

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

}
