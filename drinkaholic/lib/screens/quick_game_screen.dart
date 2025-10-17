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

class QuickGameScreen extends StatefulWidget {
  final List<Player> players;

  const QuickGameScreen({super.key, required this.players});

  @override
  State<QuickGameScreen> createState() => _QuickGameScreenState();
}

class _QuickGameScreenState extends State<QuickGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _tapAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _rippleAnimationController;
  late AnimationController _pulseAnimationController;

  late Animation<double> _glowAnimation;
  late Animation<double> _tapAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _rippleAnimation;

  final List<Offset> _ripplePositions = [];
  final List<double> _rippleOpacities = [];

  int _currentPlayerIndex = -1; // Start with no player selected
  int? _dualPlayerIndex; // Second player for dual challenges
  String _currentChallenge = '';
  bool _gameStarted = false;
  final Map<int, int> _playerWeights =
      {}; // Track how many times each player has been selected
  int _currentRound = 1;
  List<ConstantChallenge> _constantChallenges = [];
  ConstantChallengeEnd? _currentChallengeEnd;
  List<Event> _events = [];
  EventEnd? _currentEventEnd;

  @override
  void initState() {
    super.initState();

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _tapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _rippleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _tapAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapAnimationController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.linear,
      ),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _glowAnimationController.repeat(reverse: true);
    _backgroundAnimationController.repeat();
    _pulseAnimationController.repeat(reverse: true);

    // Initialize player weights (all start at 0)
    for (int i = 0; i < widget.players.length; i++) {
      _playerWeights[i] = 0;
    }

    _initializeFirstChallenge();
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _cardAnimationController.dispose();
    _glowAnimationController.dispose();
    _tapAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _rippleAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateNewChallenge() async {
    // Generar pregunta (30% probabilidad de ser genérica con jugador específico)
    if (Random().nextDouble() < 0.3 && widget.players.isNotEmpty) {
      // Seleccionar un jugador aleatorio para la pregunta genérica
      final selectedPlayerIndex = Random().nextInt(widget.players.length);
      final selectedPlayer = widget.players[selectedPlayerIndex];

      final question = await QuestionGenerator.generateRandomQuestionForPlayer(
        selectedPlayer.nombre,
      );

      setState(() {
        _currentChallenge = question.question;
        _currentPlayerIndex = selectedPlayerIndex;
      });
    } else {
      // Pregunta normal (sin jugador específico, se asignará después)
      final question = await QuestionGenerator.generateRandomQuestion();
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
    if (!gameState.isChallengeForAll &&
        !_isGenericPlayerQuestion() &&
        !gameState.isDualChallenge) {
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
        _currentPlayerIndex < widget.players.length &&
        (_currentChallenge.contains(
              '${widget.players[_currentPlayerIndex].nombre} bebe',
            ) ||
            _currentChallenge.contains(
              '${widget.players[_currentPlayerIndex].nombre} reparte',
            ));
  }

  void _selectWeightedRandomPlayer() {
    // Find the minimum weight (players who have been selected least)
    int minWeight = _playerWeights.values.reduce((a, b) => a < b ? a : b);

    // Create a list of players with minimum weight (most eligible)
    List<int> eligiblePlayers = [];
    _playerWeights.forEach((playerIndex, weight) {
      if (weight == minWeight) {
        eligiblePlayers.add(playerIndex);
      }
    });

    // If all players have been selected equally, include players with minWeight + 1
    if (eligiblePlayers.length < widget.players.length ~/ 2) {
      _playerWeights.forEach((playerIndex, weight) {
        if (weight == minWeight + 1 && !eligiblePlayers.contains(playerIndex)) {
          eligiblePlayers.add(playerIndex);
        }
      });
    }

    // Randomly select from eligible players
    int selectedPlayer =
        eligiblePlayers[Random().nextInt(eligiblePlayers.length)];

    setState(() {
      _currentPlayerIndex = selectedPlayer;
      // Increment the weight for the selected player
      _playerWeights[selectedPlayer] =
          (_playerWeights[selectedPlayer] ?? 0) + 1;
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
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: FloatingShapesPainter(_backgroundAnimation.value),
            child: Container(),
          );
        },
      ),
    );
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
            final opacity = _rippleOpacities.length > index
                ? _rippleOpacities[index]
                : 0.0;
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
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      opacity * (1 - animationValue) * 0.6,
                    ),
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFloatingParticle(
    double screenWidth,
    double screenHeight,
    int index,
  ) {
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
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
    if (gameState.canHaveEvents &&
        EventGenerator.shouldGenerateEvent(
          _currentRound,
          gameState.activeEvents,
        )) {
      await _generateNewEvent();
      return;
    }

    // 6. Verificar si debemos generar un nuevo reto constante (incluyendo duales)
    if (gameState.canHaveConstantChallenges &&
        ConstantChallengeGenerator.shouldGenerateConstantChallenge(
          _currentRound,
          gameState.activeChallenges,
        )) {
      // 20% probabilidad de reto constante dual si hay suficientes jugadores
      if (widget.players.length >= 2 && math.Random().nextDouble() < 0.2) {
        await _generateNewDualConstantChallenge();
      } else {
        await _generateNewConstantChallenge();
      }
      return;
    }

    // 7. Si no hay eventos ni retos constantes, generar un reto normal (incluyendo duales)
    // 15% probabilidad de challenge dual si hay suficientes jugadores
    if (widget.players.length >= 2 && math.Random().nextDouble() < 0.15) {
      await _generateNewDualChallenge();
    } else {
      await _generateNewChallenge();
    }

    // 8. Solo selecciona jugador si el reto NO es para todos Y no es una pregunta genérica ya asignada Y no es un reto dual
    final gameState2 = _createGameState();
    if (!gameState2.isChallengeForAll &&
        !_isGenericPlayerQuestion() &&
        !gameState2.isDualChallenge) {
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
    final activeChallenges = _constantChallenges
        .where((c) => c.isActiveAtRound(_currentRound))
        .toList();

    for (final challenge in activeChallenges) {
      if (ConstantChallengeGenerator.shouldEndConstantChallenge(
        challenge,
        _currentRound,
      )) {
        final challengeEnd = ConstantChallengeGenerator.generateChallengeEnd(
          challenge,
          _currentRound,
        );

        setState(() {
          // Marcar el reto como terminado
          _constantChallenges = _constantChallenges.map((c) {
            if (c.id == challenge.id) {
              return c.copyWith(
                status: ConstantChallengeStatus.ended,
                endRound: _currentRound,
              );
            }
            return c;
          }).toList();

          _currentChallengeEnd = challengeEnd;
          _currentChallenge = challengeEnd.endDescription;
          _currentPlayerIndex =
              -1; // No hay jugador específico para este tipo de mensaje
        });

        return; // Solo terminamos un reto por ronda
      }
    }
  }

  Future<void> _generateNewConstantChallenge() async {
    final eligiblePlayer =
        ConstantChallengeGenerator.selectPlayerForNewChallenge(
          widget.players,
          _constantChallenges
              .where((c) => c.isActiveAtRound(_currentRound))
              .toList(),
        );

    if (eligiblePlayer == null) {
      // No hay jugadores elegibles, generar reto normal en su lugar
      await _generateNewChallenge();
      return;
    }

    final constantChallenge =
        await ConstantChallengeGenerator.generateRandomConstantChallenge(
          eligiblePlayer,
          _currentRound,
        );

    setState(() {
      _constantChallenges.add(constantChallenge);
      _currentChallenge = constantChallenge.description;
      _currentPlayerIndex = widget.players.indexWhere(
        (p) => p.id == eligiblePlayer.id,
      );
    });
  }

  Future<void> _checkForEventEnding() async {
    final activeEvents = _events
        .where((e) => e.isActiveAtRound(_currentRound))
        .toList();

    for (final event in activeEvents) {
      if (EventGenerator.shouldEndEvent(event, _currentRound)) {
        final eventEnd = EventGenerator.generateEventEnd(event, _currentRound);

        setState(() {
          // Marcar el evento como terminado
          _events = _events.map((e) {
            if (e.id == event.id) {
              return e.copyWith(
                status: EventStatus.ended,
                endRound: _currentRound,
              );
            }
            return e;
          }).toList();

          _currentEventEnd = eventEnd;
          _currentChallenge = eventEnd.endDescription;
          _currentPlayerIndex =
              -1; // Eventos son globales, no hay jugador específico
        });

        return; // Solo terminamos un evento por ronda
      }
    }
  }

  Future<void> _generateNewEvent() async {
    final event = await EventGenerator.generateRandomEvent(_currentRound);

    setState(() {
      _events.add(event);
      _currentChallenge =
          '${event.typeIcon} ${event.title}: ${event.description}';
      _currentPlayerIndex =
          -1; // Eventos son globales, no hay jugador específico
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

    final question = await QuestionGenerator.generateRandomDualQuestion(
      player1.nombre,
      player2.nombre,
    );

    final player1Index = widget.players.indexOf(player1);
    final player2Index = widget.players.indexOf(player2);

    setState(() {
      _currentChallenge = question.question;
      _currentPlayerIndex = player1Index;
      _dualPlayerIndex = player2Index;

      // Incrementar pesos para ambos jugadores
      _playerWeights[_currentPlayerIndex] =
          (_playerWeights[_currentPlayerIndex] ?? 0) + 1;
      _playerWeights[_dualPlayerIndex!] =
          (_playerWeights[_dualPlayerIndex!] ?? 0) + 1;
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

    final constantChallenge =
        await ConstantChallengeGenerator.generateRandomDualConstantChallenge(
          player1,
          player2,
          _currentRound,
        );

    setState(() {
      _constantChallenges.add(constantChallenge);
      _currentChallenge = constantChallenge.description;
      _currentPlayerIndex = widget.players.indexOf(player1);
      _dualPlayerIndex = widget.players.indexOf(player2);
    });
  }

  List<Player> _selectTwoRandomPlayers() {
    if (widget.players.length < 2) return [];

    // Crear una lista de jugadores elegibles basada en pesos
    List<Player> eligiblePlayers = [];

    // Encontrar el peso mínimo
    int minWeight = _playerWeights.values.isEmpty
        ? 0
        : _playerWeights.values.reduce((a, b) => a < b ? a : b);

    // Añadir jugadores con peso mínimo
    for (int i = 0; i < widget.players.length; i++) {
      int weight = _playerWeights[i] ?? 0;
      if (weight <= minWeight + 1) {
        // Permitir hasta 1 más que el mínimo
        eligiblePlayers.add(widget.players[i]);
      }
    }

    // Si no hay suficientes jugadores elegibles, usar todos
    if (eligiblePlayers.length < 2) {
      eligiblePlayers = List.from(widget.players);
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
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: iconSize,
                            ),
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
                                    final RenderBox renderBox =
                                        context.findRenderObject() as RenderBox;
                                    final localPosition = renderBox
                                        .globalToLocal(details.globalPosition);
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              buildCenterContent(
                                                _createGameState(),
                                              ),
                                              const SizedBox(height: 0),
                                              // Tap indicator (only show at the beginning)
                                              if (!_gameStarted)
                                                AnimatedBuilder(
                                                  animation: _glowAnimation,
                                                  builder: (context, child) {
                                                    return Container(
                                                      padding: EdgeInsets.all(
                                                        7,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              25,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                _glowAnimation
                                                                        .value *
                                                                    0.8,
                                                              ),
                                                          width: 2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  _glowAnimation
                                                                          .value *
                                                                      0.3,
                                                                ),
                                                            blurRadius: 15,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.touch_app,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  _glowAnimation
                                                                      .value,
                                                                ),
                                                            size: 25,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            'TOCA LA PANTALLA',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    _glowAnimation
                                                                        .value,
                                                                  ),
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  1.2,
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
              ],
            );
          },
        ),
      ),
    );
  }
}

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

