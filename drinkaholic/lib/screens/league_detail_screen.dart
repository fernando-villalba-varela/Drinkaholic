import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/league_detail_viewmodel.dart';

class LeagueDetailScreen extends StatefulWidget {
  const LeagueDetailScreen({super.key});

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
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
    final vm = context.watch<LeagueDetailViewModel>();
    final league = vm.league;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
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
              Expanded(
                child: Text(
                  league.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
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
              // Export button with quick_game_screen style
              GestureDetector(
                onTap: () => _showExportDialog(context, league),
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
                    Icons.upload_file,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicator: BoxDecoration(),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: 'Scoreboard'),
                    Tab(text: 'Jugadores'),
                    Tab(text: 'Jugar'),
                  ],
                ),
              ),
            ),
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
            const SafeArea(
              child: TabBarView(
                children: [_LeaderboardTab(), _ParticipantsTab(), _PlayTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, league) {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(league.toJson());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exportar liga'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(jsonString)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(context);
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  ImageProvider? _avatar(String? path) {
    if (path == null) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    final f = File(path);
    if (f.existsSync()) return FileImage(f);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<LeagueDetailViewModel>();
    final players = [...vm.league.players]
      ..sort((a, b) => b.points.compareTo(a.points));

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        final img = _avatar(p.avatarPath);
        final pos = i + 1;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: SizedBox(
            width: 84,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$pos',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundImage: img,
                  child: img == null
                      ? Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ],
            ),
          ),
          title: Text(p.name),
          subtitle: Text(
            'MVDP: ${p.mvdpCount} | Tragos: ${p.totalDrinks} | Ratita: ${p.ratitaCount} | Partidas: ${p.gamesPlayed}',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(.35),
              ),
            ),
            child: Text(
              '${p.points} pts',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- PARTICIPANTES ----------------

class _ParticipantsTab extends StatefulWidget {
  const _ParticipantsTab();
  @override
  State<_ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends State<_ParticipantsTab> {
  final TextEditingController _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final players = vm.league.players;
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: players.length + 1,
        itemBuilder: (_, i) {
          if (i < players.length) {
            final p = players[i];
            return _PlayerCard(
              name: p.name,
              avatarPath: p.avatarPath,
              onAvatarTap: () => vm.showAvatarOptions(context, p.playerId),
              onTap: () => _confirmDelete(context, vm, p.playerId),
            );
          } else {
            return _AddPlayerCard(
              controller: _addCtrl,
              onAdd: () {
                final name = _addCtrl.text.trim();
                if (name.isEmpty) return;
                vm.addPlayer(
                  playerId: DateTime.now().microsecondsSinceEpoch,
                  name: name,
                );
                _addCtrl.clear();
              },
            );
          }
        },
      );
  }

  void _confirmDelete(BuildContext context, LeagueDetailViewModel vm, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar jugador'),
        content: const Text('¿Seguro que quieres eliminarlo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              vm.league.players.removeWhere((p) => p.playerId == id);
              vm.listVM.refresh();
              vm.notifyListeners();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name;
  final String? avatarPath;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const _PlayerCard({
    required this.name,
    required this.avatarPath,
    required this.onTap,
    required this.onAvatarTap,
  });

  ImageProvider? _avatarImage() {
    if (avatarPath == null) return null;
    if (avatarPath!.startsWith('assets/')) return AssetImage(avatarPath!);
    final f = File(avatarPath!);
    if (f.existsSync()) return FileImage(f);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final img = _avatarImage();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.35)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(.25),
                backgroundImage: img,
                child: img == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 3,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.touch_app,
              color: Colors.white.withOpacity(.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlayerCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  const _AddPlayerCard({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.35)),
        color: Colors.white.withOpacity(.12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(.25),
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Añadir jugador...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
// ---------------- FIN PARTICIPANTES ----------------

class _PlayTab extends StatefulWidget {
  const _PlayTab();
  @override
  State<_PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<_PlayTab> {
  final Set<int> _selected = {};

  ImageProvider? _avatar(String? path) {
    if (path == null) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    final f = File(path);
    if (f.existsSync()) return FileImage(f);
    return null;
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final players = vm.league.players;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: players.length,
            itemBuilder: (_, i) {
              final p = players[i];
              final selected = _selected.contains(p.playerId);
              final img = _avatar(p.avatarPath);
              return Card(
                elevation: 0,
                color: selected
                    ? Theme.of(context).colorScheme.primary.withOpacity(.18)
                    : Theme.of(context).cardColor.withOpacity(.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(.25),
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _toggle(p.playerId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: img,
                          child: img == null
                              ? Text(
                                  p.name.isNotEmpty
                                      ? p.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        Checkbox.adaptive(
                          value: selected,
                          onChanged: (_) => _toggle(p.playerId),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_drink),
              label: const Text('¡Que dios os bendiga!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                disabledBackgroundColor: Colors.lightBlueAccent.withOpacity(
                  .35,
                ),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: _selected.length > 1
                  ? () {
                      final map = <int, int>{};
                      for (final p in players) {
                        map[p.playerId] = _selected.contains(p.playerId)
                            ? 1
                            : 0;
                      }
                      vm.recordMatch(map);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Partida registrada para ${_selected.length} jugadores',
                          ),
                        ),
                      );
                      setState(_selected.clear);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
