---
title: Best Practices
description: Essential best practices for implementing Go Router Guards effectively and safely
---

import { Tabs, TabItem } from '@astrojs/starlight/components';

Following these best practices will help you build robust, maintainable, and performant guard systems that enhance your application's security and user experience.

## Guard Design Principles

### 1. Single Responsibility Principle

Each guard should have one clear, focused responsibility:

<Tabs>
  <TabItem label="✅ Good">
```dart
// Each guard has a single, clear purpose
class AuthGuard extends GoRouterGuard { /* Authentication only */ }
class RoleGuard extends GoRouterGuard { /* Role checking only */ }
class SubscriptionGuard extends GoRouterGuard { /* Subscription only */ }

// Combine for complex scenarios
final adminGuard = Guards.all([
  AuthGuard(),
  RoleGuard(['admin']),
]);
```
  </TabItem>
  
  <TabItem label="❌ Bad">
```dart
// Single guard doing too many things
class MegaGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(...) async {
    // Check authentication
    if (!await isAuthenticated()) return redirect('/login');
    
    // Check role
    if (!await hasRole('admin')) return redirect('/unauthorized');
    
    // Check subscription
    if (!await hasSubscription()) return redirect('/subscribe');
    
    // Check feature flags
    if (!await featureEnabled()) return redirect('/not-available');
    
    // ... too much responsibility
  }
}
```
  </TabItem>
</Tabs>

### 2. Composition Over Inheritance

Use guard combinations instead of complex inheritance hierarchies:

<Tabs>
  <TabItem label="✅ Good">
```dart
// Composable guards
class AppGuards {
  static RouteGuard get authenticated => AuthGuard();
  
  static RouteGuard get admin => Guards.all([
    authenticated,
    RoleGuard(['admin']),
  ]);
  
  static RouteGuard get premiumUser => Guards.all([
    authenticated,
    Guards.anyOf([
      SubscriptionGuard(['premium']),
      RoleGuard(['staff', 'admin']),
    ]),
  ]);
}
```
  </TabItem>
  
  <TabItem label="❌ Bad">
```dart
// Complex inheritance
abstract class BaseGuard extends GoRouterGuard { /* ... */ }
abstract class AuthenticatedGuard extends BaseGuard { /* ... */ }
abstract class RoleBasedGuard extends AuthenticatedGuard { /* ... */ }
class AdminGuard extends RoleBasedGuard { /* ... */ }
class ModeratorGuard extends RoleBasedGuard { /* ... */ }
```
  </TabItem>
</Tabs>

## Error Handling

### 1. Graceful Degradation

Always handle guard failures gracefully:

```dart
class SafeAuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final isAuthenticated = await authService.isAuthenticated();
      if (isAuthenticated) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } catch (error) {
      // Log error but don't break user experience
      logger.error('Auth check failed', error: error);
      
      // Graceful degradation strategy
      if (error is NetworkException) {
        // Offline mode - allow with warning
        _showOfflineWarning(context);
        resolver.next();
      } else {
        // Unknown error - redirect to safe page
        resolver.redirect('/error?source=auth');
      }
    }
  }
}
```

### 2. Timeout Handling

Set appropriate timeouts for async operations:

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
      final result = await authService
          .validateToken()
          .timeout(timeout);
      
      if (result.isValid) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } on TimeoutException {
      logger.warning('Auth timeout, allowing navigation');
      resolver.next(); // Graceful degradation
    } catch (error) {
      logger.error('Auth error: $error');
      resolver.redirect('/login');
    }
  }
}
```

### 3. Circuit Breaker Pattern

Prevent cascading failures with circuit breakers:

```dart
class CircuitBreakerGuard extends GoRouterGuard {
  static int _failureCount = 0;
  static DateTime? _lastFailure;
  static const int _failureThreshold = 5;
  static const Duration _recoveryTime = Duration(minutes: 5);

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Check if circuit breaker is open
    if (_isCircuitOpen()) {
      logger.warning('Circuit breaker open, allowing navigation');
      resolver.next();
      return;
    }

    try {
      final result = await externalAuthService.validate();
      if (result.isValid) {
        _resetCircuit();
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } catch (error) {
      _recordFailure();
      logger.error('Auth service failed: $error');
      resolver.next(); // Fail open
    }
  }

