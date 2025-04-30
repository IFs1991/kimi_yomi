import 'package:kimi_yomi/models/payment_method.dart';
import 'package:kimi_yomi/models/plan.dart';
import 'package:kimi_yomi/models/purchase.dart';
// import 'package:kimi_yomi/services/api_service.dart'; // 後で連携

/// 決済処理に関するサービスクラス
class PaymentService {
  // final ApiService _apiService; // バックエンドAPIサービス

  // PaymentService(this._apiService);

  /// Stripeなどの決済プロバイダを使用して支払いを行う（仮実装）
  ///
  /// [plan]: 購入するプラン
  /// [paymentMethod]: 使用する支払い方法
  /// 戻り値: 購入結果 (Purchaseオブジェクト)
  Future<Purchase?> processPayment(Plan plan, PaymentMethod paymentMethod) async {
    print('PaymentService: Processing payment for plan ${plan.id} using method ${paymentMethod.id}');

    // --- ここにStripe SDKやバックエンドAPI呼び出しを実装 ---
    // 例: Stripe支払いインテントの作成・確認
    // 例: _apiService.createPaymentIntent(...)
    // 例: _apiService.confirmPayment(...)

    // 仮の成功レスポンス (後で実際のロジックに置き換える)
    await Future.delayed(const Duration(seconds: 2)); // ネットワーク遅延をシミュレート

    // 成功した場合のダミーPurchaseオブジェクトを生成
    // 実際にはAPIからのレスポンスを元に生成する
    final dummyPurchase = Purchase(
      id: 'dummy_purchase_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user_id', // 実際のユーザーIDを取得する処理が必要
      purchasedPlan: plan,
      paymentMethodUsed: paymentMethod,
      purchaseDate: DateTime.now(),
      amountPaid: plan.price,
      currency: plan.currency,
      status: PurchaseStatus.completed,
      transactionId: 'dummy_txn_${DateTime.now().millisecondsSinceEpoch}',
    );

    print('PaymentService: Payment successful');
    return dummyPurchase;

    // エラーハンドリング (try-catchなど)
    // catch (e) {
    //   print('PaymentService: Payment failed - $e');
    //   return null;
    // }
  }

  /// 利用可能な支払い方法リストを取得する（仮実装）
  Future<List<PaymentMethod>> getAvailablePaymentMethods() async {
    print('PaymentService: Fetching available payment methods...');
    // 仮実装: ダミーデータを返す
    await Future.delayed(const Duration(seconds: 1));
    return [
      PaymentMethod(
        id: 'pm_card_visa_1234',
        type: PaymentType.card,
        last4: '1234',
        brand: 'Visa',
        expiryDate: DateTime(2028, 12),
        isDefault: true
      ),
      PaymentMethod(
        id: 'pm_card_master_5678',
        type: PaymentType.card,
        last4: '5678',
        brand: 'Mastercard',
        expiryDate: DateTime(2027, 8)
      ),
    ];
  }

  // 必要に応じて他のメソッドを追加 (支払い方法の追加・削除など)
}