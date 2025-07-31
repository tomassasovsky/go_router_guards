# Enhanced Guards System

This document describes the enhanced guards system that provides middleware-style navigation control similar to auto_route's guard system, while maintaining full compatibility with go_router.

## Overview

The enhanced guards system provides:

- **NavigationResolver**: Provides control flow similar to auto_route's resolver
- **RouteGuardEnhanced**: Middleware-style guard base class for all guard implementations
- **GuardsEnhanced**: Factory methods for combining guards (all, anyOf, oneOf)
- **RouteGuardUtils**: Utilities for using guards with regular (non-type-safe) GoRoute objects

## Key Concepts

### NavigationResolver

The `NavigationResolver` provides fine-grained control over navigation flow:

```dart
class MyGuard extends RouteGuardEnhanced {
  @override
  void onNavigation(NavigationResolver resolver, BuildContext context, GoRouterState state) async {
    final isAuthenticated = await checkAuth();
    
    if (isAuthenticated) {
      resolver.next(); // Continue navigation
    } else {
      resolver.redirect('/login'); // Redirect to login
    }
  }
}
```

### Resolver Methods

- `resolver.next()` - Allow navigation to continue
- `resolver.redirect(path)` - Redirect to a different path  
- `resolver.block()` - Block navigation by redirecting to current location
- `resolver.redirectTo(path)` - Redirect and return a future (like auto_route)

**Note on Blocking**: The `block()` method works by redirecting to the current location, which is the go_router-native way to prevent navigation. This is more elegant than having a separate blocking mechanism and integrates seamlessly with go_router's redirect-only approach.

## Enhanced Guard Examples

### Simple Authentication Guard

```dart
class AuthGuard extends RouteGuardEnhanced {
  @override
  void onNavigation(NavigationResolver resolver, BuildContext context, GoRouterState state) async {
    final isAuth = context.read<AuthCubit>().state.isAuthenticated;
    
    if (isAuth) {
      resolver.next();
    } else {
      // Include current path for redirect after login
      final currentPath = state.uri.toString();
      resolver.redirect('/login?redirect=${Uri.encodeComponent(currentPath)}');
    }
  }
}
```

### Advanced Role Guard

```dart
class RoleGuard extends RouteGuardEnhanced {
  const RoleGuard(this.requiredRoles, {this.requireAll = false});
  
  final List<String> requiredRoles;
  final bool requireAll;

  @override
  void onNavigation(NavigationResolver resolver, BuildContext context, GoRouterState state) {
    final userRoles = context.read<UserCubit>().state.roles;
    
    bool hasAccess = requireAll 
      ? requiredRoles.every(userRoles.contains)
      : requiredRoles.any(userRoles.contains);
    
    if (hasAccess) {
      resolver.next();
    } else {
      final isAuth = context.read<AuthCubit>().state.isAuthenticated;
      resolver.redirect(isAuth ? '/unauthorized' : '/login');
    }
  }
}
```

## Factory Methods

### GuardsEnhanced Combinations

```dart
// All guards must pass (sequential execution)
GuardsEnhanced.all([
  authenticationGuard,
  roleGuard,
])

// Any guard can pass (stops at first success)
GuardsEnhanced.anyOf([
  adminGuard,
  moderatorGuard,
], fallbackRedirect: '/access-denied')

// Exactly one guard must pass (validates exclusivity)
GuardsEnhanced.oneOf([
  premiumUserGuard,
  trialUserGuard,
], fallbackRedirect: '/subscription-required')
```

### Complex Guard Logic

For complex scenarios, use `GuardsEnhanced.simple()` with custom logic:

```dart
// Multiple checks with different behaviors
GuardsEnhanced.simple((resolver, context, state) async {
  // Check authentication first
  if (!await isAuthenticated(context)) {
    resolver.redirect('/login');
    return;
  }
  
  // Check role permissions
  if (!hasRole(context, 'admin')) {
    resolver.block(); // Stay on current page
    return;
  }
  
  // Additional business logic
  if (await isMaintenanceMode()) {
    resolver.redirect('/maintenance');
    return;
  }
  
  resolver.next();
})

// Path-based conditional logic
GuardsEnhanced.simple((resolver, context, state) async {
  if (state.fullPath.startsWith('/admin')) {
    // Admin routes require admin role
    if (!hasRole(context, 'admin')) {
      resolver.block();
      return;
    }
  } else {
    // Regular routes just need authentication
    if (!await isAuthenticated(context)) {
      resolver.redirect('/login');
      return;
    }
  }
  
  resolver.next();
})
```

## Usage in Routes

### Enhanced Guards

