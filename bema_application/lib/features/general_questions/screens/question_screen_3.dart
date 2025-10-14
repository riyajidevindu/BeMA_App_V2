import 'dart:ui';
import 'dart:math';
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

class _QuestionScreen3State extends State<QuestionScreen3>
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
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(_animationController);

    _colorAnimation2 = ColorTween(
      begin: Colors.purple,
      end: Colors.blue,
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
    final screenHight = MediaQuery.of(context).size.height;

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
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.scale(
                scale: screenWidth * 0.0032,
                child: Transform.rotate(
                  angle: 0,
                  child: Image.asset(
                    'assets/height_weight.png',
                    //fit: BoxFit.cover,
                    //color: Colors.black.withOpacity(0.1),
                    //colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () =>
                                context.goNamed(RouteNames.questionScreen2),
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
                                  value: 0.10,
                                  backgroundColor: Colors.transparent,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildStrokedText("Height & Weight", screenWidth * 0.08),
                      const SizedBox(height: 10),
                      Text(
                        "This helps us personalize your tips!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildMeasurementSection(
                        context,
                        "Height",
                        questionnaireProvider.heightValue ?? '170',
                        questionnaireProvider.heightUnit,
                        ['cm', 'ft', 'm'],
                        (unit) => questionnaireProvider.setHeightUnit(unit),
                        (value) => questionnaireProvider.setHeightValue(value),
                      ),
                      const SizedBox(height: 20),
                      _buildMeasurementSection(
                        context,
                        "Weight",
                        questionnaireProvider.weightValue ?? '60',
                        questionnaireProvider.weightUnit,
                        ['kg', 'lb'],
                        (unit) => questionnaireProvider.setWeightUnit(unit),
                        (value) => questionnaireProvider.setWeightValue(value),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: questionnaireProvider
                                .isHeightWeightContinueButtonActive
                            ? () => context.goNamed(RouteNames.questionScreen4)
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
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementSection(
    BuildContext context,
    String title,
    String value,
    String selectedUnit,
    List<String> units,
    Function(String) onUnitChanged,
    Function(String) onValueChanged,
  ) {
    double sliderValue = double.tryParse(value) ?? 0.0;
    double min = 0;
    double max = 250;
    int divisions = 250;

    if (title == "Height") {
      if (selectedUnit == 'ft') {
        max = 8.2;
        divisions = 82;
      }
      if (selectedUnit == 'm') {
        max = 2.5;
        divisions = 250;
      }
    } else {
      if (selectedUnit == 'lb') {
        max = 550;
        divisions = 550;
      }
    }

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
              _buildStrokedText(title, 20),
              const SizedBox(height: 10),
              _buildStrokedText(
                '$value $selectedUnit',
                32,
              ),
              Slider(
                value: sliderValue.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                label: value,
                onChanged: (newValue) {
                  onValueChanged(newValue.toStringAsFixed(1));
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: units.map((unit) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Text(unit),
                      selected: selectedUnit == unit,
                      onSelected: (isSelected) {
                        if (isSelected) {
                          onUnitChanged(unit);
                        }
                      },
                      backgroundColor: Colors.white.withOpacity(0.3),
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color:
                            selectedUnit == unit ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
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
