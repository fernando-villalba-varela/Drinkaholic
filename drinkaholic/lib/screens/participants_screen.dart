import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart'; // <-- Añade esta línea
import '../viewmodels/participants_viewmodel.dart'; // <-- Añade esta línea
import '../models/player.dart';
import 'quick_game_screen.dart';

class ParticipantsScreen extends StatelessWidget {
  final String title;
  const ParticipantsScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParticipantsViewmodel(),
      child: const _ParticipantsScreenBody(),
    );
  }
}

class _ParticipantsScreenBody extends StatefulWidget {
  const _ParticipantsScreenBody();

  @override
  State<_ParticipantsScreenBody> createState() =>
      _ParticipantsScreenBodyState();
}

class _ParticipantsScreenBodyState extends State<_ParticipantsScreenBody>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  List<Player> get _players =>
      Provider.of<ParticipantsViewmodel>(context).players;
  TextEditingController get _controller =>
      Provider.of<ParticipantsViewmodel>(context).controller;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.linear,
      ),
    );

    _backgroundAnimationController.repeat();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ParticipantsViewmodel>(
      context,
      listen: false,
    );
    viewModel.context = context;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00C9FF), // Cyan (matching Quick Game button)
                  Color(0xFF92FE9D), // Green (matching Quick Game button)
                ],
              ),
            ),
          ),
          // Animated background shapes
          _buildAnimatedBackground(),
          // Floating particles effect
          ...List.generate(
            8,
            (index) => _buildFloatingParticle(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
              index,
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom header with back button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Modern back button
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title with modern styling
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFE0F7FA)],
                        ).createShader(bounds),
                        child: const Text(
                          'JUGADORES',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(
                        width: 44,
                      ), // Balance space for back button
                    ],
                  ),
                ),
                // Players list with modern cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      itemCount: _players.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _players.length) {
                          return _buildPlayerCard(index);
                        } else {
                          return _buildAddPlayerCard();
                        }
                      },
                    ),
                  ),
                ),
                // Modern start game button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () {
                          final viewModel = Provider.of<ParticipantsViewmodel>(
                            context,
                            listen: false,
                          );
                          if (viewModel.players.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    QuickGameScreen(players: viewModel.players),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_esports,
                                color: Color(0xFF00C9FF),
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '¡EMPEZAR A JUGAR!',
                                style: TextStyle(
                                  color: Color(0xFF00C9FF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ), // Closing for Container at 102
        ],
      ),
    );
  }

  Widget _buildPlayerCard(int index) {
    final viewModel = Provider.of<ParticipantsViewmodel>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with modern styling
            GestureDetector(
              onTap: () => viewModel.onAvatarTap(index),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    (_players[index].imagen != null ||
                        _players[index].avatar != null)
                    ? ClipOval(
                        child: _players[index].imagen != null
                            ? Image.file(
                                _players[index].imagen!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.asset(
                                _players[index].avatar!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      )
                    : CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Player name
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.confirmDelete(index),
                child: Text(
                  _players[index].nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Delete indicator
            Icon(
              Icons.touch_app,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlayerCard() {
    final viewModel = Provider.of<ParticipantsViewmodel>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            // Add icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text field
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Añadir jugador...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => viewModel.addPlayer(),
              ),
            ),
            // Add button
            GestureDetector(
              onTap: viewModel.addPlayer,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
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
      child: _FloatingParticleWidget(
        size: size,
        opacity: opacity,
        duration: Duration(milliseconds: 3000 + (random % 2000)),
      ),
    );
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

class _FloatingParticleWidget extends StatefulWidget {
  final double size;
  final double opacity;
  final Duration duration;

  const _FloatingParticleWidget({
    required this.size,
    required this.opacity,
    required this.duration,
  });

  @override
  State<_FloatingParticleWidget> createState() =>
      _FloatingParticleWidgetState();
}

class _FloatingParticleWidgetState extends State<_FloatingParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _startAnimation();
  }

  void _startAnimation() {
    _controller.forward().then((_) {
      if (mounted) {
        _controller.reset();
        _startAnimation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value * 50),
          child: Opacity(
            opacity: widget.opacity * (1 - _animation.value),
            child: Container(
              width: widget.size,
              height: widget.size,
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
    );
  }
}
