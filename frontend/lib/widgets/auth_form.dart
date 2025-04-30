import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Providerをインポート
import '../providers/auth_provider.dart'; // AuthProviderをインポート

class AuthForm extends StatefulWidget {
  // isLoginをonSubmitの引数に追加
  final void Function(String email, String password, bool isLogin) onSubmit;

  const AuthForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // 確認用パスワードコントローラーを追加
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // 確認用パスワードの表示状態
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // disposeに追加
    super.dispose();
  }

  void _submitForm() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    // FocusScope.of(context).unfocus(); // キーボードを閉じる (任意)
    _formKey.currentState!.save();
    widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _isLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    // AuthProviderのローディング状態を取得
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Columnが必要な高さだけ取るように
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty || !value.contains('@')) {
                return '有効なメールアドレスを入力してください。';
              }
              return null;
            },
            enabled: !isLoading, // ローディング中は無効化
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'パスワードを入力してください。';
              }
              if (value.length < 6) {
                return 'パスワードは6文字以上である必要があります。';
              }
              return null;
            },
            enabled: !isLoading, // ローディング中は無効化
          ),
          // 登録モードの場合のみ確認用パスワードフィールドを表示
          if (!_isLogin)
            const SizedBox(height: 12),
          if (!_isLogin)
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'パスワードが一致しません。';
                }
                return null;
              },
              enabled: !isLoading, // ローディング中は無効化
            ),
          const SizedBox(height: 20),
          // ローディング中はインジケーターを表示
          if (isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // ボタンの幅を広げる
              ),
              child: Text(_isLogin ? 'Login' : 'Register'),
            ),
          // ローディング中は切り替えボタンを無効化
          TextButton(
            onPressed: isLoading ? null : () {
              setState(() {
                _isLogin = !_isLogin;
                // モード切替時にフォームをリセット（任意）
                _formKey.currentState?.reset();
                _emailController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
              });
            },
            child: Text(_isLogin ? 'Create new account' : 'I already have an account'),
          )
        ],
      ),
    );
  }
}