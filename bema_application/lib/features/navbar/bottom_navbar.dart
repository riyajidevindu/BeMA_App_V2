import 'package:flutter/material.dart';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_screen.dart';
import 'package:bema_application/features/authentication/screens/learderboard_screen/learderboard_screen.dart';
import 'package:bema_application/features/daily_suggestions/screens/daily_suggestions_screen.dart';
import 'package:bema_application/features/home/screens/home_screen.dart';
import 'package:bema_application/features/instant_stress_release/screens/instant_stress_release_screen.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';

class BNavbarScreen extends StatefulWidget {
  final int initialIndex; // Pass initial index for default tab
  const BNavbarScreen({super.key, this.initialIndex = 0}); // Default to 0 (Home)

  @override
  State<BNavbarScreen> createState() => _BNavbarScreenState();
}

class _BNavbarScreenState extends State<BNavbarScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set the initial index
  }

  @override
  void didUpdateWidget(covariant BNavbarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  // List of screens for navigation
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    StressReleaseScreen(),
    ChatScreen(),
    DailytaskScreen(),
    LearderboardScreen(),
  ];

  // Update index when navigation item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _widgetOptions.elementAt(_selectedIndex), // Load the selected screen dynamically
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 15,
            ),
          ],
        ),
        child: CustomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // Handle tab changes
          items: [
            CustomNavigationBarItem(
              icon: const Icon(Icons.home, size: 24),
              title: const Text(
                'Home',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.air, size: 24),
              title: const Text(
                'Relax',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.chat, size: 24),
              title: const Text(
                'Chat',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.work, size: 24),
              title: const Text(
                'Tasks',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.list, size: 24),
              title: const Text(
                'Points',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ),
          ],
          selectedColor: primaryColor,
          unSelectedColor: secondaryTextColor,
          iconSize: 24, // Smaller icon size
          elevation: 10, // Add some elevation to give a floating effect
          borderRadius: const Radius.circular(30),
        ),
      ),
    );
  }
}
