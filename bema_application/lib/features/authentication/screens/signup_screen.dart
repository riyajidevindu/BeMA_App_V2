import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  // For managing loading state during sign-up
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }
  // For managing form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  // Simulate sign-up logic
  void _signup() async {

    setState(() {
      _isLoading = true;
    });
    
    if (_formKey.currentState!.validate()) {
     
      if (_passwordController.text != _confirmPasswordController.text) {
        showErrorSnackBarMessage(
            context, 'Password does not match');
        return;
      }

      AuthResult result = await Provider.of<AuthenticationProvider>
      (context,listen:false)
        .signUp(
          name: _usernameController.text, 
          email: _emailController.text, 
          password: _passwordController.text, 
          confirmPassword: _confirmPasswordController.text
        );

      if (result.isSuccess) {
        //context.goNamed(RouteNames.wrapper);
        showSuccessSnackBarMessage(context, result.message);
      } else {
        showErrorSnackBarMessage(context, result.message);
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Simulate Google sign-up logic
  void _googleSignup() async {
    // Add your Google sign-up logic here (e.g., Firebase Google authentication)
    showSuccessSnackBarMessage(context, 'Google Sign-up Successful');
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2FF), // backgroundColor
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,  // Responsive padding
            vertical: screenHeight * 0.02,
          ),
          child: Form(
            key: _formKey, // Form key for validation
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: screenHeight * 0.02),

                // Sign-up Button with Loading Indicator
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup, // Disable button if loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0098FF), // primaryColor
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // Google Sign-up Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _googleSignup, // Disable button if loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Sign up with Google',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // Add space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
