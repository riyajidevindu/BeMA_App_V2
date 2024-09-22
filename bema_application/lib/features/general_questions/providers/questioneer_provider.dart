import 'package:flutter/foundation.dart';

class QuestionnaireProvider with ChangeNotifier {
  bool? _hasAllergies;
  String? _allergiesDescription;
  bool? _hasDiabetes;
  String? _diabetesDuration;

  // Getters
  bool? get hasAllergies => _hasAllergies;
  String? get allergiesDescription => _allergiesDescription;
  bool? get hasDiabetes => _hasDiabetes;
  String? get diabetesDuration => _diabetesDuration;

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
}
