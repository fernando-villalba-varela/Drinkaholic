import 'package:flutter/material.dart';

class LeagueEmptyState extends StatelessWidget {
  const LeagueEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_drink, size: 110, color: Colors.amber.shade500),
          const SizedBox(height: 34),
          const Text(
            'Aún no eres un borracho',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: .5,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Pulsa "Nueva liga" para emborracharte de gloria o importa una liga de tu amigo.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