  bool _isCircuitOpen() {
    if (_failureCount >= _failureThreshold && _lastFailure != null) {
      return DateTime.now().difference(_lastFailure!) < _recoveryTime;
    }
    return false;
  }

  void _recordFailure() {
    _failureCount++;
    _lastFailure = DateTime.now();
  }

  void _resetCircuit() {
    _failureCount = 0;
    _lastFailure = null;
  }
}
```

## Performance Optimization

### 1. Caching Strategies

Cache expensive operations appropriately:

```dart
class CachedGuard extends GoRouterGuard {
  static final Map<String, CacheEntry> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userId = getCurrentUserId(context);
    final cacheKey = 'auth_$userId';
    
    // Check cache first
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      if (cached.value) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
      return;
    }

    // Perform fresh check
    try {
      final isAuthenticated = await authService.isAuthenticated();
      _cache[cacheKey] = CacheEntry(isAuthenticated, DateTime.now());
      
      if (isAuthenticated) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } catch (error) {
      // Don't cache errors
      logger.error('Auth check failed: $error');
      resolver.redirect('/login');
    }
  }
}

class CacheEntry {
  final bool value;
  final DateTime timestamp;
  
  CacheEntry(this.value, this.timestamp);
  
  bool get isExpired => 
      DateTime.now().difference(timestamp) > CachedGuard._cacheExpiry;
}
```

### 2. Optimize Guard Order

Order guards by execution speed and likelihood of failure:

```dart
// ✅ Good - fast checks first
final optimizedGuard = Guards.all([
  LocalStateGuard(),      // Fastest - in-memory check
  CachedAuthGuard(),      // Fast - cached result
  DatabaseGuard(),        // Medium - local database
  ExternalAPIGuard(),     // Slowest - network call
]);

// ❌ Bad - slow checks first
final inefficientGuard = Guards.all([
  ExternalAPIGuard(),     // Slowest first
  DatabaseGuard(),        // Medium
  LocalStateGuard(),      // Fastest last (may not execute)
]);
```

### 3. Lazy Loading

Load heavy dependencies only when needed:

```dart
class LazyGuard extends GoRouterGuard {
  AuthService? _authService;
  
  AuthService get authService {
    return _authService ??= GetIt.instance.get<AuthService>();
  }

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Service is only loaded when guard actually executes
    final isAuthenticated = await authService.isAuthenticated();
    // ... rest of guard logic
  }
}
```

## Security Best Practices

### 1. Fail Securely

When in doubt, fail to the secure state:

```dart
class SecureGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final result = await authService.validate();
      if (result.isAuthenticated && result.hasPermission) {
        resolver.next();
      } else {
        // Explicit denial
        resolver.redirect('/unauthorized');
      }
    } catch (error) {
      // When in doubt, deny access
      logger.error('Auth validation failed: $error');
      resolver.redirect('/login');
    }
  }
}
```

### 2. Validate All Inputs

Always validate route parameters and user input:

```dart
class InputValidationGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userId = state.pathParameters['userId'];
    
    // Validate user ID format
    if (userId == null || !_isValidUserId(userId)) {
      resolver.redirect('/invalid-user');
      return;
    }
    
    // Check if user exists and current user has access
    final hasAccess = await userService.hasAccess(
      getCurrentUserId(context),
      userId,
    );
    
    if (hasAccess) {
      resolver.next();
    } else {
      resolver.redirect('/access-denied');
    }
  }

  bool _isValidUserId(String userId) {
    // Validate format (e.g., UUID, alphanumeric, etc.)
    return RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(userId) && 
           userId.length <= 50;
  }
}
```

### 3. Principle of Least Privilege

Grant the minimum necessary access:

```dart
class MinimalAccessGuard extends GoRouterGuard {
  const MinimalAccessGuard({required this.requiredPermissions});
  
  final List<String> requiredPermissions;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userPermissions = await getUserPermissions(context);
    
    // Check if user has ALL required permissions
    final hasAllPermissions = requiredPermissions.every(
      userPermissions.contains,
    );
    
