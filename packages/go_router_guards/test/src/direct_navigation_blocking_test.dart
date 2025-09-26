// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

void main() {
  group('Direct Navigation Blocking', () {
    late GoRouter router;

    setUp(() {});

    group('GoRouterNavigationResolver.block()', () {
      testWidgets(
          'block() with fallbackPath redirects to fallback '
          'when no previous route', (tester) async {
        late GoRouterNavigationResolver resolver;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/protected',
              redirect: (context, state) {
                // Set up global fallback for this test
                RouteGuardConfig.instance.fallbackPath = '/unauthorized';
                resolver = GoRouterNavigationResolver(context, state)..block();
                return resolver.future.then((result) => result.redirectPath);
              },
              builder: (context, state) => const ProtectedScreen(),
            ),
            GoRoute(
              path: '/unauthorized',
              builder: (context, state) => const UnauthorizedScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        // Navigate directly to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to unauthorized page
        expect(find.byType(UnauthorizedScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/unauthorized');
      });

      testWidgets(
          'block() without fallbackPath defaults to root when no '
          'previous route', (tester) async {
        late GoRouterNavigationResolver resolver;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/protected',
              redirect: (context, state) {
                // Reset global fallback to default
                RouteGuardConfig.instance.reset();
                resolver = GoRouterNavigationResolver(context, state)
                  ..block(); // Uses default global fallback '/'
                return resolver.future.then((result) => result.redirectPath);
              },
              builder: (context, state) => const ProtectedScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        // Navigate directly to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to root
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/');
      });

      testWidgets('block() uses global fallback correctly', (tester) async {
        late GoRouterNavigationResolver resolver;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/protected',
              redirect: (context, state) {
                resolver = GoRouterNavigationResolver(context, state);
                RouteGuardConfig.instance.fallbackPath = '/error';
                resolver.block();
                return resolver.future.then((result) => result.redirectPath);
              },
              builder: (context, state) => const ProtectedScreen(),
            ),
            GoRoute(
              path: '/error',
              builder: (context, state) => const ErrorScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        // Navigate directly to protected route
        router.go('/protected');
        await tester.pumpAndSettle();

        // Should be redirected to error page
        expect(find.byType(ErrorScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/error');
      });
    });

    group('Smart Role Guard', () {
      testWidgets(
          'redirects to fallback on direct navigation when unauthorized',
          (tester) async {
        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/admin',
              redirect: RouteGuardUtils.createGuardRedirect(
                const _SmartRoleGuard(
                  ['admin'],
                  fallbackRoute: '/unauthorized',
                ),
              ),
              builder: (context, state) => const AdminScreen(),
            ),
            GoRoute(
              path: '/unauthorized',
              builder: (context, state) => const UnauthorizedScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        // Direct navigation to admin route
        router.go('/admin');
        await tester.pumpAndSettle();

        // Should be redirected to unauthorized page
        expect(find.byType(UnauthorizedScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/unauthorized');
      });

      testWidgets('uses global fallback when no explicit redirect',
          (tester) async {
        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/admin',
              redirect: RouteGuardUtils.createGuardRedirect(
                const _SmartRoleGuard(['admin']), // No fallback route
              ),
              builder: (context, state) => const AdminScreen(),
            ),
            GoRoute(
              path: '/unauthorized',
              builder: (context, state) => const UnauthorizedScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        // Direct navigation to admin route
        router.go('/admin');
        await tester.pumpAndSettle();

        // Should be redirected to unauthorized page (global fallback)
        expect(find.byType(UnauthorizedScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/unauthorized');
      });
    });

    group('Navigation Context Detection', () {
      testWidgets('detects direct navigation vs in-app navigation',
          (tester) async {
        final contextDetector = _NavigationContextDetector();

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => HomeScreenWithNavigation(
                onNavigateToProtected: () => router.go('/protected'),
              ),
            ),
            GoRoute(
              path: '/protected',
              redirect: RouteGuardUtils.createGuardRedirect(contextDetector),
              builder: (context, state) => const ProtectedScreen(),
            ),
            GoRoute(
              path: '/blocked',
              builder: (context, state) => const Text('Navigation Blocked'),
            ),
            GoRoute(
              path: '/redirected',
              builder: (context, state) =>
                  const Text('Direct Navigation Detected'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
          ),
        );

        // Test 1: Direct navigation
        router.go('/protected');
        await tester.pumpAndSettle();
        expect(find.text('Direct Navigation Detected'), findsOneWidget);

        // Test 2: In-app navigation
        router.go('/');
        await tester.pumpAndSettle();

        // Reset the state for the next test
        contextDetector.reset();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(find.text('Navigation Blocked'), findsOneWidget);
      });
    });
  });
}

// Test Guards
class _SmartRoleGuard extends GoRouterGuard {
  const _SmartRoleGuard(this.requiredRoles, {this.fallbackRoute});

  final List<String> requiredRoles;
  final String? fallbackRoute;

  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Simulate user without required role
    const userRoles = <String>['user'];
    final hasRequiredRole = requiredRoles.any(userRoles.contains);

    if (!hasRequiredRole) {
      if (fallbackRoute != null) {
        resolver.redirect(fallbackRoute!);
      } else {
        RouteGuardConfig.instance.fallbackPath = '/unauthorized';
        resolver.block();
      }
    } else {
      resolver.next();
    }
  }
}

class _NavigationContextDetector extends GoRouterGuard {
  bool _hasBeenReset = false;

  void reset() {
    _hasBeenReset = true;
  }

  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final router = GoRouter.of(context);

    // For testing: after reset, treat as in-app navigation
    if (_hasBeenReset || router.canPop()) {
      // In-app navigation - block
      resolver.redirect('/blocked');
    } else {
      // Direct navigation - redirect with explanation
      resolver.redirect('/redirected');
    }
  }
}

// Test Screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home')),
    );
  }
}

class HomeScreenWithNavigation extends StatelessWidget {
  const HomeScreenWithNavigation({
    required this.onNavigateToProtected,
    super.key,
  });

  final VoidCallback onNavigateToProtected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onNavigateToProtected,
          child: const Text('Navigate to Protected'),
        ),
      ),
    );
  }
}

class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Protected')),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Admin')),
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Unauthorized')),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Error')),
    );
  }
}
