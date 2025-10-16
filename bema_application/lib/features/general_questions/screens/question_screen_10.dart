import 'dart:ui';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/routes/route_names.dart';

class QuestionScreen10 extends StatefulWidget {
  const QuestionScreen10({super.key});

  @override
  _QuestionScreen10State createState() => _QuestionScreen10State();
}

class _QuestionScreen10State extends State<QuestionScreen10>
    with SingleTickerProviderStateMixin {
  late TextEditingController _allergyController;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
    _allergyController = TextEditingController(
      text: context.read<QuestionnaireProvider>().allergiesDescription ?? '',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.lightBlue.shade200,
      end: Colors.purple.shade200,
    ).animate(_animationController);

    _colorAnimation2 = ColorTween(
      begin: Colors.purple.shade200,
      end: Colors.lightBlue.shade200,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_colorAnimation1.value!, _colorAnimation2.value!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () =>
                                      context.goNamed(RouteNames.questionScreen9),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: const LinearProgressIndicator(
                                        value: 0.45,
                                        backgroundColor: Colors.transparent,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            _buildStrokedText(
                                "Do you have any allergies?", screenWidth * 0.08),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildOptionChip(context, "Yes", true,
                                    questionnaireProvider.hasAllergies),
                                const SizedBox(width: 20),
                                _buildOptionChip(context, "No", false,
                                    questionnaireProvider.hasAllergies),
                              ],
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              '😝',
                              style: TextStyle(fontSize: 80),
                            ),
                            if (questionnaireProvider.hasAllergies == true)
                              _buildAllergyInput(context),
                          ],
                        ),
                        GestureDetector(
                          onTap: questionnaireProvider.isAllergiesContinueButtonActive
                              ? () => context.goNamed(RouteNames.questionScreen11)
                              : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.8),
                                  Colors.purple.withOpacity(0.8)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip(
      BuildContext context, String label, bool value, bool? currentValue) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    final bool isSelected = currentValue == value;

    Color backgroundColor;
    Color textColor;

    if (value) {
      // This is the "Yes" option
      backgroundColor =
          isSelected ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.7);
      textColor = isSelected ? Colors.white : Colors.black87;
    } else {
      // This is the "No" option
      backgroundColor = isSelected
          ? Colors.green.withOpacity(0.7)
          : Colors.white.withOpacity(0.7);
      textColor = isSelected ? Colors.white : Colors.black87;
    }

    return GestureDetector(
      onTap: () {
        questionnaireProvider.setHasAllergies(value);
      },
      child: Chip(
        label: Text(label),
        backgroundColor: backgroundColor,
        labelStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  Widget _buildAllergyInput(BuildContext context) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildStrokedText("Please describe your allergies", 20),
              const SizedBox(height: 20),
              TextFormField(
                controller: _allergyController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'e.g., Peanuts, Pollen, Dust Mites',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                onChanged: (value) {
                  questionnaireProvider.setAllergiesDescription(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrokedText(String text, double fontSize,
      {bool isSelected = true}) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
