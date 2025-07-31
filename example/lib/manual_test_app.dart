import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

import 'screens.dart';

part 'manual_test_app.g.dart';

/// Manual Testing App for Enhanced Guards
///
/// This app demonstrates all the enhanced guard features you can test manually.
/// Run this with: flutter run lib/manual_test_app.dart

// Enhanced Guards for testing
class EnhancedAuthGuard extends RouteGuardEnhanced {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final authState = context.read<AuthCubit>().state;

    if (authState.isAuthenticated) {
      resolver.next();
    } else {
      // Capture current path for redirect after login
      final currentPath = state.uri.toString();
      resolver.redirect('/login?redirect=${Uri.encodeComponent(currentPath)}');
    }
  }
}

class EnhancedRoleGuard extends RouteGuardEnhanced {
  const EnhancedRoleGuard(this.requiredRoles);

  final List<String> requiredRoles;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userState = context.read<UserCubit>().state;
    final hasRequiredRole = requiredRoles.any(userState.roles.contains);

    if (hasRequiredRole) {
      resolver.next();
    } else {
      resolver.block();
    }
  }
}

class BusinessHoursGuard extends RouteGuardEnhanced {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final now = DateTime.now();
    final isBusinessHours = now.hour >= 9 && now.hour <= 17;
    final userState = context.read<UserCubit>().state;

    if (isBusinessHours || userState.roles.contains('admin')) {
      resolver.next();
    } else {
      resolver.redirect('/after-hours?time=${now.hour}');
    }
  }
}

// Route classes for testing

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<LoginRoute>(path: '/login'),
    TypedGoRoute<FactoryGuardsRoute>(path: '/factory-guards'),
    TypedGoRoute<CustomLogicRoute>(path: '/custom-logic'),
    TypedGoRoute<ConditionalRoute>(path: '/conditional/:section'),
    TypedGoRoute<FlexibleAccessRoute>(path: '/flexible-access'),
    TypedGoRoute<AsyncGuardRoute>(path: '/async-guard'),
    TypedGoRoute<BlockingRoute>(path: '/blocking'),
    TypedGoRoute<LegacyGuardRoute>(path: '/legacy'),
  ],
)
class HomeRoute extends GoRouteData with _$HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ManualTestHomeScreen();
  }
}

class LoginRoute extends GoRouteData with _$LoginRoute {
  const LoginRoute({this.redirectTo});
  final String? redirectTo;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ManualTestLoginScreen(redirectTo: redirectTo);
  }
}

// Enhanced guard demo routes
class FactoryGuardsRoute extends GoRouteData
    with _$FactoryGuardsRoute, GuardedRoute {
  const FactoryGuardsRoute();

  @override
  RouteGuardEnhanced get guards => GuardsEnhanced.all([
    EnhancedAuthGuard(),
    EnhancedRoleGuard(['admin', 'moderator']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TestScreen(
      title: 'All Guards Demo',
      description:
          'This route uses GuardsEnhanced.all() requiring BOTH authentication AND admin/moderator role.',
    );
  }
}

class CustomLogicRoute extends GoRouteData
    with _$CustomLogicRoute, GuardedRoute {
  const CustomLogicRoute();

  @override
  RouteGuardEnhanced get guards =>
      GuardsEnhanced.all([EnhancedAuthGuard(), BusinessHoursGuard()]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TestScreen(
      title: 'Custom Logic Guard Demo',
      description:
          'This route uses custom business logic - only admins can access during even hours.',
    );
  }
}

class ConditionalRoute extends GoRouteData
    with _$ConditionalRoute, GuardedRoute {
  const ConditionalRoute({required this.section});
  final String section;

  @override
  RouteGuardEnhanced get guards => section == 'admin'
      ? GuardsEnhanced.all([
          EnhancedAuthGuard(),
          EnhancedRoleGuard(['admin']),
        ])
      : EnhancedAuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TestScreen(
      title: 'Conditional Guard Demo - $section',
      description: section == 'admin'
          ? 'Admin section requires authentication + admin role'
          : 'Regular section only requires authentication',
    );
  }
}

class HolidayGuard extends RouteGuardEnhanced {
  const HolidayGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final now = DateTime.now();
    if (now.month == 12) {
      resolver.next();
    } else {
      resolver.block();
    }
  }
}

class FlexibleAccessRoute extends GoRouteData
    with _$FlexibleAccessRoute, GuardedRoute {
  const FlexibleAccessRoute();

  @override
  RouteGuardEnhanced get guards => GuardsEnhanced.anyOf([
    EnhancedRoleGuard(['admin']),
    EnhancedRoleGuard(['premium']),
    HolidayGuard(),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TestScreen(
      title: 'AnyOf Demo',
      description:
          'Access granted if: admin OR premium OR December. Uses GuardsEnhanced.anyOf().',
    );
  }
}

class SubscriptionGuard extends RouteGuardEnhanced {
  const SubscriptionGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      // Simulate async validation
      await Future.delayed(const Duration(milliseconds: 800));

      if (!context.mounted) return;

      // Simulate external service check
      final hasValidSubscription = await _simulateSubscriptionCheck();
      if (hasValidSubscription) {
        resolver.next();
      } else {
        resolver.redirect('/subscription-required');
      }
    } catch (e) {
      resolver.redirect('/error?message=Service unavailable');
    }
  }

  static Future<bool> _simulateSubscriptionCheck() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Randomly succeed/fail for testing
    return DateTime.now().millisecond % 2 == 0;
  }
}

