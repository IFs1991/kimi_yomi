import 'package:flutter/material.dart';
import '../../models/plan.dart';
import '../../models/payment_method.dart';

/// 支払い情報のサマリーを表示するウィジェット
class PaymentSummary extends StatelessWidget {
  final Plan selectedPlan;
  final PaymentMethod? selectedPaymentMethod; // 支払い方法が選択されていない場合もある

  const PaymentSummary({
    super.key,
    required this.selectedPlan,
    this.selectedPaymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
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
            Text('注文内容', style: textTheme.titleMedium),
            const SizedBox(height: 16.0),
            _buildSummaryRow('プラン', selectedPlan.name, textTheme),
            const SizedBox(height: 8.0),
            _buildSummaryRow('価格', selectedPlan.formattedPrice, textTheme),
            const Divider(height: 24.0),
            Text('お支払い方法', style: textTheme.titleMedium),
            const SizedBox(height: 16.0),
            selectedPaymentMethod != null
                ? _buildPaymentMethodRow(selectedPaymentMethod!, textTheme)
                : Text('支払い方法が選択されていません', style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            // 必要に応じて合計金額なども表示
            const Divider(height: 24.0),
             _buildSummaryRow(
              '合計',
              selectedPlan.formattedPrice, // 税込み価格など、実際の計算が必要な場合もある
              textTheme,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, TextTheme textTheme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? textTheme.titleMedium : textTheme.bodyMedium),
        Text(
          value,
          style: isTotal
            ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRow(PaymentMethod method, TextTheme textTheme) {
    IconData iconData;
    String description;

    switch (method.type) {
      case 'card':
        iconData = Icons.credit_card;
        description = '${method.brand ?? "カード"} (下4桁: ${method.last4 ?? "****"})';
        break;
      case 'apple_pay':
        iconData = Icons.apple; // 適切なアイコンに変更
        description = 'Apple Pay';
        break;
       case 'google_pay':
         iconData = Icons.payment; // 適切なアイコンに変更
         description = 'Google Pay';
         break;
      default:
        iconData = Icons.payment;
        description = method.type;
    }

    return Row(
      children: [
        Icon(iconData, size: 20),
        const SizedBox(width: 8.0),
        Text(description, style: textTheme.bodyMedium),
      ],
    );
  }
}