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
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomAppBar(),
        automaticallyImplyLeading: true,
        elevation: 0,
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
                    22,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Choose an option to relax",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(179, 6, 42, 141),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        children: [
                          _buildCard(
                            avatar: const CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  AssetImage('assets/relax.png'),
                            ),
                            title: "Breath Relaxer",
                            subtitle: "Relax Your Mind",
                            color: Colors.orange,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.stressReleaseScreen);
                            },
                          ),
                          _buildCard(
                            avatar: const CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  AssetImage('assets/meditation.png'),
                            ),
                            title: "Dive Reflex",
                            subtitle: "Relax Your Heart",
                            color: Colors.lightBlue,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.diveReflexScreen);
                            },
                          ),
                          _buildCard(
                            avatar: const CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  AssetImage('assets/chat.png'),
                            ),
                            title: "Chat with Me",
                            subtitle: "Ask Your Problem",
                            color: Colors.lightBlueAccent,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, RouteNames.chatScreen);
                            },
                          ),
                          _buildCard(
                            avatar: const CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  AssetImage('assets/mood.png'),
                            ),
                            title: "Mood Friend",
                            subtitle: "Fix You Mood",
                            color: Colors.orangeAccent,
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
    required Widget avatar,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
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
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      avatar,
                      const SizedBox(height: 5),
                      _buildStrokedText(
                        title,
                        18,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
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
