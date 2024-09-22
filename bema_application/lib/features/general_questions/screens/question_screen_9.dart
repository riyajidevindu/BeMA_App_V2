import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/routes/route_names.dart';

class QuestionScreen9 extends StatefulWidget {
  const QuestionScreen9({super.key});

  @override
  _QuestionScreen9State createState() => _QuestionScreen9State();
}

class _QuestionScreen9State extends State<QuestionScreen9> {
  late TextEditingController _yearsController;

  @override
  void initState() {
    super.initState();
    final questionnaireProvider = context.read<QuestionnaireProvider>();
    // Initialize the controller with the value from the provider
    _yearsController = TextEditingController(
      text: questionnaireProvider.cholesterolDuration ?? '',
    );
  }

  @override
  void dispose() {
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.1; // Responsive emoji size

    // Access the QuestionnaireProvider
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Same light blue background
      body: Column(
        children: [
          const SizedBox(height: 50),
          // Fixed progress bar at the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Back button inside a transparent circle
                GestureDetector(
                  onTap: () {
                    context.goNamed(RouteNames.questionScreen8);
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
                    value: 0.48, // Progress (next step)
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
                      "Do you have high",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "cholesterol?",
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
                            questionnaireProvider.setHasCholesterol(true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(questionnaireProvider.hasCholesterol == true ? 1.0 : 0.3),
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
                            questionnaireProvider.setHasCholesterol(false);
                            _yearsController.clear(); // Clear the text field when selecting No
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(questionnaireProvider.hasCholesterol == false ? 1.0 : 0.3),
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
                      "If yes, how long have you been on medication?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const Text(
                      "(In years)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Text(
                      "💊",
                      style: TextStyle(fontSize: emojiSize * 1.5),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    TextFormField(
                      controller: _yearsController,
                      keyboardType: TextInputType.number,
                      enabled: questionnaireProvider.hasCholesterol == true, // Active only if Yes is selected
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'In Years',
                      ),
                      onChanged: (value) {
                        questionnaireProvider.setCholesterolDuration(value);
                      },
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Continue button
                    ElevatedButton(
                      onPressed: questionnaireProvider.isCholesterolContinueButtonActive
                          ? () {
                              context.goNamed(RouteNames.questionScreen10);
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
