import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';

class RelaxSectionScreen extends StatelessWidget {
  const RelaxSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20.0, top: 20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 26, 201, 213),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Relax Section",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 1, 34, 75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Choose an option to relax",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 253, 251, 251),
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
                      backgroundImage: AssetImage('assets/relax.png'),
                    ),
                    title: "Breath Relaxer",
                    subtitle: "Relax Your Mind",
                    color: Colors.orange,
                    onTap: () {
                      context.push('/${RouteNames.stressReleaseScreen}');
                    },
                  ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/chat.png'),
                    ),
                    title: "Chat with Me",
                    subtitle: "Ask Your Problem",
                    color: Colors.lightBlueAccent,
                    onTap: () {
                      context.push('/${RouteNames.chatScreen}');
                    },
                  ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/mood.png'),
                    ),
                    title: "Mood Friend",
                    subtitle: "Fix You Mood",
                    color: Colors.orangeAccent,
                    onTap: () {
                      context.push('/${RouteNames.moodFriendScreen}');
                    },
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
    required Widget avatar,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              avatar,
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
      ),
    );
  }
}