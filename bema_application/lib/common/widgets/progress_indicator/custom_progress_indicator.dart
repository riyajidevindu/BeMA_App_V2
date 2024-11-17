import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatefulWidget {
  final String logoPath;

  const CustomProgressIndicator({
    Key? key,
    this.logoPath = 'assets/logo.png',
  }) : super(key: key);

  @override
  _CustomProgressIndicatorState createState() =>
      _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waterFillAnimation;
  bool _isVisible = false;

  final List<String> _messages = [
    "Please hold on...",
    "Almost there...",
    "Thanks for your patience!",
    "Loading, just a moment..."
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _waterFillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _startMessageTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });
  }

  void _startMessageTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _messages.length;
      });
      _startMessageTimer();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.35;

    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
        ),
        // Centered logo with circular water fill effect and animated waves
        Center(
          child: AnimatedScale(
            scale: _isVisible ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular water fill within the logo
                SizedBox(
                  width: size,
                  height: size,
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Display the logo
                        CircleAvatar(
                          radius: size * 0.5,
                          backgroundImage: AssetImage(widget.logoPath),
                          backgroundColor: Colors.transparent,
                        ),
                        // Circular water fill overlay with waves
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _waterFillAnimation,
                            builder: (context, child) {
                              return ClipPath(
                                clipper: WaveClipper(_waterFillAnimation.value),
                                child: Container(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Text message below the logo
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _messages[_currentMessageIndex],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;

  WaveClipper(this.animationValue);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double waveHeight = size.height * 0.05; // Adjust wave height
    final double frequency = 2 * pi / size.width; // Frequency of wave oscillations

    // Start from the bottom left corner of the circular area
    path.moveTo(0, size.height);

    // Loop through the width and create sine waves for the top edge of the water
    for (double x = 0; x <= size.width; x++) {
      double y = size.height * (1 - animationValue) +
          waveHeight * sin(x * frequency + animationValue * 2 * pi);
      path.lineTo(x, y);
    }

    // Close the path from the end to the bottom right corner
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) {
    return oldClipper.animationValue != animationValue;
  }
}
