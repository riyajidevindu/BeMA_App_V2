import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class QuestionScreen2 extends StatefulWidget {
  const QuestionScreen2({super.key});

  @override
  _QuestionScreen2State createState() => _QuestionScreen2State();
}

class _QuestionScreen2State extends State<QuestionScreen2> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _ageController = TextEditingController();
  String _formattedAge = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updateAge() {
    final age = int.tryParse(_ageController.text) ?? 0;
    if (age > 100) {
      // Show an error or prevent update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Age cannot be greater than 100.'),
        ),
      );
      _ageController.clear();
      setState(() {
        _formattedAge = '';
      });
    } else {
      setState(() {
        _formattedAge = age > 0 ? '$age years old' : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50), // Add padding to push content down
            const LinearProgressIndicator(
              value: 0.5, // 50% progress (adjust as needed)
              backgroundColor: Colors.grey,
              color: Colors.blue, // Blue progress
            ),
            const SizedBox(height: 30), // Padding after progress bar
            const Text(
              "How young are you?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Padding after heading
            TextFormField(
              controller: _ageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter your age',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Only allow digits
              ],
              onChanged: (value) {
                // Validate and format age
                _updateAge();
              },
            ),
            const SizedBox(height: 20), // Padding after input field
            if (_formattedAge.isNotEmpty) ...[
              Text(
                _formattedAge,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20), // Padding after formatted age
            ],
            const Text(
              "We'd love to know your age so we can better understand your journey!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40), // Padding after description
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("👶", style: TextStyle(fontSize: 40)), // Child emoji
                SizedBox(width: 20),
                Text("👨", style: TextStyle(fontSize: 40)), // Adult male emoji
                SizedBox(width: 20),
                Text("👴", style: TextStyle(fontSize: 40)), // Elderly man emoji
              ],
            ),
            const Spacer(), // Push button to the bottom
            ElevatedButton(
              onPressed: () {
                context.goNamed(RouteNames.questionScreen4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button color
                minimumSize:
                    const Size(double.infinity, 50), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20), // Padding after button
          ],
        ),
      ),
    );
  }
}