    if (hasAllPermissions) {
      resolver.next();
    } else {
      // Log access attempt for security monitoring
      securityLogger.logAccessAttempt(
        userId: getCurrentUserId(context),
        path: state.uri.path,
        missingPermissions: requiredPermissions
            .where((p) => !userPermissions.contains(p))
            .toList(),
      );
      
      resolver.redirect('/insufficient-permissions');
    }
  }
}
```

## Testing Strategies

### 1. Comprehensive Test Coverage

Test all guard paths and edge cases:

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
      when(() => authService.isAuthenticated())
          .thenAnswer((_) async => true);

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      expect(result.continueNavigation, isTrue);
    });

    test('redirects when not authenticated', () async {
      when(() => authService.isAuthenticated())
          .thenAnswer((_) async => false);

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      expect(result.continueNavigation, isFalse);
      expect(result.redirectPath, '/login');
    });

    test('handles auth service errors gracefully', () async {
      when(() => authService.isAuthenticated())
          .thenThrow(Exception('Network error'));

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      // Should fail securely
      expect(result.continueNavigation, isFalse);
    });

    test('handles timeout scenarios', () async {
      when(() => authService.isAuthenticated())
          .thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 10));
        return true;
      });

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      // Should timeout and handle gracefully
      expect(result.continueNavigation, isFalse);
    });
  });
}
```

### 2. Integration Testing

Test guards in real navigation scenarios:

```dart
void main() {
  testWidgets('Auth flow integration test', (tester) async {
    final mockAuth = MockAuthService();
    
    await tester.pumpWidget(
      MyApp(authService: mockAuth),
    );

    // Start unauthenticated
    when(() => mockAuth.isAuthenticated()).thenReturn(false);

    // Try to access protected route
    await tester.tap(find.text('Go to Dashboard'));
    await tester.pumpAndSettle();

    // Should be redirected to login
    expect(find.text('Login'), findsOneWidget);

    // Login
    when(() => mockAuth.isAuthenticated()).thenReturn(true);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Should now be on dashboard
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

## Code Organization

### 1. Structured Guard Organization

Organize guards logically:

```
lib/
  guards/
    core/
      auth_guard.dart
      permission_guard.dart
    specialized/
      subscription_guard.dart
      feature_flag_guard.dart
    combinations/
      app_guards.dart
      admin_guards.dart
```

### 2. Guard Factories

Use factories for common guard configurations:

```dart
class GuardFactory {
  static RouteGuard createUserGuard() => Guards.all([
    AuthGuard(),
    RoleGuard(['user']),
  ]);

  static RouteGuard createAdminGuard() => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
    PermissionGuard(['admin_access']),
  ]);

  static RouteGuard createPremiumGuard() => Guards.all([
    AuthGuard(),
    Guards.anyOf([
      SubscriptionGuard(['premium', 'enterprise']),
      RoleGuard(['staff', 'admin']),
    ]),
  ]);

  static RouteGuard createConditionalAuth({
    required List<String> excludedPaths,
  }) => ConditionalGuard(
    guard: AuthGuard(),
    excludedPaths: excludedPaths,
  );
}
```

### 3. Configuration Management

Centralize guard configuration:

```dart
class GuardConfig {
  static const List<String> publicPaths = [
    '/',
    '/login',
    '/register',
    '/forgot-password',
    '/help',
  ];

  static const List<String> adminPaths = [
    '/admin',
    '/management',
    '/system',
  ];

  static const Duration guardTimeout = Duration(seconds: 5);
  static const Duration cacheExpiry = Duration(minutes: 5);
  
