import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/common/widgets/buttons/custom_elevation_buttons.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class QuestionScreen2 extends StatelessWidget {
  const QuestionScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50), // Add padding to push content down
            const LinearProgressIndicator(
              value: 0.5, // 50% progress (adjust as needed)
              backgroundColor: Colors.grey,
              color: Colors.blue, // Blue progress
            ),
            const SizedBox(height: 30), // Padding after progress bar
            const Text(
              "How young are you?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Padding after heading
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20), // Padding after input field
            const Text(
              "We'd love to know your age so we can better understand your journey!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40), // Padding after description
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("👶", style: TextStyle(fontSize: 40)), // Child emoji
                SizedBox(width: 20),
                Text("👨", style: TextStyle(fontSize: 40)), // Adult male emoji
                SizedBox(width: 20),
                Text("👴", style: TextStyle(fontSize: 40)), // Elderly man emoji
              ],
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
