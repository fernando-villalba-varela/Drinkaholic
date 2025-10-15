import 'package:flutter/material.dart';
import '../models/league.dart';

class LeagueListViewModel extends ChangeNotifier {
  final List<League> _leagues = [];

  List<League> get leagues => List.unmodifiable(_leagues);

  void createLeague(String name) {
    _leagues.add(League.newLeague(name));
    notifyListeners();
  }

  void addLeague(League league) {
    _leagues.add(league);
    notifyListeners();
  }

  void deleteLeague(String id) {
    _leagues.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  League? byId(String id) =>
      _leagues.where((l) => l.id == id).cast<League?>().firstOrNull;

  // export simple
  String exportLeague(League l) => l.toJson().toString();
}
