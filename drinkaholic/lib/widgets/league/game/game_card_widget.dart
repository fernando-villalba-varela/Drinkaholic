import 'package:flutter/material.dart';
import '../../../models/game_state.dart';
import '../../../models/player.dart';
import '../../quick_game_widgets.dart' show buildCenterContent;

double getResponsiveSize(
  BuildContext context, {
  required double small,
  required double medium,
  required double large,
}) {
  final width = MediaQuery.of(context).size.width;

  // Breakpoints ajustados para Nothing Phone (2400x1080)
  const breakpointSmall = 1000.0; // Móviles pequeños
  const breakpointMedium =
      1700.0; // Móviles medianos/grandes como Nothing Phone

  if (width <= breakpointSmall) {
    return small * 1.2; // Incremento del 20% para mejor visibilidad
  } else if (width <= breakpointMedium) {
    return medium * 1.5; // Incremento del 15%
  } else {
    return large * 2;
  }
}

class GameCard extends StatelessWidget {
  final GameState gameState;
  final bool showPlayerSelector;
  final Function(List<int>)? onPlayersSelected;

  const GameCard({
    super.key,
    required this.gameState,
    this.showPlayerSelector = false,
    this.onPlayersSelected,
  });

  @override
  Widget build(BuildContext context) {
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
          large: 26, // Aumentado de 24
        );

        final padding = getResponsiveSize(
          context,
          small: 18, // Aumentado de 15
          medium: 28, // Aumentado de 25
          large: 38, // Aumentado de 35
        );

        return SizedBox(
          width: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _buildChallengeContent(
                      gameState,
                      showPlayerSelector,
                      context,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Player selection buttons (for conditional questions)
                  if (showPlayerSelector &&
                      onPlayersSelected != null &&
                      gameState.players.isNotEmpty)
                    _buildPlayerSelectionButtons(
                      gameState.players,
                      onPlayersSelected!,
                    ),
                  // Tap indicator (only show at the beginning AND when NOT showing player selector)
                  if (!gameState.gameStarted && !showPlayerSelector)
                    AnimatedBuilder(
                      animation: gameState.glowAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: padding,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                gameState.glowAnimation.value * 0.8,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                  gameState.glowAnimation.value * 0.3,
                                ),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white.withOpacity(
                                  gameState.glowAnimation.value,
                                ),
                                size: iconSize,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TOCA LA PANTALLA',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    gameState.glowAnimation.value,
                                  ),
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerSelectionButtons(
    List<Player> players,
    Function(List<int>) onSelected,
  ) {
    final Set<int> selectedIds = {};

    return StatefulBuilder(
      builder: (context, setState) {
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

        // Tamaños más compactos para evitar scroll

        final buttonHeight = getResponsiveSize(
          context,
          small: 40, // Aumentado de 16
          medium: 50, // Aumentado de 20
          large: 60, // Aumentado de 24
        );

        final buttonWidth = getResponsiveSize(
          context,
          small: 230, // Aumentado de 16
          medium: 150, // Aumentado de 20
          large: 200, // Aumentado de 24
        );

        final avatarSize = 24.0;
        final spacing = 6.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instrucción más compacta
            Text(
              'Selecciona quién cumple la condición:',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 1.5),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.center,
              children: players.map((player) {
                final isSelected = selectedIds.contains(player.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedIds.remove(player.id);
                      } else {
                        selectedIds.add(player.id);
                      }
                    });
                  },
                  child: Container(
                    width: buttonWidth,
                    height: buttonHeight,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C9FF)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C9FF)
                            : Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniAvatar(player, avatarSize, context),
                        Text(
                          player.nombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: spacing * 1.5),
            // Solo mostrar botón confirmar si hay selección
            if (selectedIds.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  onSelected(selectedIds.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Confirmar (${selectedIds.length})',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniAvatar(Player player, double size, BuildContext context) {
    final iconSize = getResponsiveSize(
      context,
      small: 35, // Aumentado de 28
      medium: 20, // Aumentado de 35
      large: 30, // Aumentado de 45
    );

    final fontSize = getResponsiveSize(
      context,
      small: 18, // Aumentado de 16
      medium: 22, // Aumentado de 20
      large: 26, // Aumentado de 24
    );

    ImageProvider? img;
    if (player.imagen != null && player.imagen!.existsSync()) {
      img = FileImage(player.imagen!);
    } else if (player.avatar != null && player.avatar!.startsWith('assets/')) {
      img = AssetImage(player.avatar!);
    }

    return CircleAvatar(
      radius: iconSize,
      backgroundImage: img,
      child: img == null
          ? Text(
              player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            )
          : null,
    );
  }

  /// Builds challenge content, hiding "TODOS" icon and text when showPlayerSelector is true
  Widget _buildChallengeContent(
    GameState gameState,
    bool hideForAllIndicator,
    BuildContext context,
  ) {
    if (hideForAllIndicator && gameState.isChallengeForAll) {
      // Para preguntas condicionales, solo mostrar el texto del reto sin icono ni "TODOS"
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
            large: 26, // Aumentado de 24
          );

          final padding = getResponsiveSize(
            context,
            small: 18, // Aumentado de 15
            medium: 28, // Aumentado de 25
            large: 38, // Aumentado de 35
          );

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Solo el contenedor del reto sin icono ni texto "TODOS"
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
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_drink,
                              size: iconSize,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            SizedBox(height: 15),
                            Text(
                              gameState.currentChallenge!,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.4,
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

    // Para el resto de casos, usar el buildCenterContent normal
    return buildCenterContent(gameState);
  }
}
