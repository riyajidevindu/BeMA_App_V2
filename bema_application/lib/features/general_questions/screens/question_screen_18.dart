import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:bema_application/common/widgets/tiles/option_tile.dart';

class QuestionScreen18 extends StatefulWidget {
  const QuestionScreen18({super.key});

  @override
  _QuestionScreen18State createState() => _QuestionScreen18State();
}

class _QuestionScreen18State extends State<QuestionScreen18> {

  @override
  Widget build(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1; // Responsive emoji size

    // Smoking option
    final List<Map<String, String>> alcoholOptions = [
      {"label": "Just one", "emoji": "🍷", "option": "one"},
      {"label": "A couple", "emoji": "🥂", "option": "couple"},
      {"label": "More than a few", "emoji": "🍾", "option": "more_few"},
      {"label": "I lost count!", "emoji": "🍻", "option": "lost_count"},
    ];


    // Handle the selection and navigation logic
    void handleContinue() {
     
      context.goNamed(RouteNames.questionScreen19); // Navigate to the non-smoker page
      
    }

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
                GestureDetector(
                  onTap: () {
                    context.goNamed(RouteNames.questionScreen17);
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
                SizedBox(width: screenWidth * 0.025),

                // Progress bar
                const Expanded(
                  child: LinearProgressIndicator(
                    value: 0.85, // Adjust progress value as needed
                    backgroundColor: Colors.grey,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "When you drink, how many glasses do you typically have?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    const Text(
                      "🥃", // Cigarette emoji
                      style: TextStyle(fontSize: 50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Smoking options using OptionTile
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: screenWidth * 0.05, // Space between options
                      runSpacing: screenHeight * 0.02,
                      children: alcoholOptions.map((option) {
                        return SizedBox(
                          width: screenWidth * 0.4, // Fixed width for consistency
                          child: OptionTile(
                            emoji: option["emoji"]!,
                            label: option["label"]!,
                            option: option["option"]!,
                            selectedOption: questionnaireProvider.alcoholCount,
                            emojiSize: emojiSize,
                            onSelect: () {
                              // Update the smoking status in provider
                              questionnaireProvider.setAlcoholCount(option["option"]!);
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: screenHeight * 0.07),

                    // Continue button
                    ElevatedButton(
                      onPressed: questionnaireProvider.alcoholCount != null
                          ? handleContinue
                          : null, // Disable button if no option is selected
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
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
