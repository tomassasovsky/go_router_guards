// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/screens/protected/base_protected_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseProtectedScreen(
      title: 'Profile',
      icon: Icons.person,
      color: Colors.blue,
      description: 'This route requires authentication.\nGuard: AuthGuard()',
    );
  }
}
