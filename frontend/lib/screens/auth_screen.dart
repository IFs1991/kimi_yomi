import 'package:flutter/material.dart';
import 'package:kimi_yomi/providers/auth_provider.dart';
import 'package:kimi_yomi/widgets/auth_form.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget { // StatelessWidget から StatefulWidget に変更
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> { // Stateクラスを追加
  // ローディング状態を管理するローカル変数 (AuthProviderと連動)
  // bool _isLoading = false; // AuthProvider.isLoading を直接参照するため不要に

  Future<void> _submitAuthForm(String email, String password, bool isLogin) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // setState(() {
    //   _isLoading = true;
    // });
    try {
      if (isLogin) {
        await authProvider.login(email, password);
        // ログイン成功時のナビゲーション (例)
        // Navigator.of(context).pushReplacementNamed('/home');
      } else {
        await authProvider.register(email, password);
        // 登録成功時のナビゲーションまたはメッセージ (例)
        // Navigator.of(context).pushReplacementNamed('/home');
        // または
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Registration successful! Please log in.')),
        // );
      }
      // 成功した場合、AuthProviderのnotifyListeners()により自動的に画面遷移等がトリガーされる想定
      // (例: main.dart で Consumer<AuthProvider> を使って画面を切り替える)
    } catch (error) {
      // エラーダイアログを表示
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('エラーが発生しました'),
          content: Text(error.toString()), // より具体的なエラーメッセージを表示
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            )
          ],
        ),
      );
    } finally {
      // AuthProvider側でisLoadingが更新されるため、ここでのsetStateは不要
      // setState(() {
      //   _isLoading = false;
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthProviderのローディング状態を監視
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('キミヨミ - 認証'), // タイトル変更
      ),
      body: Stack( // ローディング表示のためにStackを使用
        children: [
          Center(
            child: SingleChildScrollView( // キーボード表示時にコンテンツが隠れないように
              child: Padding(
                padding: const EdgeInsets.all(24.0), // パディング調整
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ロゴやアプリ名の表示 (任意)
                    // Image.asset('assets/logo.png', height: 80),
                    // const SizedBox(height: 20),
                    Text(
                      'ようこそ！', // 文言変更
                      style: Theme.of(context).textTheme.headlineMedium, // スタイル調整
                    ),
                    const SizedBox(height: 30),
                    AuthForm(
                      // isLogin を渡すように修正
                      onSubmit: (email, password, isLogin) {
                        _submitAuthForm(email, password, isLogin);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ローディングインジケーターを画面中央に表示
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // 背景を少し暗くする
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}