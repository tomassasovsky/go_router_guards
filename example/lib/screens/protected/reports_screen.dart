// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/screens/protected/base_protected_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseProtectedScreen(
      title: 'Reports',
      icon: Icons.bar_chart,
      color: Colors.green,
      description:
          'This route requires authentication and (admin role OR view_reports permission).\nGuards: [AuthGuard(), [RoleGuard([\'admin\']), PermissionGuard(\'view_reports\')].anyOf()].all()',
    );
  }
}
