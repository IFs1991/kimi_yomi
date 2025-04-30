import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/diagnosis_model.dart';
import '../models/compatibility_model.dart';
import '../models/plan.dart';
import '../models/subscription.dart';
import '../models/payment_method.dart';
import '../models/purchase.dart';

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

  // --- 課金関連API (仮実装) ---

  /// 利用可能なプランを取得する
  Future<List<Plan>> getPlans() async {
    final response = await _client.get(Uri.parse('$baseUrl/plans'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Plan.fromJson(json)).toList();
    }
    throw Exception('プランの取得に失敗しました');
  }

  /// ユーザーの現在のサブスクリプションを取得する
  Future<Subscription?> getUserSubscription(String userId) async {
    final response = await _client.get(Uri.parse('$baseUrl/users/$userId/subscription'));
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      return Subscription.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null; // サブスクリプションが存在しない場合
    }
    throw Exception('サブスクリプションの取得に失敗しました');
  }

  /// 支払いインテントを作成する (Stripe等)
  Future<Map<String, dynamic>> createPaymentIntent(String userId, String planId, String paymentMethodId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/payments/create-intent'),
      body: json.encode({
        'userId': userId,
        'planId': planId,
        'paymentMethodId': paymentMethodId, // 必要に応じて送信
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body); // client_secret などを含むMapを返す想定
    }
    throw Exception('支払いインテントの作成に失敗しました');
  }

  /// トランザクションを検証/記録する
  Future<Purchase> confirmTransaction(String userId, String transactionId, Map<String, dynamic> verificationData) async {
      final response = await _client.post(
        Uri.parse('$baseUrl/payments/confirm'),
        body: json.encode({
          'userId': userId,
          'transactionId': transactionId,
          'verificationData': verificationData, // プラットフォームからの検証データ
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return Purchase.fromJson(json.decode(response.body));
      }
      throw Exception('トランザクションの確認に失敗しました');
  }

  /// サブスクリプションをキャンセルする
  Future<void> cancelSubscription(String subscriptionId) async {
      final response = await _client.delete(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('サブスクリプションのキャンセルに失敗しました');
      }
  }

  /// サブスクリプションプランを変更する
  Future<Subscription> changeSubscriptionPlan(String subscriptionId, String newPlanId) async {
    final response = await _client.patch( // または PUT
      Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
      body: json.encode({
        'planId': newPlanId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Subscription.fromJson(json.decode(response.body)); // 更新されたSubscriptionを返す想定
    }
    throw Exception('プラン変更に失敗しました');
  }

  /// アプリ内課金レシートを検証する
  Future<Purchase> verifyReceipt(String userId, String receiptData, String source) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/payments/verify-receipt'),
      body: json.encode({
        'userId': userId,
        'receiptData': receiptData,
        'source': source, // 'ios' or 'android'
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      // 検証成功後、対応するPurchase情報を返す想定
      return Purchase.fromJson(json.decode(response.body));
    }
    throw Exception('レシート検証に失敗しました');
  }
}