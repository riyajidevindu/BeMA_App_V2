import 'package:bema_application/common/widgets/tiles/option_tile.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestionScreen4 extends StatefulWidget {
  const QuestionScreen4({super.key});

  @override
  _QuestionScreen4State createState() => _QuestionScreen4State();
}

class _QuestionScreen4State extends State<QuestionScreen4> {
  String? _selectedGender; // Stores the selected option

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.05; // 5% of screen width for padding
    final emojiSize = screenWidth * 0.12; // 12% of screen width for emoji size
    final spacing = screenHeight * 0.03; // 3% of screen height for spacing

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Padding(
        padding: EdgeInsets.all(padding), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.05), // 5% of screen height padding to push content down
            const LinearProgressIndicator(
              value: 0.18, // 75% progress
              backgroundColor: Colors.grey,
              color: Colors.blue, // Blue progress
            ),
            SizedBox(height: screenHeight * 0.03), // Responsive padding after progress bar
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
            SizedBox(height: spacing), // Responsive padding after heading
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
            SizedBox(height: screenHeight * 0.05), // 5% of screen height padding after description

            // Gender options using OptionTile widget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OptionTile(
                  emoji: "👨",
                  label: "I'm male",
                  option: 'male',
                  selectedOption: _selectedGender,
                  emojiSize: emojiSize,
                  onSelect: () {
                    setState(() {
                      _selectedGender = 'male';
                    });
                  },
                ),
                OptionTile(
                  emoji: "👩",
                  label: "I'm female",
                  option: 'female',
                  selectedOption: _selectedGender,
                  emojiSize: emojiSize,
                  onSelect: () {
                    setState(() {
                      _selectedGender = 'female';
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: spacing), // Responsive padding between rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OptionTile(
                  emoji: "🧑",
                  label: "I'm non-binary",
                  option: 'non-binary',
                  selectedOption: _selectedGender,
                  emojiSize: emojiSize,
                  onSelect: () {
                    setState(() {
                      _selectedGender = 'non-binary';
                    });
                  },
                ),
                OptionTile(
                  emoji: "❓",
                  label: "Prefer not to say",
                  option: 'prefer-not',
                  selectedOption: _selectedGender,
                  emojiSize: emojiSize,
                  onSelect: () {
                    setState(() {
                      _selectedGender = 'prefer-not';
                    });
                  },
                ),
              ],
            ),
            const Spacer(), // Push button to the bottom
            ElevatedButton(
              onPressed: _selectedGender != null
                  ? () {
                      context.goNamed(RouteNames.questionScreen5);
                    }
                  : null, // Disable button if no option selected
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button color
                minimumSize: Size(double.infinity, screenHeight * 0.07), // Responsive button height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Padding after button
          ],
        ),
      ),
    );
  }

  // Helper method to create option option widgets with a border
  Widget _genderOption(String emoji, String label, String option, double emojiSize) {
    bool isSelected = _selectedGender == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = option; // Set selected option
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black, // Black border color
                width: isSelected ? 4 : 2, // Thicker border if selected
              ),
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            child: Opacity(
              opacity: isSelected || _selectedGender == null ? 1.0 : 0.3, // Blur unselected
              child: Text(
                emoji,
                style: TextStyle(fontSize: emojiSize), // Responsive emoji size
              ),
            ),
          ),
          SizedBox(height: 10), // Fixed spacing between emoji and label
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
