import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestionScreen14 extends StatefulWidget {
  const QuestionScreen14({super.key});

  @override
  State<QuestionScreen14> createState() => _QuestionScreen14State();
}

class _QuestionScreen14State extends State<QuestionScreen14> {
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.15;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Column(
        children: [
          const SizedBox(height: 50),
          
          // Row for Back button and Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Back button inside a transparent circle
                GestureDetector(
                  onTap: () {
                    context.goNamed(RouteNames.questionScreen13); // Go back to previous screen
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2), // Transparent background
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white, // White arrow color
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.025), // Space between back button and progress bar

                // Progress bar with increased width
                const Expanded(
                  child: LinearProgressIndicator(
                    value: 0.65, // Progress (adjust as needed)
                    backgroundColor: Colors.grey,
                    color: Colors.blue, // Progress bar color
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Now,",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "Let's talk about your habits, ${userName}!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    const Text(
                      "We'd like to ask a few questions ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const Text(
                      "about your lifestyle.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Text(
                      "🚬🍷", // Smoking and alcohol emojis
                      style: TextStyle(fontSize: emojiSize), // Emoji size
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    const Text(
                      "This will help us to give you more tailored advice!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    ElevatedButton(
                      onPressed: () {
                        context.goNamed(RouteNames.questionScreen15); // Navigate to behavioral questions
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Blue button color
                        minimumSize: const Size(double.infinity, 50), // Full-width button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
