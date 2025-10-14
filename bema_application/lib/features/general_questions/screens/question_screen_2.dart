import 'dart:ui';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QuestionScreen2 extends StatefulWidget {
  const QuestionScreen2({super.key});

  @override
  _QuestionScreen2State createState() => _QuestionScreen2State();
}

class _QuestionScreen2State extends State<QuestionScreen2>
    with SingleTickerProviderStateMixin {
  late int _age;
  late FixedExtentScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
    _age = Provider.of<QuestionnaireProvider>(context, listen: false).age ?? 25;
    _scrollController = FixedExtentScrollController(initialItem: _age - 1);

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
    _scrollController.dispose();
    super.dispose();
  }

  void _updateAge(int newAge) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    setState(() {
      _age = newAge;
    });
    questionnaireProvider.setAge(newAge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenHeight = constraints.maxHeight;
          final double screenWidth = constraints.maxWidth;

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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            context.goNamed(RouteNames.userWelcomeScreen);
                          },
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
                                value: 0.05,
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
                        "🎂 How young are you?", screenWidth * 0.08),
                    const SizedBox(height: 10),
                    Text(
                      "This helps us tailor your journey!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 35.0),
                        child: Image.asset(
                          'assets/age_asking.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    _buildAgePicker(),
                    const Spacer(flex: 2),
                    GestureDetector(
                      onTap: () {
                        context.goNamed(RouteNames.questionScreen3);
                      },
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
    );
  }

  Widget _buildAgePicker() {
    return SizedBox(
      height: 150,
      child: RotatedBox(
        quarterTurns: -1,
        child: ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: 80,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            _updateAge(index + 1);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: 100,
            builder: (context, index) {
              final isSelected = index + 1 == _age;
              return RotatedBox(
                quarterTurns: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  child: _buildStrokedText(
                    '${index + 1}',
                    isSelected ? 60 : 42,
                    isSelected: isSelected,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStrokedText(String text, double fontSize,
      {bool isSelected = true}) {
    return Stack(
      children: <Widget>[
        // Stroked text as border.
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        // Solid text as fill.
        Text(
          text,
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
