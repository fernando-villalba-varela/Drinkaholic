import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class QuestionTemplate {
  final String id;
  final String template;
  final Map<String, List<String>> variables;
  final String categoria;

  QuestionTemplate({required this.id, required this.template, required this.variables, required this.categoria});

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) {
    return QuestionTemplate(
      id: json['id'],
      template: json['template'],
      variables: Map<String, List<String>>.from(
        json['variables'].map((key, value) => MapEntry(key, List<String>.from(value))),
      ),
      categoria: json['categoria'],
    );
  }
}

class GeneratedQuestion {
  final String question;
  final String categoria;
  final Map<String, String> usedVariables;
  final String? answer; // Respuesta extraída de paréntesis si existe

  GeneratedQuestion({
    required this.question,
    required this.categoria,
    required this.usedVariables,
    this.answer,
  });

  // Getters
  String get getQuestion => question;
  String get getCategoria => categoria;
  Map<String, String> get getUsedVariables => usedVariables;
  String? get getAnswer => answer;

  /// Extrae la respuesta del paréntesis si existe
  static String? extractAnswer(String question) {
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(question);
    return match?.group(1);
  }

  /// Limpia la pregunta removiendo la respuesta entre paréntesis
  static String cleanQuestion(String question) {
    return question.replaceAll(RegExp(r'\s*\(.*?\)\s*$'), '').trim();
  }
}

class QuestionGenerator {
  static final Random _random = Random();
  static List<QuestionTemplate>? _templates;
  static String _currentLanguage = 'es';

