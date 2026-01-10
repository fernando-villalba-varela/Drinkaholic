import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/player.dart';
import 'tiebreaker_screen.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

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

class _GameResultsScreenState extends State<GameResultsScreen> with TickerProviderStateMixin {
  Player? _resolvedMVP;
  Player? _resolvedRatita;
  bool _mvpTieResolved = false;
  bool _ratitaTieResolved = false;
  bool _isConfirming = false; // Prevenir múltiples ejecuciones
  AnimationController? _glowController;

  // Confeti y overlay de orientación
  late AnimationController _confettiController;
  late AnimationController _orientationFadeController;
  late Animation<double> _orientationFade;
  bool _showOrientationOverlay = true;

  @override
  void initState() {
    super.initState();

    // Overlay para suavizar orientación a retrato y confeti inicial
    _orientationFadeController = AnimationController(duration: const Duration(milliseconds: 180), vsync: this);
    _orientationFade = CurvedAnimation(parent: _orientationFadeController, curve: Curves.easeInOut);
    _confettiController = AnimationController(duration: const Duration(milliseconds: 5000), vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _orientationFadeController.forward();
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await _orientationFadeController.reverse();
      if (mounted) {
        setState(() {
          _showOrientationOverlay = false;
        });
      }
      
      // SOLO disparar confeti si NO hay desempates
      _checkForTiebreakersAndStartConfetti();
    });

    // Inicializar animación de parpadeo (para brillos)
    _glowController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _confettiController.dispose();
    _orientationFadeController.dispose();
    // Restore portrait orientation when leaving this screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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

    // EXCLUIR al MVP resuelto de la lista de candidatos a Ratita
    if (_mvpTieResolved && _resolvedMVP != null) {
      ratitaPlayerIds.removeWhere((id) => id == _resolvedMVP!.id);
    }

