// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:simple_example/screens/protected/base_protected_screen.dart';

class SecretInfoScreen extends StatelessWidget {
  const SecretInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseProtectedScreen(
      title: 'Secret Info',
      icon: Icons.lock,
      color: Colors.indigo,
      description:
          'This route uses conditional guards.\nOnly /info/secret requires authentication.\nGuard: ConditionalGuard.including()',
    );
  }
}
