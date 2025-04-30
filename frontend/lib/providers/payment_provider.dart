import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // ProductDetails のため
import 'dart:io'; // Platform 確認のため

import '../models/payment_method.dart';
import '../models/plan.dart';
import '../models/purchase.dart';
import '../services/payment_service.dart';
import '../services/in_app_purchase_service.dart'; // 追加
import './auth_provider.dart'; // AuthProvider をインポート

/// 支払い処理の状態を管理するクラス
class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService;
  final InAppPurchaseService _inAppPurchaseService; // 追加
  AuthProvider? _authProvider; // AuthProvider インスタンスを保持

  // コンストラクタを修正
  PaymentProvider(this._paymentService, this._inAppPurchaseService);

  // AuthProvider を更新するメソッド
  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // 必要に応じて、認証状態の変更に基づいて支払い方法などを再ロード
    // 例: if (authProvider.isAuthenticated) loadAvailableMethods();
    // notifyListeners(); // 変更を通知する場合
  }

  List<PaymentMethod> _availableMethods = [];
  PaymentMethod? _selectedMethod;
  bool _isLoading = false;
  String? _errorMessage;
  Purchase? _lastPurchase; // クレカ/Stripe経由の購入結果
  // IAPの結果は InAppPurchaseService のリスナーで処理されるため、ここでは直接扱わないことが多い

  List<ProductDetails> _storeProducts = []; // ストアの商品リスト

  List<PaymentMethod> get availableMethods => _availableMethods;
  PaymentMethod? get selectedMethod => _selectedMethod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Purchase? get lastPurchase => _lastPurchase; // クレカ購入結果用
  List<ProductDetails> get storeProducts => _storeProducts; // ストア商品リストのゲッター

  /// 利用可能な支払い方法をロードする (userId を AuthProvider から取得)
  Future<void> loadAvailableMethods() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      _setError('ユーザーが認証されていません。');
      _availableMethods = []; // 認証されていない場合は空にする
      notifyListeners();
      return;
    }
    final userId = _authProvider!.userId;
    if (userId == null) {
      _setError('ユーザーIDが取得できませんでした。');
      _availableMethods = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    try {
      // userId を使用して支払い方法を取得
      _availableMethods = await _paymentService.getAvailablePaymentMethods(userId);
    } catch (e) {
      _setError('支払い方法の取得に失敗しました: ${e.toString()}');
      _availableMethods = []; // エラー時も空にする
    } finally {
      _setLoading(false);
    }
  }

  /// ストアから商品情報をロードする (IAP用)
  Future<void> loadStoreProducts(Set<String> productIds) async {
    _setLoading(true);
    _clearError();
    try {
      await _inAppPurchaseService.loadProducts(productIds);
      _storeProducts = _inAppPurchaseService.products;
    } catch (e) {
      _setError('ストア商品の取得に失敗しました: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 支払い方法を選択する
  void selectPaymentMethod(PaymentMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  /// 支払い処理を実行する (userId を AuthProvider から取得)
  Future<bool> processPayment(Plan selectedPlan) async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      _setError('ユーザーが認証されていません。');
      return false;
    }
    final userId = _authProvider!.userId;
    if (userId == null) {
      _setError('ユーザーIDが取得できませんでした。');
      return false;
    }

    if (_selectedMethod == null) {
      _setError('支払い方法が選択されていません。');
      return false;
    }

    _setLoading(true);
    _clearError();
    _lastPurchase = null;

    try {
      bool success = false;
      // 支払い方法タイプで分岐
      if (_selectedMethod!.type == PaymentType.card) {
        // クレジットカード払い (PaymentService経由)
        final purchaseResult = await _paymentService.processPayment(
          userId, // userId を渡す
          selectedPlan,
          _selectedMethod!,
        );
        _lastPurchase = purchaseResult;
        success = purchaseResult != null;
        if (!success) _setError('カード決済に失敗しました。');

      } else if ((Platform.isIOS && _selectedMethod!.type == PaymentType.inAppPurchaseApple) ||
                 (Platform.isAndroid && _selectedMethod!.type == PaymentType.inAppPurchaseGoogle)) {
        // アプリ内課金 (InAppPurchaseService経由)
        // IAPの場合、通常サーバー側でユーザーIDと購入情報を紐付けるため、
        // ここで直接 userId を使う必要はないかもしれないが、必要に応じて _inAppPurchaseService に渡す
        final productIdToPurchase = selectedPlan.platformProductId;
        if (productIdToPurchase == null) {
          _setError('プランに対応する商品IDが見つかりません。');
          return false;
        }
        final productDetails = _storeProducts.firstWhere(
          (p) => p.id == productIdToPurchase,
          orElse: () => throw Exception('ストア商品が見つかりません: $productIdToPurchase')
        );

        // purchaseProduct に userId を渡すか、Service内でAuthProviderを参照するか検討
        success = await _inAppPurchaseService.purchaseProduct(productDetails, userId: userId);
        // IAPの結果は purchaseStream で非同期に通知されるため、ここでは直接 Purchase オブジェクトは得られない
        // 成功した場合、UI側で購入開始されたことを示すなどの対応
        if (!success) _setError('アプリ内課金の開始に失敗しました。');

      } else {
        _setError('未対応の支払い方法タイプです: ${_selectedMethod!.type}');
        return false;
      }

      if (success) {
         _setError(null); // 成功時はエラーメッセージをクリア
      }
      notifyListeners(); // UI更新のため
      return success;

    } catch (e) {
      _setError('支払い処理中にエラーが発生しました: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- ヘルパーメソッド ---
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      _setLoading(false); // エラー発生時はローディング解除
      notifyListeners();
    }
  }

  void _clearError() {
     if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}