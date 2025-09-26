---
title: Creating Guards
description: Learn how to create custom guards for route protection
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

Creating custom guards is the foundation of the Go Router Guards system. This guide will teach you how to build effective, reusable guards for your application.

## Understanding Guards

A guard is a middleware-style function that decides whether navigation should:
- **Continue** to the intended destination
- **Redirect** to a different route
- **Block** navigation entirely

## Basic Guard Structure

<Steps>

1. **Extend the Base Class**

   Choose the appropriate base class for your guard:

   <Tabs>
     <TabItem label="Go Router Guard">
       ```dart
       class MyGuard extends GoRouterGuard {
         @override
         FutureOr<void> onGoRouterNavigation(
           NavigationResolver resolver,
           BuildContext context,
           GoRouterState state,
         ) async {
           // Your guard logic here
         }
       }
       ```
     </TabItem>
     
     <TabItem label="Framework Agnostic Guard">
       ```dart
       class MyGuard extends RouteGuard {
         @override
         FutureOr<void> onNavigation(
           NavigationResolver resolver,
           Object context,
           Object state,
         ) async {
           // Your guard logic here
         }
       }
       ```
     </TabItem>
   </Tabs>

2. **Implement Guard Logic**

   Use the resolver to control navigation:

   ```dart
   @override
   FutureOr<void> onGoRouterNavigation(
     NavigationResolver resolver,
     BuildContext context,
     GoRouterState state,
   ) async {
     if (await shouldAllow()) {
       resolver.next();           // Allow navigation
     } else if (shouldRedirect()) {
       resolver.redirect('/path'); // Redirect elsewhere
     } else {
       resolver.block();          // Block navigation
     }
   }
   ```

3. **Handle Async Operations**

   Guards support asynchronous operations:

   ```dart
   @override
   FutureOr<void> onGoRouterNavigation(
     NavigationResolver resolver,
     BuildContext context,
     GoRouterState state,
   ) async {
     // Async database call
     final user = await userRepository.getCurrentUser();
     
     // Async API call
     final permissions = await apiService.getPermissions(user.id);
     
     if (permissions.contains('access_feature')) {
       resolver.next();
     } else {
       resolver.redirect('/unauthorized');
     }
   }
   ```

</Steps>

## Common Guard Patterns

### Authentication Guard

```dart
class AuthGuard extends GoRouterGuard {
  const AuthGuard();

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Access your authentication state
    final authState = context.read<AuthBloc>().state;
    
    switch (authState) {
      case AuthAuthenticated():
        resolver.next();
      case AuthUnauthenticated():
        resolver.redirect('/login');
      case AuthLoading():
        // Wait for auth state or redirect to loading page
        resolver.redirect('/loading');
    }
  }
}
```

### Role-Based Guard

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
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }
    
    final hasRequiredRole = requiredRoles.any(user.roles.contains);
    
    if (hasRequiredRole) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}
```

### Permission Guard

```dart
class PermissionGuard extends GoRouterGuard {
  const PermissionGuard(this.requiredPermissions);
  
  final List<String> requiredPermissions;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final permissions = await permissionService.getUserPermissions();
    
    final hasAllPermissions = requiredPermissions.every(
      permissions.contains,
    );
    
    if (hasAllPermissions) {
      resolver.next();
    } else {
      resolver.block(); // No redirect, just block
    }
  }
}
```

### Feature Flag Guard

```dart
class FeatureFlagGuard extends GoRouterGuard {
  const FeatureFlagGuard(this.flagName);
  
  final String flagName;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isEnabled = await featureFlagService.isEnabled(flagName);
    
    if (isEnabled) {
      resolver.next();
    } else {
      resolver.redirect('/feature-not-available');
    }
  }
}
```

### Subscription Guard

```dart
class SubscriptionGuard extends GoRouterGuard {
  const SubscriptionGuard({this.requiredTier = 'premium'});
  
  final String requiredTier;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final subscription = await subscriptionService.getCurrentSubscription();
    
