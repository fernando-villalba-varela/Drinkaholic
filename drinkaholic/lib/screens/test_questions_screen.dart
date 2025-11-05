import 'package:flutter/material.dart';
import '../models/question_generator.dart';
import '../ui/components/drinkaholic_button.dart';
import '../ui/components/drinkaholic_card.dart';

class TestQuestionsScreen extends StatefulWidget {
  const TestQuestionsScreen({super.key});

  @override
  State<TestQuestionsScreen> createState() => _TestQuestionsScreenState();
}

class _TestQuestionsScreenState extends State<TestQuestionsScreen> {
  String _currentQuestion = 'Presiona el botón para generar una pregunta';
  String _currentCategory = '';
  List<String> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await QuestionGenerator.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _generateRandomQuestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final question = await QuestionGenerator.generateRandomQuestion();
      setState(() {
        _currentQuestion = question.question;
        _currentCategory = question.categoria;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentQuestion = 'Error: $e';
        _currentCategory = 'Error';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateQuestionByCategory(String category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final question = await QuestionGenerator.generateQuestionByCategory(category);
      setState(() {
        _currentQuestion = question.question;
        _currentCategory = question.categoria;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentQuestion = 'Error: $e';
        _currentCategory = 'Error';
        _isLoading = false;
      });
    }
  }

  void _testProbabilities() {
    QuestionGenerator.testDrinkProbabilities(1000);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Revisa la consola para ver los resultados del test de probabilidades'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23606E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Test de Preguntas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Pregunta actual
            DrinkaholicCard(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_currentCategory.isNotEmpty && _currentCategory != 'Error')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _currentCategory,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : Text(
                          _currentQuestion,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                ],
              ),
            ),

            // Botón generar pregunta aleatoria
            SizedBox(
              width: double.infinity,
              child: DrinkaholicButton(
                label: 'Generar Pregunta Aleatoria',
                icon: Icons.shuffle,
                onPressed: _isLoading ? null : _generateRandomQuestion,
                variant: DrinkaholicButtonVariant.primary,
                height: 56,
              ),
            ),

            const SizedBox(height: 20),

            // Botón test de probabilidades
            SizedBox(
              width: double.infinity,
              child: DrinkaholicButton(
                label: 'Test Probabilidades (Ver Consola)',
                icon: Icons.analytics_outlined,
                onPressed: _testProbabilities,
                variant: DrinkaholicButtonVariant.secondary,
                height: 52,
              ),
            ),

            const SizedBox(height: 20),

            // Categorías
            const Text(
              'Generar por categoría:',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return DrinkaholicButton(
                    label: category,
                    onPressed: _isLoading ? null : () => _generateQuestionByCategory(category),
                    variant: DrinkaholicButtonVariant.secondary,
                    fullWidth: true,
                    height: 44,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
