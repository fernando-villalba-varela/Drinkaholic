import 'package:flutter/material.dart';

class ButtonConfig {
  final String text;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const ButtonConfig({
    required this.text,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
