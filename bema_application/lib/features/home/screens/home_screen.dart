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
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0), // Padding inside the box
              margin: EdgeInsets.only(
                  bottom: 20.0), // Space around the box if needed
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                    255, 26, 201, 213), // Background color of the box
                borderRadius: BorderRadius.circular(12), // Rounded corners
                border: Border.all(
                    color: Colors.grey.shade300), // Border around the box
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Good Morning, ABC",
                    style: TextStyle(
                      fontSize: 22,
                      color: Color.fromARGB(255, 1, 34, 75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "6 th Monday",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 18, 8, 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/tasks.png'),
                    ),
                    title: "Daily Task",
                    subtitle: "Your Health Guide",
                    color: Colors.lightBlueAccent,
                  ),
                  _buildCard(
                   avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/mood.png'),
                    ),
                    title: "Mood Friend",
                    subtitle: "Fix You Mood",
                    color: Colors.orangeAccent
                  ),
                  _buildCard(
                   avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/meals.png'),
                    ),
                    title: "Your Meals",
                    subtitle: "Add to daily",
                    color: Colors.orange
                  ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/score.png'),
                    ),
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

  Widget _buildCard({
    required Widget avatar, // Accepts any widget (e.g., CircleAvatar)
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            avatar, // Display the passed widget (CircleAvatar in this case)
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
