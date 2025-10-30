import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'event.dart';

class EventTemplate {
  final String id;
  final String type;
  final String title;
  final String template;
  final String endTemplate;
  final Map<String, List<String>> variables;
  final String categoria;
  final int minRounds;
  final int maxRounds;
  final Map<String, dynamic> metadata;

  EventTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.template,
    required this.endTemplate,
    required this.variables,
    required this.categoria,
    required this.minRounds,
    required this.maxRounds,
    this.metadata = const {},
  });

  factory EventTemplate.fromJson(Map<String, dynamic> json) {
    return EventTemplate(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      template: json['template'],
      endTemplate: json['endTemplate'],
      variables: Map<String, List<String>>.from(
        json['variables'].map((key, value) => MapEntry(key, List<String>.from(value))),
      ),
      categoria: json['categoria'],
      minRounds: json['minRounds'],
      maxRounds: json['maxRounds'],
      metadata: json['metadata'] ?? {},
    );
  }

  EventType get eventType {
    switch (type) {
      case 'global_rule':
        return EventType.global_rule;
      case 'multiplier':
        return EventType.multiplier;
      case 'special_condition':
        return EventType.special_condition;
      default:
        return EventType.global_rule;
    }
  }
}

class EventGenerator {
  static final Random _random = Random();
  static List<EventTemplate>? _templates;

  /// Load event templates from JSON
  static Future<void> loadTemplates() async {
    if (_templates != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/events.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _templates = (jsonData['templates'] as List).map((template) => EventTemplate.fromJson(template)).toList();
    } catch (e) {
      _templates = [];
    }
  }

  /// Generate a random event
  static Future<Event> generateRandomEvent(int currentRound) async {
    await loadTemplates();

    if (_templates == null || _templates!.isEmpty) {
      // Multiple fallback events to provide variety
      final fallbackEvents = [
        {
          'title': 'Tragos Dobles',
          'description': 'EVENTO: ✖️ Todos los tragos valen x2 mientras dure este evento',
          'type': EventType.multiplier,
          'duration': 4,
          'multiplier': 2,
        },
        {
          'title': 'Zona Sin Teléfonos',
          'description':
              'EVENTO: 🌐 Nadie puede usar el teléfono mientras dure este evento. Si alguien lo usa, bebe 3 tragos',
          'type': EventType.global_rule,
          'duration': 4,
          'multiplier': 1,
        },
        {
          'title': 'Modo Silencioso',
          'description': 'EVENTO: 🌐 Solo comunicación por gestos mientras dure este evento. Hablar = 2 tragos',
          'type': EventType.global_rule,
          'duration': 3,
          'multiplier': 1,
        },
        {
          'title': 'Pausa de Baile',
          'description': 'EVENTO: ⭐ Cada trago requiere 15 segundos de baile mientras dure este evento',
          'type': EventType.special_condition,
          'duration': 4,
          'multiplier': 1,
        },
      ];

      final selectedFallback = fallbackEvents[_random.nextInt(fallbackEvents.length)];

      return Event(
        id: 'fallback_${selectedFallback['title']}_${_random.nextInt(10000)}',
        title: selectedFallback['title'] as String,
        description: selectedFallback['description'] as String,
        type: selectedFallback['type'] as EventType,
        startRound: currentRound,
        endRound: null, // Probabilistic ending
        status: EventStatus.active,
        metadata: {
          'multiplier': selectedFallback['multiplier'],
          'minDuration': selectedFallback['duration'], // Use the duration as minimum
        },
      );
    }

    final template = _templates![_random.nextInt(_templates!.length)];
    return _generateEventFromTemplate(template, currentRound);
  }

  /// Generate an event to end an existing event
  static EventEnd generateEventEnd(Event event, int endRound) {
    String endDescription;

    // Find the template using the templateId stored in metadata
    final templateId = event.metadata['templateId'] as String?;
    final template = _templates?.firstWhere((t) => t.id == templateId, orElse: () => _templates!.first);

    if (template != null) {
      endDescription = template.endTemplate;
      // Replace any variables if needed using stored metadata
      event.metadata.forEach((key, value) {
        if (key != 'templateId' && key != 'minDuration') {
          endDescription = endDescription.replaceAll('{$key}', value.toString());
        }
      });
    } else {
      endDescription = 'El evento "${event.title}" ha terminado';
    }

    return EventEnd(eventId: event.id, endDescription: endDescription, endRound: endRound);
  }

