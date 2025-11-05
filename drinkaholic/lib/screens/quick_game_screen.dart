import 'package:drinkaholic/models/question_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:math' as math show Random;
import '../models/player.dart';
import '../models/game_state.dart';
import '../models/constant_challenge.dart';
import '../models/constant_challenge_generator.dart';
import '../models/event.dart';
import '../models/event_generator.dart';
import '../widgets/quick_game_widgets.dart'; // Añade este import arriba
import '../widgets/common/animated_background.dart';

class QuickGameScreen extends StatefulWidget {
  final List<Player> players;

  const QuickGameScreen({super.key, required this.players});

  @override
  State<QuickGameScreen> createState() => _QuickGameScreenState();
}

class _QuickGameScreenState extends State<QuickGameScreen> with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _tapAnimationController;
  late AnimationController _rippleAnimationController;
  late AnimationController _pulseAnimationController;

  late Animation<double> _glowAnimation;
  late Animation<double> _tapAnimation;
  late Animation<double> _rippleAnimation;

  final List<Offset> _ripplePositions = [];
  final List<double> _rippleOpacities = [];

  // Mutable players list to allow mid-game edits
  late List<Player> _players;

  int _currentPlayerIndex = -1; // Start with no player selected
  int? _dualPlayerIndex; // Second player for dual challenges
  String _currentChallenge = '';
  bool _gameStarted = false;
  // Track how many times each player has been selected, keyed by playerId
  final Map<int, int> _playerWeights = {};
  // Track already used questions to avoid repeats within this game session
  final Set<String> _usedQuestions = <String>{};
  int _currentRound = 1;
  List<ConstantChallenge> _constantChallenges = [];
  ConstantChallengeEnd? _currentChallengeEnd;
  List<Event> _events = [];
  EventEnd? _currentEventEnd;

  @override
  void initState() {
    super.initState();

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    // Initialize local players list
    _players = List<Player>.from(widget.players);

    _cardAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _glowAnimationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _tapAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _rippleAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _pulseAnimationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowAnimationController, curve: Curves.easeInOut));

    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _tapAnimationController, curve: Curves.easeInOut));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _rippleAnimationController, curve: Curves.easeOut));

    _glowAnimationController.repeat(reverse: true);
    _pulseAnimationController.repeat(reverse: true);

    // Initialize player weights (all start at 0) keyed by playerId
    for (final p in _players) {
      _playerWeights[p.id] = 0;
    }

    _initializeFirstChallenge();
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _cardAnimationController.dispose();
    _glowAnimationController.dispose();
    _tapAnimationController.dispose();
    _rippleAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateNewChallenge() async {
    // Generar pregunta (30% probabilidad de ser genérica con jugador específico)
    if (Random().nextDouble() < 0.3 && _players.isNotEmpty) {
      // Seleccionar un jugador aleatorio para la pregunta genérica
      final selectedPlayerIndex = Random().nextInt(_players.length);
      final selectedPlayer = _players[selectedPlayerIndex];

      // Intentar generar una pregunta única evitando repetidas
      var attempts = 0;
      GeneratedQuestion question;
      do {
        question = await QuestionGenerator.generateRandomQuestionForPlayer(selectedPlayer.nombre);
        attempts++;
      } while (_usedQuestions.contains(question.question) && attempts < 30);
      _usedQuestions.add(question.question);

      setState(() {
        _currentChallenge = question.question;
        _currentPlayerIndex = selectedPlayerIndex;
      });
    } else {
      // Pregunta normal (sin jugador específico, se asignará después)
      var attempts = 0;
      GeneratedQuestion question;
      do {
        question = await QuestionGenerator.generateRandomQuestion();
        attempts++;
      } while (_usedQuestions.contains(question.question) && attempts < 30);
      _usedQuestions.add(question.question);

      setState(() {
        _currentChallenge = question.question;
        _currentPlayerIndex = -1; // Marcar que no hay jugador asignado aún
      });
    }
  }

  Future<void> _initializeFirstChallenge() async {
    await _generateNewChallenge();

    // Solo selecciona jugador si el reto NO es para todos Y no es una pregunta genérica ya asignada Y no es un reto dual
    final gameState = _createGameState();
    if (!gameState.isChallengeForAll && !_isGenericPlayerQuestion() && !gameState.isDualChallenge) {
      _selectWeightedRandomPlayer();
    } else if (gameState.isChallengeForAll) {
      // Para desafíos que son para todos, mantener _currentPlayerIndex en -1
      setState(() {
        _currentPlayerIndex = -1;
      });
    }
    // Si es una pregunta genérica, el jugador ya fue asignado en _generateNewChallenge
  }

  GameState _createGameState() {
    // Get dual player names if it's a dual challenge
    String? dualPlayer1Name;
    String? dualPlayer2Name;

    if (_dualPlayerIndex != null && _currentPlayerIndex >= 0) {
      // Get names from player indices
      if (_currentPlayerIndex < widget.players.length) {
        dualPlayer1Name = widget.players[_currentPlayerIndex].nombre;
      }
      if (_dualPlayerIndex! < widget.players.length) {
        dualPlayer2Name = widget.players[_dualPlayerIndex!].nombre;
      }
    }

    return GameState(
      players: widget.players,
      currentPlayerIndex: _currentPlayerIndex,
      currentChallenge: _currentChallenge,
      glowAnimation: _glowAnimation,
      playerWeights: _playerWeights,
      gameStarted: _gameStarted,
      currentGift: null,
      currentRound: _currentRound,
      constantChallenges: _constantChallenges,
      currentChallengeEnd: _currentChallengeEnd,
      events: _events,
      currentEventEnd: _currentEventEnd,
      dualPlayerIndex: _dualPlayerIndex,
      dualPlayer1Name: dualPlayer1Name,
      dualPlayer2Name: dualPlayer2Name,
    );
  }

  bool _isGenericPlayerQuestion() {
    if (_currentChallenge.isEmpty) return false;

    // Una pregunta genérica es aquella donde ya se asignó un jugador específico
    // y el _currentPlayerIndex es válido (no -1)
    return _currentPlayerIndex >= 0 &&
        _currentPlayerIndex < _players.length &&
        (_currentChallenge.contains('${_players[_currentPlayerIndex].nombre} bebe') ||
            _currentChallenge.contains('${_players[_currentPlayerIndex].nombre} reparte'));
  }

  void _selectWeightedRandomPlayer() {
    // Find the minimum weight (players who have been selected least)
    final minWeight = _playerWeights.values.isEmpty ? 0 : _playerWeights.values.reduce((a, b) => a < b ? a : b);

    // Build list of eligible indices based on playerId weights
    final List<int> eligibleIndices = [];
    for (int i = 0; i < _players.length; i++) {
      final id = _players[i].id;
      final w = _playerWeights[id] ?? 0;
      if (w == minWeight) eligibleIndices.add(i);
    }

    // If not enough, include players with minWeight + 1
    if (eligibleIndices.length < (_players.length ~/ 2)) {
      for (int i = 0; i < _players.length; i++) {
        if (!eligibleIndices.contains(i)) {
          final id = _players[i].id;
          final w = _playerWeights[id] ?? 0;
          if (w == minWeight + 1) eligibleIndices.add(i);
        }
      }
    }

    if (eligibleIndices.isEmpty) {
      // fallback to any player
      for (int i = 0; i < _players.length; i++) {
        eligibleIndices.add(i);
      }
    }

    // Randomly select from eligible indices
    final selectedIndex = eligibleIndices[Random().nextInt(eligibleIndices.length)];

    setState(() {
      _currentPlayerIndex = selectedIndex;
      // Increment the weight for the selected playerId
      final pid = _players[selectedIndex].id;
      _playerWeights[pid] = (_playerWeights[pid] ?? 0) + 1;
    });
  }

  void _addRippleEffect(Offset position) {
    if (_rippleAnimationController.isAnimating) return; // Prevent duplicates

    setState(() {
      _ripplePositions.clear(); // Clear previous ripples
      _rippleOpacities.clear();
      _ripplePositions.add(position);
      _rippleOpacities.add(1.0);
    });

    _rippleAnimationController.reset();
    _rippleAnimationController.forward().then((_) {
      setState(() {
        _ripplePositions.clear();
        _rippleOpacities.clear();
      });
    });
  }

  Widget _buildAnimatedBackground() {
    return const AnimatedBackground();
  }

  Widget _buildRippleEffects() {
    if (_ripplePositions.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return Stack(
          children: _ripplePositions.asMap().entries.map((entry) {
            final index = entry.key;
            final position = entry.value;
            final opacity = _rippleOpacities.length > index ? _rippleOpacities[index] : 0.0;
            final animationValue = _rippleAnimation.value;
            final size = 150.0 * animationValue;

            return Positioned(
              left: position.dx - (size / 2),
              top: position.dy - (size / 2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(opacity * (1 - animationValue) * 0.6), width: 3),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFloatingParticle(double screenWidth, double screenHeight, int index) {
    final random = (index * 1234) % 1000;
    final size = 4.0 + (random % 8);
    final left = (random * 0.7) % screenWidth;
    final top = (random * 0.8) % screenHeight;
    final opacity = 0.1 + (random % 40) / 100;

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 3000 + (random % 2000)),
        tween: Tween<double>(begin: 0, end: 1),
        onEnd: () {
          // Restart animation
        },
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -value * 50),
            child: Opacity(
              opacity: opacity * (1 - value),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _nextChallenge() async {
    // Play tap animation
    _tapAnimationController.forward().then((_) {
      _tapAnimationController.reverse();
    });

    setState(() {
      _gameStarted = true;
      _currentRound++; // Incrementar el contador de rondas
      _currentChallengeEnd = null; // Limpiar cualquier fin de reto constante
      _currentEventEnd = null; // Limpiar cualquier fin de evento
      _dualPlayerIndex = null; // Limpiar jugador dual previo
    });

    // 1. Verificar si debemos terminar algún evento
    await _checkForEventEnding();

    // 2. Si estamos mostrando un fin de evento, no generamos nuevo reto
    if (_currentEventEnd != null) {
      return;
    }

    // 3. Verificar si debemos terminar algún reto constante
    await _checkForConstantChallengeEnding();

    // 4. Si estamos mostrando un fin de reto, no generamos nuevo reto normal
    if (_currentChallengeEnd != null) {
      return;
    }

    // 5. Verificar si debemos generar un nuevo evento (prioridad alta)
    final gameState = _createGameState();
    if (gameState.canHaveEvents && EventGenerator.shouldGenerateEvent(_currentRound, gameState.activeEvents)) {
      await _generateNewEvent();
      return;
    }

    // 6. Verificar si debemos generar un nuevo reto constante (incluyendo duales)
    if (gameState.canHaveConstantChallenges &&
        ConstantChallengeGenerator.shouldGenerateConstantChallenge(_currentRound, gameState.activeChallenges)) {
      // 20% probabilidad de reto constante dual si hay suficientes jugadores
      if (_players.length >= 2 && math.Random().nextDouble() < 0.2) {
        await _generateNewDualConstantChallenge();
      } else {
        await _generateNewConstantChallenge();
      }
      return;
    }

    // 7. Si no hay eventos ni retos constantes, generar un reto normal (incluyendo duales)
    // 15% probabilidad de challenge dual si hay suficientes jugadores
    if (_players.length >= 2 && math.Random().nextDouble() < 0.15) {
      await _generateNewDualChallenge();
    } else {
      await _generateNewChallenge();
    }

    // 8. Solo selecciona jugador si el reto NO es para todos Y no es una pregunta genérica ya asignada Y no es un reto dual
    final gameState2 = _createGameState();
    if (!gameState2.isChallengeForAll && !_isGenericPlayerQuestion() && !gameState2.isDualChallenge) {
      _selectWeightedRandomPlayer();
    } else if (gameState2.isChallengeForAll) {
      setState(() {
        _currentPlayerIndex = -1; // Valor especial para "todos"
      });
    }
    // Si es un reto dual, los jugadores ya fueron asignados en _generateNewDualChallenge
    // Si es una pregunta genérica, el jugador ya fue asignado en _generateNewChallenge
  }

  Future<void> _checkForConstantChallengeEnding() async {
    final activeChallenges = _constantChallenges.where((c) => c.isActiveAtRound(_currentRound)).toList();

    for (final challenge in activeChallenges) {
      if (ConstantChallengeGenerator.shouldEndConstantChallenge(challenge, _currentRound)) {
        final challengeEnd = ConstantChallengeGenerator.generateChallengeEnd(challenge, _currentRound);

        setState(() {
          // Marcar el reto como terminado
          _constantChallenges = _constantChallenges.map((c) {
            if (c.id == challenge.id) {
              return c.copyWith(status: ConstantChallengeStatus.ended, endRound: _currentRound);
            }
            return c;
          }).toList();

          _currentChallengeEnd = challengeEnd;
          _currentChallenge = challengeEnd.endDescription;
          _currentPlayerIndex = -1; // No hay jugador específico para este tipo de mensaje
        });

        return; // Solo terminamos un reto por ronda
      }
    }
  }

  Future<void> _generateNewConstantChallenge() async {
    final eligiblePlayer = ConstantChallengeGenerator.selectPlayerForNewChallenge(
      _players,
      _constantChallenges.where((c) => c.isActiveAtRound(_currentRound)).toList(),
    );

    if (eligiblePlayer == null) {
      // No hay jugadores elegibles, generar reto normal en su lugar
      await _generateNewChallenge();
      return;
    }

    final constantChallenge = await ConstantChallengeGenerator.generateRandomConstantChallenge(
      eligiblePlayer,
      _currentRound,
    );

    setState(() {
      _constantChallenges.add(constantChallenge);
      _currentChallenge = constantChallenge.description;
      _currentPlayerIndex = _players.indexWhere((p) => p.id == eligiblePlayer.id);
    });
  }

  Future<void> _checkForEventEnding() async {
    final activeEvents = _events.where((e) => e.isActiveAtRound(_currentRound)).toList();

    for (final event in activeEvents) {
      if (EventGenerator.shouldEndEvent(event, _currentRound)) {
        final eventEnd = EventGenerator.generateEventEnd(event, _currentRound);

        setState(() {
          // Marcar el evento como terminado
          _events = _events.map((e) {
            if (e.id == event.id) {
              return e.copyWith(status: EventStatus.ended, endRound: _currentRound);
            }
            return e;
          }).toList();

          _currentEventEnd = eventEnd;
          _currentChallenge = eventEnd.endDescription;
          _currentPlayerIndex = -1; // Eventos son globales, no hay jugador específico
        });

        return; // Solo terminamos un evento por ronda
      }
    }
  }

  Future<void> _generateNewEvent() async {
    final event = await EventGenerator.generateRandomEvent(_currentRound);

    setState(() {
      _events.add(event);
      _currentChallenge = '${event.typeIcon} ${event.title}: ${event.description}';
      _currentPlayerIndex = -1; // Eventos son globales, no hay jugador específico
    });
  }

  Future<void> _generateNewDualChallenge() async {
    // Seleccionar dos jugadores diferentes
    final selectedPlayers = _selectTwoRandomPlayers();
    if (selectedPlayers.length < 2) {
      // Fallback a challenge normal si no hay suficientes jugadores
      await _generateNewChallenge();
      return;
    }

    final player1 = selectedPlayers[0];
    final player2 = selectedPlayers[1];

    // Intentar generar una pregunta dual única evitando repetidas
    var attempts = 0;
    GeneratedQuestion question;
    do {
      question = await QuestionGenerator.generateRandomDualQuestion(player1.nombre, player2.nombre);
      attempts++;
    } while (_usedQuestions.contains(question.question) && attempts < 30);
    _usedQuestions.add(question.question);

    final player1Index = _players.indexOf(player1);
    final player2Index = _players.indexOf(player2);

    setState(() {
      _currentChallenge = question.question;
      _currentPlayerIndex = player1Index;
      _dualPlayerIndex = player2Index;

      // Incrementar pesos para ambos jugadores por playerId
      final id1 = _players[_currentPlayerIndex].id;
      final id2 = _players[_dualPlayerIndex!].id;
      _playerWeights[id1] = (_playerWeights[id1] ?? 0) + 1;
      _playerWeights[id2] = (_playerWeights[id2] ?? 0) + 1;
    });
  }

  Future<void> _generateNewDualConstantChallenge() async {
    // Seleccionar dos jugadores diferentes
    final selectedPlayers = _selectTwoRandomPlayers();
    if (selectedPlayers.length < 2) {
      // Fallback a challenge constante normal
      await _generateNewConstantChallenge();
      return;
    }

    final player1 = selectedPlayers[0];
    final player2 = selectedPlayers[1];

    final constantChallenge = await ConstantChallengeGenerator.generateRandomDualConstantChallenge(
      player1,
      player2,
      _currentRound,
    );

    setState(() {
      _constantChallenges.add(constantChallenge);
      _currentChallenge = constantChallenge.description;
      _currentPlayerIndex = _players.indexOf(player1);
      _dualPlayerIndex = _players.indexOf(player2);
    });
  }

  List<Player> _selectTwoRandomPlayers() {
    if (_players.length < 2) return [];

    // Crear una lista de jugadores elegibles basada en pesos
    List<Player> eligiblePlayers = [];

    // Encontrar el peso mínimo
    int minWeight = _playerWeights.values.isEmpty ? 0 : _playerWeights.values.reduce((a, b) => a < b ? a : b);

    // Añadir jugadores con peso <= min+1
    for (final p in _players) {
      final weight = _playerWeights[p.id] ?? 0;
      if (weight <= minWeight + 1) {
        eligiblePlayers.add(p);
      }
    }

    // Si no hay suficientes jugadores elegibles, usar todos
    if (eligiblePlayers.length < 2) {
      eligiblePlayers = List.from(_players);
    }

    // Seleccionar dos jugadores diferentes aleatoriamente
    eligiblePlayers.shuffle(math.Random());
    return eligiblePlayers.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = getResponsiveSize(
              context,
              small: 35, // Aumentado de 28
              medium: 40, // Aumentado de 35
              large: 50, // Aumentado de 45
            );

            getResponsiveSize(
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

            final containerMargin = getResponsiveSize(
              context,
              small: 200, // Nuevo valor
              medium: 250, // Nuevo valor
              large: 400, // Nuevo valor
            );

            return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF00C9FF), // Cyan
                        Color(0xFF92FE9D), // Green
                      ],
                    ),
                  ),
                ),
                _buildAnimatedBackground(),
                // Floating particles effect like home_screen
                ...List.generate(
                  8,
                  (index) => _buildFloatingParticle(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                    index,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            margin: EdgeInsets.only(bottom: containerMargin),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
                          ),
                        ),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _tapAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _tapAnimation.value,
                                child: GestureDetector(
                                  onTapDown: (details) {
                                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                    final localPosition = renderBox.globalToLocal(details.globalPosition);
                                    _addRippleEffect(localPosition);
                                  },
                                  onTap: _nextChallenge,
                                  behavior: HitTestBehavior.opaque,
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              buildCenterContent(_createGameState()),
                                              const SizedBox(height: 0),
                                              // Tap indicator (only show at the beginning)
                                              if (!_gameStarted)
                                                AnimatedBuilder(
                                                  animation: _glowAnimation,
                                                  builder: (context, child) {
                                                    return Container(
                                                      padding: EdgeInsets.all(7),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(25),
                                                        border: Border.all(
                                                          color: Colors.white.withOpacity(_glowAnimation.value * 0.8),
                                                          width: 2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
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
                                                            color: Colors.white.withOpacity(_glowAnimation.value),
                                                            size: 25,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            'TOCA LA PANTALLA',
                                                            style: TextStyle(
                                                              color: Colors.white.withOpacity(_glowAnimation.value),
                                                              fontSize: 15,
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
                                      _buildRippleEffects(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // // Players row
                        //  SizedBox(
                        //    width: 50,
                        //    child: Column(
                        //      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //      children: widget.players.asMap().entries.map((entry) {
                        //        final index = entry.key;
                        //        final player = entry.value;
                        //        return Column(
                        //          mainAxisAlignment: MainAxisAlignment.center,
                        //          children: [
                        //            _buildPlayerAvatar(
                        //              player,
                        //              isActive: index == _currentPlayerIndex,
                        //            ),
                        //            const SizedBox(height: 5),
                        //            Text(
                        //              player.nombre,
                        //              style: TextStyle(
                        //                color: index == _currentPlayerIndex
                        //                    ? Colors.white
                        //                    : Colors.white.withOpacity(0.7),
                        //                fontSize: 14,
                        //                fontWeight: index == _currentPlayerIndex
                        //                    ? FontWeight.bold
                        //                    : FontWeight.normal,
                        //              ),
                        //              textAlign: TextAlign.center,
                        //            ),
                        //          ],
                        //        );
                        //      }).toList(),
                        //    ),
                        //  ),
                      ],
                    ),
                  ),
                ),
                // Edit players button (top-right)
                Positioned(
                  top: padding,
                  right: padding,
                  child: GestureDetector(
                    onTap: _openPlayerManager,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(Icons.group, color: Colors.white, size: iconSize),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openPlayerManager() async {
    final updated = await showModalBottomSheet<List<Player>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        List<Player> temp = List<Player>.from(_players);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white24),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.group, color: Colors.white),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Editar jugadores',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Añadir jugador...',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isEmpty) return;
                                  setModalState(() {
                                    temp.add(Player(id: _nextPlayerId(temp), nombre: value.trim()));
                                  });
                                  controller.clear();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final value = controller.text.trim();
                                if (value.isEmpty) return;
                                setModalState(() {
                                  temp.add(Player(id: _nextPlayerId(temp), nombre: value));
                                });
                                controller.clear();
                              },
                              child: const Text('Añadir'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: temp.length,
                          itemBuilder: (context, index) {
                            final p = temp[index];
                            return ListTile(
                              title: Text(p.nombre, style: const TextStyle(color: Colors.white)),
                              onTap: () async {
                                final tc = TextEditingController(text: p.nombre);
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Renombrar jugador'),
                                      content: TextField(
                                        controller: tc,
                                        autofocus: true,
                                        decoration: const InputDecoration(hintText: 'Nombre'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, tc.text.trim()),
                                          child: const Text('Guardar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (newName != null && newName.isNotEmpty) {
                                  setModalState(() {
                                    temp[index] = Player(id: p.id, nombre: newName, imagen: p.imagen, avatar: p.avatar);
                                  });
                                }
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                    onPressed: () async {
                                      final tc = TextEditingController(text: p.nombre);
                                      final newName = await showDialog<String>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Renombrar jugador'),
                                            content: TextField(
                                              controller: tc,
                                              autofocus: true,
                                              decoration: const InputDecoration(hintText: 'Nombre'),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, tc.text.trim()),
                                                child: const Text('Guardar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (newName != null && newName.isNotEmpty) {
                                        setModalState(() {
                                          temp[index] = Player(
                                            id: p.id,
                                            nombre: newName,
                                            imagen: p.imagen,
                                            avatar: p.avatar,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      setModalState(() {
                                        temp.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, temp),
                            child: const Text('Listo'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (updated != null) {
      _applyPlayersUpdate(updated);
    }
  }

  int _nextPlayerId(List<Player> list) {
    final ids = list.map((e) => e.id);
    final maxId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  void _applyPlayersUpdate(List<Player> newPlayers) {
    setState(() {
      // Preserve weights for existing ids
      final oldWeights = Map<int, int>.from(_playerWeights);
      _players = List<Player>.from(newPlayers);
      _playerWeights.clear();
      for (final p in _players) {
        _playerWeights[p.id] = oldWeights[p.id] ?? 0;
      }

      // Re-map current indices to new list based on player id
      int? newCurrent;
      int? newDual;
      if (_currentPlayerIndex >= 0 && _currentPlayerIndex < _players.length) {
        final prevId = (_currentPlayerIndex >= 0 && _currentPlayerIndex < _players.length)
            ? _players[_currentPlayerIndex].id
            : null;
        if (prevId != null) {
          newCurrent = _players.indexWhere((p) => p.id == prevId);
        }
      }
      if (_dualPlayerIndex != null && _dualPlayerIndex! >= 0 && _dualPlayerIndex! < _players.length) {
        final prevId2 = _players[_dualPlayerIndex!].id;
        newDual = _players.indexWhere((p) => p.id == prevId2);
      }
      _currentPlayerIndex = (newCurrent != null && newCurrent >= 0) ? newCurrent : -1;
      _dualPlayerIndex = (newDual != null && newDual >= 0) ? newDual : null;
    });
  }
}

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
