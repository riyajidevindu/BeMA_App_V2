import 'package:bema_application/features/authentication/screens/welcome_screen.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';  // Import GoRouter

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());  // Loading state
          } else if (snapshot.hasData) {
            // User is signed in, navigate to BottomNavigationBarScreen
            Future.delayed(Duration.zero, () {
              context.go('/${RouteNames.bottomNavigationBarScreen}', extra: 0); 
            });
            return Container(); // Empty container while redirecting
          } else {
            // User is not signed in, show WelcomeScreen
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}