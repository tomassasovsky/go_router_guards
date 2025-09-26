---
title: Conditional Guards
description: Learn how to apply guards conditionally based on paths, parameters, and runtime conditions
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

Conditional guards allow you to apply protection selectively based on various criteria such as paths, route parameters, user state, or other runtime conditions.

## ConditionalGuard

The built-in `ConditionalGuard` applies guards based on path patterns:

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

## Path-Based Conditions

### Excluding Paths

Protect all routes except specific ones:

```dart
final router = GoRouter(
  routes: $appRoutes,
  redirect: RouteGuardUtils.createGuardRedirect(
    ConditionalGuard(
      guard: AuthGuard(),
      excludedPaths: [
        '/',              // Home page
        '/login',         // Login page
        '/register',      // Registration page
        '/forgot-password', // Password reset
        '/public',        // Public content
        '/help',          // Help pages
      ],
    ),
  ),
);
```

### Including Specific Paths

Protect only specific routes:

```dart
final premiumGuard = ConditionalGuard(
  guard: SubscriptionGuard(['premium', 'enterprise']),
  includedPaths: [
    '/premium',         // Premium features
    '/advanced',        // Advanced tools
    '/analytics',       // Analytics dashboard
    '/api-access',      // API access
  ],
);
```

### Path Patterns

Use pattern matching for flexible path conditions:

```dart
class PatternConditionalGuard extends GoRouterGuard {
  const PatternConditionalGuard({
    required this.guard,
    this.includePatterns = const [],
    this.excludePatterns = const [],
  });

  final RouteGuard guard;
  final List<String> includePatterns;
  final List<String> excludePatterns;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;
    
    // Check exclusion patterns first
    for (final pattern in excludePatterns) {
      if (_matchesPattern(path, pattern)) {
        resolver.next();
        return;
      }
    }
    
    // Check inclusion patterns
    if (includePatterns.isNotEmpty) {
      bool matches = false;
      for (final pattern in includePatterns) {
        if (_matchesPattern(path, pattern)) {
          matches = true;
          break;
        }
      }
      if (!matches) {
        resolver.next();
        return;
      }
    }
    
    // Apply the guard
    await guard.onNavigation(resolver, context, state);
  }

  bool _matchesPattern(String path, String pattern) {
    // Convert pattern to regex
    final regexPattern = pattern
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    return RegExp('^$regexPattern\$').hasMatch(path);
  }
}

// Usage
final patternGuard = PatternConditionalGuard(
  guard: AdminGuard(),
  includePatterns: [
    '/admin/*',         // All admin routes
    '/management/*',    // All management routes
    '/reports/*',       // All report routes
  ],
  excludePatterns: [
    '/admin/help',      // Admin help is public
    '/reports/public',  // Public reports
  ],
);
```

## Parameter-Based Conditions

### Route Parameters

Create guards that check route parameters:

```dart
class ParameterConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userId = state.pathParameters['userId'];
    final currentUser = context.read<UserCubit>().state.user;
    
    // Users can access their own profile without additional checks
    if (userId == currentUser?.id) {
      resolver.next();
      return;
    }
    
    // Others need admin access
    if (currentUser?.hasRole('admin') == true) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}

// Route definition
@TypedGoRoute<UserProfileRoute>(path: '/user/:userId')
class UserProfileRoute extends GoRouteData with GuardedRoute {
  const UserProfileRoute({required this.userId});
  
  final String userId;

  @override
  RouteGuard get guards => ParameterConditionalGuard();
}
```

### Query Parameters

Check query parameters for conditional protection:

```dart
class FeatureConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final beta = state.uri.queryParameters['beta'];
    
    if (beta == 'true') {
      // Beta features require special access
      final guard = Guards.all([
        AuthGuard(),
        BetaTesterGuard(),
        FeatureFlagGuard('beta_features'),
      ]);
      await guard.onNavigation(resolver, context, state);
    } else {
      // Regular access
      await AuthGuard().onNavigation(resolver, context, state);
    }
  }
}
```

## User-State Conditions

### Role-Based Conditional Protection

Apply different guards based on user roles:

