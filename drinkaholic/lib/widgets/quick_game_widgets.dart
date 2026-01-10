import 'package:drinkaholic/models/player.dart';
import 'package:drinkaholic/widgets/common/answer_info_button.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'dart:math';

// Helper function para determinar tamaños responsivos
double getResponsiveSize(BuildContext context, {required double small, required double medium, required double large}) {
  final width = MediaQuery.of(context).size.width;

  // Breakpoints ajustados para Nothing Phone (2400x1080)
  const breakpointSmall = 1000.0; // Móviles pequeños
  const breakpointMedium = 1700.0; // Móviles medianos/grandes como Nothing Phone

  if (width <= breakpointSmall) {
    return small * 1.2; // Incremento del 20% para mejor visibilidad
  } else if (width <= breakpointMedium) {
    return medium * 1.5; // Incremento del 15%
  } else {
    return large * 2;
  }
}

Widget buildCenterContent(GameState gameState) {
  //Current challenge es solo cuando son preguntas
  //Se creara uan variable para el gift si es reto o juego
  if (gameState.currentChallenge != null) {
    // Verificar si es un evento
    if (gameState.isEvent) {
      return _buildEventContent(gameState);
    }

    // Verificar si es un reto constante
    if (gameState.isConstantChallenge) {
      return _buildConstantChallengeContent(gameState);
    }

    final isForAll = gameState.isChallengeForAll;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Definir tamaños responsivos
        final iconSize = getResponsiveSize(
          context,
          small: 35, // Aumentado de 28
          medium: 40, // Aumentado de 35
          large: 50, // Aumentado de 45
        );

        final fontSize = getResponsiveSize(
          context,
          small: 18, // Aumentado de 16
          medium: 22, // Aumentado de 20
          large: 26, // Aumentado de 24
        );

        final padding = getResponsiveSize(
          context,
          small: 18, // Aumentado de 15
          medium: 28, // Aumentado de 25
          large: 38, // Aumentado de 35
        );

        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 500;

        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Current player indicator with glow (single or dual)
              AnimatedBuilder(
                animation: gameState.glowAnimation,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(gameState.glowAnimation.value * 0.6),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: isForAll
                        ? Icon(Icons.people, size: 50, color: Colors.white.withOpacity(gameState.glowAnimation.value))
                        : gameState.isDualChallenge
                        ? _buildDualPlayerAvatars(gameState)
                        : _isGenericPlayerQuestion(gameState)
                        ? Icon(
                            Icons.group,
                            size: iconSize,
                            color: Colors.white.withOpacity(gameState.glowAnimation.value),
                          )
                        : _getPlayerIndexFromQuestion(gameState) != null
                        ? _buildSinglePlayerAvatarByIndex(gameState, _getPlayerIndexFromQuestion(gameState)!)
                        : Icon(
                            Icons.group,
                            size: iconSize,
                            color: Colors.white.withOpacity(gameState.glowAnimation.value),
                          ),
                  );
                },
              ),

              SizedBox(height: isSmallScreen ? 5 : 10),

              // Player name or "Todos" (with dual support)
              // Text(
              //   gameState.isDualChallenge
              //       ? gameState.dualTurnDisplayName
              //       : gameState.currentTurnDisplayName,
              //   style: TextStyle(
              //     fontSize: fontSize, // Smaller text for dual names
              //     fontWeight: FontWeight.w900,
              //     color: Colors.white,
              //     letterSpacing: gameState.isDualChallenge ? 2 : 3,
              //     shadows: const [
              //       Shadow(
              //         color: Colors.black38,
              //         offset: Offset(2, 2),
              //         blurRadius: 4,
              //       ),
              //     ],
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              //SizedBox(height: isSmallScreen ? 10 : 20),

              // Enhanced Challenge text container
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: Container(
                      padding: EdgeInsets.all(padding),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.10)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
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
                                  size: iconSize + (sin(iconValue * 2 * pi) * 5),
                                  color: Colors.white.withOpacity(0.9 + (0.1 * iconValue)),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 400),
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.4,
                                    shadows: [
                                      Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(2, 2), blurRadius: 4),
                                      Shadow(
                                        color: Colors.cyan.withOpacity(0.3),
                                        offset: const Offset(-1, -1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(gameState.currentChallenge!, textAlign: TextAlign.center),
                                ),
                              ),
                              AnswerInfoButton(answer: gameState.currentAnswer),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  // Add a fallback return to satisfy the non-nullable return type
  return const SizedBox.shrink();
}

