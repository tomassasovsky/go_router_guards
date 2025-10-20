// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/app_router.dart';

/// Base screen widget for protected routes
class BaseProtectedScreen extends StatelessWidget {
  const BaseProtectedScreen({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                description,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => const HomeRoute().go(context),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
