import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plan.dart';
import '../../models/payment_method.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/payment/payment_form.dart';
import '../../widgets/payment/payment_summary.dart';
// import './confirmation_screen.dart'; // 次の画面への遷移用

/// 支払い方法選択と課金実行画面
class PurchaseScreen extends StatefulWidget {
  final Plan selectedPlan;

  const PurchaseScreen({super.key, required this.selectedPlan});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _showNewPaymentForm = false;
  final String _userId = "user_123"; // 仮のユーザーID

  @override
  void initState() {
    super.initState();
    // 利用可能な支払い方法をロード
    Future.microtask(() =>
      context.read<PaymentProvider>().loadAvailableMethods(_userId)
    );
  }

  void _onPaymentMethodSelected(PaymentMethod method) {
    context.read<PaymentProvider>().selectPaymentMethod(method);
    setState(() {
      _showNewPaymentForm = false; // 既存を選択したらフォームを閉じる
    });
  }

  void _onNewPaymentMethodCreated(PaymentMethod newMethod) {
     // 新しい支払い方法が作成された後、それを選択状態にする
     context.read<PaymentProvider>().selectPaymentMethod(newMethod);
     // 必要に応じて、新しい支払い方法リストを再ロードする
     // context.read<PaymentProvider>().loadAvailableMethods(_userId);
     setState(() {
       _showNewPaymentForm = false;
     });
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('新しい支払い方法を登録しました。')),
     );
  }

  void _navigateToConfirmationScreen() {
    final paymentProvider = context.read<PaymentProvider>();
    if (paymentProvider.selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支払い方法を選択してください。')),
      );
      return;
    }
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => ConfirmationScreen(
    //       selectedPlan: widget.selectedPlan,
    //       selectedPaymentMethod: paymentProvider.selectedMethod!)
    // ));
    print("Navigating to confirmation screen...");
    // TODO: 実際の画面遷移
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('確認画面へ進みます（未実装）。支払い方法: ${paymentProvider.selectedMethod!.type}')),
     );
  }


  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final availableMethods = paymentProvider.availableMethods;
    final selectedMethod = paymentProvider.selectedMethod;
    final isLoading = paymentProvider.isLoading;
    final error = paymentProvider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('お支払い'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('選択中のプラン', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            // プラン概要はPaymentSummaryに含めるか、別途表示
            Card(child: ListTile(title: Text(widget.selectedPlan.name), subtitle: Text(widget.selectedPlan.formattedPrice))),
            const SizedBox(height: 24.0),

            Text('お支払い方法を選択', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16.0),

            if (isLoading && availableMethods.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (error != null && availableMethods.isEmpty)
              Center(child: Text('エラー: $error'))
            else
              _buildPaymentMethodList(context, availableMethods, selectedMethod),

            const SizedBox(height: 16.0),

            if (_showNewPaymentForm)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: PaymentForm(onPaymentMethodCreated: _onNewPaymentMethodCreated),
              )
            else
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showNewPaymentForm = true;
                  });
                },
                icon: const Icon(Icons.add_card),
                label: const Text('新しいカード情報を追加'),
              ),
          ],
        ),
      ),
      bottomNavigationBar: selectedMethod != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _navigateToConfirmationScreen,
                child: const Text('確認画面へ進む'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0)),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentMethodList(BuildContext context, List<PaymentMethod> methods, PaymentMethod? selected) {
    if (methods.isEmpty && !_showNewPaymentForm) {
       return const Text('利用可能な支払い方法がありません。');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // SingleChildScrollView内なのでスクロール不要
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        return RadioListTile<PaymentMethod>(
          title: Text(_getPaymentMethodDescription(method)),
          secondary: Icon(_getPaymentMethodIcon(method.type)),
          value: method,
          groupValue: selected,
          onChanged: (PaymentMethod? value) {
            if (value != null) {
               _onPaymentMethodSelected(value);
            }
          },
        );
      },
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

   IconData _getPaymentMethodIcon(String type) {
     switch (type) {
      case 'card': return Icons.credit_card;
      case 'apple_pay': return Icons.apple; // 適切なアイコンに変更
      case 'google_pay': return Icons.payment; // 適切なアイコンに変更
      default: return Icons.payment;
    }
  }
}