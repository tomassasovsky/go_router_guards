// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

/// Example demonstrating global fallback configuration.
///
/// Shows how to set a global fallback path that is used by default
/// when guards block navigation without specifying a fallback.

void main() {
  // Configure global fallback - this will be used by all guards
  // when they call block() without specifying a fallbackPath
  RouteGuardConfig.instance.fallbackPath = '/access-denied';

  runApp(GlobalFallbackApp());
}

class GlobalFallbackApp extends StatelessWidget {
  GlobalFallbackApp({super.key});

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Route that uses global fallback
          GoRoute(
            path: 'protected-global',
            redirect: RouteGuardUtils.createGuardRedirect(
              GlobalFallbackGuard(),
            ),
            builder: (context, state) =>
                const Text('Protected with Global Fallback'),
          ),

          // Route that overrides global fallback
          GoRoute(
            path: 'protected-custom',
            redirect: RouteGuardUtils.createGuardRedirect(
              CustomFallbackGuard(),
            ),
            builder: (context, state) =>
                const Text('Protected with Custom Fallback'),
          ),

          // Fallback pages
          GoRoute(
            path: 'access-denied',
            builder: (context, state) =>
                const AccessDeniedScreen(isGlobal: true),
          ),
          GoRoute(
            path: 'custom-error',
            builder: (context, state) =>
                const AccessDeniedScreen(isGlobal: false),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Global Fallback Demo',
    );
  }
}

/// Guard that uses the global fallback
class GlobalFallbackGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Always block without specifying fallback - uses global fallback
    resolver.block();
  }
}

/// Guard that uses redirect for custom behavior instead of global fallback
class CustomFallbackGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Use redirect for custom behavior instead of blocking
    resolver.redirect('/custom-error');
  }
}

// UI Screens

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Fallback Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Global fallback is set to: /access-denied',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/protected-global'),
              child: const Text('Protected Route (Global Fallback)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/protected-custom'),
              child: const Text('Protected Route (Custom Fallback)'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Both routes are protected and will redirect to their '
              'respective error pages.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({
    required this.isGlobal,
    super.key,
  });

  final bool isGlobal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${isGlobal ? 'Global' : 'Custom'} Fallback'),
        backgroundColor: isGlobal ? Colors.blue : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: isGlobal ? Colors.blue : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isGlobal
                  ? 'Redirected by: Global Fallback (/access-denied)'
                  : 'Redirected by: Custom Fallback (/custom-error)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
