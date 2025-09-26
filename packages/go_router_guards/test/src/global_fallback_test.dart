// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

void main() {
  group('Global Fallback', () {
    setUp(() {
      // Reset global fallback before each test
      RouteGuardConfig.instance.reset();
    });

    tearDown(() {
      // Clean up after each test
      RouteGuardConfig.instance.reset();
    });

    group('GlobalFallback Configuration', () {
      test('defaults to root path', () {
        expect(RouteGuardConfig.instance.fallbackPath, '/');
      });

      test('can set and get fallback path', () {
        RouteGuardConfig.instance.fallbackPath = '/error';
        expect(RouteGuardConfig.instance.fallbackPath, '/error');
      });

      test('can reset to default', () {
        RouteGuardConfig.instance.fallbackPath = '/custom';
        expect(RouteGuardConfig.instance.fallbackPath, '/custom');

        RouteGuardConfig.instance.reset();
        expect(RouteGuardConfig.instance.fallbackPath, '/');
      });

      test('is singleton', () {
        final instance1 = RouteGuardConfig.instance;
        final instance2 = RouteGuardConfig.instance;
        expect(identical(instance1, instance2), true);

        instance1.fallbackPath = '/test';
        expect(instance2.fallbackPath, '/test');
      });
    });

    group('Navigation Resolver with Global Fallback', () {
      testWidgets('uses global fallback when no specific fallback provided',
          (tester) async {
        // Set global fallback
        RouteGuardConfig.instance.fallbackPath = '/global-error';

        late GoRouter router;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Home'),
            ),
            GoRoute(
              path: '/protected',
              redirect: RouteGuardUtils.createGuardRedirect(
                _GlobalFallbackGuard(),
              ),
              builder: (context, state) => const Text('Protected'),
            ),
            GoRoute(
              path: '/global-error',
              builder: (context, state) => const Text('Global Error'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        // Navigate to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to global error page
        expect(find.text('Global Error'), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/global-error');
      });

      testWidgets(
          'redirect can be used instead of blocking for custom behavior',
          (tester) async {
        // Set global fallback
        RouteGuardConfig.instance.fallbackPath = '/global-error';

        late GoRouter router;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Home'),
            ),
            GoRoute(
              path: '/protected',
              redirect: RouteGuardUtils.createGuardRedirect(
                _CustomFallbackGuard(),
              ),
              builder: (context, state) => const Text('Protected'),
            ),
            GoRoute(
              path: '/global-error',
              builder: (context, state) => const Text('Global Error'),
            ),
            GoRoute(
              path: '/custom-error',
              builder: (context, state) => const Text('Custom Error'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        // Navigate to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to custom error page via redirect()
        expect(find.text('Custom Error'), findsOneWidget);
        expect(find.text('Global Error'), findsNothing);
        expect(router.routeInformationProvider.value.uri.path, '/custom-error');
      });

      testWidgets('different global fallback paths work correctly',
          (tester) async {
        // Set custom global fallback
        RouteGuardConfig.instance.fallbackPath = '/access-denied';

        late GoRouter router;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Home'),
            ),
            GoRoute(
              path: '/protected',
              redirect: RouteGuardUtils.createGuardRedirect(
                _GlobalFallbackGuard(),
              ),
              builder: (context, state) => const Text('Protected'),
            ),
            GoRoute(
              path: '/access-denied',
              builder: (context, state) => const Text('Access Denied'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        // Navigate to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to access denied page
        expect(find.text('Access Denied'), findsOneWidget);
        expect(
          router.routeInformationProvider.value.uri.path,
          '/access-denied',
        );
      });
    });

    group('GoRouterNavigationResolver with Global Fallback', () {
      testWidgets('GoRouter block() uses global fallback for direct navigation',
          (tester) async {
        // Set global fallback
        RouteGuardConfig.instance.fallbackPath = '/blocked';

        late GoRouterNavigationResolver resolver;
        late GoRouter router;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Home'),
            ),
            GoRoute(
              path: '/protected',
              redirect: (context, state) {
                resolver = GoRouterNavigationResolver(context, state)
                  ..block(); // No fallback specified - should use global
                return resolver.future.then((result) => result.redirectPath);
              },
              builder: (context, state) => const Text('Protected'),
            ),
            GoRoute(
              path: '/blocked',
              builder: (context, state) => const Text('Blocked'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router),
        );

        // Direct navigation to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to global fallback
        expect(find.text('Blocked'), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/blocked');
      });
    });
  });
}

// Test Guards
class _GlobalFallbackGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Block without specifying fallback - uses global fallback
    resolver.block();
  }
}

class _CustomFallbackGuard extends GoRouterGuard {
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
