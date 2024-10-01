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
        body: const Padding(
          padding:
              EdgeInsets.all(16.0), // Provide padding around body content
          child:      Text(
                    "Learboard screen",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 1, 34, 75),
                      fontWeight: FontWeight.bold,
                    ),
          ),
        ));
  }
}