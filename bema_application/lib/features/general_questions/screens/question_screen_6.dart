import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuestionScreen6 extends StatefulWidget {
  const QuestionScreen6({super.key});

  @override
  State<QuestionScreen6> createState() => _QuestionScreen6State();
}

class _QuestionScreen6State extends State<QuestionScreen6> {
  final profileService = ProfileService();
  String userName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUser(); // Fetch user details when the screen loads
  }

  Future<void> getUser() async {
    UserModel? user =
        await profileService.getUser(FirebaseAuth.instance.currentUser!.uid);

    // Debug the fetched user details
    debugPrint('Fetched user: ${user?.name}');

    if (user != null && user.name.isNotEmpty) {
      setState(() {
        userName = user.name;
        isLoading = false; // Set loading to false once name is fetched
      });
    } else {
      setState(() {
        userName = 'User'; // Set a default name if none is available
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50), // Padding at the top
            Text(
              "Hey Mr. ${userName}", // Greet the user by name from widget
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Padding after the greeting
            const Text(
              "👋", // Waving hand emoji
              style: TextStyle(fontSize: 50), // Emoji size
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // Padding after the emoji
            const Text(
              "We're friends now!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Padding after the text
            const Text(
              "😊", // Smiling face emoji
              style: TextStyle(fontSize: 50), // Emoji size
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // Padding after the emoji
            const Text(
              "Let's take the next step and gather some medical info to help you better.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20), // Padding after the text
            const Text(
              "🩺", // Stethoscope emoji
              style: TextStyle(fontSize: 50), // Emoji size
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // Padding after the emoji
            const Text(
              "Ready? Let's do it!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(), // Push button to the bottom
            ElevatedButton(
              onPressed: () {
                // Navigate to the next screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button color
                minimumSize:
                    const Size(double.infinity, 50), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20), // Padding after button
          ],
        ),
      ),
    );
  }
}
