---
title: Quick Start
description: Get up and running with Go Router Guards in 5 minutes
---

import { Steps } from '@astrojs/starlight/components';

This guide will help you create your first guard and protect a route in just a few minutes.

## Prerequisites

- Flutter project with Go Router already set up
- Go Router Guards [installed](/installation/)

## 5-Minute Setup

<Steps>

1. **Create Your First Guard**

   Create a simple authentication guard:

   ```dart
   import 'dart:async';
   import 'package:flutter/material.dart';
   import 'package:go_router_guards/go_router_guards.dart';

   class AuthGuard extends GoRouterGuard {
     @override
     FutureOr<void> onGoRouterNavigation(
       NavigationResolver resolver,
       BuildContext context,
       GoRouterState state,
     ) async {
       // Simulate checking authentication
       final isAuthenticated = await _checkAuth();
       
       if (isAuthenticated) {
         resolver.next(); // Allow navigation
       } else {
         resolver.redirect('/login'); // Redirect to login
       }
     }

     Future<bool> _checkAuth() async {
       // Your authentication logic here
       return false; // For demo purposes
     }
   }
   ```

2. **Protect a Type-Safe Route**

   Use the `GuardedRoute` mixin to protect a route:

   ```dart
   import 'package:go_router/go_router.dart';
   import 'package:go_router_guards/go_router_guards.dart';

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

3. **Set Up Your Router**

   Configure your Go Router with the protected routes:

   ```dart
   final router = GoRouter(
     routes: [
       // Your login route (unprotected)
       GoRoute(
         path: '/login',
         builder: (context, state) => const LoginScreen(),
       ),
       
       // Type-safe protected route
       ...ProfileRoute().routes,
     ],
   );
   ```

4. **Test the Protection**

   Run your app and try to navigate to `/profile`. You should be redirected to `/login`!

</Steps>

## Alternative: Traditional Routes

If you prefer traditional Go Router syntax:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
      redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
    ),
  ],
);
```

## What Just Happened?

1. **Created a Guard**: `AuthGuard` checks authentication and redirects unauthenticated users
2. **Protected a Route**: `ProfileRoute` uses `GuardedRoute` mixin to apply the guard
3. **Handled Navigation**: The guard automatically intercepts navigation attempts

## Next Steps

Now that you have basic protection working, explore these features:

### Combine Multiple Guards

```dart
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
  ]);
}
```

### Create Role-Based Guards

```dart
class RoleGuard extends GoRouterGuard {
  const RoleGuard(this.requiredRoles);
  
  final List<String> requiredRoles;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userRoles = await getUserRoles();
    final hasRequiredRole = requiredRoles.any(userRoles.contains);
    
    if (hasRequiredRole) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}
```

### Add Router-Level Protection

```dart
final router = GoRouter(
  routes: $appRoutes,
  // Protect all routes except login
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/login', '/register'],
    ),
  ),
);
```

## Common Patterns

### Loading States

```dart
class AuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (_) => const CircularProgressIndicator(),
    );

    try {
      final isAuthenticated = await _checkAuth();
      Navigator.of(context).pop(); // Hide loading
      
      if (isAuthenticated) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } catch (error) {
      Navigator.of(context).pop(); // Hide loading
      resolver.redirect('/error');
    }
  }
}
```

### Conditional Logic

```dart
class SubscriptionGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = await getCurrentUser();
    
    if (user.hasActiveSubscription) {
      resolver.next();
    } else if (user.isTrialExpired) {
      resolver.redirect('/subscription-required');
    } else {
      resolver.redirect('/trial-warning');
    }
  }
}
```

## Debugging Tips

### Enable Guard Logging

```dart
class AuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    print('AuthGuard: Checking route ${state.uri}');
    
    final isAuthenticated = await _checkAuth();
    print('AuthGuard: User authenticated: $isAuthenticated');
    
    if (isAuthenticated) {
      print('AuthGuard: Allowing navigation');
      resolver.next();
    } else {
      print('AuthGuard: Redirecting to login');
      resolver.redirect('/login');
    }
  }
}
```

### Test Your Guards

```dart
void main() {
  testWidgets('AuthGuard redirects unauthenticated users', (tester) async {
    final guard = AuthGuard();
    final context = MockBuildContext();
    final state = MockGoRouterState();
    
    final result = await guard.executeWithResolver(context, state);
    
    expect(result.continueNavigation, false);
    expect(result.redirectPath, '/login');
  });
}
```

## Need Help?

- 📖 Read the detailed [Guides](/guides/creating-guards/)
- 🔍 Check out [Examples](/examples/authentication/)
- 💬 Ask questions in [GitHub Discussions](https://github.com/tomassasovsky/go_router_guards/discussions)
- 🐛 Report issues on [GitHub](https://github.com/tomassasovsky/go_router_guards/issues)

You're now ready to build sophisticated navigation protection! 🎉
