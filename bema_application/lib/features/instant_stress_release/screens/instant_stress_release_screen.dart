import 'package:flutter/material.dart';
import 'dart:async';

class StressReleaseScreen extends StatefulWidget {
  const StressReleaseScreen({Key? key}) : super(key: key);

  @override
  State<StressReleaseScreen> createState() => _StressReleaseScreenState();
}

class _StressReleaseScreenState extends State<StressReleaseScreen>
    with TickerProviderStateMixin {
  late AnimationController _inhaleController;
  late AnimationController _exhaleController;
  late Animation<double> _inhaleAnimation;
  late Animation<double> _exhaleAnimation;

  int currentCycle = 0;
  int maxCycles = 10;
  String statusText = "Start to Relax";

  @override
  void initState() {
    super.initState();

    _inhaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _exhaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _inhaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _inhaleController, curve: Curves.easeInOut),
    );

    _exhaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _exhaleController, curve: Curves.easeInOut),
    );
  }

  void _startBreathingCycle() async {
    for (int i = 0; i < maxCycles; i++) {
      setState(() {
        currentCycle = i + 1;
        statusText = "Inhale...";
      });

      await _inhaleController.forward();
      setState(() {
        statusText = "Hold...";
      });
      await Future.delayed(const Duration(seconds: 2)); // Holding the breath

      setState(() {
        statusText = "Exhale...";
      });
      await _exhaleController.forward();

      _inhaleController.reset();
      _exhaleController.reset();
    }
  }

  @override
  void dispose() {
    _inhaleController.dispose();
    _exhaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant Stress Release'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _inhaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _inhaleController.isAnimating
                        ? _inhaleAnimation.value
                        : _exhaleAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withOpacity(0.6),
                      ),
                      child: Center(
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Text(
            'Cycle: $currentCycle / $maxCycles',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _startBreathingCycle(),
            child: const Text('Start Breathing'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: const CircleBorder()
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