Widget _buildConstantChallengeContent(GameState gameState) {
  final isEndingChallenge = gameState.isEndingConstantChallenge;
  final isNewChallenge = gameState.isNewConstantChallenge;

  return LayoutBuilder(
    builder: (context, constraints) {
      final iconSize = getResponsiveSize(
        context,
        small: 35, // Aumentado de 28
        medium: 40, // Aumentado de 35
        large: 50, // Aumentado de 45
      );

      final fontSize = getResponsiveSize(
        context,
        small: 18, // Aumentado de 16
        medium: 22, // Aumentado de 20
        large: 23, // Aumentado de 24
      );

      final padding = getResponsiveSize(
        context,
        small: 18, // Aumentado de 15
        medium: 28, // Aumentado de 25
        large: 38, // Aumentado de 35
      );

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Challenge type indicator with icon on the left (sin martillo gigante arriba)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Martillo con aura amarilla a la izquierda (más grande)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isEndingChallenge ? Colors.green : Colors.orange).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  isEndingChallenge ? Icons.celebration : Icons.gavel,
                  size: iconSize * 1.0, // Aumentado de 0.7 a 1.0
                  color: isEndingChallenge ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                decoration: BoxDecoration(
                  color: isEndingChallenge ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isEndingChallenge ? Colors.green : Colors.orange, width: 2),
                ),
                child: Text(
                  isEndingChallenge ? 'RETO FINALIZADO' : 'NUEVO RETO CONSTANTE',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: isEndingChallenge ? Colors.green : Colors.orange,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          //SizedBox(height: isSmallScreen ? 5 : 10),

          // Player name (if applicable)
          // if (gameState.currentPlayerIndex >= 0 && gameState.currentPlayerIndex < gameState.players.length)
          //   Text(
          //     gameState.players[gameState.currentPlayerIndex].nombre.toUpperCase(),
          //     style: const TextStyle(
          //       fontSize: 32,
          //       fontWeight: FontWeight.w900,
          //       color: Colors.white,
          //       letterSpacing: 2.5,
          //       shadows: [
          //         Shadow(
          //           color: Colors.black38,
          //           offset: Offset(2, 2),
          //           blurRadius: 4,
          //         ),
          //       ],
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          SizedBox(height: 20),

          // Challenge container with special styling
          Container(
            padding: EdgeInsets.all(padding),
            margin: EdgeInsets.symmetric(horizontal: padding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isEndingChallenge
                    ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                    : [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: (isEndingChallenge ? Colors.green : Colors.orange).withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                // Texto del reto con estrella AL PRINCIPIO (al lado del número)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isEndingChallenge ? Icons.celebration : Icons.star,
                      size: iconSize * 0.7,
                      color: isEndingChallenge ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        gameState.currentChallenge!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Show punishment info for new constant challenges
                if (isNewChallenge && !isEndingChallenge) ...[
                  const SizedBox(height: 15),
                  ..._buildPunishmentInfo(gameState, context),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

List<Widget> _buildPunishmentInfo(GameState gameState, BuildContext context) {
  final iconSize = getResponsiveSize(
    context,
    small: 25, // Aumentado de 28
    medium: 30, // Aumentado de 35
    large: 40, // Aumentado de 45
  );

  final fontSize = getResponsiveSize(
    context,
    small: 18, // Aumentado de 16
    medium: 22, // Aumentado de 20
    large: 26, // Aumentado de 24
  );

  final padding = getResponsiveSize(
    context,
    small: 18, // Aumentado de 15
    medium: 28, // Aumentado de 25
    large: 35, // Aumentado de 35
  );

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
    const SizedBox(height: 7),
    Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.red, size: iconSize),
              const SizedBox(width: 8),
              Text(
                'CASTIGO',
                style: TextStyle(color: Colors.red, fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            activeChallenge!.punishment,
            style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ];
}

Widget _buildEventContent(GameState gameState) {
  final isEndingEvent = gameState.isEndingEvent;

  return LayoutBuilder(
    builder: (context, constraints) {
      getResponsiveSize(
        context,
        small: 35, // Aumentado de 28
        medium: 40, // Aumentado de 35
        large: 50, // Aumentado de 45
      );

      final fontSize = getResponsiveSize(
        context,
        small: 18, // Aumentado de 16
        medium: 22, // Aumentado de 20
        large: 26, // Aumentado de 24
      );

      final padding = getResponsiveSize(
        context,
        small: 18, // Aumentado de 15
        medium: 28, // Aumentado de 25
        large: 38, // Aumentado de 35
      );

      getResponsiveSize(
        context,
        small: 20, // Nuevo valor
        medium: 30, // Nuevo valor
        large: 40, // Nuevo valor
      );

      getResponsiveSize(
        context,
        small: 15, // Nuevo valor
        medium: 25, // Nuevo valor
        large: 35, // Nuevo valor
      );

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Event type indicator sin calendario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEndingEvent
                    ? [Colors.purple.withOpacity(0.3), Colors.indigo.withOpacity(0.1)]
                    : [Colors.cyan.withOpacity(0.3), Colors.blue.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isEndingEvent ? Colors.purple : Colors.cyan, width: 2),
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
                Text('🌌', style: TextStyle(fontSize: fontSize)),
                const SizedBox(width: 10),
                Text(
                  isEndingEvent ? 'EVENTO FINALIZADO' : 'NUEVO EVENTO GLOBAL',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: isEndingEvent ? Colors.purple : Colors.cyan,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Text('🌌', style: TextStyle(fontSize: fontSize)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Global indicator - no specific player
          Text(
            'TODOS LOS JUGADORES',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              shadows: const [
                Shadow(color: Colors.black38, offset: Offset(3, 3), blurRadius: 6),
                Shadow(color: Colors.cyan, offset: Offset(-1, -1), blurRadius: 3),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20),

          // Event container with cosmic styling
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.85 + (0.15 * value),
                child: Container(
                  padding: EdgeInsets.all(padding),
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
                    border: Border.all(color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.5), width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10)),
                      BoxShadow(
                        color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Event description with cosmic styling (sin icono del mundo arriba)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 600),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.3,
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.6), offset: const Offset(2, 2), blurRadius: 6),
                                  Shadow(
                                    color: (isEndingEvent ? Colors.purple : Colors.cyan).withOpacity(0.4),
                                    offset: const Offset(-1, -1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Text(gameState.currentChallenge!, textAlign: TextAlign.center),
                            ),
                          ),
                          AnswerInfoButton(answer: gameState.currentAnswer),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
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
  return LayoutBuilder(
    builder: (context, constraints) {
      final avatarSize = getResponsiveSize(
        context,
        small: 60, // Tamaño para pantallas pequeñas
        medium: 80, // Tamaño para pantallas medianas
        large: 100, // Tamaño para pantallas grandes
      );

      final borderWidth = getResponsiveSize(context, small: 2, medium: 3, large: 4);

      final iconSize = getResponsiveSize(context, small: 30, medium: 40, large: 50);

      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(gameState.glowAnimation.value), width: borderWidth),
        ),
        child: ClipOval(
          child: gameState.currentPlayer!.imagen != null
              ? Image.file(gameState.currentPlayer!.imagen!, fit: BoxFit.contain) // Cambiado de cover a contain
              : gameState.currentPlayer!.avatar != null
              ? Image.asset(gameState.currentPlayer!.avatar!, fit: BoxFit.contain) // Cambiado de cover a contain
              : Container(
                  color: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(gameState.glowAnimation.value),
                    size: iconSize,
                  ),
                ),
        ),
      );
    },
  );
}

Widget _buildSinglePlayerAvatarByIndex(GameState gameState, int playerIndex) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final avatarSize = getResponsiveSize(
        context,
        small: 60,
        medium: 80,
        large: 100,
      );

      final borderWidth = getResponsiveSize(context, small: 2, medium: 3, large: 4);

      final iconSize = getResponsiveSize(context, small: 30, medium: 40, large: 50);

      if (playerIndex < 0 || playerIndex >= gameState.players.length) {
        return Icon(Icons.group, size: avatarSize, color: Colors.white);
      }

      final player = gameState.players[playerIndex];

      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(gameState.glowAnimation.value), width: borderWidth),
        ),
        child: ClipOval(
          child: player.imagen != null
              ? Image.file(player.imagen!, fit: BoxFit.contain)
              : player.avatar != null
              ? Image.asset(player.avatar!, fit: BoxFit.contain)
              : Container(
                  color: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(gameState.glowAnimation.value),
                    size: iconSize,
                  ),
                ),
        ),
      );
    },
  );
}

