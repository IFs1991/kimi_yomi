import 'package:flutter/material.dart';
import 'package:kimi_yomi/widgets/diagnosis/question_card.dart';
import 'package:kimi_yomi/models/diagnosis_model.dart'; // Added import for Question model
// import '../../models/question.dart'; // Commented out as file might not exist
// import 'package:kimi_yomi/services/diagnosis_service.dart'; // Removed incorrect path
import 'package:kimi_yomi/services/api_service.dart'; // Added import for ApiService

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({Key? key}) : super(key: key);

  @override
  _DiagnosisScreenState createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService(); // Use ApiService
  String? _sessionId;
  Question? _currentQuestion;
  int _currentQuestionIndex = 0; // Added question index state
  int _totalQuestions = 50; // Added total questions state (assuming 50 for now)
  // List<Question> _questions = []; // Replaced with _currentQuestion
  Map<String, int> _answers = {}; // Changed key type to String (questionId)

  @override
  void initState() {
    super.initState();
    _startDiagnosisSession();
    // _loadQuestions(); // Replaced with _startDiagnosisSession
  }

  Future<void> _startDiagnosisSession() async {
    try {
      // TODO: Replace 'dummyUserId' with actual logged-in user ID
      final session = await _apiService.startDiagnosis('dummyUserId');
      setState(() {
        _sessionId = session.id;
        _currentQuestionIndex = session.currentQuestionIndex;
        // TODO: Get total questions from session or config if available
        // _totalQuestions = session.totalQuestions;
      });
      _loadNextQuestion(); // Load the first question
    } catch (e) {
      // Handle error (show message to user)
      print("Error starting diagnosis: $e");
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_sessionId == null) return;
    try {
      final question = await _apiService.getNextQuestion(_sessionId!);
      setState(() {
        _currentQuestion = question;
        _currentQuestionIndex++; // Increment index after loading next question
      });
    } catch (e) {
      // Handle error (e.g., all questions answered or API error)
      print("Error loading next question: $e");
      // Potentially navigate to results or show error
       if (e.toString().contains('診断は既に完了しています') || e.toString().contains('No more questions')) { // Check for completion messages
         _getResults();
       }
    }
  }


  Future<void> _loadQuestions() async {
    // This method is no longer used with the new session-based approach
    // // Load Big5 questions from service
    // _questions = await _diagnosisService.getQuestions();
    // setState(() {});
  }

  void _handleAnswer(String questionId, int value) async { // Changed questionId type to String
    if (_sessionId == null) return;
    setState(() {
      _answers[questionId] = value;
    });

    try {
      await _apiService.submitAnswer(_sessionId!, questionId, value);
      // Load next question or finish
      _loadNextQuestion();
    } catch (e) {
       print("Error submitting answer: $e");
       // Handle submission error
    }

    // Original PageView logic (commented out)
    // setState(() {
    //   _answers[questionId] = value;
    //   if (_pageController.page?.toInt() == _questions.length - 1) {
    //     _submitDiagnosis();
    //   } else {
    //     _pageController.nextPage(
    //       duration: const Duration(milliseconds: 300),
    //       curve: Curves.easeInOut,
    //     );
    //   }
    // });
  }

  Future<void> _getResults() async {
     if (_sessionId == null) return;
     try {
       final result = await _apiService.getDiagnosisResult(_sessionId!);
       Navigator.pushNamed(context, '/results', arguments: result);
     } catch (e) {
       print("Error getting results: $e");
       // Handle error getting results
     }
  }

  Future<void> _submitDiagnosis() async {
    // This method is potentially replaced by _getResults or integrated into _loadNextQuestion error handling
    // // Submit answers to backend
    // final result = await _diagnosisService.submitAnswers(_answers);
    // // Navigate to results screen
    // Navigator.pushNamed(context, '/results', arguments: result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性格診断テスト'),
        elevation: 0,
      ),
      body: _currentQuestion == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuestionCard(
                  question: _currentQuestion!.content,
                  questionNumber: _currentQuestionIndex, // Use state for index
                  totalQuestions: _totalQuestions, // Use state for total
                  onValueChanged: (value) => _handleAnswer(_currentQuestion!.id, value),
                  currentValue: _answers[_currentQuestion!.id] ?? 3, // Default value
              ),
            )
      // Original PageView (commented out)
      // body: _questions.isEmpty
      //     ? const Center(child: CircularProgressIndicator())
      //     : PageView.builder(
      //         controller: _pageController,
      //         physics: const NeverScrollableScrollPhysics(),
      //         itemCount: _questions.length,
      //         itemBuilder: (context, index) {
      //           return QuestionCard(
      //             question: _questions[index],
      //             onAnswer: _handleAnswer,
      //             currentValue: _answers[_questions[index].id],
      //           );
      //         },
      //       ),
    );
  }
}