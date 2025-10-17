import 'package:flutter/material.dart';
import '../../../models/player.dart';

class LetterCounterOverlay extends StatefulWidget {
  final List<Player> selectedPlayers; // Solo los jugadores seleccionados
  final String letter;
  final int drinksPerLetter;
  final Function(Map<int, int>) onConfirm; // Map<playerId, totalDrinks>

  const LetterCounterOverlay({
    super.key,
    required this.selectedPlayers,
    required this.letter,
    required this.drinksPerLetter,
    required this.onConfirm,
  });

  @override
  State<LetterCounterOverlay> createState() => _LetterCounterOverlayState();
}

class _LetterCounterOverlayState extends State<LetterCounterOverlay> {
  final Map<int, int> _letterCounts =
      {}; // playerId -> count seleccionado manualmente

  @override
  void initState() {
    super.initState();
    // Inicializar todos en 0
    for (final player in widget.selectedPlayers) {
      _letterCounts[player.id] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600 || screenSize.height < 400;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            children: [
              // Título
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                ),
                child: Column(
                  children: [
                    Text(
                      'Conteo de letra "${widget.letter}"',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    Text(
                      '${widget.drinksPerLetter} trago${widget.drinksPerLetter > 1 ? 's' : ''} por cada letra',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isSmallScreen ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de jugadores con selectores
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    children: widget.selectedPlayers.map((player) {
                      final selectedCount = _letterCounts[player.id] ?? 0;
                      final totalDrinks =
                          selectedCount * widget.drinksPerLetter;

                      return Container(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Fila superior: Avatar + Nombre + Tragos
                            Row(
                              children: [
                                _buildPlayerAvatar(player, isSmallScreen),
                                SizedBox(width: isSmallScreen ? 8 : 10),

                                Expanded(
                                  child: Text(
                                    player.nombre,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Contador de tragos resultante
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 10,
                                    vertical: isSmallScreen ? 4 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: totalDrinks > 0
                                        ? const Color(0xFF00C9FF)
                                        : Colors.grey.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_drink,
                                        color: Colors.white,
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalDrinks',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isSmallScreen ? 8 : 10),

                            // Fila inferior: Selectores 0-5
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) {
                                final isSelected = selectedCount == index;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _letterCounts[player.id] = index;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 6 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF00C9FF)
                                              : Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        '$index',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF00C9FF)
                                              : Colors.white,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Botón Confirmar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Calcular tragos totales y filtrar los que tienen 0
                    final playersWithDrinks = <int, int>{};
                    _letterCounts.forEach((playerId, count) {
                      final totalDrinks = count * widget.drinksPerLetter;
                      if (totalDrinks > 0) {
                        playersWithDrinks[playerId] = totalDrinks;
                      }
                    });
                    widget.onConfirm(playersWithDrinks);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00C9FF),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 32 : 48,
                      vertical: isSmallScreen ? 14 : 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirmar',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(Player player, bool isSmallScreen) {
    final size = isSmallScreen ? 32.0 : 36.0;

    if (player.imagen != null) {
      return ClipOval(
        child: Image.file(
          player.imagen!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (player.avatar != null && player.avatar!.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          player.avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
          ),
        ),
        child: Center(
          child: Text(
            player.nombre[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
