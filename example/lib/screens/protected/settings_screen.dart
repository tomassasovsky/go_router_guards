// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/screens/protected/base_protected_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseProtectedScreen(
      title: 'Settings',
      icon: Icons.settings,
      color: Colors.orange,
      description:
          'This route requires authentication and view_settings permission.\nGuards: [AuthGuard(), PermissionGuard(\'view_settings\')].all()',
    );
  }
}
