import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'dart:math';

Widget buildCenterContent(GameState gameState) {
  
  //Current challenge es solo cuando son preguntas
  //Se creara uan variable para el gift si es reto o juego 
   if(gameState.currentChallenge != null){ 
    // Verificar si es un evento
    if (gameState.isEvent) {
      return _buildEventContent(gameState);
    }
    
    // Verificar si es un reto constante
    if (gameState.isConstantChallenge) {
      return _buildConstantChallengeContent(gameState);
    }
    
    final isForAll = gameState.isChallengeForAll;

    return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Current player indicator with glow (single or dual)
      AnimatedBuilder(
        animation: gameState.glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(4),
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
            child: isForAll 
                ? Icon(
                    Icons.people,
                    size: 50,
                    color: Colors.white.withOpacity(gameState.glowAnimation.value),
                  )
                : gameState.isDualChallenge
                    ? _buildDualPlayerAvatars(gameState)
                    : gameState.currentPlayer != null
                        ? _buildSinglePlayerAvatar(gameState)
                        : Icon(
                            Icons.person_pin,
                            size: 50,
                            color: Colors.white.withOpacity(gameState.glowAnimation.value),
                          ),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      // Player name or "Todos" (with dual support)
      Text(
        gameState.isDualChallenge ? gameState.dualTurnDisplayName : gameState.currentTurnDisplayName,
        style: TextStyle(
          fontSize: gameState.isDualChallenge ? 28 : 36, // Smaller text for dual names
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: gameState.isDualChallenge ? 2 : 3,
          shadows: const [
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
      
      // Enhanced Challenge text container
      TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 0),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, iconValue, child) {
                      return Transform.rotate(
                        angle: iconValue * 2 * pi,
                        child: Icon(
                          _getDynamicIcon(gameState.currentChallenge!),
                          size: 50 + (sin(iconValue * 2 * pi) * 5),
                          color: Colors.white.withOpacity(0.9 + (0.1 * iconValue)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    style: TextStyle(
                      fontSize: 26 + (sin(value * pi) * 2),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                        Shadow(
                          color: Colors.cyan.withOpacity(0.3),
                          offset: const Offset(-1, -1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      gameState.currentChallenge!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

Widget _buildEventContent(GameState gameState) {
  final isEndingEvent = gameState.isEndingEvent;
  final isNewEvent = gameState.isNewEvent;
  
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Special icon for events with cosmic glow effect
      AnimatedBuilder(
        animation: gameState.glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isEndingEvent 
                    ? [Colors.purple.withOpacity(0.4), Colors.indigo.withOpacity(0.2)]
                    : [Colors.cyan.withOpacity(0.4), Colors.blue.withOpacity(0.2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isEndingEvent ? Colors.purple : Colors.cyan)
                      .withOpacity(gameState.glowAnimation.value * 0.8),
                  blurRadius: 35,
                  spreadRadius: 12,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(gameState.glowAnimation.value * 0.6),
                  blurRadius: 20,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Icon(
              isEndingEvent 
                  ? Icons.event_busy 
                  : Icons.event_available,
              size: 70,
              color: isEndingEvent 
                  ? Colors.purple.withOpacity(gameState.glowAnimation.value)
                  : Colors.cyan.withOpacity(gameState.glowAnimation.value),
            ),
          );
        },
      ),
      
      const SizedBox(height: 25),
      
      // Event type indicator with cosmic theme
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEndingEvent 
                ? [Colors.purple.withOpacity(0.3), Colors.indigo.withOpacity(0.1)]
                : [Colors.cyan.withOpacity(0.3), Colors.blue.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isEndingEvent ? Colors.purple : Colors.cyan,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🌌',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isEndingEvent ? 'EVENTO FINALIZADO' : 'NUEVO EVENTO GLOBAL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isEndingEvent ? Colors.purple : Colors.cyan,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '🌌',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 20),
      
      // Global indicator - no specific player
      Text(
        'TODOS LOS JUGADORES',
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: Colors.black38,
              offset: Offset(3, 3),
              blurRadius: 6,
            ),
            Shadow(
              color: Colors.cyan,
              offset: Offset(-1, -1),
              blurRadius: 3,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      
      const SizedBox(height: 35),
      
      // Event container with cosmic styling
      TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.85 + (0.15 * value),
            child: Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isEndingEvent 
                      ? [Colors.purple.withOpacity(0.2), Colors.indigo.withOpacity(0.05)]
                      : [Colors.cyan.withOpacity(0.2), Colors.blue.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Animated cosmic icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, iconValue, child) {
                      return Transform.rotate(
                        angle: iconValue * 2 * pi,
                        child: Transform.scale(
                          scale: 1.0 + (sin(iconValue * 4 * pi) * 0.1),
                          child: Text(
                            isEndingEvent ? '🌟' : '🌐',
                            style: TextStyle(
                              fontSize: 60 + (sin(iconValue * 3 * pi) * 8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  
                  // Event description with cosmic styling
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: TextStyle(
                      fontSize: 28 + (sin(value * pi) * 3),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(2, 2),
                          blurRadius: 6,
                        ),
                        Shadow(
                          color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.4),
                          offset: const Offset(-1, -1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      gameState.currentChallenge!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      
    ],
  );
}

IconData _getDynamicIcon(String challenge) {
  final lowerChallenge = challenge.toLowerCase();
  
  // Drinking related
  if (lowerChallenge.contains('bebe') || lowerChallenge.contains('trago') || lowerChallenge.contains('shot')) {
    return Icons.local_drink;
  }
  
  // Party/celebration related
  if (lowerChallenge.contains('baila') || lowerChallenge.contains('canta') || lowerChallenge.contains('música')) {
    return Icons.music_note;
  }
  
  // Truth or questions
  if (lowerChallenge.contains('pregunta') || lowerChallenge.contains('cuenta') || lowerChallenge.contains('confiesa')) {
    return Icons.quiz;
  }
  
  // Social/group activities
  if (lowerChallenge.contains('todos') || lowerChallenge.contains('grupo') || lowerChallenge.contains('equipo')) {
    return Icons.group;
  }
  
  // Game/challenge related
  if (lowerChallenge.contains('juego') || lowerChallenge.contains('reto') || lowerChallenge.contains('desafío')) {
    return Icons.sports_esports;
  }
  
  // Love/romantic related
  if (lowerChallenge.contains('amor') || lowerChallenge.contains('besa') || lowerChallenge.contains('pareja')) {
    return Icons.favorite;
  }
  
  // Action/movement related
  if (lowerChallenge.contains('salta') || lowerChallenge.contains('corre') || lowerChallenge.contains('mueve')) {
    return Icons.directions_run;
  }
  
  // Phone/social media related
  if (lowerChallenge.contains('teléfono') || lowerChallenge.contains('mensaje') || lowerChallenge.contains('llamada')) {
    return Icons.phone;
  }
  
  // Time related
  if (lowerChallenge.contains('minutos') || lowerChallenge.contains('tiempo') || lowerChallenge.contains('segundo')) {
    return Icons.timer;
  }
  
  // Star/special challenges
  if (lowerChallenge.contains('especial') || lowerChallenge.contains('estrella') || lowerChallenge.contains('premio')) {
    return Icons.star;
  }
  
  // Default drink icon
  return Icons.local_drink;
}

/// Helper function to build single player avatar
Widget _buildSinglePlayerAvatar(GameState gameState) {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(gameState.glowAnimation.value),
        width: 3,
      ),
    ),
    child: ClipOval(
      child: gameState.currentPlayer!.imagen != null
          ? Image.file(
              gameState.currentPlayer!.imagen!,
              fit: BoxFit.cover,
            )
          : gameState.currentPlayer!.avatar != null
          ? Image.asset(
              gameState.currentPlayer!.avatar!,
              fit: BoxFit.cover,
            )
          : Container(
              color: Colors.white.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: Colors.white.withOpacity(gameState.glowAnimation.value),
                size: 40,
              ),
            ),
    ),
  );
}

/// Helper function to build dual player avatars
Widget _buildDualPlayerAvatars(GameState gameState) {
  return SizedBox(
    width: 120,
    height: 80,
    child: Stack(
      children: [
        // First player avatar (left)
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(gameState.glowAnimation.value),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: gameState.currentPlayer!.imagen != null
                  ? Image.file(
                      gameState.currentPlayer!.imagen!,
                      fit: BoxFit.cover,
                    )
                  : gameState.currentPlayer!.avatar != null
                  ? Image.asset(
                      gameState.currentPlayer!.avatar!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: Colors.white.withOpacity(gameState.glowAnimation.value),
                        size: 35,
                      ),
                    ),
            ),
          ),
        ),
        // Second player avatar (right, overlapped)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyan.withOpacity(gameState.glowAnimation.value * 0.8),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: gameState.dualPlayer!.imagen != null
                  ? Image.file(
                      gameState.dualPlayer!.imagen!,
                      fit: BoxFit.cover,
                    )
                  : gameState.dualPlayer!.avatar != null
                  ? Image.asset(
                      gameState.dualPlayer!.avatar!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.cyan.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: Colors.cyan.withOpacity(gameState.glowAnimation.value),
                        size: 35,
                      ),
                    ),
            ),
          ),
        ),
        // VS indicator in the middle
        Positioned(
          left: 35,
          top: 25,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
