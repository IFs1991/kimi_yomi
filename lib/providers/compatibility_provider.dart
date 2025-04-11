import 'package:flutter/foundation.dart';
import '../models/compatibility_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CompatibilityProvider with ChangeNotifier {
  final ApiService _apiService;
  DailyCompatibility? _dailyCompatibility;
  List<Compatibility> _history = [];
  bool _isLoading = false;

  CompatibilityProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  DailyCompatibility? get dailyCompatibility => _dailyCompatibility;
  List<Compatibility> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  Future<void> loadDailyCompatibility(String userId) async {
    if (_dailyCompatibility?.isToday ?? false) return;

    _isLoading = true;
    notifyListeners();

    try {
      _dailyCompatibility = await _apiService.getDailyCompatibility(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCompatibilityHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _apiService.getCompatibilityHistory(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Compatibility> calculateCompatibility(String user1Id, String user2Id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final compatibility = await _apiService.calculateCompatibility(user1Id, user2Id);
      _history.insert(0, compatibility);
      return compatibility;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 相性分析
  String getCompatibilityLevel(double score) {
    if (score >= 80) return '最高の相性';
    if (score >= 60) return '良い相性';
    if (score >= 40) return '普通の相性';
    return '要努力の相性';
  }

  List<String> getCompatibilityAdvice(Compatibility compatibility) {
    final List<String> advice = [];

    if (compatibility.details.valueScore >= 70) {
      advice.add('価値観が非常に近く、深い理解が期待できます');
    }

    if (compatibility.details.interestScore >= 70) {
      advice.add('共通の興味関心が多く、一緒に楽しめる活動が見つかりやすいでしょう');
    }

    if (compatibility.details.lifestyleScore >= 70) {
      advice.add('生活リズムが合っており、日常生活での摩擦が少ないでしょう');
    }

    if (compatibility.details.emotionScore >= 70) {
      advice.add('感情面での理解が深く、心地よいコミュニケーションが期待できます');
    }

    if (advice.isEmpty) {
      advice.add('お互いの違いを理解し、尊重し合うことで、より良い関係を築けるでしょう');
    }

    return advice;
  }

  List<String> getRecommendedActivities(Compatibility compatibility) {
    final List<String> activities = [];

    if (compatibility.details.interestScore >= 60) {
      activities.addAll([
        '共通の趣味を見つけるためのカフェ巡り',
        '一緒に新しい体験をするアクティビティ',
        '文化的なイベントへの参加',
      ]);
    }

    if (compatibility.details.lifestyleScore >= 60) {
      activities.addAll([
        '定期的な食事会',
        '一緒の運動やスポーツ',
        '休日の共同活動',
      ]);
    }

    if (activities.isEmpty) {
      activities.addAll([
        'お互いを知るためのカジュアルな会話',
        '短時間での交流から始める',
      ]);
    }

    return activities;
  }
}