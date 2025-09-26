---
title: go_router_guards Package
description: Go Router specific integration for navigation guards with type-safe route support
---

import { Card, CardGrid } from '@astrojs/starlight/components';

<div class="package-badge">Go Router Integration</div>

# go_router_guards

The `go_router_guards` package provides seamless integration between the core `route_guards` system and Flutter's Go Router. It includes specialized classes, mixins, and utilities designed specifically for Go Router's architecture.

## Overview

This package extends the core guard functionality with Go Router-specific features:

- **GoRouterGuard**: Specialized guard class for Go Router
- **GuardedRoute/UnguardedRoute**: Mixins for type-safe routes
- **RouteGuardUtils**: Utilities for traditional GoRoute usage
- **ConditionalGuard**: Path-based conditional protection

## Key Features

<CardGrid>
  <Card title="🎯 Type-Safe Integration" icon="target">
    Full support for Go Router's type-safe routing with specialized mixins.
  </Card>
  
  <Card title="🔄 Backward Compatibility" icon="recycle">
    Works with both traditional GoRoute syntax and type-safe routes.
  </Card>
  
  <Card title="🏗️ Built-in Utilities" icon="seti:config">
    Ready-to-use utilities for common guard patterns.
  </Card>
  
  <Card title="📍 Context-Aware" icon="map">
    Access to BuildContext and GoRouterState in guard logic.
  </Card>
</CardGrid>

## Installation

```bash
flutter pub add go_router_guards
```

This automatically includes `route_guards` as a dependency.

## Core Classes

### GoRouterGuard

Specialized guard class that provides access to Flutter's `BuildContext` and Go Router's `GoRouterState`:

```dart
abstract class GoRouterGuard extends RouteGuard {
  const GoRouterGuard();

  /// Override this method for Go Router specific guard logic
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  );
}
```

**Example Implementation:**

```dart
class AuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Access context for state management
    final authState = context.read<AuthBloc>().state;
    
    if (authState.isAuthenticated) {
      resolver.next();
    } else {
      // Use type-safe navigation
      resolver.redirect(LoginRoute().location);
    }
  }
}
```

### GuardedRoute Mixin

Mixin for type-safe routes that adds automatic guard execution:

```dart
mixin GuardedRoute on GoRouteData {
  /// Override to define route protection
  RouteGuard get guards;

  /// Automatically called by Go Router
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return executeGuards(context, state);
  }
}
```

**Usage Example:**

```dart
@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
```

### UnguardedRoute Mixin

Explicitly opt-out of router-level guards:

```dart
mixin UnguardedRoute on GoRouteData {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return null; // Always allow navigation
  }
}
```

**Usage Example:**

```dart
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with UnguardedRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}
```

### GuardedShellRoute Mixin

Similar to `GuardedRoute` but for shell routes:

```dart
@TypedShellRoute<AppShellRoute>()
class AppShellRoute extends ShellRouteData with GuardedShellRoute {
  @override
  RouteGuard get guards => AuthGuard();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget child) {
    return AppShell(child: child);
  }
}
```

## Utilities

### RouteGuardUtils

Utility class for traditional GoRoute integration:

```dart
class RouteGuardUtils {
  /// Creates a redirect function for traditional GoRoute usage
  static GoRouterRedirect createGuardRedirect(RouteGuard guard);
}
```

**Example Usage:**

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/protected',
      builder: (context, state) => const ProtectedScreen(),
      redirect: RouteGuardUtils.createGuardRedirect(
        Guards.all([AuthGuard(), RoleGuard(['user'])]),
      ),
    ),
  ],
);
```

### ConditionalGuard

Apply guards conditionally based on path patterns:

```dart
class ConditionalGuard extends GoRouterGuard {
  const ConditionalGuard({
    required this.guard,
    this.includedPaths = const [],
    this.excludedPaths = const [],
  });

  final RouteGuard guard;
  final List<String> includedPaths;
  final List<String> excludedPaths;
}
```

**Example Usage:**

```dart
final router = GoRouter(
  routes: $appRoutes,
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/login', '/register', '/forgot-password'],
    ),
  ),
);
```

## Advanced Patterns

### Multi-Level Protection

Combine router-level and route-level guards:

```dart
// Router-level: Basic authentication
final router = GoRouter(
  routes: $appRoutes,
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/login', '/public'],
    ),
  ),
);

