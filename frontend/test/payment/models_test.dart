import 'package:flutter_test/flutter_test.dart';
import 'package:キミヨミ/models/plan.dart'; // プロジェクト名に合わせて修正
import 'package:キミヨミ/models/payment_method.dart';
import 'package:キミヨミ/models/purchase.dart';
import 'package:キミヨミ/models/subscription.dart';

void main() {
  group('Plan Model Tests', () {
    test('Plan.fromJson creates a valid Plan object', () {
      final json = {
        'id': 'plan1',
        'name': 'Test Plan',
        'description': 'Test Description',
        'price': 1000.0,
        'currency': 'JPY',
        'interval': 'month',
        'interval_count': 1,
        'features': ['Feature A', 'Feature B'],
      };
      final plan = Plan.fromJson(json);

      expect(plan.id, 'plan1');
      expect(plan.name, 'Test Plan');
      expect(plan.price, 1000.0);
      expect(plan.interval, 'month');
      expect(plan.features.length, 2);
      expect(plan.formattedPrice, '1000 JPY / month');
    });

    test('Plan.toJson creates a valid JSON map', () {
       final plan = Plan(
        id: 'plan2',
        name: 'Yearly Plan',
        description: '',
        price: 10000,
        currency: 'JPY',
        interval: 'year',
        features: [],
      );
      final json = plan.toJson();

      expect(json['id'], 'plan2');
      expect(json['interval'], 'year');
      expect(json['price'], 10000);
    });
  });

  group('PaymentMethod Model Tests', () {
     test('PaymentMethod.fromJson creates a valid PaymentMethod object', () {
      final json = {
        'id': 'pm_123',
        'type': 'card',
        'last4': '4242',
        'brand': 'Visa',
      };
      final method = PaymentMethod.fromJson(json);

      expect(method.id, 'pm_123');
      expect(method.type, 'card');
      expect(method.last4, '4242');
      expect(method.brand, 'Visa');
    });

     test('PaymentMethod.toJson creates a valid JSON map', () {
       final method = PaymentMethod(id: 'pm_abc', type: 'apple_pay');
       final json = method.toJson();

       expect(json['id'], 'pm_abc');
       expect(json['type'], 'apple_pay');
       expect(json['last4'], isNull);
     });
  });

  group('Purchase Model Tests', () {
     test('Purchase.fromJson creates a valid Purchase object', () {
        final json = {
          'id': 'pur_123',
          'user_id': 'user_abc',
          'plan': {
            'id': 'plan1',
            'name': 'Test Plan', 'description': '', 'price': 1000.0, 'currency': 'JPY', 'interval': 'month', 'features': []
          },
          'payment_method': {
            'id': 'pm_123', 'type': 'card', 'last4': '4242', 'brand': 'Visa'
          },
          'purchase_date': DateTime.now().toIso8601String(),
          'status': 'completed',
          'transaction_id': 'txn_123',
          'platform': 'ios'
        };
        final purchase = Purchase.fromJson(json);

        expect(purchase.id, 'pur_123');
        expect(purchase.userId, 'user_abc');
        expect(purchase.plan.id, 'plan1');
        expect(purchase.paymentMethod.id, 'pm_123');
        expect(purchase.status, 'completed');
     });

     // toJson テストも同様に追加
  });

  group('Subscription Model Tests', () {
     test('Subscription.fromJson creates a valid Subscription object', () {
       final planJson = {
         'id': 'plan_sub', 'name': 'Sub Plan', 'description': '', 'price': 500.0, 'currency': 'JPY', 'interval': 'month', 'features': []
       };
       final startDate = DateTime.now().subtract(const Duration(days: 5));
       final endDate = DateTime.now().add(const Duration(days: 25));

       final json = {
         'id': 'sub_abc',
         'user_id': 'user_xyz',
         'plan': planJson,
         'status': 'active',
         'current_period_start': startDate.toIso8601String(),
         'current_period_end': endDate.toIso8601String(),
         'cancel_at_period_end': false,
         'canceled_at': null,
         'trial_end': null,
       };
       final subscription = Subscription.fromJson(json);

       expect(subscription.id, 'sub_abc');
       expect(subscription.plan.id, 'plan_sub');
       expect(subscription.status, 'active');
       expect(subscription.isActive, isTrue);
       expect(subscription.currentPeriodStart.isAtSameMomentAs(startDate), isTrue);
     });

     test('Subscription isActive getter works correctly', () {
        final plan = Plan(id:'', name:'', description:'', price:0, currency:'', interval:'', features:[]);
        final subActive = Subscription(id:'', userId:'', plan:plan, status:'active', currentPeriodStart:DateTime.now(), currentPeriodEnd:DateTime.now(), cancelAtPeriodEnd:false);
        final subTrial = Subscription(id:'', userId:'', plan:plan, status:'trialing', currentPeriodStart:DateTime.now(), currentPeriodEnd:DateTime.now(), cancelAtPeriodEnd:false);
        final subCanceled = Subscription(id:'', userId:'', plan:plan, status:'canceled', currentPeriodStart:DateTime.now(), currentPeriodEnd:DateTime.now(), cancelAtPeriodEnd:true);

        expect(subActive.isActive, isTrue);
        expect(subTrial.isActive, isTrue);
        expect(subCanceled.isActive, isFalse);
     });

      // toJson テストも同様に追加
  });
}