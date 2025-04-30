import 'package:flutter/foundation.dart';
import '../models/diagnosis_model.dart';
import '../services/api_service.dart';
import './auth_provider.dart'; // AuthProvider をインポート

class DiagnosisProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider; // AuthProvider を保持
  DiagnosisSession? _currentSession;
  Question? _currentQuestion;
  DiagnosisResult? _result;
  bool _isLoading = false;
  Map<String, int> _answers = {};

  DiagnosisProvider({required AuthProvider authProvider, ApiService? apiService})
      : _authProvider = authProvider, // コンストラクタで AuthProvider を受け取る
        _apiService = apiService ?? ApiService();

  DiagnosisSession? get currentSession => _currentSession;
  Question? get currentQuestion => _currentQuestion;
  DiagnosisResult? get result => _result;
  bool get isLoading => _isLoading;
  Map<String, int> get answers => Map.unmodifiable(_answers);
  bool get isComplete => _currentSession?.isComplete ?? false;
  double get progress => _answers.length / 50; // 全50問を想定

  Future<void> startDiagnosis() async { // userId 引数を削除
    final userId = _authProvider.userId; // AuthProvider から userId を取得
    if (userId == null) {
      // ユーザーが認証されていない場合の処理 (例: エラーを投げる、ログイン画面に遷移させるなど)
      print('User not authenticated');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentSession = await _apiService.startDiagnosis(userId);
      await _loadNextQuestion();
      _answers.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitAnswer(int score) async {
    if (_currentSession == null || _currentQuestion == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.submitAnswer(
        _currentSession!.id,
        _currentQuestion!.id,
        score,
      );

      _answers[_currentQuestion!.id] = score;

      if (_answers.length < 50) { // 全50問を想定
        await _loadNextQuestion();
      } else {
        await _loadResult();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_currentSession == null) return;

    try {
      _currentQuestion = await _apiService.getNextQuestion(_currentSession!.id);
    } catch (e) {
      _currentQuestion = null;
      rethrow;
    }
  }

  Future<void> _loadResult() async {
    if (_currentSession == null) return;

    try {
      _result = await _apiService.getDiagnosisResult(_currentSession!.id);
      _currentSession = _currentSession!.copyWith(isComplete: true);
    } catch (e) {
      _result = null;
      rethrow;
    }
  }

  void reset() {
    _currentSession = null;
    _currentQuestion = null;
    _result = null;
    _answers.clear();
    notifyListeners();
  }

  // 回答の分析
  Map<String, double> getTraitScores() {
    if (_result == null) return {};

    return {
      '開放性': _result!.scores.openness,
      '誠実性': _result!.scores.conscientiousness,
      '外向性': _result!.scores.extraversion,
      '協調性': _result!.scores.agreeableness,
      '神経症的傾向': _result!.scores.neuroticism,
    };
  }

  List<PersonalityInsight> getInsights() {
    return _result?.insights ?? [];
  }

  String getDominantTrait() {
    if (_result == null) return '';

    final scores = getTraitScores();
    return scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}