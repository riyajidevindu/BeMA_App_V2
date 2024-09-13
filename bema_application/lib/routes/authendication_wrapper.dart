import 'package:bema_application/features/authentication/screens/welcome_screen.dart';
import 'package:bema_application/features/authentication/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading state
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            // User is signed in
            return const LoginScreen();
          } else {
            // User is not signed in
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
// body: FutureBuilder(
//         future: Provider.of<AuthenticationProvider>(context, listen: false)
//             .checkAuthToken(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             if ((snapshot.hasData && snapshot.data == true)) {
//               return const SelectionScreen();
//             } else {
//               return const WelcomeScreen();
//             }
//           } else {
//             return const CircularProgressIndicator();
//           }
//         },
//       ),