import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QuestionScreen11 extends StatefulWidget {
  const QuestionScreen11({super.key});

  @override
  _QuestionScreen11State createState() => _QuestionScreen11State();
}

class _QuestionScreen11State extends State<QuestionScreen11> {
  late TextEditingController _surgeryYearController;
  late TextEditingController _surgeryTypeController;

  @override
  void initState() {
    super.initState();
    final questionnaireProvider = context.read<QuestionnaireProvider>();
    _surgeryYearController = TextEditingController(
      text: questionnaireProvider.surgeryYear ?? '',
    );
    _surgeryTypeController = TextEditingController(
      text: questionnaireProvider.surgeryType ?? '',
    );
  }

  @override
  void dispose() {
    _surgeryYearController.dispose();
    _surgeryTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1;

    // Access the QuestionnaireProvider
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: true);

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
                    context.goNamed(RouteNames.questionScreen10);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black
                          .withOpacity(0.2), // Transparent background
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white, // White arrow color
                    ),
                  ),
                ),
                SizedBox(
                    width: screenWidth *
                        0.025), // Space between back button and progress bar

                // Progress bar with increased width
                const Expanded(
                  child: LinearProgressIndicator(
                    value: 0.60, // Progress (next step)
                    backgroundColor: Colors.grey,
                    color: Colors.blue, // Progress bar color
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
                      "Have you had any surgeries?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "🏥", // X-ray emoji
                      style: TextStyle(fontSize: 50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Surgery Yes/No buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            questionnaireProvider.setHasSurgeries(true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(
                                  questionnaireProvider.hasSurgeries == true
                                      ? 1.0
                                      : 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "✅",
                              style: TextStyle(
                                fontSize: emojiSize
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.15),
                        GestureDetector(
                          onTap: () {
                            questionnaireProvider.setHasSurgeries(false);
                            _surgeryYearController
                                .clear(); // Clear the text fields when "No" is selected
                            _surgeryTypeController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(
                                  questionnaireProvider.hasSurgeries == false
                                      ? 1.0
                                      : 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "❌",
                              style: TextStyle(
                                fontSize: emojiSize
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: screenHeight * 0.05), // Padding after options

                    // Hint text and input for surgery year
                    const Text(
                      "If yes, when? (In years)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _surgeryYearController,
                      keyboardType: TextInputType.number,
                      enabled: questionnaireProvider.hasSurgeries == true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter the year of surgery',
                      ),
                      onChanged: (value) {
                        questionnaireProvider.setSurgeryYear(value);
                      },
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Hint text and input for surgery type
                    const Text(
                      "and what kind?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _surgeryTypeController,
                      keyboardType: TextInputType.text,
                      enabled: questionnaireProvider.hasSurgeries == true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter the type of surgery',
                      ),
                      onChanged: (value) {
                        questionnaireProvider.setSurgeryType(value);
                      },
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Continue button
                    ElevatedButton(
                      onPressed: questionnaireProvider
                              .isSurgeriesContinueButtonActive
                          ? () {
                              //context.goNamed(RouteNames.questionScreen12);
                            }
                          : null, // Disable button if conditions are not met
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Blue button color
                        minimumSize: const Size(
                            double.infinity, 50), // Full-width button
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
