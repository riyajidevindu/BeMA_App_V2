import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

void changeMode(BuildContext context) {
  final autProvider =
      Provider.of<AuthenticationProvider>(context, listen: false);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Wrapping the Container in Flexible ensures it doesn't overflow
        Flexible(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, primaryColor],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 15),
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/logo.png'),
                    ),
                    const SizedBox(width: 15), // Reduced for responsiveness
                    Text(
                      "BeMa",
                      style: TextStyle(
                        color: backgroundColor,
                        fontWeight: FontWeight.w500,
                        fontSize: width * 0.055, // Responsive text size
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (!context.mounted) return;
                        // context.push('/${RouteNames.notificationScreen}');
                      },
                      icon: Icon(
                        Icons.notifications,
                        color: backgroundColor,
                        size: width * 0.06, // Responsive icon size
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.settings,
                        color: backgroundColor,
                        size: width * 0.06, // Responsive icon size
                      ),
                      onSelected: (value) {
                        if (value == 'profile') {
                          // Navigate to the Profile screen
                          context.push('/${RouteNames.profileScreen}');
                        } else if (value == 'signOut') {
                          // Perform Sign Out
                          final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
                          authProvider.signOut();
                          // Navigate to the Sign-In screen or homepage
                          context.push('/${RouteNames.loginScreen}');
                        }
                        else if (value == 'chat') {
                          context.push('/${RouteNames.chatScreen}');
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: Text('Profile'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'signOut',
                            child: Text('Sign Out'),
                          ),
                             const PopupMenuItem<String>(
                            value: 'chat',
                            child: Text('Chat'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
