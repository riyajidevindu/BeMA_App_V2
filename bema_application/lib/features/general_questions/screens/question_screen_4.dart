import 'package:flutter/material.dart';

class QuestionScreen4 extends StatefulWidget {
  const QuestionScreen4({super.key});

  @override
  _QuestionScreen4State createState() => _QuestionScreen4State();
}

class _QuestionScreen4State extends State<QuestionScreen4> {
  String? _selectedGender; // Stores the selected gender

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
              value: 0.75, // 75% progress
              backgroundColor: Colors.grey,
              color: Colors.blue, // Blue progress
            ),
            const SizedBox(height: 30), // Padding after progress bar
            const Text(
              "What's your ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "gender identity?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Padding after heading
            const Text(
              "Just so we know how to",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Text(
              "address you properly!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40), // Padding after description
            // Gender options using emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _genderOption("👨", "I'm male", 'male'),
                _genderOption("👩", "I'm female", 'female'),
              ],
            ),
            const SizedBox(height: 20), // Padding between rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _genderOption("🧑", "I'm non-binary", 'non-binary'),
                _genderOption("❓", "Prefer not to say", 'prefer-not'),
              ],
            ),
            const Spacer(), // Push button to the bottom
            ElevatedButton(
              onPressed: _selectedGender != null
                  ? () {
                      // Navigate to the next screen
                    }
                  : null, // Disable button if no gender selected
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

  // Helper method to create gender option widgets
  Widget _genderOption(String emoji, String label, String gender) {
    bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender; // Set selected gender
        });
      },
      child: Column(
        children: [
          Opacity(
            opacity: isSelected || _selectedGender == null
                ? 1.0
                : 0.3, // Blur unselected
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 50), // Emoji size
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
