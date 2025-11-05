import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/league.dart';
import '../../viewmodels/league_list_viewmodel.dart';
import '../../viewmodels/league_detail_viewmodel.dart';
import '../../screens/league_detail_screen.dart';

class LeagueCard extends StatelessWidget {
  final League league;

  const LeagueCard({super.key, required this.league});

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
                gradient: const LinearGradient(
                  colors: [
                    Color(0x2EFFFFFF), // white with 18% opacity
                    Color(0x14FFFFFF), // white with 8% opacity
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  width: 1.2,
                  color: const Color(0x38FFFFFF), // white with 22% opacity
                ),
              ),
            ),
          ),
          // Light sheen
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x1AFFFFFF), // white with 10% opacity
                    Colors.transparent,
                  ],
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
                      create: (_) => LeagueDetailViewModel(league, listVM),
                      child: const LeagueDetailScreen(),
                    ),
                  ),
                );
              },
              splashColor: const Color(0x40009688), // tealAccent with 25% opacity
              highlightColor: const Color(0x14009688), // tealAccent with 8% opacity
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    AvatarBadge(text: league.name),
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
                          Row(children: [ParticipantsPill(count: league.players.length)]),
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

class AvatarBadge extends StatelessWidget {
  final String text;

  const AvatarBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0f9b8e), Color(0xFF0a5f6d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x73000000), // black with 45% opacity
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text.isNotEmpty ? text[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }
}

class ParticipantsPill extends StatelessWidget {
  final int count;

  const ParticipantsPill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x59000000), // black with 35% opacity
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0x40FFFFFF), // white with 25% opacity
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group, size: 14, color: Colors.tealAccent),
          const SizedBox(width: 4),
          Text('$count participantes', style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: .2)),
        ],
      ),
    );
  }
}
