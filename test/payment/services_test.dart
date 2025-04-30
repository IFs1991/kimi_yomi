import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/payment_service.dart'; // 相対パスに修正
import '../lib/services/subscription_service.dart'; // 相対パスに修正
import '../lib/services/in_app_purchase_service.dart'; // 相対パスに修正
import '../lib/services/api_service.dart'; // 相対パスに修正
import '../lib/models/plan.dart'; // 相対パスに修正
import '../lib/models/payment_method.dart'; // 相対パスに修正
import '../lib/models/purchase.dart'; // 相対パスに修正
import '../lib/models/subscription.dart'; // 相対パスに修正

// モック対象のクラスを指定 (build_runnerが必要)
@GenerateMocks([ApiService, InAppPurchaseService]) // 他にモックしたいクラスがあれば追加
import 'services_test.mocks.dart'; // 生成されるファイル

void main() {
  late MockApiService mockApiService;
  late PaymentService paymentService;
  late SubscriptionService subscriptionService;
  // late MockInAppPurchaseService mockInAppPurchaseService; // IAPテスト用

  setUp(() {
    // 各テストの前にモックとサービスを初期化
    mockApiService = MockApiService();
    paymentService = PaymentService(/* mockApiService */); // ApiServiceに依存する場合
    subscriptionService = SubscriptionService(/* mockApiService */); // ApiServiceに依存する場合
    // mockInAppPurchaseService = MockInAppPurchaseService();
  });

  group('PaymentService Tests', () {
    final testPlan = Plan(id: 'p1', name: 'Test Plan', description: '', price: 100, currency: 'JPY', interval: 'month', features: []);
    final testMethod = PaymentMethod(id: 'pm1', type: 'card', last4: '1234', brand: 'Visa');
    const userId = 'user1';

    test('processPayment returns a Purchase on successful API call (example)', () async {
       // --- モックの設定例 (ApiServiceに依存する場合) ---
       /*
       // `createPaymentIntent` が呼ばれたら成功レスポンスを返すように設定
       when(mockApiService.createPaymentIntent(any, any, any))
           .thenAnswer((_) async => {'client_secret': 'test_secret'});

       // `confirmTransaction` が呼ばれたらダミーのPurchaseを返すように設定
       when(mockApiService.confirmTransaction(any, any, any))
            .thenAnswer((_) async => Purchase(
                  id: 'test_purchase', userId: userId, plan: testPlan,
                  paymentMethod: testMethod, purchaseDate: DateTime.now(),
                  status: 'completed'
                ));
       */
       // --- ここまでモック設定例 ---

       // サービスのメソッドを呼び出し (現在はApiServiceに依存していないため、モックなしで直接テスト)
       final purchase = await paymentService.processPayment(
         userId: userId,
         selectedPlan: testPlan,
         paymentMethod: testMethod,
       );

       // 結果を検証 (現在はダミーデータを返すので、基本的な検証のみ)
       expect(purchase, isA<Purchase>());
       expect(purchase.userId, userId);
       expect(purchase.plan.id, testPlan.id);
       expect(purchase.paymentMethod.id, testMethod.id);
       expect(purchase.status, 'completed');

       // --- モックの呼び出し検証例 (ApiServiceに依存する場合) ---
       /*
       verify(mockApiService.createPaymentIntent(userId, testPlan.id, testMethod.id)).called(1);
       verify(mockApiService.confirmTransaction(eq(userId), any, any)).called(1);
       */
       // --- ここまでモック検証例 ---
    });

     test('getAvailablePaymentMethods returns list of methods (example)', () async {
       // モック設定 (APIから取得する場合)
       // when(mockApiService.getPaymentMethods(userId)).thenAnswer((_) async => [...]);

       final methods = await paymentService.getAvailablePaymentMethods(userId);

       // 結果検証 (現在は固定値を返す)
       expect(methods, isA<List<PaymentMethod>>());
       expect(methods.isNotEmpty, isTrue);
       expect(methods.first.type, 'card');
     });

    // エラーケースのテストも追加...
  });

  group('SubscriptionService Tests', () {
     const userId = 'user_sub_test';
     final plan1 = Plan(id: 'p_sub1', name: 'Sub Plan 1', description: '', price: 500, currency: 'JPY', interval: 'month', features: []);

    test('getAvailablePlans returns a list of plans (example)', () async {
      // モック設定 (APIから取得する場合)
      // when(mockApiService.getPlans()).thenAnswer((_) async => [plan1.toJson()]);

      final plans = await subscriptionService.getAvailablePlans();

      expect(plans, isA<List<Plan>>());
      expect(plans.isNotEmpty, isTrue);
      // 現在は固定データを返すので、詳細な検証も可能
      expect(plans.any((p) => p.id == 'plan_monthly_basic'), isTrue);
    });

    test('getCurrentSubscription returns Subscription or null (example)', () async {
       // モック設定 (APIから取得する場合)
       /*
       final subData = Subscription(
         id: 'sub_test', userId: userId, plan: plan1, status: 'active',
         currentPeriodStart: DateTime.now(), currentPeriodEnd: DateTime.now().add(Duration(days:30)),
         cancelAtPeriodEnd: false
       );
       when(mockApiService.getUserSubscription(userId)).thenAnswer((_) async => subData);
       */

       final subscription = await subscriptionService.getCurrentSubscription(userId);

       // 結果検証 (現在はダミーデータを返す)
       expect(subscription, isA<Subscription?>());
       if (subscription != null) {
          expect(subscription.userId, userId);
          expect(subscription.status, 'active');
       }
    });

    test('cancelSubscription completes (example)', () async {
      // モック設定 (APIを呼ぶ場合)
      // when(mockApiService.cancelSubscription(any)).thenAnswer((_) async => {});

      // サービスのメソッドを呼び出し
      final result = await subscriptionService.cancelSubscription('sub_123');

      // 結果検証 (現在は常にtrueを返す)
      expect(result, isTrue);

      // モックの呼び出し検証 (APIを呼ぶ場合)
      // verify(mockApiService.cancelSubscription('sub_123')).called(1);
    });

    // エラーケースのテストも追加...
  });

  // InAppPurchaseServiceのテストも同様に追加 (モックを使用)
  // group('InAppPurchaseService Tests', () { ... });
}