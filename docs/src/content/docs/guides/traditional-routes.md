---
title: Traditional Routes
description: Learn how to use Go Router Guards with traditional GoRoute syntax
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

Traditional Go Router syntax uses the `GoRoute` class directly rather than type-safe route classes. Go Router Guards provides seamless integration through the `RouteGuardUtils` utility class.

## RouteGuardUtils

The `RouteGuardUtils` class provides utilities for integrating guards with traditional Go Router syntax:

```dart
class RouteGuardUtils {
  /// Creates a redirect function for traditional GoRoute usage
  static GoRouterRedirect createGuardRedirect(RouteGuard guard);
}
```

## Basic Usage

<Steps>

1. **Create Your Guard**

   ```dart
   class AuthGuard extends GoRouterGuard {
     @override
     FutureOr<void> onGoRouterNavigation(
       NavigationResolver resolver,
       BuildContext context,
       GoRouterState state,
     ) async {
       final isAuthenticated = await checkAuth();
       if (isAuthenticated) {
         resolver.next();
       } else {
         resolver.redirect('/login');
       }
     }
   }
   ```

2. **Apply to Routes**

   ```dart
   final router = GoRouter(
     routes: [
       GoRoute(
         path: '/protected',
         builder: (context, state) => const ProtectedScreen(),
         redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
       ),
     ],
   );
   ```

</Steps>

## Multiple Guards

Combine guards using the `Guards` utility:

```dart
GoRoute(
  path: '/admin',
  builder: (context, state) => const AdminScreen(),
  redirect: RouteGuardUtils.createGuardRedirect(
    Guards.all([
      AuthGuard(),
      RoleGuard(['admin']),
      PermissionGuard(['admin_access']),
    ]),
  ),
)
```

## Router-Level Protection

Apply guards at the router level to protect multiple routes:

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  ],
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/login', '/register'],
    ),
  ),
);
```

## Conditional Protection

Use `ConditionalGuard` for path-based protection:

```dart
final router = GoRouter(
  routes: $appRoutes,
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: Guards.all([
        AuthGuard(),
        SubscriptionGuard(),
      ]),
      includedPaths: ['/premium'], // Only protect premium routes
      excludedPaths: ['/login', '/public'], // Never protect these
    ),
  ),
);
```

## Nested Route Protection

Protect nested routes with different guard levels:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardLayout(),
      redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
          // Inherits auth from parent, no additional guards needed
        ),
        GoRoute(
          path: 'admin',
          builder: (context, state) => const AdminScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            RoleGuard(['admin']), // Additional admin check
          ),
        ),
      ],
    ),
  ],
);
```

## Shell Routes

Protect shell routes and their children:

```dart
final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
```

## Error Handling

Handle guard errors gracefully:

```dart
class SafeRouteGuardUtils {
  static GoRouterRedirect createSafeGuardRedirect(RouteGuard guard) {
    return (BuildContext context, GoRouterState state) async {
      try {
        final result = await guard.executeWithResolver(context, state);
        return result.continueNavigation ? null : result.redirectPath;
      } catch (error) {
        // Log error and allow navigation to prevent app breakage
        debugPrint('Guard error: $error');
        return null; // Allow navigation
      }
    };
  }
}

// Usage
GoRoute(
  path: '/risky',
  builder: (context, state) => const RiskyScreen(),
  redirect: SafeRouteGuardUtils.createSafeGuardRedirect(RiskyGuard()),
)
```

## Performance Optimization

### Cached Guards

Create guards that cache expensive operations:

```dart
class CachedAuthGuard extends GoRouterGuard {
  static DateTime? _lastCheck;
  static bool? _lastResult;
  static const _cacheDuration = Duration(minutes: 5);

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final now = DateTime.now();
    
    // Use cached result if available and fresh
    if (_lastCheck != null && 
        _lastResult != null && 
        now.difference(_lastCheck!) < _cacheDuration) {
      if (_lastResult!) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
      return;
    }
    
    // Perform fresh check
    final isAuthenticated = await authService.isAuthenticated();
    _lastCheck = now;
    _lastResult = isAuthenticated;
    
    if (isAuthenticated) {
      resolver.next();
    } else {
      resolver.redirect('/login');
    }
  }
}
```

