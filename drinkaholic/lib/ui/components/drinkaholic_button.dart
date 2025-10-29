import 'package:flutter/material.dart';

enum DrinkaholicButtonVariant { primary, secondary, outline }

typedef ButtonBuilder = Widget Function(BuildContext context, VoidCallback? onPressed);

class DrinkaholicButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DrinkaholicButtonVariant variant;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  const DrinkaholicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DrinkaholicButtonVariant.primary,
    this.fullWidth = true,
    this.height = 56,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    BoxDecoration decoration;
    TextStyle textStyle;
    Color? iconColor;

    switch (variant) {
      case DrinkaholicButtonVariant.primary:
        final colors = const [Color(0xFF00C9FF), Color(0xFF92FE9D)];
        decoration = BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(colors: [
                  const Color(0xFF5A5A6E).withOpacity(0.6),
                  const Color(0xFF7A7A8E).withOpacity(0.6),
                ])
              : LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00C9FF).withOpacity(0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
        );
        textStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        );
        iconColor = Colors.white;
        break;

      case DrinkaholicButtonVariant.secondary:
        decoration = BoxDecoration(
          color: isDisabled ? Colors.white.withOpacity(0.20) : Colors.white.withOpacity(0.28),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textStyle = TextStyle(
          color: Colors.white.withOpacity(isDisabled ? 0.7 : 0.95),
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.5,
        );
        iconColor = Colors.white;
        break;

      case DrinkaholicButtonVariant.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withOpacity(isDisabled ? 0.35 : 0.6), width: 1.6),
        );
        textStyle = TextStyle(
          color: Colors.white.withOpacity(isDisabled ? 0.7 : 1.0),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );
        iconColor = Colors.white;
        break;
    }

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      ],
    );

    final button = Container(
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          )),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
