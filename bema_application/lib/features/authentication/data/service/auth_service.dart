//import 'dart:io';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store user with questionnaireCompleted flag
  Future<AuthResult> storeUser(User firebaseUser, String name) async {
    UserModel user = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      name: name,
      questionnaireCompleted: false, // Set this to false at registration
    );

    try {
      print('Attempting to store user in Firestore: ${firebaseUser.uid}');
      await _firestore
          .collection('AppUsers')
          .doc(firebaseUser.uid)
          .set(user.toJson());
      print('User successfully stored in Firestore');
      return AuthResult(isSuccess: true, message: 'User Registered');
    } catch (e) {
      print('Error storing user in Firestore: $e');
      return AuthResult(
          isSuccess: false, message: 'Failed to register user: $e');
    }
  }

  // Update questionnaire completion status
  Future<void> updateQuestionnaireStatus(User user) async {
    try {
      await _firestore
          .collection('AppUsers')
          .doc(user.uid)
          .update({'questionnaireCompleted': true});
    } catch (e) {
      print("Error updating questionnaire status: $e");
    }
  }

  // Check if user has completed the questionnaire
  Future<bool> checkQuestionnaireCompletion(User user) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('AppUsers').doc(user.uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['questionnaireCompleted'] ??
            false;
      }
    } catch (e) {
      print("Error checking questionnaire completion: $e");
    }
    return false;
  }
}
