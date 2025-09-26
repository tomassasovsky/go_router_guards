# Go Router Guards

A flexible and extensible guard system for Go Router that enables type-safe route protection with complex boolean logic support.

## 📦 Packages

This repository contains two packages following the `bloc` + `flutter_bloc` pattern:

| Package | Description | Version |
|---------|-------------|---------|
| [`route_guards`](packages/route_guards) | Framework-agnostic core guard system | 1.0.0 |
| [`go_router_guards`](packages/go_router_guards) | Go Router specific integration | 1.0.0+2 |

### 🔧 Core Package: `route_guards`

The base package that provides framework-agnostic guard functionality:
- Core guard abstractions and interfaces
- Guard composition utilities (`Guards.all()`, `Guards.anyOf()`, `Guards.oneOf()`)
- Navigation resolver pattern
- No dependencies on Flutter or Go Router

### 🎯 Integration Package: `go_router_guards`

Go Router specific implementation and utilities:
- Type-safe route mixins (`GuardedRoute`, `UnguardedRoute`)
- Go Router integration utilities (`RouteGuardUtils`, `ConditionalGuard`)
- Enhanced Go Router specific functionality
- Re-exports all core functionality for seamless usage

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

[ci_badge]: https://github.com/tomassasovsky/go_router_guards/workflows/ci/badge.svg
[ci_link]: https://github.com/tomassasovsky/go_router_guards/actions/workflows/main.yaml
[coverage_badge]: https://codecov.io/gh/tomassasovsky/go_router_guards/master/graph/badge.svg
[pub_badge]: https://img.shields.io/pub/v/go_router_guards.svg
[pub_link]: https://pub.dev/packages/go_router_guards
[license_badge]: https://img.shields.io/badge/License-MIT-yellow.svg
[license_link]: LICENSE

