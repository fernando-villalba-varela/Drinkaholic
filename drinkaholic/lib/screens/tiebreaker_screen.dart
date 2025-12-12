import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/player.dart';
import '../widgets/common/animated_background.dart';
import '../ui/components/drinkaholic_button.dart';

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

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);

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
            shadows: [Shadow(color: Colors.black.withOpacity(0.9), offset: Offset(1, 1), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Dibujar texto centrado horizontalmente respecto al avatar
      textPainter.paint(canvas, Offset(textX - textPainter.width / 2, textY - textPainter.height / 2));
    }

    // Dibujar borde exterior
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawPlayerAvatar(Canvas canvas, Player player, double x, double y, double radius, bool isWinner) {
    // Dibujar círculo de fondo para el avatar
    final avatarPaint = Paint()
      ..color = isWinner ? (isMVP ? const Color(0xFFFFD700) : const Color(0xFF8B4513)) : Colors.white.withOpacity(0.9)
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
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Dibujar borde del avatar encima de todo
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, y), radius, borderPaint);
  }

  void _drawPlayerImage(Canvas canvas, ui.Image image, double x, double y, double radius) {
    final Rect rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
    final Rect srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

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
  final bool isQuestionTiebreaker; // True si es desempate de pregunta, False si es final
  final String? currentQuestion; // La pregunta actual para mostrar abajo
  final int drinksAmount; // Cantidad de tragos a beber

  const TiebreakerScreen({
    super.key,
    required this.tiedPlayers,
    required this.tiedScore,
    required this.type,
    required this.onTiebreakerResolved,
    this.isQuestionTiebreaker = false,
    this.currentQuestion,
    this.drinksAmount = 1,
  });

  @override
  State<TiebreakerScreen> createState() => _TiebreakerScreenState();
}

