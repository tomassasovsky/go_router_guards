---
title: route_guards Package
description: Core framework-agnostic guard system for navigation protection
---

import { Card, CardGrid } from '@astrojs/starlight/components';

<div class="package-badge">Core Package</div>

# route_guards

The `route_guards` package provides the core, framework-agnostic foundation for creating navigation guards. It defines the basic abstractions and utilities that can work with any routing system.

## Overview

This package contains the fundamental building blocks for creating route protection systems:

- **RouteGuard**: Base class for creating custom guards
- **NavigationResolver**: Controls navigation flow with middleware pattern
- **Guards**: Utility class for combining and composing guards
- **GuardResult**: Represents the outcome of guard execution

## Key Features

<CardGrid>
  <Card title="🔧 Framework Agnostic" icon="gear">
    Works with any router or navigation system, not tied to specific frameworks.
  </Card>
  
  <Card title="🧩 Composable Guards" icon="puzzle">
    Combine multiple guards with logical operators (all, any, one).
  </Card>
  
  <Card title="⚡ Async Support" icon="lightning">
    Full support for asynchronous guard operations.
  </Card>
  
  <Card title="🎯 Resolver Pattern" icon="target">
    Clean middleware-style control flow with NavigationResolver.
  </Card>
</CardGrid>

## Installation

```bash
dart pub add route_guards
```

## Core Classes

### RouteGuard

The base class for all guards. Extend this to create custom protection logic:

```dart
abstract class RouteGuard {
  const RouteGuard();

  /// Override this method to implement guard logic
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  );
}
```

**Example Implementation:**

```dart
class AuthGuard extends RouteGuard {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    final isAuthenticated = await checkAuth();
    if (isAuthenticated) {
      resolver.next(); // Allow navigation
    } else {
      resolver.redirect('/login'); // Redirect to login
    }
  }
}
```

### NavigationResolver

Controls navigation flow within guards. Provides three actions:

```dart
class NavigationResolver {
  /// Allow navigation to continue
  void next();
  
  /// Redirect to a different path
  void redirect(String path);
  
  /// Block navigation entirely
  void block();
}
```

**Usage Pattern:**

```dart
@override
FutureOr<void> onNavigation(
  NavigationResolver resolver,
  Object context,
  Object state,
) async {
  if (await isAllowed()) {
    resolver.next();
  } else if (shouldRedirect()) {
    resolver.redirect('/alternative-path');
  } else {
    resolver.block();
  }
}
```

### Guards Utility

Combines multiple guards with logical operations:

```dart
class Guards {
  /// All guards must pass
  static RouteGuard all(List<RouteGuard> guards);
  
  /// At least one guard must pass
  static RouteGuard anyOf(List<RouteGuard> guards);
  
  /// Exactly one guard must pass
  static RouteGuard oneOf(List<RouteGuard> guards);
}
```

**Examples:**

```dart
// All guards must pass (AND logic)
final adminGuard = Guards.all([
  AuthGuard(),
  RoleGuard(['admin']),
  PermissionGuard(['read_users']),
]);

// Any guard can pass (OR logic)
final memberGuard = Guards.anyOf([
  SubscriptionGuard(),
  TrialGuard(),
  AdminGuard(),
]);

// Exactly one guard must pass (XOR logic)
final exclusiveGuard = Guards.oneOf([
  DevModeGuard(),
  ProductionAccessGuard(),
]);
```

### GuardResult

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

## Advanced Usage

### Custom Guard Combinations

Create custom guard combinations for complex scenarios:

```dart
class ConditionalGuard extends RouteGuard {
  const ConditionalGuard({
    required this.guard,
    this.includedPaths = const [],
    this.excludedPaths = const [],
  });

  final RouteGuard guard;
  final List<String> includedPaths;
  final List<String> excludedPaths;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    final path = _extractPath(state);
    
    // Check if path should be excluded
    if (excludedPaths.any((excluded) => path.startsWith(excluded))) {
      resolver.next();
      return;
    }
    
    // Check if path should be included
    if (includedPaths.isNotEmpty &&
        !includedPaths.any((included) => path.startsWith(included))) {
      resolver.next();
      return;
    }
    
    // Apply the guard
    await guard.onNavigation(resolver, context, state);
  }
}
```

