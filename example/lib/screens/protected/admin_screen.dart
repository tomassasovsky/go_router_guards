// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/screens/protected/base_protected_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseProtectedScreen(
      title: 'Admin',
      icon: Icons.admin_panel_settings,
      color: Colors.red,
      description:
          'This route requires authentication and admin role.\nGuards: [AuthGuard(), RoleGuard([\'admin\'])].all()',
    );
  }
}
