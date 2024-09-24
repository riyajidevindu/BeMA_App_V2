import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:go_router/go_router.dart';

class QuestionScreen3 extends StatefulWidget {
  const QuestionScreen3({super.key});

  @override
  _QuestionScreen3State createState() => _QuestionScreen3State();
}

class _QuestionScreen3State extends State<QuestionScreen3> {
  late TextEditingController _heightController ;
  late TextEditingController _weightController ;

  @override
  void initState() {
    super.initState();
    final questionnaireProvider = context.read<QuestionnaireProvider>();
    _heightController = TextEditingController(
      text: questionnaireProvider.heightValue ?? '',
    );
    _weightController = TextEditingController(
      text: questionnaireProvider.weightValue ?? '',
    );
  }


  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the QuestionnaireProvider
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context, listen: true);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      body: Column(
        children: [
          const SizedBox(height: 50),
          
          // Progress bar at the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [

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
                SizedBox(width: screenWidth * 0.025), 

                const Expanded(
                  child: LinearProgressIndicator(
                    value: 0.10, // Progress value
                    backgroundColor: Colors.grey,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "What is your height?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "📏", // Height emoji
                      style: TextStyle(fontSize: 50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Height input field
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter your height in ${questionnaireProvider.heightUnit}',
                        suffixText: questionnaireProvider.heightUnit,
                      ),
                      onChanged: (value) {
                        questionnaireProvider.setHeightValue(value);
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Measurement unit buttons for height
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUnitButton(context, 'ft', questionnaireProvider.heightUnit == 'ft', () {
                          questionnaireProvider.setHeightUnit('ft');
                        }),
                        SizedBox(width: screenWidth * 0.05),
                        _buildUnitButton(context, 'cm', questionnaireProvider.heightUnit == 'cm', () {
                          questionnaireProvider.setHeightUnit('cm');
                        }),
                        SizedBox(width: screenWidth * 0.05),
                        _buildUnitButton(context, 'm', questionnaireProvider.heightUnit == 'm', () {
                          questionnaireProvider.setHeightUnit('m');
                        }),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Height hint text
                    const Text(
                      "Just to get an idea of how tall you stand!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    const Text(
                      "And how much do you weigh?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "⚖️", // Weight emoji
                      style: TextStyle(fontSize: 50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Weight input field
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter your weight in ${questionnaireProvider.weightUnit}',
                        suffixText: questionnaireProvider.weightUnit,
                      ),
                      onChanged: (value) {
                        questionnaireProvider.setWeightValue(value);
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Measurement unit buttons for weight
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUnitButton(context, 'lb', questionnaireProvider.weightUnit == 'lb', () {
                          questionnaireProvider.setWeightUnit('lb');
                        }),
                        SizedBox(width: screenWidth * 0.05),
                        _buildUnitButton(context, 'kg', questionnaireProvider.weightUnit == 'kg', () {
                          questionnaireProvider.setWeightUnit('kg');
                        }),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Weight hint text
                    const Text(
                      "This helps us to give you more personalized tips!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Continue button
                    ElevatedButton(
                      onPressed: questionnaireProvider.isHeightWeightContinueButtonActive
                          ? () {
                              context.goNamed(RouteNames.questionScreen4);
                            }
                          : null, // Disable button if both inputs are not valid
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for unit selection buttons
  Widget _buildUnitButton(BuildContext context, String unit, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          unit,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
