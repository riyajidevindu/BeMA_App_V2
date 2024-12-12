import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final profileService = ProfileService();
  String userName = 'User'; // Default name while loading
  String greetingMessage = 'Good Day'; // Default greeting
  bool isLoading = true; // Track loading state
  String formattedDate = ""; // To hold the formatted date

  @override
  void initState() {
    super.initState();
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
    final daySuffix = _getDaySuffix(dayOfMonth); // Get the correct day suffix (e.g., 1st, 2nd)
    final formattedDay = DateFormat('EEEE').format(now); // Get the day of the week (e.g., Monday)

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
      backgroundColor: backgroundColor, // Use background color from theme
      appBar: AppBar(
        backgroundColor: backgroundColor, // Consistent background color
        title: const CustomAppBar(), // Custom AppBar from previous screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0), // Padding inside the box
              margin: const EdgeInsets.only(
                  bottom: 20.0, top: 20), // Space around the box if needed
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 26, 201, 213), // Background color of the box
                borderRadius: BorderRadius.circular(12), // Rounded corners
                border: Border.all(
                    color: Colors.grey.shade300), // Border around the box
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$greetingMessage, $userName!",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 1, 34, 75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formattedDate, // Dynamically set date here
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 253, 251, 251),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
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
                      context.goNamed(RouteNames.bottomNavigationBarScreen, extra: 3);
                    },
                  ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/mood.png'),
                    ),
                    title: "Mood Friend",
                    subtitle: "Fix You Mood",
                    color: Colors.orangeAccent,
                    onTap: () {
                      // Navigate to Mood tab (index 2)
                      context.goNamed(RouteNames.moodFriendScreen);
                    },
                  ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/relax.png'),
                    ),
                    title: "Breath Relaxer",
                    subtitle: "Relax Your Mind",
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to Relax tab (index 1)
                      context.goNamed(RouteNames.bottomNavigationBarScreen, extra: 1);
                    },
                  ),
                  _buildCard(
                  avatar: const CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('assets/chat.png'),
                  ),
                  title: "Chat with Me",
                  subtitle: "Ask Your Problem",
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    // Navigate to Daily Task tab (index 3)
                    context.goNamed(RouteNames.bottomNavigationBarScreen, extra: 2);
                  },
                ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/score.png'),
                    ),
                    title: "Your Points",
                    subtitle: "Check me",
                    color: Colors.lightBlue,
                    onTap: () {
                      // Navigate to Points tab (index 4)
                      context.goNamed(RouteNames.bottomNavigationBarScreen, extra: 4);
                    },
                  ),
                  _buildCard(
                    avatar: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/exersize.png'),
                    ),
                    title: "Workout Plans",
                    subtitle: "Practice with",
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to Points tab (index 5)
                      context.goNamed(RouteNames.bottomNavigationBarScreen,extra: 5);
                    },
                  ),
                ],
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
    return GestureDetector(
      onTap: onTap, // Trigger the onTap function if tapped
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              avatar, // Display the passed widget (CircleAvatar in this case)
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
