import 'package:drinkaholic/models/question_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/player.dart';
import '../models/game_state.dart';
import '../models/constant_challenge.dart';
import '../models/constant_challenge_generator.dart';
import '../widgets/quick_game_widgets.dart'; // Añade este import arriba


class QuickGameScreen extends StatefulWidget {
  final List<Player> players;
  
  const QuickGameScreen({
    super.key,
    required this.players,
  });

  @override
  State<QuickGameScreen> createState() => _QuickGameScreenState();
}

class _QuickGameScreenState extends State<QuickGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _tapAnimationController;
  
  late Animation<double> _glowAnimation;
  late Animation<double> _tapAnimation;
  
  int _currentPlayerIndex = -1; // Start with no player selected
  String _currentChallenge = '';
  bool _gameStarted = false;
  Map<int, int> _playerWeights = {}; // Track how many times each player has been selected
  int _currentRound = 1;
  List<ConstantChallenge> _constantChallenges = [];
  ConstantChallengeEnd? _currentChallengeEnd;

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
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimationController.repeat(reverse: true);
    
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
    super.dispose();
  }

Future<void> _generateNewChallenge() async {
  // Generar pregunta (30% probabilidad de ser genérica con jugador específico)
  if (Random().nextDouble() < 0.3 && widget.players.isNotEmpty) {
    // Seleccionar un jugador aleatorio para la pregunta genérica
    final selectedPlayerIndex = Random().nextInt(widget.players.length);
    final selectedPlayer = widget.players[selectedPlayerIndex];
    
    final question = await QuestionGenerator.generateRandomQuestionForPlayer(selectedPlayer.nombre);
    
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
  
  // Solo selecciona jugador si el reto NO es para todos Y no es una pregunta genérica ya asignada
  final gameState = _createGameState();
  if (!gameState.isChallengeForAll && !_isGenericPlayerQuestion()) {
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
    );
  }

  bool _isGenericPlayerQuestion() {
    if (_currentChallenge.isEmpty) return false;
    
    // Una pregunta genérica es aquella donde ya se asignó un jugador específico
    // y el _currentPlayerIndex es válido (no -1)
    return _currentPlayerIndex >= 0 && 
           _currentPlayerIndex < widget.players.length &&
           (_currentChallenge.contains('${widget.players[_currentPlayerIndex].nombre} bebe') ||
            _currentChallenge.contains('${widget.players[_currentPlayerIndex].nombre} reparte'));
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
    int selectedPlayer = eligiblePlayers[Random().nextInt(eligiblePlayers.length)];
    
    setState(() {
      _currentPlayerIndex = selectedPlayer;
      // Increment the weight for the selected player
      _playerWeights[selectedPlayer] = (_playerWeights[selectedPlayer] ?? 0) + 1;
    });
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
    });

    // 1. Verificar si debemos terminar algún reto constante
    await _checkForConstantChallengeEnding();
    
    // 2. Si estamos mostrando un fin de reto, no generamos nuevo reto normal
    if (_currentChallengeEnd != null) {
      return;
    }

    // 3. Verificar si debemos generar un nuevo reto constante
    final gameState = _createGameState();
    if (gameState.canHaveConstantChallenges &&
        ConstantChallengeGenerator.shouldGenerateConstantChallenge(
          _currentRound,
          gameState.activeChallenges,
        )) {
      await _generateNewConstantChallenge();
      return;
    }

    // 4. Si no hay retos constantes, generar un reto normal
    await _generateNewChallenge();

    // 5. Solo selecciona jugador si el reto NO es para todos Y no es una pregunta genérica ya asignada
    final gameState2 = _createGameState();
    if (!gameState2.isChallengeForAll && !_isGenericPlayerQuestion()) {
      _selectWeightedRandomPlayer();
    } else if (gameState2.isChallengeForAll) {
      setState(() {
        _currentPlayerIndex = -1; // Valor especial para "todos"
      });
    }
    // Si es una pregunta genérica, el jugador ya fue asignado en _generateNewChallenge
  }

  Future<void> _checkForConstantChallengeEnding() async {
    final activeChallenges = _constantChallenges
        .where((c) => c.isActiveAtRound(_currentRound))
        .toList();

    for (final challenge in activeChallenges) {
      if (ConstantChallengeGenerator.shouldEndConstantChallenge(challenge, _currentRound)) {
        final challengeEnd = ConstantChallengeGenerator.generateChallengeEnd(challenge, _currentRound);
        
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
          _currentPlayerIndex = -1; // No hay jugador específico para este tipo de mensaje
        });
        
        print('Terminando reto constante: ${challenge.description}');
        return; // Solo terminamos un reto por ronda
      }
    }
  }

  Future<void> _generateNewConstantChallenge() async {
    final eligiblePlayer = ConstantChallengeGenerator.selectPlayerForNewChallenge(
      widget.players,
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
      _currentPlayerIndex = widget.players.indexWhere((p) => p.id == eligiblePlayer.id);
    });

    print('Nuevo reto constante: ${constantChallenge.description}');
  }

  Widget _buildPlayerAvatar(Player player, {bool isActive = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isActive ? 4 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          width: isActive ? 3 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ] : null,
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: player.imagen != null
              ? Image.file(
                  player.imagen!,
                  fit: BoxFit.cover,
                )
              : player.avatar != null
              ? Image.asset(
                  player.avatar!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Top section with exit button and players
                Row(
                  children: [
                    // Exit button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Players row
                    Expanded(
                      child: SizedBox(
                        height: 150,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: widget.players.asMap().entries.map((entry) {
                            final index = entry.key;
                            final player = entry.value;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPlayerAvatar(
                                  player,
                                  isActive: index == _currentPlayerIndex,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  player.nombre,
                                  style: TextStyle(
                                    color: index == _currentPlayerIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: index == _currentPlayerIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Center content area (tappable)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tapAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _tapAnimation.value,
                        child: GestureDetector(
                          onTap: _nextChallenge,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildCenterContent(_createGameState()),
                            const SizedBox(height: 40),
                            // Tap indicator (only show at the beginning)
                            if (!_gameStarted)
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'TOCA LA PANTALLA',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(_glowAnimation.value),
                                            fontSize: 14,
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
                          ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}