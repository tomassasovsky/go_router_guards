---
title: API Overview
description: Complete API reference for Go Router Guards packages
---

This section provides comprehensive API documentation for both packages in the Go Router Guards system.

## Package Structure

### route_guards (Core Package)

The foundation package providing framework-agnostic guard functionality.

#### Core Classes

| Class | Description |
|-------|-------------|
| `RouteGuard` | Abstract base class for all guards |
| `NavigationResolver` | Controls navigation flow in guards |
| `GuardResult` | Represents the outcome of guard execution |
| `Guards` | Utility class for combining guards |

#### Key Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `onNavigation(resolver, context, state)` | `FutureOr<void>` | Override to implement guard logic |
| `executeWithResolver(context, state)` | `Future<GuardResult>` | Executes guard using resolver pattern |
| `Guards.all(guards)` | `RouteGuard` | All guards must pass (AND logic) |
| `Guards.anyOf(guards)` | `RouteGuard` | Any guard can pass (OR logic) |
| `Guards.oneOf(guards)` | `RouteGuard` | Exactly one guard must pass (XOR logic) |

### go_router_guards (Integration Package)

Go Router specific integration with Flutter context and type-safe routing support.

#### Specialized Classes

| Class | Description |
|-------|-------------|
| `GoRouterGuard` | Go Router specific guard with BuildContext access |
| `ConditionalGuard` | Path-based conditional guard application |
| `RouteGuardUtils` | Utilities for traditional GoRoute integration |

#### Mixins

| Mixin | Description |
|-------|-------------|
| `GuardedRoute` | Adds guard functionality to type-safe routes |
| `UnguardedRoute` | Explicitly opts out of router-level guards |
| `GuardedShellRoute` | Adds guard functionality to shell routes |

#### Key Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `onGoRouterNavigation(resolver, context, state)` | `FutureOr<void>` | Go Router specific guard implementation |
| `RouteGuardUtils.createGuardRedirect(guard)` | `GoRouterRedirect` | Creates redirect function for traditional routes |
| `executeGuards(context, state)` | `Future<String?>` | Executes guards and returns redirect path |

## NavigationResolver API

The resolver provides three control methods:

```dart
class NavigationResolver {
  /// Allow navigation to continue
  void next();
  
  /// Redirect to a different path
  void redirect(String path);
  
  /// Block navigation entirely
  void block();
  
  /// Get the future result
  Future<GuardResult> get future;
}
```

## GuardResult API

Represents the outcome of guard execution:

```dart
class GuardResult {
  final bool continueNavigation;
  final String? redirectPath;
  
  // Factory constructors
  GuardResult.next();           // Allow navigation
  GuardResult.redirect(String path); // Redirect
  GuardResult.block();          // Block navigation
}
```

## Common Guard Patterns

### Basic Guard Implementation

```dart
class MyGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (await checkCondition()) {
      resolver.next();
    } else {
      resolver.redirect('/fallback');
    }
  }
}
```

### Guard Combination

```dart
final combinedGuard = Guards.all([
  AuthGuard(),
  RoleGuard(['admin']),
  PermissionGuard(['access']),
]);
```

### Type-Safe Route Protection

```dart
@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => MyGuard();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}
```

### Traditional Route Protection

```dart
GoRoute(
  path: '/protected',
  builder: (context, state) => const ProtectedScreen(),
  redirect: RouteGuardUtils.createGuardRedirect(MyGuard()),
)
```

## Error Handling

All guard methods should handle errors gracefully:

```dart
@override
FutureOr<void> onGoRouterNavigation(
  NavigationResolver resolver,
  BuildContext context,
  GoRouterState state,
) async {
  try {
    final result = await riskyOperation();
    if (result.isValid) {
      resolver.next();
    } else {
      resolver.redirect('/error');
    }
  } catch (error) {
    // Log error and gracefully degrade
    logger.error('Guard failed: $error');
    resolver.next(); // or resolver.redirect('/fallback');
  }
}
```

## Type Definitions

### Core Types

```dart
typedef GoRouterRedirect = FutureOr<String?> Function(
  BuildContext context,
  GoRouterState state,
);
```

### Guard Execution Flow

1. Router calls guard (via redirect or mixin)
2. Guard creates `NavigationResolver`
3. Guard calls `onNavigation`/`onGoRouterNavigation`
4. Guard uses resolver to control flow
5. Resolver completes with `GuardResult`
6. Router acts on the result

## Migration Guide

### From Custom Redirects

**Before:**
```dart
GoRoute(
  redirect: (context, state) async {
    final isAuth = await checkAuth();
    return isAuth ? null : '/login';
  },
)
```

**After:**
```dart
GoRoute(
  redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
)
```

### From Manual Guard Logic

**Before:**
```dart
class MyRoute extends GoRouteData {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    // Manual guard logic
  }
}
```

**After:**
```dart
class MyRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => MyGuard();
}
```

## Performance Considerations

- Guards execute in order for `Guards.all()`
- Guards stop on first success for `Guards.anyOf()`
- Cache expensive operations when possible
- Use timeouts for network calls
- Consider guard execution frequency

## Best Practices

1. **Single Responsibility**: One guard, one concern
2. **Composition**: Use `Guards` utility for complex logic
3. **Error Handling**: Always handle potential failures
4. **Testing**: Write unit tests for guard logic
5. **Performance**: Order guards by execution time
6. **Documentation**: Document guard requirements clearly

For detailed examples and advanced usage patterns, see the [Guides](/guides/) and [Examples](/examples/) sections.
