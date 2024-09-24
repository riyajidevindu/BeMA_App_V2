import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1;

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
                    context.goNamed(RouteNames.questionScreen5);
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
                    value: 0.25, // Progress (next step)
                    backgroundColor: Colors.grey,
                    color: Colors.blue, // Progress bar color
                    //minHeight: 8, // Slightly increase the height of the progress bar
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
                      "👋", // Waving hand emoji
                      style: TextStyle(fontSize: 50), // Emoji size
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      "Hey Mr. ${userName}", // Greet the user by name from widget
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    const Text(
                      "We're friends now!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    const Text(
                      "😊", // Smiling face emoji
                      style: TextStyle(fontSize: 50), // Emoji size
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    const Text(
                      "Let's take the next step and gather some medical info to help you better.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    const Text(
                      "🩺", // Stethoscope emoji
                      style: TextStyle(fontSize: 50), // Emoji size
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    const Text(
                      "Ready? Let's do it!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    ElevatedButton(
                      onPressed: () {
                        context.goNamed(RouteNames.questionScreen7);
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
