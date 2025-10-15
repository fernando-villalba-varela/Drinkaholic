import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/league_detail_viewmodel.dart';

class LeagueDetailScreen extends StatelessWidget {
  const LeagueDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final league = vm.league;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(league.name),
          actions: [
            IconButton(
              tooltip: 'Exportar JSON',
              icon: const Icon(Icons.upload_file),
              onPressed: () => _showExportDialog(context, league),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Scoreboard'),
              Tab(text: 'Jugadores'),
              Tab(text: 'Jugar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LeaderboardTab(), _ParticipantsTab(), _PlayTab()],
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
        ),
      ),
      child: ListView.builder(
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
      ),
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
