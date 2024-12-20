import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class StartRelaxScreen extends StatefulWidget {
  const StartRelaxScreen({Key? key}) : super(key: key);

  @override
  _StartRelaxScreenState createState() => _StartRelaxScreenState();
}

class _StartRelaxScreenState extends State<StartRelaxScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  Timer? _timer;
  int _seconds = 0;
  bool _isTimerRunning = false;

  final List<Map<String, String>> steps = [
    {
      "heading": "Prepare Cold Water",
      "content": "Fill a bowl with cold water and add ice cubes. If unavailable, grab an ice pack or wet cloth.",
      "gif": "assets/ice-box.gif"
    },
    {
      "heading": "Find a Calm Spot",
      "content": "Sit comfortably in a safe and quiet place.",
      "gif": "assets/chair.gif"
    },
    {
      "heading": "Take a Deep Breath",
      "content": "Inhale deeply to prepare yourself for the exercise.",
      "gif": "assets/breath.gif"
    },
    {
      "heading": "Apply the Cold",
      "content": "Submerge your face in the cold water for 10–30 seconds. If using an ice pack, press it gently on your forehead and nose.",
      "gif": "assets/man.gif"
    },
    {
      "heading": "Breathe and Relax",
      "content": "Focus on slow, deep breaths while applying the cold. Feel your stress melt away.",
      "gif": "assets/relax.gif"
    },
    {
      "heading": "Repeat if Needed",
      "content": "If stress persists, repeat the process up to 2–3 times.",
      "gif": "assets/repeat.png"
    },
  ];

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
        child: Center(
          child: Container(
            width: screenWidth * 0.9,
            height: screenHeight * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                    if (_currentStep == 3) {
                      _stopTimer();
                      _seconds = 0;
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          step['heading']!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          height: screenHeight * 0.3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            child: Image.asset(
                              step['gif']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          step['content']!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            color: Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (index == 3) ...[
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "Time in water: $_seconds s",
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          ElevatedButton(
                            onPressed: _isTimerRunning ? _stopTimer : _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isTimerRunning ? Colors.redAccent : Colors.blueAccent,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1,
                                vertical: screenHeight * 0.02,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              _isTimerRunning ? "Stop Timer" : "Start Timer",
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentStep < steps.length - 1) {
            setState(() {
              _currentStep++;
            });
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            setState(() {
              _currentStep = 0;
              _pageController.jumpToPage(0);
            });
          }
        },
        backgroundColor:Colors.blueGrey.withOpacity(0.4),
        elevation: 0,
        child: const Icon(Icons.arrow_forward, color: Colors.blueAccent),
      ),
    );
  }
}