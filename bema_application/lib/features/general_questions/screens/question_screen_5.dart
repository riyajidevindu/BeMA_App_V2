import 'package:bema_application/common/widgets/tiles/option_tile.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestionScreen5 extends StatefulWidget {
  const QuestionScreen5({super.key});

  @override
  _QuestionScreen5State createState() => _QuestionScreen5State();
}

class _QuestionScreen5State extends State<QuestionScreen5> {
  String? _selectOccupation; // Stores the selected occupation
  final TextEditingController _occupationController = TextEditingController();
  bool _isTextFieldSelected = false;

  @override
  void dispose() {
    _occupationController.dispose();
    super.dispose();
  }

  // Method to check if continue button should be active
  bool get _isContinueButtonActive {
    return _selectOccupation != null || _occupationController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1;

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
                    context.goNamed(RouteNames.questionScreen4);
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
                    value: 0.24, // Progress (next step)
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
                        "What keeps you busy during the day?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      const Text(
                        "We'd love to know what you do for a living!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),

                      // Randomly placed emoji options using OptionTile
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20.0, // Spacing between the options
                        runSpacing: 20.0,
                        children: [
                          OptionTile(
                            emoji: "🧑‍⚕️",
                            label: "Doctor",
                            option: "doctor",
                            selectedOption: _selectOccupation,
                            emojiSize: emojiSize,
                            onSelect: () {
                              setState(() {
                                _selectOccupation = 'doctor';
                              });
                            },
                          ),
                          OptionTile(
                            emoji: "👨‍🏫",
                            label: "Teacher",
                            option: "teacher",
                            selectedOption: _selectOccupation,
                            emojiSize: emojiSize,
                            onSelect: () {
                              setState(() {
                                _selectOccupation = 'teacher';
                              });
                            },
                          ),
                          OptionTile(
                            emoji: "👨‍💻",
                            label: "Programmer",
                            option: "programmer",
                            selectedOption: _selectOccupation,
                            emojiSize: emojiSize,
                            onSelect: () {
                              setState(() {
                                _selectOccupation = 'programmer';
                              });
                            },
                          ),
                          OptionTile(
                            emoji: "👨‍🌾",
                            label: "Farmer",
                            option: "farmer",
                            selectedOption: _selectOccupation,
                            emojiSize: emojiSize,
                            onSelect: () {
                              setState(() {
                                _selectOccupation = 'farmer';
                              });
                            },
                          ),
                          OptionTile(
                            emoji: "🎓",
                            label: "Undergraduate",
                            option: "undergraduate",
                            selectedOption: _selectOccupation,
                            emojiSize: emojiSize,
                            onSelect: () {
                              setState(() {
                                _selectOccupation = 'undergraduate';
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.05),

                      const Text(
                        "Or anything else?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Text input field for other occupations
                      TextFormField(
                        controller: _occupationController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Enter your occupation',
                        ),
                        onChanged: (option) {
                          setState(() {
                            _isTextFieldSelected = option.isNotEmpty;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Continue button
                      ElevatedButton(
                        onPressed: _isContinueButtonActive
                            ? () {
                                context.goNamed(RouteNames.questionScreen6);
                              }
                            : null, // Disable button if neither emoji nor text is selected
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Blue button color
                          minimumSize: const Size(double.infinity, 50), // Full-width button
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
}
