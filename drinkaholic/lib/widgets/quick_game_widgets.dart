import 'dart:io';
import 'package:flutter/material.dart';
import '../models/player.dart';

Widget buildCenterContent(
  StatefulWidget widget,
  List<Player> players,
  int currentPlayerIndex,
  String? currentChallenge,
  Animation<double> glowAnimation,
  Map<int, int> playerWeights,
  bool gameStarted,
  File? currentGift,
) {
  
  //Current challenge es solo cuando son preguntas
  //Se creara uan variable para el gift si es reto o juego 
   if(currentChallenge != null){ 
    final isForAll = isChallengeForAll(currentChallenge);

    return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Current player indicator with glow
      AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(glowAnimation.value * 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isForAll ? Icons.people : Icons.person_pin,
              size: 50,
              color: Colors.white.withOpacity(glowAnimation.value),
            ),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      // Player name or "Todos"
      Text(
        isForAll
            ? 'TODOS'
            : players[currentPlayerIndex].nombre.toUpperCase(),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: Colors.black38,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      
      const SizedBox(height: 40),
      
      // Challenge text
      Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.local_drink,
              size: 50,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              currentChallenge,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 30),
      
      // Selection count display (for testing)
      if (gameStarted)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Turnos: ${playerWeights.values.join(", ")}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
  }
  // Add a fallback return to satisfy the non-nullable return type
  return const SizedBox.shrink();
}

bool isChallengeForAll(String challenge) {
  final lower = challenge.toLowerCase();
  return lower.contains('todos') || lower.contains('cualquiera');
}