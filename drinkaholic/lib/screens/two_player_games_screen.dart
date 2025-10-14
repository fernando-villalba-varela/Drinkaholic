import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/player.dart';

enum GameType {
  ticTacToe,
  rockPaperScissors,
  battleships,
  memoryMatch,
  numberGuess,
  quickMath,
}

enum GameState { waiting, playing, finished }
enum TicTacToeCell { empty, x, o }
enum RPSChoice { rock, paper, scissors }
enum BattleshipCell { empty, ship, hit, miss }

class TwoPlayerGamesScreen extends StatefulWidget {
  final List<Player> players;

  const TwoPlayerGamesScreen({
    super.key,
    required this.players,
  });

  @override
  State<TwoPlayerGamesScreen> createState() => _TwoPlayerGamesScreenState();
}

class _TwoPlayerGamesScreenState extends State<TwoPlayerGamesScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  GameType _currentGame = GameType.ticTacToe;
  GameState _gameState = GameState.waiting;
  Player? _player1;
  Player? _player2;
  String _gameResult = '';
  int _player1Score = 0;
  int _player2Score = 0;

  // Tic-Tac-Toe state
  List<TicTacToeCell> _ticTacToeBoard = List.filled(9, TicTacToeCell.empty);
  bool _ticTacToeIsXTurn = true;

  // Rock Paper Scissors state
  RPSChoice? _player1Choice;
  RPSChoice? _player2Choice;
  bool _rpsPlayer1Ready = false;
  bool _rpsPlayer2Ready = false;

  // Battleships state
  List<BattleshipCell> _player1Ships = List.filled(16, BattleshipCell.empty);
  List<BattleshipCell> _player2Ships = List.filled(16, BattleshipCell.empty);
  List<BattleshipCell> _player1Board = List.filled(16, BattleshipCell.empty);
  List<BattleshipCell> _player2Board = List.filled(16, BattleshipCell.empty);
  bool _battleshipsPlayer1Turn = true;
  bool _battleshipsSetupComplete = false;

  // Memory Match state
  List<int> _memoryCards = [];
  List<bool> _memoryRevealed = List.filled(12, false);
  List<int> _memoryMatched = [];
  int? _memoryFirstCard;
  bool _memoryPlayer1Turn = true;

  // Number Guess state
  int _numberToGuess = 0;
  int _numberGuesses = 0;
  String _numberHint = '';
  bool _numberPlayer1Turn = true;

  // Quick Math state
  int _mathA = 0;
  int _mathB = 0;
  int _mathAnswer = 0;
  String _mathOperation = '+';
  bool _mathPlayer1Turn = true;

  final Map<GameType, String> _gameNames = {
    GameType.ticTacToe: 'Tres en Raya',
    GameType.rockPaperScissors: 'Piedra Papel Tijera',
    GameType.battleships: 'Batalla Naval',
    GameType.memoryMatch: 'Memoria',
    GameType.numberGuess: 'Adivina el Número',
    GameType.quickMath: 'Matemáticas Rápidas',
  };

  @override
  void initState() {
    super.initState();

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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
    _selectRandomPlayers();
    _initializeCurrentGame();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _selectRandomPlayers() {
    final random = Random();
    final shuffledPlayers = List<Player>.from(widget.players);
    shuffledPlayers.shuffle();
    
    setState(() {
      _player1 = shuffledPlayers[0];
      _player2 = shuffledPlayers[1];
    });
  }

  void _initializeCurrentGame() {
    setState(() {
      _gameState = GameState.waiting;
      _gameResult = '';
    });

    switch (_currentGame) {
      case GameType.ticTacToe:
        _initializeTicTacToe();
        break;
      case GameType.rockPaperScissors:
        _initializeRockPaperScissors();
        break;
      case GameType.battleships:
        _initializeBattleships();
        break;
      case GameType.memoryMatch:
        _initializeMemoryMatch();
        break;
      case GameType.numberGuess:
        _initializeNumberGuess();
        break;
      case GameType.quickMath:
        _initializeQuickMath();
        break;
    }
  }

  void _initializeTicTacToe() {
    setState(() {
      _ticTacToeBoard = List.filled(9, TicTacToeCell.empty);
      _ticTacToeIsXTurn = true;
      _gameState = GameState.playing;
    });
  }

  void _initializeRockPaperScissors() {
    setState(() {
      _player1Choice = null;
      _player2Choice = null;
      _rpsPlayer1Ready = false;
      _rpsPlayer2Ready = false;
      _gameState = GameState.playing;
    });
  }

  void _initializeBattleships() {
    setState(() {
      _player1Ships = List.filled(16, BattleshipCell.empty);
      _player2Ships = List.filled(16, BattleshipCell.empty);
      _player1Board = List.filled(16, BattleshipCell.empty);
      _player2Board = List.filled(16, BattleshipCell.empty);
      _battleshipsPlayer1Turn = true;
      _battleshipsSetupComplete = false;
      _gameState = GameState.playing;
    });
    _placeBattleships();
  }

  void _placeBattleships() {
    final random = Random();
    // Place 4 ships randomly for each player
    for (int player = 1; player <= 2; player++) {
      List<BattleshipCell> ships = player == 1 ? _player1Ships : _player2Ships;
      int shipsPlaced = 0;
      while (shipsPlaced < 4) {
        int pos = random.nextInt(16);
        if (ships[pos] == BattleshipCell.empty) {
          ships[pos] = BattleshipCell.ship;
          shipsPlaced++;
        }
      }
    }
    setState(() {
      _battleshipsSetupComplete = true;
    });
  }

  void _initializeMemoryMatch() {
    setState(() {
      _memoryCards = List.generate(12, (index) => (index ~/ 2) + 1);
      _memoryCards.shuffle();
      _memoryRevealed = List.filled(12, false);
      _memoryMatched = [];
      _memoryFirstCard = null;
      _memoryPlayer1Turn = true;
      _gameState = GameState.playing;
    });
  }

  void _initializeNumberGuess() {
    setState(() {
      _numberToGuess = Random().nextInt(20) + 1;
      _numberGuesses = 0;
      _numberHint = 'Adivina el número del 1 al 20';
      _numberPlayer1Turn = true;
      _gameState = GameState.playing;
    });
  }

  void _initializeQuickMath() {
    _generateMathProblem();
    setState(() {
      _mathPlayer1Turn = true;
      _gameState = GameState.playing;
    });
  }

  void _generateMathProblem() {
    final random = Random();
    final operations = ['+', '-', '×'];
    _mathOperation = operations[random.nextInt(operations.length)];
    
    switch (_mathOperation) {
      case '+':
        _mathA = random.nextInt(20) + 1;
        _mathB = random.nextInt(20) + 1;
        _mathAnswer = _mathA + _mathB;
        break;
      case '-':
        _mathA = random.nextInt(20) + 10;
        _mathB = random.nextInt(_mathA) + 1;
        _mathAnswer = _mathA - _mathB;
        break;
      case '×':
        _mathA = random.nextInt(10) + 2;
        _mathB = random.nextInt(10) + 2;
        _mathAnswer = _mathA * _mathB;
        break;
    }
  }

  void _nextGame() {
    final games = GameType.values;
    final currentIndex = games.indexOf(_currentGame);
    setState(() {
      _currentGame = games[(currentIndex + 1) % games.length];
    });
    _initializeCurrentGame();
  }

  void _playTicTacToeMove(int index) {
    if (_ticTacToeBoard[index] != TicTacToeCell.empty || _gameState != GameState.playing) return;

    setState(() {
      _ticTacToeBoard[index] = _ticTacToeIsXTurn ? TicTacToeCell.x : TicTacToeCell.o;
      _ticTacToeIsXTurn = !_ticTacToeIsXTurn;
    });

    _checkTicTacToeWinner();
  }

  void _checkTicTacToeWinner() {
    // Check rows, columns, and diagonals
    final winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final pattern in winPatterns) {
      final a = _ticTacToeBoard[pattern[0]];
      final b = _ticTacToeBoard[pattern[1]];
      final c = _ticTacToeBoard[pattern[2]];

      if (a != TicTacToeCell.empty && a == b && b == c) {
        setState(() {
          _gameState = GameState.finished;
          if (a == TicTacToeCell.x) {
            _gameResult = '${_player1!.nombre} gana!';
            _player1Score++;
          } else {
            _gameResult = '${_player2!.nombre} gana!';
            _player2Score++;
          }
        });
        return;
      }
    }

    // Check for tie
    if (!_ticTacToeBoard.contains(TicTacToeCell.empty)) {
      setState(() {
        _gameState = GameState.finished;
        _gameResult = '¡Empate!';
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
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: player.imagen != null
              ? Image.file(player.imagen!, fit: BoxFit.cover)
              : player.avatar != null
              ? Image.asset(player.avatar!, fit: BoxFit.cover)
              : Container(
                  color: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white, size: 25),
                ),
        ),
      ),
    );
  }

  Widget _buildTicTacToe() {
    return Column(
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _playTicTacToeMove(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _ticTacToeBoard[index] == TicTacToeCell.x
                          ? 'X'
                          : _ticTacToeBoard[index] == TicTacToeCell.o
                          ? 'O'
                          : '',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_gameState == GameState.playing)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Turno de: ${_ticTacToeIsXTurn ? _player1!.nombre : _player2!.nombre}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
      ],
    );
  }

  Widget _buildRockPaperScissors() {
    return Column(
      children: [
        if (_gameState == GameState.playing)
          Column(
            children: [
              const Text(
                'Elige tu jugada:',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRPSButton(RPSChoice.rock, '🪨', 'Piedra'),
                  _buildRPSButton(RPSChoice.paper, '📄', 'Papel'),
                  _buildRPSButton(RPSChoice.scissors, '✂️', 'Tijera'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Player 1: ${_rpsPlayer1Ready ? "✅" : "⏳"} | Player 2: ${_rpsPlayer2Ready ? "✅" : "⏳"}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        if (_gameState == GameState.finished)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(_player1!.nombre, style: const TextStyle(color: Colors.white, fontSize: 18)),
                      Text(_getRPSEmoji(_player1Choice!), style: const TextStyle(fontSize: 60)),
                    ],
                  ),
                  const Text('VS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Column(
                    children: [
                      Text(_player2!.nombre, style: const TextStyle(color: Colors.white, fontSize: 18)),
                      Text(_getRPSEmoji(_player2Choice!), style: const TextStyle(fontSize: 60)),
                    ],
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRPSButton(RPSChoice choice, String emoji, String text) {
    return GestureDetector(
      onTap: () => _playRPSMove(choice),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _playRPSMove(RPSChoice choice) {
    if (!_rpsPlayer1Ready) {
      setState(() {
        _player1Choice = choice;
        _rpsPlayer1Ready = true;
      });
    } else if (!_rpsPlayer2Ready) {
      setState(() {
        _player2Choice = choice;
        _rpsPlayer2Ready = true;
      });
      _checkRPSWinner();
    }
  }

  void _checkRPSWinner() {
    if (_player1Choice == _player2Choice) {
      setState(() {
        _gameResult = '¡Empate!';
        _gameState = GameState.finished;
      });
    } else if ((_player1Choice == RPSChoice.rock && _player2Choice == RPSChoice.scissors) ||
               (_player1Choice == RPSChoice.paper && _player2Choice == RPSChoice.rock) ||
               (_player1Choice == RPSChoice.scissors && _player2Choice == RPSChoice.paper)) {
      setState(() {
        _gameResult = '${_player1!.nombre} gana!';
        _player1Score++;
        _gameState = GameState.finished;
      });
    } else {
      setState(() {
        _gameResult = '${_player2!.nombre} gana!';
        _player2Score++;
        _gameState = GameState.finished;
      });
    }
  }

  String _getRPSEmoji(RPSChoice choice) {
    switch (choice) {
      case RPSChoice.rock:
        return '🪨';
      case RPSChoice.paper:
        return '📄';
      case RPSChoice.scissors:
        return '✂️';
    }
  }

  Widget _buildCurrentGame() {
    switch (_currentGame) {
      case GameType.ticTacToe:
        return _buildTicTacToe();
      case GameType.rockPaperScissors:
        return _buildRockPaperScissors();
      case GameType.battleships:
        return _buildPlaceholder('🚢 Batalla Naval\n(Simplificada - En desarrollo)');
      case GameType.memoryMatch:
        return _buildPlaceholder('🧠 Juego de Memoria\n(En desarrollo)');
      case GameType.numberGuess:
        return _buildPlaceholder('🔢 Adivina el Número\n(En desarrollo)');
      case GameType.quickMath:
        return _buildPlaceholder('➕ Matemáticas Rápidas\n(En desarrollo)');
    }
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
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
              Color(0xFF00C9FF),
              Color(0xFF92FE9D),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top section
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _gameNames[_currentGame]!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Players section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        _buildPlayerAvatar(_player1!, isActive: true),
                        const SizedBox(height: 10),
                        Text(
                          _player1!.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Score: $_player1Score',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      children: [
                        _buildPlayerAvatar(_player2!, isActive: true),
                        const SizedBox(height: 10),
                        Text(
                          _player2!.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Score: $_player2Score',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Game area
                Expanded(
                  child: Center(
                    child: _buildCurrentGame(),
                  ),
                ),
                
                // Result and buttons
                if (_gameResult.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _gameResult,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _initializeCurrentGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF00C9FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('JUGAR DE NUEVO', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF00C9FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('SIGUIENTE JUEGO', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}