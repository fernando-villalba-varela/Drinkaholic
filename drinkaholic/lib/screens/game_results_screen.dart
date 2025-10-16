import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';

class GameResultsScreen extends StatefulWidget {
  final List<Player> players;
  final Map<int, int> playerDrinks;
  final int maxRounds;
  final VoidCallback onConfirm;

  const GameResultsScreen({
    super.key,
    required this.players,
    required this.playerDrinks,
    required this.maxRounds,
    required this.onConfirm,
  });

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // playerDrinks ahora es Map<playerId, drinks>
    // Calcular MVP (más tragos) y Ratita (menos tragos)
    int mvpPlayerId = -1;
    int ratitaPlayerId = -1;
    int maxDrinks = 0;
    int minDrinks = 999999;

    widget.playerDrinks.forEach((playerId, drinks) {
      if (drinks > maxDrinks) {
        maxDrinks = drinks;
        mvpPlayerId = playerId;
      }
      if (drinks < minDrinks) {
        minDrinks = drinks;
        ratitaPlayerId = playerId;
      }
    });

    Player? mvp = widget.players.firstWhere(
      (p) => p.id == mvpPlayerId,
      orElse: () => widget.players.first,
    );
    Player? ratita = widget.players.firstWhere(
      (p) => p.id == ratitaPlayerId,
      orElse: () => widget.players.last,
    );

    // Ordenar jugadores por cantidad de tragos (de más a menos)
    final sortedPlayers = List<MapEntry<int, int>>.from(
      widget.playerDrinks.entries,
    )..sort((a, b) => b.value.compareTo(a.value));

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600 || screenSize.height < 400;

    // Dimensiones adaptativas
    final headerPadding = isSmallScreen ? 16.0 : 24.0;
    final contentPadding = isSmallScreen ? 16.0 : 24.0;
    final iconSize = isSmallScreen ? 24.0 : 32.0;
    final titleFontSize = isSmallScreen ? 18.0 : 24.0;
    final subtitleFontSize = isSmallScreen ? 13.0 : 16.0;
    final sectionTitleFontSize = isSmallScreen ? 15.0 : 18.0;
    final statsFontSize = isSmallScreen ? 13.0 : 16.0;
    final buttonFontSize = isSmallScreen ? 15.0 : 18.0;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(headerPadding),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¡Juego Terminado!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      children: [
                        Text(
                          'Se han completado ${widget.maxRounds} rondas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: subtitleFontSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        // MVP Section - TOP
                        _buildMVPCard(
                          player: mvp,
                          drinks: maxDrinks,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        // Estadísticas del Juego
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
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
                                final playerId = entry.key;
                                final drinks = entry.value;
                                // Buscar jugador por playerId
                                final player = widget.players.firstWhere(
                                  (p) => p.id == playerId,
                                  orElse: () => widget.players.first,
                                );

                                final avatarSize = isSmallScreen ? 28.0 : 32.0;
                                final drinkIconSize = isSmallScreen
                                    ? 14.0
                                    : 16.0;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isSmallScreen ? 8 : 12,
                                  ),
                                  child: Row(
                                    children: [
                                      _buildPlayerAvatar(
                                        player,
                                        size: avatarSize,
                                      ),
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
                                          color: const Color(
                                            0xFF00C9FF,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.local_drink,
                                              color: const Color(0xFF00C9FF),
                                              size: drinkIconSize,
                                            ),
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
                              // Ratita Section - BOTTOM
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildRatitaCard(
                                player: ratita,
                                drinks: minDrinks,
                                isSmallScreen: isSmallScreen,
                              ),
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
                      onPressed: widget.onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9FF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: buttonFontSize,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildMVPCard({
    required Player player,
    required int drinks,
    required bool isSmallScreen,
  }) {
    final avatarSize = isSmallScreen ? 50.0 : 60.0;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final titleFontSize = isSmallScreen ? 12.0 : 14.0;
    final playerNameFontSize = isSmallScreen ? 18.0 : 22.0;
    final drinksFontSize = isSmallScreen ? 13.0 : 15.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.3),
            const Color(0xFFFFD700).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(
        children: [
          _buildPlayerAvatar(player, size: avatarSize),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 MVDP (Más Borracho)',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Text(
                  player.nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: playerNameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '$drinks tragos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: drinksFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatitaCard({
    required Player player,
    required int drinks,
    required bool isSmallScreen,
  }) {
    final avatarSize = isSmallScreen ? 40.0 : 48.0;
    final padding = isSmallScreen ? 10.0 : 12.0;
    final titleFontSize = isSmallScreen ? 11.0 : 13.0;
    final playerNameFontSize = isSmallScreen ? 15.0 : 18.0;
    final drinksFontSize = isSmallScreen ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF92FE9D).withOpacity(0.3),
            const Color(0xFF92FE9D).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF92FE9D), width: 2),
      ),
      child: Row(
        children: [
          _buildPlayerAvatar(player, size: avatarSize),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🐭 Ratita (Más Sobrio)',
                  style: TextStyle(
                    color: const Color(0xFF92FE9D),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  player.nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: playerNameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '$drinks tragos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: drinksFontSize,
                  ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            )
          : null,
    );
  }
}
