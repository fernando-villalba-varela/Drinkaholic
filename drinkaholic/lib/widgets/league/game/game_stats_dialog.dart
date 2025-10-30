import 'package:flutter/material.dart';
import '../../../models/player.dart';

void showGameStatsDialog({
  required BuildContext context,
  required List<Player> players,
  required Map<int, int> playerDrinks,
  required int maxRounds,
  required VoidCallback onConfirm,
}) {
  // Calcular MVP (más tragos) y Ratita (menos tragos)
  int mvpIndex = -1;
  int ratitaIndex = -1;
  int maxDrinks = 0;
  int minDrinks = 999999;

  playerDrinks.forEach((index, drinks) {
    if (drinks > maxDrinks) {
      maxDrinks = drinks;
      mvpIndex = index;
    }
    if (drinks < minDrinks) {
      minDrinks = drinks;
      ratitaIndex = index;
    }
  });

  Player? mvp = mvpIndex >= 0 && mvpIndex < players.length ? players[mvpIndex] : null;
  Player? ratita = ratitaIndex >= 0 && ratitaIndex < players.length ? players[ratitaIndex] : null;

  // Ordenar jugadores por cantidad de tragos (de más a menos)
  final sortedPlayers = List<MapEntry<int, int>>.from(playerDrinks.entries)..sort((a, b) => b.value.compareTo(a.value));

  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600 || screenSize.height < 400;
  final isLandscape = screenSize.width > screenSize.height;

  // Calcular dimensiones adaptativas
  final maxWidth = isSmallScreen ? screenSize.width * 0.95 : 600.0;
  final maxHeight = isLandscape
      ? screenSize.height * 0.9
      : (isSmallScreen ? screenSize.height * 0.85 : double.infinity);
  final headerPadding = isSmallScreen ? 16.0 : 24.0;
  final contentPadding = isSmallScreen ? 16.0 : 24.0;
  final iconSize = isSmallScreen ? 24.0 : 32.0;
  final titleFontSize = isSmallScreen ? 18.0 : 24.0;
  final subtitleFontSize = isSmallScreen ? 13.0 : 16.0;
  final awardFontSize = isSmallScreen ? 11.0 : 14.0;
  final playerNameFontSize = isSmallScreen ? 16.0 : 20.0;
  final sectionTitleFontSize = isSmallScreen ? 15.0 : 18.0;
  final statsFontSize = isSmallScreen ? 13.0 : 16.0;
  final buttonFontSize = isSmallScreen ? 15.0 : 18.0;
  final buttonPadding = isSmallScreen ? 12.0 : 16.0;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(headerPadding),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: iconSize),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Juego Terminado!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFontSize),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    children: [
                      Text(
                        'Se han completado $maxRounds rondas',
                        style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // MVP Section
                      if (mvp != null)
                        _buildAwardCard(
                          title: '🏆 MVP (Más Borracho)',
                          player: mvp,
                          subtitle: '$maxDrinks tragos',
                          color: const Color(0xFFFFD700),
                          isSmallScreen: isSmallScreen,
                          awardFontSize: awardFontSize,
                          playerNameFontSize: playerNameFontSize,
                        ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Ratita Section
                      if (ratita != null)
                        _buildAwardCard(
                          title: '🐭 Ratita (Más Sobrio)',
                          player: ratita,
                          subtitle: '$minDrinks tragos',
                          color: const Color(0xFF92FE9D),
                          isSmallScreen: isSmallScreen,
                          awardFontSize: awardFontSize,
                          playerNameFontSize: playerNameFontSize,
                        ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Estadísticas de todos los jugadores
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estadísticas del Juego',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            ...sortedPlayers.map((entry) {
                              final index = entry.key;
                              final drinks = entry.value;
                              final player = index < players.length ? players[index] : null;
                              if (player == null) {
                                return const SizedBox.shrink();
                              }

                              final avatarSize = isSmallScreen ? 28.0 : 32.0;
                              final drinkIconSize = isSmallScreen ? 14.0 : 16.0;

                              return Padding(
                                padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                                child: Row(
                                  children: [
                                    _buildPlayerAvatar(player, size: avatarSize),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        player.nombre,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: statsFontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 12,
                                        vertical: isSmallScreen ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C9FF).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_drink, color: const Color(0xFF00C9FF), size: drinkIconSize),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$drinks',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: statsFontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Button
              Padding(
                padding: EdgeInsets.all(buttonPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: buttonFontSize),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Text('Guardar y Volver'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAwardCard({
  required String title,
  required Player player,
  required String subtitle,
  required Color color,
  required bool isSmallScreen,
  required double awardFontSize,
  required double playerNameFontSize,
}) {
  final avatarSize = isSmallScreen ? 40.0 : 48.0;
  final padding = isSmallScreen ? 12.0 : 16.0;
  final spacing = isSmallScreen ? 12.0 : 16.0;
  final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;

  return Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.5), width: 2),
    ),
    child: Row(
      children: [
        _buildPlayerAvatar(player, size: avatarSize),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: awardFontSize, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                player.nombre,
                style: TextStyle(color: Colors.white, fontSize: playerNameFontSize, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPlayerAvatar(Player player, {double size = 40}) {
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.4),
          )
        : null,
  );
}
