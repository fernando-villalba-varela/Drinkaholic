import 'package:flutter/material.dart';
import '../../../models/player.dart';
import '../../../ui/components/drinkaholic_button.dart';

class PlayerSelectorOverlay extends StatefulWidget {
  final List<Player> players;
  final Function(List<int>) onPlayersSelected;
  final VoidCallback onCancel;
  final bool isMoreLikelyQuestion; // True si es pregunta "más probable que"

  const PlayerSelectorOverlay({
    super.key,
    required this.players,
    required this.onPlayersSelected,
    required this.onCancel,
    this.isMoreLikelyQuestion = false,
  });

  @override
  State<PlayerSelectorOverlay> createState() => _PlayerSelectorOverlayState();
}

class _PlayerSelectorOverlayState extends State<PlayerSelectorOverlay> with SingleTickerProviderStateMixin {
  final Set<int> _selectedPlayerIds = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayer(int playerId) {
    setState(() {
      if (_selectedPlayerIds.contains(playerId)) {
        _selectedPlayerIds.remove(playerId);
      } else {
        _selectedPlayerIds.add(playerId);
      }
    });
  }

  void _confirm() {
    if (_selectedPlayerIds.isEmpty) return;
    _animationController.reverse().then((_) {
      widget.onPlayersSelected(_selectedPlayerIds.toList());
    });
  }

  void _cancel() {
    _animationController.reverse().then((_) {
      widget.onCancel();
    });
  }

  ImageProvider? _avatar(Player player) {
    if (player.imagen != null && player.imagen!.existsSync()) {
      return FileImage(player.imagen!);
    }
    if (player.avatar != null && player.avatar!.startsWith('assets/')) {
      return AssetImage(player.avatar!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600 || screenSize.height < 400;
    final isLandscape = screenSize.width > screenSize.height;

    // Calcular dimensiones adaptativas
    final maxWidth = isSmallScreen ? screenSize.width * 0.95 : 600.0;
    final maxHeight = isLandscape ? screenSize.height * 0.85 : (isSmallScreen ? screenSize.height * 0.75 : 500.0);
    final margin = isSmallScreen ? 12.0 : 24.0;
    final headerPadding = isSmallScreen ? 12.0 : 20.0;
    final iconSize = isSmallScreen ? 22.0 : 28.0;
    final titleFontSize = isSmallScreen ? 16.0 : 20.0;
    final itemPadding = isSmallScreen ? 12.0 : 16.0;
    final avatarRadius = isSmallScreen ? 20.0 : 24.0;
    final playerFontSize = isSmallScreen ? 15.0 : 18.0;
    final checkIconSize = isSmallScreen ? 24.0 : 28.0;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Fondo semitransparente
            Positioned.fill(
              child: GestureDetector(
                onTap: _cancel,
                child: Container(color: Colors.black.withOpacity(0.7 * _fadeAnimation.value)),
              ),
            ),
            // Contenido
            Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
                    margin: EdgeInsets.all(margin),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(headerPadding),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people, color: Colors.white, size: iconSize),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.isMoreLikelyQuestion
                                      ? 'Habéis señalado a'
                                      : '¿Quiénes cumplen la condición?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                                iconSize: iconSize,
                                padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                                constraints: const BoxConstraints(),
                                onPressed: _cancel,
                              ),
                            ],
                          ),
                        ),
                        // Lista de jugadores
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.all(itemPadding),
                            itemCount: widget.players.length,
                            itemBuilder: (context, index) {
                              final player = widget.players[index];
                              final isSelected = _selectedPlayerIds.contains(player.id);
                              final img = _avatar(player);

                              return Card(
                                elevation: 0,
                                color: isSelected ? const Color(0xFF00C9FF).withAlpha(0x4D) : const Color(0xFF3A3A4E),
                                margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF00C9FF) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _togglePlayer(player.id),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: itemPadding,
                                      vertical: isSmallScreen ? 8 : 12,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: avatarRadius,
                                          backgroundImage: img,
                                          child: img == null
                                              ? Text(
                                                  player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: avatarRadius * 0.8,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: isSmallScreen ? 12 : 16),
                                        Expanded(
                                          child: Text(
                                            player.nombre,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: playerFontSize,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle, color: const Color(0xFF00C9FF), size: checkIconSize)
                                        else
                                          Icon(
                                            Icons.circle_outlined,
                                            color: Colors.white.withOpacity(0.3),
                                            size: checkIconSize,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Botones de acción
                        Container(
                          padding: EdgeInsets.all(buttonPadding),
                          child: Row(
                            children: [
                              Expanded(
                                child: DrinkaholicButton(
                                  label: 'Cancelar',
                                  onPressed: _cancel,
                                  variant: DrinkaholicButtonVariant.outline,
                                  fullWidth: true,
                                  height: isSmallScreen ? 40 : 48,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DrinkaholicButton(
                                  label: _selectedPlayerIds.isEmpty
                                      ? 'Selecciona jugadores'
                                      : 'Confirmar (${_selectedPlayerIds.length})',
                                  onPressed: _selectedPlayerIds.isEmpty ? null : _confirm,
                                  variant: DrinkaholicButtonVariant.primary,
                                  fullWidth: true,
                                  height: isSmallScreen ? 40 : 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
