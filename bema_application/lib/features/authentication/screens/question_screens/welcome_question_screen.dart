import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/common/widgets/buttons/custom_elevation_buttons.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class UserWelcomeScreen extends StatefulWidget {
  const UserWelcomeScreen({super.key});

  @override
  State<UserWelcomeScreen> createState() => _UserWelcomeScreenState();
}

class _UserWelcomeScreenState extends State<UserWelcomeScreen> {
  final profileService = ProfileService();
  String userName = '';
  bool isLoading = true;  // Track loading state

  @override
  void initState() {
    super.initState();
    getUser();  // Fetch user details when the screen loads
  }

  Future<void> getUser() async {
    UserModel? user =
        await profileService.getUser(FirebaseAuth.instance.currentUser!.uid);

    // Debug the fetched user details
    debugPrint('Fetched user: ${user?.name}');

    if (user != null && user.name.isNotEmpty) {
      setState(() {
        userName = user.name;
        isLoading = false;  // Set loading to false once name is fetched
      });
    } else {
      setState(() {
        userName = 'User';  // Set a default name if none is available
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const CircularProgressIndicator()  // Display loader while fetching data
              else
                Text(
                  "👋 Hi, $userName!",  // Display userName
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              const Text(
                "Tell us about you!",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              const Text(
                "Let's become friends 😜",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // Handle next action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
