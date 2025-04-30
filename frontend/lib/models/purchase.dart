import 'package:kimi_yomi/models/plan.dart';
import 'package:kimi_yomi/models/payment_method.dart';

/// 購入トランザクションの状態
enum PurchaseStatus {
  pending, // 保留中
  completed, // 完了
  failed, // 失敗
  refunded, // 返金済み
  cancelled, // キャンセル済み
  unknown,
}

/// 購入トランザクションを表現するモデルクラス
class Purchase {
  final String id; // 購入トランザクションの一意なID
  final String userId; // 購入したユーザーのID
  final Plan purchasedPlan; // 購入したプラン
  final PaymentMethod paymentMethodUsed; // 使用された支払い方法
  final DateTime purchaseDate; // 購入日時
  final double amountPaid; // 支払い額
  final String currency; // 通貨
  final PurchaseStatus status; // 購入ステータス
  final String? transactionId; // 決済プロバイダのトランザクションID
  final String? receiptData; // レシートデータ (アプリ内課金など)

  Purchase({
    required this.id,
    required this.userId,
    required this.purchasedPlan,
    required this.paymentMethodUsed,
    required this.purchaseDate,
    required this.amountPaid,
    required this.currency,
    required this.status,
    this.transactionId,
    this.receiptData,
  });

  // JSON変換メソッドを追加
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      // PlanとPaymentMethodのfromJsonを呼び出す
      purchasedPlan: Plan.fromJson(json['purchased_plan'] as Map<String, dynamic>),
      paymentMethodUsed: PaymentMethod.fromJson(json['payment_method_used'] as Map<String, dynamic>),
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      currency: json['currency'] as String,
      status: PurchaseStatus.values[json['status'] as int],
      transactionId: json['transaction_id'] as String?,
      receiptData: json['receipt_data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      // PlanとPaymentMethodのtoJsonを呼び出す
      'purchased_plan': purchasedPlan.toJson(),
      'payment_method_used': paymentMethodUsed.toJson(),
      'purchase_date': purchaseDate.toIso8601String(),
      'amount_paid': amountPaid,
      'currency': currency,
      'status': status.index,
      'transaction_id': transactionId,
      'receipt_data': receiptData,
    };
  }
}