import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_screen.dart';
import 'package:bema_application/features/authentication/screens/learderboard_screen/learderboard_screen.dart';
import 'package:bema_application/features/authentication/screens/profile_screen.dart';
import 'package:bema_application/features/daily_suggestions/screens/daily_suggestions_screen.dart';
import 'package:bema_application/features/home/screens/home_screen.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:flutter/material.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final int initialIndex;
  const BottomNavigationBarScreen({super.key, required this.initialIndex});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ChatScreen(),
    const LearderboardScreen(),
    const ProfileViewScreen(),
    const DailytaskScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _selectedIndex = widget.initialIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
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
          onTap: _onItemTapped,
          items: [
            CustomNavigationBarItem(
              icon: const Icon(Icons.home),
              title:
                  const Text('Home', style: TextStyle(color: textColor)),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.work),
              title: const Text('Dairly Task',
                  style: TextStyle(color: textColor)),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.timeline),
              title: const Text('Mode Friends',
                  style: TextStyle(color: textColor)),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.list),
              title:
                  const Text('Your Points', style: TextStyle(color: textColor)),
            ),
            CustomNavigationBarItem(
              icon: const Icon(Icons.content_cut),
              title: const Text(
                'Profile',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
          selectedColor: primaryColor,
          unSelectedColor: textColor,
          strokeColor: const Color.fromARGB(0, 22, 0, 0),
          iconSize: 25.0,
          elevation: 0,
          borderRadius: const Radius.circular(25),
        ),
      ),
    );
  }
}