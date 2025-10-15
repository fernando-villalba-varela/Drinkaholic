import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/league_list_viewmodel.dart';
import '../viewmodels/league_detail_viewmodel.dart';
import '../models/league.dart';
import 'league_detail_screen.dart';

class LeagueListScreen extends StatefulWidget {
  const LeagueListScreen({super.key});

  @override
  State<LeagueListScreen> createState() => _LeagueListScreenState();
}

class _LeagueListScreenState extends State<LeagueListScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));
    
    _backgroundAnimationController.repeat();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    return Consumer<LeagueListViewModel>(
      builder: (_, vm, __) => Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // Back button with quick_game_screen style
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
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title with enhanced styling
              const Expanded(
                child: Text(
                  'LIGAS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: Colors.purple,
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Import button with quick_game_screen style
              GestureDetector(
                onTap: () => _importLeagueDialog(context),
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
                    Icons.download,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background gradient with Liga button colors
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFC466B), // Pink/Red from Liga button
                    Color(0xFF3F5EFB), // Purple/Blue from Liga button
                  ],
                ),
              ),
            ),
            // Animated background
            _buildAnimatedBackground(),
            // Main content
            SafeArea(
              child: vm.leagues.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 120, 16, 140),
                      itemCount: vm.leagues.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (_, i) => _LeagueCard(league: vm.leagues[i]),
                    ),
            ),
          ],
        ),
        floatingActionButton: _FabNewLeague(
          onPressed: () => _createLeagueDialog(context),
        ),
      ),
    );
  }

  void _createLeagueDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16363F),
        title: const Text(
          'Crear nueva liga',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.tealAccent,
          decoration: const InputDecoration(
            labelText: 'Nombre de la liga',
            labelStyle: TextStyle(color: Colors.tealAccent),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.tealAccent),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitCreate(context, nameCtrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.tealAccent.shade700,
            ),
            onPressed: () => _submitCreate(context, nameCtrl),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _submitCreate(BuildContext context, TextEditingController c) {
    final name = c.text.trim();
    if (name.isNotEmpty) {
      context.read<LeagueListViewModel>().createLeague(name);
    }
    Navigator.pop(context);
  }

  void _importLeagueDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16363F),
        title: const Text(
          'Importar liga (JSON)',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: jsonCtrl,
          maxLines: 8,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Pega aquí el JSON exportado',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.tealAccent.shade700,
            ),
            onPressed: () {
              final raw = jsonCtrl.text.trim();
              if (raw.isNotEmpty) {
                final map = _safeDecode(raw);
                if (map != null) {
                  final league = League.fromJson(map);
                  final vm = context.read<LeagueListViewModel>();
                  final exists = vm.leagues.any((l) => l.id == league.id);
                  if (!exists) {
                    vm.createLeague(league.name);
                  }
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _safeDecode(String raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_drink, size: 110, color: Colors.amber.shade500),
          const SizedBox(height: 34),
          const Text(
            'Aún no eres un borracho',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: .5,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Pulsa "Nueva liga" para emborracharte de gloria o importa una liga de tu amigo.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingShapesPainter extends CustomPainter {
  final double animationValue;
  
  FloatingShapesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
      
    // Create multiple floating shapes with different speeds and sizes
    final shapes = [
      // Large circles
      _FloatingShape(
        Offset(size.width * 0.1 + (sin(animationValue * 2 * pi) * 30),
               size.height * 0.2 + (cos(animationValue * 2 * pi) * 20)),
        30,
        Colors.white.withOpacity(0.05),
      ),
      _FloatingShape(
        Offset(size.width * 0.8 + (sin(animationValue * 2 * pi + 1) * 40),
               size.height * 0.7 + (cos(animationValue * 2 * pi + 1) * 30)),
        25,
        Colors.white.withOpacity(0.08),
      ),
      // Medium circles
      _FloatingShape(
        Offset(size.width * 0.3 + (sin(animationValue * 2 * pi + 2) * 50),
               size.height * 0.5 + (cos(animationValue * 2 * pi + 2) * 25)),
        20,
        Colors.white.withOpacity(0.04),
      ),
      _FloatingShape(
        Offset(size.width * 0.7 + (sin(animationValue * 2 * pi + 3) * 35),
               size.height * 0.3 + (cos(animationValue * 2 * pi + 3) * 40)),
        18,
        Colors.pink.withOpacity(0.06),
      ),
      // Small circles
      _FloatingShape(
        Offset(size.width * 0.5 + (sin(animationValue * 2 * pi + 4) * 60),
               size.height * 0.8 + (cos(animationValue * 2 * pi + 4) * 15)),
        12,
        Colors.white.withOpacity(0.03),
      ),
      _FloatingShape(
        Offset(size.width * 0.9 + (sin(animationValue * 2 * pi + 5) * 25),
               size.height * 0.1 + (cos(animationValue * 2 * pi + 5) * 35)),
        15,
        Colors.purple.withOpacity(0.05),
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

class _LeagueCard extends StatelessWidget {
  final League league;
  const _LeagueCard({required this.league});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // Glass background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.18),
                    Colors.white.withOpacity(.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  width: 1.2,
                  color: Colors.white.withOpacity(.22),
                ),
              ),
            ),
          ),
          // Light sheen
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(.10), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                final listVM = context.read<LeagueListViewModel>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => LeagueDetailViewModel(
                        league,
                        listVM,
                      ), // <-- pasar listVM
                      child: const LeagueDetailScreen(),
                    ),
                  ),
                );
              },
              splashColor: Colors.tealAccent.withOpacity(.25),
              highlightColor: Colors.tealAccent.withOpacity(.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _AvatarBadge(text: league.name),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            league.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _ParticipantsPill(count: league.players.length),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String text;
  const _AvatarBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF0f9b8e), Color(0xFF0a5f6d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.45),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text.isNotEmpty ? text[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _ParticipantsPill extends StatelessWidget {
  final int count;
  const _ParticipantsPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group, size: 14, color: Colors.tealAccent),
          const SizedBox(width: 4),
          Text(
            '$count participantes',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FabNewLeague extends StatelessWidget {
  final VoidCallback onPressed;
  const _FabNewLeague({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      foregroundColor: Colors.black87,
      backgroundColor: Colors.tealAccent.shade200,
      elevation: 4,
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Nueva liga'),
    );
  }
}
