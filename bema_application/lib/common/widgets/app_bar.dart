import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatefulWidget {
  final bool? showBackButton;

  const CustomAppBar({super.key, this.showBackButton});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF26C6DA)], // Gradient effect
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // Rounded corners for entire AppBar
      ),
      height: 60, // Consistent height
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to the home tab in the bottom navigation bar
              context.goNamed(RouteNames.bottomNavigationBarScreen, extra: 0);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/logo.png'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "BeMA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.06, // Responsive font size
                      ),
                    ),
                  ],
                ),
                if (widget.showBackButton == true)
                  Positioned(
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: width * 0.06,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Handle notification button press
                },
                icon: Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: width * 0.06,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
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
    );
  }

  // Function to build each popup menu item with custom styling
  Widget _buildPopupMenuItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}