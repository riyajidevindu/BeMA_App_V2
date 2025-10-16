import 'dart:ui';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/routes/route_names.dart';

class QuestionScreen17 extends StatefulWidget {
  const QuestionScreen17({super.key});

  @override
  _QuestionScreen17State createState() => _QuestionScreen17State();
}

class _QuestionScreen17State extends State<QuestionScreen17>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  final List<Map<String, String>> alcoholOptions = [
    {"label": "No, I don't drink", "emoji": "🚫", "option": "no_alcohol"},
    {"label": "Used to, but not anymore", "emoji": "🍾", "option": "used_to_alcohol"},
    {"label": "Yes, occasionally", "emoji": "🥂", "option": "occasionally_alcohol"},
    {"label": "Yes, quite frequently", "emoji": "🍻", "option": "frequently_alcohol"},
  ];

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

  void handleContinue() {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    if (questionnaireProvider.alcoholStatus == "no_alcohol") {
      context.goNamed(RouteNames.questionScreen19);
    } else {
      context.goNamed(RouteNames.questionScreen18);
    }
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
                          context.goNamed(RouteNames.questionScreen15),
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
                            value: 0.80,
                            backgroundColor: Colors.transparent,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildStrokedText("How about alcohol?", screenWidth * 0.08),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: alcoholOptions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final option = alcoholOptions[index];
                      return _buildAlcoholOption(
                        context,
                        option["emoji"]!,
                        option["label"]!,
                        option["option"]!,
                        questionnaireProvider.alcoholStatus,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  '🙈',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: questionnaireProvider.alcoholStatus != null
                      ? handleContinue
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

  Widget _buildAlcoholOption(
    BuildContext context,
    String emoji,
    String label,
    String option,
    String? selectedOption,
  ) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    final bool isSelected = selectedOption == option;

    return GestureDetector(
      onTap: () {
        questionnaireProvider.setAlcoholStatus(option);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected
                    ? Colors.blue.shade700
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
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
