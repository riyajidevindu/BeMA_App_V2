import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LearderboardScreen extends StatefulWidget {
  const LearderboardScreen({super.key});

  @override
  State<LearderboardScreen> createState() => _LearderboardScreenState();
}

class _LearderboardScreenState extends State<LearderboardScreen> {
  final profileService = ProfileService();
  String userName = 'User';
  bool isLoading = true;
  double totalPoints = 0; // Store the total points

  @override
  void initState() {
    super.initState();
    getUser(); // Fetch user details when the screen loads
  }

  /// Fetches the user profile data
  Future<void> getUser() async {
    try {
      UserModel? user =
          await profileService.getUser(FirebaseAuth.instance.currentUser!.uid);

      // Debug the fetched user details
      debugPrint('Fetched user: ${user?.name}');

      if (user != null && user.name.isNotEmpty) {
        setState(() {
          userName = user.name;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      setState(() {
        isLoading = false; // Set loading to false once data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate total points based on task progress
    totalPoints = calculateTotalPoints();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Your Daily Points",
                  style: TextStyle(
                    fontSize: 24,
                    color: Color.fromARGB(255, 2, 150, 79),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildTotalPointsBox(), // Display total points inside a box
            const SizedBox(height: 20), // Increased space
            Expanded(
              child: ListView(
                children: [
                  buildAchievementRow('Water Intake', '90/200 Articles Liked', 90 / 200, Icons.local_drink),
                  buildAchievementRow('Walking Duration', '2/8 Games Played', 2 / 8, Icons.directions_walk),
                  buildAchievementRow('Stretching Time', '25/30 Apps Downloaded', 25 / 30, Icons.accessibility_new),
                  buildAchievementRow('Mindfulness Exercise', '0/5 Items Bought', 0 / 5, Icons.self_improvement),
                  buildAchievementRow('Nutrition Tip', '0/5 Items Bought', 0 / 5, Icons.local_dining),
                  buildAchievementRow('Sleep Reminder', '0/5 Items Bought', 0 / 5, Icons.nightlight_round),
                  buildAchievementRow('Screen Time Break', '0/5 Items Bought', 0 / 5, Icons.screen_lock_portrait),
                  buildAchievementRow('Special Task', '0/5 Items Bought', 0 / 5, Icons.assignment),
                  buildAchievementRow('Social Interaction', '0/5 Items Bought', 0 / 5, Icons.people),
                  buildAchievementRow('Posture Check', '0/5 Items Bought', 0 / 5, Icons.accessibility),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget for the total points box
  Widget buildTotalPointsBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Total Points: ${totalPoints.toStringAsFixed(1)} / 100',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// Calculate points for each task based on progress
  double calculatePoints(double progress) {
    return progress * 10;
  }

  /// Calculate total points by summing up points from all tasks
  double calculateTotalPoints() {
    return calculatePoints(90 / 200) +
           calculatePoints(2 / 8) +
           calculatePoints(25 / 30) +
           calculatePoints(0 / 5) +
           calculatePoints(0 / 5) +
           calculatePoints(0 / 5) +
           calculatePoints(0 / 5) +
           calculatePoints(0 / 5) +
           calculatePoints(0 / 5) +
           calculatePoints(0 / 5);
  }

  // Method to determine progress bar color based on progress
  Color getProgressColor(double progress) {
    if (progress >= 0.7) {
      return Colors.green; // High progress
    } else if (progress >= 0.3) {
      return Colors.blue; // Medium progress
    } else {
      return Colors.red; // Low progress
    }
  }

  /// Widget to build each task row with points
  Widget buildAchievementRow(String title, String progressText, double progress, IconData icon) {
    int progressPercentage = (progress * 100).round(); // Calculate percentage
    double points = calculatePoints(progress); // Calculate points for this task

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Space between containers
      padding: const EdgeInsets.all(12.0), // Padding inside each container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  maxLines: 2, // Text wrapping for long titles
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Text(
                  progressText,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getProgressColor(progress).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: getProgressColor(progress), width: 1),
                ),
                child: Text(
                  '${points.toStringAsFixed(1)} / 10', // Display points for each task
                  style: TextStyle(
                    color: getProgressColor(progress),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Space between title and progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0%', // Start of progress
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '$progressPercentage%', // Current percentage
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const Text(
                '100%', // End of progress
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 5), // Space between labels and progress bar
          SizedBox(
            height: 12, // Height of the progress bar
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6), // Rounded corners
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(progress)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
