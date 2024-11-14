
class UserHealthModel {
  final String userId;
  final int age;
  final double height;
  final String? heightUnit;
  final double weight;
  final String? weightUnit;
  final String gender;
  final String profession;
  final bool hasDiabetes;
  final int? diabetesTreatmentYears;
  final bool hasHighBloodPressure;
  final int? highBloodPressureTreatmentYears;
  final bool hasCholesterol;
  final int? cholesterolTreatmentYears;
  final bool hasAllergies;
  final String? allergyType;
  final bool hadSurgeries;
  final int? surgeryYear;
  final String? surgeryType;
  final bool hasDisabilitiesOrSpecialNeeds;
  final String? disabilityDiscription;
  final bool hasFamilyMedicalHistory;
  final String? familyMedicalHistoryDiscription;
  final bool smokes;
  final String? smokingFrequency;
  final bool drinks;
  final String? glassesPerWeek;
  final bool exercises;
  final String? favoriteExercise;

  UserHealthModel({
    required this.userId,
    required this.age,
    required this.height,
    this.heightUnit,
    required this.weight,
    this.weightUnit,
    required this.gender,
    required this.profession,
    required this.hasDiabetes,
    this.diabetesTreatmentYears,
    required this.hasHighBloodPressure,
    this.highBloodPressureTreatmentYears,
    required this.hasCholesterol,
    this.cholesterolTreatmentYears,
    required this.hasAllergies,
    this.allergyType,
    this.surgeryYear,
    required this.hadSurgeries,
    this.surgeryType,
    required this.hasDisabilitiesOrSpecialNeeds,
    this.disabilityDiscription,
    required this.hasFamilyMedicalHistory,
    this.familyMedicalHistoryDiscription,
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
      'userId': userId,
      'age': age,
      'height': height,
      'heightUnit': heightUnit,
      'weight': weight,
      'weightUnit': weightUnit,
      'gender': gender,
      'profession': profession,
      'hasDiabetes': hasDiabetes,
      'diabetesTreatmentYears': diabetesTreatmentYears,
      'hasHighBloodPressure': hasHighBloodPressure,
      'highBloodPressureTreatmentYears': highBloodPressureTreatmentYears,
      'hasCholesterol': hasCholesterol,
      'cholesterolTreatmentYears': cholesterolTreatmentYears,
      'hasAllergies': hasAllergies,
      'allergyType': allergyType,
      'hadSurgeries': hadSurgeries,
      'surgeryYear': surgeryYear,
      'surgeryType': surgeryType,
      'hasDisabilitiesOrSpecialNeeds': hasDisabilitiesOrSpecialNeeds,
      'disabilityDiscription': disabilityDiscription,
      'hasFamilyMedicalHistory':hasFamilyMedicalHistory,
      'familyMedicalHistoryDiscription':familyMedicalHistoryDiscription,
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
      userId: map['userId'],
      age: map['age'] ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      heightUnit: map['heightUnit']??'',
      weight: map['weight']?.toDouble() ?? 0.0,
      weightUnit: map['weightUnit']??'',
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
      allergyType: map['allergyType'],
      hadSurgeries: map['hadSurgeries'] ?? false,
      surgeryYear: map['surgeryYear'] ?? 0,
      surgeryType: map['surgeryType'],
      hasDisabilitiesOrSpecialNeeds:
          map['hasDisabilitiesOrSpecialNeeds'] ?? false,
      disabilityDiscription: map['disabilityDiscription'] ?? '',
      hasFamilyMedicalHistory:
          map['hasFamilyMedicalHistory'] ?? false,
      familyMedicalHistoryDiscription: map['familyMedicalHistoryDiscription'] ?? '',
      smokes: map['smokes'] ?? false,
      smokingFrequency: map['smokingFrequency'],
      drinks: map['drinks'] ?? false,
      glassesPerWeek: map['glassesPerWeek']?.toInt(),
      exercises: map['exercises'] ?? false,
      favoriteExercise: map['favoriteExercise'],
    );
  }
}
