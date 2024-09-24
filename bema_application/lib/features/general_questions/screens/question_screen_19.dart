import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:bema_application/common/widgets/tiles/option_tile.dart';

class QuestionScreen19 extends StatefulWidget {
  const QuestionScreen19({super.key});

  @override
  _QuestionScreen19State createState() => _QuestionScreen19State();
}

class _QuestionScreen19State extends State<QuestionScreen19> {

  @override
  Widget build(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1; // Responsive emoji size

    final List<Map<String, String>> exerciseOptions = [
      {"label": "Not very active", "emoji": "🛋️", "option": "inactive"},
      {"label": "I exercise a few times a week", "emoji": "🏋️", "option": "few_times_week"},
      {"label": "I try to move a bit each day", "emoji": "🚶", "option": "daily_movement"},
      {"label": "I'm super active", "emoji": "🏃", "option": "super_active"},
    ];

    // Handle the selection and navigation logic
    void handleContinue() {
     
      if (questionnaireProvider.activeness == "inactive") {
        context.goNamed(RouteNames.thankYouScreen); 
      } else {
        context.goNamed(RouteNames.questionScreen20); 
      }
      
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
                    value: 0.90, // Adjust progress value as needed
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
                      "Let's talk about exercise,",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "How active are you on a daily basis?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    const Text(
                      "🏃‍♂️", // Cigarette emoji
                      style: TextStyle(fontSize: 50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Smoking options using OptionTile
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: screenWidth * 0.05, // Space between options
                      runSpacing: screenHeight * 0.02,
                      children: exerciseOptions.map((option) {
                        return SizedBox(
                          width: screenWidth * 0.4, // Fixed width for consistency
                          child: OptionTile(
                            emoji: option["emoji"]!,
                            label: option["label"]!,
                            option: option["option"]!,
                            selectedOption: questionnaireProvider.activeness,
                            emojiSize: emojiSize,
                            onSelect: () {
                              // Update the smoking status in provider
                              questionnaireProvider.setActiveness(option["option"]!);
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: screenHeight * 0.07),

                    // Continue button
                    ElevatedButton(
                      onPressed: questionnaireProvider.activeness != null
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
