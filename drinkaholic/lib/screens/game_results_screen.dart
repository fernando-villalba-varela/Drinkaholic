import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import 'tiebreaker_screen.dart';

class GameResultsScreen extends StatefulWidget {
  final List<Player> players;
  final Map<int, int> playerDrinks;
  final int maxRounds;
  final VoidCallback onConfirm;
  final Map<int, String>? streakMessages; // Mensajes especiales de rachas

  const GameResultsScreen({
    super.key,
    required this.players,
    required this.playerDrinks,
    required this.maxRounds,
    required this.onConfirm,
    this.streakMessages,
  });

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen>
    with TickerProviderStateMixin {
  Player? _resolvedMVP;
  Player? _resolvedRatita;
  bool _mvpTieResolved = false;
  bool _ratitaTieResolved = false;
  bool _isConfirming = false; // Prevenir múltiples ejecuciones
  AnimationController? _glowController;

  @override
  void initState() {
    super.initState();
    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Inicializar animación de parpadeo
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Inicializar verificación de empates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForTiebreakers();
    });
  }

  @override
  void dispose() {
    _glowController?.dispose();
    // Restore portrait orientation when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _checkForTiebreakers() {
    // MVDP = jugadores con MÁS tragos
    int maxDrinks = widget.playerDrinks.values.reduce((a, b) => a > b ? a : b);
    List<int> mvpPlayerIds = widget.playerDrinks.entries
        .where((entry) => entry.value == maxDrinks)
        .map((entry) => entry.key)
        .toList();

    // Ratita = jugadores con MENOS tragos
    int minDrinks = widget.playerDrinks.values.reduce((a, b) => a < b ? a : b);
    List<int> ratitaPlayerIds = widget.playerDrinks.entries
        .where((entry) => entry.value == minDrinks)
        .map((entry) => entry.key)
        .toList();

    // Verificar empate MVP
    if (mvpPlayerIds.length > 1 && !_mvpTieResolved) {
      List<Player> tiedMVPPlayers = widget.players
          .where((p) => mvpPlayerIds.contains(p.id))
          .toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TiebreakerScreen(
            tiedPlayers: tiedMVPPlayers,
            tiedScore: maxDrinks,
            type: TiebreakerType.mvp,
            onTiebreakerResolved: (winner, loser) {
              setState(() {
                _resolvedMVP = winner;
                _mvpTieResolved = true;
              });
              Navigator.pop(context);

              // Verificar empate Ratita después de resolver MVP
              if (ratitaPlayerIds.length > 1 && !_ratitaTieResolved) {
                _checkRatitaTiebreaker(ratitaPlayerIds, minDrinks);
              }
            },
          ),
        ),
      );
    }
    // Verificar empate Ratita si no hay empate MVP
    else if (ratitaPlayerIds.length > 1 && !_ratitaTieResolved) {
      _checkRatitaTiebreaker(ratitaPlayerIds, minDrinks);
    }
  }

  void _checkRatitaTiebreaker(List<int> ratitaPlayerIds, int minDrinks) {
    List<Player> tiedRatitaPlayers = widget.players
        .where((p) => ratitaPlayerIds.contains(p.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TiebreakerScreen(
          tiedPlayers: tiedRatitaPlayers,
          tiedScore: minDrinks,
          type: TiebreakerType.ratita,
          onTiebreakerResolved: (winner, loser) {
            setState(() {
              _resolvedRatita = winner;
              _ratitaTieResolved = true;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // playerDrinks ahora es Map<playerId, drinks>
    // Calcular MVDP (más tragos) y Ratita (menos tragos)
    int maxDrinks = widget.playerDrinks.values.reduce((a, b) => a > b ? a : b);
    int minDrinks = widget.playerDrinks.values.reduce((a, b) => a < b ? a : b);

    // Usar resultados de desempate si están disponibles, sino calcular normalmente
    Player mvp;
    Player ratita;

    if (_resolvedMVP != null) {
      mvp = _resolvedMVP!;
    } else {
      // MVDP = quien MÁS bebió (más tragos)
      int mvpPlayerId = widget.playerDrinks.entries
          .firstWhere((entry) => entry.value == maxDrinks)
          .key;
      mvp = widget.players.firstWhere(
        (p) => p.id == mvpPlayerId,
        orElse: () => widget.players.first,
      );
    }

    if (_resolvedRatita != null) {
      ratita = _resolvedRatita!;
    } else {
      // Ratita = quien MENOS bebió (menos tragos)
      int ratitaPlayerId = widget.playerDrinks.entries
          .firstWhere((entry) => entry.value == minDrinks)
          .key;
      ratita = widget.players.firstWhere(
        (p) => p.id == ratitaPlayerId,
        orElse: () => widget.players.last,
      );
    }

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
                          drinks: widget.playerDrinks[mvp.id] ?? 0,
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
                                drinks: widget.playerDrinks[ratita.id] ?? 0,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                        // Mensajes de Rachas Especiales
                        if (widget.streakMessages != null &&
                            widget.streakMessages!.isNotEmpty)
                          _buildStreakMessagesSection(isSmallScreen),
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
                      onPressed: _isConfirming
                          ? null
                          : () {
                              if (_isConfirming) return;
                              setState(() {
                                _isConfirming = true;
                              });
                              widget.onConfirm();
                            },
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
                  '🏆 MVDP',
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
            const Color.fromARGB(255, 98, 46, 33).withOpacity(0.3),
            const Color.fromARGB(255, 98, 46, 33).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 98, 46, 33),
          width: 2,
        ),
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
                  '🐭 Ratita',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 98, 46, 33),
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

  Widget _buildStreakMessagesSection(bool isSmallScreen) {
    // Filtrar solo los mensajes que no están vacíos
    final messagesWithContent = widget.streakMessages!.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (messagesWithContent.isEmpty) return const SizedBox.shrink();

    // Si el controlador no está inicializado, mostrar contenedor sin animación
    if (_glowController == null) {
      return Container(
        margin: EdgeInsets.only(top: isSmallScreen ? 16 : 24),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Fondo blanco brillante
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '👺 ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'BREAKING',
                      style: TextStyle(
                        color: const Color(0xFFCC0000), // Rojo CNN
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFCC0000).withOpacity(0.7),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: ' ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'NEWS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text:
                          ' -> El duende con un litte boy en la mano anuncia lo siguiente:',
                      style: TextStyle(
                        color: const Color(0xFFCC0000), // Rojo CNN
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ...messagesWithContent.map((entry) {
              final playerId = entry.key;
              final message = entry.value;
              widget.players.firstWhere(
                (p) => p.id == playerId,
                orElse: () => widget.players.first,
              );

              // Determinar si es racha de victorias o derrotas
              final isLossStreak = message.contains('rata asquerosa');
              final backgroundColor = isLossStreak
                  ? Colors.red.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2);
              final iconColor = isLossStreak ? Colors.red : Colors.orange;
              final icon = isLossStreak
                  ? Icons.cleaning_services
                  : Icons.emoji_events;

              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: isSmallScreen ? 20 : 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 13.0 : 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glowController!,
      builder: (context, child) {
        final animationValue = _glowController?.value ?? 0.0;
        return Container(
          margin: EdgeInsets.only(top: isSmallScreen ? 16 : 24),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(
                const Color(
                  0xFF228B22,
                ).withOpacity(0.4), // Verde oscuro de bosque
                const Color(
                  0xFF32CD32,
                ).withOpacity(0.9), // Verde duende brillante
                animationValue,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(
                    0xFF228B22,
                  ).withOpacity(0.2), // Verde oscuro suave
                  const Color(0xFF32CD32).withOpacity(0.6), // Verde brillante
                  animationValue,
                )!,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '👺 ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'BREAKING',
                      style: TextStyle(
                        color: const Color(0xFFCC0000), // Rojo CNN
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFCC0000).withOpacity(0.7),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: ' ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'NEWS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text:
                          ' -> El duende con un litte boy en la mano anuncia lo siguiente:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              ...messagesWithContent.map((entry) {
                final playerId = entry.key;
                final message = entry.value;
                widget.players.firstWhere(
                  (p) => p.id == playerId,
                  orElse: () => widget.players.first,
                );

                // Determinar si es racha de victorias o derrotas
                final isLossStreak = message.contains('rata asquerosa');
                final backgroundColor = isLossStreak
                    ? Colors.red.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2);
                final iconColor = isLossStreak ? Colors.red : Colors.orange;
                final icon = isLossStreak
                    ? Icons.cleaning_services
                    : Icons.emoji_events;

                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 13.0 : 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
