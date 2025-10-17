import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class StressReleaseScreen extends StatefulWidget {
  const StressReleaseScreen({Key? key}) : super(key: key);

  @override
  State<StressReleaseScreen> createState() => _StressReleaseScreenState();
}

class _StressReleaseScreenState extends State<StressReleaseScreen>
    with TickerProviderStateMixin {
  late AnimationController _inhaleController;
  late AnimationController _holdController;
  late AnimationController _exhaleController;
  late AnimationController
      _heartbeatController; // Heartbeat animation controller
  late Animation<double> _inhaleAnimation;
  late Animation<double> _exhaleAnimation;
  late Animation<double> _heartbeatAnimation; // Heartbeat scaling animation

  double currentProgress = 0.0;
  int currentCycle = 0;
  int selectedCycleCount = 10; // Default number of cycles (user-adjustable)
  String statusText = "🌿\nStart to Relax"; // Initial status with emoji
  bool relaxationComplete = false; // Track when relaxation is complete

  final int inhaleDuration = 4; // seconds
  final int holdDuration = 2; // seconds
  final int exhaleDuration = 6; // seconds
  late int totalCycleDuration;

  @override
  void initState() {
    super.initState();

    // Total duration of one complete cycle (inhale + hold + exhale)
    totalCycleDuration = inhaleDuration + holdDuration + exhaleDuration;

    // Initialize inhale controller
    _inhaleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: inhaleDuration),
    )..addListener(() {
        setState(() {
          // Cumulative progress bar during inhale phase
          currentProgress = ((currentCycle * totalCycleDuration) +
                  (_inhaleController.value * inhaleDuration)) /
              (totalCycleDuration * selectedCycleCount);
        });
      });

    // Initialize hold controller
    _holdController = AnimationController(
      vsync: this,
      duration: Duration(seconds: holdDuration),
    )..addListener(() {
        setState(() {
          // Cumulative progress bar during hold phase
          currentProgress = ((currentCycle * totalCycleDuration) +
                  (inhaleDuration + (_holdController.value * holdDuration))) /
              (totalCycleDuration * selectedCycleCount);
        });
      });

    // Initialize exhale controller
    _exhaleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: exhaleDuration),
    )..addListener(() {
        setState(() {
          // Cumulative progress bar during exhale phase
          currentProgress = ((currentCycle * totalCycleDuration) +
                  (inhaleDuration +
                      holdDuration +
                      (_exhaleController.value * exhaleDuration))) /
              (totalCycleDuration * selectedCycleCount);
        });
      });

    _inhaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _inhaleController, curve: Curves.easeInOut),
    );

    _exhaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _exhaleController, curve: Curves.easeInOut),
    );

    // Heartbeat controller for the rhythmic pulsation after relaxation
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 2000), // 1 second for a full heartbeat cycle
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _heartbeatController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _heartbeatController.forward();
        }
      });

    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );
  }

  // Start the breathing cycle
  void _startBreathingCycle() async {
    setState(() {
      relaxationComplete = false;
    });

    for (int i = 0; i < selectedCycleCount; i++) {
      setState(() {
        currentCycle = i;
        statusText = "🌬️\nInhale..."; // Use emoji for inhale
      });

      // Inhale for the specified duration
      await _inhaleController.forward();

      setState(() {
        statusText = "⏳\nHold..."; // Use emoji for hold
      });

      // Hold for the specified duration
      await _holdController.forward();

      setState(() {
        statusText = "💨\nExhale..."; // Use emoji for exhale
      });

      // Exhale for the specified duration
      await _exhaleController.forward();

      // Reset controllers for the next cycle, but NOT progress
      _inhaleController.reset();
      _holdController.reset();
      _exhaleController.reset();
    }

    // After the last cycle, start the heartbeat animation
    setState(() {
      currentProgress = 1.0; // Fully completed progress
      statusText = "🎉\nExercise Complete"; // Emoji for completion
      relaxationComplete = true; // Mark relaxation as complete
      _heartbeatController.forward(); // Start the heartbeat animation
    });
  }

  // Increment cycle count (up to a maximum)
  void _incrementCycleCount() {
    setState(() {
      if (selectedCycleCount < 20) {
        // Set a reasonable max limit
        selectedCycleCount++;
      }
    });
  }

  // Decrement cycle count (down to a minimum of 1)
  void _decrementCycleCount() {
    setState(() {
      if (selectedCycleCount > 1) {
        selectedCycleCount--;
      }
    });
  }

  @override
  void dispose() {
    _inhaleController.dispose();
    _holdController.dispose();
    _exhaleController.dispose();
    _heartbeatController.dispose(); // Dispose the heartbeat controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using MediaQuery to calculate screen height and width for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add a "Breath Relaxer" heading
          Padding(
            padding: EdgeInsets.only(
                top: screenHeight * 0.02), // Reduced padding to reduce the gap
            child: Text(
              'Breath Relaxer',
              style: TextStyle(
                fontSize: screenWidth * 0.08, // Responsive text size
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: relaxationComplete
                    ? _heartbeatController
                    : _inhaleController,
                builder: (context, child) {
                  // Scale the circle based on the current phase (inhale, hold, exhale) or heartbeat animation
                  double circleScale;
                  if (relaxationComplete) {
                    // Use the heartbeat animation when relaxation is complete
                    circleScale = _heartbeatAnimation.value;
                  } else {
                    // Normal inhale/exhale animation during the cycle
                    circleScale = (_inhaleController.isAnimating ||
                            _holdController.isAnimating)
                        ? _inhaleAnimation.value
                        : _exhaleAnimation.value;
                  }

                  // Ensure that the initial and final scale stays consistent
                  double finalScale =
                      (currentCycle < selectedCycleCount || relaxationComplete)
                          ? circleScale
                          : 1.0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular Progress Indicator wrapping the expanding circle
                      Transform.scale(
                        scale:
                            finalScale, // Scale the circle and progress bar together
                        child: SizedBox(
                          width: screenWidth *
                              0.5, // Responsive size for the circle
                          height: screenWidth * 0.5,
                          child: CircularProgressIndicator(
                            value:
                                currentProgress, // Continuous progress across stages
                            strokeWidth:
                                screenWidth * 0.03, // Responsive stroke width
                            backgroundColor: Colors.grey[300],
                            color: Colors.blueAccent, // Visible progress color
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: finalScale, // Match the scaling of the circle
                        child: Container(
                          width: screenWidth * 0.4,
                          height: screenWidth * 0.4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Colors.blueAccent, Colors.purpleAccent],
                              center: Alignment.center,
                              radius: 0.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              statusText, // Display the status with emoji and text
                              textAlign: TextAlign
                                  .center, // Center the text inside the circle
                              style: TextStyle(
                                fontSize:
                                    screenWidth * 0.06, // Responsive text size
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Display the current cycle count with "+" and "-" buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _decrementCycleCount,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding:
                      EdgeInsets.all(screenWidth * 0.04), // Responsive padding
                  backgroundColor: Colors.redAccent,
                  shadowColor: Colors.red,
                ),
                child: Icon(Icons.remove,
                    color: Colors.white, size: screenWidth * 0.08),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  '$selectedCycleCount Cycles', // Display the selected cycle count
                  style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: _incrementCycleCount,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding:
                      EdgeInsets.all(screenWidth * 0.04), // Responsive padding
                  backgroundColor: Colors.greenAccent,
                  shadowColor: Colors.green,
                ),
                child: Icon(Icons.add,
                    color: Colors.white, size: screenWidth * 0.08),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.02), // Reduced spacing

          // Enhanced Start Button
          Padding(
            padding: EdgeInsets.only(
                bottom: screenHeight *
                    0.10), // Added bottom padding to keep it above navbar
            child: ElevatedButton(
              onPressed: () => _startBreathingCycle(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.25,
                    vertical: screenHeight * 0.025),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.blueAccent, // Button background color
                shadowColor: Colors.blue, // Shadow color for effect
                elevation: 10, // Give the button a raised look
              ),
              child: Text(
                'Start Breathing',
                style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
