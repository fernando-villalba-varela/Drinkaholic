import 'package:flutter/material.dart';

class FabNewLeague extends StatelessWidget {
  final VoidCallback onPressed;

  const FabNewLeague({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      foregroundColor: Colors.black87,
      backgroundColor: Colors.tealAccent.shade200,
      elevation: 4,
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Nueva liga'),
    );
  }
}
