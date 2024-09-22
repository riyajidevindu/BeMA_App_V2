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
  String? get selectedOccupation => _selectedOccupation;
  String? get customOccupation => _customOccupation;

  // Getters
  bool? get hasAllergies => _hasAllergies;
  String? get allergiesDescription => _allergiesDescription;
  bool? get hasDiabetes => _hasDiabetes;
  String? get diabetesDuration => _diabetesDuration;
  int? get age => _age;
  String? get selectedGender => _selectedGender;

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

}
