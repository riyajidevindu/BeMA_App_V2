import 'package:flutter/material.dart';
import 'dart:math';

class ThinkingCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Colors.lightBlueAccent],
        stops: [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ModernSoundWavePainter extends CustomPainter {
  final double animationValue;

  ModernSoundWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0098FF), Color(0xFF00C6FF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midHeight = size.height / 2;
    final barCount = 20;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;

      // Create varied wave heights based on position and animation
      final heightMultiplier =
          sin((i / barCount * 2 * pi) + animationValue * 2 * pi);
      final barHeight =
          (midHeight * 0.8 * (0.3 + heightMultiplier.abs())).abs();

      // Draw vertical bars
      final path = Path();
      path.moveTo(x, midHeight - barHeight);
      path.lineTo(x, midHeight + barHeight);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// New painter for particle effects during thinking
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final int particleCount;

  ParticlesPainter(this.animationValue, {this.particleCount = 30});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final distance = size.width * 0.3 * animationValue;
      final x = size.width / 2 + cos(angle) * distance;
      final y = size.height / 2 + sin(angle) * distance;

      final opacity = 1.0 - animationValue;
      paint.color = const Color(0xFF0098FF).withOpacity(opacity * 0.6);

      final particleSize = 4 * (1 - animationValue);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
