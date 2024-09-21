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
    final emojiSize = screenWidth * 0.12; // 12% of screen width for emoji size
   
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Column(
        children: [
          const SizedBox(height: 50),
          
          // Row for Back button and Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Back button inside a transparent circle
                GestureDetector(
                  onTap: () {
                    context.goNamed(RouteNames.questionScreen2);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2), // Transparent background
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white, // White arrow color
                    ),
                  ),
                ),

                SizedBox(width: screenWidth * 0.025), // Space between back button and progress bar

                // Progress bar with increased width
                const Expanded(
                  child: LinearProgressIndicator(
                    value: 0.18, // Progress (next step)
                    backgroundColor: Colors.grey,
                    color: Colors.blue, // Progress bar color
                    //minHeight: 8, // Slightly increase the height of the progress bar
                  ),
                ),
              ],
            ),
          ),

            Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    SizedBox(height: screenHeight * 0.03),
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
                    SizedBox(height: screenHeight * 0.05), 

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
                    SizedBox(height: screenHeight * 0.04),
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
                    SizedBox(height: screenHeight * 0.05),
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
                  ],
                ),
              ),
            ),
          ),

        ],

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