class FloatingShapesPainter extends CustomPainter {
  final double animationValue;

  FloatingShapesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create multiple floating shapes with different speeds and sizes
    final shapes = [
      // Large circles
      _FloatingShape(
        Offset(
          size.width * 0.1 + (sin(animationValue * 2 * pi) * 30),
          size.height * 0.2 + (cos(animationValue * 2 * pi) * 20),
        ),
        30,
        Colors.white.withOpacity(0.05),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.8 + (sin(animationValue * 2 * pi + 1) * 40),
          size.height * 0.7 + (cos(animationValue * 2 * pi + 1) * 30),
        ),
        25,
        Colors.white.withOpacity(0.08),
      ),
      // Medium circles
      _FloatingShape(
        Offset(
          size.width * 0.3 + (sin(animationValue * 2 * pi + 2) * 50),
          size.height * 0.5 + (cos(animationValue * 2 * pi + 2) * 25),
        ),
        20,
        Colors.white.withOpacity(0.04),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.7 + (sin(animationValue * 2 * pi + 3) * 35),
          size.height * 0.3 + (cos(animationValue * 2 * pi + 3) * 40),
        ),
        18,
        Colors.cyan.withOpacity(0.06),
      ),
      // Small circles
      _FloatingShape(
        Offset(
          size.width * 0.5 + (sin(animationValue * 2 * pi + 4) * 60),
          size.height * 0.8 + (cos(animationValue * 2 * pi + 4) * 15),
        ),
        12,
        Colors.white.withOpacity(0.03),
      ),
      _FloatingShape(
        Offset(
          size.width * 0.9 + (sin(animationValue * 2 * pi + 5) * 25),
          size.height * 0.1 + (cos(animationValue * 2 * pi + 5) * 35),
        ),
        15,
        Colors.green.withOpacity(0.05),
      ),
    ];

    // Draw all shapes
    for (final shape in shapes) {
      paint.color = shape.color;
      canvas.drawCircle(shape.position, shape.radius, paint);
    }

    // Add some triangular shapes for variety
    final trianglePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final trianglePath = Path();
    final triangleCenter = Offset(
      size.width * 0.6 + (sin(animationValue * 2 * pi + 6) * 45),
      size.height * 0.4 + (cos(animationValue * 2 * pi + 6) * 30),
    );

    trianglePath.moveTo(triangleCenter.dx, triangleCenter.dy - 15);
    trianglePath.lineTo(triangleCenter.dx - 13, triangleCenter.dy + 10);
    trianglePath.lineTo(triangleCenter.dx + 13, triangleCenter.dy + 10);
    trianglePath.close();

    canvas.drawPath(trianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(FloatingShapesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _FloatingShape {
  final Offset position;
  final double radius;
  final Color color;

  _FloatingShape(this.position, this.radius, this.color);
}
