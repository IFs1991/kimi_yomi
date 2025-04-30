import 'package:flutter/foundation.dart';
import '../models/compatibility_model.dart';
import '../services/api_service.dart';
import './auth_provider.dart'; // AuthProviderをインポート

class CompatibilityProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider; // AuthProviderを追加
  DailyCompatibility? _dailyCompatibility;
  List<Compatibility> _history = [];
  bool _isLoading = false;

  CompatibilityProvider({
    ApiService? apiService,
    required AuthProvider authProvider, // AuthProviderを必須引数に追加
  })  : _apiService = apiService ?? ApiService(),
        _authProvider = authProvider; // AuthProviderを初期化

  DailyCompatibility? get dailyCompatibility => _dailyCompatibility;
  List<Compatibility> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  Future<void> loadDailyCompatibility() async { // userId引数を削除
    if (_dailyCompatibility?.isToday ?? false) return;
    if (!_authProvider.isAuthenticated) return; // 認証チェック

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authProvider.currentUser!.id; // AuthProviderからuserIdを取得
      _dailyCompatibility = await _apiService.getDailyCompatibility(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCompatibilityHistory() async { // userId引数を削除
    if (!_authProvider.isAuthenticated) return; // 認証チェック

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authProvider.currentUser!.id; // AuthProviderからuserIdを取得
      _history = await _apiService.getCompatibilityHistory(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Compatibility> calculateCompatibility(String user2Id) async { // user1Id引数を削除
    if (!_authProvider.isAuthenticated) {
      throw Exception('User not authenticated'); // 認証されていない場合は例外をスロー
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user1Id = _authProvider.currentUser!.id; // AuthProviderからuser1Idを取得
      final compatibility = await _apiService.calculateCompatibility(user1Id, user2Id);
      // 履歴への追加は任意。重複を避けるなどのロジックが必要な場合がある
      if (!_history.any((c) => (c.user1.id == user1Id && c.user2.id == user2Id) || (c.user1.id == user2Id && c.user2.id == user1Id))) {
         _history.insert(0, compatibility);
      }
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