[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

## Quick Start

### Installation

For most users, you'll want the complete Go Router integration:

```yaml
dependencies:
  go_router_guards: ^1.0.0+2
```

If you only need the core guard system (framework-agnostic):

```yaml
dependencies:
  route_guards: ^1.0.0
```

### Type-Safe Routes with Guard Expressions

Following [VGV's routing best practices](https://engineering.verygood.ventures/navigation/navigation/), use type-safe routes with guard expressions:

```dart
import 'package:go_router_guards/go_router_guards.dart';

// Define type-safe routes
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with GuardedRoute {
  const ProtectedRoute();

  @override
  GuardExpression get guards => Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

// Create type-safe guards
class AuthenticationGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      return LoginRoute().location; // Type-safe navigation
    }
    return null;
  }
}

// Navigate using type-safe routes
ElevatedButton(
  onPressed: () => ProtectedRoute().go(context),
  child: const Text('Go to Protected Route'),
)
```

## Core Features

### RouteGuard Interface

Implement guards to protect your routes:

```dart
mixin RouteGuard {
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}
```

- Return `null` to allow access
- Return a route location (e.g., `LoginRoute().location`) to redirect

### Direct Navigation Handling

Guards automatically handle direct navigation scenarios (when users type URLs directly):

```dart
class RoleGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!hasRequiredRole) {
      // Block using global fallback
      resolver.block();
      // OR redirect directly to a specific route
      resolver.redirect('/unauthorized');
    } else {
      resolver.next();
    }
  }
}
```

### Global Fallback Configuration

Configure a global fallback path that all guards use when blocking without specifying a fallback:

```dart
void main() {
  // Set global fallback - used when guards call block() without fallbackPath
  GlobalFallback.instance.setFallbackPath('/access-denied');
  
  runApp(MyApp());
}

class MyGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(resolver, context, state) async {
    if (!hasAccess) {
      resolver.block(); // Uses global fallback '/access-denied'
    }
  }
}
```

If you need custom fallback behavior, use redirect instead:

```dart
class CustomGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(resolver, context, state) async {
    if (!hasAccess) {
      resolver.redirect('/custom-error'); // Custom redirect
    }
  }
}
```

### Guard Expressions with Logical Operators

Create complex guard logic using boolean expressions:

```dart
// Simple AND: both must pass
Guards.all([
  AuthenticationGuard(),
  RoleGuard(['admin']),
])

// Simple OR: either can pass
Guards.anyOf([
  AuthenticationGuard(),
  AdminGuard(),
])

// Complex expression: (a & b) || c
Guards.anyOf([
  Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin']),
  ]),
  SuperAdminGuard(),
])

// Multiple guards with ALL: all must pass
Guards.all([
  AuthenticationGuard(),
  RoleGuard(['admin']),
  SubscriptionGuard(),
  PaymentGuard(),
])

// Multiple guards with ANY OF: any can pass
Guards.anyOf([
  AuthenticationGuard(),
  AdminGuard(),
  SuperAdminGuard(),
])

// Multiple guards with ONE OF: exactly one must pass
Guards.oneOf([
  AuthenticationGuard(),
  AdminGuard(),
  SuperAdminGuard(),
], '/unauthorized')

// ONE OF: exactly one must pass
Guards.oneOf([
  AuthenticationGuard(),
  AdminGuard(),
], '/unauthorized')
```

### GuardedRoute Mixin

Add guard functionality to your route classes:

```dart
class AdminRoute extends GoRouteData with GuardedRoute {
  const AdminRoute();

  @override
  GuardExpression get guards => Guards.anyOf([
    Guards.all([
      AuthenticationGuard(),
      RoleGuard(['admin']),
    ]),
    SuperAdminGuard(),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
```

### Complex Guard Logic

```dart
// Route accessible by:
// - Authenticated users with admin role AND premium subscription
// - OR super admins
// - OR users with special access token
class PremiumAdminRoute extends GoRouteData with GuardedRoute {
  const PremiumAdminRoute();

  @override
  GuardExpression get guards => Guards.anyOf([
    Guards.all([
      AuthenticationGuard(),
      RoleGuard(['admin']),
      SubscriptionGuard(),
    ]),
    Guards.anyOf([
      SuperAdminGuard(),
      SpecialAccessGuard(),
    ]),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumAdminScreen();
  }
}
```

### Conditional Guards

```dart
class ConditionalGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final appState = context.read<AppCubit>().state;
    
    if (appState.isMaintenanceMode) {
      return MaintenanceRoute().location;
    }
    
    if (appState.isOffline) {
      return OfflineRoute().location;
    }
    
    return null;
  }
}
```

### Testing Guards

```dart
test('complex guard expression', () async {
  final expression = Guards.anyOf([
    Guards.all([
      AuthenticationGuard(),
      RoleGuard(['admin']),
    ]),
    SuperAdminGuard(),
  ]);

  // Test with authenticated admin
  when(mockAuthCubit.state).thenReturn(AuthenticatedState());
  when(mockUserCubit.state).thenReturn(UserState(roles: ['admin']));
  
  final result = await expression.execute(mockContext, mockState);
  expect(result, isNull); // Access granted
});
```

## Best Practices

### 1. Use Type-Safe Navigation

Always use type-safe routes for navigation:

```dart
// ✅ Good - Type-safe
context.go(ProtectedRoute().location);
ProtectedRoute().go(context);

// ❌ Bad - Hardcoded paths
context.go('/protected');
```

### 2. Order Guards by Performance

Order guards from fastest to slowest in ALL expressions:

```dart
Guards.all([
  AppInitializationGuard(), // Fast check
  AuthenticationGuard(),    // Medium check
  AsyncGuard(),             // Slow async check
])
```

### 3. Create Reusable Guard Expressions

Extract common guard logic:

```dart
class PremiumFeatureGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final userState = context.read<UserCubit>().state;
    if (!userState.hasPremiumAccess) {
      return UpgradeRoute().location;
    }
    return null;
  }
}

// Reusable expression
final premiumGuard = PremiumFeatureGuard();
final adminGuard = RoleGuard(['admin']);

// Use in multiple routes
final adminPremiumGuard = Guards.all([adminGuard, premiumGuard]);
```

### 4. Handle Guard Failures Gracefully

```dart
class RobustGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    try {
      final userState = context.read<UserCubit>().state;
      if (!userState.isAuthenticated) {
        return LoginRoute().location;
      }
      return null;
    } catch (e) {
      return ErrorRoute().location;
    }
  }
}
```

## Testing

### Unit Testing Guard Expressions
```dart
test('AND expression with both guards passing', () async {
  final expression = Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin']),
  ]);
  
  when(mockAuthCubit.state).thenReturn(AuthenticatedState());
  when(mockUserCubit.state).thenReturn(UserState(roles: ['admin']));
  
  final result = await expression.execute(mockContext, mockState);
  expect(result, isNull);
});
```

### Integration Testing
```dart
testWidgets('complex guard expression redirects correctly', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.tap(find.text('Premium Admin Route'));
  await tester.pumpAndSettle();
  
  // Should redirect to login if not authenticated
  expect(find.text('Login'), findsOneWidget);
});
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
