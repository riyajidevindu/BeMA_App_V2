import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
                    const SizedBox(width: 15),
                    Text(
                      "BeMA",
                      style: TextStyle(
                        color: backgroundColor,
                        fontWeight: FontWeight.w500,
                        fontSize: width * 0.055,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle notification button press
                      },
                      icon: Icon(
                        Icons.notifications,
                        color: backgroundColor,
                        size: width * 0.06,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.settings,
                        color: backgroundColor,
                        size: width * 0.06,
                      ),
                      onSelected: (value) {
                        if (value == 'profile') {
                          context.push('/${RouteNames.profileScreen}');
                        } else if (value == 'signOut') {
                          final authProvider =
                              Provider.of<AuthenticationProvider>(context, listen: false);
                          authProvider.signOut();
                          context.push('/${RouteNames.loginScreen}');
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: _buildPopupMenuItem(
                              icon: Icons.person,
                              text: 'Profile',
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'signOut',
                            child: _buildPopupMenuItem(
                              icon: Icons.exit_to_app,
                              text: 'Sign Out',
                            ),
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

  // Function to build each popup menu item with custom styling
  Widget _buildPopupMenuItem({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white, // Light background
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // Shadow effect
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Offset for shadow
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor), // Icon with custom color
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
