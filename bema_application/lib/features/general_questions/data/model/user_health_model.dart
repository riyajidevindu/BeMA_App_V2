import 'package:cloud_firestore/cloud_firestore.dart';

class UserHealthModel {
  final int age;
  final double height;
  final double weight;
  final String gender;
  final String profession;
  final bool hasDiabetes;
  final int? diabetesTreatmentYears;
  final bool hasHighBloodPressure;
  final int? highBloodPressureTreatmentYears;
  final bool hasCholesterol;
  final int? cholesterolTreatmentYears;
  final bool hasAllergies;
  final bool hadSurgeries;
  final String? surgeryType;
  final bool hasDisabilitiesOrSpecialNeeds;
  final bool smokes;
  final String? smokingFrequency;
  final bool drinks;
  final int? glassesPerWeek;
  final bool exercises;
  final String? favoriteExercise;

  UserHealthModel({
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.profession,
    required this.hasDiabetes,
    this.diabetesTreatmentYears,
    required this.hasHighBloodPressure,
    this.highBloodPressureTreatmentYears,
    required this.hasCholesterol,
    this.cholesterolTreatmentYears,
    required this.hasAllergies,
    required this.hadSurgeries,
    this.surgeryType,
    required this.hasDisabilitiesOrSpecialNeeds,
    required this.smokes,
    this.smokingFrequency,
    required this.drinks,
    this.glassesPerWeek,
    required this.exercises,
    this.favoriteExercise,
  });

  // Convert a UserHealthModel into a Map. The keys must correspond to the names of the fields in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'profession': profession,
      'hasDiabetes': hasDiabetes,
      'diabetesTreatmentYears': diabetesTreatmentYears,
      'hasHighBloodPressure': hasHighBloodPressure,
      'highBloodPressureTreatmentYears': highBloodPressureTreatmentYears,
      'hasCholesterol': hasCholesterol,
      'cholesterolTreatmentYears': cholesterolTreatmentYears,
      'hasAllergies': hasAllergies,
      'hadSurgeries': hadSurgeries,
      'surgeryType': surgeryType,
      'hasDisabilitiesOrSpecialNeeds': hasDisabilitiesOrSpecialNeeds,
      'smokes': smokes,
      'smokingFrequency': smokingFrequency,
      'drinks': drinks,
      'glassesPerWeek': glassesPerWeek,
      'exercises': exercises,
      'favoriteExercise': favoriteExercise,
    };
  }

  // Convert a Map into a UserHealthModel
  factory UserHealthModel.fromMap(Map<String, dynamic> map) {
    return UserHealthModel(
      age: map['age'] ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      gender: map['gender'] ?? '',
      profession: map['profession'] ?? '',
      hasDiabetes: map['hasDiabetes'] ?? false,
      diabetesTreatmentYears: map['diabetesTreatmentYears']?.toInt(),
      hasHighBloodPressure: map['hasHighBloodPressure'] ?? false,
      highBloodPressureTreatmentYears:
          map['highBloodPressureTreatmentYears']?.toInt(),
      hasCholesterol: map['hasCholesterol'] ?? false,
      cholesterolTreatmentYears: map['cholesterolTreatmentYears']?.toInt(),
      hasAllergies: map['hasAllergies'] ?? false,
      hadSurgeries: map['hadSurgeries'] ?? false,
      surgeryType: map['surgeryType'],
      hasDisabilitiesOrSpecialNeeds:
          map['hasDisabilitiesOrSpecialNeeds'] ?? false,
      smokes: map['smokes'] ?? false,
      smokingFrequency: map['smokingFrequency'],
      drinks: map['drinks'] ?? false,
      glassesPerWeek: map['glassesPerWeek']?.toInt(),
      exercises: map['exercises'] ?? false,
      favoriteExercise: map['favoriteExercise'],
    );
  }
}
