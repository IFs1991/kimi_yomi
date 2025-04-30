import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'; // iOS specific
import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // Android specific
import '../models/plan.dart'; // Planモデルが必要な場合

/// アプリ内課金に関連するサービスクラス
class InAppPurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Public getter for products
  List<ProductDetails> get products => _products;

  InAppPurchaseService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isAvailable = await _iap.isAvailable();
    print('InAppPurchaseService: Store available? $_isAvailable');

    if (_isAvailable) {
      // プラットフォーム固有の初期化 (Android)
      if (Platform.isAndroid) {
        final InAppPurchaseAndroidPlatformAddition androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        // TODO: Verify/update this method call based on the in_app_purchase_android version.
        // await androidAddition.setObfuscatedAccountId('YOUR_OBFUSCATED_ACCOUNT_ID'); // 実際のIDを設定
        // 必要に応じて obfuscatedProfileId も設定
      }

      // 購入更新ストリームをリッスン開始
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('InAppPurchaseService: Purchase stream error - $error'),
      );

      // 未完了のトランザクションを処理 (オプション)
      // _processPendingPurchases();
    } else {
      print('InAppPurchaseService: Store is not available.');
    }
  }

  /// 利用可能な商品（プラン）を取得する
  Future<void> loadProducts(Set<String> productIds) async {
    if (!_isAvailable) return;

    print('InAppPurchaseService: Loading products for IDs: $productIds');
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        print('InAppPurchaseService: Error loading products - ${response.error!.message}');
        _products = [];
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        print('InAppPurchaseService: Products not found - ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      print('InAppPurchaseService: Products loaded: ${_products.map((p) => p.id).toList()}');
    } catch (e) {
      print('InAppPurchaseService: Error loading products - $e');
       _products = [];
    }
  }

  /// 商品（プラン）を購入する
  Future<bool> purchaseProduct(ProductDetails productDetails) async {
    if (!_isAvailable) {
      print('InAppPurchaseService: Cannot purchase, store not available.');
      return false;
    }
    print('InAppPurchaseService: Attempting to purchase ${productDetails.id}');
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    // プラットフォーム固有のパラメータ設定 (Android)
    // if (Platform.isAndroid) { ... }

    try {
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      // buyConsumable や buySubscription も利用可能
      print('InAppPurchaseService: Purchase request sent successfully? $success');
      return success;
    } catch (e) {
      print('InAppPurchaseService: Error during purchase initiation - $e');
      return false;
    }
  }

  /// 購入状態の更新をリッスンする
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      print('InAppPurchaseService: Purchase update received - ID: ${purchaseDetails.purchaseID}, Status: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('InAppPurchaseService: Purchase pending...');
          // UIに進捗を表示するなど
          break;
        case PurchaseStatus.error:
          print('InAppPurchaseService: Purchase error - ${purchaseDetails.error?.message}');
          _handleError(purchaseDetails.error);
          await _completePurchase(purchaseDetails); // エラーでも完了させる場合がある
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored: // 復元の場合も同様に処理
          print('InAppPurchaseService: Purchase successful or restored!');
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            print('InAppPurchaseService: Purchase verified. Delivering content...');
            // --- ここでコンテンツの付与やバックエンドでの検証を行う ---
            // 例: deliverProduct(purchaseDetails);
            // 例: _apiService.verifyReceipt(...);
            await _completePurchase(purchaseDetails); // ★重要: 購入処理を完了させる
          } else {
            print('InAppPurchaseService: Purchase verification failed.');
            // 必要に応じてエラー処理
            await _completePurchase(purchaseDetails); // 検証失敗でも完了させるか検討
          }
          break;
        case PurchaseStatus.canceled: // iOSで追加されたステータス
           print('InAppPurchaseService: Purchase canceled.');
           await _completePurchase(purchaseDetails);
           break;
        default:
          // 他のステータス (例: deferred - 親の承認待ちなど)
          break;
      }
    });
  }

  /// 購入情報を検証する（サーバーサイドでの検証を強く推奨）
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    print('InAppPurchaseService: Verifying purchase - ${purchaseDetails.purchaseID}');
    // --- ここにレシート検証ロジックを実装 ---
    // 1. purchaseDetails.verificationData を取得
    // 2. バックエンドAPIに送信してサーバーサイドで検証 (推奨)
    //    例: await _apiService.verifyReceipt(purchaseDetails.verificationData.serverVerificationData)
    // 3. クライアントサイドでの簡易検証 (非推奨)

    // 仮実装: 常に true を返す
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// 購入処理を完了する (ストアに通知する)
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      print('InAppPurchaseService: Completing purchase - ${purchaseDetails.purchaseID}');
      try {
        await _iap.completePurchase(purchaseDetails);
      } catch (e) {
        print('InAppPurchaseService: Error completing purchase - $e');
        // 必要に応じてエラー処理
      }
    }
  }

  /// 購入エラーを処理する
  void _handleError(IAPError? error) {
    if (error != null) {
      print('InAppPurchaseService: Purchase Error Details - Code: ${error.code}, Message: ${error.message}, Source: ${error.source}');
      // ユーザーにエラーメッセージを表示するなどの処理
    }
  }

  /// 購入済みアイテムをリストアする (iOS/Android)
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      print("Restore purchases initiated.");
    } catch (e) {
      print("Error restoring purchases: $e");
    }
  }

  void dispose() {
    print('InAppPurchaseService: Disposing service and cancelling subscription.');
    _subscription?.cancel();
  }
}