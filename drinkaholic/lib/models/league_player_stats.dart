class LeaguePlayerStats {
  final int playerId;
  String name;
  String? avatarPath;

  int points;
  int totalDrinks;
  int drinksGiven;
  int mvdpCount;
  int ratitaCount;
  int gamesPlayed;
  bool lastWasRatita;

  LeaguePlayerStats({
    required this.playerId,
    required this.name,
    this.avatarPath,
    this.points = 0,
    this.totalDrinks = 0,
    this.drinksGiven = 0,
    this.mvdpCount = 0,
    this.ratitaCount = 0,
    this.gamesPlayed = 0,
    this.lastWasRatita = false,
  });

  void applyGame({required int drinks, bool isMvp = false, bool isRatita = false, int bonusDrinks = 0}) {
    totalDrinks += drinks + bonusDrinks;
    gamesPlayed++;
    if (isMvp) mvdpCount++;
    if (isRatita) {
      ratitaCount++;
      lastWasRatita = true;
    } else {
      lastWasRatita = false;
    }
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'name': name,
    'avatarPath': avatarPath,
    'points': points,
    'totalDrinks': totalDrinks,
    'drinksGiven': drinksGiven,
    'mvdpCount': mvdpCount,
    'ratitaCount': ratitaCount,
    'gamesPlayed': gamesPlayed,
    'lastWasRatita': lastWasRatita,
  };

  factory LeaguePlayerStats.fromJson(Map<String, dynamic> j) => LeaguePlayerStats(
    playerId: j['playerId'],
    name: j['name'],
    avatarPath: j['avatarPath'],
    points: j['points'],
    totalDrinks: j['totalDrinks'],
    drinksGiven: j['drinksGiven'],
    mvdpCount: j['mvdpCount'],
    ratitaCount: j['ratitaCount'],
    gamesPlayed: j['gamesPlayed'],
    lastWasRatita: j['lastWasRatita'],
  );
}