  static const Map<String, List<String>> rolePermissions = {
    'admin': ['*'],
    'moderator': ['read', 'write', 'moderate'],
    'user': ['read'],
  };
}
```

## Monitoring and Debugging

### 1. Comprehensive Logging

Implement proper logging for guards:

```dart
class LoggedGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final startTime = DateTime.now();
    final path = state.uri.path;
    final userId = getCurrentUserId(context);

    logger.info('Guard execution started', extra: {
      'guard': runtimeType.toString(),
      'path': path,
      'userId': userId,
    });

    try {
      await _executeGuardLogic(resolver, context, state);
      
      final duration = DateTime.now().difference(startTime);
      logger.info('Guard execution completed', extra: {
        'guard': runtimeType.toString(),
        'path': path,
        'userId': userId,
        'duration': duration.inMilliseconds,
        'result': resolver.result,
      });
    } catch (error, stackTrace) {
      logger.error('Guard execution failed', 
        error: error, 
        stackTrace: stackTrace,
        extra: {
          'guard': runtimeType.toString(),
          'path': path,
          'userId': userId,
        },
      );
      rethrow;
    }
  }
}
```

### 2. Metrics Collection

Track guard performance and success rates:

```dart
class MetricsGuard extends GoRouterGuard {
  static final Map<String, GuardMetrics> _metrics = {};

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final guardName = runtimeType.toString();
    final startTime = DateTime.now();

    try {
      await _executeGuardLogic(resolver, context, state);
      _recordSuccess(guardName, startTime);
    } catch (error) {
      _recordFailure(guardName, startTime, error);
      rethrow;
    }
  }

  void _recordSuccess(String guardName, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    _metrics.putIfAbsent(guardName, () => GuardMetrics())
      ..recordSuccess(duration);
  }

  void _recordFailure(String guardName, DateTime startTime, Object error) {
    final duration = DateTime.now().difference(startTime);
    _metrics.putIfAbsent(guardName, () => GuardMetrics())
      ..recordFailure(duration, error);
  }
}
```

## Documentation

### 1. Clear Guard Documentation

Document guard behavior and requirements:

```dart
/// Protects routes that require premium subscription.
/// 
/// This guard checks if the current user has an active premium subscription.
/// Users without a subscription are redirected to the subscription page.
/// 
/// **Requirements:**
/// - User must be authenticated (use with [AuthGuard])
/// - User must have active subscription with tier 'premium' or 'enterprise'
/// 
/// **Redirects:**
/// - `/login` - if user is not authenticated
/// - `/subscribe` - if user has no subscription
/// - `/upgrade` - if user has basic subscription
/// 
/// **Usage:**
/// ```dart
/// // Type-safe route
/// @override
/// RouteGuard get guards => Guards.all([
///   AuthGuard(),
///   SubscriptionGuard(['premium']),
/// ]);
/// 
/// // Traditional route
/// redirect: RouteGuardUtils.createGuardRedirect(
///   Guards.all([AuthGuard(), SubscriptionGuard(['premium'])]),
/// )
/// ```
class SubscriptionGuard extends GoRouterGuard {
  // Implementation...
}
```

### 2. Architecture Documentation

Document your guard architecture and patterns:

```dart
/// Application Guard Architecture
/// 
/// Our guard system follows a layered approach:
/// 
/// 1. **Authentication Layer** - [AuthGuard]
///    - Verifies user is logged in
///    - Redirects to login if not authenticated
/// 
/// 2. **Authorization Layer** - [RoleGuard], [PermissionGuard]
///    - Checks user roles and permissions
///    - Redirects to unauthorized page if insufficient access
/// 
/// 3. **Business Logic Layer** - [SubscriptionGuard], [FeatureFlagGuard]
///    - Enforces business rules and feature access
///    - Redirects to upgrade/feature pages as needed
/// 
/// Guards are combined using [Guards] utility:
/// - [Guards.all] - All guards must pass (AND)
/// - [Guards.anyOf] - Any guard can pass (OR)
/// - [Guards.oneOf] - Exactly one guard must pass (XOR)
class AppGuards {
  // Guard factory methods...
}
```

Following these best practices will help you build a robust, secure, and maintainable guard system that enhances your application's security while providing a great user experience.

## Key Takeaways

1. **🎯 Single Responsibility**: One guard, one concern
2. **🛡️ Fail Securely**: When in doubt, deny access
3. **⚡ Performance Matters**: Cache, optimize order, use timeouts
4. **🧪 Test Thoroughly**: Cover all paths and edge cases
5. **📊 Monitor & Log**: Track performance and failures
6. **📚 Document Well**: Clear documentation helps maintainability
7. **🔄 Graceful Degradation**: Handle errors without breaking UX
8. **🏗️ Compose Guards**: Use combinations over complex single guards
