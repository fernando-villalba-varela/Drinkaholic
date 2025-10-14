import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/player.dart';

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
  late Animation<double> _cardFlipAnimation;
  late Animation<double> _glowAnimation;
  
  int _currentPlayerIndex = 0;
  String _currentChallenge = '';
  bool _gameStarted = false;
  Map<int, int> _playerWeights = {}; // Track how many times each player has been selected

  // Lista de desafíos para el juego rápido
  final List<String> _challenges = [
    "Bebe 2 tragos",
    "Elige a alguien para que beba",
    "Todos beben excepto tú",
    "Bebe si tienes más de 25 años",
    "El jugador a tu izquierda bebe",
    "Bebe y cuenta un secreto",
    "Haz una pregunta, quien no responda bebe",
    "Imita a otro jugador, si adivinan bebes tú",
    "Bebe si usas gafas",
    "Todos los que tengan pareja beben",
    "Bebe si tu nombre empieza por vocal",
    "El más joven de la mesa bebe",
    "Bebe si tienes hermanos",
    "Elige dos personas para que beban",
    "Bebe si llevas algo azul puesto",
  ];

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
    
    _cardFlipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
    
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

  void _generateNewChallenge() {
    setState(() {
      _currentChallenge = _challenges[Random().nextInt(_challenges.length)];
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

  void _nextChallenge() {
    setState(() {
      _gameStarted = true;
    });
    
    _generateNewChallenge();
    _selectWeightedRandomPlayer();
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

  Widget _buildCenterContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Current player indicator with glow
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(_glowAnimation.value * 0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.person_pin,
                size: 50,
                color: Colors.white.withOpacity(_glowAnimation.value),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Player name
        Text(
          widget.players[_currentPlayerIndex].nombre.toUpperCase(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
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
        
        const SizedBox(height: 40),
        
        // Challenge text
        Container(
          padding: const EdgeInsets.all(30),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.local_drink,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                _currentChallenge,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Selection count display (for testing)
        if (_gameStarted)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Turnos: ${_playerWeights.values.join(", ")}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
      ],
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
            padding: const EdgeInsets.all(20),
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
                      child: Container(
                        height: 100,
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
                                const SizedBox(height: 8),
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
                    child: _buildCenterContent(),
                  ),
                ),
                
                // Bottom button
                Container(
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