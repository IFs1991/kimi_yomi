import 'package:flutter/material.dart';
import 'package:kimi_yomi/widgets/auth_form.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AuthForm(
              onSubmit: (email, password) {
                // TODO: Implement login/registration logic based on context or form state
                print('Submitting with email: $email, password: $password');
                // Maybe call different methods based on a state variable (isLogin vs isRegister)
              },
            ),
          ],
        ),
      ),
    );
  }
}