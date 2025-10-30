class DrinkTransfer {
  final int fromPlayerId;
  final int toPlayerId;
  final int amount;
  DrinkTransfer({required this.fromPlayerId, required this.toPlayerId, required this.amount});

  Map<String, dynamic> toJson() => {'from': fromPlayerId, 'to': toPlayerId, 'amount': amount};

  factory DrinkTransfer.fromJson(Map<String, dynamic> j) =>
      DrinkTransfer(fromPlayerId: j['from'], toPlayerId: j['to'], amount: j['amount']);
}

class MatchResult {
  final String id;
  final String leagueId;
  final DateTime date;
  final Map<int, int> perPlayerDrinks;
  final List<int> mvpPlayerIds;
  final List<int> ratitaPlayerIds;
  final List<DrinkTransfer> transfers;

  MatchResult({
    required this.id,
    required this.leagueId,
    required this.date,
    required this.perPlayerDrinks,
    required this.mvpPlayerIds,
    required this.ratitaPlayerIds,
    this.transfers = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'leagueId': leagueId,
    'date': date.toIso8601String(),
    'perPlayerDrinks': perPlayerDrinks.map((k, v) => MapEntry(k.toString(), v)),
    'mvpPlayerIds': mvpPlayerIds,
    'ratitaPlayerIds': ratitaPlayerIds,
    'transfers': transfers.map((e) => e.toJson()).toList(),
  };

  factory MatchResult.fromJson(Map<String, dynamic> j) => MatchResult(
    id: j['id'],
    leagueId: j['leagueId'],
    date: DateTime.parse(j['date']),
    perPlayerDrinks: (j['perPlayerDrinks'] as Map).map((k, v) => MapEntry(int.parse(k as String), v as int)),
    mvpPlayerIds: List<int>.from(j['mvpPlayerIds']),
    ratitaPlayerIds: List<int>.from(j['ratitaPlayerIds']),
    transfers: (j['transfers'] as List).map((e) => DrinkTransfer.fromJson(e)).toList(),
  );
}
