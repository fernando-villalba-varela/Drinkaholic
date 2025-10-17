// ignore_for_file: constant_identifier_names

enum EventType {
  global_rule, // Reglas globales que afectan a todos
  multiplier, // Multiplicadores de tragos/castigos
  special_condition, // Condiciones especiales temporales
}

enum EventStatus {
  active, // El evento está activo
  ended, // El evento ha terminado
  pending, // El evento está esperando para activarse
}

class Event {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final int startRound;
  final int? endRound; // null si aún no ha terminado
  final EventStatus status;
  final Map<String, dynamic>
  metadata; // Para datos adicionales como multiplicadores, etc.

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startRound,
    this.endRound,
    required this.status,
    this.metadata = const {},
  });

  /// Creates a copy of this event with the given fields replaced
  Event copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    int? startRound,
    int? endRound,
    EventStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startRound: startRound ?? this.startRound,
      endRound: endRound ?? this.endRound,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Returns true if this event is currently active
  bool isActiveAtRound(int currentRound) {
    return status == EventStatus.active &&
        currentRound >= startRound &&
        (endRound == null || currentRound <= endRound!);
  }

  /// Returns true if this event can be ended (has been active for at least the minimum duration)
  bool canBeEndedAtRound(int currentRound) {
    final minDuration = metadata['minDuration'] as int? ?? 3;
    return status == EventStatus.active &&
        currentRound >= (startRound + minDuration);
  }

  /// Returns a user-friendly duration description
  String getDurationDescription(int currentRound) {
    final roundsActive = currentRound - startRound + 1;
    if (endRound != null) {
      final totalDuration = endRound! - startRound + 1;
      return 'Duró $totalDuration rondas';
    } else {
      return 'Activo desde hace $roundsActive rondas';
    }
  }

  /// Returns the icon for this type of event
  String get typeIcon {
    switch (type) {
      case EventType.global_rule:
        return '🌐';
      case EventType.multiplier:
        return '✖️';
      case EventType.special_condition:
        return '⭐';
    }
  }

  /// Returns the multiplier value for drinks if this is a multiplier event
  int get drinkMultiplier {
    if (type != EventType.multiplier) return 1;
    return metadata['multiplier'] as int? ?? 2;
  }

  /// Returns the remaining rounds for this event (null if indefinite)
  int? getRemainingRounds(int currentRound) {
    if (endRound == null) return null;
    return endRound! - currentRound;
  }

  @override
  String toString() {
    return 'Event($title: $description, Round $startRound${endRound != null ? '-$endRound' : '+'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents the ending of an event
class EventEnd {
  final String eventId;
  final String endDescription;
  final int endRound;

  const EventEnd({
    required this.eventId,
    required this.endDescription,
    required this.endRound,
  });
}
