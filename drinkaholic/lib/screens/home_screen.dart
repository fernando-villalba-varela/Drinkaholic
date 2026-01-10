import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home/modern_button.dart';
import '../widgets/home/animated_icon_widget.dart';
import '../widgets/home/floating_particle.dart';
import '../screens/participants_screen.dart';
import '../screens/league_list_screen.dart';
import '../models/button_config.dart';
import 'dart:math';

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
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _iconMoveAnimation = Tween<double>(
      begin: 0.0,
      end: -200.0, // Move upward for rocket launch
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart));

    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 360.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
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

    await Future.delayed(const Duration(milliseconds: 200));

    onComplete();

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
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [Color(0xFF2D1B69), Color(0xFF11072C), Color(0xFF0D0221)],
                  ),
                ),
              ),
              ...List.generate(
                6,
                (index) => FloatingParticle(screenWidth: screenWidth, screenHeight: screenHeight, index: index),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo above title
                            Image.asset(
                              'assets/images/logo.png',
                              width: min(screenWidth * 0.4, 180),
                              height: min(screenWidth * 0.4, 180),
                              fit: BoxFit.contain,
                            ),
                            
                            SizedBox(height: 20.h),

                            // Title with epic styling connected to background
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outline stroke for readability
                                Text(
                                  'LA PREVIA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: min(screenWidth * 0.12, 88),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 3
                                      ..color = Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF7F5AF0), // neon violet
                                      Color(0xFF00D1FF), // cyan
                                    ],
                                  ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'LA PREVIA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: min(screenWidth * 0.12, 88),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF7F5AF0).withOpacity(0.45),
                                          blurRadius: 30,
                                          offset: const Offset(0, 0),
                                        ),
                                        Shadow(
                                          color: const Color(0xFF00D1FF).withOpacity(0.35),
                                          blurRadius: 30,
                                          offset: const Offset(0, 0),
                                        ),
                                        Shadow(color: Colors.black54, blurRadius: 8, offset: const Offset(2, 2)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 6.h),
                            Text(
                              'Powered by',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xCCFFFFFF),
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            
                            SizedBox(height: 16.h), // Increased from 8.h to 16.h
                            
                            // Promo image
                            Image.asset(
                              'assets/images/promo.png',
                              width: min(screenWidth * 0.25, 100),
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(
                              builder: (context) {
                                final config = _getQuickGameButtonConfig(context);
                                return ModernButton(
                                  onTap: config.onTap,
                                  text: config.text,
                                  icon: config.icon,
                                  gradient: config.gradient,
                                );
                              },
                            ),
                            SizedBox(height: 18.h),

                            Builder(
                              builder: (context) {
                                final config = _getLeagueButtonConfig(context);
                                return ModernButton(
                                  onTap: config.onTap,
                                  text: config.text,
                                  icon: config.icon,
                                  gradient: config.gradient,
                                );
                              },
                            ),
                            SizedBox(height: 18.h),

                            Builder(
                              builder: (context) {
                                final config = _getElixirsButtonConfig(context);
                                return ModernButton(
                                  onTap: config.onTap,
                                  text: config.text,
                                  icon: config.icon,
                                  gradient: config.gradient,
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Language Toggle Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: Consumer<LanguageService>(
                  builder: (context, languageService, child) {
                    return GestureDetector(
                      onTap: () => languageService.toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              languageService.isSpanish ? '🇪🇸' : '🇬🇧',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              languageService.isSpanish ? 'ES' : 'EN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isAnimating && _currentGradient != null)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(gradient: _currentGradient, shape: BoxShape.circle),
                          child: _scaleAnimation.value > 0.3
                              ? Stack(
                                  children: [
                                    if (_scaleAnimation.value > 0.3)
                                      Center(
                                        child: AnimatedIconWidget(
                                          animatingIcon: _animatingIcon,
                                          animationController: _animationController,
                                          opacityAnimation: _opacityAnimation,
                                          iconMoveAnimation: _iconMoveAnimation,
                                          iconScaleAnimation: _iconScaleAnimation,
                                          iconRotationAnimation: _iconRotationAnimation,
                                        ),
                                      ),
                                    if (_scaleAnimation.value > 0.8)
                                      FadeTransition(
                                        opacity: _opacityAnimation,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 200),
                                              const CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 3,
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                '$_animatingButtonText...',
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

              if (_viewModel.hasError)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.red.shade600, Colors.red.shade800]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: const Color(0x4DF44336), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _viewModel.errorMessage!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
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

  void _navigateToQuickGame() {
    try {
      _viewModel.clearError();
      final title = Provider.of<LanguageService>(context, listen: false).translate('play_quick'); // Use translated title
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ParticipantsScreen(title: title)),
      );
    } catch (e) {
      _viewModel.setError('Error al navegar a Partida Rápida: ${e.toString()}');
    }
  }

  void _navigateToLeague() {
    try {
      _viewModel.clearError();
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LeagueListScreen()));
    } catch (e) {
      _viewModel.setError('Error al navegar a Liga: ${e.toString()}');
    }
  }

  void _navigateToElixirs() {
    // Placeholder function for now
    final msg = Provider.of<LanguageService>(context, listen: false).isSpanish 
        ? 'Recarga de elixires próximamente' 
        : 'Elixir refill coming soon';
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  ButtonConfig _getQuickGameButtonConfig(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final text = languageService.translate('play_quick');
    return ButtonConfig(
      text: text,
      icon: Icons.flash_on,
      gradient: HomeViewModel.quickGameGradient,
      onTap: () {
        _startAnimatedNavigation(HomeViewModel.quickGameGradient,
            text, Icons.flash_on, _navigateToQuickGame);
      },
    );
  }

  ButtonConfig _getLeagueButtonConfig(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final text = languageService.translate('play_league');
    return ButtonConfig(
      text: text,
      icon: Icons.emoji_events,
      gradient: HomeViewModel.leagueGradient,
      onTap: () {
        _startAnimatedNavigation(HomeViewModel.leagueGradient, text,
            Icons.emoji_events, _navigateToLeague);
      },
    );
  }

  ButtonConfig _getElixirsButtonConfig(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final text = languageService.translate('menu_reload_elixirs');
    return ButtonConfig(
      text: text,
      icon: Icons.local_drink,
      gradient: HomeViewModel.elixirsGradient,
      onTap: () {
        _startAnimatedNavigation(HomeViewModel.elixirsGradient,
            text, Icons.local_drink, _navigateToElixirs);
      },
    );
  }
}
