import 'package:flutter/material.dart';
import 'package:your_app/widgets/auth_form.dart';

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
              onRegister: (email, password, age) {
                // TODO: Implement registration logic
                print('Registering with email: $email, password: $password, age: $age');
              },
              onLogin: (email, password) {
                // TODO: Implement login logic
                print('Logging in with email: $email, password: $password');
              },
              onAgeVerification: (age) {
                // TODO: Implement age verification logic
                print('Verifying age: $age');
              },
            ),
          ],
        ),
      ),
    );
  }
};