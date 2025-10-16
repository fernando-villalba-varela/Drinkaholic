import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home/modern_button.dart';
import '../widgets/home/animated_icon_widget.dart';
import '../widgets/home/floating_particle.dart';

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
                    colors: [
                      Color(0xFF2D1B69),
                      Color(0xFF11072C),
                      Color(0xFF0D0221),
                    ],
                  ),
                ),
              ),
              ...List.generate(
                6,
                (index) => FloatingParticle(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  index: index,
                ),
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
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x4DD4A373),
                                    blurRadius: 30.r,
                                    spreadRadius: 10.r,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/drinkaholic_logo.gif',
                                width: 160.w,
                                height: 160.w,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFD4A373),
                                  Color(0xFFB8860B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'DRINKAHOLIC',
                                style: TextStyle(
                                  fontSize: 42.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.5,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(2.w, 2.h),
                                      blurRadius: 4.r,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 6.h),
                            Text(
                              'A beber como los duendes',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xCCFFFFFF),
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w300,
                              ),
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
                                final config = _viewModel
                                    .getQuickGameButtonConfig(
                                      context,
                                      _startAnimatedNavigation,
                                    );
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
                                final config = _viewModel.getLeagueButtonConfig(
                                  context,
                                  _startAnimatedNavigation,
                                );
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
                                    if (_scaleAnimation.value > 0.3)
                                      Center(
                                        child: AnimatedIconWidget(
                                          animatingIcon: _animatingIcon,
                                          animationController:
                                              _animationController,
                                          opacityAnimation: _opacityAnimation,
                                          iconMoveAnimation: _iconMoveAnimation,
                                          iconScaleAnimation:
                                              _iconScaleAnimation,
                                          iconRotationAnimation:
                                              _iconRotationAnimation,
                                        ),
                                      ),
                                    if (_scaleAnimation.value > 0.8)
                                      FadeTransition(
                                        opacity: _opacityAnimation,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 200),
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
                          color: const Color(0x4DF44336),
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
}
