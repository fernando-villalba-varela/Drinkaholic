import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/league_detail_viewmodel.dart';
import '../../../models/player.dart';
import '../../../screens/league_game_screen.dart';
import '../../../screens/game_results_screen.dart';

class PlayTab extends StatefulWidget {
  const PlayTab({super.key});

  @override
  State<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<PlayTab> {
  final Set<int> _selected = {};
  bool _isProcessingGameEnd = false;

  ImageProvider? _avatar(String? path) {
    if (path == null) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    final f = File(path);
    if (f.existsSync()) return FileImage(f);
    return null;
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Map<int, String> _saveGameResults(Map<int, int> playerDrinks) {
    final vm = context.read<LeagueDetailViewModel>();

    // Usar el método correcto del ViewModel que maneja toda la lógica de puntuación
    final streakMessages = vm.recordMatch(playerDrinks);

    setState(() {
      _selected.clear(); // Limpiar selección después de guardar
    });

    return streakMessages;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final players = vm.league.players;

    // Si no hay jugadores, mostrar mensaje
    if (players.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports_outlined, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No hay jugadores',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega jugadores desde la pestaña "Jugadores"',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: players.length,
            itemBuilder: (_, i) {
              final p = players[i];
              final selected = _selected.contains(p.playerId);
              final img = _avatar(p.avatarPath);
              return Card(
                elevation: 0,
                color: selected
                    ? Theme.of(context).colorScheme.primary.withAlpha(0x2E)
                    : Theme.of(context).cardColor.withAlpha(0x0D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selected ? Theme.of(context).colorScheme.primary : const Color(0x40808080),
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _toggle(p.playerId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: img,
                          child: img == null
                              ? Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                        ),
                        Checkbox.adaptive(value: selected, onChanged: (_) => _toggle(p.playerId)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_drink),
              label: Text(
                _selected.length >= 2
                    ? '¡Que dios os bendiga!'
                    : players.length < 2
                    ? 'Necesitas al menos 2 jugadores'
                    : 'Selecciona al menos 2 jugadores',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                disabledBackgroundColor: const Color(0x5987CEEB),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: (_selected.length >= 2 && players.length >= 2)
                  ? () {
                      // Capturar el TabController ANTES de navegar
                      final tabController = DefaultTabController.of(context);

                      // Convertir los jugadores seleccionados de LeaguePlayerStats a Player
                      final selectedPlayers = players.where((p) => _selected.contains(p.playerId)).map((leaguePlayer) {
                        // Convertir avatarPath a File o mantener como asset
                        File? imagen;
                        String? avatar;

                        if (leaguePlayer.avatarPath != null) {
                          if (leaguePlayer.avatarPath!.startsWith('assets/')) {
                            avatar = leaguePlayer.avatarPath;
                          } else {
                            final file = File(leaguePlayer.avatarPath!);
                            if (file.existsSync()) {
                              imagen = file;
                            }
                          }
                        }

                        return Player(
                          id: leaguePlayer.playerId,
                          nombre: leaguePlayer.name,
                          imagen: imagen,
                          avatar: avatar,
                        );
                      }).toList();

                      // Navegar a LeagueGameScreen con los jugadores convertidos
                      // Generar número aleatorio entre 30 y 50 rondas
                      final random = Random();
                      final maxRounds = 30 + random.nextInt(21); // 30 a 50

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeagueGameScreen(
                            players: selectedPlayers,
                            maxRounds: maxRounds,
                            onGameEnd: (playerDrinks) {
                              // Prevenir múltiples ejecuciones
                              if (_isProcessingGameEnd) return;
                              _isProcessingGameEnd = true;

                              // Procesar resultados y obtener mensajes de rachas
                              final streakMessages = _saveGameResults(playerDrinks);

                              // Navegar a GameResultsScreen con los mensajes de rachas
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameResultsScreen(
                                    players: selectedPlayers,
                                    playerDrinks: playerDrinks,
                                    maxRounds: maxRounds,
                                    streakMessages: streakMessages,
                                    onConfirm: () {
                                      // Cerrar GameResultsScreen
                                      Navigator.pop(context);
                                      // Cerrar también LeagueGameScreen para volver a PlayTab
                                      Navigator.pop(context);
                                      // Cambiar a la pestaña del scoreboard usando el controlador capturado
                                      if (mounted) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          tabController.animateTo(0);
                                        });
                                      }
                                      // Resetear el flag
                                      _isProcessingGameEnd = false;
                                    },
                                  ),
                                ),
                              ).then((_) {
                                // Resetear el flag si se cierra la pantalla de otra manera
                                _isProcessingGameEnd = false;
                              });
                            },
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
