import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/diagnosis_model.dart';
import '../models/compatibility_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // 認証関連
  Future<User> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      body: json.encode({
        'email': email,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    throw Exception('ログインに失敗しました');
  }

  // 診断関連
  Future<DiagnosisSession> startDiagnosis(String userId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/diagnosis/start'),
      body: json.encode({'userId': userId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return DiagnosisSession.fromJson(json.decode(response.body));
    }
    throw Exception('診断の開始に失敗しました');
  }

  Future<Question> getNextQuestion(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/diagnosis/sessions/$sessionId/next'),
    );

    if (response.statusCode == 200) {
      return Question.fromJson(json.decode(response.body));
    }
    throw Exception('質問の取得に失敗しました');
  }

  Future<void> submitAnswer(String sessionId, String questionId, int score) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/diagnosis/sessions/$sessionId/answer'),
      body: json.encode({
        'questionId': questionId,
        'score': score,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('回答の送信に失敗しました');
    }
  }

  Future<DiagnosisResult> getDiagnosisResult(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/diagnosis/sessions/$sessionId/result'),
    );

    if (response.statusCode == 200) {
      return DiagnosisResult.fromJson(json.decode(response.body));
    }
    throw Exception('診断結果の取得に失敗しました');
  }

  // 相性診断関連
  Future<Compatibility> calculateCompatibility(String user1Id, String user2Id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/compatibility/calculate'),
      body: json.encode({
        'user1Id': user1Id,
        'user2Id': user2Id,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Compatibility.fromJson(json.decode(response.body));
    }
    throw Exception('相性診断の計算に失敗しました');
  }

  Future<DailyCompatibility> getDailyCompatibility(String userId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/compatibility/daily/$userId'),
    );

    if (response.statusCode == 200) {
      return DailyCompatibility.fromJson(json.decode(response.body));
    }
    throw Exception('日替わり相性診断の取得に失敗しました');
  }

  Future<List<Compatibility>> getCompatibilityHistory(String userId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/compatibility/history/$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Compatibility.fromJson(json)).toList();
    }
    throw Exception('相性診断履歴の取得に失敗しました');
  }

  // ユーザー関連
  Future<User> getUserProfile(String userId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/$userId'),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    throw Exception('ユーザープロフィールの取得に失敗しました');
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/users/$userId'),
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('プロフィールの更新に失敗しました');
    }
  }
}