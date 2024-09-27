import 'package:bema_application/common/widgets/buttons/custom_elevation_buttons.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2FF),
      body: SingleChildScrollView(
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
                SizedBox(height: screenHeight * 0.04), // Responsive spacing

                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo.png', // Make sure this path is correct
                    height: screenHeight * 0.2, // Logo size
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // Spacing after logo

                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000), // Text color
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.person, color: Colors.grey[600]), // Add icon
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // More rounded
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.email, color: Colors.grey[600]), // Add icon
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.lock, color: Colors.grey[600]), // Add icon
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                SizedBox(height: screenHeight * 0.02),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.lock, color: Colors.grey[600]), // Add icon
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.04),

                // Custom Button
                CustomElevationBtn(
                  buttonName: 'Sign Up',
                  onClick: () async {
                    setState(() {
                      isSubmitting = true;
                    });
                    if (_formKey.currentState!.validate()) {
                      AuthResult result =
                          await Provider.of<AuthenticationProvider>(
                        context,
                        listen: false,
                      ).signUp(
                        name: _usernameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                        confirmPassword: _confirmPasswordController.text,
                      );

                      if (result.isSuccess) {
                        context.goNamed(RouteNames
                            .userWelcomeScreen); // Redirect to questionnaire
                        showSuccessSnackBarMessage(context, result.message);
                      } else {
                        showErrorSnackBarMessage(context, result.message);
                      }
                    }

                    setState(() {
                      isSubmitting = false;
                    });
                  },
                  isSubmitting: isSubmitting,
                ),

                SizedBox(height: screenHeight * 0.02),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.goNamed(RouteNames.loginScreen);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.blue, // Make the link stand out
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
