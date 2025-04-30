import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // InputFormatters用
import '../../models/payment_method.dart';

/// 支払い情報（例：カード情報）入力フォームウィジェット
/// 注意: これは基本的な例です。実際のカード情報入力には、
/// Stripe Elementsなどの安全なUIコンポーネントを使用することを強く推奨します。
/// PCI DSS準拠のため、カード情報を直接サーバーに送信しないでください。
class PaymentForm extends StatefulWidget {
  final Function(PaymentMethod paymentMethod)? onPaymentMethodCreated;

  const PaymentForm({super.key, this.onPaymentMethodCreated});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // --- ここで決済プロバイダSDKを使用して支払い方法を作成 ---
      // 例 (Stripe SDK - これは概念的なもので、実際のSDKの使用方法は異なります):
      // try {
      //   final stripe = Stripe.instance;
      //   final paymentMethod = await stripe.createPaymentMethod(
      //     params: PaymentMethodParams.card(
      //       paymentMethodData: PaymentMethodData(
      //         billingDetails: BillingDetails(
      //           name: _nameController.text,
      //         ),
      //       ),
      //     ),
      //   );
      //   if (widget.onPaymentMethodCreated != null) {
      //      // 実際のPaymentMethodモデルに変換して渡す
      //     final appPaymentMethod = PaymentMethod(
      //         id: paymentMethod.id,
      //         type: 'card',
      //         last4: paymentMethod.card.last4, // SDKから取得
      //         brand: paymentMethod.card.brand, // SDKから取得
      //      );
      //     widget.onPaymentMethodCreated!(appPaymentMethod);
      //   }
      // } catch (e) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('支払い方法の作成に失敗しました: ${e.toString()}')),
      //   );
      // }
      // --- 仮実装 ---
      await Future.delayed(const Duration(seconds: 1)); // 処理をシミュレート
      final dummyPaymentMethod = PaymentMethod(
          id: 'pm_dummy_${DateTime.now().millisecondsSinceEpoch}',
          type: 'card',
          last4: _cardNumberController.text.substring(_cardNumberController.text.length - 4),
          brand: 'Visa', // 仮
      );
       if (widget.onPaymentMethodCreated != null) {
         widget.onPaymentMethodCreated!(dummyPaymentMethod);
       }
      print("Dummy Payment Method Created: ${dummyPaymentMethod.id}");
       // --- 仮実装終了 ---

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'カード名義人',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'カード名義人名を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'カード番号',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.replaceAll(' ', '').length != 16) {
                return '有効なカード番号を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(
                    labelText: '有効期限 (MM/YY)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 5 || !value.contains('/')) {
                      return 'MM/YY形式で入力してください';
                    }
                    // 簡単な有効性チェック (より厳密なチェックが必要)
                    final parts = value.split('/');
                    final month = int.tryParse(parts[0]);
                    final year = int.tryParse(parts[1]);
                    if (month == null || month < 1 || month > 12 || year == null) {
                       return '有効な年月を入力してください';
                    }
                    // 未来の日付かどうかのチェックも必要
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4), // Amexは4桁
                  ],
                   validator: (value) {
                    if (value == null || value.length < 3 || value.length > 4) {
                      return '有効なCVCを入力してください';
                    }
                    return null;
                  },
                   obscureText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('支払い情報を登録する'),
          ),
        ],
      ),
    );
  }
}

// カード番号入力フォーマッタ (スペース挿入)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}

// 有効期限入力フォーマッタ (MM/YY)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}