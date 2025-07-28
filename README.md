# go_router_guards

A flexible and extensible guard system for Go Router that enables type-safe route protection with complex boolean logic support.

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
[license_link]: https://opensource.org/licenses/MIT

[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis


## Quick Start

### Installation

Add `go_router_guards` to your `pubspec.yaml`:

```yaml
dependencies:
  go_router_guards: ^1.0.0+1
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
  GuardExpression get guards => Guards.and(
    Guards.guard(AuthenticationGuard()),
    Guards.guard(RoleGuard(['admin'])),
  );

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

### Guard Expressions with Logical Operators

Create complex guard logic using boolean expressions:

```dart
// Simple AND: both must pass
Guards.and(
  Guards.guard(AuthenticationGuard()),
  Guards.guard(RoleGuard(['admin'])),
)

// Simple OR: either can pass
Guards.or(
  Guards.guard(AuthenticationGuard()),
  Guards.guard(AdminGuard()),
)

// Complex expression: (a & b) || c
Guards.or(
  Guards.and(
    Guards.guard(AuthenticationGuard()),
    Guards.guard(RoleGuard(['admin'])),
  ),
  Guards.guard(SuperAdminGuard()),
)

// Multiple guards with AND ALL: all must pass
Guards.andAll([
  Guards.guard(AuthenticationGuard()),
  Guards.guard(RoleGuard(['admin'])),
  Guards.guard(SubscriptionGuard()),
  Guards.guard(PaymentGuard()),
])

// Multiple guards with OR ALL: any can pass
Guards.orAll([
  Guards.guard(AuthenticationGuard()),
  Guards.guard(AdminGuard()),
  Guards.guard(SuperAdminGuard()),
])

// Multiple guards with XOR ALL: exactly one must pass
Guards.xorAll([
  Guards.guard(AuthenticationGuard()),
  Guards.guard(AdminGuard()),
  Guards.guard(SuperAdminGuard()),
], '/unauthorized')

// XOR: exactly one must pass
Guards.xor(
  Guards.guard(AuthenticationGuard()),
  Guards.guard(AdminGuard()),
)

// NOT: invert the result
Guards.not(Guards.guard(AuthenticationGuard()))
```

### GuardedRoute Mixin

Add guard functionality to your route classes:

```dart
class AdminRoute extends GoRouteData with GuardedRoute {
  const AdminRoute();

  @override
  GuardExpression get guards => Guards.or(
    Guards.and(
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ),
    Guards.guard(SuperAdminGuard()),
  );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
```

## Advanced Usage

### Working with Multiple Guards

When you need more than two guards for a route, you have several options:

#### 1. **Multi-Expression Operators (Recommended)**
```dart
// All guards must pass
Guards.andAll([
  Guards.guard(AuthenticationGuard()),
  Guards.guard(RoleGuard(['admin'])),
  Guards.guard(SubscriptionGuard()),
  Guards.guard(PaymentGuard()),
])

// Any guard can pass
Guards.orAll([
  Guards.guard(AuthenticationGuard()),
  Guards.guard(AdminGuard()),
  Guards.guard(SuperAdminGuard()),
])

// Exactly one guard must pass
Guards.xorAll([
  Guards.guard(AuthenticationGuard()),
  Guards.guard(AdminGuard()),
  Guards.guard(SuperAdminGuard()),
], '/unauthorized')
```

#### 2. **Nested Binary Operators**
```dart
// For complex logic: ((a & b) & c) & d
Guards.and(
  Guards.and(
    Guards.and(
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ),
    Guards.guard(SubscriptionGuard()),
  ),
  Guards.guard(PaymentGuard()),
)
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
  GuardExpression get guards => Guards.or(
    Guards.and(
      Guards.guard(AuthenticationGuard()),
      Guards.and(
        Guards.guard(RoleGuard(['admin'])),
        Guards.guard(SubscriptionGuard()),
      ),
    ),
    Guards.or(
      Guards.guard(SuperAdminGuard()),
      Guards.guard(SpecialAccessGuard()),
    ),
  );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumAdminScreen();
  }
}

// Same logic using multi-expression operators (cleaner)
class PremiumAdminRouteV2 extends GoRouteData with GuardedRoute {
  const PremiumAdminRouteV2();

  @override
  GuardExpression get guards => Guards.or(
    Guards.andAll([
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
      Guards.guard(SubscriptionGuard()),
    ]),
    Guards.orAll([
      Guards.guard(SuperAdminGuard()),
      Guards.guard(SpecialAccessGuard()),
    ]),
  );

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
  final expression = Guards.or(
    Guards.and(
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ),
    Guards.guard(SuperAdminGuard()),
  );

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

Order guards from fastest to slowest in AND expressions:

```dart
Guards.and(
  Guards.guard(AppInitializationGuard()), // Fast check
  Guards.guard(AuthenticationGuard()),    // Medium check
  Guards.guard(AsyncGuard()),             // Slow async check
)
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
final premiumGuard = Guards.guard(PremiumFeatureGuard());
final adminGuard = Guards.guard(RoleGuard(['admin']));

// Use in multiple routes
final adminPremiumGuard = Guards.and(adminGuard, premiumGuard);
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

### 5. Use Guard Utilities

```dart
// Always allow access (for testing or public routes)
Guards.allow()
```



## Testing

### Unit Testing Guard Expressions
```dart
test('AND expression with both guards passing', () async {
  final expression = Guards.and(
    Guards.guard(AuthenticationGuard()),
    Guards.guard(RoleGuard(['admin'])),
  );
  
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

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
