import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/data/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class AuthenticationProvider extends ChangeNotifier {
  //String? userType;
  User? firebaseUser;

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _authService = AuthService();

  AuthenticationProvider() {
    //getType();
  }

  // Retrieve user type from shared preferences
  // Future<dynamic> getType() async {
  //   final pref = await SharedPreferences.getInstance();
  //   userType = pref.getString('userType');
  //   notifyListeners();
  //   return userType;
  // }

  // Update user type in shared preferences
  // Future<void> updateType(String type) async {
  //   //final pref = await SharedPreferences.getInstance();
  //   await pref.setString('userType', type);
  //   debugPrint('User Type updated: $type');
  //   userType = type;
  //   notifyListeners();
  // }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = result.user;

      notifyListeners();
      return AuthResult(isSuccess: true, message: 'Login Successful');
    } catch (e) {
      String errorMessage = "An error occurred. Invalid User Credentials";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "User not found. Please check your email.";
            break;
          case 'wrong-password':
            errorMessage = "Wrong password. Please try again.";
            break;
        }
      }
      notifyListeners();

      return AuthResult(
          isSuccess: false, message: errorMessage); // Return false on error
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUp(
      {required String name,
      required String email,
      // required String number,
      required String password,
      required String confirmPassword
      // required String photoUrl,
      // required List<double> location
      }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = result.user;
      if (result.user != null) {
        await _authService.storeUser(
            result.user!, name);
      }
      notifyListeners();
      return AuthResult(isSuccess: true, message: 'User Registered');
    } catch (e) {
      String errorMessage = "An error occurred. Invalid User Credentials";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "Email already in use. Please use another email.";
            break;
          case 'weak-password':
            errorMessage =
                "Password is too weak. Please use a stronger password.";
            break;
        }
      }
      notifyListeners();

      return AuthResult(
          isSuccess: false, message: errorMessage); // Return false on error
    }
  }

  // Sign out
  Future<void> logout() async {
    //final pref = await SharedPreferences.getInstance();
    //await pref.remove('userType');
    // debugPrint('User Type removed');
    // userType = null;
    notifyListeners();
    await _auth.signOut();
    notifyListeners();
  }
}
