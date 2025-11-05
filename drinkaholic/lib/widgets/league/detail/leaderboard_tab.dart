import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/league_detail_viewmodel.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

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
      ..sort((a, b) {
        final pointsComparison = b.points.compareTo(a.points);
        if (pointsComparison != 0) return pointsComparison;
        return b.totalDrinks.compareTo(a.totalDrinks);
      });
    final lastPos = players.length;

    // Si no hay jugadores, mostrar mensaje
    if (players.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No hay jugadores',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega jugadores desde la pestaña "Jugadores"',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        final img = _avatar(p.avatarPath);
        final pos = i + 1;
        final league = vm.league;
        final isMvpStreak = league.currentMvpStreak == p.playerId && league.mvpStreakCount >= 2;
        final isRatitaStreak = league.currentRatitaStreak == p.playerId && league.ratitaStreakCount >= 2;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: SizedBox(
            width: 84,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$pos',
                  style: TextStyle(fontWeight: FontWeight.w700, color: pos == 1 ? Colors.amber : Colors.black),
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundImage: img,
                      child: img == null
                          ? Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    if (pos == 1)
                      Positioned(
                        top: -30,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '👑',
                            style: TextStyle(
                              fontSize: 24,
                              shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                        ),
                      ),
                    if (pos == lastPos && lastPos > 1)
                      Positioned(
                        top: -23,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '🐭',
                            style: TextStyle(
                              fontSize: 20,
                              shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(p.name)),
              if (isMvpStreak)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text('🔥${league.mvpStreakCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              if (isRatitaStreak)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text('💩${league.ratitaStreakCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          subtitle: Text(
            'MVDP: ${p.mvdpCount} | Tragos: ${p.totalDrinks} | Ratita: ${p.ratitaCount} | Partidas: ${p.gamesPlayed}',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(0x14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(0x59)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${p.points} pts',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                ),
                // Quitamos las coronas y ratitas adicionales de los puntos
                // Solo se muestran el fuego y caca en el nombre
              ],
            ),
          ),
        );
      },
    );
  }
}
