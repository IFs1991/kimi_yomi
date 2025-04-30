import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plan.dart';
import '../../models/payment_method.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/payment/payment_summary.dart';
// import './completion_screen.dart'; // 次の画面への遷移用

/// 購入確認画面
class ConfirmationScreen extends StatefulWidget {
  final Plan selectedPlan;
  final PaymentMethod selectedPaymentMethod;

  const ConfirmationScreen({
    super.key,
    required this.selectedPlan,
    required this.selectedPaymentMethod,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _agreedToTerms = false;
  final String _userId = "user_123"; // 仮のユーザーID

  void _processPurchase() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約に同意してください。')),
      );
      return;
    }

    final paymentProvider = context.read<PaymentProvider>();
    final success = await paymentProvider.processPayment(_userId, widget.selectedPlan);

    if (success && context.mounted) {
      // Navigator.pushReplacement(context, MaterialPageRoute(
      //   builder: (context) => CompletionScreen(purchase: paymentProvider.lastPurchase!)
      // ));
       print("Payment successful! Navigating to completion screen...");
       // TODO: 実際の画面遷移
        ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('購入が完了しました！完了画面へ進みます（未実装）。ID: ${paymentProvider.lastPurchase?.id}')),
       );
       // 支払い完了後、前の画面に戻れないようにするなどの処理が必要
       Navigator.popUntil(context, (route) => route.isFirst); // 例：最初の画面まで戻る

    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('購入処理に失敗しました: ${paymentProvider.errorMessage ?? "不明なエラー"}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final isLoading = paymentProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('購入内容の確認'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentSummary(
              selectedPlan: widget.selectedPlan,
              selectedPaymentMethod: widget.selectedPaymentMethod,
            ),
            const SizedBox(height: 24.0),
            CheckboxListTile(
              title: GestureDetector(
                 onTap: () {
                   // TODO: 利用規約表示ロジック
                   print("Show Terms and Conditions");
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('利用規約'),
                        content: const SingleChildScrollView(
                          child: Text("ここに利用規約の全文が入ります...\n" * 10),
                        ),
                        actions: [
                           TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
                        ],
                      )
                    );
                 },
                 child: const Text(
                  '利用規約に同意する',
                  style: TextStyle(decoration: TextDecoration.underline),
                 )
              ),
              value: _agreedToTerms,
              onChanged: (bool? value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24.0),
            // 注意書きなど
            Text(
              '「購入を確定する」ボタンを押すと、${widget.selectedPlan.formattedPrice} が選択されたお支払い方法に請求されます。サブスクリプションは自動更新されます。いつでもキャンセルできます。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isLoading || !_agreedToTerms ? null : _processPurchase,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('購入を確定する'),
        ),
      ),
    );
  }
}