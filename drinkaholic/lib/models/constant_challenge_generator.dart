import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'constant_challenge.dart';
import 'player.dart';

class ConstantChallengeTemplate {
  final String id;
  final String type;
  final String template;
  final String endTemplate;
  final String punishment;
  final Map<String, List<String>> variables;
  final String categoria;
  final int minRounds;
  final int maxRounds;

  ConstantChallengeTemplate({
    required this.id,
    required this.type,
    required this.template,
    required this.endTemplate,
    required this.punishment,
    required this.variables,
    required this.categoria,
    required this.minRounds,
    required this.maxRounds,
  });

  factory ConstantChallengeTemplate.fromJson(Map<String, dynamic> json) {
    return ConstantChallengeTemplate(
      id: json['id'],
      type: json['type'],
      template: json['template'],
      endTemplate: json['endTemplate'],
      punishment: json['punishment'],
      variables: Map<String, List<String>>.from(
        json['variables'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      categoria: json['categoria'],
      minRounds: json['minRounds'],
      maxRounds: json['maxRounds'],
    );
  }

  ConstantChallengeType get challengeType {
    switch (type) {
      case 'restriction':
        return ConstantChallengeType.restriction;
      case 'obligation':
        return ConstantChallengeType.obligation;
      case 'rule':
        return ConstantChallengeType.rule;
      default:
        return ConstantChallengeType.restriction;
    }
  }
}

class ConstantChallengeGenerator {
  static final Random _random = Random();
  static List<ConstantChallengeTemplate>? _templates;

  /// Load constant challenge templates from JSON
  static Future<void> loadTemplates() async {
    if (_templates != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/constant_challenges.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _templates = (jsonData['templates'] as List)
          .map((template) => ConstantChallengeTemplate.fromJson(template))
          .toList();
    } catch (e) {
      print('Error loading constant challenges: $e');
      _templates = [];
    }
  }

  /// Generate a random constant challenge for a specific player
  static Future<ConstantChallenge> generateRandomConstantChallenge(
    Player targetPlayer,
    int currentRound,
  ) async {
    await loadTemplates();
    
    if (_templates == null || _templates!.isEmpty) {
      // Fallback challenge
      return ConstantChallenge(
        id: 'fallback_${_random.nextInt(10000)}',
        targetPlayer: targetPlayer,
        description: '${targetPlayer.nombre} debe beber con la mano izquierda',
        punishment: 'Si ${targetPlayer.nombre} usa la mano derecha, bebe 2 tragos',
        type: ConstantChallengeType.restriction,
        startRound: currentRound,
        status: ConstantChallengeStatus.active,
      );
    }

    final template = _templates![_random.nextInt(_templates!.length)];
    return _generateChallengeFromTemplate(template, targetPlayer, currentRound);
  }

  /// Generate a challenge to end an existing constant challenge
  static ConstantChallengeEnd generateChallengeEnd(
    ConstantChallenge challenge,
    int endRound,
  ) {
    String endDescription;
    
    // Find the template using the templateId stored in metadata
    final templateId = challenge.metadata['templateId'] as String?;
    final template = _templates?.firstWhere(
      (t) => t.id == templateId,
      orElse: () => _templates!.first,
    );

    if (template != null) {
      endDescription = template.endTemplate.replaceAll('{PLAYER}', challenge.targetPlayer.nombre);
      // Replace any other variables if needed using stored metadata
      challenge.metadata.forEach((key, value) {
        if (key != 'templateId') {
          endDescription = endDescription.replaceAll('{$key}', value.toString());
        }
      });
    } else {
      endDescription = '${challenge.targetPlayer.nombre} ya no tiene restricciones especiales';
    }

    return ConstantChallengeEnd(
      challengeId: challenge.id,
      targetPlayer: challenge.targetPlayer,
      endDescription: endDescription,
      endRound: endRound,
    );
  }

  /// Generate a challenge from a specific template
  static ConstantChallenge _generateChallengeFromTemplate(
    ConstantChallengeTemplate template,
    Player targetPlayer,
    int currentRound,
  ) {
    String description = template.template.replaceAll('{PLAYER}', targetPlayer.nombre);
    String punishment = template.punishment.replaceAll('{PLAYER}', targetPlayer.nombre);
    Map<String, dynamic> metadata = {'templateId': template.id};

    // Replace variables with random values
    template.variables.forEach((variableName, possibleValues) {
      if (possibleValues.isNotEmpty) {
        final selectedValue = possibleValues[_random.nextInt(possibleValues.length)];
        description = description.replaceAll('{$variableName}', selectedValue);
        punishment = punishment.replaceAll('{$variableName}', selectedValue);
        metadata[variableName] = selectedValue;
      }
    });

    return ConstantChallenge(
      id: '${template.id}_${targetPlayer.id}_$currentRound',
      targetPlayer: targetPlayer,
      description: description,
      punishment: punishment,
      type: template.challengeType,
      startRound: currentRound,
      status: ConstantChallengeStatus.active,
      metadata: metadata,
    );
  }

  /// Determines if a constant challenge should be generated this round
  static bool shouldGenerateConstantChallenge(
    int currentRound,
    List<ConstantChallenge> activeChallenges,
  ) {
    // No constant challenges before round 5
    if (currentRound < 5) return false;

    // Lower probability if there are many active challenges
    final activeChallengeCount = activeChallenges.length;
    
    double baseProbability;
    if (activeChallengeCount == 0) {
      baseProbability = 0.15; // 15% chance if no active challenges
    } else if (activeChallengeCount < 3) {
      baseProbability = 0.08; // 8% chance if few active challenges
    } else {
      baseProbability = 0.03; // 3% chance if many active challenges
    }

    return _random.nextDouble() < baseProbability;
  }

  /// Determines if a constant challenge should be ended this round
  static bool shouldEndConstantChallenge(
    ConstantChallenge challenge,
    int currentRound,
  ) {
    if (!challenge.canBeEndedAtRound(currentRound)) return false;

    // Lower probability as time goes on to make challenges persist longer
    final roundsActive = currentRound - challenge.startRound;
    
    double probability;
    if (roundsActive >= 15) {
      probability = 0.25; // 25% chance after 15 rounds
    } else if (roundsActive >= 12) {
      probability = 0.15; // 15% chance after 12 rounds
    } else if (roundsActive >= 10) {
      probability = 0.08; // 8% chance after 10 rounds
    } else if (roundsActive >= 8) {
      probability = 0.05; // 5% chance after 8 rounds
    } else {
      probability = 0.02; // 2% chance after minimum 5 rounds
    }

    return _random.nextDouble() < probability;
  }

  /// Get a random player who doesn't have too many active challenges
  static Player? selectPlayerForNewChallenge(
    List<Player> players,
    List<ConstantChallenge> activeChallenges,
  ) {
    // Count active challenges per player
    Map<int, int> challengeCount = {};
    for (var player in players) {
      challengeCount[player.id] = activeChallenges
          .where((c) => c.targetPlayer.id == player.id)
          .length;
    }

    // Find players with the minimum number of active challenges
    final minChallenges = challengeCount.values.isEmpty ? 0 : challengeCount.values.reduce((a, b) => a < b ? a : b);
    final eligiblePlayers = players.where((player) => 
      (challengeCount[player.id] ?? 0) == minChallenges && minChallenges < 3
    ).toList();

    if (eligiblePlayers.isEmpty) return null;

    return eligiblePlayers[_random.nextInt(eligiblePlayers.length)];
  }
}