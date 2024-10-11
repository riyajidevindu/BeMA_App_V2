import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class LearderboardScreen extends StatefulWidget {
  const LearderboardScreen({super.key});

  @override
  State<LearderboardScreen> createState() => _LearderboardScreenState();
}

class _LearderboardScreenState extends State<LearderboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor, // Use background color from theme
        appBar: AppBar(
          backgroundColor: backgroundColor, // Consistent background color
          title: const CustomAppBar(), // Custom AppBar from previous screen
        ),
       body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ROOKIE',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
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
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                progressText,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              SizedBox(height: 5),
              Container(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}