```dart
class RoleBasedConditionalGuard extends GoRouterGuard {
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
    
    RouteGuard guard;
    
    if (user.hasRole('admin')) {
      // Admins have full access
      guard = const _AllowGuard();
    } else if (user.hasRole('premium')) {
      // Premium users need subscription check
      guard = SubscriptionGuard();
    } else {
      // Regular users need multiple checks
      guard = Guards.all([
        UsageLimitGuard(),
        FeatureLimitGuard(),
      ]);
    }
    
    await guard.onNavigation(resolver, context, state);
  }
}
```

### Subscription-Based Conditions

Different protection levels based on subscription:

```dart
class SubscriptionConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final subscription = await subscriptionService.getCurrentSubscription();
    
    if (subscription == null) {
      resolver.redirect('/subscribe');
      return;
    }
    
    final path = state.uri.path;
    
    // Enterprise features
    if (path.startsWith('/enterprise')) {
      if (subscription.tier == 'enterprise') {
        resolver.next();
      } else {
        resolver.redirect('/upgrade-to-enterprise');
      }
      return;
    }
    
    // Premium features
    if (path.startsWith('/premium')) {
      if (['premium', 'enterprise'].contains(subscription.tier)) {
        resolver.next();
      } else {
        resolver.redirect('/upgrade-to-premium');
      }
      return;
    }
    
    // Basic features (all subscribers)
    resolver.next();
  }
}
```

## Time-Based Conditions

### Business Hours Guard

Protect routes during specific hours:

```dart
class BusinessHoursConditionalGuard extends GoRouterGuard {
  const BusinessHoursConditionalGuard({
    required this.guard,
    required this.businessHours,
    this.timezone = 'UTC',
  });

  final RouteGuard guard;
  final List<int> businessHours; // [9, 10, 11, ..., 17]
  final String timezone;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final now = DateTime.now().toUtc();
    final currentHour = now.hour;
    
    if (businessHours.contains(currentHour)) {
      // During business hours, apply the guard
      await guard.onNavigation(resolver, context, state);
    } else {
      // Outside business hours, block access
      resolver.redirect('/outside-business-hours');
    }
  }
}

// Usage
final businessHoursGuard = BusinessHoursConditionalGuard(
  guard: AdminGuard(),
  businessHours: [9, 10, 11, 12, 13, 14, 15, 16, 17], // 9 AM to 5 PM
);
```

### Maintenance Mode

Conditionally apply maintenance guards:

```dart
class MaintenanceConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final maintenanceMode = await configService.isMaintenanceMode();
    
    if (maintenanceMode) {
      final user = context.read<UserCubit>().state.user;
      
      // Allow staff during maintenance
      if (user?.hasRole('staff') == true) {
        resolver.next();
      } else {
        resolver.redirect('/maintenance');
      }
    } else {
      // Normal operation
      resolver.next();
    }
  }
}
```

## Feature Flag Conditions

### Dynamic Feature Protection

```dart
class FeatureFlagConditionalGuard extends GoRouterGuard {
  const FeatureFlagConditionalGuard({
    required this.featureFlags,
    required this.fallbackGuard,
  });

  final Map<String, RouteGuard> featureFlags;
  final RouteGuard fallbackGuard;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;
    
    // Check if this path has feature flag protection
    for (final entry in featureFlags.entries) {
      if (path.startsWith(entry.key)) {
        final isEnabled = await featureFlagService.isEnabled(entry.key);
        if (isEnabled) {
          await entry.value.onNavigation(resolver, context, state);
        } else {
          resolver.redirect('/feature-not-available');
        }
        return;
      }
    }
    
    // No feature flag, use fallback guard
    await fallbackGuard.onNavigation(resolver, context, state);
  }
}

// Usage
final featureGuard = FeatureFlagConditionalGuard(
  featureFlags: {
    '/beta': BetaTesterGuard(),
    '/experimental': InternalUserGuard(),
    '/ai-features': PremiumGuard(),
  },
  fallbackGuard: AuthGuard(),
);
```

## Device-Based Conditions

### Platform-Specific Guards

```dart
class PlatformConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;
    
    // Mobile-only features
    if (path.startsWith('/mobile') && !Platform.isMobile) {
      resolver.redirect('/not-available-on-desktop');
      return;
    }
    
    // Desktop-only features
    if (path.startsWith('/desktop') && Platform.isMobile) {
      resolver.redirect('/mobile-version');
      return;
    }
    
    // Apply regular protection
    await AuthGuard().onNavigation(resolver, context, state);
  }
}
```

