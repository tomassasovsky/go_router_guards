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
[license_link]: LICENSE

[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

## Quick Start

Install:

```yaml
dependencies:
  go_router_guards: ^1.0.0
```

Type-safe route with a guard:

```dart
@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with GuardedRoute {
  const ProtectedRoute();

  @override
  RouteGuard get guard => guardAll([
    const AuthGuard(),
    const RoleGuard(['admin']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) => const ProtectedScreen();
}
```

Traditional GoRoute with a guard:

```dart
GoRoute(
  path: '/protected',
  builder: (context, state) => const ProtectedScreen(),
  redirect: guardAll([
    const AuthGuard(),
    const RoleGuard(['admin']),
  ]).toRedirect(),
)
```

Compose guards:

```dart
final premiumGuard = guardAnyOf([
  const SubscriptionGuard(),
  const RoleGuard(['staff']),
]);
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
