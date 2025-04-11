import 'package:flutter/material.dart';
import '../../widgets/question_card.dart';
import '../../models/question.dart';
import '../../services/diagnosis_service.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({Key? key}) : super(key: key);

  @override
  _DiagnosisScreenState createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final PageController _pageController = PageController();
  final DiagnosisService _diagnosisService = DiagnosisService();
  List<Question> _questions = [];
  Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Load Big5 questions from service
    _questions = await _diagnosisService.getQuestions();
    setState(() {});
  }

  void _handleAnswer(int questionId, int value) {
    setState(() {
      _answers[questionId] = value;
      if (_pageController.page?.toInt() == _questions.length - 1) {
        _submitDiagnosis();
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _submitDiagnosis() async {
    // Submit answers to backend
    final result = await _diagnosisService.submitAnswers(_answers);
    // Navigate to results screen
    Navigator.pushNamed(context, '/results', arguments: result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性格診断テスト'),
        elevation: 0,
      ),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return QuestionCard(
                  question: _questions[index],
                  onAnswer: _handleAnswer,
                  currentValue: _answers[_questions[index].id],
                );
              },
            ),
    );
  }
}