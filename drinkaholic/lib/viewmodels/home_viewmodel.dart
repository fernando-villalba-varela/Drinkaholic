import 'package:flutter/material.dart';
import '../screens/participants_screen.dart';
import '../screens/league_list_screen.dart';
import '../models/button_config.dart';

class HomeViewModel extends ChangeNotifier {
  final bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  static const LinearGradient quickGameGradient = LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]);

  static const LinearGradient leagueGradient = LinearGradient(colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)]);

  void navigateToQuickGame(BuildContext context) {
    try {
      _clearError();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ParticipantsScreen(title: 'Partida Rápida')),
      );
    } catch (e) {
      _setError('Error al navegar a Partida Rápida: ${e.toString()}');
    }
  }

  void navigateToLeague(BuildContext context) {
    try {
      _clearError();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeagueListScreen()));
    } catch (e) {
      _setError('Error al navegar a Liga: ${e.toString()}');
    }
  }

  ButtonConfig getQuickGameButtonConfig(
    BuildContext context,
    Function(Gradient, String, IconData, VoidCallback) onAnimatedTap,
  ) {
    return ButtonConfig(
      text: 'PARTIDA RÁPIDA',
      icon: Icons.flash_on,
      gradient: quickGameGradient,
      onTap: () {
        onAnimatedTap(quickGameGradient, 'PARTIDA RÁPIDA', Icons.flash_on, () => navigateToQuickGame(context));
      },
    );
  }

  ButtonConfig getLeagueButtonConfig(
    BuildContext context,
    Function(Gradient, String, IconData, VoidCallback) onAnimatedTap,
  ) {
    return ButtonConfig(
      text: 'LIGA',
      icon: Icons.emoji_events,
      gradient: leagueGradient,
      onTap: () {
        onAnimatedTap(leagueGradient, 'LIGA', Icons.emoji_events, () => navigateToLeague(context));
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

  @override
  // ignore: unnecessary_overrides
  void dispose() {
    super.dispose();
  }
}
