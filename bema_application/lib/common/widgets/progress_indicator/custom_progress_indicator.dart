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
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Delay to show progress indicator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive size scaling
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
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
        // Centered progress indicator
        Center(
          child: AnimatedScale(
            scale: _isVisible ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 500),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating circular progress indicator
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * 3.141592653589793,
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: _ModernCircularPainter(
                            gradientColors: [
                              Colors.blueAccent,
                              Colors.blueAccent.shade200,
                              Colors.blueAccent.withOpacity(0.5),
                            ],
                            strokeWidth: size * 0.08, // Increased width
                          ),
                        ),
                      );
                    },
                  ),
                  // Center logo
                  CircleAvatar(
                    radius: size * 0.30, // Increased logo size
                    backgroundImage: AssetImage(widget.logoPath),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for modern circular progress
class _ModernCircularPainter extends CustomPainter {
  final List<Color> gradientColors;
  final double strokeWidth;

  _ModernCircularPainter({
    required this.gradientColors,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: 0.0,
        endAngle: 2 * 3.141592653589793,
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius - strokeWidth / 2),
      -3.14 / 2,
      2 * 3.14 * 0.75, // 75% progress arc
      false,
      paint,
    );

    // Add shadow for a 3D effect
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius - strokeWidth / 2),
      -3.14 / 2,
      2 * 3.14 * 0.75, // 75% progress arc
      false,
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
