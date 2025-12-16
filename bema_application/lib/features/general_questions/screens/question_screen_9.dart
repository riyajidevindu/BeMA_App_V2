import 'dart:ui';
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

class _QuestionScreen9State extends State<QuestionScreen9>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedBuilder(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () =>
                          context.goNamed(RouteNames.questionScreen8),
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
                            value: 0.40,
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
                    "Do you have high cholesterol?", screenWidth * 0.08),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOptionChip(context, "Yes", true,
                        questionnaireProvider.hasCholesterol),
                    const SizedBox(width: 20),
                    _buildOptionChip(context, "No", false,
                        questionnaireProvider.hasCholesterol),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  '🙃',
                  style: TextStyle(fontSize: 80),
                ),
                const Spacer(),
                if (questionnaireProvider.hasCholesterol == true)
                  _buildDurationPicker(context),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: questionnaireProvider.isCholesterolContinueButtonActive
                      ? () => context.goNamed(RouteNames.questionScreen10)
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
        questionnaireProvider.setHasCholesterol(value);
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

  Widget _buildDurationPicker(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);
    int duration =
        int.tryParse(questionnaireProvider.cholesterolDuration ?? '0') ?? 0;

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
              _buildStrokedText("Medication Duration (Years)", 20),
              const SizedBox(height: 10),
              _buildStrokedText(
                duration.toString(),
                48,
              ),
              Slider(
                value: duration.toDouble(),
                min: 0,
                max: 50,
                divisions: 50,
                label: duration.toString(),
                onChanged: (newValue) {
                  questionnaireProvider
                      .setCholesterolDuration(newValue.round().toString());
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.5),
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
