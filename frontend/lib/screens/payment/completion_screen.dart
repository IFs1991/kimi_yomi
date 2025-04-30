import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用
import '../../models/purchase.dart';
import '../../models/payment_method.dart';
import '../../widgets/payment/payment_summary.dart'; // サマリーの一部を再利用可能

/// 購入完了画面
class CompletionScreen extends StatelessWidget {
  final Purchase purchase;

  const CompletionScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('購入完了'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示に
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24.0),
              Text(
                '${purchase.plan.name} の購入が完了しました！',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'ご利用ありがとうございます。',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),

              // 購入詳細サマリー
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('購入内容', style: textTheme.titleMedium),
                       const SizedBox(height: 16.0),
                       _buildDetailRow('プラン', purchase.plan.name, textTheme),
                       const SizedBox(height: 8.0),
                       _buildDetailRow('購入日時', dateFormat.format(purchase.purchaseDate), textTheme),
                       const SizedBox(height: 8.0),
                       _buildDetailRow('支払い方法', _getPaymentMethodDescription(purchase.paymentMethod), textTheme),
                       const SizedBox(height: 8.0),
                       _buildDetailRow('トランザクションID', purchase.transactionId ?? 'N/A', textTheme),
                       const SizedBox(height: 8.0),
                       _buildDetailRow('合計金額', purchase.plan.formattedPrice, textTheme, isBold: true),
                    ],
                  )
                )
              ),

              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  // ホーム画面などに戻る
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('ホームに戻る'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, TextTheme textTheme, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ],
    );
  }

   String _getPaymentMethodDescription(PaymentMethod method) {
     switch (method.type) {
      case 'card':
        return '${method.brand ?? "カード"} (下4桁: ${method.last4 ?? "****"})';
      case 'apple_pay': return 'Apple Pay';
      case 'google_pay': return 'Google Pay';
      default: return method.type;
    }
  }
}