import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class QuestionTemplate {
  final String id;
  final String template;
  final Map<String, List<String>> variables;
  final String categoria;

  QuestionTemplate({
    required this.id,
    required this.template,
    required this.variables,
    required this.categoria,
  });

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) {
    return QuestionTemplate(
      id: json['id'],
      template: json['template'],
      variables: Map<String, List<String>>.from(
        json['variables'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      categoria: json['categoria'],
    );
  }
}

class GeneratedQuestion {
  final String question;
  final String categoria;
  final Map<String, String> usedVariables;

  GeneratedQuestion({
    required this.question,
    required this.categoria,
    required this.usedVariables,
  });
}

class QuestionGenerator {
  static final Random _random = Random();
  static List<QuestionTemplate>? _templates;

  /// Cargar las plantillas desde el JSON
  static Future<void> loadTemplates() async {
    if (_templates != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _templates = (jsonData['templates'] as List)
          .map((template) => QuestionTemplate.fromJson(template))
          .toList();
    } catch (e) {
      print('Error loading questions: $e');
      _templates = [];
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

  /// Generar una pregunta aleatoria
  static Future<GeneratedQuestion> generateRandomQuestion() async {
    await loadTemplates();
    
    if (_templates == null || _templates!.isEmpty) {
      return GeneratedQuestion(
        question: 'Error: No se pudieron cargar las preguntas',
        categoria: 'Error',
        usedVariables: {},
      );
    }

    final template = _templates![_random.nextInt(_templates!.length)];
    return _generateQuestionFromTemplate(template);
  }

  /// Generar una pregunta de una categoría específica
  static Future<GeneratedQuestion> generateQuestionByCategory(String categoria) async {
    await loadTemplates();
    
    if (_templates == null || _templates!.isEmpty) {
      return generateRandomQuestion();
    }

    final categoryTemplates = _templates!
        .where((template) => template.categoria == categoria)
        .toList();
    
    if (categoryTemplates.isEmpty) {
      return generateRandomQuestion();
    }
    
    final template = categoryTemplates[_random.nextInt(categoryTemplates.length)];
    return _generateQuestionFromTemplate(template);
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
  static GeneratedQuestion _generateQuestionFromTemplate(QuestionTemplate template) {
    String question = template.template;
    Map<String, String> usedVariables = {};

    // Reemplazar cada variable con un valor aleatorio
    template.variables.forEach((variableName, possibleValues) {
      if (variableName == 'Y' && possibleValues.contains('tragos')) {
        // Para Y = tragos, usar el generador de probabilidades
        final drinkAmount = _generateDrinkAmount();
        question = question.replaceAll('{$variableName}', drinkAmount);
        usedVariables[variableName] = drinkAmount;
      } else {
        // Para otras variables, selección aleatoria normal
        final selectedValue = possibleValues[_random.nextInt(possibleValues.length)];
        question = question.replaceAll('{$variableName}', selectedValue);
        usedVariables[variableName] = selectedValue;
      }
    });

    return GeneratedQuestion(
      question: question,
      categoria: template.categoria,
      usedVariables: usedVariables,
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
    
    print('Resultados de $testCount pruebas:');
    counts.forEach((drink, count) {
      final percentage = (count / testCount * 100).toStringAsFixed(1);
      print('$drink: $count veces ($percentage%)');
    });
  }
}