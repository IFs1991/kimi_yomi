import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

/// サブスクリプションの状態を管理するクラス
class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService;

  SubscriptionProvider(this._subscriptionService);

  Subscription? _currentSubscription;
  bool _isLoadingSubscription = false;
  bool _isCanceling = false;
  bool _isChangingPlan = false;
  String? _error;

  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoadingSubscription => _isLoadingSubscription;
  bool get isCanceling => _isCanceling;
  bool get isChangingPlan => _isChangingPlan;
  String? get error => _error;
  bool get hasActiveSubscription => _currentSubscription?.isActive ?? false;

  /// 現在のサブスクリプションをロードする
  Future<void> loadCurrentSubscription() async {
    _isLoadingSubscription = true;
    _error = null;
    notifyListeners();
    try {
      _currentSubscription = await _subscriptionService.getCurrentSubscription('DUMMY_USER_ID');
    } catch (e) {
      _error = 'サブスクリプション情報の取得に失敗しました: ${e.toString()}';
      _currentSubscription = null;
    } finally {
      _isLoadingSubscription = false;
      notifyListeners();
    }
  }

  /// サブスクリプションをキャンセルする
  Future<bool> cancelSubscription() async {
    if (_currentSubscription == null) {
      _setError('キャンセルするサブスクリプションがありません。');
      return false;
    }

    _isCanceling = true;
    _setError(null);
    notifyListeners();

    bool success = false;
    try {
      success = await _subscriptionService.cancelSubscription(_currentSubscription!.id);
      if (success) {
        await loadCurrentSubscription();
      } else {
         _setError('サブスクリプションのキャンセルに失敗しました。');
      }
    } catch (e) {
      _setError('サブスクリプションのキャンセル中にエラーが発生しました: ${e.toString()}');
      success = false;
    } finally {
      _isCanceling = false;
      notifyListeners();
    }
    return success;
  }

  /// サブスクリプションプランを変更する
  Future<bool> changePlan(String newPlanId) async {
    if (_currentSubscription == null) {
      _setError('プラン変更対象のサブスクリプションがありません。');
      return false;
    }
    if (_currentSubscription!.currentPlan.id == newPlanId) {
      _setError('現在と同じプランには変更できません。');
      return false;
    }

    _isChangingPlan = true;
    _setError(null);
    notifyListeners();

    bool success = false;
    try {
      final updatedSubscription = await _subscriptionService.changePlan(
        _currentSubscription!.id,
        newPlanId,
      );
      if (updatedSubscription != null) {
        _currentSubscription = updatedSubscription;
        success = true;
      } else {
        _setError('プラン変更に失敗しました。');
      }
    } catch (e) {
      _setError('プラン変更中にエラーが発生しました: ${e.toString()}');
      success = false;
    } finally {
      _isChangingPlan = false;
      notifyListeners();
    }
    return success;
  }

  /// 状態をリセットする（ログアウト時など）
  void resetState() {
     _currentSubscription = null;
     _isLoadingSubscription = false;
     _isCanceling = false;
     _isChangingPlan = false;
     _error = null;
     notifyListeners();
  }

  void _setError(String? message) {
    if (_error != message) {
      _error = message;
      _isLoadingSubscription = false;
      _isCanceling = false;
      _isChangingPlan = false;
      notifyListeners();
    }
  }
}