  /// Cargar las plantillas desde el JSON
  static Future<void> loadTemplates({String language = 'es'}) async {
    // Si ya están cargadas y el idioma es el mismo, no hacer nada
    if (_templates != null && _currentLanguage == language) return;

    // Actualizar idioma actual
    _currentLanguage = language;
    
    // Resetear templates para forzar recarga
    _templates = null;

    try {
      final String jsonPath = language == 'es' 
          ? 'assets/questions.json' 
          : 'assets/questions_$language.json';
          
      final String jsonString = await rootBundle.loadString(jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _templates = (jsonData['templates'] as List).map((template) => QuestionTemplate.fromJson(template)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading questions ($language): $e');
      }
      // Fallback a español si falla inglés (opcional, pero seguro)
      if (language != 'es') {
        print('Falling back to Spanish questions');
        await loadTemplates(language: 'es');
      } else {
        _templates = [];
      }
    }
  }

  /// Genera el número de tragos con probabilidades ponderadas
  /// 70% = 1 trago, 20% = 2 tragos, 10% = 3 tragos
  static String _generateDrinkAmount() {
    final randomValue = _random.nextDouble();

    if (randomValue < 0.5) {
      return '1 trago';
    } else if (randomValue < 0.8) {
      return '2 tragos';
    } else {
      return '3 tragos';
    }
  }

  /// Generar una pregunta aleatoria (excluyendo templates con PLAYER)
  static Future<GeneratedQuestion> generateRandomQuestion({String language = 'es'}) async {
    await loadTemplates(language: language);

    if (_templates == null || _templates!.isEmpty) {
      return GeneratedQuestion(
        question: 'Error: No se pudieron cargar las preguntas',
        categoria: 'Error',
        usedVariables: {},
      );
    }

    // Filtrar templates que NO contengan la variable PLAYER ni variables duales
    final nonPlayerTemplates = _templates!.where((template) {
      return !template.variables.values.any((values) => values.contains('PLAYER')) &&
          !(template.variables.containsKey('PLAYER1') &&
              template.variables.containsKey('PLAYER2') &&
              template.variables['PLAYER1']!.contains('DUAL_PLAYER1') &&
              template.variables['PLAYER2']!.contains('DUAL_PLAYER2'));
    }).toList();

    if (nonPlayerTemplates.isEmpty) {
      // Si todos los templates requieren PLAYER, usar uno cualquiera
      final template = _templates![_random.nextInt(_templates!.length)];
      if (kDebugMode) {
        print('Generando pregunta de la categoría (fallback): ${template.template}');
      }
      return _generateQuestionFromTemplate(template);
    }

    final template = nonPlayerTemplates[_random.nextInt(nonPlayerTemplates.length)];
    if (kDebugMode) {
      print('Generando pregunta de la categoría: ${template.template}');
    }
    return _generateQuestionFromTemplate(template);
  }

  /// Generar una pregunta aleatoria con un jugador específico
  static Future<GeneratedQuestion> generateRandomQuestionForPlayer(String playerName, {String language = 'es'}) async {
    await loadTemplates(language: language);

    if (_templates == null || _templates!.isEmpty) {
      return GeneratedQuestion(
        question: 'Error: No se pudieron cargar las preguntas',
        categoria: 'Error',
        usedVariables: {},
      );
    }

    // Filtrar solo templates que contengan la variable PLAYER (no dual)
    final playerTemplates = _templates!.where((template) {
      return template.variables.values.any((values) => values.contains('PLAYER')) &&
          !(template.variables.containsKey('PLAYER1') &&
              template.variables.containsKey('PLAYER2') &&
              template.variables['PLAYER1']!.contains('DUAL_PLAYER1') &&
              template.variables['PLAYER2']!.contains('DUAL_PLAYER2'));
    }).toList();

    if (playerTemplates.isEmpty) {
      // Si no hay templates con PLAYER, usar uno normal
      final template = _templates![_random.nextInt(_templates!.length)];
      return _generateQuestionFromTemplate(template);
      return GeneratedQuestion(
        question: '$playerName bebe 1 trago (Fallback)',
        categoria: 'Genérico',
        usedVariables: {'PLAYER': playerName},
      );
    }

    final template = playerTemplates[_random.nextInt(playerTemplates.length)];
    return _generateQuestionFromTemplate(template, playerName: playerName);
  }

  /// Generar una pregunta dual aleatoria (para 2 jugadores)
  static Future<GeneratedQuestion> generateRandomDualQuestion(String player1Name, String player2Name, {String language = 'es'}) async {
    await loadTemplates(language: language);

    if (_templates == null || _templates!.isEmpty) {
      return generateRandomQuestion();
    }

    // Filtrar solo templates duales
    final dualTemplates = _templates!.where((template) {
      return template.variables.containsKey('PLAYER1') &&
          template.variables.containsKey('PLAYER2') &&
          template.variables['PLAYER1']!.contains('DUAL_PLAYER1') &&
          template.variables['PLAYER2']!.contains('DUAL_PLAYER2');
    }).toList();

    if (dualTemplates.isEmpty) {
      // Si no hay templates duales, generar uno normal
      return generateRandomQuestion();
    }

    final template = dualTemplates[_random.nextInt(dualTemplates.length)];
    return _generateQuestionFromTemplate(template, playerName: player1Name, dualPlayerName: player2Name);
  }

  /// Generar una pregunta de una categoría específica
  static Future<GeneratedQuestion> generateQuestionByCategory(String categoria, {String? playerName}) async {
    await loadTemplates();

    if (_templates == null || _templates!.isEmpty) {
      return generateRandomQuestion();
    }

    final categoryTemplates = _templates!.where((template) => template.categoria == categoria).toList();

    if (categoryTemplates.isEmpty) {
      return generateRandomQuestion();
    }

    final template = categoryTemplates[_random.nextInt(categoryTemplates.length)];
    return _generateQuestionFromTemplate(template, playerName: playerName);
  }

  /// Obtener todas las categorías disponibles
  static Future<List<String>> getCategories() async {
    await loadTemplates();

    if (_templates == null || _templates!.isEmpty) {
      return [];
    }

    return _templates!.map((template) => template.categoria).toSet().toList()..sort();
  }

  /// Generar pregunta desde una plantilla específica
  static GeneratedQuestion _generateQuestionFromTemplate(
    QuestionTemplate template, {
    String? playerName,
    String? dualPlayerName,
  }) {
    String question = template.template;
    Map<String, String> usedVariables = {};

    // Reemplazar cada variable con un valor aleatorio
    template.variables.forEach((variableName, possibleValues) {
      if (variableName == 'Y' && possibleValues.contains('tragos')) {
        // Para Y = tragos, usar el generador de probabilidades
        final drinkAmount = _generateDrinkAmount();
        question = question.replaceAll('{$variableName}', drinkAmount);
        usedVariables[variableName] = drinkAmount;
      } else if (possibleValues.length == 1 && possibleValues[0] == 'PLAYER' && playerName != null) {
        // Para variables que solo contienen PLAYER, usar el nombre del jugador
        question = question.replaceAll('{$variableName}', playerName);
        usedVariables[variableName] = playerName;
      } else if (possibleValues.length == 1 && possibleValues[0] == 'DUAL_PLAYER1' && playerName != null) {
        // Para DUAL_PLAYER1, usar el primer jugador
        question = question.replaceAll('{$variableName}', playerName);
        usedVariables[variableName] = playerName;
      } else if (possibleValues.length == 1 && possibleValues[0] == 'DUAL_PLAYER2' && dualPlayerName != null) {
        // Para DUAL_PLAYER2, usar el segundo jugador
        question = question.replaceAll('{$variableName}', dualPlayerName);
        usedVariables[variableName] = dualPlayerName;
      } else {
        // Para otras variables, selección aleatoria normal
        final selectedValue = possibleValues[_random.nextInt(possibleValues.length)];
        question = question.replaceAll('{$variableName}', selectedValue);
        usedVariables[variableName] = selectedValue;
      }
    });

    // Extraer respuesta si existe
    final answer = GeneratedQuestion.extractAnswer(question);
    // Limpiar la pregunta removiendo la respuesta
    final cleanedQuestion = GeneratedQuestion.cleanQuestion(question);

    return GeneratedQuestion(
      question: cleanedQuestion,
      categoria: template.categoria,
      usedVariables: usedVariables,
      answer: answer,
    );
  }

  /// Generar múltiples preguntas únicas
  static Future<List<GeneratedQuestion>> generateMultipleQuestions(int count) async {
    List<GeneratedQuestion> questions = [];
    Set<String> usedQuestions = {};

    int attempts = 0;
    while (questions.length < count && attempts < count * 3) {
      final question = await generateRandomQuestion();
      if (!usedQuestions.contains(question.question)) {
        questions.add(question);
        usedQuestions.add(question.question);
      }
      attempts++;
    }

    return questions;
  }

  /// Método para testear las probabilidades de los tragos
  static void testDrinkProbabilities(int testCount) {
    Map<String, int> counts = {'1 trago': 0, '2 tragos': 0, '3 tragos': 0};

    for (int i = 0; i < testCount; i++) {
      final drink = _generateDrinkAmount();
      counts[drink] = (counts[drink] ?? 0) + 1;
    }

    if (kDebugMode) {
      print('Resultados de $testCount pruebas:');
    }
    counts.forEach((drink, count) {
      final percentage = (count / testCount * 100).toStringAsFixed(1);
      if (kDebugMode) {
        print('$drink: $count veces ($percentage%)');
      }
    });
  }
}