    if (subscription == null) {
      resolver.redirect('/subscribe');
    } else if (subscription.tier != requiredTier) {
      resolver.redirect('/upgrade-subscription');
    } else if (subscription.isExpired) {
      resolver.redirect('/subscription-expired');
    } else {
      resolver.next();
    }
  }
}
```

## Advanced Guard Techniques

### Parameterized Guards

Create guards that accept configuration:

```dart
class TimeBasedGuard extends GoRouterGuard {
  const TimeBasedGuard({
    required this.allowedHours,
    this.timezone = 'UTC',
  });
  
  final List<int> allowedHours; // e.g., [9, 10, 11, 12, 13, 14, 15, 16, 17]
  final String timezone;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final now = DateTime.now().toUtc();
    final currentHour = now.hour;
    
    if (allowedHours.contains(currentHour)) {
      resolver.next();
    } else {
      resolver.redirect('/outside-business-hours');
    }
  }
}
```

### Stateful Guards

Guards that maintain state across navigation events:

```dart
class AttemptLimitGuard extends GoRouterGuard {
  AttemptLimitGuard({required this.maxAttempts});
  
  final int maxAttempts;
  int _attemptCount = 0;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    _attemptCount++;
    
    if (_attemptCount > maxAttempts) {
      resolver.redirect('/too-many-attempts');
    } else {
      resolver.next();
    }
  }
  
  void resetAttempts() {
    _attemptCount = 0;
  }
}
```

### Context-Aware Guards

Guards that use route context for decision making:

```dart
class ResourceOwnerGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Extract resource ID from route parameters
    final resourceId = state.pathParameters['id'];
    if (resourceId == null) {
      resolver.redirect('/not-found');
      return;
    }
    
    // Get current user
    final currentUser = context.read<UserCubit>().state.user;
    if (currentUser == null) {
      resolver.redirect('/login');
      return;
    }
    
    // Check if user owns the resource
    final resource = await resourceService.getResource(resourceId);
    if (resource.ownerId == currentUser.id || currentUser.isAdmin) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}
```

## Error Handling

### Graceful Degradation

```dart
class SafeGuard extends GoRouterGuard {
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
        resolver.redirect('/fallback');
      }
    } catch (error, stackTrace) {
      // Log the error
      logger.error('Guard failed', error: error, stackTrace: stackTrace);
      
      // Gracefully degrade - allow navigation to prevent app breakage
      resolver.next();
    }
  }
}
```

### Timeout Handling

```dart
class TimeoutGuard extends GoRouterGuard {
  const TimeoutGuard({this.timeout = const Duration(seconds: 5)});
  
  final Duration timeout;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final result = await slowOperation().timeout(timeout);
      
      if (result.isSuccess) {
        resolver.next();
      } else {
        resolver.redirect('/error');
      }
    } on TimeoutException {
      // Handle timeout
      resolver.redirect('/timeout');
    } catch (error) {
      resolver.redirect('/error');
    }
  }
}
```

## Testing Guards

### Unit Testing

```dart
void main() {
  group('AuthGuard', () {
    late AuthGuard guard;
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
      guard = AuthGuard(authService: authService);
    });

    test('allows navigation when authenticated', () async {
      // Arrange
      when(() => authService.isAuthenticated())
          .thenAnswer((_) async => true);

      // Act
      final result = await guard.executeWithResolver(
        MockBuildContext(),
        MockGoRouterState(),
      );

      // Assert
      expect(result.continueNavigation, isTrue);
      expect(result.redirectPath, isNull);
    });

    test('redirects to login when not authenticated', () async {
      // Arrange
      when(() => authService.isAuthenticated())
          .thenAnswer((_) async => false);

      // Act
      final result = await guard.executeWithResolver(
        MockBuildContext(),
        MockGoRouterState(),
      );

      // Assert
      expect(result.continueNavigation, isFalse);
      expect(result.redirectPath, '/login');
    });
  });
}
```

### Integration Testing

```dart
void main() {
  testWidgets('Protected route redirects unauthenticated users', (tester) async {
    // Arrange
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

    // Act - try to navigate to protected route
    await tester.tap(find.text('Go to Protected'));
    await tester.pumpAndSettle();

    // Assert - should be on login screen
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Protected Content'), findsNothing);
  });
}
```

## Best Practices

### 1. Single Responsibility

Each guard should have one clear purpose:

```dart
// ✅ Good - single responsibility
class AuthGuard extends GoRouterGuard { /* ... */ }
class RoleGuard extends GoRouterGuard { /* ... */ }

