// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_example/app_router.dart';
import 'package:simple_example/cubit/auth_cubit.dart';

/// Login Screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Login to access protected routes',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AuthCubit>().login();
                const HomeRoute().go(context);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
