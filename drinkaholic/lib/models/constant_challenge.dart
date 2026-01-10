import '../models/player.dart';

enum ConstantChallengeType {
  restriction, // Restricciones (no puede hacer algo)
  obligation, // Obligaciones (debe hacer algo)
  rule, // Reglas especiales
}

enum ConstantChallengeStatus {
  active, // El reto está activo
  ended, // El reto ha terminado
  pending, // El reto está esperando para activarse
}

class ConstantChallenge {
  final String id;
  final Player targetPlayer;
  final String description;
  final String punishment; // Castigo si se olvida del reto
  final ConstantChallengeType type;
  final int startRound;
  final int? endRound; // null si aún no ha terminado
  final ConstantChallengeStatus status;
  final Map<String, dynamic> metadata; // Para datos adicionales como letras prohibidas, etc.

  const ConstantChallenge({
    required this.id,
    required this.targetPlayer,
    required this.description,
    required this.punishment,
    required this.type,
    required this.startRound,
    this.endRound,
    required this.status,
    this.metadata = const {},
  });

  /// Creates a copy of this challenge with the given fields replaced
  ConstantChallenge copyWith({
    String? id,
    Player? targetPlayer,
    String? description,
    String? punishment,
    ConstantChallengeType? type,
    int? startRound,
    int? endRound,
    ConstantChallengeStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return ConstantChallenge(
      id: id ?? this.id,
      targetPlayer: targetPlayer ?? this.targetPlayer,
      description: description ?? this.description,
      punishment: punishment ?? this.punishment,
      type: type ?? this.type,
      startRound: startRound ?? this.startRound,
      endRound: endRound ?? this.endRound,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Returns true if this challenge is currently active
  bool isActiveAtRound(int currentRound) {
    return status == ConstantChallengeStatus.active &&
        currentRound >= startRound &&
        (endRound == null || currentRound <= endRound!);
  }

  /// Returns true if this challenge can be ended (has been active for at least 5 rounds)
  bool canBeEndedAtRound(int currentRound) {
    return status == ConstantChallengeStatus.active && currentRound >= (startRound + 5);
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

  /// Returns the icon for this type of challenge
  String get typeIcon {
    switch (type) {
      case ConstantChallengeType.restriction:
        return '🚫';
      case ConstantChallengeType.obligation:
        return '✅';
      case ConstantChallengeType.rule:
        return '📋';
    }
  }

  /// Returns true since this is always a constant challenge
  bool get isConstantChallenge => true;

  @override
  String toString() {
    return 'ConstantChallenge(${targetPlayer.nombre}: $description, Round $startRound${endRound != null ? '-$endRound' : '+'}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConstantChallenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents the ending of a constant challenge
class ConstantChallengeEnd {
  final String challengeId;
  final Player targetPlayer;
  final String endDescription;
  final int endRound;

  const ConstantChallengeEnd({
    required this.challengeId,
    required this.targetPlayer,
    required this.endDescription,
    required this.endRound,
  });
}