// Route-level: Additional authorization
@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    RoleGuard(['admin']),           // Already authenticated by router
    PermissionGuard(['manage_users']), // Additional permission check
  ]);
}
```

### Dynamic Guard Configuration

Create guards that adapt based on route parameters:

```dart
class DynamicGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userId = state.pathParameters['userId'];
    final currentUser = context.read<UserCubit>().state.user;
    
    // Users can only access their own profile or admins can access any
    if (userId == currentUser.id || currentUser.hasRole('admin')) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}

@TypedGoRoute<UserProfileRoute>(path: '/user/:userId')
class UserProfileRoute extends GoRouteData with GuardedRoute {
  const UserProfileRoute({required this.userId});
  
  final String userId;

  @override
  RouteGuard get guards => DynamicGuard();
}
```

### State Management Integration

Integrate with popular state management solutions:

```dart
class BlocAuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final authState = context.read<AuthBloc>().state;
    
    switch (authState) {
      case AuthAuthenticated():
        resolver.next();
      case AuthUnauthenticated():
        resolver.redirect('/login');
      case AuthLoading():
        resolver.redirect('/loading');
    }
  }
}
```

### Loading and Error Handling

Handle loading states and errors gracefully:

```dart
class AsyncAuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await authService.validateToken();
      
      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.isValid) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } catch (error) {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Handle error
      resolver.redirect('/error?message=${Uri.encodeComponent(error.toString())}');
    }
  }
}
```

## Testing

### Testing GuardedRoute

```dart
void main() {
  testWidgets('AdminRoute requires authentication and admin role', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [...AdminRoute().routes],
          redirect: (context, state) {
            // Mock unauthenticated state
            return '/login';
          },
        ),
      ),
    );

    // Try to navigate to admin route
    await tester.tap(find.text('Go to Admin'));
    await tester.pumpAndSettle();

    // Should be redirected to login
    expect(find.text('Login'), findsOneWidget);
  });
}
```

### Testing Guards with Context

```dart
void main() {
  group('AuthGuard', () {
    testWidgets('redirects to login when not authenticated', (tester) async {
      final guard = AuthGuard();
      final mockContext = MockBuildContext();
      final mockState = MockGoRouterState();

      when(() => mockContext.read<AuthBloc>())
          .thenReturn(mockAuthBloc);
      when(() => mockAuthBloc.state)
          .thenReturn(const AuthUnauthenticated());

      final result = await guard.executeWithResolver(mockContext, mockState);

      expect(result.continueNavigation, false);
      expect(result.redirectPath, '/login');
    });
  });
}
```

## Migration Guide

### From Traditional Routes to Type-Safe Routes

**Before:**
```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
  redirect: (context, state) async {
    final isAuth = await checkAuth();
    return isAuth ? null : '/login';
  },
)
```

**After:**
```dart
@TypedGoRoute<ProfileRoute>(path: '/profile')
class ProfileRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProfileScreen();
  }
}
```

### From Custom Redirect to Guards

**Before:**
```dart
final router = GoRouter(
  redirect: (context, state) {
    if (!_publicPaths.contains(state.uri.path)) {
      final isAuth = context.read<AuthCubit>().state.isAuthenticated;
      return isAuth ? null : '/login';
    }
    return null;
  },
);
```

**After:**
```dart
final router = GoRouter(
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/login', '/register', '/public'],
    ),
  ),
);
```

## Best Practices

1. **Use Type-Safe Routes**: Prefer `GuardedRoute` mixin over traditional redirects
2. **Layer Your Protection**: Use router-level for basic checks, route-level for specific authorization
3. **Handle Loading States**: Show progress indicators for async guards
4. **Error Boundaries**: Always handle guard failures gracefully
5. **Test Guards**: Write comprehensive tests for guard logic
6. **Performance**: Cache expensive checks when possible

## API Reference

### Classes

| Class | Description |
|-------|-------------|
| `GoRouterGuard` | Base class for Go Router specific guards |
| `ConditionalGuard` | Path-based conditional guard application |
| `RouteGuardUtils` | Utilities for traditional GoRoute integration |

### Mixins

| Mixin | Description |
|-------|-------------|
| `GuardedRoute` | Adds guard functionality to type-safe routes |
| `UnguardedRoute` | Explicitly opts out of router-level guards |
| `GuardedShellRoute` | Adds guard functionality to shell routes |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `RouteGuardUtils.createGuardRedirect(guard)` | `GoRouterRedirect` | Creates redirect function for traditional routes |
| `executeGuards(context, state)` | `Future<String?>` | Executes guards and returns redirect path |

## Contributing

The `go_router_guards` package welcomes contributions! See the [contribution guide](https://github.com/tomassasovsky/go_router_guards/blob/main/CONTRIBUTING.md) for details.
