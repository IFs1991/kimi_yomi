import 'package:kimi_yomi/models/subscription.dart';
import 'package:kimi_yomi/models/plan.dart';
// import 'package:kimi_yomi/services/api_service.dart'; // 後で連携

/// ユーザーのサブスクリプション管理に関するサービスクラス
class SubscriptionService {
  // final ApiService _apiService; // バックエンドAPIサービス

  // SubscriptionService(this._apiService);

  /// 現在のユーザーのサブスクリプション情報を取得する（仮実装）
  ///
  /// [userId]: 対象のユーザーID
  /// 戻り値: 現在のSubscription情報、存在しない場合はnull
  Future<Subscription?> getCurrentSubscription(String userId) async {
    print('SubscriptionService: Fetching current subscription for user $userId');

    // --- ここにバックエンドAPI呼び出しを実装 ---
    // 例: final response = await _apiService.getSubscription(userId);
    // 例: return Subscription.fromJson(response.data);

    // 仮のレスポンス (後で実際のロジックに置き換える)
    await Future.delayed(const Duration(seconds: 1));

    // ダミーデータ (プランもダミー)
    final dummyPlan = Plan(
      id: 'premium_monthly',
      name: 'プレミアムプラン',
      description: '全ての機能が利用可能です',
      price: 1000,
      currency: 'JPY',
      interval: PlanInterval.month
    );
    final dummySubscription = Subscription(
      id: 'sub_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      currentPlan: dummyPlan,
      status: SubscriptionStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 15)),
      nextBillingDate: DateTime.now().add(const Duration(days: 15)),
      autoRenew: true,
    );

    print('SubscriptionService: Found active subscription');
    return dummySubscription;

    // エラーハンドリングや、サブスクリプションが存在しない場合のnull返却
    // catch (e) {
    //   print('SubscriptionService: Error fetching subscription - $e');
    //   return null;
    // }
  }

  /// サブスクリプションをキャンセルする（仮実装）
  ///
  /// [subscriptionId]: キャンセルするサブスクリプションのID
  /// 戻り値: キャンセルが成功したかどうか
  Future<bool> cancelSubscription(String subscriptionId) async {
    print('SubscriptionService: Attempting to cancel subscription $subscriptionId');

    // --- ここにバックエンドAPI呼び出しを実装 ---
    // 例: final response = await _apiService.cancelSubscription(subscriptionId);
    // 例: return response.success;

    // 仮の成功レスポンス
    await Future.delayed(const Duration(seconds: 1));
    print('SubscriptionService: Subscription cancelled successfully');
    return true;

    // エラーハンドリング
    // catch (e) {
    //   print('SubscriptionService: Error cancelling subscription - $e');
    //   return false;
    // }
  }

  /// サブスクリプションプランを変更する（仮実装）
  ///
  /// [subscriptionId]: 変更対象のサブスクリプションID
  /// [newPlanId]: 新しいプランのID
  /// 戻り値: プラン変更後のSubscription情報、失敗した場合はnull
  Future<Subscription?> changePlan(String subscriptionId, String newPlanId) async {
    print('SubscriptionService: Attempting to change plan for subscription $subscriptionId to $newPlanId');

    // --- ここにバックエンドAPI呼び出しを実装 ---
    // 例: final response = await _apiService.changeSubscriptionPlan(subscriptionId, newPlanId);
    // 例: return Subscription.fromJson(response.data);

    // 仮の成功レスポンス
    await Future.delayed(const Duration(seconds: 2));

    // ダミーデータ (変更後のプランとサブスクリプション)
    final newDummyPlan = Plan(
      id: newPlanId,
      name: 'アルティメットプラン',
      description: '全てを超えたプラン',
      price: 3000,
      currency: 'JPY',
      interval: PlanInterval.month
    );
    final updatedDummySubscription = Subscription(
      id: subscriptionId,
      userId: 'current_user_id', // 実際のユーザーID
      currentPlan: newDummyPlan,
      status: SubscriptionStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 15)), // 本来は変更前の開始日
      nextBillingDate: DateTime.now().add(const Duration(days: 30)), // 次回請求日も更新されるはず
      autoRenew: true,
    );
    print('SubscriptionService: Plan changed successfully');
    return updatedDummySubscription;

    // エラーハンドリング
    // catch (e) {
    //   print('SubscriptionService: Error changing plan - $e');
    //   return null;
    // }
  }

  // 必要に応じて他のメソッドを追加 (サブスクリプション再開など)
}