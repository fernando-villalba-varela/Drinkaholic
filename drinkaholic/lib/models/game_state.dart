import 'dart:io';
import 'package:flutter/material.dart';
import 'player.dart';
import 'constant_challenge.dart';

class GameState {
  final List<Player> players;
  final int currentPlayerIndex;
  final String? currentChallenge;
  final Animation<double> glowAnimation;
  final Map<int, int> playerWeights;
  final bool gameStarted;
  final File? currentGift;
  final int currentRound;
  final List<ConstantChallenge> constantChallenges;
  final ConstantChallengeEnd? currentChallengeEnd; // Para mostrar cuando un reto constante termina

  const GameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.currentChallenge,
    required this.glowAnimation,
    required this.playerWeights,
    required this.gameStarted,
    this.currentGift,
    this.currentRound = 1,
    this.constantChallenges = const [],
    this.currentChallengeEnd,
  });

  /// Creates a copy of this GameState with the given fields replaced with new values
  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    String? currentChallenge,
    Animation<double>? glowAnimation,
    Map<int, int>? playerWeights,
    bool? gameStarted,
    File? currentGift,
    int? currentRound,
    List<ConstantChallenge>? constantChallenges,
    ConstantChallengeEnd? currentChallengeEnd,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentChallenge: currentChallenge ?? this.currentChallenge,
      glowAnimation: glowAnimation ?? this.glowAnimation,
      playerWeights: playerWeights ?? this.playerWeights,
      gameStarted: gameStarted ?? this.gameStarted,
      currentGift: currentGift ?? this.currentGift,
      currentRound: currentRound ?? this.currentRound,
      constantChallenges: constantChallenges ?? this.constantChallenges,
      currentChallengeEnd: currentChallengeEnd ?? this.currentChallengeEnd,
    );
  }

  /// Returns true if the current challenge is for all players
  bool get isChallengeForAll {
    if (currentChallenge == null) return false;
    final lower = currentChallenge!.toLowerCase();
    return lower.contains('todos') || lower.contains('cualquiera');
  }

  /// Returns the current player or null if the challenge is for all players
  Player? get currentPlayer {
    if (currentPlayerIndex < 0 || currentPlayerIndex >= players.length) {
      return null;
    }
    return players[currentPlayerIndex];
  }

  /// Returns the display name for the current turn (player name or "TODOS")
  String get currentTurnDisplayName {
    if (isChallengeForAll) {
      return 'TODOS';
    }
    final player = currentPlayer;
    return player?.nombre.toUpperCase() ?? 'DESCONOCIDO';
  }

  /// Returns all active constant challenges for the current round
  List<ConstantChallenge> get activeChallenges {
    return constantChallenges
        .where((challenge) => challenge.isActiveAtRound(currentRound))
        .toList();
  }

  /// Returns constant challenges that can be ended in the current round
  List<ConstantChallenge> get endableChallenges {
    return constantChallenges
        .where((challenge) => challenge.canBeEndedAtRound(currentRound))
        .toList();
  }

  /// Returns active challenges for a specific player
  List<ConstantChallenge> getActiveChallengesForPlayer(Player player) {
    return activeChallenges
        .where((challenge) => challenge.targetPlayer.id == player.id)
        .toList();
  }

  /// Returns true if we're showing a constant challenge (start or end)
  bool get isConstantChallenge {
    return currentChallengeEnd != null || isNewConstantChallenge;
  }

  /// Returns true if the current challenge is a new constant challenge
  bool get isNewConstantChallenge {
    if (currentChallenge == null) return false;
    return currentChallenge!.contains('no puede') || 
           currentChallenge!.contains('debe') ||
           currentChallenge!.contains('ya puede') ||
           currentChallenge!.contains('regla:');
  }

  /// Returns true if the current challenge is ending a constant challenge
  bool get isEndingConstantChallenge {
    return currentChallengeEnd != null;
  }

  /// Returns true if constant challenges can appear (round 5 or later)
  bool get canHaveConstantChallenges {
    return currentRound >= 5;
  }
}
