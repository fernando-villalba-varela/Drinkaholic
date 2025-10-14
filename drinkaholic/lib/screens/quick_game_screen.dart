import 'package:drinkaholic/models/question_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/player.dart';
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
  
late Animation<double> _glowAnimation;
  
  int _currentPlayerIndex = 0;
  String _currentChallenge = '';
  bool _gameStarted = false;
  Map<int, int> _playerWeights = {}; // Track how many times each player has been selected

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
    
    
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimationController.repeat(reverse: true);
    
    // Initialize player weights (all start at 0)
    for (int i = 0; i < widget.players.length; i++) {
      _playerWeights[i] = 0;
    }
    
    _generateNewChallenge();
    _selectWeightedRandomPlayer();
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
    super.dispose();
  }

Future<void> _generateNewChallenge() async {
  
  //numero aleatorio de 1 a 3  
   final question = await QuestionGenerator.generateRandomQuestion();
  setState(() {
    _currentChallenge = question.question;
  });
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
    setState(() {
      _gameStarted = true;
    });
    await _generateNewChallenge();

    // Solo selecciona jugador si el reto NO es para todos
    if (!isChallengeForAll(_currentChallenge)) {
      _selectWeightedRandomPlayer();
    } else {
      setState(() {
        _currentPlayerIndex = -1; // Valor especial para "todos"
      });
    }
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
                
                // Center content area
                Expanded(
                  child: Center(
                    child: buildCenterContent(
  widget,
  widget.players,
  _currentPlayerIndex,
  _currentChallenge,
  _glowAnimation,
  _playerWeights,
  _gameStarted,
  null
),
                  ),
                ),
                
                // Bottom button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00C9FF),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'SIGUIENTE DESAFÍO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
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
}