import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Coreをインポート
import 'firebase_options.dart'; // 生成されたfirebase_options.dartをインポート

import './providers/auth_provider.dart';
import './providers/diagnosis_provider.dart';
import './providers/payment_provider.dart';
import './providers/compatibility_provider.dart';
import './providers/user_profile_provider.dart';
import './services/api_service.dart';
import './services/diagnosis_service.dart';
import './services/payment_service.dart';
import './services/compatibility_service.dart';
import './services/user_profile_service.dart';
import './services/in_app_purchase_service.dart'; // 追加

import './screens/splash_screen.dart'; // スプラッシュ画面
import './screens/auth_screen.dart';
import './screens/home_screen.dart';
import './screens/diagnosis/diagnosis_intro_screen.dart';
import './screens/diagnosis/diagnosis_question_screen.dart';
import './screens/diagnosis/diagnosis_result_screen.dart';
import './screens/payment/plan_selection_screen.dart';
import './screens/payment/payment_method_screen.dart';
import './screens/payment/confirmation_screen.dart';
// import './screens/payment/completion_screen.dart'; // まだ使わない
import './screens/compatibility/compatibility_input_screen.dart';
import './screens/compatibility/compatibility_result_screen.dart';
import './screens/profile/user_profile_screen.dart';
import './screens/profile/edit_profile_screen.dart';

void main() async { // mainをasyncに変更
  WidgetsFlutterBinding.ensureInitialized(); // Flutterバインディングを初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebaseを初期化
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- サービスインスタンスの生成 ---
    final apiService = ApiService();
    final diagnosisService = DiagnosisService(apiService);
    final paymentService = PaymentService(apiService);
    final compatibilityService = CompatibilityService(apiService);
    final userProfileService = UserProfileService(apiService);
    final inAppPurchaseService = InAppPurchaseService(); // IAPサービス生成

    return MultiProvider(
      providers: [
        // --- 基本的なプロバイダー ---
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // --- 依存関係のあるプロバイダー (ProxyProviderを使用) ---
        ChangeNotifierProxyProvider<AuthProvider, DiagnosisProvider>(
          create: (_) => DiagnosisProvider(diagnosisService), // 初期生成
          update: (_, auth, previousDiagnosis) =>
              previousDiagnosis!..updateAuthProvider(auth), // AuthProviderを更新
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (_) => PaymentProvider(paymentService, inAppPurchaseService), // 初期生成 (IAPサービスも渡す)
          update: (_, auth, previousPayment) =>
              previousPayment!..updateAuthProvider(auth), // AuthProviderを更新
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompatibilityProvider>(
          create: (_) => CompatibilityProvider(compatibilityService),
          update: (_, auth, previousCompatibility) =>
              previousCompatibility!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(userProfileService),
          update: (_, auth, previousProfile) =>
              previousProfile!..updateAuthProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Kimi Yomi',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'NotoSansJP', // 例: 日本語フォント指定
          ),
          // 認証状態に基づいて表示する画面を決定
          home: auth.isAuth
              ? const HomeScreen() // 認証済みならホーム画面
              : FutureBuilder(
                  future: auth.tryAutoLogin(), // 自動ログイン試行
                  builder: (ctx, authResultSnapshot) =>
                      authResultSnapshot.connectionState == ConnectionState.waiting
                          ? const SplashScreen() // 待機中はスプラッシュ画面
                          : const AuthScreen(), // それ以外は認証画面
                ),
          routes: {
            // '/': (ctx) => const SplashScreen(), // 初期ルートはhomeで管理
            '/auth': (ctx) => const AuthScreen(),
            '/home': (ctx) => const HomeScreen(),
            '/diagnosis_intro': (ctx) => const DiagnosisIntroScreen(),
            '/diagnosis_question': (ctx) => const DiagnosisQuestionScreen(),
            '/diagnosis_result': (ctx) => const DiagnosisResultScreen(),
            '/plan_selection': (ctx) => const PlanSelectionScreen(),
            '/payment_method': (ctx) => const PaymentMethodScreen(),
            // ConfirmationScreen は引数が必要なので routes では定義しにくい
            // '/payment_confirmation': (ctx) => ConfirmationScreen(),
            // '/payment_completion': (ctx) => CompletionScreen(),
            '/compatibility_input': (ctx) => const CompatibilityInputScreen(),
            '/compatibility_result': (ctx) => const CompatibilityResultScreen(),
            '/user_profile': (ctx) => const UserProfileScreen(),
            '/edit_profile': (ctx) => const EditProfileScreen(),
          },
        ),
      ),
    );
  }
}
