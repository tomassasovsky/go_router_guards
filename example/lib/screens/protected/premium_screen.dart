// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/screens/protected/base_protected_screen.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseProtectedScreen(
      title: 'Premium',
      icon: Icons.workspace_premium,
      color: Colors.purple,
      description:
          'This route requires authentication and premium OR vip role.\nGuards: [AuthGuard(), [RoleGuard([\'premium\']), RoleGuard([\'vip\'])].anyOf()].all()',
    );
  }
}
