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

    // Filter only single-player templates (exclude dual templates)
    final singlePlayerTemplates = _templates!.where((template) {
      return !(template.variables.containsKey('PLAYER1') &&
               template.variables.containsKey('PLAYER2') &&
               template.variables['PLAYER1']!.contains('DUAL_PLAYER1') &&
               template.variables['PLAYER2']!.contains('DUAL_PLAYER2'));
    }).toList();
    
    if (singlePlayerTemplates.isEmpty) {
      return _generateChallengeFromTemplate(_templates!.first, targetPlayer, currentRound);
    }
    
    final template = singlePlayerTemplates[_random.nextInt(singlePlayerTemplates.length)];
    return _generateChallengeFromTemplate(template, targetPlayer, currentRound);
  }

  /// Generate a random dual constant challenge for two specific players
  static Future<ConstantChallenge> generateRandomDualConstantChallenge(
    Player player1,
    Player player2,
    int currentRound,
  ) async {
    await loadTemplates();
    
    if (_templates == null || _templates!.isEmpty) {
      // Fallback dual challenge
      return ConstantChallenge(
        id: 'dual_fallback_${_random.nextInt(10000)}',
        targetPlayer: player1, // Use first player as primary target
        description: '${player1.nombre}, cada vez que ${player2.nombre} beba por el juego, bebes 1 trago',
        punishment: 'Si ${player1.nombre} no bebe cuando debe, bebe 3 tragos adicionales',
        type: ConstantChallengeType.rule,
        startRound: currentRound,
        status: ConstantChallengeStatus.active,
        metadata: {'dualPlayer2': player2.nombre, 'dualPlayer2Id': player2.id},
      );
    }

    // Filter only dual-player templates
    final dualTemplates = _templates!.where((template) {
      return template.variables.containsKey('PLAYER1') &&
             template.variables.containsKey('PLAYER2') &&
             template.variables['PLAYER1']!.contains('DUAL_PLAYER1') &&
             template.variables['PLAYER2']!.contains('DUAL_PLAYER2');
    }).toList();
    
    if (dualTemplates.isEmpty) {
      return generateRandomConstantChallenge(player1, currentRound);
    }
    
    final template = dualTemplates[_random.nextInt(dualTemplates.length)];
    return _generateDualChallengeFromTemplate(template, player1, player2, currentRound);
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
      endDescription = template.endTemplate;
      
      // Handle dual challenges
      if (challenge.metadata.containsKey('dualPlayer2')) {
        final dualPlayer2 = challenge.metadata['dualPlayer2'] as String;
        endDescription = endDescription.replaceAll('{PLAYER1}', challenge.targetPlayer.nombre);
        endDescription = endDescription.replaceAll('{PLAYER2}', dualPlayer2);
      } else {
        // Handle single player challenges
        endDescription = endDescription.replaceAll('{PLAYER}', challenge.targetPlayer.nombre);
      }
      
      // Replace any other variables if needed using stored metadata
      challenge.metadata.forEach((key, value) {
        if (key != 'templateId' && key != 'dualPlayer2' && key != 'dualPlayer2Id') {
          endDescription = endDescription.replaceAll('{$key}', value.toString());
        }
      });
    } else {
      if (challenge.metadata.containsKey('dualPlayer2')) {
        final dualPlayer2 = challenge.metadata['dualPlayer2'] as String;
        endDescription = '${challenge.targetPlayer.nombre} y $dualPlayer2 ya no tienen restricciones especiales';
      } else {
        endDescription = '${challenge.targetPlayer.nombre} ya no tiene restricciones especiales';
      }
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

  /// Generate a dual challenge from a specific template
  static ConstantChallenge _generateDualChallengeFromTemplate(
    ConstantChallengeTemplate template,
    Player player1,
    Player player2,
    int currentRound,
  ) {
    String description = template.template;
    String punishment = template.punishment;
    Map<String, dynamic> metadata = {
      'templateId': template.id,
      'dualPlayer2': player2.nombre,
      'dualPlayer2Id': player2.id,
    };

    // Replace PLAYER1 and PLAYER2 first
    description = description.replaceAll('{PLAYER1}', player1.nombre);
    description = description.replaceAll('{PLAYER2}', player2.nombre);
    punishment = punishment.replaceAll('{PLAYER1}', player1.nombre);
    punishment = punishment.replaceAll('{PLAYER2}', player2.nombre);
    
    // Replace other variables with random values
    template.variables.forEach((variableName, possibleValues) {
      if (variableName != 'PLAYER1' && variableName != 'PLAYER2' && possibleValues.isNotEmpty) {
        final selectedValue = possibleValues[_random.nextInt(possibleValues.length)];
        description = description.replaceAll('{$variableName}', selectedValue);
        punishment = punishment.replaceAll('{$variableName}', selectedValue);
        metadata[variableName] = selectedValue;
      }
    });

    return ConstantChallenge(
      id: '${template.id}_${player1.id}_${player2.id}_$currentRound',
      targetPlayer: player1, // Primary target is player1
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