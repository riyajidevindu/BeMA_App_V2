class UserModel {
  String id;
  String email;
  String name;
  bool questionnaireCompleted; // New field to track if the user completed the questionnaire

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.questionnaireCompleted = false, // Default to false
  });

  // Factory method to create a UserModel from a JSON object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      questionnaireCompleted: json['questionnaireCompleted'] as bool? ?? false, // Default to false if not set
    );
  }

  // Method to convert a UserModel to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'questionnaireCompleted': questionnaireCompleted, // Include this field in the serialized JSON
    };
  }
}
