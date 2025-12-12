import 'dart:ui';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_screen.dart';
import 'package:bema_application/features/authentication/screens/mood_screen/mood_friend.dart';
import 'package:bema_application/features/dive_reflex/screens/dive_reflex_screen.dart';
import 'package:bema_application/features/instant_stress_release/screens/instant_stress_release_screen.dart';
import 'package:flutter/material.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';

class RelaxSectionScreen extends StatelessWidget {
  const RelaxSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        Widget page = const RelaxSectionHome();
        if (settings.name == RouteNames.stressReleaseScreen) {
          page = const StressReleaseScreen();
        } else if (settings.name == RouteNames.chatScreen) {
          page = const ChatScreen();
        } else if (settings.name == RouteNames.moodFriendScreen) {
          page = const MoodFriend();
        } else if (settings.name == RouteNames.diveReflexScreen) {
          page = const DiveReflexScreen();
        }
        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }
}

class RelaxSectionHome extends StatefulWidget {
  const RelaxSectionHome({Key? key}) : super(key: key);

  @override
  State<RelaxSectionHome> createState() => _RelaxSectionHomeState();
}

class _RelaxSectionHomeState extends State<RelaxSectionHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(_animationController);
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/relax.png'), context);
    precacheImage(const AssetImage('assets/meditation.png'), context);
    precacheImage(const AssetImage('assets/chat.png'), context);
    precacheImage(const AssetImage('assets/mood.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Responsive calculations
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    // Responsive sizes
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final headerPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final headerTitleSize = (screenWidth * 0.055).clamp(18.0, 26.0);
    final headerSubtitleSize = (screenWidth * 0.042).clamp(14.0, 20.0);
    final gridSpacing = (screenWidth * 0.04).clamp(12.0, 20.0);
    final avatarRadius = (screenWidth * 0.09).clamp(28.0, 45.0);
    final cardSpacing = (screenWidth * 0.012).clamp(4.0, 8.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomAppBar(),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(headerPadding),
              margin: EdgeInsets.only(bottom: gridSpacing, top: gridSpacing),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStrokedText(
                    "Relax Section",
                    headerTitleSize,
                  ),
                  SizedBox(height: cardSpacing),
                  Text(
                    "Choose an option to relax",
                    style: TextStyle(
                      fontSize: headerSubtitleSize,
                      color: const Color.fromARGB(179, 6, 42, 141),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gridSpacing),
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: gridSpacing,
                        childAspectRatio:
                            isSmallScreen ? 0.85 : (isMediumScreen ? 0.9 : 1.0),
                        children: [
                          _buildCard(
                            avatarRadius: avatarRadius,
                            avatarImage: 'assets/relax.png',
                            title: "Breath Relaxer",
                            subtitle: "Relax Your Mind",
                            color: Colors.orange,
                            screenWidth: screenWidth,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.stressReleaseScreen);
                            },
                          ),
                          _buildCard(
                            avatarRadius: avatarRadius,
                            avatarImage: 'assets/meditation.png',
                            title: "Dive Reflex",
                            subtitle: "Relax Your Heart",
                            color: Colors.lightBlue,
                            screenWidth: screenWidth,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.diveReflexScreen);
                            },
                          ),
                          _buildCard(
                            avatarRadius: avatarRadius,
                            avatarImage: 'assets/chat.png',
                            title: "Chat with Me",
                            subtitle: "Ask Your Problem",
                            color: Colors.lightBlueAccent,
                            screenWidth: screenWidth,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.chatScreen);
                            },
                          ),
                          _buildCard(
                            avatarRadius: avatarRadius,
                            avatarImage: 'assets/mood.png',
                            title: "Mood Friend",
                            subtitle: "Fix You Mood",
                            color: Colors.orangeAccent,
                            screenWidth: screenWidth,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.moodFriendScreen);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required double avatarRadius,
    required String avatarImage,
    required String title,
    required String subtitle,
    required Color color,
    required double screenWidth,
    VoidCallback? onTap,
  }) {
    // Responsive sizes based on screen width
    final titleSize = (screenWidth * 0.045).clamp(14.0, 20.0);
    final subtitleSize = (screenWidth * 0.035).clamp(11.0, 16.0);
    final cardPadding = (screenWidth * 0.02).clamp(6.0, 12.0);
    final spacing = (screenWidth * 0.012).clamp(4.0, 8.0);

    return MouseRegion(
      onEnter: (event) {},
      onExit: (event) {},
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(0.1),
        alignment: FractionalOffset.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: AssetImage(avatarImage),
                      ),
                      SizedBox(height: spacing),
                      _buildStrokedText(
                        title,
                        titleSize,
                      ),
                      SizedBox(height: spacing * 1.5),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokedText(String text, double fontSize,
      {bool isSelected = true}) {
    return Stack(
      children: <Widget>[
        // Stroked text as border.
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        // Solid text as fill.
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
