import 'package:flutter/material.dart';
import '../../../models/game_state.dart';
import '../../../models/player.dart';
import '../../quick_game_widgets.dart' show buildCenterContent;

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
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        final indicatorFontSize = isSmallScreen ? 11.0 : 14.0;
        final indicatorIconSize = isSmallScreen ? 16.0 : 20.0;
        final indicatorPaddingH = isSmallScreen ? 12.0 : 20.0;
        final indicatorPaddingV = isSmallScreen ? 6.0 : 10.0;

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
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 20),
                  // Player selection buttons (for conditional questions)
                  if (showPlayerSelector &&
                      onPlayersSelected != null &&
                      gameState.players.isNotEmpty)
                    _buildPlayerSelectionButtons(
                      gameState.players,
                      isSmallScreen,
                      onPlayersSelected!,
                    ),
                  // Tap indicator (only show at the beginning AND when NOT showing player selector)
                  if (!gameState.gameStarted && !showPlayerSelector)
                    AnimatedBuilder(
                      animation: gameState.glowAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: indicatorPaddingH,
                            vertical: indicatorPaddingV,
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
                                size: indicatorIconSize,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TOCA LA PANTALLA',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    gameState.glowAnimation.value,
                                  ),
                                  fontSize: indicatorFontSize,
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
    bool isSmallScreen,
    Function(List<int>) onSelected,
  ) {
    final Set<int> selectedIds = {};

    return StatefulBuilder(
      builder: (context, setState) {
        // Tamaños más compactos para evitar scroll
        final buttonHeight = isSmallScreen ? 28.0 : 36.0;
        final buttonFontSize = isSmallScreen ? 10.0 : 12.0;
        final avatarSize = isSmallScreen ? 20.0 : 24.0;
        final spacing = isSmallScreen ? 4.0 : 6.0;
        final instructionFontSize = isSmallScreen ? 10.0 : 12.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instrucción más compacta
            Text(
              'Selecciona quién cumple la condición:',
              style: TextStyle(
                color: Colors.white,
                fontSize: instructionFontSize,
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
                    height: buttonHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 10,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C9FF)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 14 : 18,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C9FF)
                            : Colors.white.withOpacity(0.5),
                        width: isSmallScreen ? 1.5 : 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniAvatar(player, avatarSize),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          player.nombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: spacing * 1.5),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón "Nadie cumple"
                OutlinedButton(
                  onPressed: () {
                    // Pasar directamente al siguiente reto sin diálogo
                    onSelected(
                      [],
                    ); // Pasar lista vacía para indicar que nadie cumple
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 16,
                      vertical: isSmallScreen ? 6 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Nadie cumple',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selectedIds.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  // Botón "Confirmar" (solo visible si hay selección)
                  ElevatedButton(
                    onPressed: () {
                      onSelected(selectedIds.toList());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 20,
                        vertical: isSmallScreen ? 6 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Confirmar (${selectedIds.length})',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniAvatar(Player player, double size) {
    ImageProvider? img;
    if (player.imagen != null && player.imagen!.existsSync()) {
      img = FileImage(player.imagen!);
    } else if (player.avatar != null && player.avatar!.startsWith('assets/')) {
      img = AssetImage(player.avatar!);
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundImage: img,
      child: img == null
          ? Text(
              player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.5,
              ),
            )
          : null,
    );
  }

  /// Builds challenge content, hiding "TODOS" icon and text when showPlayerSelector is true
  Widget _buildChallengeContent(GameState gameState, bool hideForAllIndicator) {
    if (hideForAllIndicator && gameState.isChallengeForAll) {
      // Para preguntas condicionales, solo mostrar el texto del reto sin icono ni "TODOS"
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 500;
          final double padding = isSmallScreen ? 10 : 20;

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
                              size: isSmallScreen ? 25 : 35,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 15),
                            Text(
                              gameState.currentChallenge!,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.4,
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
