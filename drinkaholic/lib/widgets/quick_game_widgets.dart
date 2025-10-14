import 'package:flutter/material.dart';
import '../models/game_state.dart';

Widget buildCenterContent(GameState gameState) {
  
  //Current challenge es solo cuando son preguntas
  //Se creara uan variable para el gift si es reto o juego 
   if(gameState.currentChallenge != null){ 
    // Verificar si es un reto constante
    if (gameState.isConstantChallenge) {
      return _buildConstantChallengeContent(gameState);
    }
    
    final isForAll = gameState.isChallengeForAll;

    return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Current player indicator with glow
      AnimatedBuilder(
        animation: gameState.glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(gameState.glowAnimation.value * 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isForAll ? Icons.people : Icons.person_pin,
              size: 50,
              color: Colors.white.withOpacity(gameState.glowAnimation.value),
            ),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      // Player name or "Todos"
      Text(
        gameState.currentTurnDisplayName,
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
              gameState.currentChallenge!,
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
      if (gameState.gameStarted)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Turnos: ${gameState.playerWeights.values.join(", ")}',
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

Widget _buildConstantChallengeContent(GameState gameState) {
  final isEndingChallenge = gameState.isEndingConstantChallenge;
  final isNewChallenge = gameState.isNewConstantChallenge;
  
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Special icon for constant challenges
      AnimatedBuilder(
        animation: gameState.glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEndingChallenge 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: (isEndingChallenge ? Colors.green : Colors.orange)
                      .withOpacity(gameState.glowAnimation.value * 0.6),
                  blurRadius: 25,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isEndingChallenge 
                  ? Icons.check_circle_outline 
                  : isNewChallenge 
                      ? Icons.gavel 
                      : Icons.rule,
              size: 60,
              color: isEndingChallenge 
                  ? Colors.green.withOpacity(gameState.glowAnimation.value)
                  : Colors.orange.withOpacity(gameState.glowAnimation.value),
            ),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      // Challenge type indicator
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isEndingChallenge 
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEndingChallenge ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Text(
          isEndingChallenge ? 'RETO FINALIZADO' : 'NUEVO RETO CONSTANTE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEndingChallenge ? Colors.green : Colors.orange,
            letterSpacing: 1.2,
          ),
        ),
      ),
      
      const SizedBox(height: 15),
      
      // Player name (if applicable)
      if (gameState.currentPlayerIndex >= 0 && gameState.currentPlayerIndex < gameState.players.length)
        Text(
          gameState.players[gameState.currentPlayerIndex].nombre.toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2.5,
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
      
      const SizedBox(height: 30),
      
      // Challenge container with special styling
      Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEndingChallenge 
                ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                : [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: (isEndingChallenge ? Colors.green : Colors.orange).withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              isEndingChallenge ? Icons.celebration : Icons.star,
              size: 40,
              color: isEndingChallenge ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 15),
            Text(
              gameState.currentChallenge!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            // Show punishment info for new constant challenges
            if (isNewChallenge && !isEndingChallenge) ..._buildPunishmentInfo(gameState),
          ],
        ),
      ),
      
      const SizedBox(height: 25),
      
      // Round counter
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'Ronda ${gameState.currentRound}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Active challenges indicator (if any)
      if (gameState.activeChallenges.isNotEmpty && !isEndingChallenge)
        Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Retos Activos:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              ...gameState.activeChallenges.take(3).map((challenge) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${challenge.typeIcon} ${challenge.targetPlayer.nombre}: ${_truncateText(challenge.description, 30)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              )),
              if (gameState.activeChallenges.length > 3)
                Text(
                  '... y ${gameState.activeChallenges.length - 3} más',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

String _truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

List<Widget> _buildPunishmentInfo(GameState gameState) {
  // Find the current constant challenge being created
  final currentPlayerIndex = gameState.currentPlayerIndex;
  if (currentPlayerIndex < 0 || currentPlayerIndex >= gameState.players.length) {
    return [];
  }
  
  final currentPlayer = gameState.players[currentPlayerIndex];
  final activeChallenges = gameState.constantChallenges
      .where((c) => c.targetPlayer.id == currentPlayer.id && c.startRound == gameState.currentRound)
      .toList();
  final activeChallenge = activeChallenges.isEmpty ? null : activeChallenges.last;
      
  if (activeChallenge?.punishment == null) {
    return [];
  }
  
  return [
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.red.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'CASTIGO',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeChallenge!.punishment,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ];
}