class AsyncGuardRoute extends GoRouteData with _$AsyncGuardRoute, GuardedRoute {
  const AsyncGuardRoute();

  @override
  RouteGuardEnhanced get guards =>
      GuardsEnhanced.all([EnhancedAuthGuard(), SubscriptionGuard()]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TestScreen(
      title: 'Async Guard Demo',
      description:
          'This route performs async validation with external service simulation.',
    );
  }
}

class MaintenanceGuard extends RouteGuardEnhanced {
  const MaintenanceGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Block access during "maintenance mode" (odd minutes)
    final minute = DateTime.now().minute;
    if (minute % 2 == 1) {
      resolver.block(); // Blocks by redirecting to current location
    } else {
      resolver.next();
    }
  }
}

class BlockingRoute extends GoRouteData with _$BlockingRoute, GuardedRoute {
  const BlockingRoute();

  @override
  RouteGuardEnhanced get guards => MaintenanceGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TestScreen(
      title: 'Blocking Guard Demo',
      description:
          'This route blocks access during odd minutes using resolver.block().',
    );
  }
}

// Legacy compatibility route
class LegacyGuardRoute extends GoRouteData
    with _$LegacyGuardRoute, GuardedRoute {
  const LegacyGuardRoute();

  @override
  RouteGuard get guards => Guards.all([
    AuthenticationGuard(),
    EnhancedRoleGuard(['user']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TestScreen(
      title: 'Legacy Guards Demo',
      description:
          'This route uses the original Guards.all() with legacy guard classes.',
    );
  }
}

// Support screens
class TestScreen extends StatelessWidget {
  const TestScreen({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Access Granted!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            _buildStatusInfo(context),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userState = context.watch<UserCubit>().state;
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('🔐 Authenticated: ${authState.isAuthenticated}'),
            Text('👤 Roles: ${userState.roles.join(', ')}'),
            Text(
              '🕐 Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            ),
            Text('📅 Month: ${now.month}'),
          ],
        ),
      ),
    );
  }
}

