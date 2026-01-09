import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/league.dart';
import '../services/league_storage_service.dart';

class LeagueListViewModel extends ChangeNotifier {
  final List<League> _leagues = [];
  final LeagueStorageService _storageService;
  bool _isLoaded = false;

  LeagueListViewModel({required LeagueStorageService storageService})
      : _storageService = storageService;

  List<League> get leagues => List.unmodifiable(_leagues);
  bool get isLoaded => _isLoaded;

  /// Carga las ligas guardadas al iniciar
  Future<void> loadLeagues() async {
    if (_isLoaded) return; // Ya cargadas

    final loadedLeagues = await _storageService.loadLeagues();
    _leagues.clear();
    _leagues.addAll(loadedLeagues);
    _isLoaded = true;
    notifyListeners();
  }

  /// Guarda todas las ligas
  Future<void> _saveLeagues() async {
    await _storageService.saveLeagues(_leagues);
  }

  void createLeague(String name) {
    _leagues.add(League.newLeague(name));
    _saveLeagues(); // Guardar automáticamente
    notifyListeners();
  }

  void addLeague(League league) {
    _leagues.add(league);
    _saveLeagues(); // Guardar automáticamente
    notifyListeners();
  }

  void deleteLeague(String id) {
    _leagues.removeWhere((l) => l.id == id);
    _saveLeagues(); // Guardar automáticamente
    notifyListeners();
  }

  void refresh() {
    _saveLeagues(); // Guardar cuando se actualice
    notifyListeners();
  }

  League? byId(String id) =>
      _leagues.where((l) => l.id == id).cast<League?>().firstOrNull;

  // export simple
  String exportLeague(League l) => l.toJson().toString();

  /// Intenta importar una liga desde un JSON.
  /// Retorna true si se creó exitosamente, false si falló o ya existía.
  bool importLeagueFromJson(String rawJson) {
    final map = _safeDecode(rawJson);
    if (map != null) {
      try {
        final league = League.fromJson(map);
        final exists = _leagues.any((l) => l.id == league.id);
        if (!exists) {
          // Nota original: createLeague crea una NUEVA liga con el nombre, no importa todos los datos.
          // Manteniendo comportamiento original.
          createLeague(league.name);
          return true;
        }
      } catch (e) {
        if (kDebugMode) print('Error parsing league: $e');
      }
    }
    return false;
  }

  Map<String, dynamic>? _safeDecode(String raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
