import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/player.dart';

class WheelPainter extends CustomPainter {
  final List<Player> players;
  final Player? winner;
  final bool isMVP;
  final bool hasSpun;
  final List<Color> fixedColors;
  final Map<String, ui.Image?> playerImages;

  WheelPainter({
    required this.players,
    required this.winner,
    required this.isMVP,
    required this.hasSpun,
    required this.fixedColors,
    required this.playerImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final anglePerSection = (2 * pi) / players.length;

    // Usar colores fijos pasados como parámetro

    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final isWinner = hasSpun && winner?.id == player.id;

      // Ángulo inicial de la sección (empezamos desde arriba: -π/2)
      final startAngle = (i * anglePerSection) - (pi / 2);
      final sweepAngle = anglePerSection;

      // Color de la sección - mantener colores originales siempre
      Color sectionColor = fixedColors[i % fixedColors.length];

      // Dibujar sección
      final paint = Paint()
        ..color = sectionColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dibujar líneas divisorias
      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final endX = center.dx + radius * cos(startAngle);
      final endY = center.dy + radius * sin(startAngle);

      canvas.drawLine(center, Offset(endX, endY), linePaint);

      // Calcular posición del avatar (punto de referencia principal)
      final sectionAngle = startAngle + (sweepAngle / 2);
      final avatarRadius = radius * 0.65; // Avatar en posición centrada

      // Posición del avatar (centro de referencia)
      final avatarX = center.dx + avatarRadius * cos(sectionAngle);
      final avatarY = center.dy + avatarRadius * sin(sectionAngle);

      // Posición del texto DIRECTAMENTE ABAJO del avatar
      final textX = avatarX; // Misma coordenada X que el avatar
      final textY = avatarY + 35; // 35 píxeles ABAJO del avatar

      // 1. Dibujar avatar primero
      _drawPlayerAvatar(canvas, player, avatarX, avatarY, 20, isWinner);

      // 2. Dibujar texto DIRECTAMENTE ABAJO del avatar
      final textPainter = TextPainter(
        text: TextSpan(
          text: player.nombre, // Mostrar nombre completo sin truncar
          style: TextStyle(
            color: Colors.white,
            fontSize: 10, // Reducir tamaño para que quepa mejor
            fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.9),
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Dibujar texto centrado horizontalmente respecto al avatar
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Dibujar borde exterior
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawPlayerAvatar(
    Canvas canvas,
    Player player,
    double x,
    double y,
    double radius,
    bool isWinner,
  ) {
    // Dibujar círculo de fondo para el avatar
    final avatarPaint = Paint()
      ..color = isWinner
          ? (isMVP ? const Color(0xFFFFD700) : const Color(0xFF8B4513))
          : Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), radius, avatarPaint);

    // Obtener imagen del jugador
    final ui.Image? playerImage = playerImages[player.nombre];

    if (playerImage != null) {
      // Si hay imagen cargada, dibujarla
      _drawPlayerImage(canvas, playerImage, x, y, radius);
    } else {
      // Si no hay imagen, dibujar inicial del jugador
      final textPainter = TextPainter(
        text: TextSpan(
          text: player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?',
          style: TextStyle(
            color: isWinner ? Colors.white : Colors.black,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Dibujar borde del avatar encima de todo
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, y), radius, borderPaint);
  }

  void _drawPlayerImage(
    Canvas canvas,
    ui.Image image,
    double x,
    double y,
    double radius,
  ) {
    final Rect rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Crear un clip circular para la imagen
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    // Dibujar la imagen escalada al círculo
    canvas.drawImageRect(image, srcRect, rect, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum TiebreakerType { mvp, ratita }

class TiebreakerScreen extends StatefulWidget {
  final List<Player> tiedPlayers;
  final int tiedScore;
  final TiebreakerType type;
  final Function(Player winner, Player? loser) onTiebreakerResolved;

  const TiebreakerScreen({
    super.key,
    required this.tiedPlayers,
    required this.tiedScore,
    required this.type,
    required this.onTiebreakerResolved,
  });

  @override
  State<TiebreakerScreen> createState() => _TiebreakerScreenState();
}

class _TiebreakerScreenState extends State<TiebreakerScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  bool _hasSpun = false;
  Player? _winner;

  // Colores fijos generados una sola vez
  late List<Color> _fixedColors;

  // Posición final de la botella
  double _finalBottleAngle = 0.0;

  // Mapa de imágenes cargadas para cada jugador
  final Map<String, ui.Image?> _playerImages = {};

  @override
  void initState() {
    super.initState();
    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Generar colores fijos una sola vez
    _fixedColors = [
      Colors.red.withOpacity(0.7),
      Colors.blue.withOpacity(0.7),
      Colors.green.withOpacity(0.7),
      Colors.orange.withOpacity(0.7),
      Colors.purple.withOpacity(0.7),
      Colors.pink.withOpacity(0.7),
      Colors.teal.withOpacity(0.7),
      Colors.amber.withOpacity(0.7),
    ];

    // Configurar animación de giro
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));

    // Cargar imágenes de los jugadores
    _loadPlayerImages();
  }

  Future<void> _loadPlayerImages() async {
    for (final player in widget.tiedPlayers) {
      ui.Image? image;

      try {
        if (player.imagen != null && player.imagen!.existsSync()) {
          // Cargar imagen desde archivo
          final bytes = await player.imagen!.readAsBytes();
          image = await decodeImageFromList(bytes);
        } else if (player.avatar != null &&
            player.avatar!.startsWith('assets/')) {
          // Cargar imagen desde assets
          final data = await rootBundle.load(player.avatar!);
          final bytes = data.buffer.asUint8List();
          image = await decodeImageFromList(bytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error cargando imagen para ${player.nombre}: $e');
        }
      }

      _playerImages[player.nombre] = image;
    }

    // Actualizar el UI después de cargar las imágenes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinBottle() async {
    if (_isSpinning || _hasSpun) return; // Solo se puede girar una vez

    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    // Generar un ángulo completamente aleatorio usando Random()
    final random = Random();
    final playerCount = widget.tiedPlayers.length;

    // Generar un ángulo final completamente aleatorio
    final randomAngle = random.nextDouble() * 2 * pi;

    // Añadir vueltas extra para efecto visual (4-7 vueltas completas)
    final extraSpins = 4 + random.nextInt(4);
    final totalAngle = randomAngle + (extraSpins * 2 * pi);

    // Configurar animación con el ángulo final
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: totalAngle,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));

    // Iniciar animación
    await _spinController.forward();

    // Guardar la posición final de la botella
    _finalBottleAngle = totalAngle;

    // CÁLCULO CORRECTO del ganador basado en la posición de la flecha
    final normalizedAngle = totalAngle % (2 * pi);
    final anglePerSection = (2 * pi) / playerCount;

    // La flecha apunta hacia arriba (-π/2 en coordenadas canvas)
    // Las secciones se dibujan desde -π/2 en sentido horario
    // Sección 0: desde -π/2 hasta -π/2 + anglePerSection
    // Sección 1: desde -π/2 + anglePerSection hasta -π/2 + 2*anglePerSection, etc.

    // La flecha en posición inicial (sin rotación) apunta a la sección 0
    // Cuando gira, necesitamos calcular a qué sección apunta
    final sectionIndex =
        (normalizedAngle / anglePerSection).floor() % playerCount;

    // Convertir el índice calculado al jugador correspondiente
    final winnerIndex = sectionIndex;

    setState(() {
      _winner = widget.tiedPlayers[winnerIndex];
      _isSpinning = false;
      _hasSpun = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMVP = widget.type == TiebreakerType.mvp;
    final title = isMVP ? 'Desempate MVDP' : 'Desempate Ratita';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              children: [
                // Header
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle con texto especial brillante
                isMVP
                    ? RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Hay varios jugones empatados con ${widget.tiedScore} tragos\n (Solo puede haber un ',
                            ),
                            TextSpan(
                              text: 'puto amo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color(
                                      0xFFFFFF99,
                                    ), // Amarillo claro brillante
                                    blurRadius: 4,
                                    offset: Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: Color(0xFFFFFF99),
                                    blurRadius: 8,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            const TextSpan(text: ')'),
                          ],
                        ),
                      )
                    : RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Manda huevos que hayais bebido ${widget.tiedScore} tragos\n (',
                            ),
                            TextSpan(
                              text: 'sois escoria',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color(
                                      0xFF8B4513,
                                    ), // Marrón caca brillante
                                    blurRadius: 4,
                                    offset: Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: Color(0xFF8B4513),
                                    blurRadius: 8,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            const TextSpan(text: ')'),
                          ],
                        ),
                      ),
                const SizedBox(height: 32),

                // Ruleta con jugadores
                Expanded(
                  child: Column(
                    children: [
                      if (!_hasSpun && !_isSpinning) ...[
                        Text(
                          'Solo el Little Boy sabe tu destino...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else if (_isSpinning) ...[
                        Text(
                          '¡Girando...!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else ...[
                        Text(
                          isMVP
                              ? '¡Se te ha caido esto! -> 👑'
                              : '¡Ratitaa🐭🐭 (JAJA)!',
                          style: TextStyle(
                            color: isMVP
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF8B4513),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                (isMVP
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF8B4513))
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMVP
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF8B4513),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPlayerAvatar(_winner!, size: 50),
                              const SizedBox(width: 16),
                              Text(
                                _winner!.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Ruleta circular con jugadores
                      _buildSpinWheel(),
                    ],
                  ),
                ),

                // Botón para confirmar resultado
                if (_hasSpun && _winner != null)
                  ElevatedButton(
                    onPressed: () {
                      final loser = widget.tiedPlayers.length > 1
                          ? widget.tiedPlayers.firstWhere(
                              (p) => p.id != _winner!.id,
                            )
                          : null;
                      widget.onTiebreakerResolved(_winner!, loser);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmar Resultado'),
                  )
                else if (_isSpinning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpinWheel() {
    final isMVP = widget.type == TiebreakerType.mvp;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ruleta con secciones para cada jugador
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: WheelPainter(
                players: widget.tiedPlayers,
                winner: _winner,
                isMVP: isMVP,
                hasSpun: _hasSpun,
                fixedColors: _fixedColors,
                playerImages: _playerImages,
              ),
            ),
          ),

          // Botella en el centro (giratoria)
          GestureDetector(
            onTap: (_isSpinning || _hasSpun) ? null : _spinBottle,
            child: AnimatedBuilder(
              animation: _spinAnimation,
              builder: (context, child) {
                // Usar la posición final si ya terminó de girar
                final angle = _hasSpun
                    ? _finalBottleAngle
                    : _spinAnimation.value;
                return Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.brown.withOpacity(0.8),
                      border: Border.all(color: Colors.brown, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cuerpo de la botella
                        const Icon(
                          Icons.local_drink,
                          color: Colors.white,
                          size: 30,
                        ),
                        // Punta que apunta al ganador
                        Positioned(
                          top: 8,
                          child: Container(
                            width: 4,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(Player player, {double size = 40}) {
    ImageProvider? img;
    if (player.imagen != null && player.imagen!.existsSync()) {
      img = FileImage(player.imagen!);
    } else if (player.avatar != null && player.avatar!.startsWith('assets/')) {
      img = AssetImage(player.avatar!);
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundImage: img,
      child: img == null
          ? Text(
              player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            )
          : null,
    );
  }
}
