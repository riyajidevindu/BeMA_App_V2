import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/common/widgets/buttons/custom_elevation_buttons.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // For Google icon

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
              children: [
                SizedBox(height: screenHeight * 0.1), // Responsive spacing
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000), // textColor
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.05),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please confirm your password';
                  //   }
                  //   if (value != _passwordController.text) {
                  //     return 'Passwords do not match';
                  //   }
                  //   return null;
                  // },
                ),
                SizedBox(height: screenHeight * 0.02),


                CustomElevationBtn(
                  buttonName: 'Sign Up',
                  onClick: () async {
                    setState(() {
                      isSubmitting = true;
                    });
                    if (_passwordController.text != _confirmPasswordController.text) {
                      showErrorSnackBarMessage(context, 'Password does not match');
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      AuthResult result = await Provider.of<AuthenticationProvider>(
                        context, 
                        listen: false,
                      ).signUp(
                        name: _usernameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                        confirmPassword: _confirmPasswordController.text,
                      );

                      if (result.isSuccess) {
                        context.goNamed(RouteNames.userWelcomeScreen); // Redirect to questionnaire
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
                          color: Colors.black,
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