// ❌ Bad - multiple responsibilities
class AuthAndRoleGuard extends GoRouterGuard { /* ... */ }
```

### 2. Composition Over Complexity

Use guard combinations instead of complex single guards:

```dart
// ✅ Good - composed guards
final adminGuard = Guards.all([
  AuthGuard(),
  RoleGuard(['admin']),
  PermissionGuard(['admin_access']),
]);

// ❌ Bad - complex single guard
class ComplexAdminGuard extends GoRouterGuard {
  // Handles auth, roles, and permissions in one guard
}
```

### 3. Meaningful Names

Use descriptive names that indicate the guard's purpose:

```dart
// ✅ Good
class SubscriptionRequiredGuard { /* ... */ }
class BusinessHoursOnlyGuard { /* ... */ }
class ResourceOwnerGuard { /* ... */ }

// ❌ Bad
class Guard1 { /* ... */ }
class MyGuard { /* ... */ }
class CheckGuard { /* ... */ }
```

### 4. Error Handling

Always handle potential failures:

```dart
@override
FutureOr<void> onGoRouterNavigation(
  NavigationResolver resolver,
  BuildContext context,
  GoRouterState state,
) async {
  try {
    final result = await checkCondition();
    if (result) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  } catch (error) {
    // Log error and gracefully degrade
    logger.error('Guard failed: $error');
    resolver.next(); // or resolver.redirect('/error');
  }
}
```

### 5. Performance Considerations

- Cache expensive operations when possible
- Use timeouts for network calls
- Avoid blocking the UI thread

```dart
class CachedAuthGuard extends GoRouterGuard {
  static DateTime? _lastCheck;
  static bool? _lastResult;
  static const cacheDuration = Duration(minutes: 5);

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
        now.difference(_lastCheck!) < cacheDuration) {
      if (_lastResult!) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
      return;
    }
    
    // Perform fresh check
    final isAuthenticated = await authService.check();
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

## Common Pitfalls

### 1. Infinite Redirects

Avoid redirecting to routes that have the same guard:

```dart
// ❌ Bad - can cause infinite loop
class AuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(/* ... */) async {
    if (!isAuthenticated) {
      resolver.redirect('/login'); // If /login also has AuthGuard
    }
  }
}

// ✅ Good - use conditional guards or unguarded routes
final router = GoRouter(
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: ['/login', '/register'],
    ),
  ),
);
```

### 2. Forgetting Async/Await

```dart
// ❌ Bad - missing await
@override
FutureOr<void> onGoRouterNavigation(/* ... */) {
  final result = asyncOperation(); // Missing await
  if (result) resolver.next(); // This won't work as expected
}

// ✅ Good
@override
FutureOr<void> onGoRouterNavigation(/* ... */) async {
  final result = await asyncOperation();
  if (result) resolver.next();
}
```

### 3. Not Handling All Cases

```dart
// ❌ Bad - missing else case
@override
FutureOr<void> onGoRouterNavigation(/* ... */) async {
  if (condition) {
    resolver.next();
  }
  // What happens if condition is false?
}

// ✅ Good
@override
FutureOr<void> onGoRouterNavigation(/* ... */) async {
  if (condition) {
    resolver.next();
  } else {
    resolver.redirect('/fallback');
  }
}
```

## Next Steps

Now that you understand how to create guards:

1. 🎯 Learn about [Type-Safe Routes](/guides/type-safe-routes/)
2. 🔄 Explore [Traditional Routes](/guides/traditional-routes/) 
3. 🧩 Discover [Guard Combinations](/guides/guard-combinations/)
4. 📖 See [Examples](/examples/authentication/) for real-world usage
