import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Mantener si Gridient/Color se usan aquí o en constantes, pero idealmente desacoplar.
// En este caso, dejamos Gradient constants aquí por conveniencia de diseño centralizado,
// pero eliminamos la lógica de navegación y contexto.

class HomeViewModel extends ChangeNotifier {
  final bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  static const LinearGradient quickGameGradient =
      LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]);

  static const LinearGradient leagueGradient =
      LinearGradient(colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)]);

  static const LinearGradient elixirsGradient =
      LinearGradient(colors: [Color(0xFFFFD200), Color(0xFFF7971E)]);

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  // ignore: unnecessary_overrides
  void dispose() {
    super.dispose();
  }
}
