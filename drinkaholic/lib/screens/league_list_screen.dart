import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/league_list_viewmodel.dart';
import '../viewmodels/league_detail_viewmodel.dart';
import '../models/league.dart';
import 'league_detail_screen.dart';

class LeagueListScreen extends StatelessWidget {
  const LeagueListScreen({super.key});

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
          backgroundColor: Colors.black.withOpacity(.55),
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          title: const Text('Ligas'),
          actions: [
            IconButton(
              tooltip: 'Importar liga',
              color: Colors.white,
              onPressed: () => _importLeagueDialog(context),
              icon: const Icon(Icons.download),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/potion_background.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(.55),
                  Colors.black.withOpacity(.30),
                  Colors.black.withOpacity(.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: vm.leagues.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 140),
                    itemCount: vm.leagues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (_, i) => _LeagueCard(league: vm.leagues[i]),
                  ),
          ),
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
