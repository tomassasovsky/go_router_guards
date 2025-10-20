// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_example/app_router.dart';
import 'package:simple_example/cubit/auth_cubit.dart';
import 'package:simple_example/cubit/user_cubit.dart';
import 'package:simple_example/widgets/route_button.dart';

/// Home Screen - Public, no authentication required
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Router Guards - Simple Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final userState = context.watch<UserCubit>().state;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Authenticated: ${authState.isAuthenticated}'),
                        Text('Roles: ${userState.roles.join(", ")}'),
                        Text(
                          'Permissions: ${userState.permissions.isEmpty ? "None" : userState.permissions.join(", ")}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: authState.isAuthenticated
                      ? () => context.read<AuthCubit>().logout()
                      : () => const LoginRoute().go(context),
                  child: Text(
                    authState.isAuthenticated ? 'Logout' : 'Go to Login',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Role Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Admin'),
                      selected: userState.hasRole('admin'),
                      onSelected: (_) =>
                          context.read<UserCubit>().toggleRole('admin'),
                    ),
                    FilterChip(
                      label: const Text('Premium'),
                      selected: userState.hasRole('premium'),
                      onSelected: (_) =>
                          context.read<UserCubit>().toggleRole('premium'),
                    ),
                    FilterChip(
                      label: const Text('VIP'),
                      selected: userState.hasRole('vip'),
                      onSelected: (_) =>
                          context.read<UserCubit>().toggleRole('vip'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Permission Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('View Settings'),
                      selected: userState.hasPermission('view_settings'),
                      onSelected: (_) => context
                          .read<UserCubit>()
                          .togglePermission('view_settings'),
                    ),
                    FilterChip(
                      label: const Text('View Reports'),
                      selected: userState.hasPermission('view_reports'),
                      onSelected: (_) => context
                          .read<UserCubit>()
                          .togglePermission('view_reports'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Try navigating to these routes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const RouteButton(
                  label: 'Profile',
                  route: ProfileRoute(),
                  description: 'Requires: Authentication',
                  color: Colors.blue,
                ),
                const RouteButton(
                  label: 'Admin',
                  route: AdminRoute(),
                  description: 'Requires: Auth + Admin role',
                  color: Colors.red,
                ),
                const RouteButton(
                  label: 'Premium',
                  route: PremiumRoute(),
                  description: 'Requires: Auth + (Premium OR VIP role)',
                  color: Colors.purple,
                ),
                const RouteButton(
                  label: 'Settings',
                  route: SettingsRoute(),
                  description: 'Requires: Auth + view_settings permission',
                  color: Colors.orange,
                ),
                const RouteButton(
                  label: 'Reports',
                  route: ReportsRoute(),
                  description:
                      'Requires: Auth + (Admin role OR view_reports permission)',
                  color: Colors.green,
                ),
                const RouteButton(
                  label: 'Dashboard',
                  route: DashboardRoute(),
                  description: 'Requires: Authentication (Async guard)',
                  color: Colors.teal,
                ),
                const RouteButton(
                  label: 'Info',
                  route: InfoRoute(),
                  description: 'Public route',
                  color: Colors.grey,
                ),
                const RouteButton(
                  label: 'Secret Info',
                  route: SecretInfoRoute(),
                  description: 'Requires: Authentication (Conditional guard)',
                  color: Colors.indigo,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