    // Verificar empate MVP
    if (mvpPlayerIds.length > 1 && !_mvpTieResolved) {
      List<Player> tiedMVPPlayers = widget.players.where((p) => mvpPlayerIds.contains(p.id)).toList();

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

              // Recalcular candidatos a Ratita EXCLUYENDO al MVP ganador
              List<int> updatedRatitaPlayerIds = widget.playerDrinks.entries
                  .where((entry) => entry.value == minDrinks && entry.key != winner.id)
                  .map((entry) => entry.key)
                  .toList();

              // Verificar empate Ratita después de resolver MVP (con lista actualizada)
              if (updatedRatitaPlayerIds.length > 1 && !_ratitaTieResolved) {
                _checkRatitaTiebreaker(updatedRatitaPlayerIds, minDrinks);
              } else {
                // NO hay más empates - disparar confeti
                _startConfettiAnimation();
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
    List<Player> tiedRatitaPlayers = widget.players.where((p) => ratitaPlayerIds.contains(p.id)).toList();

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
            
            // Después de resolver el último desempate - disparar confeti
            _startConfettiAnimation();
          },
        ),
      ));
  }

  void _checkForTiebreakersAndStartConfetti() {
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

    // EXCLUIR al MVP resuelto de la lista de candidatos a Ratita
    if (_mvpTieResolved && _resolvedMVP != null) {
      ratitaPlayerIds.removeWhere((id) => id == _resolvedMVP!.id);
    }

    // Verificar si hay empates
    bool hasMVPTie = mvpPlayerIds.length > 1;
    bool hasRatitaTie = ratitaPlayerIds.length > 1;

    if (!hasMVPTie && !hasRatitaTie) {
      // NO hay empates - disparar confeti inmediatamente
      _startConfettiAnimation();
    } else {
      // HAY empates - manejar desempates primero
      _checkForTiebreakers();
    }
  }

  void _startConfettiAnimation() {
    if (mounted) {
      _confettiController.forward().then((_) {
        // Ya no usamos reset(), simplemente dejamos que termine y se desvanezca naturalmente
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // playerDrinks ahora es Map<playerId, drinks>
    // Calcular MVDP (más tragos) y Ratita (menos tragos)
    int maxDrinks = widget.playerDrinks.values.reduce((a, b) => a > b ? a : b);
    int minDrinks = widget.playerDrinks.values.reduce((a, b) => a < b ? a : b);

    // Obtener MVP
    Player mvpPlayer;
    int mvpDrinks;
    if (_mvpTieResolved && _resolvedMVP != null) {
      mvpPlayer = _resolvedMVP!;
      mvpDrinks = widget.playerDrinks[mvpPlayer.id] ?? 0;
    } else {
      mvpPlayer = widget.players.firstWhere((p) => widget.playerDrinks[p.id] == maxDrinks);
      mvpDrinks = maxDrinks;
    }

    // Obtener Ratita (EXCLUYENDO al MVP si es el mismo caso de empate total)
    Player ratitaPlayer;
    int ratitaDrinks;
    if (_ratitaTieResolved && _resolvedRatita != null) {
      ratitaPlayer = _resolvedRatita!;
      ratitaDrinks = widget.playerDrinks[ratitaPlayer.id] ?? 0;
    } else {
      // Filtrar candidatos a Ratita excluyendo al MVP si ya fue resuelto
      List<Player> ratitaCandidates = widget.players.where((p) {
        bool hasMinDrinks = widget.playerDrinks[p.id] == minDrinks;
        bool isNotResolvedMVP = !(_mvpTieResolved && _resolvedMVP != null && p.id == _resolvedMVP!.id);
        return hasMinDrinks && isNotResolvedMVP;
      }).toList();
      
      ratitaPlayer = ratitaCandidates.isNotEmpty 
          ? ratitaCandidates.first 
          : widget.players.firstWhere((p) => widget.playerDrinks[p.id] == minDrinks);
      ratitaDrinks = minDrinks;
    }

    // Ordenar jugadores por cantidad de tragos (de más a menos)
    final sortedPlayers = List<MapEntry<int, int>>.from(widget.playerDrinks.entries)
      ..sort((a, b) => b.value.compareTo(a.value));

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
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                ),
              ),
            ),
            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                // Header
                Container(
                  padding: EdgeInsets.all(headerPadding),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: iconSize),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          Provider.of<LanguageService>(context).translate('game_over_title'),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFontSize),
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
                          '${Provider.of<LanguageService>(context).translate('rounds_completed_text')} ${widget.maxRounds} ${Provider.of<LanguageService>(context).translate('rounds')}',
                          style: TextStyle(color: Colors.white, fontSize: subtitleFontSize),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        // MVP Section - TOP - USAR mvpPlayer en lugar de mvp
                        _buildMVPCard(
                          player: mvpPlayer,
                          drinks: widget.playerDrinks[mvpPlayer.id] ?? 0,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        // Estadísticas del Juego
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  Provider.of<LanguageService>(context).translate('game_statistics_title'),
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
                              // Ratita Section - BOTTOM - USAR ratitaPlayer en lugar de ratita
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildRatitaCard(
                                player: ratitaPlayer,
                                drinks: widget.playerDrinks[ratitaPlayer.id] ?? 0,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                        // Mensajes de Rachas Especiales
                        if (widget.streakMessages != null && widget.streakMessages!.isNotEmpty)
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
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: buttonFontSize),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text(Provider.of<LanguageService>(context).translate('save_and_return_button')),
                    ),
                  ),
                ),
              ],
            ),
          ),
            // Confeti celebratorio y overlay de orientación
            _buildConfettiOverlay(),
            if (_showOrientationOverlay)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orientationFade,
                  builder: (context, _) => Container(color: Colors.black.withOpacity(_orientationFade.value)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMVPCard({required Player player, required int drinks, required bool isSmallScreen}) {
    final avatarSize = isSmallScreen ? 50.0 : 60.0;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final titleFontSize = isSmallScreen ? 12.0 : 14.0;
    final playerNameFontSize = isSmallScreen ? 18.0 : 22.0;
    final drinksFontSize = isSmallScreen ? 13.0 : 15.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFD700).withOpacity(0.3), const Color(0xFFFFD700).withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.25 + 0.35 * (_glowController?.value ?? 0.0)),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
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
                  Provider.of<LanguageService>(context).translate('mvp_title'),
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Text(
                  player.nombre,
                  style: TextStyle(color: Colors.white, fontSize: playerNameFontSize, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '$drinks ${Provider.of<LanguageService>(context).translate('drinks_count_suffix')}',
                  style: TextStyle(color: Colors.white70, fontSize: drinksFontSize),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatitaCard({required Player player, required int drinks, required bool isSmallScreen}) {
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
        border: Border.all(color: const Color.fromARGB(255, 98, 46, 33), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4513).withOpacity(0.20 + 0.30 * (_glowController?.value ?? 0.0)),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
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
                  Provider.of<LanguageService>(context).translate('rat_title'),
                  style: TextStyle(
                    color: const Color.fromARGB(255, 98, 46, 33),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  player.nombre,
                  style: TextStyle(color: Colors.white, fontSize: playerNameFontSize, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '$drinks ${Provider.of<LanguageService>(context).translate('drinks_count_suffix')}',
                  style: TextStyle(color: Colors.white70, fontSize: drinksFontSize),
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

  Widget _buildStreakMessagesSection(bool isSmallScreen) {
    // Filtrar solo los mensajes que no están vacíos
    final messagesWithContent = widget.streakMessages!.entries.where((entry) => entry.value.isNotEmpty).toList();

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
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 4 : 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Fondo blanco brillante
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)],
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '👺 ',
                      style: TextStyle(fontSize: isSmallScreen ? 15.0 : 18.0, fontWeight: FontWeight.w900),
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
                      style: TextStyle(fontSize: isSmallScreen ? 15.0 : 18.0, fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: 'NEWS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 6, offset: const Offset(0, 0)),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: Provider.of<LanguageService>(context).translate('breaking_news_intro'),
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
              widget.players.firstWhere((p) => p.id == playerId, orElse: () => widget.players.first);

              // Determinar si es racha de victorias o derrotas
              final isLossStreak = message.contains('rata asquerosa');
              final backgroundColor = isLossStreak ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2);
              final iconColor = isLossStreak ? Colors.red : Colors.orange;
              final icon = isLossStreak ? Icons.cleaning_services : Icons.emoji_events;

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
                const Color(0xFF228B22).withOpacity(0.4), // Verde oscuro de bosque
                const Color(0xFF32CD32).withOpacity(0.9), // Verde duende brillante
                animationValue,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0xFF228B22).withOpacity(0.2), // Verde oscuro suave
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
                      style: TextStyle(fontSize: isSmallScreen ? 15.0 : 18.0, fontWeight: FontWeight.w900),
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
                      style: TextStyle(fontSize: isSmallScreen ? 15.0 : 18.0, fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: 'NEWS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 15.0 : 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 6, offset: const Offset(0, 0)),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: Provider.of<LanguageService>(context).translate('breaking_news_intro'),
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
                widget.players.firstWhere((p) => p.id == playerId, orElse: () => widget.players.first);

                // Determinar si es racha de victorias o derrotas
                final isLossStreak = message.contains('rata asquerosa');
                final backgroundColor = isLossStreak ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2);
                final iconColor = isLossStreak ? Colors.red : Colors.orange;
                final icon = isLossStreak ? Icons.cleaning_services : Icons.emoji_events;

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
      },
    );
  }

  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, _) {
        final v = _confettiController.value;
        // Solo ocultar cuando esté completamente en 0.0 O cuando haya terminado completamente
        if (v == 0.0 || _confettiController.status == AnimationStatus.completed) {
          // Si está completado, esperar un momento antes de ocultar para que termine el desvanecimiento
          if (_confettiController.status == AnimationStatus.completed) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _confettiController.reset();
              }
            });
          }
          return const SizedBox.shrink();
        }
        return Positioned.fill(
          child: CustomPaint(
            painter: _ConfettiPainter(progress: v),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress; // 0..1
  _ConfettiPainter({required this.progress});

  final List<Color> colors = const [
    Color(0xFFFFD700),
    Color(0xFF00C9FF),
    Color(0xFF92FE9D),
    Color(0xFFFF6B6B),
    Color(0xFF7F5AF0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final count = 80;
    
    // Desvanecimiento gradual en los últimos 2 segundos (0.6 a 1.0)
    double globalOpacity = 1.0;
    if (progress > 0.6) {
      globalOpacity = 1.0 - ((progress - 0.6) / 0.4); // Se desvanece en los últimos 40%
    }
    
    for (int i = 0; i < count; i++) {
      // Las partículas siempre caen hacia abajo
      final t = (i / count + progress * 0.7) % 1.0;
      final x = rnd.nextDouble() * size.width;
      final startY = -50.0 - rnd.nextDouble() * 200.0;
      final y = startY + t * (size.height + 300.0);
      final w = 4.0 + rnd.nextDouble() * 6.0;
      final h = 6.0 + rnd.nextDouble() * 10.0;
      final angle = rnd.nextDouble() * 3.1415;
      
      // Opacidad individual + opacidad global de desvanecimiento
      final individualOpacity = 1.0 - (t * 0.2);
      final finalOpacity = individualOpacity * globalOpacity;
      
      final paint = Paint()..color = colors[i % colors.length].withOpacity(finalOpacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w / 2, -h / 2, w, h), const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
