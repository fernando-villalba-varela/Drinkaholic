import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/league.dart';
import '../services/league_storage_service.dart';

class LeagueListViewModel extends ChangeNotifier {
  final List<League> _leagues = [];
  final LeagueStorageService _storageService = LeagueStorageService();
  bool _isLoaded = false;

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

  League? byId(String id) => _leagues.where((l) => l.id == id).cast<League?>().firstOrNull;

  // export simple
  String exportLeague(League l) => l.toJson().toString();

  // Dialog methods
  void showCreateLeagueDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16363F),
        title: const Text('Crear nueva liga', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.tealAccent,
          decoration: const InputDecoration(
            labelText: 'Nombre de la liga',
            labelStyle: TextStyle(color: Colors.tealAccent),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitCreateLeague(context, nameCtrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.tealAccent.shade700),
            onPressed: () => _submitCreateLeague(context, nameCtrl),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _submitCreateLeague(BuildContext context, TextEditingController c) {
    final name = c.text.trim();
    if (name.isNotEmpty) {
      createLeague(name);
    }
    Navigator.pop(context);
  }

  void showImportLeagueDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16363F),
        title: const Text('Importar liga (JSON)', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: jsonCtrl,
          maxLines: 8,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Pega aquí el JSON exportado',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.tealAccent.shade700),
            onPressed: () {
              final raw = jsonCtrl.text.trim();
              if (raw.isNotEmpty) {
                final map = _safeDecode(raw);
                if (map != null) {
                  final league = League.fromJson(map);
                  final exists = _leagues.any((l) => l.id == league.id);
                  if (!exists) {
                    createLeague(league.name);
                  }
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _safeDecode(String raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
