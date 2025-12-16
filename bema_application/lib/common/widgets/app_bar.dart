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
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive calculations based on screen width
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    // Responsive sizes
    final appBarHeight = isSmallScreen ? 50.0 : (isMediumScreen ? 56.0 : 64.0);
    final horizontalPadding =
        isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 16.0);
    final logoRadius = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
    final logoTextSize =
        isSmallScreen ? 16.0 : (isMediumScreen ? screenWidth * 0.05 : 24.0);
    final iconSize =
        isSmallScreen ? 20.0 : (isMediumScreen ? screenWidth * 0.055 : 26.0);
    final backButtonRadius =
        isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
    final spacing = isSmallScreen ? 6.0 : (isMediumScreen ? 10.0 : 14.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF26C6DA)], // Gradient effect
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(12), // Rounded corners for entire AppBar
      ),
      height: appBarHeight,
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
                    CircleAvatar(
                      radius: logoRadius,
                      backgroundImage: const AssetImage('assets/logo.png'),
                    ),
                    SizedBox(width: spacing),
                    Text(
                      "BeMA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: logoTextSize,
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
                        radius: backButtonRadius,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: iconSize,
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
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                constraints: BoxConstraints(
                  minWidth: isSmallScreen ? 32 : 40,
                  minHeight: isSmallScreen ? 32 : 40,
                ),
                onPressed: () {
                  // Handle notification button press
                },
                icon: Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              PopupMenuButton<String>(
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: iconSize,
                ),
                onSelected: (value) {
                  if (value == 'profile') {
                    context.push('/${RouteNames.profileScreen}');
                  } else if (value == 'signOut') {
                    final authProvider = Provider.of<AuthenticationProvider>(
                        context,
                        listen: false);
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
                        screenWidth: screenWidth,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'signOut',
                      child: _buildPopupMenuItem(
                        icon: Icons.exit_to_app,
                        text: 'Sign Out',
                        screenWidth: screenWidth,
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
  Widget _buildPopupMenuItem({
    required IconData icon,
    required String text,
    required double screenWidth,
  }) {
    final isSmallScreen = screenWidth < 360;
    final iconSize = isSmallScreen ? 18.0 : 24.0;
    final fontSize = isSmallScreen ? 13.0 : 14.0;

    return Row(
      children: [
        Icon(icon, color: primaryColor, size: iconSize),
        SizedBox(width: isSmallScreen ? 8 : 10),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