### Stateful Guards

Create guards that maintain state across navigation events:

```dart
class RateLimitGuard extends RouteGuard {
  RateLimitGuard({required this.maxAttempts, required this.timeWindow});
  
  final int maxAttempts;
  final Duration timeWindow;
  final Map<String, List<DateTime>> _attempts = {};

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) {
    final userId = _extractUserId(context);
    final now = DateTime.now();
    
    // Clean old attempts
    _attempts[userId]?.removeWhere(
      (attempt) => now.difference(attempt) > timeWindow,
    );
    
    final attempts = _attempts[userId] ?? [];
    
    if (attempts.length >= maxAttempts) {
      resolver.redirect('/rate-limited');
    } else {
      attempts.add(now);
      _attempts[userId] = attempts;
      resolver.next();
    }
  }
}
```

### Dependency Injection Support

Integrate with dependency injection systems:

```dart
class ServiceGuard extends RouteGuard {
  const ServiceGuard({
    required this.authService,
    required this.userService,
  });
  
  final AuthService authService;
  final UserService userService;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    final user = await authService.getCurrentUser();
    if (user == null) {
      resolver.redirect('/login');
      return;
    }
    
    final permissions = await userService.getPermissions(user.id);
    if (permissions.contains('access_feature')) {
      resolver.next();
    } else {
      resolver.block();
    }
  }
}
```

## Testing Guards

The package provides excellent testing support:

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
      when(() => authService.isAuthenticated()).thenAnswer((_) async => true);
      
      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );
      
      expect(result.continueNavigation, isTrue);
    });

    test('redirects when not authenticated', () async {
      when(() => authService.isAuthenticated()).thenAnswer((_) async => false);
      
      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );
      
      expect(result.continueNavigation, isFalse);
      expect(result.redirectPath, '/login');
    });
  });
}
```

## Error Handling

Handle errors gracefully in your guards:

```dart
class SafeAuthGuard extends RouteGuard {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    try {
      final isAuthenticated = await checkAuth();
      if (isAuthenticated) {
        resolver.next();
      } else {
        resolver.redirect('/login');
      }
    } catch (error) {
      // Log error and allow navigation to prevent app breakage
      print('Auth check failed: $error');
      resolver.next();
    }
  }
}
```

## Best Practices

1. **Keep Guards Simple**: Each guard should have a single responsibility
2. **Handle Errors**: Always handle potential exceptions
3. **Use Composition**: Combine simple guards instead of creating complex ones
4. **Test Thoroughly**: Write tests for all guard logic and edge cases
5. **Performance**: Avoid expensive operations in guards when possible
6. **Logging**: Add logging for debugging and monitoring

## Framework Integrations

While this package is framework-agnostic, it's designed to work with:

- **go_router_guards**: Official Go Router integration
- **Custom integrations**: Build your own router integration

## API Reference

### Classes

| Class | Description |
|-------|-------------|
| `RouteGuard` | Base class for all guards |
| `NavigationResolver` | Controls navigation flow |
| `GuardResult` | Result of guard execution |
| `Guards` | Utility for combining guards |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `Guards.all(guards)` | `RouteGuard` | All guards must pass |
| `Guards.anyOf(guards)` | `RouteGuard` | Any guard can pass |
| `Guards.oneOf(guards)` | `RouteGuard` | Exactly one guard must pass |
| `resolver.next()` | `void` | Allow navigation |
| `resolver.redirect(path)` | `void` | Redirect to path |
| `resolver.block()` | `void` | Block navigation |

## Migration Guide

### From v0.x to v1.x

- `onNavigation` now takes `NavigationResolver` as first parameter
- `GuardResult` is now created through factory constructors
- Async support is now built-in

## Contributing

The `route_guards` package welcomes contributions! See the [contribution guide](https://github.com/tomassasovsky/go_router_guards/blob/main/CONTRIBUTING.md) for details.
