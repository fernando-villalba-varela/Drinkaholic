import 'package:flutter/material.dart';

class FloatingParticle extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final int index;

  const FloatingParticle({super.key, required this.screenWidth, required this.screenHeight, required this.index});

  @override
  Widget build(BuildContext context) {
    final random = (index * 1234) % 1000;
    final size = 4.0 + (random % 8);
    final left = (random * 0.7) % screenWidth;
    final top = (random * 0.8) % screenHeight;
    final opacity = 0.1 + (random % 40) / 100;

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 3000 + (random % 2000)),
        tween: Tween<double>(begin: 0, end: 1),
        onEnd: () {
          // Restart animation - handled automatically by TweenAnimationBuilder
        },
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -value * 50),
            child: Opacity(
              opacity: opacity * (1 - value),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0x99FFFFFF), // white with 0.6 opacity
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x4DFFFFFF), // white with 0.3 opacity
                      blurRadius: 4,
                      spreadRadius: 1,
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
}
