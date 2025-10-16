import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/league_detail_viewmodel.dart';
import '../../../models/player.dart';
import '../../../screens/league_game_screen.dart';

class PlayTab extends StatefulWidget {
  const PlayTab({super.key});

  @override
  State<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<PlayTab> {
  final Set<int> _selected = {};

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

  void _saveGameResults(Map<int, int> playerDrinks) {
    final vm = context.read<LeagueDetailViewModel>();

    // playerDrinks ahora es Map<playerId, drinks>
    // Encontrar MVP (más tragos) y Ratita (menos tragos)
    int mvpPlayerId = -1;
    int ratitaPlayerId = -1;
    int maxDrinks = 0;
    int minDrinks = 999999;

    playerDrinks.forEach((playerId, drinks) {
      if (drinks > maxDrinks) {
        maxDrinks = drinks;
        mvpPlayerId = playerId;
      }
      if (drinks < minDrinks) {
        minDrinks = drinks;
        ratitaPlayerId = playerId;
      }
    });

    // Actualizar estadísticas SOLO de los jugadores que jugaron
    playerDrinks.forEach((playerId, drinks) {
      // Buscar el jugador por su playerId en la lista de la liga
      final playerStats = vm.league.players.firstWhere(
        (p) => p.playerId == playerId,
      );

      final isMvp = playerId == mvpPlayerId;
      final isRatita = playerId == ratitaPlayerId;

      // Actualizar tragos y partidas jugadas
      playerStats.totalDrinks += drinks;
      playerStats.gamesPlayed++;

      // Actualizar MVDP y Ratita counts
      if (isMvp) {
        playerStats.mvdpCount++;
        playerStats.points += 3; // MVP gana 3 puntos
        playerStats.lastWasRatita = false;
      } else if (isRatita) {
        playerStats.ratitaCount++;
        playerStats.points -= 3; // Ratita pierde 3 puntos
        playerStats.lastWasRatita = true;
      } else {
        playerStats.points += 1; // Resto gana 1 punto
        playerStats.lastWasRatita = false;
      }
    });

    // Guardar la liga con los datos actualizados
    vm.saveLeague();

    setState(() {
      _selected.clear(); // Limpiar selección después de guardar
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueDetailViewModel>();
    final players = vm.league.players;

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
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0x40808080),
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _toggle(p.playerId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: img,
                          child: img == null
                              ? Text(
                                  p.name.isNotEmpty
                                      ? p.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        Checkbox.adaptive(
                          value: selected,
                          onChanged: (_) => _toggle(p.playerId),
                        ),
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
              label: const Text('¡Que dios os bendiga!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                disabledBackgroundColor: const Color(0x5987CEEB),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: _selected.length >= 2
                  ? () {
                      // Convertir los jugadores seleccionados de LeaguePlayerStats a Player
                      final selectedPlayers = players
                          .where((p) => _selected.contains(p.playerId))
                          .map((leaguePlayer) {
                            // Convertir avatarPath a File o mantener como asset
                            File? imagen;
                            String? avatar;

                            if (leaguePlayer.avatarPath != null) {
                              if (leaguePlayer.avatarPath!.startsWith(
                                'assets/',
                              )) {
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
                          })
                          .toList();

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
                              _saveGameResults(playerDrinks);
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
