import 'package:drinkaholic/screens/league_list_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final HomeViewModel _viewModel;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _iconMoveAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

  bool _isAnimating = false;
  Gradient? _currentGradient;
  String? _animatingButtonText;
  IconData? _animatingIcon;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _iconMoveAnimation =
        Tween<double>(
          begin: 0.0,
          end: -200.0, // Move upward for rocket launch
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _startAnimatedNavigation(
    Gradient gradient,
    String buttonText,
    IconData icon,
    VoidCallback onComplete,
  ) async {
    setState(() {
      _isAnimating = true;
      _currentGradient = gradient;
      _animatingButtonText = buttonText;
      _animatingIcon = icon;
    });

    await _animationController.forward();

    // Wait a bit for the full effect
    await Future.delayed(const Duration(milliseconds: 200));

    // Execute the navigation
    onComplete();

    // Reset animation after navigation
    await Future.delayed(const Duration(milliseconds: 100));
    _animationController.reset();
    setState(() {
      _isAnimating = false;
      _currentGradient = null;
      _animatingButtonText = null;
      _animatingIcon = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              // Beautiful gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      Color(0xFF2D1B69), // Deep purple
                      Color(0xFF11072C), // Dark purple
                      Color(0xFF0D0221), // Almost black
                    ],
                  ),
                ),
              ),
              // Floating particles effect
              ...List.generate(
                6,
                (index) =>
                    _buildFloatingParticle(screenWidth, screenHeight, index),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with glow effect
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4A373,
                                    ).withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/drinkaholic_logo.gif',
                                width: 180,
                                height: 180,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Title with enhanced styling
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700), // Gold
                                  Color(0xFFD4A373), // Bronze
                                  Color(0xFFB8860B), // Dark gold
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'DRINKAHOLIC',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'A beber como los duendes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 2,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buttons section
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModernButton(
                              onTap: () {
                                const gradient = LinearGradient(
                                  colors: [
                                    Color(0xFF00C9FF),
                                    Color(0xFF92FE9D),
                                  ],
                                );
                                _startAnimatedNavigation(
                                  gradient,
                                  'PARTIDA RÁPIDA',
                                  Icons.flash_on,
                                  () => _viewModel.navigateToQuickGame(context),
                                );
                              },
                              text: 'PARTIDA RÁPIDA',
                              icon: Icons.flash_on,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildModernButton(
                              onTap: () {
                                const gradient = LinearGradient(
                                  colors: [
                                    Color(0xFFFC466B),
                                    Color(0xFF3F5EFB),
                                  ],
                                );
                                _startAnimatedNavigation(
                                  gradient,
                                  'LIGA',
                                  Icons.emoji_events,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LeagueListScreen(),
                                    ),
                                  ),
                                );
                              },
                              text: 'LIGA',
                              icon: Icons.emoji_events,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Fullscreen animation overlay
              if (_isAnimating && _currentGradient != null)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _currentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: _scaleAnimation.value > 0.3
                              ? Stack(
                                  children: [
                                    // Animated icon layer (appears early)
                                    if (_scaleAnimation.value > 0.3)
                                      Center(child: _buildAnimatedIcon()),
                                    // Loading text layer (appears later)
                                    if (_scaleAnimation.value > 0.8)
                                      FadeTransition(
                                        opacity: _opacityAnimation,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 200,
                                              ), // Space for icon animation
                                              const CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                                strokeWidth: 3,
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Iniciando $_animatingButtonText...',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),

              // Error handling with modern styling
              if (_viewModel.hasError)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade800],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _viewModel.errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onTap,
    required String text,
    required IconData icon,
    required Gradient gradient,
    bool isSmaller = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: isSmaller ? 50 : 65,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isSmaller ? 25 : 32),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isSmaller ? 25 : 32),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: isSmaller ? 20 : 24),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmaller ? 16 : 18,
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
    );
  }

  Widget _buildAnimatedIcon() {
    if (_animatingIcon == null) return const SizedBox.shrink();

    // Different animations based on icon type
    if (_animatingIcon == Icons.flash_on) {
      // Rocket launch animation - moves up with trail effect
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Rocket trail effect
              if (_iconMoveAnimation.value < -50)
                ...List.generate(5, (index) {
                  final opacity = (1 - (index * 0.2)) * _opacityAnimation.value;
                  final trailOffset = _iconMoveAnimation.value + (index * 30);
                  return Transform.translate(
                    offset: Offset(0, trailOffset),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Icon(
                        Icons.circle,
                        size: 8 - (index * 1.5),
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              // Main rocket icon
              Transform.translate(
                offset: Offset(0, _iconMoveAnimation.value),
                child: Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Transform.rotate(
                    angle: (_iconRotationAnimation.value * 3.14159) / 180,
                    child: Icon(_animatingIcon, size: 80, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (_animatingIcon == Icons.emoji_events) {
      // Trophy bounce and glow animation
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 120 * _iconScaleAnimation.value,
                height: 120 * _iconScaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(
                        0.6 * _opacityAnimation.value,
                      ),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Floating sparkles around trophy
              ...List.generate(8, (index) {
                final angle = (index * 45) + (_iconRotationAnimation.value * 2);
                final distance = 60 + (10 * _iconScaleAnimation.value);
                final x = distance * cos(angle * 3.14159 / 180);
                final y = distance * sin(angle * 3.14159 / 180);
                return Transform.translate(
                  offset: Offset(x, y),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Icon(
                      Icons.star,
                      size: 12 + (8 * _iconScaleAnimation.value),
                      color: Colors.yellow,
                    ),
                  ),
                );
              }),
              // Main trophy icon with bounce
              Transform.translate(
                offset: Offset(
                  0,
                  sin(_iconRotationAnimation.value * 3.14159 / 180) * 20,
                ),
                child: Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Icon(_animatingIcon, size: 80, color: Colors.yellow),
                ),
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
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
}
