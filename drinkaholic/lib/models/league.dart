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

  League({
    required this.id,
    required this.name,
    required this.code,
    required this.players,
    List<MatchResult>? matches,
  }) : matches = matches ?? <MatchResult>[];

  factory League.newLeague(String name) => League(
    id: const Uuid().v4(),
    name: name,
    code: const Uuid().v4().substring(0, 8),
    players: [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'players': players.map((p) => p.toJson()).toList(),
    'matches': matches.map((m) => m.toJson()).toList(),
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
  );
}
