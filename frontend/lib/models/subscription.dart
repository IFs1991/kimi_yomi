import 'package:kimi_yomi/models/plan.dart';

/// サブスクリプションの状態
enum SubscriptionStatus {
  active, // 有効
  inactive, // 無効 (期間終了など)
  paused, // 一時停止中
  cancelled, // キャンセル済み (期間終了までは有効な場合あり)
  pending, // 支払い確認中など
  unknown,
}

/// ユーザーのサブスクリプション情報を表現するモデルクラス
class Subscription {
  final String id; // サブスクリプションの一意なID
  final String userId; // ユーザーID
  final Plan currentPlan; // 現在のプラン
  final SubscriptionStatus status; // 現在のステータス
  final DateTime startDate; // 開始日
  final DateTime? endDate; // 終了日 (期間が決まっている場合)
  final DateTime? trialEndDate; // トライアル終了日
  final DateTime? nextBillingDate; // 次回請求日
  final bool autoRenew; // 自動更新が有効か

  Subscription({
    required this.id,
    required this.userId,
    required this.currentPlan,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    this.nextBillingDate,
    this.autoRenew = true,
  });

  // 必要に応じてJSON変換などのメソッドを追加
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      // PlanのfromJsonを呼び出す (PlanモデルにfromJson実装が必要)
      currentPlan: Plan.fromJson(json['current_plan'] as Map<String, dynamic>),
      status: SubscriptionStatus.values[json['status'] as int],
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      trialEndDate: json['trial_end_date'] != null ? DateTime.parse(json['trial_end_date'] as String) : null,
      nextBillingDate: json['next_billing_date'] != null ? DateTime.parse(json['next_billing_date'] as String) : null,
      autoRenew: json['auto_renew'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      // PlanのtoJsonを呼び出す (PlanモデルにtoJson実装が必要)
      'current_plan': currentPlan.toJson(),
      'status': status.index,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'trial_end_date': trialEndDate?.toIso8601String(),
      'next_billing_date': nextBillingDate?.toIso8601String(),
      'auto_renew': autoRenew,
    };
  }

  /// サブスクリプションが有効かどうか
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.paused;
}