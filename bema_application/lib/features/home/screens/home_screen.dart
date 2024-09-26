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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning, ABC", 
              style: TextStyle(
                fontSize: 22, 
                color: Colors.redAccent,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "6 th Monday",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildCard(
                    icon: Icons.fitness_center, 
                    title: "Daily Task", 
                    subtitle: "Your Health Guide", 
                    color: Colors.lightBlueAccent
                  ),
                  _buildCard(
                    icon: Icons.mood, 
                    title: "Mood Friend", 
                    subtitle: "Fix You Mood", 
                    color: Colors.orangeAccent
                  ),
                  _buildCard(
                    icon: Icons.restaurant, 
                    title: "Your Meals", 
                    subtitle: "Add to daily", 
                    color: Colors.orange
                  ),
                  _buildCard(
                    icon: Icons.score, 
                    title: "Your Points", 
                    subtitle: "Check me", 
                    color: Colors.lightBlue
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}