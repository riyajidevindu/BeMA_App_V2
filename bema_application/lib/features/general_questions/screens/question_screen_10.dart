import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';

class QuestionScreen10 extends StatefulWidget {
  const QuestionScreen10({super.key});

  @override
  _QuestionScreen10State createState() => _QuestionScreen10State();
}

class _QuestionScreen10State extends State<QuestionScreen10> {
  bool? _hasAllergies; // Tracks user's allergies response (true, false, or null)
  final TextEditingController _allergyController = TextEditingController();

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  // Method to check if continue button should be active
  bool get _isContinueButtonActive {
    if (_hasAllergies == null) {
      return false;
    } else if (_hasAllergies == true) {
      return _allergyController.text.isNotEmpty;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1; // Responsive emoji size

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Same light blue background
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
                    context.goNamed(RouteNames.questionScreen9);
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
                    value: 0.54, // Progress (next step)
                    backgroundColor: Colors.grey,
                    color: Colors.blue, // Progress bar color
                    //minHeight: 8, // Slightly increase the height of the progress bar
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content below the progress bar
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Do you have any",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "allergies?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Emoji buttons for Yes and No options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasAllergies = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(_hasAllergies == true ? 1.0 : 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "✅",
                              style: TextStyle(
                                fontSize: emojiSize,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.15),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasAllergies = false;
                              _allergyController.clear(); // Clear the input if No is selected
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(_hasAllergies == false ? 1.0 : 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "❌",
                              style: TextStyle(
                                fontSize: emojiSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.05), // Padding after options

                    const Text(
                      "If yes, could you share what",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const Text(
                      "they are?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Use allergy emoji
                    Text(
                      "🤧", 
                      style: TextStyle(fontSize: emojiSize * 1.5),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    TextFormField(
                      controller: _allergyController,
                      keyboardType: TextInputType.text,
                      enabled: _hasAllergies == true, // Active only if Yes is selected
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Specify your allergies',
                      ),
                      onChanged: (value) {
                        setState(() {
                          // State is updated whenever input changes
                        });
                      },
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Continue button
                    ElevatedButton(
                      onPressed: _isContinueButtonActive
                          ? () {
                              //context.goNamed(RouteNames.questionScreen11);
                            }
                          : null, // Disable button if conditions are not met
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
                    const SizedBox(height: 20), // Padding after button
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