## A/B Testing Guards

### Experiment-Based Routing

```dart
class ExperimentConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    final experiment = await experimentService.getUserExperiment(user?.id);
    
    switch (experiment) {
      case 'control':
        await StandardGuard().onNavigation(resolver, context, state);
      case 'variant_a':
        await EnhancedGuard().onNavigation(resolver, context, state);
      case 'variant_b':
        await PremiumGuard().onNavigation(resolver, context, state);
      default:
        await StandardGuard().onNavigation(resolver, context, state);
    }
  }
}
```

## Complex Conditional Logic

### Multi-Criteria Guard

```dart
class ComplexConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final path = state.uri.path;
    final user = context.read<UserCubit>().state.user;
    final now = DateTime.now();
    
    // Weekend admin access restriction
    if (path.startsWith('/admin') && _isWeekend(now)) {
      if (user?.hasRole('super_admin') != true) {
        resolver.redirect('/admin-weekend-restricted');
        return;
      }
    }
    
    // Geographic restrictions
    if (path.startsWith('/region-restricted')) {
      final location = await locationService.getUserLocation();
      if (!_isAllowedRegion(location)) {
        resolver.redirect('/geo-restricted');
        return;
      }
    }
    
    // Time-sensitive features
    if (path.startsWith('/limited-time')) {
      final feature = await featureService.getLimitedTimeFeature();
      if (feature?.isExpired == true) {
        resolver.redirect('/feature-expired');
        return;
      }
    }
    
    // Apply standard auth
    await AuthGuard().onNavigation(resolver, context, state);
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || 
           date.weekday == DateTime.sunday;
  }

  bool _isAllowedRegion(String region) {
    const allowedRegions = ['US', 'CA', 'EU'];
    return allowedRegions.contains(region);
  }
}
```

## Testing Conditional Guards

```dart
void main() {
  group('ConditionalGuard', () {
    test('excludes specified paths', () async {
      final guard = ConditionalGuard(
        guard: AuthGuard(),
        excludedPaths: ['/login', '/public'],
      );

      // Should allow navigation to excluded paths
      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(path: '/login'),
      );

      expect(result.continueNavigation, isTrue);
    });

    test('applies guard to non-excluded paths', () async {
      when(() => mockAuthService.isAuthenticated())
          .thenAnswer((_) async => false);

      final guard = ConditionalGuard(
        guard: AuthGuard(),
        excludedPaths: ['/login'],
      );

      // Should apply guard to non-excluded paths
      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(path: '/protected'),
      );

      expect(result.continueNavigation, isFalse);
    });
  });
}
```

## Best Practices

1. **Clear Conditions**: Make conditional logic easy to understand
2. **Fallback Behavior**: Always define what happens when conditions aren't met
3. **Performance**: Cache expensive condition checks
4. **Testing**: Test all conditional branches thoroughly
5. **Documentation**: Document the conditions and their behavior
6. **Monitoring**: Log conditional guard decisions for debugging

## Common Patterns

### Environment-Based Guards

```dart
class EnvironmentConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (kDebugMode) {
      // Development: allow all access
      resolver.next();
    } else if (kProfileMode) {
      // Testing: require basic auth
      await AuthGuard().onNavigation(resolver, context, state);
    } else {
      // Production: full protection
      await Guards.all([
        AuthGuard(),
        RoleGuard(['user']),
        SecurityCheckGuard(),
      ]).onNavigation(resolver, context, state);
    }
  }
}
```

### Graceful Degradation

```dart
class GracefulConditionalGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      // Try premium features
      await PremiumGuard().onNavigation(resolver, context, state);
    } catch (error) {
      // Fallback to basic features
      debugPrint('Premium guard failed, using basic: $error');
      await BasicGuard().onNavigation(resolver, context, state);
    }
  }
}
```

Conditional guards provide powerful flexibility for creating sophisticated protection schemes that adapt to your application's runtime conditions and user contexts.

## Next Steps

- 📋 Review [Best Practices](/guides/best-practices/)
- 📖 See practical [Examples](/examples/authentication/)
- 🧪 Learn about [Testing Guards](/guides/testing-guards/)
- 🔧 Explore [Advanced Patterns](/guides/advanced-patterns/)
