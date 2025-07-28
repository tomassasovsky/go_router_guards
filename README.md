# go_router_guards

A flexible and extensible guard system for Go Router that enables type-safe route protection with chainable guards.

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

[ci_badge]: https://github.com/tomassasovsky/go_router_guards/workflows/go_router_guards/badge.svg
[ci_link]: https://github.com/tomassasovsky/go_router_guards/actions/workflows/main.yaml
[coverage_badge]: https://codecov.io/gh/tomassasovsky/go_router_guards/branch/main/graph/badge.svg
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
  go_router_guards: ^0.1.0
```

### Type-Safe Routes with Guards

Following [VGV's routing best practices](https://engineering.verygood.ventures/navigation/navigation/), use type-safe routes with guards:

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
  GuardChain get guards => GuardChain()..add(AuthenticationGuard());

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

### GuardChain

Chain multiple guards together:

```dart
GuardChain()
  ..add(AuthenticationGuard())
  ..add(RoleBasedGuard(['admin']))
  ..add(SubscriptionGuard())
```

### GuardedRoute Mixin

Add guard functionality to your route classes:

```dart
class AdminRoute extends GoRouteData with GuardedRoute {
  const AdminRoute();

  @override
  GuardChain get guards => GuardChain()
    ..add(AuthenticationGuard())
    ..add(RoleBasedGuard(['admin']));

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
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

### 2. Chain Guards by Performance

Order guards from fastest to slowest:

```dart
GuardChain()
  ..add(AppInitializationGuard()) // Fast check
  ..add(AuthenticationGuard())    // Medium check
  ..add(AsyncGuard())             // Slow async check
```

### 3. Create Reusable Guards

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

## Integration Examples

### With Cubit/Bloc
```dart
class AuthGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      return LoginRoute().location;
    }
    return null;
  }
}
```

### With Provider
```dart
class UserGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      return LoginRoute().location;
    }
    return null;
  }
}
```

### With Riverpod
```dart
class ProfileGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final profile = context.read(profileProvider);
    if (!profile.hasCompletedOnboarding) {
      return OnboardingRoute().location;
    }
    return null;
  }
}
```

## Testing

### Unit Testing Guards
```dart
test('AuthenticationGuard should redirect when not authenticated', () async {
  final guard = AuthenticationGuard();
  final mockContext = MockBuildContext();
  final mockState = MockGoRouterState();
  
  when(mockContext.read<AuthCubit>()).thenReturn(mockAuthCubit);
  when(mockAuthCubit.state).thenReturn(UnauthenticatedState());
  
  final result = await guard.redirect(mockContext, mockState);
  
  expect(result, LoginRoute().location);
});
```

### Integration Testing
```dart
testWidgets('Protected route should redirect to login', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.tap(find.text('Protected Route'));
  await tester.pumpAndSettle();
  
  expect(find.text('Login'), findsOneWidget);
});
```

## Migration from Manual Guards

### Before (Manual Implementation)
```dart
class ProtectedRoute extends GoRouteData {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      return '/login'; // Hardcoded path
    }
    return null;
  }
}
```

### After (Type-Safe Guards)
```dart
class ProtectedRoute extends GoRouteData with GuardedRoute {
  @override
  GuardChain get guards => GuardChain()..add(AuthenticationGuard());

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

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