/// Ajustar tamaños para avatares duales
Widget _buildDualPlayerAvatars(GameState gameState) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final containerWidth = getResponsiveSize(context, small: 100, medium: 120, large: 140);

      final avatarSize = getResponsiveSize(context, small: 50, medium: 70, large: 90);

      final vsSize = getResponsiveSize(context, small: 25, medium: 30, large: 35);

      final vsFontSize = getResponsiveSize(context, small: 10, medium: 12, large: 14);

      return SizedBox(
        width: containerWidth,
        height: avatarSize,
        child: Stack(
          children: [
            // Primer avatar (izquierda)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(gameState.glowAnimation.value), width: 3),
                ),
                child: ClipOval(
                  child: _buildPlayerImage(
                    gameState.currentPlayer!,
                    gameState,
                    context, // Pasar el context
                  ),
                ),
              ),
            ),
            // Segundo avatar (derecha)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyan.withOpacity(gameState.glowAnimation.value * 0.8), width: 3),
                ),
                child: ClipOval(
                  child: _buildPlayerImage(
                    gameState.dualPlayer!,
                    gameState,
                    context, // Pasar el context
                  ),
                ),
              ),
            ),
            // Indicador VS
            Positioned(
              left: containerWidth / 2.75,
              top: avatarSize / 3,
              child: Container(
                width: vsSize,
                height: vsSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)],
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: TextStyle(fontSize: vsFontSize, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Helper function para detectar si es una pregunta genérica con jugador específico
// Retorna true si es genérica (no menciona a ningún jugador específico)
bool _isGenericPlayerQuestion(GameState gameState) {
  final challenge = gameState.currentChallenge;
  if (challenge == null || challenge.isEmpty) return true; // Si no hay pregunta, es genérica

  // Buscar si la pregunta menciona a ALGÚN jugador específico por su nombre
  for (final player in gameState.players) {
    if (challenge.contains('${player.nombre} bebe') || challenge.contains('${player.nombre} reparte')) {
      return false; // Encontró un jugador específico, NO es genérica
    }
  }
  
  return true; // No menciona a ningún jugador específico, SÍ es genérica
}

// Helper function para obtener el índice del jugador si está mencionado en la pregunta
int? _getPlayerIndexFromQuestion(GameState gameState) {
  final challenge = gameState.currentChallenge;
  if (challenge == null || challenge.isEmpty) return null;

  // Buscar cuál jugador es mencionado en la pregunta
  for (int i = 0; i < gameState.players.length; i++) {
    final player = gameState.players[i];
    if (challenge.contains('${player.nombre} bebe') || challenge.contains('${player.nombre} reparte')) {
      return i;
    }
  }
  
  return null;
}

// Helper method para construir la imagen del jugador
Widget _buildPlayerImage(Player player, GameState gameState, BuildContext context) {
  final iconSize = getResponsiveSize(
    context, // Usar el context pasado como parámetro
    small: 30,
    medium: 40,
    large: 50,
  );

  return player.imagen != null
      ? Image.file(player.imagen!, fit: BoxFit.contain) // Cambiado de cover a contain
      : player.avatar != null
          ? Image.asset(player.avatar!, fit: BoxFit.contain)
          : Container(
              color: Colors.white.withOpacity(0.2),
              child: Icon(Icons.person, color: Colors.white.withOpacity(gameState.glowAnimation.value), size: iconSize),
            );
}
