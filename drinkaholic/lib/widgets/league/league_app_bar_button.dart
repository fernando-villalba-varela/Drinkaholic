import 'package:flutter/material.dart';

class LeagueAppBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const LeagueAppBarButton({super.key, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF), // white with 20% opacity
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x4DFFFFFF), // white with 30% opacity
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // black with 10% opacity
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