### Optimized Guard Ordering

Order guards by execution speed:

```dart
final optimizedGuard = Guards.all([
  LocalCacheGuard(),    // Fastest - memory check
  DatabaseGuard(),      // Medium - local database
  NetworkGuard(),       // Slowest - network call
]);
```

## Real-World Example

Complete traditional router setup with guards:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

// Guards
class AuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated = await AuthService.instance.isAuthenticated();
    if (isAuthenticated) {
      resolver.next();
    } else {
      resolver.redirect('/login');
    }
  }
}

class AdminGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = await AuthService.instance.getCurrentUser();
    if (user?.hasRole('admin') == true) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}

// Router configuration
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Public routes
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (context, state) => const UnauthorizedScreen(),
    ),
    
    // Protected routes
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
      redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
    ),
    
    // Admin routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
      redirect: RouteGuardUtils.createGuardRedirect(
        Guards.all([AuthGuard(), AdminGuard()]),
      ),
    ),
    
    // Subscription-protected routes
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
      redirect: RouteGuardUtils.createGuardRedirect(
        Guards.all([
          AuthGuard(),
          SubscriptionGuard(['premium', 'enterprise']),
        ]),
      ),
    ),
  ],
  
  // Optional: Global redirect for common protection
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/', '/login', '/register', '/unauthorized'],
    ),
  ),
);

// App setup
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Traditional Router Guards Demo',
      routerConfig: appRouter,
    );
  }
}
```

## Testing Traditional Routes

```dart
void main() {
  group('Traditional Routes with Guards', () {
    testWidgets('protected route redirects unauthenticated users', (tester) async {
      // Mock unauthenticated state
      when(() => mockAuthService.isAuthenticated())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/protected',
                builder: (context, state) => const ProtectedScreen(),
                redirect: RouteGuardUtils.createGuardRedirect(AuthGuard()),
              ),
            ],
          ),
        ),
      );

      // Navigate to protected route
      GoRouter.of(tester.element(find.byType(MaterialApp)))
          .go('/protected');
      await tester.pumpAndSettle();

      // Should be redirected to login
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });
  });
}
```

## Migration from Custom Redirects

### Before (Custom Logic)

```dart
GoRoute(
  path: '/protected',
  builder: (context, state) => const ProtectedScreen(),
  redirect: (context, state) async {
    final isAuth = await checkAuth();
    if (!isAuth) return '/login';
    
    final hasRole = await checkRole('admin');
    if (!hasRole) return '/unauthorized';
    
    return null; // Allow navigation
  },
)
```

### After (Using Guards)

```dart
GoRoute(
  path: '/protected',
  builder: (context, state) => const ProtectedScreen(),
  redirect: RouteGuardUtils.createGuardRedirect(
    Guards.all([
      AuthGuard(),
      RoleGuard(['admin']),
    ]),
  ),
)
```

## Best Practices

1. **Reusable Guards**: Create guards that can be used across multiple routes
2. **Combine at Router Level**: Use global redirects for common protection
3. **Path Exclusions**: Always exclude login/public routes from auth guards
4. **Error Handling**: Wrap guards in try-catch for production apps
5. **Performance**: Cache expensive guard operations
6. **Testing**: Write integration tests for route protection

## Advantages vs Type-Safe Routes

**Traditional Routes Advantages:**
- Simpler setup for existing projects
- No code generation required
- Familiar Go Router syntax
- Easy to migrate existing routes

**Type-Safe Routes Advantages:**
- Compile-time route safety
- Better IDE support
- Cleaner guard integration
- Reduced runtime errors

Choose the approach that best fits your project's needs and team preferences.

## Next Steps

- 🔄 Compare with [Type-Safe Routes](/guides/type-safe-routes/)
- 🧩 Learn about [Guard Combinations](/guides/guard-combinations/)
- ⚙️ Explore [Conditional Guards](/guides/conditional-guards/)
- 📋 Review [Best Practices](/guides/best-practices/)
