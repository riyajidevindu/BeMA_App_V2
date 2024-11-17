import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/buttons/custom_elevation_buttons.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/authentication/data/service/auth_service.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // For Google icon

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final auth = AuthenticationProvider();
  final state = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      final result = await auth.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (result.isSuccess) {
        bool isQuestionnaireCompleted =
            await state.checkQuestionnaireCompletion(auth.firebaseUser!);

        if (isQuestionnaireCompleted) {
          context.goNamed(RouteNames.homeScreen); // Redirect to home if questionnaire is completed
        } else {
          context.goNamed(RouteNames.userWelcomeScreen); // Redirect to questionnaire
        }

        showSuccessSnackBarMessage(context, result.message);
      } else {
        showErrorSnackBarMessage(context, result.message);
      }
    }

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2FF),
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.05), // Adjusted for responsiveness

          // Logo and Login Text (Fixed elements)
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png', // Ensure this path is correct
                  height: screenHeight * 0.25, // Responsive logo size
                ),
                SizedBox(height: screenHeight * 0.02), // Spacing after the logo

                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Dark text color
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02), // Slightly reduce the space
              ],
            ),
          ),

          // Scrollable part (Email, Password, Button, etc.)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.02,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: Colors.grey[600]), // Add email icon
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.grey),
                          fillColor: const Color(0xFFFFFFFF),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // More rounded corners
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: Colors.grey[600]), // Add password icon
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.grey),
                          fillColor: const Color(0xFFFFFFFF),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // More rounded corners
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Custom Elevated Button
                      CustomElevationBtn(
                        buttonName: 'Login',
                        onClick: _login,
                        isSubmitting: isSubmitting,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'If you don\'t have an account ',
                            style: TextStyle(color: secondaryTextColor, fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.goNamed(RouteNames.registerScreen);
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.blue, // Accent color for the clickable text
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Forgot your password? ',
                            style: TextStyle(color: secondaryTextColor, fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Add functionality to reset password
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.blue, // Accent color for clickable text
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.04), // More spacing at the end
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
