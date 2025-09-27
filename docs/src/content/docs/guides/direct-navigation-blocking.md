---
title: Handling Direct Navigation Blocking
description: Learn how to properly handle route blocking when users navigate directly to protected routes
---

# Handling Direct Navigation Blocking

When users directly enter a protected URL in their browser (e.g., typing `/admin` directly), there's no previous route to navigate back to when blocking access. This guide covers strategies for handling these scenarios gracefully.

## The Problem

Consider this scenario:
1. User types `myapp.com/admin` directly into browser
2. Admin route is protected by guards
3. User doesn't have admin permissions
4. Guard calls `resolver.block()` 
5. **Problem**: There's no previous route to "stay at"

## Solutions

### 1. Redirect to Specific Routes

The most common approach is to redirect unauthorized users to specific routes:

```dart
class RoleGuard extends GoRouterGuard {
  const RoleGuard(this.requiredRoles, {this.unauthorizedRoute});

  final List<String> requiredRoles;
  final String? unauthorizedRoute;

  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userRoles = context.read<UserCubit>().state.roles;
    final hasRequiredRole = requiredRoles.any(userRoles.contains);
    
    if (!hasRequiredRole) {
      // Always redirect to unauthorized page for direct navigation
      resolver.redirect(unauthorizedRoute ?? '/unauthorized');
    } else {
      resolver.next();
    }
  }
}
```

Usage:
```dart
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin'], unauthorizedRoute: '/unauthorized'),
  ]);
}
```

### 2. Smart Blocking with Fallback

Use the enhanced `block()` method with fallback for better UX:

```dart
class RoleGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userRoles = context.read<UserCubit>().state.roles;
    final hasRequiredRole = requiredRoles.any(userRoles.contains);
    
    if (!hasRequiredRole) {
      // Block with fallback to unauthorized page
      resolver.block(fallbackPath: '/unauthorized');
      // OR use the convenience method:
      // resolver.blockWithFallback('/unauthorized');
    } else {
      resolver.next();
    }
  }
}
```

### 3. Context-Aware Blocking

Implement different behaviors based on navigation context:

```dart
class SmartRoleGuard extends GoRouterGuard {
  const SmartRoleGuard(this.requiredRoles);

  final List<String> requiredRoles;

  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userRoles = context.read<UserCubit>().state.roles;
    final hasRequiredRole = requiredRoles.any(userRoles.contains);
    
    if (!hasRequiredRole) {
      final router = GoRouter.of(context);
      
      if (router.canPop()) {
        // User navigated from within app - block (stay at previous page)
        resolver.block();
      } else {
        // Direct navigation - redirect to appropriate page
        resolver.redirect('/unauthorized');
      }
    } else {
      resolver.next();
    }
  }
}
```

## Best Practices

### 1. Always Provide Fallbacks

Never leave users stranded with no valid route:

```dart
// ✅ Good - Always has a fallback
resolver.block(fallbackPath: '/home');

// ❌ Bad - Could leave user with no valid route
resolver.block();
```

### 2. Use Meaningful Error Pages

Create helpful unauthorized pages:

```dart
@TypedGoRoute<UnauthorizedRoute>(path: '/unauthorized')
class UnauthorizedRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UnauthorizedScreen(); // Shows login button, explanation, etc.
  }
}
```

### 3. Consider User Experience

Different strategies for different route types:

```dart
// Admin routes - redirect to unauthorized page
class AdminGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(resolver, context, state) async {
    if (!hasAdminRole) {
      resolver.redirect('/unauthorized');
    }
  }
}

// Premium content - redirect to upgrade page
class PremiumGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(resolver, context, state) async {
    if (!isPremiumUser) {
      resolver.redirect('/upgrade');
    }
  }
}
```

### 4. Combine with Authentication Guards

Layer guards appropriately:

```dart
class SecureAdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    // First check authentication
    AuthenticationGuard(), // Redirects to /login
    // Then check authorization  
    RoleGuard(['admin']), // Uses blockWithFallback or redirect to /unauthorized
  ]);
}
```

## Testing Direct Navigation

```dart
testWidgets('direct navigation to admin route without permissions', (tester) async {
  // Setup user without admin role
  when(mockUserCubit.state).thenReturn(UserState(roles: ['user']));
  
  // Simulate direct navigation
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  
  // Navigate directly to admin route
  router.go('/admin');
  await tester.pumpAndSettle();
  
  // Should be redirected to unauthorized page
  expect(find.byType(UnauthorizedScreen), findsOneWidget);
});
```

## Advanced Patterns

### Navigation History Aware Guards

```dart
class HistoryAwareGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!hasPermission) {
      final router = GoRouter.of(context);
      final currentLocation = router.routerDelegate.currentConfiguration.fullPath;
      
      // Check if this is the first route (direct navigation)
      if (currentLocation.isEmpty || !router.canPop()) {
        // Direct navigation - send to home with error message
        resolver.redirect('/?error=unauthorized');
      } else {
        // Navigation from within app - stay at current page
        resolver.block();
      }
    }
  }
}
```

### Route-Specific Fallbacks

```dart
class RouteSpecificGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!hasPermission) {
      // Different fallbacks based on attempted route
      final fallback = switch (state.uri.path) {
        '/admin' => '/login?return=/admin',
        '/premium' => '/upgrade',
        '/profile' => '/login',
        _ => '/unauthorized',
      };
      
      resolver.redirect(fallback);
    }
  }
}
```

Remember: The goal is to provide a smooth user experience even when blocking access to protected routes. Always consider what happens when users bookmark or directly navigate to protected URLs.