class ManualTestHomeScreen extends StatelessWidget {
  const ManualTestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Guards Manual Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            _buildControlsCard(context),
            const SizedBox(height: 16),
            _buildTestRoutesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userState = context.watch<UserCubit>().state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('🔐 Authenticated: ${authState.isAuthenticated}'),
            Text('👤 Roles: ${userState.roles.join(', ')}'),
            Text(
              '🕐 Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => context.read<AuthCubit>().toggleAuth(),
                  child: const Text('Toggle Auth'),
                ),
                ElevatedButton(
                  onPressed: () => context.read<UserCubit>().toggleAdmin(),
                  child: const Text('Toggle Admin'),
                ),
                ElevatedButton(
                  onPressed: () => context.read<UserCubit>().togglePremium(),
                  child: const Text('Toggle Premium'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRoutesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Routes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildTestButton(
              context,
              'All Guards',
              '/factory-guards',
              'Tests GuardsEnhanced.all() with authentication + role check',
            ),
            _buildTestButton(
              context,
              'Custom Logic',
              '/custom-logic',
              'Custom business logic - admin-only during even hours',
            ),
            _buildTestButton(
              context,
              'Conditional Guards',
              '/conditional/admin',
              'Different guards based on path section',
            ),
            _buildTestButton(
              context,
              'AnyOf Demo',
              '/flexible-access',
              'Tests GuardsEnhanced.anyOf() - admin OR premium OR December',
            ),
            _buildTestButton(
              context,
              'Async Guards',
              '/async-guard',
              'Async validation with external service simulation',
            ),
            _buildTestButton(
              context,
              'Blocking Guard',
              '/blocking',
              'Blocks access during odd minutes',
            ),
            _buildTestButton(
              context,
              'Legacy Guards',
              '/legacy',
              'Tests backward compatibility with old guard system',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String title,
    String route,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go(route),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class ManualTestLoginScreen extends StatelessWidget {
  const ManualTestLoginScreen({super.key, this.redirectTo});
  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen'),
            if (redirectTo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Will redirect to: $redirectTo',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AuthCubit>().login();
                if (redirectTo != null) {
                  context.go(redirectTo!);
                } else {
                  context.go('/');
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

final manualTestRouter = GoRouter(routes: $appRoutes);

// Router configuration
// final manualTestRouter = GoRouter(
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => const HomeRoute().build(context, state),
//     ),
//     GoRoute(
//       path: '/login',
//       builder: (context, state) {
//         final redirect = state.uri.queryParameters['redirect'];
//         return LoginRoute(redirectTo: redirect).build(context, state);
//       },
//     ),
//     GoRoute(
//       path: '/factory-guards',
//       builder: (context, state) =>
//           const FactoryGuardsRoute().build(context, state),
//       redirect: (context, state) =>
//           const FactoryGuardsRoute().executeGuards(context, state),
//     ),
//     GoRoute(
//       path: '/custom-logic',
//       builder: (context, state) =>
//           const CustomLogicRoute().build(context, state),
//       redirect: (context, state) =>
//           const CustomLogicRoute().executeGuards(context, state),
//     ),
//     GoRoute(
//       path: '/conditional/:section',
//       builder: (context, state) {
//         final section = state.pathParameters['section']!;
//         return ConditionalRoute(section: section).build(context, state);
//       },
//       redirect: (context, state) {
//         final section = state.pathParameters['section']!;
//         return ConditionalRoute(section: section).executeGuards(context, state);
//       },
//     ),
//     GoRoute(
//       path: '/flexible-access',
//       builder: (context, state) =>
//           const FlexibleAccessRoute().build(context, state),
//       redirect: (context, state) =>
//           const FlexibleAccessRoute().executeGuards(context, state),
//     ),
//     GoRoute(
//       path: '/async-guard',
//       builder: (context, state) =>
//           const AsyncGuardRoute().build(context, state),
//       redirect: (context, state) =>
//           const AsyncGuardRoute().executeGuards(context, state),
//     ),
//     GoRoute(
//       path: '/blocking',
//       builder: (context, state) => const BlockingRoute().build(context, state),
//       redirect: (context, state) =>
//           const BlockingRoute().executeGuards(context, state),
//     ),
//     GoRoute(
//       path: '/legacy',
//       builder: (context, state) =>
//           const LegacyGuardRoute().build(context, state),
//       redirect: (context, state) =>
//           const LegacyGuardRoute().executeGuards(context, state),
//     ),
//     // Support routes
//     GoRoute(
//       path: '/unauthorized',
//       builder: (context, state) => const TestScreen(
//         title: 'Unauthorized',
//         description:
//             'You do not have the required permissions to access the requested page.',
//       ),
//     ),
//     GoRoute(
//       path: '/maintenance',
//       builder: (context, state) {
//         final hour = state.uri.queryParameters['hour'] ?? 'unknown';
//         return TestScreen(
//           title: 'Maintenance Mode',
//           description:
//               'The system is in maintenance mode (hour: $hour). Only admins can access.',
//         );
//       },
//     ),
//     GoRoute(
//       path: '/subscription-required',
//       builder: (context, state) => const TestScreen(
//         title: 'Subscription Required',
//         description: 'This feature requires a valid subscription.',
//       ),
//     ),
//     GoRoute(
//       path: '/upgrade',
//       builder: (context, state) => const TestScreen(
//         title: 'Upgrade Required',
//         description: 'Please upgrade to premium to access this feature.',
//       ),
//     ),
//     GoRoute(
//       path: '/access-denied',
//       builder: (context, state) => const TestScreen(
//         title: 'Access Denied',
//         description: 'Access denied. None of the access conditions were met.',
//       ),
//     ),
//     GoRoute(
//       path: '/after-hours',
//       builder: (context, state) {
//         final time = state.uri.queryParameters['time'] ?? 'unknown';
//         return TestScreen(
//           title: 'After Hours',
//           description:
//               'Access is only allowed during business hours (9-17). Current hour: $time',
//         );
//       },
//     ),
//     GoRoute(
//       path: '/error',
//       builder: (context, state) {
//         final message = state.uri.queryParameters['message'] ?? 'Unknown error';
//         return TestScreen(
//           title: 'Error',
//           description: 'An error occurred: $message',
//         );
//       },
//     ),
//   ],
// );

// Legacy guards for compatibility testing
class AuthenticationGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
    if (!isAuthenticated) {
      return LoginRoute().location;
    }
    return null;
  }
}

// class EnhancedRoleGuard extends RouteGuardEnhanced {
//   const EnhancedRoleGuard(this.requiredRoles);

//   final List<String> requiredRoles;

//   @override
//   FutureOr<void> onNavigation(
//     NavigationResolver resolver,
//     BuildContext context,
//     GoRouterState state,
//   ) async {
//     final userRoles = context.read<UserCubit>().state.roles;
//     final hasRequiredRole = requiredRoles.any(userRoles.contains);
//     if (!hasRequiredRole) {
//       resolver.block();
//     } else {
//       resolver.next();
//     }
//   }
// }

// class EnhancedRoleGuard extends RouteGuardEnhanced {
//   const EnhancedRoleGuard(this.requiredRoles);
//   final List<String> requiredRoles;
//   FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
//     final userRoles = context.read<UserCubit>().state.roles;
//     final hasRequiredRole = requiredRoles.any(userRoles.contains);
//     if (!hasRequiredRole) {
//       return ;
//     }
//     return null;
//   }
// }
