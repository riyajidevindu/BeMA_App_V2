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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$userName!",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            buildAchievementRow('Hot Dog', '90/200 Articles Liked', 90 / 200, Icons.fastfood),
            buildAchievementRow('Beer', '2/8 Games Played', 2 / 8, Icons.sports_bar),
            buildAchievementRow('Protein Shake', '25/30 Apps Downloaded', 25 / 30, Icons.local_drink),
            buildAchievementRow('Soda', '0/5 Items Bought', 0 / 5, Icons.local_cafe),
          ],
        ),
      ),
    );
  }

  Widget buildAchievementRow(String title, String progressText, double progress, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.black, fontSize: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                progressText,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Container(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}