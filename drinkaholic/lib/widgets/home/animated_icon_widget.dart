import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedIconWidget extends StatelessWidget {
  final IconData? animatingIcon;
  final AnimationController animationController;
  final Animation<double> opacityAnimation;
  final Animation<double> iconMoveAnimation;
  final Animation<double> iconScaleAnimation;
  final Animation<double> iconRotationAnimation;

  const AnimatedIconWidget({
    super.key,
    required this.animatingIcon,
    required this.animationController,
    required this.opacityAnimation,
    required this.iconMoveAnimation,
    required this.iconScaleAnimation,
    required this.iconRotationAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (animatingIcon == null) return const SizedBox.shrink();

    // Different animations based on icon type
    if (animatingIcon == Icons.flash_on) {
      // Rocket launch animation - moves up with trail effect
      return AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Rocket trail effect
              if (iconMoveAnimation.value < -50)
                ...List.generate(5, (index) {
                  final opacity = (1 - (index * 0.2)) * opacityAnimation.value;
                  final trailOffset = iconMoveAnimation.value + (index * 30);
                  return Transform.translate(
                    offset: Offset(0, trailOffset),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Icon(Icons.circle, size: 8 - (index * 1.5), color: Colors.white),
                    ),
                  );
                }),
              // Main rocket icon
              Transform.translate(
                offset: Offset(0, iconMoveAnimation.value),
                child: Transform.scale(
                  scale: iconScaleAnimation.value,
                  child: Transform.rotate(
                    angle: (iconRotationAnimation.value * 3.14159) / 180,
                    child: Icon(animatingIcon, size: 80, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (animatingIcon == Icons.emoji_events) {
      // Trophy bounce and glow animation
      return AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 120 * iconScaleAnimation.value,
                height: 120 * iconScaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(((0.6 * opacityAnimation.value) * 255).round(), 255, 235, 59),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Floating sparkles around trophy
              ...List.generate(8, (index) {
                final angle = (index * 45) + (iconRotationAnimation.value * 2);
                final distance = 60 + (10 * iconScaleAnimation.value);
                final x = distance * cos(angle * 3.14159 / 180);
                final y = distance * sin(angle * 3.14159 / 180);
                return Transform.translate(
                  offset: Offset(x, y),
                  child: Opacity(
                    opacity: opacityAnimation.value,
                    child: Icon(Icons.star, size: 12 + (8 * iconScaleAnimation.value), color: Colors.yellow),
                  ),
                );
              }),
              // Main trophy icon with bounce
              Transform.translate(
                offset: Offset(0, sin(iconRotationAnimation.value * 3.14159 / 180) * 20),
                child: Transform.scale(
                  scale: iconScaleAnimation.value,
                  child: Icon(animatingIcon, size: 80, color: Colors.yellow),
                ),
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
