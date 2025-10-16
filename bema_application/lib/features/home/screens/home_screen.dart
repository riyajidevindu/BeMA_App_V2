import 'dart:ui';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final profileService = ProfileService();
  String userName = 'User'; // Default name while loading
  String greetingMessage = 'Good Day'; // Default greeting
  bool isLoading = true; // Track loading state
  String formattedDate = ""; // To hold the formatted date
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/tasks.png'), context);
    precacheImage(const AssetImage('assets/relax.png'), context);
    precacheImage(const AssetImage('assets/score.png'), context);
  }

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
    getUser(); // Fetch user details when the screen loads
    _setGreetingMessage(); // Set the appropriate greeting message
    _setFormattedDate(); // Set the formatted date
  }

  /// Fetches the user profile data
  Future<void> getUser() async {
    try {
      UserModel? user =
          await profileService.getUser(FirebaseAuth.instance.currentUser!.uid);

      if (user != null && user.name.isNotEmpty) {
        setState(() {
          userName = user.name;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      setState(() {
        isLoading = false; // Set loading to false once data is fetched
      });
      _animationController.forward();
    }
  }

  /// Sets the greeting message based on the current time
  void _setGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greetingMessage = 'Good Morning';
    } else if (hour < 17) {
      greetingMessage = 'Good Afternoon';
    } else if (hour < 21) {
      greetingMessage = 'Good Evening';
    } else {
      greetingMessage = 'Good Night';
    }
  }

  /// Sets the formatted date based on the current date
  void _setFormattedDate() {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daySuffix = _getDaySuffix(
        dayOfMonth); // Get the correct day suffix (e.g., 1st, 2nd)
    final formattedDay = DateFormat('EEEE')
        .format(now); // Get the day of the week (e.g., Monday)

    setState(() {
      formattedDate = "$dayOfMonth$daySuffix $formattedDay";
    });
  }

  /// Helper function to determine the correct suffix for the day
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomAppBar(), // Custom AppBar from previous screen
        automaticallyImplyLeading: false, // Remove the back arrow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(0.1),
              alignment: FractionalOffset.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16.0), // Padding inside the box
                    margin: const EdgeInsets.only(
                        bottom: 20.0,
                        top: 20), // Space around the box if needed
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
                        AnimatedTextKit(
                          key: ValueKey<String>(userName),
                          animatedTexts: [
                            TypewriterAnimatedText(
                              "$greetingMessage, $userName!",
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Color.fromARGB(255, 3, 112, 3),
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Color.fromARGB(255, 235, 226, 132),
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              speed: const Duration(milliseconds: 100),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          isRepeatingAnimation: false,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formattedDate, // Dynamically set date here
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(179, 5, 19, 215),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                              backgroundImage: AssetImage('assets/tasks.png'),
                            ),
                            title: "Daily Task",
                            subtitle: "Your Health Guide",
                            color: Colors.lightBlueAccent,
                            onTap: () {
                              // Navigate to Daily Task tab (index 3)
                              context.push(
                                  '/${RouteNames.bottomNavigationBarScreen}',
                                  extra: 1);
                            },
                          ),
                          _buildCard(
                            avatar: const CircleAvatar(
                              radius: 35,
                              backgroundImage: AssetImage('assets/relax.png'),
                            ),
                            title: "Relax Section",
                            subtitle: "Relax Your Mind",
                            color: Colors.orange,
                            onTap: () {
                              // Navigate to Relax tab (index 1)
                              context.push(
                                  '/${RouteNames.bottomNavigationBarScreen}',
                                  extra: 2);
                            },
                          ),
                          _buildCard(
                            avatar: const CircleAvatar(
                              radius: 35,
                              backgroundImage: AssetImage('assets/score.png'),
                            ),
                            title: "Your Points",
                            subtitle: "Check Your Progress",
                            color: Colors.lightBlue,
                            onTap: () {
                              // Navigate to Points tab (index 4)
                              context.push(
                                  '/${RouteNames.bottomNavigationBarScreen}',
                                  extra: 3);
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
    required Widget avatar, // Accepts any widget (e.g., CircleAvatar)
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap, // onTap can be null if not provided
  }) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {});
      },
      onExit: (event) {
        setState(() {});
      },
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
              onTap: onTap, // Trigger the onTap function if tapped
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
                      avatar, // Display the passed widget (CircleAvatar in this case)
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
                          color: Color.fromARGB(179, 255, 255, 255),
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
