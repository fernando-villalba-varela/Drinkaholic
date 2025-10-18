import 'league_player_stats.dart';
import 'match_result.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';

class League {
  final String id;
  String name;
  String code;
  final List<LeaguePlayerStats> players;
  final List<MatchResult> matches;
  
  // Rachas consecutivas entre partidas
  int? currentMvpStreak; // playerId del actual MVP en racha
  int mvpStreakCount; // cuántas veces consecutivas ha ganado
  int? currentRatitaStreak; // playerId de la actual Ratita en racha  
  int ratitaStreakCount; // cuántas veces consecutivas ha perdido

  League({
    required this.id,
    required this.name,
    required this.code,
    required this.players,
    List<MatchResult>? matches,
    this.currentMvpStreak,
    this.mvpStreakCount = 0,
    this.currentRatitaStreak,
    this.ratitaStreakCount = 0,
  }) : matches = matches ?? <MatchResult>[];

  factory League.newLeague(String name) => League(
    id: const Uuid().v4(),
    name: name,
    code: const Uuid().v4().substring(0, 8),
    players: [],
    mvpStreakCount: 0,
    ratitaStreakCount: 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'players': players.map((p) => p.toJson()).toList(),
    'matches': matches.map((m) => m.toJson()).toList(),
    'currentMvpStreak': currentMvpStreak,
    'mvpStreakCount': mvpStreakCount,
    'currentRatitaStreak': currentRatitaStreak,
    'ratitaStreakCount': ratitaStreakCount,
  };

  factory League.fromJson(Map<String, dynamic> j) => League(
    id: j['id'],
    name: j['name'],
    code: j['code'],
    players: (j['players'] as List)
        .map((e) => LeaguePlayerStats.fromJson(e))
        .toList(),
    matches: (j['matches'] as List)
        .map((e) => MatchResult.fromJson(e))
        .toList(),
    currentMvpStreak: j['currentMvpStreak'],
    mvpStreakCount: j['mvpStreakCount'] ?? 0,
    currentRatitaStreak: j['currentRatitaStreak'],
    ratitaStreakCount: j['ratitaStreakCount'] ?? 0,
  );
}
