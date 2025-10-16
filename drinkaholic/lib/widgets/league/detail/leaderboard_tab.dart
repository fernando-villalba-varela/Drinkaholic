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
                    color: pos == 1 ? Colors.amber : Colors.black,
                  ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
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
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
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
              color: theme.colorScheme.primary.withAlpha(0x14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(0x59),
              ),
            ),
            child: Text(
              '${p.points} pts',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
