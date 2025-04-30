import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import '../lib/main.dart' as app; // 相対パスに修正
import '../lib/providers/payment_provider.dart'; // 相対パスに修正
import '../lib/providers/subscription_provider.dart'; // 相対パスに修正
import '../lib/services/payment_service.dart'; // 相対パスに修正
import '../lib/services/subscription_service.dart'; // 相対パスに修正

// 必要ならモックを使う場合もあるが、統合テストでは実サービスや
// スタブ化されたバックエンドを使うことが多い

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Flow Integration Test', () {
    testWidgets('Full purchase flow for a basic plan', (WidgetTester tester) async {
      // --- アプリの起動 ---
      // main.dart で Provider を初期化してアプリを起動
      // (main.dartがサービスインスタンスを受け取るように変更済みと仮定)
      final paymentService = PaymentService(); // ここでは実インスタンスを使う例
      final subscriptionService = SubscriptionService();
      app.main(paymentService: paymentService, subscriptionService: subscriptionService); // 修正したmainを呼ぶ想定

      await tester.pumpAndSettle(); // アプリが安定するまで待つ

      // --- 1. ホーム画面からプラン選択画面へ ---
      print("Finding 'プラン選択画面へ' button...");
      expect(find.text('プラン選択画面へ'), findsOneWidget);
      await tester.tap(find.text('プラン選択画面へ'));
      await tester.pumpAndSettle(); // 画面遷移を待つ
      print("Navigated to PlanSelectionScreen.");

      // --- 2. プラン選択画面でプランを選択 ---
      // プランが表示されるまで待つ (非同期ロードのため)
      await tester.pump(const Duration(seconds: 2)); // 仮の待機時間
      expect(find.text('ベーシックプラン（月額）'), findsOneWidget);
      print("Found 'ベーシックプラン（月額）'. Tapping...");
      await tester.tap(find.text('ベーシックプラン（月額）'));
      await tester.pumpAndSettle();
      print("Plan selected. Finding 'このプランで進む' button...");

      // ボタンが有効化されたことを確認
      expect(find.text('このプランで進む'), findsOneWidget);
      await tester.tap(find.text('このプランで進む'));
      await tester.pumpAndSettle(); // PurchaseScreenへの遷移を待つ
      print("Navigated to PurchaseScreen.");

      // --- 3. 購入画面で支払い方法を選択 (ここでは既存のカードを選択するシナリオ) ---
       // 支払い方法が表示されるまで待つ
      await tester.pump(const Duration(seconds: 2)); // 仮の待機時間
      expect(find.text('Visa (下4桁: 4242)'), findsOneWidget);
      print("Found 'Visa (下4桁: 4242)'. Tapping...");
      await tester.tap(find.text('Visa (下4桁: 4242)'));
      await tester.pumpAndSettle();
      print("Payment method selected. Finding '確認画面へ進む' button...");

      // 確認ボタンが有効化されたことを確認
      expect(find.text('確認画面へ進む'), findsOneWidget);
      await tester.tap(find.text('確認画面へ進む'));
      await tester.pumpAndSettle(); // ConfirmationScreenへの遷移を待つ
      print("Navigated to ConfirmationScreen.");

      // --- 4. 確認画面で規約に同意して購入確定 ---
      expect(find.text('購入内容の確認'), findsOneWidget);
      // 利用規約チェックボックスを見つける (実装によってはKeyを使う方が確実)
      final checkbox = find.byType(CheckboxListTile);
      expect(checkbox, findsOneWidget);
      print("Found CheckboxListTile. Tapping...");
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      print("Checkbox tapped. Finding '購入を確定する' button...");

      // 購入ボタンが有効化されたことを確認 (isLoading=false, agreed=true)
      expect(find.text('購入を確定する'), findsOneWidget);
      final purchaseButton = find.widgetWithText(ElevatedButton, '購入を確定する');
      expect(tester.widget<ElevatedButton>(purchaseButton).enabled, isTrue);
      await tester.tap(purchaseButton);
       print("Tapped '購入を確定する'. Waiting for completion...");
      // 購入処理 (非同期) と完了画面への遷移を待つ
      await tester.pump(const Duration(seconds: 3)); // 支払い処理の仮待機時間
      await tester.pumpAndSettle();
      print("Navigated to CompletionScreen (presumably).");

      // --- 5. 完了画面の表示を確認 ---
      expect(find.text('購入完了'), findsOneWidget);
      expect(find.text('ベーシックプラン（月額） の購入が完了しました！'), findsOneWidget);
      expect(find.text('ホームに戻る'), findsOneWidget);
      print("Completion screen verified.");

       // --- 6. ホームに戻る ---
      await tester.tap(find.text('ホームに戻る'));
      await tester.pumpAndSettle();
      print("Navigated back home.");
      // ホーム画面に戻ったことを確認 (例: 特定のテキスト)
      expect(find.text('課金フローテスト'), findsOneWidget);
      print("Integration test completed successfully!");

    });

    // 他のシナリオ（新しいカード追加、エラーケースなど）のテストも追加
  });
}