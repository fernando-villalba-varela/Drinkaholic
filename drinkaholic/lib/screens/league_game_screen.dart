import 'package:drinkaholic/models/question_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:math' as math show Random;
import 'dart:async';
import '../models/player.dart';
import '../models/game_state.dart';
import '../models/constant_challenge.dart';
import '../models/constant_challenge_generator.dart';
import '../models/event.dart';
import '../models/event_generator.dart';
import '../widgets/common/animated_background.dart';
import '../widgets/league/game/game_card_widget.dart';
import '../widgets/league/game/player_selector_overlay.dart';
import '../widgets/league/game/letter_counter_overlay.dart';
import '../screens/tiebreaker_screen.dart';

class LeagueGameScreen extends StatefulWidget {
  final List<Player> players;
  final int maxRounds;
  final Function(Map<int, int>) onGameEnd; // Map de playerId -> drinks

  const LeagueGameScreen({super.key, required this.players, required this.maxRounds, required this.onGameEnd});

  @override
  State<LeagueGameScreen> createState() => _LeagueGameScreenState();
}

class _LeagueGameScreenState extends State<LeagueGameScreen> with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _tapAnimationController;
  late AnimationController _rippleAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _tapAnimation;
  late Animation<double> _rippleAnimation;

  // Overlay para suavizar el cambio de orientación
  late AnimationController _orientationFadeController;
  late Animation<double> _orientationFade;
  bool _showOrientationOverlay = true;

  final List<Offset> _ripplePositions = [];
  final List<double> _rippleOpacities = [];

  int _currentPlayerIndex = -1;
  int? _dualPlayerIndex;
  String _currentChallenge = '';
  String? _currentAnswer; // Respuesta a la pregunta actual si existe
  bool _gameStarted = false;
  final Map<int, int> _playerWeights = {};
  final Map<int, int> _playerDrinks = {}; // Contador de tragos por jugador
  // Track already used questions to avoid repeats within this league game session
  final Set<String> _usedQuestions = <String>{};

  int _currentRound = 1;
  List<ConstantChallenge> _constantChallenges = [];
  ConstantChallengeEnd? _currentChallengeEnd;
  List<Event> _events = [];
  EventEnd? _currentEventEnd;
  bool _showingPlayerSelector = false;
  bool _showingLetterCounter = false;
  List<int> _selectedPlayerIdsForLetterCounter = []; // Guardar IDs seleccionados

  // Variables para el doble tap "nadie cumple"
  DateTime? _lastTapTime;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();

    // Preparar overlay de orientación y ejecutar transición suave a landscape
    _orientationFadeController = AnimationController(duration: const Duration(milliseconds: 180), vsync: this);
    _orientationFade = CurvedAnimation(parent: _orientationFadeController, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _orientationFadeController.forward();
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await _orientationFadeController.reverse();
      if (mounted) {
        setState(() {
          _showOrientationOverlay = false;
        });
      }
    });

    _cardAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _glowAnimationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _tapAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _rippleAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

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

    // Initialize player weights and drinks usando playerId
    for (int i = 0; i < widget.players.length; i++) {
      _playerWeights[i] = 0;
      _playerDrinks[widget.players[i].id] = 0; // Usar playerId como clave
    }

    _initializeFirstChallenge();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _cardAnimationController.dispose();
    _glowAnimationController.dispose();
    _tapAnimationController.dispose();
    _rippleAnimationController.dispose();
    _orientationFadeController.dispose();
    _toastTimer?.cancel(); // Cancelar el timer si está activo
    super.dispose();
  }

  Future<void> _generateNewChallenge() async {
    if (Random().nextDouble() < 0.3 && widget.players.isNotEmpty) {
      final selectedPlayerIndex = Random().nextInt(widget.players.length);
      final selectedPlayer = widget.players[selectedPlayerIndex];

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
        _currentAnswer = question.answer;
        _currentPlayerIndex = selectedPlayerIndex;
      });
    } else {
      var attempts = 0;
      GeneratedQuestion question;
      do {
        question = await QuestionGenerator.generateRandomQuestion();
        attempts++;
      } while (_usedQuestions.contains(question.question) && attempts < 30);
      _usedQuestions.add(question.question);

      setState(() {
        _currentChallenge = question.question;
        _currentAnswer = question.answer;
        _currentPlayerIndex = -1;
      });
    }
  }

  Future<void> _initializeFirstChallenge() async {
    await _generateNewChallenge();

    final gameState = _createGameState();
    if (!gameState.isChallengeForAll && !_isGenericPlayerQuestion() && !gameState.isDualChallenge) {
      _selectWeightedRandomPlayer();
    } else if (gameState.isChallengeForAll) {
      setState(() {
        _currentPlayerIndex = -1;
      });
    }
  }

  GameState _createGameState() {
    String? dualPlayer1Name;
    String? dualPlayer2Name;

    if (_dualPlayerIndex != null && _currentPlayerIndex >= 0) {
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
      currentAnswer: _currentAnswer,
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

    return _currentPlayerIndex >= 0 &&
        _currentPlayerIndex < widget.players.length &&
        (_currentChallenge.contains('${widget.players[_currentPlayerIndex].nombre} bebe') ||
            _currentChallenge.contains('${widget.players[_currentPlayerIndex].nombre} reparte') ||
            _currentChallenge.contains('${widget.players[_currentPlayerIndex].nombre} responde') ||
            _currentChallenge.contains('${widget.players[_currentPlayerIndex].nombre} confiesa'));
  }

  bool _isConditionalQuestion() {
    if (_currentChallenge.isEmpty) return false;

    final lowerChallenge = _currentChallenge.toLowerCase();

    // Detectar preguntas condicionales "Cualquiera que..." que SÍ cuentan tragos
    // Estas son las categorías del JSON: Ropa, Físico, Edad, Relaciones, Tecnología,
    // Comida, Hobbies, Trabajo, Hábitos, Diversión, Nombres
    return lowerChallenge.startsWith('cualquiera que') ||
        lowerChallenge.startsWith('cualquiera con') ||
        lowerChallenge.contains('bebe 3 tragos por cada vocal');
  }

  // Detectar si la pregunta es "más probable que"
  bool _isMoreLikelyQuestion() {
    if (_currentChallenge.isEmpty) return false;
    final lowerChallenge = _currentChallenge.toLowerCase();
    return lowerChallenge.contains('más probable') || 
        lowerChallenge.contains('señalen a') ||
        lowerChallenge.contains('apunten a');
  }

  // Detectar si la pregunta tiene multiplicador (por cada letra)
  bool _hasLetterMultiplier() {
    final lowerChallenge = _currentChallenge.toLowerCase();
    return lowerChallenge.contains('por cada') &&
        (lowerChallenge.contains('vocal') || lowerChallenge.contains('letra'));
  }

  // Extraer la letra/vocal a contar
  String? _extractLetterToCount() {
    // Buscar patrones como "vocal A" o "letra E"
    final match = RegExp(r'vocal\s+([aeiouAEIOU])', caseSensitive: false).firstMatch(_currentChallenge);
    if (match != null) {
      return match.group(1)?.toUpperCase();
    }
    return null;
  }

  int _extractDrinksFromChallenge() {
    if (_currentChallenge.isEmpty) return 1;

    final lowerChallenge = _currentChallenge.toLowerCase();

    // Buscar patrones como "bebe X trago(s)" o "bebe X"
    final patterns = [
      RegExp(r'bebe\s+(\d+)\s+trago'), // "bebe 3 tragos"
      RegExp(r'bebe\s+(\d+)'), // "bebe 3"
      RegExp(r'(\d+)\s+trago'), // "3 tragos"
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerChallenge);
      if (match != null && match.groupCount >= 1) {
        final drinks = int.tryParse(match.group(1)!);
        if (drinks != null && drinks > 0) {
          return drinks;
        }
      }
    }

    // Por defecto, 1 trago si no se encuentra cantidad específica
    return 1;
  }

  bool _shouldCountDrinks() {
    if (_currentChallenge.isEmpty) return false;

    final lowerChallenge = _currentChallenge.toLowerCase();

    // Solo contar tragos si es una pregunta condicional tipo "Cualquiera que..."
    // NO contar si es:
    // - Duelo entre dos jugadores (contiene "entre" y dos nombres)
    // - Reto de un jugador ("reparte X tragos si logra...")
    // - Pregunta de conocimiento ("reparte X tragos si responde correctamente")
    // - Piedra papel tijera
    // - Adivinanza

    // Excluir duelos y batallas (tienen dos jugadores mencionados)
    if (lowerChallenge.contains(' y ') &&
        (lowerChallenge.contains('entre') ||
            lowerChallenge.contains('juegan') ||
            lowerChallenge.contains('el que sea más') ||
            lowerChallenge.contains('quien') && lowerChallenge.contains('primero'))) {
      return false;
    }

    // Excluir retos individuales con "reparte si logra" o "bebe si no puede"
    if (lowerChallenge.contains('reparte') &&
        (lowerChallenge.contains('si logra') ||
            lowerChallenge.contains('si responde') ||
            lowerChallenge.contains('si todos aplauden') ||
            lowerChallenge.contains('si recuerda') ||
            lowerChallenge.contains('si actúa'))) {
      return false;
    }

    if (lowerChallenge.contains('bebe') &&
        (lowerChallenge.contains('si no puede') ||
            lowerChallenge.contains('si no sabe') ||
            lowerChallenge.contains('si no resuelve'))) {
      return false;
    }

    // Excluir "reparte X tragos por..." (son razones aleatorias, no condicionales)
    if (lowerChallenge.contains('reparte') && lowerChallenge.contains('tragos por')) {
      return false;
    }

    // Excluir "bebe X tragos por..." (razones aleatorias)
    if (lowerChallenge.contains('bebe') && lowerChallenge.contains('tragos por') && !lowerChallenge.contains('vocal')) {
      return false;
    }

    // Excluir repartos simples de un jugador específico
    if (lowerChallenge.contains('reparte') &&
        lowerChallenge.contains('tragos') &&
        !lowerChallenge.contains('cualquiera')) {
      return false;
    }

    // Solo contar si es "Cualquiera que/con..." (preguntas condicionales)
    return _isConditionalQuestion() || _isMoreLikelyQuestion();
  }

  bool _isDirectDrinkForCurrentPlayer() {
    if (_currentChallenge.isEmpty) return false;
    if (_currentPlayerIndex < 0 || _currentPlayerIndex >= widget.players.length) return false;
    if (_isConditionalQuestion() || _isMoreLikelyQuestion()) return false;
    if (_dualPlayerIndex != null) return false; // Evitar duelos

    final lowerChallenge = _currentChallenge.toLowerCase();
    final playerName = widget.players[_currentPlayerIndex].nombre.toLowerCase();

    // Debe mencionar al jugador y tener "bebe", sin ser reparto
    if (!lowerChallenge.contains(playerName)) return false;
    if (!lowerChallenge.contains('bebe')) return false;
    if (lowerChallenge.contains('reparte')) return false;

    return true;
  }

  void _applyDirectDrinksForCurrentPlayer() {
    if (!_isDirectDrinkForCurrentPlayer()) return;

    final playerId = widget.players[_currentPlayerIndex].id;
    final drinksAmount = _extractDrinksFromChallenge();

    setState(() {
      _playerDrinks[playerId] = (_playerDrinks[playerId] ?? 0) + drinksAmount;
    });
  }

  void _selectWeightedRandomPlayer() {
    int minWeight = _playerWeights.values.reduce((a, b) => a < b ? a : b);

    List<int> eligiblePlayers = [];
    _playerWeights.forEach((playerIndex, weight) {
      if (weight == minWeight) {
        eligiblePlayers.add(playerIndex);
      }
    });

    if (eligiblePlayers.length < widget.players.length ~/ 2) {
      _playerWeights.forEach((playerIndex, weight) {
        if (weight == minWeight + 1 && !eligiblePlayers.contains(playerIndex)) {
          eligiblePlayers.add(playerIndex);
        }
      });
    }

    int selectedPlayer = eligiblePlayers[Random().nextInt(eligiblePlayers.length)];

    setState(() {
      _currentPlayerIndex = selectedPlayer;
      _playerWeights[selectedPlayer] = (_playerWeights[selectedPlayer] ?? 0) + 1;
    });
  }

  void _addRippleEffect(Offset position) {
    if (_rippleAnimationController.isAnimating) return;

    setState(() {
      _ripplePositions.clear();
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

  void _handleDoubleTapForNobody() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 1000) {
      // Doble tap detectado - cancelar el timer y nadie cumple
      _toastTimer?.cancel();
      setState(() {
        if (_shouldCountDrinks()) {
          // No añadir tragos porque nadie cumple
        }
      });
      // Avanzar al siguiente reto
      _nextChallenge();
    } else {
      // Primer tap - iniciar timer para mostrar mensaje después de 1 segundo
      _lastTapTime = now;
      _toastTimer?.cancel(); // Cancelar timer anterior si existe

      _toastTimer = Timer(Duration(seconds: 1), () {
        // Solo mostrar el toast si seguimos en el mismo contexto
        if (mounted && _lastTapTime != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Si nadie cumple, pulsa rápido 2 veces', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1, left: 20, right: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      });
    }
  }

  // Detectar si hay empate entre jugadores señalados
  bool _hasEmpateBetweenPlayers(List<int> selectedPlayerIds) {
    if (selectedPlayerIds.length <= 1) return false;
    // Si hay 2 o más jugadores seleccionados, es un empate
    return true;
  }

  // Manejar empate usando la ruleta
  void _handleTiebreakerForMoreLikelyQuestion(List<int> selectedPlayerIds) {
    if (!_hasEmpateBetweenPlayers(selectedPlayerIds)) {
      // No hay empate, proceder normal
      _applyMoreLikelyQuestionDrinks(selectedPlayerIds);
      return;
    }

    // Hay empate, usar ruleta
    final tiedPlayers = widget.players.where((p) => selectedPlayerIds.contains(p.id)).toList();
    final drinksAmount = _extractDrinksFromChallenge();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TiebreakerScreen(
          tiedPlayers: tiedPlayers,
          tiedScore: 0,
          type: TiebreakerType.mvp,
          isQuestionTiebreaker: true, // Desempate de pregunta, no final
          currentQuestion: _currentChallenge,
          drinksAmount: drinksAmount,
          onTiebreakerResolved: (winnerPlayer, loserPlayer) {
            Navigator.of(context).pop();
            
            // El ganador de la ruleta recibe los tragos
            setState(() {
              _showingPlayerSelector = false;
              if (_shouldCountDrinks()) {
                final drinksAmount = _extractDrinksFromChallenge();
                _playerDrinks[winnerPlayer.id] = (_playerDrinks[winnerPlayer.id] ?? 0) + drinksAmount;
              }
            });

            // Avanzar al siguiente reto después de 500ms
            Future.delayed(const Duration(milliseconds: 500), () {
              _nextChallenge();
            });
          },
        ),
      ),
    );
  }

  // Aplicar tragos normalmente sin empate
  void _applyMoreLikelyQuestionDrinks(List<int> selectedPlayerIds) {
    setState(() {
      _showingPlayerSelector = false;
      if (_shouldCountDrinks()) {
        final drinksAmount = _extractDrinksFromChallenge();
        for (final playerId in selectedPlayerIds) {
          _playerDrinks[playerId] = (_playerDrinks[playerId] ?? 0) + drinksAmount;
        }
      }
    });
    
    // Avanzar al siguiente reto después de seleccionar
    Future.delayed(const Duration(milliseconds: 300), () {
      _nextChallenge();
    });
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
        onEnd: () {},
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
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 2, spreadRadius: 1)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _nextChallenge() async {
    _tapAnimationController.forward().then((_) {
      _tapAnimationController.reverse();
    });

    setState(() {
      _gameStarted = true;
      _currentRound++;
      _currentChallengeEnd = null;
      _currentEventEnd = null;
      _dualPlayerIndex = null;
      _currentAnswer = null; // Limpiar respuesta anterior
    });

    // Verificar si alcanzamos el límite de rondas
    if (_currentRound > widget.maxRounds) {
      _endGame();
      return;
    }

    await _checkForEventEnding();

    if (_currentEventEnd != null) {
      return;
    }

    await _checkForConstantChallengeEnding();

    if (_currentChallengeEnd != null) {
      return;
    }

    final gameState = _createGameState();
    if (gameState.canHaveEvents && EventGenerator.shouldGenerateEvent(_currentRound, gameState.activeEvents)) {
      await _generateNewEvent();
      return;
    }

    if (gameState.canHaveConstantChallenges &&
        ConstantChallengeGenerator.shouldGenerateConstantChallenge(_currentRound, gameState.activeChallenges)) {
      if (widget.players.length >= 2 && math.Random().nextDouble() < 0.2) {
        await _generateNewDualConstantChallenge();
      } else {
        await _generateNewConstantChallenge();
      }
      return;
    }

    if (widget.players.length >= 2 && math.Random().nextDouble() < 0.15) {
      await _generateNewDualChallenge();
    } else {
      await _generateNewChallenge();
    }

    final gameState2 = _createGameState();
    if (!gameState2.isChallengeForAll && !_isGenericPlayerQuestion() && !gameState2.isDualChallenge) {
      _selectWeightedRandomPlayer();
    } else if (gameState2.isChallengeForAll) {
      setState(() {
        _currentPlayerIndex = -1;
      });
    }
  }

  Future<void> _checkForConstantChallengeEnding() async {
    final activeChallenges = _constantChallenges.where((c) => c.isActiveAtRound(_currentRound)).toList();

    for (final challenge in activeChallenges) {
      if (ConstantChallengeGenerator.shouldEndConstantChallenge(challenge, _currentRound)) {
        final challengeEnd = ConstantChallengeGenerator.generateChallengeEnd(challenge, _currentRound);

        setState(() {
          _constantChallenges = _constantChallenges.map((c) {
            if (c.id == challenge.id) {
              return c.copyWith(status: ConstantChallengeStatus.ended, endRound: _currentRound);
            }
            return c;
          }).toList();

          _currentChallengeEnd = challengeEnd;
          _currentChallenge = challengeEnd.endDescription;
          _currentPlayerIndex = -1;
        });

        return;
      }
    }
  }

  Future<void> _generateNewConstantChallenge() async {
    final eligiblePlayer = ConstantChallengeGenerator.selectPlayerForNewChallenge(
      widget.players,
      _constantChallenges.where((c) => c.isActiveAtRound(_currentRound)).toList(),
    );

    if (eligiblePlayer == null) {
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
      _currentAnswer = null; // Los retos constantes no tienen respuesta oculta
      _currentPlayerIndex = widget.players.indexWhere((p) => p.id == eligiblePlayer.id);
    });
  }

  Future<void> _checkForEventEnding() async {
    final activeEvents = _events.where((e) => e.isActiveAtRound(_currentRound)).toList();

    for (final event in activeEvents) {
      if (EventGenerator.shouldEndEvent(event, _currentRound)) {
        final eventEnd = EventGenerator.generateEventEnd(event, _currentRound);

        setState(() {
          _events = _events.map((e) {
            if (e.id == event.id) {
              return e.copyWith(status: EventStatus.ended, endRound: _currentRound);
            }
            return e;
          }).toList();

          _currentEventEnd = eventEnd;
          _currentChallenge = eventEnd.endDescription;
          _currentPlayerIndex = -1;
        });

        return;
      }
    }
  }

  Future<void> _generateNewEvent() async {
    final event = await EventGenerator.generateRandomEvent(_currentRound);

    setState(() {
      _events.add(event);
      _currentChallenge = '${event.typeIcon} ${event.title}: ${event.description}';
      _currentAnswer = null; // Los eventos no tienen respuesta oculta
      _currentPlayerIndex = -1;
    });
  }

  Future<void> _generateNewDualChallenge() async {
    final selectedPlayers = _selectTwoRandomPlayers();
    if (selectedPlayers.length < 2) {
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

    final player1Index = widget.players.indexOf(player1);
    final player2Index = widget.players.indexOf(player2);

    setState(() {
      _currentChallenge = question.question;
      _currentAnswer = question.answer;
      _currentPlayerIndex = player1Index;
      _dualPlayerIndex = player2Index;

      _playerWeights[_currentPlayerIndex] = (_playerWeights[_currentPlayerIndex] ?? 0) + 1;
      _playerWeights[_dualPlayerIndex!] = (_playerWeights[_dualPlayerIndex!] ?? 0) + 1;
    });
  }

  Future<void> _generateNewDualConstantChallenge() async {
    final selectedPlayers = _selectTwoRandomPlayers();
    if (selectedPlayers.length < 2) {
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
      _currentPlayerIndex = widget.players.indexOf(player1);
      _dualPlayerIndex = widget.players.indexOf(player2);
    });
  }

  List<Player> _selectTwoRandomPlayers() {
    if (widget.players.length < 2) return [];

    List<Player> eligiblePlayers = [];

    int minWeight = _playerWeights.values.isEmpty ? 0 : _playerWeights.values.reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < widget.players.length; i++) {
      int weight = _playerWeights[i] ?? 0;
      if (weight <= minWeight + 1) {
        eligiblePlayers.add(widget.players[i]);
      }
    }

    if (eligiblePlayers.length < 2) {
      eligiblePlayers = List.from(widget.players);
    }

    eligiblePlayers.shuffle(math.Random());
    return eligiblePlayers.take(2).toList();
  }

  void _openActiveChallengesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Retos y Eventos Activos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionTitle('📋 Retos Constantes'),
                        if (_constantChallenges.where((c) => c.status == ConstantChallengeStatus.active).isEmpty)
                          _buildEmptyState('No hay retos constantes activos')
                        else
                          ..._constantChallenges
                              .where((c) => c.status == ConstantChallengeStatus.active)
                              .map((c) => _buildActiveChallengeItem(c)),

                        _buildSectionTitle('🌐 Eventos Globales'),
                        if (_events.where((e) => e.status == EventStatus.active).isEmpty)
                          _buildEmptyState('No hay eventos globales activos')
                        else
                          ..._events.where((e) => e.status == EventStatus.active).map((e) => _buildActiveEventItem(e)),
                          
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildActiveChallengeItem(ConstantChallenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(challenge.typeIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para: ${challenge.targetPlayer.nombre}',
                  style: const TextStyle(
                    color: Color(0xFF00C9FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  challenge.description,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.getDurationDescription(_currentRound),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEventItem(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(event.typeIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Color(0xFF92FE9D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  event.description,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  event.getDurationDescription(_currentRound),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _endGame() async {
    // Cambiar a vertical ANTES de navegar para evitar parpadeo
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    // Dar más tiempo para que la orientación se aplique completamente
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Llamar onGameEnd - el callback se encarga de toda la navegación
    widget.onGameEnd(_playerDrinks);
    // No hacemos Navigator.pop() aquí porque el callback usa pushReplacement
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            const AnimatedBackground(),
            ...List.generate(
              8,
              (index) =>
                  _buildFloatingParticle(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height, index),
            ),
            SafeArea(
              child: Stack(
                children: [
                  // Game content - full screen
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final hasActiveSelector =
                          _isConditionalQuestion() && !_showingPlayerSelector && !_showingLetterCounter;
                      final isMoreLikelyAndNotSelected = _isMoreLikelyQuestion() && !_showingPlayerSelector;
                      
                      return GestureDetector(
                        onTapDown: hasActiveSelector
                            ? null
                            : (details) {
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final localPosition = renderBox.globalToLocal(details.globalPosition);
                                _addRippleEffect(localPosition);
                              },
                        onTap: hasActiveSelector 
                            ? _handleDoubleTapForNobody 
                            : (isMoreLikelyAndNotSelected
                                ? () {
                                    setState(() {
                                      _showingPlayerSelector = true;
                                    });
                                  }
                                : () {
                                    _applyDirectDrinksForCurrentPlayer();
                                    _nextChallenge();
                                  }),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedBuilder(
                          animation: _tapAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _tapAnimation.value,
                              child: Stack(
                                children: [
                                  GameCard(
                                    gameState: _createGameState(),
                                    showPlayerSelector:
                                        _isConditionalQuestion() && !_showingPlayerSelector && !_showingLetterCounter,
                                    onPlayersSelected: (selectedIds) {
                                      // Detectar si es una pregunta con multiplicador de letras
                                      if (_hasLetterMultiplier()) {
                                        final letter = _extractLetterToCount();
                                        if (letter != null) {
                                          // Si la lista está vacía (nadie cumple), avanzar directamente
                                          if (selectedIds.isEmpty) {
                                            _nextChallenge();
                                            return;
                                          }

                                          // Guardar los IDs seleccionados y mostrar el contador de letras
                                          setState(() {
                                            _selectedPlayerIdsForLetterCounter = selectedIds;
                                            _showingLetterCounter = true;
                                          });
                                          return;
                                        }
                                      }

                                      // Añadir tragos SOLO si es una pregunta que cuenta (no duelos, repartos, retos)
                                      setState(() {
                                        if (_shouldCountDrinks()) {
                                          final drinksAmount = _extractDrinksFromChallenge();
                                          for (final playerId in selectedIds) {
                                            // Usar directamente playerId como clave
                                            _playerDrinks[playerId] = (_playerDrinks[playerId] ?? 0) + drinksAmount;
                                          }
                                        }
                                      });
                                      // Avanzar automáticamente al siguiente reto
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        _nextChallenge();
                                      });
                                    },
                                  ),
                                  _buildRippleEffects(),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  // Back button - top left corner
                  Positioned(
                    top: 12,
                    left: 12,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isSmallScreen = screenWidth < 600;
                        final backButtonSize = isSmallScreen ? 40.0 : 50.0;

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('¿Salir del juego?'),
                                content: const Text(
                                  '¿Estás seguro de que quieres salir? Se perderá el progreso del juego.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Salir'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: backButtonSize,
                            height: backButtonSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: isSmallScreen ? 20 : 24),
                          ),
                        );
                      },
                    ),
                  ),

                  // Active Challenges button - top right corner
                  Positioned(
                    top: 12,
                    right: 12,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isSmallScreen = screenWidth < 600;
                        final buttonSize = isSmallScreen ? 40.0 : 50.0;
                        final iconSize = isSmallScreen ? 20.0 : 25.0;

                        return GestureDetector(
                          onTap: _openActiveChallengesModal,
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: Icon(Icons.list_alt, color: Colors.white, size: iconSize),
                          ),
                        );
                      },
                    ),
                  ),
                  // Round Counter - top right corner
                  Positioned(
                    top: 12,
                    right: 12,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            'RONDA $_currentRound',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Player selector overlay
            if (_showingPlayerSelector)
              PlayerSelectorOverlay(
                players: widget.players,
                isMoreLikelyQuestion: _isMoreLikelyQuestion(),
                onPlayersSelected: (selectedPlayerIds) {
                  // Si es "más probable que" y hay empate, usar ruleta
                  if (_isMoreLikelyQuestion()) {
                    _handleTiebreakerForMoreLikelyQuestion(selectedPlayerIds);
                  } else {
                    // Para otras preguntas condicionales, proceder normalmente
                    _applyMoreLikelyQuestionDrinks(selectedPlayerIds);
                  }
                },
                onCancel: () {
                  setState(() {
                    _showingPlayerSelector = false;
                  });
                },
              ),
            // Letter counter overlay
            if (_showingLetterCounter)
              LetterCounterOverlay(
                selectedPlayers: widget.players
                    .where((p) => _selectedPlayerIdsForLetterCounter.contains(p.id))
                    .toList(),
                letter: _extractLetterToCount() ?? 'A',
                drinksPerLetter: _extractDrinksFromChallenge(),
                onConfirm: (playerDrinksMap) {
                  setState(() {
                    _showingLetterCounter = false;
                    _selectedPlayerIdsForLetterCounter = [];
                    // Añadir los tragos calculados con multiplicador
                    playerDrinksMap.forEach((playerId, drinks) {
                      _playerDrinks[playerId] = (_playerDrinks[playerId] ?? 0) + drinks;
                    });
                  });
                  // Avanzar al siguiente reto
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _nextChallenge();
                  });
                },
              ),
            // Overlay negro para suavizar el cambio de orientación
            if (_showOrientationOverlay)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orientationFade,
                  builder: (context, _) => Container(
                    color: Colors.black.withOpacity(_orientationFade.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
