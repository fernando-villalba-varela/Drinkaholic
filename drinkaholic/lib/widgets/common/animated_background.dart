import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Duration duration;
  final bool isActive;

  const AnimatedBackground({super.key, this.duration = const Duration(seconds: 20), this.isActive = true});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(painter: _FloatingShapesPainter(_animation.value));
        },
      ),
    );
  }
}

class _FloatingShapesPainter extends CustomPainter {
  final double animationValue;

  _FloatingShapesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final shapes = [
      _FloatingShape(
        Offset(
          size.width * 0.1 + (sin(animationValue * 2 * pi) * 30),
          size.height * 0.2 + (cos(animationValue * 2 * pi) * 20),
        ),
        30,
        const Color(0x0DFFFFFF),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.8 + (sin(animationValue * 2 * pi + 1) * 40),
          size.height * 0.7 + (cos(animationValue * 2 * pi + 1) * 30),
        ),
        25,
        const Color(0x14FFFFFF),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.3 + (sin(animationValue * 2 * pi + 2) * 50),
          size.height * 0.5 + (cos(animationValue * 2 * pi + 2) * 25),
        ),
        20,
        const Color(0x0AFFFFFF),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.7 + (sin(animationValue * 2 * pi + 3) * 35),
          size.height * 0.3 + (cos(animationValue * 2 * pi + 3) * 40),
        ),
        18,
        const Color(0x0D00BCD4),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.5 + (sin(animationValue * 2 * pi + 4) * 60),
          size.height * 0.8 + (cos(animationValue * 2 * pi + 4) * 15),
        ),
        12,
        const Color(0x08FFFFFF),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.9 + (sin(animationValue * 2 * pi + 5) * 25),
          size.height * 0.1 + (cos(animationValue * 2 * pi + 5) * 35),
        ),
        15,
        const Color(0x0D4CAF50),
      ),
    ];

    for (final shape in shapes) {
      paint.color = shape.color;
      canvas.drawCircle(shape.position, shape.radius, paint);
    }

    final trianglePaint = Paint()
      ..color = const Color(0x05FFFFFF)
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
  bool shouldRepaint(_FloatingShapesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _FloatingShape {
  final Offset position;
  final double radius;
  final Color color;

  _FloatingShape(this.position, this.radius, this.color);
}
