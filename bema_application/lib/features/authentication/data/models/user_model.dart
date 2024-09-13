class UserModel {
  String id;
  String email;
  String name;
  // String photoUrl;
  // String contact;
  // List<double> location;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    // required this.photoUrl,
    // required this.contact,
    // required this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      // photoUrl: json['photoUrl'] as String,
      // contact: json['contact'],
      // location:
      //     (json['location'] as List<dynamic>).map((e) => e as double).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      //'photoUrl': photoUrl,
      //'contact': contact,
      //'location': location,
    };
  }
}
