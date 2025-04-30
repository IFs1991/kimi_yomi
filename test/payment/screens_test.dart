import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../../lib/screens/payment/plan_selection_screen.dart'; // 相対パスに修正
import '../../lib/screens/payment/purchase_screen.dart'; // 相対パスに修正
import '../../lib/providers/subscription_provider.dart'; // 相対パスに修正
import '../../lib/providers/payment_provider.dart'; // 相対パスに修正
import '../../lib/models/plan.dart'; // 相対パスに修正
import '../../lib/models/payment_method.dart'; // 相対パスに修正
import '../../lib/services/subscription_service.dart'; // 相対パスに修正
import '../../lib/services/payment_service.dart'; // 相対パスに修正

// モック対象のクラスを指定 (build_runnerが必要)
import 'services_test.mocks.dart'; // services_testで生成したものを再利用可能

// Providerのモックを作成 (必要に応じて)
class MockSubscriptionProvider extends Mock implements SubscriptionProvider {}
class MockPaymentProvider extends Mock implements PaymentProvider {}

void main() {
  // --- PlanSelectionScreen Tests ---
  group('PlanSelectionScreen Widget Tests', () {
    late MockSubscriptionProvider mockSubscriptionProvider;
    late MockSubscriptionService mockSubscriptionService; // Providerのコンストラクタ用

    setUp(() {
      // モックのセットアップ
      mockSubscriptionService = MockSubscriptionService(); // これはGenerateMocksに追加するか、手動でMockクラスを作成
      mockSubscriptionProvider = MockSubscriptionProvider();
       // ダミーのプランリストを返すように設定
       when(mockSubscriptionProvider.availablePlans).thenReturn([
         Plan(id: 'p1', name: 'Plan A', description:'', price:100, currency:'', interval:'', features:[]),
         Plan(id: 'p2', name: 'Plan B', description:'', price:200, currency:'', interval:'', features:[]),
       ]);
       when(mockSubscriptionProvider.isLoadingPlans).thenReturn(false);
       when(mockSubscriptionProvider.error).thenReturn(null);
        // loadAvailablePlansの呼び出しをスタブ化 (非同期の場合)
       when(mockSubscriptionProvider.loadAvailablePlans()).thenAnswer((_) async {});
    });

    // ヘルパー関数: テスト対象ウィジェットをラップ
    Widget createTestableWidget(Widget child) {
      return MaterialApp(
        home: ChangeNotifierProvider<SubscriptionProvider>.value(
          value: mockSubscriptionProvider,
          child: child,
        ),
      );
    }

    testWidgets('Loads and displays plans correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const PlanSelectionScreen()));

      // ローディングが終わるのを待つ (もしあれば)
      await tester.pumpAndSettle();

      // プランが表示されていることを確認
      expect(find.text('Plan A'), findsOneWidget);
      expect(find.text('Plan B'), findsOneWidget);
      // プランカードのウィジェットタイプで探すことも可能
      // expect(find.byType(PlanCard), findsNWidgets(2));
       // ボタンが最初は非表示であることを確認
      expect(find.text('このプランで進む'), findsNothing);
    });

    testWidgets('Selecting a plan enables the bottom button', (WidgetTester tester) async {
       await tester.pumpWidget(createTestableWidget(const PlanSelectionScreen()));
       await tester.pumpAndSettle();

       // 最初のプランをタップ
       await tester.tap(find.text('Plan A'));
       await tester.pump(); // setStateを反映

       // ボタンが表示されることを確認
       expect(find.text('このプランで進む'), findsOneWidget);

        // 2番目のプランをタップ
       await tester.tap(find.text('Plan B'));
       await tester.pump();

       // ボタンがまだ表示されていることを確認
       expect(find.text('このプランで進む'), findsOneWidget);
    });

    testWidgets('Tapping button navigates (mock check)', (WidgetTester tester) async {
       await tester.pumpWidget(createTestableWidget(const PlanSelectionScreen()));
       await tester.pumpAndSettle();

       // プランを選択してボタンを有効化
       await tester.tap(find.text('Plan A'));
       await tester.pump();

       // ボタンをタップ
       await tester.tap(find.text('このプランで進む'));
       await tester.pump(); // ナビゲーション処理などを反映

       // TODO: 実際のナビゲーションテスト or モック化したNavigatorの呼び出し検証
       // この例ではprint出力とSnackBar表示をチェック
       expect(find.widgetWithText(SnackBar, 'Plan A を選択しました。購入画面へ進みます（未実装）'), findsOneWidget);
    });

    // ローディング表示やエラー表示のテストも追加...

  });

  // --- PurchaseScreen Tests ---
  group('PurchaseScreen Widget Tests', () {
      late MockPaymentProvider mockPaymentProvider;
      late MockPaymentService mockPaymentService; // Providerのコンストラクタ用
      final testPlan = Plan(id: 'p1', name: 'Test Plan', description: '', price: 100, currency: 'JPY', interval: 'month', features: []);

      setUp(() {
        mockPaymentService = MockPaymentService(); // GenerateMocksに追加するか手動作成
        mockPaymentProvider = MockPaymentProvider();
        // ダミーの支払い方法リストを返すように設定
        when(mockPaymentProvider.availableMethods).thenReturn([
          PaymentMethod(id: 'pm1', type: 'card', last4: '1234', brand: 'Visa')
        ]);
        when(mockPaymentProvider.selectedMethod).thenReturn(null); // 初期状態は未選択
        when(mockPaymentProvider.isLoading).thenReturn(false);
        when(mockPaymentProvider.errorMessage).thenReturn(null);
        // メソッド呼び出しのスタブ化
        when(mockPaymentProvider.loadAvailableMethods(any)).thenAnswer((_) async {});
        when(mockPaymentProvider.selectPaymentMethod(any)).thenAnswer((_) {});
      });

      Widget createTestableWidget(Widget child) {
        return MaterialApp(
          home: ChangeNotifierProvider<PaymentProvider>.value(
            value: mockPaymentProvider,
            child: child,
          ),
        );
      }

      testWidgets('Displays plan and payment methods', (WidgetTester tester) async {
         await tester.pumpWidget(createTestableWidget(PurchaseScreen(selectedPlan: testPlan)));
         await tester.pumpAndSettle();

         // プラン名が表示されているか
         expect(find.text(testPlan.name), findsOneWidget);
         // 支払い方法が表示されているか (RadioListTileのテキスト部分)
         expect(find.text('Visa (下4桁: 1234)'), findsOneWidget);
         // 追加ボタンが表示されているか
         expect(find.text('新しいカード情報を追加'), findsOneWidget);
         // 確認ボタンが最初は非表示であること
         expect(find.text('確認画面へ進む'), findsNothing);
      });

       testWidgets('Selecting a payment method enables button', (WidgetTester tester) async {
           // selectedMethodが更新されるようにモックを設定変更
          when(mockPaymentProvider.selectedMethod).thenAnswer((_) =>
             PaymentMethod(id: 'pm1', type: 'card', last4: '1234', brand: 'Visa')
          );

          await tester.pumpWidget(createTestableWidget(PurchaseScreen(selectedPlan: testPlan)));
          await tester.pumpAndSettle();

          // 支払い方法を選択 (RadioListTileをタップ)
          await tester.tap(find.text('Visa (下4桁: 1234)'));
          // モックProviderの状態が変わったことをUIに反映させるため再度pump
          // (実際のProviderならnotifyListenersで自動更新されるが、モックは手動で状態を反映させる必要あり)
          await tester.pump();

          // ボタンが表示されることの確認が必要だが、モックの状態更新がテスト内で反映されにくい
          // 代わりにProviderのselectPaymentMethodが呼ばれたことをverifyするなどが有効
           verify(mockPaymentProvider.selectPaymentMethod(any)).called(1);

          // ボタン表示の確認 (モックのselectedMethodがnullでない場合に表示される想定)
           expect(find.text('確認画面へ進む'), findsOneWidget);
       });

       testWidgets('Tapping add button shows payment form', (WidgetTester tester) async {
          await tester.pumpWidget(createTestableWidget(PurchaseScreen(selectedPlan: testPlan)));
          await tester.pumpAndSettle();

          // 追加ボタンをタップ
          await tester.tap(find.text('新しいカード情報を追加'));
          await tester.pump();

          // PaymentFormが表示されることを確認 (例: フォーム内の特定のテキストで)
          expect(find.text('カード名義人'), findsOneWidget);
          expect(find.text('支払い情報を登録する'), findsOneWidget);
       });

      // PaymentForm入力と作成後のテストも追加...
      // ConfirmationScreen, CompletionScreenのテストも同様に追加...
  });
}