import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/league.dart';

/// Servicio para persistir ligas usando SharedPreferences
class LeagueStorageService {
  static const String _keyLeagues = 'leagues';

  /// Guarda todas las ligas
  Future<void> saveLeagues(List<League> leagues) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = leagues.map((league) => league.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyLeagues, jsonString);
    } catch (e) {
      print('Error guardando ligas: $e');
    }
  }

  /// Carga todas las ligas guardadas
  Future<List<League>> loadLeagues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLeagues);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => League.fromJson(json)).toList();
    } catch (e) {
      print('Error cargando ligas: $e');
      return [];
    }
  }

  /// Elimina todas las ligas guardadas (útil para testing)
  Future<void> clearLeagues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLeagues);
    } catch (e) {
      print('Error eliminando ligas: $e');
    }
  }

  /// Guarda una liga específica (actualiza la lista completa)
  Future<void> saveLeague(League league, List<League> allLeagues) async {
    final index = allLeagues.indexWhere((l) => l.id == league.id);
    if (index >= 0) {
      allLeagues[index] = league;
    } else {
      allLeagues.add(league);
    }
    await saveLeagues(allLeagues);
  }

  /// Elimina una liga específica
  Future<void> deleteLeague(String leagueId, List<League> allLeagues) async {
    allLeagues.removeWhere((l) => l.id == leagueId);
    await saveLeagues(allLeagues);
  }
}
