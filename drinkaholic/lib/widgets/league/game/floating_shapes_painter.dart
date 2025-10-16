import 'package:flutter/material.dart';
import 'dart:math';

class FloatingShapesPainter extends CustomPainter {
  final double animationValue;

  FloatingShapesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create multiple floating shapes with different speeds and sizes
    final shapes = [
      // Large circles
      _FloatingShape(
        Offset(
          size.width * 0.1 + (sin(animationValue * 2 * pi) * 30),
          size.height * 0.2 + (cos(animationValue * 2 * pi) * 20),
        ),
        30,
        Colors.white.withOpacity(0.05),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.8 + (sin(animationValue * 2 * pi + 1) * 40),
          size.height * 0.7 + (cos(animationValue * 2 * pi + 1) * 30),
        ),
        25,
        Colors.white.withOpacity(0.08),
      ),
      // Medium circles
      _FloatingShape(
        Offset(
          size.width * 0.3 + (sin(animationValue * 2 * pi + 2) * 50),
          size.height * 0.5 + (cos(animationValue * 2 * pi + 2) * 25),
        ),
        20,
        Colors.white.withOpacity(0.04),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.7 + (sin(animationValue * 2 * pi + 3) * 35),
          size.height * 0.3 + (cos(animationValue * 2 * pi + 3) * 40),
        ),
        18,
        Colors.cyan.withOpacity(0.06),
      ),
      // Small circles
      _FloatingShape(
        Offset(
          size.width * 0.5 + (sin(animationValue * 2 * pi + 4) * 60),
          size.height * 0.8 + (cos(animationValue * 2 * pi + 4) * 15),
        ),
        12,
        Colors.white.withOpacity(0.03),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.9 + (sin(animationValue * 2 * pi + 5) * 25),
          size.height * 0.1 + (cos(animationValue * 2 * pi + 5) * 35),
        ),
        15,
        Colors.green.withOpacity(0.05),
      ),
    ];

    // Draw all shapes
    for (final shape in shapes) {
      paint.color = shape.color;
      canvas.drawCircle(shape.position, shape.radius, paint);
    }

    // Add some triangular shapes for variety
    final trianglePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final trianglePath = Path();
    final triangleCenter = Offset(
      size.width * 0.6 + (sin(animationValue * 2 * pi + 6) * 45),
      size.height * 0.4 + (cos(animationValue * 2 * pi + 6) * 30),
    );

    trianglePath.moveTo(triangleCenter.dx, triangleCenter.dy - 15);
    trianglePath.lineTo(triangleCenter.dx - 13, triangleCenter.dy + 10);
    trianglePath.lineTo(triangleCenter.dx + 13, triangleCenter.dy + 10);
    trianglePath.close();

    canvas.drawPath(trianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(FloatingShapesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _FloatingShape {
  final Offset position;
  final double radius;
  final Color color;

  _FloatingShape(this.position, this.radius, this.color);
}