```dart
@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuardEnhanced get guards => GuardsEnhanced.all([
    AuthenticationGuard(),
    AdminRoleGuard(),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

// Example individual guards
class AuthenticationGuard extends RouteGuardEnhanced {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (context.read<AuthCubit>().state.isAuthenticated) {
      resolver.next();
    } else {
      resolver.redirect('/login');
    }
  }
}

class AdminRoleGuard extends RouteGuardEnhanced {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final roles = context.read<UserCubit>().state.roles;
    if (roles.contains('admin')) {
      resolver.next();
    } else {
      resolver.block(); // Stay on current page
    }
  }
}
```

### Custom Business Logic

```dart
@TypedGoRoute<BusinessHoursRoute>(path: '/business-only')
class BusinessHoursRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuardEnhanced get guards => GuardsEnhanced.simple(
    (resolver, context, state) async {
      final authState = context.read<AuthCubit>().state;
      final userState = context.read<UserCubit>().state;
      
      if (!authState.isAuthenticated) {
        resolver.redirect('/login');
        return;
      }
      
      // Check business hours
      final now = DateTime.now();
      final isBusinessHours = now.hour >= 9 && now.hour <= 17;
      
      if (!isBusinessHours && !userState.roles.contains('admin')) {
        resolver.redirect('/after-hours-notice');
        return;
      }
      
      resolver.next();
    },
  );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const BusinessContent();
  }
}
```

### Async External Validation

```dart
@TypedGoRoute<SubscriptionRoute>(path: '/premium')
class SubscriptionRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuardEnhanced get guards => GuardsEnhanced.simple(
    (resolver, context, state) async {
      try {
        final isAuth = context.read<AuthCubit>().state.isAuthenticated;
        if (!isAuth) {
          resolver.redirect('/login');
          return;
        }
        
        // External subscription check
        final hasSubscription = await subscriptionService.checkStatus();
        if (hasSubscription) {
          resolver.next();
        } else {
          resolver.redirect('/subscribe');
        }
      } catch (e) {
        resolver.redirect('/error?message=${Uri.encodeComponent('Service unavailable')}');
      }
    },
  );
}
```

## Backward Compatibility

Your existing guards continue to work without changes:

```dart
// Legacy guard still works
class LegacyAuthGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isAuth = context.read<AuthCubit>().state.isAuthenticated;
    return isAuth ? null : '/login';
  }
}

@TypedGoRoute<LegacyRoute>(path: '/legacy')
class LegacyRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    LegacyAuthGuard(),
    RoleGuard(['user']),
  ]);
}
```

## Migration Guide

### From Legacy to Enhanced

**Before:**
```dart
class AuthGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return isAuth ? null : '/login';
  }
}
```

**After:**
```dart
class AuthGuard extends RouteGuardEnhanced {
  @override
  void onNavigation(NavigationResolver resolver, BuildContext context, GoRouterState state) {
    if (isAuth) {
      resolver.next();
    } else {
      resolver.redirect('/login');
    }
  }
}
```

### Using Factory Methods

**Instead of custom classes:**
```dart
// Replace custom guard classes with factory methods
RouteGuardEnhanced get guards => GuardsEnhanced.authenticated(
  check: (context) => context.read<AuthCubit>().state.isAuthenticated,
  redirectTo: '/login',
);
```

## Comparison with Auto Route

| Feature | Auto Route | Enhanced Guards |
|---------|------------|-----------------|
| Resolver Pattern | ✅ `NavigationResolver` | ✅ `NavigationResolver` |
| `next()` method | ✅ | ✅ |
| `redirect()` method | ✅ | ✅ |
| Factory constructors | ✅ | ✅ |
| Temporary redirects | ✅ `redirectUntil()` | ✅ `redirectTo()` |
| Route overrides | ✅ | ❌ (go_router limitation) |
| Reevaluation | ✅ | 🚧 (planned) |
| Backward compatibility | ❌ | ✅ |

## Advanced Patterns

### Error Handling in Guards

```dart
GuardsEnhanced.simple((resolver, context, state) async {
  try {
    await validateUser();
    resolver.next();
  } catch (e) {
    if (e is AuthenticationException) {
      resolver.redirect('/login');
    } else {
      resolver.redirect('/error');
    }
  }
})
```

### Multiple Validation Steps

```dart
GuardsEnhanced.simple((resolver, context, state) async {
  // Step 1: Check authentication
  if (!await isAuthenticated()) {
    resolver.redirect('/login');
    return;
  }
  
  // Step 2: Check permissions
  if (!await hasPermission(requiredPermission)) {
    resolver.redirect('/unauthorized');
    return;
  }
  
  // Step 3: Check subscription
  if (!await hasValidSubscription()) {
    resolver.redirect('/subscribe');
    return;
  }
  
  resolver.next();
})
```

This enhanced guard system gives you the flexibility and control of auto_route's guards while keeping the simplicity and type safety of go_router. 