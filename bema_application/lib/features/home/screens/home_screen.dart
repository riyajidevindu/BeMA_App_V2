import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor, // Use background color from theme
      appBar: AppBar(
        backgroundColor: backgroundColor, // Consistent background color
        title: const CustomAppBar(), // Custom AppBar from previous screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
          children: [
            // Welcome message
            const Text(
              "Welcome to Your Health Dashboard",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Spacing

            // Short description
            const Text(
              "Track your progress, view tips, and continue improving your health journey!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: screenHeight * 0.05), // Spacing

            // Icon or emoji for the home screen
            Text(
              "🏡", // Home emoji
              style: TextStyle(fontSize: screenWidth * 0.2), // Adjust emoji size
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.05), // Spacing

            // Button to view user profile
            ElevatedButton(
              onPressed: () {
                context.goNamed(RouteNames.profileScreen); // Navigate to Profile Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button color
                minimumSize: const Size(double.infinity, 50), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "View Profile",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20), // Spacing

            // Button to view tips or resources
            ElevatedButton(
              onPressed: () {
                //context.goNamed(RouteNames.tipsScreen); // Navigate to Tips Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button color
                minimumSize: const Size(double.infinity, 50), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "View Health Tips",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20), // Spacing

            // Button to start the questionnaire again or explore more
            ElevatedButton(
              onPressed: () {
                //context.goNamed(RouteNames.questionScreen1); // Restart the questionnaire
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button color
                minimumSize: const Size(double.infinity, 50), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Start Over",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
