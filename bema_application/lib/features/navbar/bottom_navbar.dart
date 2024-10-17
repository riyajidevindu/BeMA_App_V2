import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/home/screens/home_screen.dart';
import 'package:bema_application/features/instant_stress_release/screens/instant_stress_release_screen.dart';
import 'package:flutter/material.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';

class BNavbarScreen extends StatefulWidget {
  final int initialIndex; // Added to allow passing initial tab index
  const BNavbarScreen({super.key, this.initialIndex = 0}); // Default to 0 (Home)

  @override
  State<BNavbarScreen> createState() => _BNavbarScreenState();
}

class _BNavbarScreenState extends State<BNavbarScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Set the selected index to the initial index passed when navigating
    _selectedIndex = widget.initialIndex;
  }

  // List of screens for navigation
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Actual HomeScreen widget
    StressReleaseScreen(), // Actual StressReleaseScreen widget
    // Add more screens here if needed
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
        height: 55,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          border: Border.all(
            color: backgroundColor,
            width: 2.0,
          ),
        ),
        child: CustomNavigationBar(
          backgroundColor: backgroundColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // Handle tab changes
          items: [
            CustomNavigationBarItem(
              icon: const Icon(Icons.home),
              title: const Text(
                'Home',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.air),
              title: const Text(
                'Relax',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            // You can add more CustomNavigationBarItem here
          ],
          selectedColor: primaryColor,
          unSelectedColor: secondaryTextColor,
          strokeColor: const Color.fromARGB(0, 22, 0, 0),
          iconSize: 30.0,
          elevation: 0,
          borderRadius: const Radius.circular(25),
        ),
      ),
    );
  }
}
