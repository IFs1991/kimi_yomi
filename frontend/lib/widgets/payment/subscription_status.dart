import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用 (pubspec.yamlに追加が必要な場合があります)
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart'; // Providerを使用する場合
import 'package:provider/provider.dart'; // Providerパッケージ

/// 現在のサブスクリプションステータスを表示するウィジェット
class SubscriptionStatus extends StatelessWidget {
  const SubscriptionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // Providerパターンを使用する例
    // 他の状態管理ライブラリを使用する場合は適宜変更してください
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildStatusContent(context, subscriptionProvider),
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context, SubscriptionProvider provider) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (provider.isLoadingSubscription) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.currentSubscription == null) {
      return Text('サブスクリプション情報の取得に失敗しました。',
                 style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error));
    }

    final subscription = provider.currentSubscription;

    if (subscription == null || !subscription.isActive) {
      return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text('現在のサブスクリプション', style: textTheme.titleMedium),
           const SizedBox(height: 8.0),
           Text('有効なサブスクリプションはありません。', style: textTheme.bodyMedium),
           const SizedBox(height: 16.0),
           ElevatedButton( // プラン選択画面への導線など
             onPressed: () {
               // Navigator.pushNamed(context, '/plan-selection'); // 例
             },
             child: const Text('プランを見る')
           ),
         ],
      );
    }

    // 有効なサブスクリプションがある場合
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final nextBillingDate = dateFormat.format(subscription.currentPeriodEnd);
    final planName = subscription.plan.name;
    final statusText = subscription.status == 'trialing' ? 'トライアル中' : '有効';
    final statusColor = subscription.status == 'trialing' ? Colors.blue : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text('現在のサブスクリプション', style: textTheme.titleMedium),
             Chip(
               label: Text(statusText, style: textTheme.labelSmall?.copyWith(color: Colors.white)),
               backgroundColor: statusColor,
               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
               visualDensity: VisualDensity.compact,
             ),
          ],
        ),
        const SizedBox(height: 12.0),
        Text(planName, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Text('次回の請求日: $nextBillingDate', style: textTheme.bodyMedium),
        if (subscription.cancelAtPeriodEnd)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '期間終了日 ($nextBillingDate) にキャンセルされます。',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.error), // warn -> error に変更
            ),
          ),
        const SizedBox(height: 16.0),
        // キャンセルボタンなどのアクション
        if (!subscription.cancelAtPeriodEnd)
          TextButton(
            onPressed: provider.isCanceling ? null : () async {
               // キャンセル確認ダイアログ表示など
               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: const Text('サブスクリプションのキャンセル'),
                   content: const Text('本当にキャンセルしますか？期間終了まで利用できます。'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('いいえ')),
                     TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('はい')),
                   ],
                 ),
               ) ?? false;

               if (confirm) {
                 final success = await provider.cancelSubscription();
                 if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error ?? 'キャンセルに失敗しました'), backgroundColor: theme.colorScheme.error),
                    );
                 }
               }
            },
            child: provider.isCanceling
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('サブスクリプションをキャンセル', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}