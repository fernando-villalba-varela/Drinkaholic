import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/participants_screen.dart';

class HomeViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Navigation methods
  void navigateToQuickGame(BuildContext context) {
    try {
      _clearError();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ParticipantsScreen(title: 'Partida Rápida'),
        ),
      );
    } catch (e) {
      _setError('Error al navegar a Partida Rápida: ${e.toString()}');
    }
  }

  // Exit functionality
  void showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23606E),
          title: const Text(
            '¿Deseas salir de la aplicación?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => _cancelExit(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => _confirmExit(),
              child: const Text('Aceptar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Private helper methods
  void _cancelExit(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _confirmExit() {
    try {
      SystemNavigator.pop();
    } catch (e) {
      _setError('Error al salir de la aplicación: ${e.toString()}');
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23606E),
          title: Text(
            '$feature - Próximamente',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Esta función estará disponible pronto.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    super.dispose();
  }
}