class _TiebreakerScreenState extends State<TiebreakerScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _winnerScaleController;
  late Animation<double> _winnerScale;
  late AnimationController _colorChangeController;
  late Animation<double> _colorAnimation;
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

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
    _spinController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic));

    _winnerScaleController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _winnerScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _winnerScaleController, curve: Curves.elasticOut),
    );

    // Animación para cambio de color blanco-verde
    _colorChangeController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
    
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _colorChangeController, curve: Curves.easeInOut),
    );

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
        } else if (player.avatar != null && player.avatar!.startsWith('assets/')) {
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
    _winnerScaleController.dispose();
    _colorChangeController.dispose();
    super.dispose();
  }

  void _spinBottle() async {
    if (_isSpinning || _hasSpun) return; // Solo se puede girar una vez

    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
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
    final sectionIndex = (normalizedAngle / anglePerSection).floor() % playerCount;

    // Convertir el índice calculado al jugador correspondiente
    final winnerIndex = sectionIndex;

    setState(() {
      _winner = widget.tiedPlayers[winnerIndex];
      _isSpinning = false;
      _hasSpun = true;
    });
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    _winnerScaleController.forward(from: 0.0);
  }

  int _extractDrinksFromQuestion() {
    return widget.drinksAmount;
  }

  String _extractQuestionPart() {
    if (widget.currentQuestion == null || widget.currentQuestion!.isEmpty) {
      return '';
    }
    
    final question = widget.currentQuestion!.trim();
    
    // Patrones a eliminar del inicio de la pregunta
    final patterns = [
      // Patrones de "más probable que"
      RegExp(r'^a\s+la\s+de\s+\d+\s+(?:todos\s+)?señalan?\s+al?\s+jugador(?:a)?\s+que\s+sea\s+m[aá]s\s+probable\s+que\s+',
          caseSensitive: false),
      RegExp(r'^a\s+la\s+de\s+\d+,?\s+(?:todos\s+)?señalen?\s+a\s+quien\s+se(?:a|rá)\s+m[aá]s\s+probable\s+que\s+',
          caseSensitive: false),
      RegExp(r'^a\s+(?:la\s+)?cuenta?\s+de\s+\d+,?\s+(?:todos\s+)?apunten?\s+(?:a\s+)?quien(?:es)?\s+(?:crean|sea)\s+que\s+',
          caseSensitive: false),
      RegExp(r'^a\s+la\s+de\s+\d+,?\s+(?:todos\s+)?señalen?\s+a\s+(?:la\s+)?persona?\s+m[aá]s\s+propensa?\s+a\s+',
          caseSensitive: false),
      // Otros patrones genéricos
      RegExp(r'^(?:a\s+la\s+de\s+\d+\s+)?(?:todos\s+)?(?:cualquiera|el\s+que|quien|aquello\s+que)\s+',
          caseSensitive: false),
    ];
    
    String result = question;
    
    // Aplicar cada patrón y quedarse con el primero que coincida
    for (final pattern in patterns) {
      final match = pattern.firstMatch(result);
      if (match != null) {
        result = result.substring(match.end).trim();
        break;
      }
    }
    
    // Limpiar puntuación final y separadores comunes
    // Eliminar "; ese jugador beber", ", ese jugador beber", etc.
    result = result.replaceAll(RegExp(r';\s*(?:ese\s+)?jugador(?:a)?\s+beb[eé].*$', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r',\s*(?:ese\s+)?jugador(?:a)?\s+beb[eé].*$', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'[;,]\s*(?:ese|esa)\s+(?:jugador(?:a)?|persona)\s+beb[eé]r?a?.*$', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r';\s*quien.*$', caseSensitive: false), '');
    
    // Si el resultado termina con "tragos" u otros patrones, eliminarlo
    result = result.replaceAll(RegExp(r'\s+(?:tragos?|trago).*$', caseSensitive: false), '').trim();
    
    // Aplicar transformaciones gramaticales para que tenga sentido
    result = _transformGrammatically(result);
    
    return result;
  }

  String _transformGrammatically(String text) {
    // Transformar verbos en subjuntivo a formas más naturales para la frase "El duende sabe que..."
    
    // Convertir verbos en subjuntivo presente a futuro o presente indicativo
    final transformations = <RegExp, String>{
      // "llegue" → "llegarás" (subjuntivo → futuro informal)
      RegExp(r'\bllegue\b', caseSensitive: false): 'llegarás',
      RegExp(r'\bse\s+quede\b', caseSensitive: false): 'te quedarás',
      RegExp(r'\bresponda\b', caseSensitive: false): 'responderás',
      RegExp(r'\bse\s+case\b', caseSensitive: false): 'te casarás',
      RegExp(r'\bolvide\b', caseSensitive: false): 'olvidarás',
      RegExp(r'\bhaga\b', caseSensitive: false): 'harás',
      RegExp(r'\bse\s+pierda\b', caseSensitive: false): 'te perderás',
      RegExp(r'\borganice\b', caseSensitive: false): 'organizarás',
      RegExp(r'\brompa\b', caseSensitive: false): 'romperás',
      RegExp(r'\bmande\b', caseSensitive: false): 'mandarás',
      RegExp(r'\bllore\b', caseSensitive: false): 'llorarás',
      RegExp(r'\bligue\b', caseSensitive: false): 'ligarás',
      RegExp(r'\bgane\b', caseSensitive: false): 'ganarás',
      RegExp(r'\bse\s+vaya\b', caseSensitive: false): 'te irás',
      RegExp(r'\bse\s+haga\b', caseSensitive: false): 'te harás',
      RegExp(r'\btenga\b', caseSensitive: false): 'tendrás',
      RegExp(r'\badopte\b', caseSensitive: false): 'adoptarás',
      RegExp(r'\bse\s+tatúe\b', caseSensitive: false): 'te tatúarás',
      RegExp(r'\bcoma\b', caseSensitive: false): 'comerás',
      RegExp(r'\bcante\b', caseSensitive: false): 'cantarás',
      RegExp(r'\bpierda\b', caseSensitive: false): 'perderás',
      RegExp(r'\bse\s+cambie\b', caseSensitive: false): 'te cambiarás',
      RegExp(r'\bsuba\b', caseSensitive: false): 'subirás',
      RegExp(r'\bhaga\s+un\s+maratón\b', caseSensitive: false): 'harás un maratón',
      RegExp(r'\bcocine\b', caseSensitive: false): 'cocinarás',
      RegExp(r'\bse\s+apunte\b', caseSensitive: false): 'te apuntarás',
      RegExp(r'\bsea\b', caseSensitive: false): 'serás',
      RegExp(r'\bse\s+rompa\b', caseSensitive: false): 'se te romperá',
      RegExp(r'\bolvide\s+dónde\b', caseSensitive: false): 'olvidarás dónde',
      RegExp(r'\bpierda\s+la\s+cartera\b', caseSensitive: false): 'perderás la cartera',
      RegExp(r'\bhaga\s+match\b', caseSensitive: false): 'harás match',
      RegExp(r'\bse\s+haga\s+un\s+piercing\b', caseSensitive: false): 'te harás un piercing',
      RegExp(r'\bcante\s+a\s+gritos\b', caseSensitive: false): 'cantarás a gritos',
      RegExp(r'\bse\s+duerma\b', caseSensitive: false): 'te dormirás',
      RegExp(r'\brobe\b', caseSensitive: false): 'robarás',
      RegExp(r'\badopte\s+un\s+gato\b', caseSensitive: false): 'adoptarás un gato',
      RegExp(r'\bse\s+haga\s+vegano\b', caseSensitive: false): 'te harás vegano',
      RegExp(r'\bllore\s+de\s+la\s+risa\b', caseSensitive: false): 'llorarás de la risa',
      RegExp(r'\bcuente\b', caseSensitive: false): 'contarás',
      RegExp(r'\bcambie\b', caseSensitive: false): 'cambiarás',
      RegExp(r'\bdeje\b', caseSensitive: false): 'dejarás',
      RegExp(r'\babra\b', caseSensitive: false): 'abrirás',
      RegExp(r'\bse\s+enamore\b', caseSensitive: false): 'te enamorarás',
      RegExp(r'\bhaga\s+ghosting\b', caseSensitive: false): 'harás ghosting',
      RegExp(r'\bvuelva\b', caseSensitive: false): 'volverás',
      RegExp(r'\bse\s+olvide\b', caseSensitive: false): 'se te olvidará',
    };
    
    String result = text;
    transformations.forEach((pattern, replacement) {
      result = result.replaceAll(pattern, replacement);
    });
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isMVP = widget.type == TiebreakerType.mvp;

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
        child: Stack(
          children: [
            const AnimatedBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    // Header - Personalizado si es desempate de pregunta
                    if (widget.isQuestionTiebreaker)
                      AnimatedBuilder(
                        animation: _colorAnimation,
                        builder: (context, child) {
                          final color = Color.lerp(
                            Colors.white,
                            const Color(0xFF00FF00),
                            _colorAnimation.value,
                          )!;
                          return Text(
                            '⚖️ El duende va a hablar',
                            style: TextStyle(
                              color: color,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      )
                    else
                      Text(
                        isMVP ? 'Desempate MVDP' : 'Desempate Ratita',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 12),
                    // Subtitle - Personalizado si es desempate de pregunta
                    if (widget.isQuestionTiebreaker)
                      Text(
                        'Hay empate en quien cumple la condición\n¡El duende te ayudará a elegir!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      )
                    else
                      (isMVP
                          ? RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                                          color: Color(0xFFFFFF99), // Amarillo claro brillante
                                          blurRadius: 4,
                                          offset: Offset(0, 0),
                                        ),
                                        Shadow(color: Color(0xFFFFFF99), blurRadius: 8, offset: Offset(0, 0)),
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
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                                children: [
                                  TextSpan(text: 'Manda huevos que hayais bebido ${widget.tiedScore} tragos\n ('),
                                  TextSpan(
                                    text: 'sois escoria',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF8B4513), // Marrón caca brillante
                                          blurRadius: 4,
                                          offset: Offset(0, 0),
                                        ),
                                        Shadow(color: Color(0xFF8B4513), blurRadius: 8, offset: Offset(0, 0)),
                                      ],
                                    ),
                                  ),
                                  const TextSpan(text: ')'),
                                ],
                              ),
                            )),
                    const SizedBox(height: 32),

                    // Ruleta con jugadores - CENTRADA
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
                        children: [
                          if (!_hasSpun && !_isSpinning) ...[
                            Text(
                              'Solo el Little Boy sabe tu destino...',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                          ] else if (_isSpinning) ...[
                            Text(
                              '¡Girando...!',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            if (widget.isQuestionTiebreaker) ...[
                              // Desempate de pregunta: mostrar mensaje con estilo de duende (verde con rayos)
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    const Color(0xFF00FF00),
                                    const Color(0xFF00CC00),
                                    const Color(0xFF00FF00),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds),
                                child: Text(
                                  '🧙 El duende elige a... 🧙',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ] else ...[
                              // Desempate final: mostrar mensaje normal
                              Text(
                                isMVP ? '¡Se te ha caido esto! -> 👑' : '¡Ratitaa🐭🐭 (JAJA)!',
                                style: TextStyle(
                                  color: isMVP ? const Color(0xFFFFD700) : const Color(0xFF8B4513),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Centrar el resultado del ganador
                            Center(
                              child: ScaleTransition(
                                scale: _winnerScale,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: (widget.isQuestionTiebreaker
                                            ? Colors.purple
                                            : (isMVP ? const Color(0xFFFFD700) : const Color(0xFF8B4513)))
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: widget.isQuestionTiebreaker
                                          ? Colors.purple
                                          : (isMVP ? const Color(0xFFFFD700) : const Color(0xFF8B4513)),
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Ruleta circular con jugadores - CENTRADA
                          Center(child: _buildSpinWheel()),
                          
                          // Mostrar el texto de tragos si es desempate de pregunta y hay ganador
                          if (widget.isQuestionTiebreaker && _hasSpun && _winner != null) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'El duende sabe que ${_extractQuestionPart()}... ¡Así que bebete los ${_extractDrinksFromQuestion()} tragos!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Botón para confirmar resultado - CENTRADO
                    Center(
                      child: Column(
                        children: [
                          if (_hasSpun && _winner != null)
                            DrinkaholicButton(
                              label: widget.isQuestionTiebreaker ? 'Confirmar' : 'Confirmar Resultado',
                              icon: Icons.check_circle_outline,
                              onPressed: () {
                                final loser = widget.tiedPlayers.length > 1
                                    ? widget.tiedPlayers.firstWhere((p) => p.id != _winner!.id)
                                    : null;
                                widget.onTiebreakerResolved(_winner!, loser);
                              },
                              variant: DrinkaholicButtonVariant.primary,
                              fullWidth: false,
                              height: 52,
                            )
                          else if (_isSpinning)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              child: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                final angle = _hasSpun ? _finalBottleAngle : _spinAnimation.value;
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
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cuerpo de la botella
                        const Icon(Icons.local_drink, color: Colors.white, size: 30),
                        // Punta que apunta al ganador
                        Positioned(
                          top: 8,
                          child: Container(
                            width: 4,
                            height: 15,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.4),
            )
          : null,
    );
  }
}