  /// Generate an event from a specific template
  static Event _generateEventFromTemplate(EventTemplate template, int currentRound) {
    String title = template.title;
    String description = template.template;
    Map<String, dynamic> metadata = {
      'templateId': template.id,
      'minDuration': template.minRounds,
      'maxSuggestedDuration': template.maxRounds, // For reference but not enforced
    };

    // Add template-specific metadata
    metadata.addAll(template.metadata);

    // Replace variables with random values
    template.variables.forEach((variableName, possibleValues) {
      if (possibleValues.isNotEmpty) {
        final selectedValue = possibleValues[_random.nextInt(possibleValues.length)];
        title = title.replaceAll('{$variableName}', selectedValue);
        description = description.replaceAll('{$variableName}', selectedValue);
        metadata[variableName] = selectedValue;
      }
    });

    // Don't set fixed endRound - let events end probabilistically like constant challenges
    int? endRound; // Always null for probabilistic ending

    return Event(
      id: '${template.id}_$currentRound',
      title: title,
      description: description,
      type: template.eventType,
      startRound: currentRound,
      endRound: endRound,
      status: EventStatus.active,
      metadata: metadata,
    );
  }

  /// Determines if an event should be generated this round
  static bool shouldGenerateEvent(int currentRound, List<Event> activeEvents) {
    // No events before round 8
    if (currentRound < 8) return false;

    // Lower probability if there are active events
    final activeEventCount = activeEvents.length;

    double baseProbability;
    if (activeEventCount == 0) {
      baseProbability = 0.12; // 12% chance if no active events
    } else if (activeEventCount < 2) {
      baseProbability = 0.06; // 6% chance if one active event
    } else {
      baseProbability = 0.02; // 2% chance if multiple active events
    }

    return _random.nextDouble() < baseProbability;
  }

  /// Determines if an event should be ended this round
  static bool shouldEndEvent(Event event, int currentRound) {
    if (!event.canBeEndedAtRound(currentRound)) return false;

    // Base probability grows with rounds active (older events more likely to end)
    final roundsActive = currentRound - event.startRound;

    double baseProbability;
    if (roundsActive >= 10) {
      baseProbability = 0.25; // 25% chance after 10 rounds
    } else if (roundsActive >= 8) {
      baseProbability = 0.15; // 15% chance after 8 rounds
    } else if (roundsActive >= 6) {
      baseProbability = 0.08; // 8% chance after 6 rounds
    } else if (roundsActive >= 4) {
      baseProbability = 0.05; // 5% chance after 4 rounds
    } else {
      baseProbability = 0.02; // 2% chance after minimum duration (3 rounds)
    }

    // Difficulty-aware adjustment: eventos más duros (p.ej. x3) terminan antes que x2
    int drinks = 1; // para PUNISHMENT
    int templateMultiplier = 1; // variable MULTIPLIER (string)
    int metadataMultiplier = event.metadata['multiplier'] is int
        ? (event.metadata['multiplier'] as int)
        : 1; // metadata numérica

    final drinksRaw = event.metadata['PUNISHMENT'];
    if (drinksRaw is int) {
      drinks = drinksRaw;
    } else if (drinksRaw is String) {
      drinks = int.tryParse(drinksRaw) ?? 1;
    }

    final multRaw = event.metadata['MULTIPLIER'];
    if (multRaw is int) {
      templateMultiplier = multRaw;
    } else if (multRaw is String) {
      templateMultiplier = int.tryParse(multRaw) ?? 1;
    }

    final difficultyScore = [drinks, templateMultiplier, metadataMultiplier, 1].reduce((a, b) => a > b ? a : b);

    // Escala lineal suave: cada punto de dificultad aumenta un 20% la probabilidad de terminar
    final difficultyFactor = 1.0 + 0.20 * (difficultyScore - 1);
    final probability = (baseProbability * difficultyFactor).clamp(0.0, 0.9);

    return _random.nextDouble() < probability;
  }
}
